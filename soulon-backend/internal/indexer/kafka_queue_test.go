package indexer

import (
	"testing"
	"time"
)

func TestKafkaQueueValidation(t *testing.T) {
	_, err := NewKafkaQueue(KafkaOptions{
		Brokers: []string{},
		Topic:   "topic",
		GroupID: "group",
	}, 8)
	if err == nil {
		t.Fatal("empty brokers should fail")
	}
	_, err = NewKafkaQueue(KafkaOptions{
		Brokers: []string{"127.0.0.1:9092"},
		Topic:   "",
		GroupID: "group",
	}, 8)
	if err == nil {
		t.Fatal("empty topic should fail")
	}
	_, err = NewKafkaQueue(KafkaOptions{
		Brokers: []string{"127.0.0.1:9092"},
		Topic:   "topic",
		GroupID: "",
	}, 8)
	if err == nil {
		t.Fatal("empty group should fail")
	}
}

func TestKafkaQueueBuildsClient(t *testing.T) {
	queue, err := NewKafkaQueue(KafkaOptions{
		Brokers: []string{"127.0.0.1:9092"},
		Topic:   "topic",
		GroupID: "group",
	}, 8)
	if err != nil {
		t.Fatalf("create kafka queue failed: %v", err)
	}
	if queue.writer == nil || queue.reader == nil {
		t.Fatal("kafka client should be initialized")
	}
	queue.close()
}

func TestKafkaQueuePausePartition(t *testing.T) {
	queue, err := NewKafkaQueue(KafkaOptions{
		Brokers: []string{"127.0.0.1:9092"},
		Topic:   "topic",
		GroupID: "group",
	}, 8)
	if err != nil {
		t.Fatalf("create kafka queue failed: %v", err)
	}
	queue.PausePartition(1, 20*time.Millisecond)
	if wait := queue.partitionPauseDuration(1); wait <= 0 {
		t.Fatal("partition should be paused")
	}
	time.Sleep(25 * time.Millisecond)
	if wait := queue.partitionPauseDuration(1); wait > 0 {
		t.Fatal("partition pause should be cleared")
	}
	queue.close()
}

func TestKafkaQueueBacklog(t *testing.T) {
	queue, err := NewKafkaQueue(KafkaOptions{
		Brokers: []string{"127.0.0.1:9092"},
		Topic:   "topic",
		GroupID: "group",
	}, 8)
	if err != nil {
		t.Fatalf("create kafka queue failed: %v", err)
	}
	queue.publishedTotal = 5
	queue.committedTotal = 2
	if backlog := queue.Backlog(); backlog != 3 {
		t.Fatalf("unexpected backlog: %d", backlog)
	}
	queue.publishedTotal = 1
	queue.committedTotal = 3
	if backlog := queue.Backlog(); backlog != 0 {
		t.Fatalf("backlog should never be negative: %d", backlog)
	}
	queue.close()
}
