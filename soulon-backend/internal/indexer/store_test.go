package indexer

import (
	"context"
	"path/filepath"
	"testing"
	"time"
)

func TestFileEventStoreRollbackAndState(t *testing.T) {
	storePath := filepath.Join(t.TempDir(), "events.jsonl")
	store, err := NewFileEventStore(storePath)
	if err != nil {
		t.Fatalf("create store failed: %v", err)
	}

	now := time.Now()
	_, err = store.Upsert(context.Background(), Event{
		ID:         "h1-a",
		Height:     1,
		Type:       "new_block",
		BlockHash:  "h1-a",
		ParentHash: "",
		ProducedAt: now,
	})
	if err != nil {
		t.Fatalf("upsert h1 failed: %v", err)
	}
	_, err = store.Upsert(context.Background(), Event{
		ID:         "h2-a",
		Height:     2,
		Type:       "new_block",
		BlockHash:  "h2-a",
		ParentHash: "h1-a",
		ProducedAt: now,
	})
	if err != nil {
		t.Fatalf("upsert h2 failed: %v", err)
	}
	_, err = store.Upsert(context.Background(), Event{
		ID:         "h3-a",
		Height:     3,
		Type:       "new_block",
		BlockHash:  "h3-a",
		ParentHash: "h2-a",
		ProducedAt: now,
	})
	if err != nil {
		t.Fatalf("upsert h3 failed: %v", err)
	}

	state := store.State()
	if state.TipHeight != 3 || state.Reorgs != 0 {
		t.Fatalf("unexpected initial state: %+v", state)
	}

	_, err = store.Upsert(context.Background(), Event{
		ID:         "h2-b",
		Height:     2,
		Type:       "new_block",
		BlockHash:  "h2-b",
		ParentHash: "h1-a",
		ProducedAt: now,
	})
	if err != nil {
		t.Fatalf("upsert h2-b failed: %v", err)
	}

	state = store.State()
	if state.TipHeight != 2 {
		t.Fatalf("tip height after rollback mismatch: %+v", state)
	}
	if state.TipHash != "h2-b" {
		t.Fatalf("tip hash after rollback mismatch: %+v", state)
	}
	if state.Reorgs != 1 {
		t.Fatalf("reorg count mismatch: %+v", state)
	}
}

func TestFileEventStoreForkParentMismatchRollback(t *testing.T) {
	storePath := filepath.Join(t.TempDir(), "events.jsonl")
	store, err := NewFileEventStore(storePath)
	if err != nil {
		t.Fatalf("create store failed: %v", err)
	}
	now := time.Now()
	seed := []Event{
		{ID: "h1-a", Height: 1, Type: "new_block", BlockHash: "h1-a", ProducedAt: now},
		{ID: "h2-a", Height: 2, Type: "new_block", BlockHash: "h2-a", ParentHash: "h1-a", ProducedAt: now},
		{ID: "h3-a", Height: 3, Type: "new_block", BlockHash: "h3-a", ParentHash: "h2-a", ProducedAt: now},
	}
	for _, event := range seed {
		if _, err := store.Upsert(context.Background(), event); err != nil {
			t.Fatalf("seed upsert failed: %v", err)
		}
	}
	_, err = store.Upsert(context.Background(), Event{
		ID:         "h4-b",
		Height:     4,
		Type:       "new_block",
		BlockHash:  "h4-b",
		ParentHash: "unexpected-parent",
		ProducedAt: now,
	})
	if err != nil {
		t.Fatalf("fork upsert failed: %v", err)
	}
	state := store.State()
	if state.Reorgs != 1 {
		t.Fatalf("reorg count mismatch: %+v", state)
	}
	if state.TipHeight != 4 {
		t.Fatalf("tip height mismatch: %+v", state)
	}
	if state.TipHash != "h4-b" {
		t.Fatalf("tip hash mismatch: %+v", state)
	}
}
