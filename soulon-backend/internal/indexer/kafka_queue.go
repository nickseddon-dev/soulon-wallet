package indexer

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/segmentio/kafka-go"
)

type KafkaQueue struct {
	options          KafkaOptions
	writer           *kafka.Writer
	reader           *kafka.Reader
	dlqWriter        *kafka.Writer
	pausedPartitions map[int]time.Time
	publishedTotal   int64
	committedTotal   int64
	mu               sync.Mutex
}

func NewKafkaQueue(options KafkaOptions, buffer int) (*KafkaQueue, error) {
	validBrokers := make([]string, 0, len(options.Brokers))
	for _, broker := range options.Brokers {
		trimmed := strings.TrimSpace(broker)
		if trimmed != "" {
			validBrokers = append(validBrokers, trimmed)
		}
	}
	if len(validBrokers) == 0 {
		return nil, fmt.Errorf("kafka brokers cannot be empty")
	}
	if strings.TrimSpace(options.Topic) == "" {
		return nil, fmt.Errorf("kafka topic cannot be empty")
	}
	if strings.TrimSpace(options.GroupID) == "" {
		return nil, fmt.Errorf("kafka group id cannot be empty")
	}
	if options.WriteRetries <= 0 {
		options.WriteRetries = 3
	}
	if options.WriteTimeoutMs <= 0 {
		options.WriteTimeoutMs = 3000
	}
	if options.KeyStrategy == "" {
		options.KeyStrategy = "id"
	}
	if buffer <= 0 {
		buffer = 128
	}
	options.Brokers = validBrokers
	options.Topic = strings.TrimSpace(options.Topic)
	options.GroupID = strings.TrimSpace(options.GroupID)
	options.DLQTopic = strings.TrimSpace(options.DLQTopic)
	options.KeyStrategy = strings.ToLower(strings.TrimSpace(options.KeyStrategy))
	if options.KeyStrategy != "id" && options.KeyStrategy != "height" && options.KeyStrategy != "type" {
		options.KeyStrategy = "id"
	}
	readerConfig := kafka.ReaderConfig{
		Brokers:        options.Brokers,
		Topic:          options.Topic,
		GroupID:        options.GroupID,
		CommitInterval: 0,
		MinBytes:       1,
		MaxBytes:       10e6,
		QueueCapacity:  buffer,
		MaxWait:        time.Second,
		MaxAttempts:    3,
	}
	var dlqWriter *kafka.Writer
	if options.DLQTopic != "" {
		dlqWriter = &kafka.Writer{
			Addr:         kafka.TCP(options.Brokers...),
			Topic:        options.DLQTopic,
			Balancer:     &kafka.LeastBytes{},
			BatchTimeout: 50 * time.Millisecond,
			BatchBytes:   1 << 20,
			RequiredAcks: kafka.RequireAll,
			Async:        false,
		}
	}
	return &KafkaQueue{
		options: options,
		writer: &kafka.Writer{
			Addr:         kafka.TCP(validBrokers...),
			Topic:        options.Topic,
			Balancer:     &kafka.LeastBytes{},
			BatchTimeout: 50 * time.Millisecond,
			BatchBytes:   1 << 20,
			RequiredAcks: kafka.RequireAll,
			Async:        false,
		},
		reader:           kafka.NewReader(readerConfig),
		dlqWriter:        dlqWriter,
		pausedPartitions: map[int]time.Time{},
	}, nil
}

func (q *KafkaQueue) Publish(ctx context.Context, event Event) error {
	payload, err := json.Marshal(event)
	if err != nil {
		return err
	}
	message := kafka.Message{
		Key:   []byte(q.keyForEvent(event)),
		Value: payload,
		Time:  event.ProducedAt,
	}
	var lastErr error
	for attempt := 1; attempt <= q.options.WriteRetries; attempt++ {
		attemptCtx, cancel := context.WithTimeout(ctx, time.Duration(q.options.WriteTimeoutMs)*time.Millisecond)
		writeErr := q.writer.WriteMessages(attemptCtx, message)
		cancel()
		if writeErr == nil {
			atomic.AddInt64(&q.publishedTotal, 1)
			return nil
		}
		lastErr = writeErr
		if ctx.Err() != nil {
			return ctx.Err()
		}
		time.Sleep(time.Duration(attempt) * 100 * time.Millisecond)
	}
	return lastErr
}

