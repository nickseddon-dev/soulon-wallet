package indexer

import (
	"context"
	"path/filepath"
	"strconv"
	"testing"
	"time"
)

func BenchmarkFileEventStoreUpsert(b *testing.B) {
	storePath := filepath.Join(b.TempDir(), "bench-events.jsonl")
	store, err := NewFileEventStore(storePath)
	if err != nil {
		b.Fatalf("create store failed: %v", err)
	}
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		height := int64(i + 1)
		event := Event{
			ID:         "bench-" + strconv.Itoa(i),
			Height:     height,
			Type:       "new_block",
			BlockHash:  "bench-" + strconv.Itoa(i),
			Payload:    `{"source":"benchmark"}`,
			ProducedAt: time.Now(),
		}
		if _, err := store.Upsert(context.Background(), event); err != nil {
			b.Fatalf("upsert failed: %v", err)
		}
	}
}
