package indexer

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"sync/atomic"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

var (
	workerProducedTotal = promauto.NewCounter(prometheus.CounterOpts{
		Name: "indexer_worker_produced_total",
		Help: "Total number of produced events.",
	})
	workerConsumedTotal = promauto.NewCounter(prometheus.CounterOpts{
		Name: "indexer_worker_consumed_total",
		Help: "Total number of consumed events.",
	})
	workerErrorTotal = promauto.NewCounter(prometheus.CounterOpts{
		Name: "indexer_worker_error_total",
		Help: "Total number of worker errors.",
	})
	workerLatencyMs = promauto.NewGauge(prometheus.GaugeOpts{
		Name: "indexer_worker_last_latency_ms",
		Help: "Latest end-to-end latency in milliseconds.",
	})
	workerBacklog = promauto.NewGauge(prometheus.GaugeOpts{
		Name: "indexer_worker_backlog",
		Help: "Current queue backlog size.",
	})
	workerReorgs = promauto.NewGauge(prometheus.GaugeOpts{
		Name: "indexer_worker_reorgs",
		Help: "Current reorg count.",
	})
	workerPausedPartitionsTotal = promauto.NewCounter(prometheus.CounterOpts{
		Name: "indexer_worker_paused_partitions_total",
		Help: "Total number of partition pause operations due to failures.",
	})
)

type WorkerOptions struct {
	PersistMaxRetries     int
	PersistRetryBackoffMs int
	PersistFailurePolicy  string
	ConsumePauseMs        int
	MaintenanceIntervalMs int
	Notifier              Notifier
}

type Worker struct {
	pollInterval  time.Duration
	reorgInterval int64
	queue         Queue
	store         Store
	logger        *log.Logger
	nextHeight    int64
	hashByHeight  map[int64]string
	producedTotal int64
	consumedTotal int64
	errorTotal    int64
	lastLatencyMs int64
	tickCount     int64
	options       WorkerOptions
}

func NewWorker(
	pollInterval time.Duration,
	reorgInterval int64,
	queue Queue,
	store Store,
	logger *log.Logger,
	options WorkerOptions,
) *Worker {
	if options.PersistMaxRetries <= 0 {
		options.PersistMaxRetries = 3
	}
	if options.PersistRetryBackoffMs < 0 {
		options.PersistRetryBackoffMs = 500
	}
	if options.PersistFailurePolicy == "" {
		options.PersistFailurePolicy = "stop"
	}
	if options.ConsumePauseMs <= 0 {
		options.ConsumePauseMs = 3000
	}
	if options.MaintenanceIntervalMs <= 0 {
		options.MaintenanceIntervalMs = 60000
	}
	if options.Notifier == nil {
		options.Notifier = NoopNotifier{}
	}
	return &Worker{
		pollInterval:  pollInterval,
		reorgInterval: reorgInterval,
		queue:         queue,
		store:         store,
		logger:        logger,
		nextHeight:    1,
		hashByHeight:  map[int64]string{},
		options:       options,
	}
}

func (w *Worker) Run(ctx context.Context) error {
	consumerErrors := make(chan error, 1)
	go w.consumeLoop(ctx, consumerErrors)
	ticker := time.NewTicker(w.pollInterval)
	maintenanceTicker := time.NewTicker(time.Duration(w.options.MaintenanceIntervalMs) * time.Millisecond)
	defer ticker.Stop()
	defer maintenanceTicker.Stop()
	for {
		select {
		case <-ctx.Done():
			return nil
		case err := <-consumerErrors:
			return err
		case <-ticker.C:
			events := w.generateTickEvents()
			for _, event := range events {
				if err := w.queue.Publish(ctx, event); err != nil {
					atomic.AddInt64(&w.errorTotal, 1)
					workerErrorTotal.Inc()
					w.logger.Printf("[ERROR] publish failed: id=%s height=%d err=%v", event.ID, event.Height, err)
					return err
				}
				atomic.AddInt64(&w.producedTotal, 1)
				workerProducedTotal.Inc()
			}
			tick := atomic.AddInt64(&w.tickCount, 1)
			if tick%10 == 0 {
				state := w.store.State()
				workerBacklog.Set(float64(w.queue.Backlog()))
				workerReorgs.Set(float64(state.Reorgs))
				w.logger.Printf(
					"[INFO] worker metrics: produced=%d consumed=%d backlog=%d tipHeight=%d reorgs=%d lastLatencyMs=%d errors=%d",
					atomic.LoadInt64(&w.producedTotal),
					atomic.LoadInt64(&w.consumedTotal),
					w.queue.Backlog(),
					state.TipHeight,
					state.Reorgs,
					atomic.LoadInt64(&w.lastLatencyMs),
					atomic.LoadInt64(&w.errorTotal),
				)
			}
		case <-maintenanceTicker.C:
			if err := w.store.RunMaintenance(ctx); err != nil {
				atomic.AddInt64(&w.errorTotal, 1)
				workerErrorTotal.Inc()
				w.logger.Printf("[ERROR] maintenance failed: err=%v", err)
			}
		}
	}
}

