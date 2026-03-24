package indexer

import (
	"context"
	"errors"
	"log"
	"testing"
	"time"
)

type flakyStore struct {
	failures int
	calls    int
}

func (s *flakyStore) Upsert(_ context.Context, _ Event) (bool, error) {
	s.calls++
	if s.calls <= s.failures {
		return false, errors.New("injected failure")
	}
	return true, nil
}

func (s *flakyStore) Count() int {
	return 0
}

func (s *flakyStore) State() StoreState {
	return StoreState{}
}

func (s *flakyStore) RunMaintenance(_ context.Context) error {
	return nil
}

type testQueue struct {
	dlqCount      int
	pauseCount    int
	lastPartition int
}

func (q *testQueue) Publish(_ context.Context, _ Event) error {
	return nil
}

func (q *testQueue) Consume(_ context.Context) <-chan Event {
	out := make(chan Event)
	close(out)
	return out
}

func (q *testQueue) PublishDeadLetter(_ context.Context, _ string, _ []byte, _ string) error {
	q.dlqCount++
	return nil
}

func (q *testQueue) Backlog() int {
	return 0
}

func (q *testQueue) PausePartition(partition int, _ time.Duration) {
	q.pauseCount++
	q.lastPartition = partition
}

func TestPersistWithRetrySkip(t *testing.T) {
	store := &flakyStore{failures: 5}
	queue := &testQueue{}
	worker := NewWorker(
		time.Second,
		0,
		queue,
		store,
		log.Default(),
		WorkerOptions{
			PersistMaxRetries:     3,
			PersistRetryBackoffMs: 1,
			PersistFailurePolicy:  "skip",
		},
	)
	created, err := worker.persistWithRetry(context.Background(), Event{
		ID:         "evt-1",
		Height:     1,
		Type:       "new_block",
		Partition:  2,
		ProducedAt: time.Now(),
	})
	if err != nil {
		t.Fatalf("skip policy should not return error: %v", err)
	}
	if created {
		t.Fatal("skip policy should not create event")
	}
	if queue.dlqCount != 1 {
		t.Fatalf("dlq count mismatch: %d", queue.dlqCount)
	}
	if queue.pauseCount != 1 || queue.lastPartition != 2 {
		t.Fatalf("partition pause mismatch: count=%d partition=%d", queue.pauseCount, queue.lastPartition)
	}
}

func TestPersistWithRetryStop(t *testing.T) {
	store := &flakyStore{failures: 5}
	queue := &testQueue{}
	worker := NewWorker(
		time.Second,
		0,
		queue,
		store,
		log.Default(),
		WorkerOptions{
			PersistMaxRetries:     2,
			PersistRetryBackoffMs: 1,
			PersistFailurePolicy:  "stop",
		},
	)
	_, err := worker.persistWithRetry(context.Background(), Event{
		ID:         "evt-2",
		Height:     2,
		Type:       "new_block",
		Partition:  3,
		ProducedAt: time.Now(),
	})
	if err == nil {
		t.Fatal("stop policy should return error")
	}
	if queue.dlqCount != 1 {
		t.Fatalf("dlq count mismatch: %d", queue.dlqCount)
	}
	if queue.pauseCount != 1 || queue.lastPartition != 3 {
		t.Fatalf("partition pause mismatch: count=%d partition=%d", queue.pauseCount, queue.lastPartition)
	}
}
