package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"soulon-backend/internal/config"
	"soulon-backend/internal/gateway"
	"syscall"
	"time"
)

func main() {
	cfg, err := config.LoadGatewayConfigFromEnv()
	if err != nil {
		log.Fatal(err)
	}
	server := gateway.NewServer(
		cfg.ListenAddr,
		cfg.NodeEndpoints,
		cfg.HealthCheckInterval,
		cfg.ForwardTimeout,
	)
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)
	defer signal.Stop(stop)
	errCh := make(chan error, 1)
	go func() {
		log.Printf("gateway listening on %s", cfg.ListenAddr)
		errCh <- server.Start()
	}()
	select {
	case err := <-errCh:
		if err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatal(err)
		}
	case sig := <-stop:
		log.Printf("gateway received signal: %s", sig.String())
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 8*time.Second)
		defer cancel()
		if err := server.Shutdown(shutdownCtx); err != nil {
			log.Fatal(err)
		}
		if err := <-errCh; err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatal(err)
		}
		log.Print("gateway shutdown completed")
	}
}
