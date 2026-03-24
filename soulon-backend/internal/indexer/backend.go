package indexer

import (
	"fmt"
	"strings"
)

type KafkaOptions struct {
	Brokers        []string
	Topic          string
	GroupID        string
	DLQTopic       string
	KeyStrategy    string
	WriteTimeoutMs int
	WriteRetries   int
}

func NewQueueByBackend(
	backend string,
	buffer int,
	kafkaOptions KafkaOptions,
) (Queue, error) {
	switch strings.ToLower(strings.TrimSpace(backend)) {
	case "", "memory":
		return NewMemoryQueue(buffer), nil
	case "kafka":
		return NewKafkaQueue(kafkaOptions, buffer)
	default:
		return nil, fmt.Errorf("unsupported queue backend: %s", backend)
	}
}

func NewStoreByBackend(
	backend string,
	eventStorePath string,
	postgresDSN string,
	postgresRetentionBlocks int64,
) (Store, error) {
	switch strings.ToLower(strings.TrimSpace(backend)) {
	case "", "file":
		return NewFileEventStore(eventStorePath)
	case "postgres":
		return NewPostgresStore(postgresDSN, postgresRetentionBlocks)
	default:
		return nil, fmt.Errorf("unsupported store backend: %s", backend)
	}
}