func (q *KafkaQueue) Consume(ctx context.Context) <-chan Event {
	out := make(chan Event)
	go func() {
		defer close(out)
		defer q.close()
		for {
			message, err := q.reader.FetchMessage(ctx)
			if err != nil {
				if ctx.Err() != nil {
					return
				}
				continue
			}
			var event Event
			if err := json.Unmarshal(message.Value, &event); err != nil {
				_ = q.PublishDeadLetter(ctx, string(message.Key), message.Value, "invalid-json")
				if commitErr := q.reader.CommitMessages(ctx, message); commitErr == nil {
					atomic.AddInt64(&q.committedTotal, 1)
				}
				continue
			}
			event.Partition = message.Partition
			event.Offset = message.Offset
			if waitDuration := q.partitionPauseDuration(event.Partition); waitDuration > 0 {
				select {
				case <-ctx.Done():
					return
				case <-time.After(waitDuration):
				}
			}
			select {
			case <-ctx.Done():
				return
			case out <- event:
			}
			if err := q.reader.CommitMessages(ctx, message); err != nil {
				if ctx.Err() != nil {
					return
				}
			} else {
				atomic.AddInt64(&q.committedTotal, 1)
			}
		}
	}()
	return out
}

func (q *KafkaQueue) close() {
	q.mu.Lock()
	defer q.mu.Unlock()
	if q.reader != nil {
		_ = q.reader.Close()
		q.reader = nil
	}
	if q.writer != nil {
		_ = q.writer.Close()
		q.writer = nil
	}
	if q.dlqWriter != nil {
		_ = q.dlqWriter.Close()
		q.dlqWriter = nil
	}
}

func (q *KafkaQueue) Backlog() int {
	published := atomic.LoadInt64(&q.publishedTotal)
	committed := atomic.LoadInt64(&q.committedTotal)
	backlog := published - committed
	if backlog < 0 {
		return 0
	}
	return int(backlog)
}

func (q *KafkaQueue) PausePartition(partition int, duration time.Duration) {
	if partition < 0 || duration <= 0 {
		return
	}
	q.mu.Lock()
	defer q.mu.Unlock()
	q.pausedPartitions[partition] = time.Now().Add(duration)
}

func (q *KafkaQueue) PublishDeadLetter(ctx context.Context, key string, payload []byte, reason string) error {
	if q.dlqWriter == nil {
		return nil
	}
	body, err := json.Marshal(map[string]any{
		"key":     key,
		"reason":  reason,
		"payload": payload,
		"at":      time.Now().UTC(),
	})
	if err != nil {
		return err
	}
	message := kafka.Message{
		Key:   []byte(key),
		Value: body,
		Time:  time.Now(),
	}
	return q.dlqWriter.WriteMessages(ctx, message)
}

func (q *KafkaQueue) keyForEvent(event Event) string {
	switch q.options.KeyStrategy {
	case "height":
		return fmt.Sprintf("%d", event.Height)
	case "type":
		if event.Type != "" {
			return event.Type
		}
	}
	if event.ID != "" {
		return event.ID
	}
	if event.BlockHash != "" {
		return event.BlockHash
	}
	return fmt.Sprintf("%d", event.Height)
}

func (q *KafkaQueue) partitionPauseDuration(partition int) time.Duration {
	q.mu.Lock()
	defer q.mu.Unlock()
	until, exists := q.pausedPartitions[partition]
	if !exists {
		return 0
	}
	remaining := time.Until(until)
	if remaining <= 0 {
		delete(q.pausedPartitions, partition)
		return 0
	}
	return remaining
}
