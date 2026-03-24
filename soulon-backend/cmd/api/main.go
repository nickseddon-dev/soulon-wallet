package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"soulon-backend/internal/api"
	"soulon-backend/internal/config"
	"syscall"
	"time"
)

func main() {
	cfg, err := config.LoadAPIConfigFromEnv()
	if err != nil {
		log.Fatal(err)
	}
	server := api.NewServer(
		cfg.ListenAddr,
		cfg.EventStorePath,
		cfg.StoreBackend,
		cfg.PostgresDSN,
		cfg.NotifyWebhookToken,
		cfg.NotificationCapacity,
	)
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)
	defer signal.Stop(stop)
	errCh := make(chan error, 1)
	go func() {
		log.Printf("api listening on %s", cfg.ListenAddr)
		errCh <- server.Start()
	}()
	select {
	case err := <-errCh:
		if err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatal(err)
		}
	case sig := <-stop:
		log.Printf("api received signal: %s", sig.String())
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 8*time.Second)
		defer cancel()
		if err := server.Shutdown(shutdownCtx); err != nil {
			log.Fatal(err)
		}
		if err := <-errCh; err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatal(err)
		}
		log.Print("api shutdown completed")
	}
}
