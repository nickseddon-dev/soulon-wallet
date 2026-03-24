package api

import (
	"soulon-backend/internal/indexer"
	"testing"
)

func TestRebuildStateWithRollback(t *testing.T) {
	state := rebuildState([]indexer.Event{
		{Height: 1, Type: "new_block", BlockHash: "h1-a"},
		{Height: 2, Type: "new_block", BlockHash: "h2-a"},
		{Height: 3, Type: "new_block", BlockHash: "h3-a"},
		{Type: "rollback", RollbackFrom: 2},
		{Height: 2, Type: "new_block", BlockHash: "h2-b"},
	})

	if state.TipHeight != 2 {
		t.Fatalf("tip height mismatch: %+v", state)
	}
	if state.TipHash != "h2-b" {
		t.Fatalf("tip hash mismatch: %+v", state)
	}
	if state.Total != 2 {
		t.Fatalf("total mismatch: %+v", state)
	}
	if state.Reorgs != 1 {
		t.Fatalf("reorg mismatch: %+v", state)
	}
}
