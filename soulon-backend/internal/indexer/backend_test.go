package indexer

import "testing"

func TestNewQueueByBackend(t *testing.T) {
	queue, err := NewQueueByBackend("memory", 8, KafkaOptions{})
	if err != nil {
		t.Fatalf("memory backend should be created: %v", err)
	}
	if queue == nil {
		t.Fatal("queue should not be nil")
	}
	queue, err = NewQueueByBackend("kafka", 8, KafkaOptions{
		Brokers: []string{"127.0.0.1:9092"},
		Topic:   "topic",
		GroupID: "group",
	})
	if err != nil {
		t.Fatalf("kafka backend should be created: %v", err)
	}
	if queue == nil {
		t.Fatal("kafka queue should not be nil")
	}
	_, err = NewQueueByBackend("unknown", 8, KafkaOptions{})
	if err == nil {
		t.Fatal("unknown queue backend should fail")
	}
}

func TestNewStoreByBackend(t *testing.T) {
	store, err := NewStoreByBackend("file", "data/test-events.jsonl", "", 0)
	if err != nil {
		t.Fatalf("file backend should be created: %v", err)
	}
	if store == nil {
		t.Fatal("store should not be nil")
	}
	store, err = NewStoreByBackend("postgres", "data/test-events.jsonl", "postgres://example", 0)
	if err != nil {
		t.Fatalf("postgres backend should be created: %v", err)
	}
	if store == nil {
		t.Fatal("postgres store should not be nil")
	}
	_, err = NewStoreByBackend("unknown", "data/test-events.jsonl", "", 0)
	if err == nil {
		t.Fatal("unknown store backend should fail")
	}
}
