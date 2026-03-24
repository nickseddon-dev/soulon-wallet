package indexer

import (
	"context"
	"os"
	"testing"
	"time"
)

func TestKafkaAndPostgresIntegration(t *testing.T) {
	if os.Getenv("RUN_E2E") != "1" {
		t.Skip("set RUN_E2E=1 to run integration test")
	}
	kafkaQueue, err := NewKafkaQueue(
		KafkaOptions{
			Brokers:  []string{getEnvWithDefault("INDEXER_KAFKA_BROKERS", "127.0.0.1:9092")},
			Topic:    getEnvWithDefault("INDEXER_KAFKA_TOPIC", "soulon.indexer.events"),
			GroupID:  getEnvWithDefault("INDEXER_KAFKA_GROUP_ID", "soulon-indexer-e2e"),
			DLQTopic: getEnvWithDefault("INDEXER_KAFKA_DLQ_TOPIC", "soulon.indexer.events.dlq"),
		},
		128,
	)
	if err != nil {
		t.Fatalf("kafka queue init failed: %v", err)
	}
	store, err := NewPostgresStore(getEnvWithDefault("INDEXER_POSTGRES_DSN", "postgres://postgres:postgres@127.0.0.1:5432/soulon_indexer?sslmode=disable"), 0)
	if err != nil {
		t.Fatalf("postgres store init failed: %v", err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	stream := kafkaQueue.Consume(ctx)
	event := Event{
		ID:         "e2e-1",
		Height:     1,
		Type:       "new_block",
		BlockHash:  "e2e-1",
		ParentHash: "",
		Payload:    `{"source":"e2e"}`,
		ProducedAt: time.Now(),
	}
	if err := kafkaQueue.Publish(ctx, event); err != nil {
		t.Fatalf("publish failed: %v", err)
	}
	select {
	case got := <-stream:
		if got.ID != event.ID {
			t.Fatalf("consume mismatch: %+v", got)
		}
		if _, err := store.Upsert(ctx, got); err != nil {
			t.Fatalf("store upsert failed: %v", err)
		}
	case <-ctx.Done():
		t.Fatal("consume timeout")
	}
	state := store.State()
	if state.TipHeight < 1 {
		t.Fatalf("state tip not updated: %+v", state)
	}
}

func getEnvWithDefault(key string, fallback string) string {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}
	return value
}
