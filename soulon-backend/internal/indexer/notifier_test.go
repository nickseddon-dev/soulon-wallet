package indexer

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestWebhookNotifierNotify(t *testing.T) {
	received := false
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, request *http.Request) {
		if request.Method != http.MethodPost {
			t.Fatalf("unexpected method: %s", request.Method)
		}
		if request.Header.Get("authorization") != "Bearer test-token" {
			t.Fatalf("missing auth header")
		}
		received = true
		w.WriteHeader(http.StatusAccepted)
	}))
	defer server.Close()
	notifier, err := NewWebhookNotifier(WebhookNotifierOptions{
		URL:       server.URL,
		TimeoutMs: 1000,
		Retries:   1,
		AuthToken: "test-token",
	})
	if err != nil {
		t.Fatalf("create notifier failed: %v", err)
	}
	err = notifier.Notify(context.Background(), Event{
		ID:         "evt-1",
		Type:       "new_block",
		Height:     11,
		BlockHash:  "h11",
		ParentHash: "h10",
		Payload:    `{"height":11}`,
		ProducedAt: time.Now(),
	})
	if err != nil {
		t.Fatalf("notify failed: %v", err)
	}
	if !received {
		t.Fatal("webhook should receive event")
	}
}

func TestWebhookNotifierNotifyFailure(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
	}))
	defer server.Close()
	notifier, err := NewWebhookNotifier(WebhookNotifierOptions{
		URL:       server.URL,
		TimeoutMs: 1000,
		Retries:   1,
	})
	if err != nil {
		t.Fatalf("create notifier failed: %v", err)
	}
	if err := notifier.Notify(context.Background(), Event{ID: "evt-2", ProducedAt: time.Now()}); err == nil {
		t.Fatal("notify should fail on non-2xx response")
	}
}