func (w *Worker) generateTickEvents() []Event {
	height := w.nextHeight
	parentHash := w.hashByHeight[height-1]
	blockHash := fmt.Sprintf("block-%d-a", height)
	mainEvent := Event{
		ID:         blockHash,
		Height:     height,
		Type:       "new_block",
		BlockHash:  blockHash,
		ParentHash: parentHash,
		Payload:    fmt.Sprintf(`{"height":%d,"branch":"main"}`, height),
		ProducedAt: time.Now(),
	}
	w.hashByHeight[height] = blockHash
	w.nextHeight++
	events := []Event{mainEvent}
	if w.reorgInterval > 0 && height > 2 && height%w.reorgInterval == 0 {
		reorgHeight := height - 1
		reorgParentHash := w.hashByHeight[reorgHeight-1]
		reorgHash := fmt.Sprintf("block-%d-b", reorgHeight)
		reorgEvent := Event{
			ID:         reorgHash,
			Height:     reorgHeight,
			Type:       "new_block",
			BlockHash:  reorgHash,
			ParentHash: reorgParentHash,
			Payload:    fmt.Sprintf(`{"height":%d,"branch":"reorg"}`, reorgHeight),
			ProducedAt: time.Now(),
		}
		events = append(events, reorgEvent)
		w.hashByHeight[reorgHeight] = reorgHash
		for h := reorgHeight + 1; h <= height; h++ {
			delete(w.hashByHeight, h)
		}
		w.nextHeight = reorgHeight + 1
	}
	return events
}

func (w *Worker) consumeLoop(ctx context.Context, consumerErrors chan<- error) {
	stream := w.queue.Consume(ctx)
	for event := range stream {
		created, err := w.persistWithRetry(ctx, event)
		if err != nil {
			atomic.AddInt64(&w.errorTotal, 1)
			workerErrorTotal.Inc()
			w.logger.Printf("[ERROR] persist failed: id=%s height=%d err=%v", event.ID, event.Height, err)
			consumerErrors <- err
			return
		}
		atomic.AddInt64(&w.consumedTotal, 1)
		workerConsumedTotal.Inc()
		if !event.ProducedAt.IsZero() {
			latency := time.Since(event.ProducedAt).Milliseconds()
			atomic.StoreInt64(&w.lastLatencyMs, latency)
			workerLatencyMs.Set(float64(latency))
		}
		if created {
			if err := w.options.Notifier.Notify(ctx, event); err != nil {
				atomic.AddInt64(&w.errorTotal, 1)
				workerErrorTotal.Inc()
				w.logger.Printf("[WARN] notify failed: id=%s height=%d err=%v", event.ID, event.Height, err)
			}
			state := w.store.State()
			w.logger.Printf(
				"[INFO] event persisted: id=%s height=%d total=%d tipHeight=%d reorgs=%d",
				event.ID,
				event.Height,
				state.Total,
				state.TipHeight,
				state.Reorgs,
			)
		} else {
			w.logger.Printf("[WARN] duplicate event skipped: id=%s height=%d", event.ID, event.Height)
		}
	}
}

func (w *Worker) persistWithRetry(ctx context.Context, event Event) (bool, error) {
	var lastErr error
	for attempt := 1; attempt <= w.options.PersistMaxRetries; attempt++ {
		created, err := w.store.Upsert(ctx, event)
		if err == nil {
			return created, nil
		}
		lastErr = err
		atomic.AddInt64(&w.errorTotal, 1)
		workerErrorTotal.Inc()
		w.logger.Printf("[WARN] persist retry: id=%s attempt=%d err=%v", event.ID, attempt, err)
		if attempt == w.options.PersistMaxRetries {
			break
		}
		select {
		case <-ctx.Done():
			return false, ctx.Err()
		case <-time.After(time.Duration(w.options.PersistRetryBackoffMs) * time.Millisecond):
		}
	}
	payload, marshalErr := json.Marshal(event)
	if marshalErr == nil {
		_ = w.queue.PublishDeadLetter(ctx, event.ID, payload, lastErr.Error())
	}
	if w.options.ConsumePauseMs > 0 {
		w.queue.PausePartition(event.Partition, time.Duration(w.options.ConsumePauseMs)*time.Millisecond)
		workerPausedPartitionsTotal.Inc()
		w.logger.Printf(
			"[WARN] partition paused: partition=%d offset=%d pauseMs=%d id=%s",
			event.Partition,
			event.Offset,
			w.options.ConsumePauseMs,
			event.ID,
		)
	}
	if w.options.PersistFailurePolicy == "skip" {
		w.logger.Printf("[ERROR] persist skipped after retries: id=%s err=%v", event.ID, lastErr)
		return false, nil
	}
	return false, lastErr
}
