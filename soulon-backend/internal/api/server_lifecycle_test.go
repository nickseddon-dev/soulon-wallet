package api

import (
	"context"
	"errors"
	"net/http"
	"testing"
	"time"
)

func TestServerStartAndShutdown(t *testing.T) {
	server := NewServer("127.0.0.1:0", "testdata/events.jsonl", "file", "", "", 200)
	errCh := make(chan error, 1)
	go func() {
		errCh <- server.Start()
	}()
	time.Sleep(40 * time.Millisecond)
	shutdownCtx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	if err := server.Shutdown(shutdownCtx); err != nil {
		t.Fatalf("shutdown failed: %v", err)
	}
	err := <-errCh
	if err != nil && !errors.Is(err, http.ErrServerClosed) {
		t.Fatalf("start exited with unexpected error: %v", err)
	}
}
