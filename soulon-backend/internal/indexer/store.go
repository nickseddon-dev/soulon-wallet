package indexer

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sync"
	"time"
)

type Store interface {
	Upsert(ctx context.Context, event Event) (bool, error)
	Count() int
	State() StoreState
	RunMaintenance(ctx context.Context) error
}

type StoreState struct {
	TipHeight int64  `json:"tipHeight"`
	TipHash   string `json:"tipHash"`
	Total     int    `json:"total"`
	Reorgs    int    `json:"reorgs"`
}

type FileEventStore struct {
	path           string
	seen           map[string]struct{}
	eventsByHeight map[int64]Event
	tipHeight      int64
	tipHash        string
	reorgs         int
	mu             sync.Mutex
}

func NewFileEventStore(path string) (*FileEventStore, error) {
	store := &FileEventStore{
		path:           path,
		seen:           map[string]struct{}{},
		eventsByHeight: map[int64]Event{},
	}
	if err := store.loadSeen(); err != nil {
		return nil, err
	}
	return store, nil
}

func (s *FileEventStore) Upsert(_ context.Context, event Event) (bool, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if event.Type == "" {
		event.Type = "new_block"
	}
	if event.Type == "rollback" {
		if event.RollbackFrom <= 0 {
			return false, fmt.Errorf("invalid rollback height: %d", event.RollbackFrom)
		}
		event.ID = fmt.Sprintf("rollback-%d-%d", event.RollbackFrom, time.Now().UnixNano())
		event.Height = event.RollbackFrom
		if err := s.appendEvent(event); err != nil {
			return false, err
		}
		s.applyRollback(event.RollbackFrom)
		s.reorgs++
		return true, nil
	}
	if event.ID == "" {
		if event.BlockHash != "" {
			event.ID = event.BlockHash
		} else {
			event.ID = fmt.Sprintf("block-%d", event.Height)
		}
	}
	if event.BlockHash == "" {
		event.BlockHash = event.ID
	}
	if _, exists := s.seen[event.ID]; exists {
		return false, nil
	}
	if needsRollback, rollbackFrom := s.requiresRollback(event); needsRollback {
		rollbackEvent := Event{
			ID:           fmt.Sprintf("rollback-%d-%d", rollbackFrom, time.Now().UnixNano()),
			Height:       rollbackFrom,
			Type:         "rollback",
			RollbackFrom: rollbackFrom,
			Payload:      fmt.Sprintf(`{"rollbackFrom":%d}`, rollbackFrom),
			ProducedAt:   event.ProducedAt,
		}
		if err := s.appendEvent(rollbackEvent); err != nil {
			return false, err
		}
		s.applyRollback(rollbackFrom)
		s.reorgs++
	}
	if err := s.appendEvent(event); err != nil {
		return false, err
	}
	s.applyBlock(event)
	return true, nil
}

func (s *FileEventStore) Count() int {
	s.mu.Lock()
	defer s.mu.Unlock()
	return len(s.seen)
}

func (s *FileEventStore) State() StoreState {
	s.mu.Lock()
	defer s.mu.Unlock()
	return StoreState{
		TipHeight: s.tipHeight,
		TipHash:   s.tipHash,
		Total:     len(s.seen),
		Reorgs:    s.reorgs,
	}
}

func (s *FileEventStore) RunMaintenance(_ context.Context) error {
	return nil
}

func (s *FileEventStore) loadSeen() error {
	file, err := os.Open(s.path)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return err
	}
	defer file.Close()
	decoder := json.NewDecoder(file)
	for {
		var event Event
		if decodeErr := decoder.Decode(&event); decodeErr != nil {
			if errors.Is(decodeErr, io.EOF) {
				return nil
			}
			return decodeErr
		}
		if event.Type == "rollback" {
			s.applyRollback(event.RollbackFrom)
			s.reorgs++
			continue
		}
		s.applyBlock(event)
	}
}

func (s *FileEventStore) requiresRollback(event Event) (bool, int64) {
	if event.Height <= 0 {
		return false, 0
	}
	current, exists := s.eventsByHeight[event.Height]
	if exists && current.BlockHash != "" && current.BlockHash != event.BlockHash {
		return true, event.Height
	}
	if s.tipHeight == 0 {
		return false, 0
	}
	if event.Height <= s.tipHeight {
		return true, event.Height
	}
	if s.tipHash != "" && event.ParentHash != "" && event.ParentHash != s.tipHash {
		rollbackFrom := event.Height - 1
		if rollbackFrom <= 0 {
			rollbackFrom = 1
		}
		return true, rollbackFrom
	}
	return false, 0
}

func (s *FileEventStore) applyRollback(fromHeight int64) {
	if fromHeight <= 0 {
		return
	}
	for height, event := range s.eventsByHeight {
		if height >= fromHeight {
			delete(s.eventsByHeight, height)
			if event.ID != "" {
				delete(s.seen, event.ID)
			}
		}
	}
	s.recalculateTip()
}

func (s *FileEventStore) applyBlock(event Event) {
	if event.ID == "" {
		event.ID = fmt.Sprintf("block-%d", event.Height)
	}
	if event.BlockHash == "" {
		event.BlockHash = event.ID
	}
	s.eventsByHeight[event.Height] = event
	s.seen[event.ID] = struct{}{}
	if event.Height >= s.tipHeight {
		s.tipHeight = event.Height
		s.tipHash = event.BlockHash
	}
}

func (s *FileEventStore) recalculateTip() {
	var tipHeight int64
	var tipHash string
	for height, event := range s.eventsByHeight {
		if height >= tipHeight {
			tipHeight = height
			tipHash = event.BlockHash
		}
	}
	s.tipHeight = tipHeight
	s.tipHash = tipHash
}

func (s *FileEventStore) appendEvent(event Event) error {
	event.PersistedAt = time.Now()
	lineBytes, err := json.Marshal(event)
	if err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(s.path), 0o755); err != nil {
		return err
	}
	file, err := os.OpenFile(s.path, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		return err
	}
	defer file.Close()
	_, err = file.Write(append(lineBytes, '\n'))
	return err
}
