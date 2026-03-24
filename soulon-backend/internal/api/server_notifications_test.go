package api

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestNotificationWebhookAndList(t *testing.T) {
	server := NewServer(":0", "testdata/events.jsonl", "file", "", "token-123", 2)
	postBody := bytes.NewBufferString(`{"id":"evt-1","type":"new_block","height":1,"blockHash":"h1","payload":"{}","producedAt":"2026-03-04T00:00:00Z","persistedAt":"2026-03-04T00:00:01Z"}`)
	request := httptest.NewRequest(http.MethodPost, "/v1/notifications/webhook", postBody)
	request.Header.Set("authorization", "Bearer token-123")
	recorder := httptest.NewRecorder()
	server.http.Handler.ServeHTTP(recorder, request)
	if recorder.Code != http.StatusOK {
		t.Fatalf("unexpected webhook status: %d body=%s", recorder.Code, recorder.Body.String())
	}
	listRequest := httptest.NewRequest(http.MethodGet, "/v1/notifications?limit=20&offset=0", nil)
	listRecorder := httptest.NewRecorder()
	server.http.Handler.ServeHTTP(listRecorder, listRequest)
	if listRecorder.Code != http.StatusOK {
		t.Fatalf("unexpected list status: %d body=%s", listRecorder.Code, listRecorder.Body.String())
	}
	var response struct {
		Notifications []notificationMessage `json:"notifications"`
		Total         int                   `json:"total"`
	}
	if err := json.Unmarshal(listRecorder.Body.Bytes(), &response); err != nil {
		t.Fatalf("decode list response failed: %v", err)
	}
	if response.Total != 1 || len(response.Notifications) != 1 {
		t.Fatalf("unexpected list payload: %+v", response)
	}
	if response.Notifications[0].ID != "evt-1" {
		t.Fatalf("unexpected notification: %+v", response.Notifications[0])
	}
}

func TestNotificationWebhookUnauthorized(t *testing.T) {
	server := NewServer(":0", "testdata/events.jsonl", "file", "", "token-123", 10)
	request := httptest.NewRequest(
		http.MethodPost,
		"/v1/notifications/webhook",
		bytes.NewBufferString(`{"id":"evt-2","type":"new_block","height":2,"payload":"{}"}`),
	)
	recorder := httptest.NewRecorder()
	server.http.Handler.ServeHTTP(recorder, request)
	if recorder.Code != http.StatusUnauthorized {
		t.Fatalf("unexpected status: %d", recorder.Code)
	}
}

func TestNotificationCapacityLimit(t *testing.T) {
	server := NewServer(":0", "testdata/events.jsonl", "file", "", "", 2)
	for _, id := range []string{"evt-1", "evt-2", "evt-3"} {
		request := httptest.NewRequest(
			http.MethodPost,
			"/v1/notifications/webhook",
			bytes.NewBufferString(`{"id":"`+id+`","type":"new_block","height":1,"payload":"{}"}`),
		)
		recorder := httptest.NewRecorder()
		server.http.Handler.ServeHTTP(recorder, request)
		if recorder.Code != http.StatusOK {
			t.Fatalf("unexpected webhook status: %d", recorder.Code)
		}
	}
	listRequest := httptest.NewRequest(http.MethodGet, "/v1/notifications?limit=10&offset=0", nil)
	listRecorder := httptest.NewRecorder()
	server.http.Handler.ServeHTTP(listRecorder, listRequest)
	var response struct {
		Notifications []notificationMessage `json:"notifications"`
		Total         int                   `json:"total"`
	}
	if err := json.Unmarshal(listRecorder.Body.Bytes(), &response); err != nil {
		t.Fatalf("decode list response failed: %v", err)
	}
	if response.Total != 2 {
		t.Fatalf("total mismatch: %d", response.Total)
	}
	if len(response.Notifications) != 2 {
		t.Fatalf("notifications mismatch: %d", len(response.Notifications))
	}
	if response.Notifications[0].ID != "evt-3" || response.Notifications[1].ID != "evt-2" {
		t.Fatalf("unexpected order: %+v", response.Notifications)
	}
}

func TestNotificationStreamMethodNotAllowed(t *testing.T) {
	server := NewServer(":0", "testdata/events.jsonl", "file", "", "", 2)
	request := httptest.NewRequest(http.MethodPost, "/v1/notifications/stream", nil)
	recorder := httptest.NewRecorder()
	server.http.Handler.ServeHTTP(recorder, request)
	if recorder.Code != http.StatusMethodNotAllowed {
		t.Fatalf("unexpected status: %d", recorder.Code)
	}
}

func TestNotificationStreamUnauthorized(t *testing.T) {
	server := NewServer(":0", "testdata/events.jsonl", "file", "", "token-123", 2)
	request := httptest.NewRequest(http.MethodGet, "/v1/notifications/stream", nil)
	recorder := httptest.NewRecorder()
	server.http.Handler.ServeHTTP(recorder, request)
	if recorder.Code != http.StatusUnauthorized {
		t.Fatalf("unexpected status: %d", recorder.Code)
	}
}

func TestPushNotificationBroadcast(t *testing.T) {
	server := NewServer(":0", "testdata/events.jsonl", "file", "", "", 4)
	subscriberID, streamCh := server.addSubscriber()
	defer server.removeSubscriber(subscriberID)
	message := notificationMessage{
		ID:         "evt-9",
		Type:       "new_block",
		Height:     9,
		Payload:    "{}",
		ProducedAt: time.Now().UTC(),
		ReceivedAt: time.Now().UTC(),
	}
	server.pushNotification(message)
	select {
	case pushed := <-streamCh:
		if pushed.ID != "evt-9" {
			t.Fatalf("unexpected pushed message: %+v", pushed)
		}
	case <-time.After(300 * time.Millisecond):
		t.Fatal("subscriber should receive notification")
	}
	snapshot := server.snapshotNotifications()
	if len(snapshot) != 1 || snapshot[0].ID != "evt-9" {
		t.Fatalf("unexpected snapshot: %+v", snapshot)
	}
}

func TestSnapshotLatestNotifications(t *testing.T) {
	server := NewServer(":0", "testdata/events.jsonl", "file", "", "", 5)
	for _, id := range []string{"evt-1", "evt-2", "evt-3"} {
		server.pushNotification(notificationMessage{
			ID:         id,
			Type:       "new_block",
			Payload:    "{}",
			ProducedAt: time.Now().UTC(),
			ReceivedAt: time.Now().UTC(),
		})
	}
	latest := server.snapshotLatestNotifications(2)
	if len(latest) != 2 {
		t.Fatalf("unexpected latest size: %d", len(latest))
	}
	if latest[0].ID != "evt-3" || latest[1].ID != "evt-2" {
		t.Fatalf("unexpected latest order: %+v", latest)
	}
}
