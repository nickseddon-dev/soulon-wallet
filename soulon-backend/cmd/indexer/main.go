package main

import (
	"context"
	"log"
	"net/http"
	"os/signal"
	"soulon-backend/internal/config"
	"soulon-backend/internal/indexer"
	"syscall"

	"github.com/prometheus/client_golang/prometheus/promhttp"
)

func main() {
	ctx, cancel := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer cancel()
	cfg, err := config.LoadIndexerConfigFromEnv()
	if err != nil {
		log.Fatal(err)
	}
	if cfg.MetricsListenAddr != "" {
		go func() {
			mux := http.NewServeMux()
			mux.Handle("/metrics", promhttp.Handler())
			server := &http.Server{
				Addr:    cfg.MetricsListenAddr,
				Handler: mux,
			}
			if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
				log.Printf("metrics server stopped: %v", err)
			}
		}()
		log.Printf("metrics server started: %s", cfg.MetricsListenAddr)
	}
	queue, err := indexer.NewQueueByBackend(
		cfg.QueueBackend,
		cfg.QueueBuffer,
		indexer.KafkaOptions{
			Brokers:        cfg.KafkaBrokers,
			Topic:          cfg.KafkaTopic,
			GroupID:        cfg.KafkaGroupID,
			DLQTopic:       cfg.KafkaDLQTopic,
			KeyStrategy:    cfg.KafkaKeyStrategy,
			WriteTimeoutMs: cfg.KafkaWriteTimeoutMs,
			WriteRetries:   cfg.KafkaWriteRetries,
		},
	)
	if err != nil {
		log.Fatal(err)
	}
	store, err := indexer.NewStoreByBackend(cfg.StoreBackend, cfg.EventStorePath, cfg.PostgresDSN, cfg.PostgresRetentionBlocks)
	if err != nil {
		log.Fatal(err)
	}
	notifier := indexer.Notifier(indexer.NoopNotifier{})
	if cfg.NotifyWebhookURL != "" {
		webhookNotifier, notifierErr := indexer.NewWebhookNotifier(indexer.WebhookNotifierOptions{
			URL:       cfg.NotifyWebhookURL,
			TimeoutMs: cfg.NotifyTimeoutMs,
			Retries:   cfg.NotifyRetries,
			AuthToken: cfg.NotifyAuthToken,
		})
		if notifierErr != nil {
			log.Fatal(notifierErr)
		}
		notifier = webhookNotifier
	}
	worker := indexer.NewWorker(
		cfg.PollInterval,
		cfg.ReorgInterval,
		queue,
		store,
		log.Default(),
		indexer.WorkerOptions{
			PersistMaxRetries:     cfg.PersistMaxRetries,
			PersistRetryBackoffMs: cfg.PersistRetryBackoffMs,
			PersistFailurePolicy:  cfg.PersistFailurePolicy,
			ConsumePauseMs:        cfg.ConsumePauseMs,
			MaintenanceIntervalMs: cfg.MaintenanceIntervalMs,
			Notifier:              notifier,
		},
	)
	log.Println("indexer started")
	if err := worker.Run(ctx); err != nil {
		log.Fatal(err)
	}
	log.Println("indexer stopped")
}
