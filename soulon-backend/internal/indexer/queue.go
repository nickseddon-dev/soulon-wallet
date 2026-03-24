package indexer

import (
	"context"
	"time"
)

type Queue interface {
	Publish(ctx context.Context, event Event) error
	Consume(ctx context.Context) <-chan Event
	PublishDeadLetter(ctx context.Context, key string, payload []byte, reason string) error
	PausePartition(partition int, duration time.Duration)
	Backlog() int
}

type MemoryQueue struct {
	stream chan Event
}

func NewMemoryQueue(buffer int) *MemoryQueue {
	return &MemoryQueue{
		stream: make(chan Event, buffer),
	}
}

func (q *MemoryQueue) Publish(ctx context.Context, event Event) error {
	select {
	case <-ctx.Done():
		return ctx.Err()
	case q.stream <- event:
		return nil
	}
}

func (q *MemoryQueue) Consume(ctx context.Context) <-chan Event {
	out := make(chan Event)
	go func() {
		defer close(out)
		for {
			select {
			case <-ctx.Done():
				return
			case event := <-q.stream:
				select {
				case <-ctx.Done():
					return
				case out <- event:
				}
			}
		}
	}()
	return out
}

func (q *MemoryQueue) Backlog() int {
	return len(q.stream)
}

func (q *MemoryQueue) PublishDeadLetter(_ context.Context, _ string, _ []byte, _ string) error {
	return nil
}

func (q *MemoryQueue) PausePartition(_ int, _ time.Duration) {}
