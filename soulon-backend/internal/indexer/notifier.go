package indexer

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"
)

type Notifier interface {
	Notify(ctx context.Context, event Event) error
}

type NoopNotifier struct{}

func (NoopNotifier) Notify(_ context.Context, _ Event) error {
	return nil
}

type WebhookNotifierOptions struct {
	URL       string
	TimeoutMs int
	Retries   int
	AuthToken string
}

type WebhookNotifier struct {
	client    *http.Client
	url       string
	retries   int
	authToken string
}

func NewWebhookNotifier(options WebhookNotifierOptions) (*WebhookNotifier, error) {
	url := strings.TrimSpace(options.URL)
	if url == "" {
		return nil, fmt.Errorf("webhook url is empty")
	}
	timeoutMs := options.TimeoutMs
	if timeoutMs <= 0 {
		timeoutMs = 3000
	}
	retries := options.Retries
	if retries < 0 {
		retries = 0
	}
	return &WebhookNotifier{
		client: &http.Client{
			Timeout: time.Duration(timeoutMs) * time.Millisecond,
		},
		url:       url,
		retries:   retries,
		authToken: strings.TrimSpace(options.AuthToken),
	}, nil
}

func (n *WebhookNotifier) Notify(ctx context.Context, event Event) error {
	payload, err := json.Marshal(map[string]any{
		"id":          event.ID,
		"type":        event.Type,
		"height":      event.Height,
		"blockHash":   event.BlockHash,
		"parentHash":  event.ParentHash,
		"payload":     event.Payload,
		"producedAt":  event.ProducedAt,
		"persistedAt": event.PersistedAt,
	})
	if err != nil {
		return err
	}
	var lastErr error
	for attempt := 0; attempt <= n.retries; attempt++ {
		req, reqErr := http.NewRequestWithContext(ctx, http.MethodPost, n.url, bytes.NewReader(payload))
		if reqErr != nil {
			return reqErr
		}
		req.Header.Set("content-type", "application/json")
		if n.authToken != "" {
			req.Header.Set("authorization", "Bearer "+n.authToken)
		}
		response, doErr := n.client.Do(req)
		if doErr == nil {
			_ = response.Body.Close()
			if response.StatusCode >= 200 && response.StatusCode < 300 {
				return nil
			}
			doErr = fmt.Errorf("unexpected webhook status: %d", response.StatusCode)
		}
		lastErr = doErr
		if attempt < n.retries {
			select {
			case <-ctx.Done():
				return ctx.Err()
			case <-time.After(time.Duration(attempt+1) * 200 * time.Millisecond):
			}
		}
	}
	return lastErr
}
