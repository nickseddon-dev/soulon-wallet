package api

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"soulon-backend/internal/indexer"
	"testing"
)

func TestParseEventQuery(t *testing.T) {
	request := httptest.NewRequest("GET", "/v1/indexer/events?limit=10&offset=1&order=asc&type=new_block&minHeight=2&maxHeight=5", nil)
	query, err := parseEventQuery(request)
	if err != nil {
		t.Fatalf("parse should succeed: %v", err)
	}
	if query.limit != 10 {
		t.Fatalf("limit mismatch: %d", query.limit)
	}
	if query.offset != 1 {
		t.Fatalf("offset mismatch: %d", query.offset)
	}
	if query.order != "asc" {
		t.Fatalf("order mismatch: %s", query.order)
	}
	if query.eventType != "new_block" {
		t.Fatalf("type mismatch: %s", query.eventType)
	}
	if !query.hasMin || query.minHeight != 2 {
		t.Fatalf("minHeight mismatch: %+v", query)
	}
	if !query.hasMax || query.maxHeight != 5 {
		t.Fatalf("maxHeight mismatch: %+v", query)
	}
}

func TestParseEventQueryInvalidLimit(t *testing.T) {
	request := httptest.NewRequest("GET", "/v1/indexer/events?limit=0", nil)
	_, err := parseEventQuery(request)
	if err == nil {
		t.Fatal("invalid limit should fail")
	}
}

func TestParseEventQueryInvalidHeightRange(t *testing.T) {
	request := httptest.NewRequest("GET", "/v1/indexer/events?minHeight=5&maxHeight=2", nil)
	_, err := parseEventQuery(request)
	if err == nil {
		t.Fatal("invalid height range should fail")
	}
}

func TestFilterAndSelectEvents(t *testing.T) {
	events := []indexer.Event{
		{Height: 1, Type: "new_block", ID: "e1"},
		{Height: 2, Type: "new_block", ID: "e2"},
		{Height: 3, Type: "rollback", ID: "e3"},
		{Height: 4, Type: "new_block", ID: "e4"},
	}
	query := eventQuery{
		limit:     2,
		offset:    0,
		order:     "desc",
		eventType: "new_block",
		minHeight: 2,
		hasMin:    true,
	}
	filtered := filterEvents(events, query)
	if len(filtered) != 2 {
		t.Fatalf("filtered count mismatch: %d", len(filtered))
	}
	selected, hasMore := selectEvents(filtered, query)
	if len(selected) != 2 {
		t.Fatalf("selected count mismatch: %d", len(selected))
	}
	if hasMore {
		t.Fatal("hasMore mismatch")
	}
	if selected[0].ID != "e4" || selected[1].ID != "e2" {
		t.Fatalf("selection mismatch: %+v", selected)
	}
}

func TestSelectEventsWithOffset(t *testing.T) {
	events := []indexer.Event{
		{Height: 1, Type: "new_block", ID: "e1"},
		{Height: 2, Type: "new_block", ID: "e2"},
		{Height: 3, Type: "new_block", ID: "e3"},
		{Height: 4, Type: "new_block", ID: "e4"},
	}
	query := eventQuery{
		limit:  2,
		offset: 1,
		order:  "desc",
	}
	selected, hasMore := selectEvents(events, query)
	if len(selected) != 2 {
		t.Fatalf("selected count mismatch: %d", len(selected))
	}
	if !hasMore {
		t.Fatal("hasMore mismatch")
	}
	if selected[0].ID != "e3" || selected[1].ID != "e2" {
		t.Fatalf("selection mismatch: %+v", selected)
	}
}

func TestFindEventByID(t *testing.T) {
	events := []indexer.Event{
		{ID: "e1", Height: 1, Type: "new_block"},
		{ID: "e2", Height: 2, Type: "new_block"},
		{ID: "e1", Height: 3, Type: "new_block"},
	}
	event, found := findEventByID(events, "e1")
	if !found {
		t.Fatal("event should be found")
	}
	if event.Height != 3 {
		t.Fatalf("expected latest event by id, got %+v", event)
	}
}

func TestHandleIndexerEventByID(t *testing.T) {
	tempDir := t.TempDir()
	eventStorePath := filepath.Join(tempDir, "events.log")
	lines := []string{
		`{"id":"e1","height":1,"type":"new_block","payload":"{}","producedAt":"2026-03-04T00:00:00Z"}`,
		`{"id":"e2","height":2,"type":"new_block","payload":"{\"order\":2}","producedAt":"2026-03-04T00:01:00Z"}`,
	}
	if err := os.WriteFile(eventStorePath, []byte(lines[0]+"\n"+lines[1]+"\n"), 0o600); err != nil {
		t.Fatalf("write event store failed: %v", err)
	}
	server := NewServer(":0", eventStorePath, "file", "", "", 200)
	request := httptest.NewRequest(http.MethodGet, "/v1/indexer/events/e2", nil)
	recorder := httptest.NewRecorder()

	server.http.Handler.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("unexpected status: %d, body: %s", recorder.Code, recorder.Body.String())
	}
	var response struct {
		Event indexer.Event `json:"event"`
	}
	if err := json.Unmarshal(recorder.Body.Bytes(), &response); err != nil {
		t.Fatalf("decode response failed: %v", err)
	}
	if response.Event.ID != "e2" {
		t.Fatalf("event id mismatch: %+v", response.Event)
	}
}

func TestHandleIndexerEventByIDNotFound(t *testing.T) {
	tempDir := t.TempDir()
	eventStorePath := filepath.Join(tempDir, "events.log")
	if err := os.WriteFile(eventStorePath, []byte(`{"id":"e1","height":1,"type":"new_block","payload":"{}","producedAt":"2026-03-04T00:00:00Z"}`), 0o600); err != nil {
		t.Fatalf("write event store failed: %v", err)
	}
	server := NewServer(":0", eventStorePath, "file", "", "", 200)
	request := httptest.NewRequest(http.MethodGet, "/v1/indexer/events/missing", nil)
	recorder := httptest.NewRecorder()

	server.http.Handler.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusNotFound {
		t.Fatalf("unexpected status: %d", recorder.Code)
	}
}
