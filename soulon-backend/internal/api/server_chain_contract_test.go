package api

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestChainAPIProxyRoutes(t *testing.T) {
	var upstreamMethod string
	var upstreamPath string
	var upstreamQuery string
	var upstreamBody string
	upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, request *http.Request) {
		upstreamMethod = request.Method
		upstreamPath = request.URL.Path
		upstreamQuery = request.URL.RawQuery
		payload, _ := io.ReadAll(request.Body)
		upstreamBody = string(payload)
		w.Header().Set("content-type", "application/json")
		_, _ = w.Write([]byte(`{"ok":true}`))
	}))
	defer upstream.Close()
	t.Setenv("API_CHAIN_REST_ENDPOINT", upstream.URL)
	server := NewServer(":0", "testdata/events.jsonl", "file", "", "", 200)

	request := httptest.NewRequest(http.MethodGet, "/v1/chain/staking/validators?status=BOND_STATUS_BONDED", nil)
	recorder := httptest.NewRecorder()
	server.http.Handler.ServeHTTP(recorder, request)
	if recorder.Code != http.StatusOK {
		t.Fatalf("validators status mismatch: %d, body: %s", recorder.Code, recorder.Body.String())
	}
	if upstreamMethod != http.MethodGet {
		t.Fatalf("validators method mismatch: %s", upstreamMethod)
	}
	if upstreamPath != "/cosmos/staking/v1beta1/validators" {
		t.Fatalf("validators path mismatch: %s", upstreamPath)
	}
	if upstreamQuery != "status=BOND_STATUS_BONDED" {
		t.Fatalf("validators query mismatch: %s", upstreamQuery)
	}

	request = httptest.NewRequest(http.MethodGet, "/v1/chain/gov/proposals/11/votes?pagination.limit=20", nil)
	recorder = httptest.NewRecorder()
	server.http.Handler.ServeHTTP(recorder, request)
	if recorder.Code != http.StatusOK {
		t.Fatalf("votes status mismatch: %d, body: %s", recorder.Code, recorder.Body.String())
	}
	if upstreamPath != "/cosmos/gov/v1beta1/proposals/11/votes" {
		t.Fatalf("votes path mismatch: %s", upstreamPath)
	}
	if upstreamQuery != "pagination.limit=20" {
		t.Fatalf("votes query mismatch: %s", upstreamQuery)
	}

	request = httptest.NewRequest(http.MethodPost, "/v1/chain/txs", bytes.NewBufferString(`{"tx_bytes":"AA==","mode":"BROADCAST_MODE_SYNC"}`))
	recorder = httptest.NewRecorder()
	server.http.Handler.ServeHTTP(recorder, request)
	if recorder.Code != http.StatusOK {
		t.Fatalf("broadcast status mismatch: %d, body: %s", recorder.Code, recorder.Body.String())
	}
	if upstreamMethod != http.MethodPost {
		t.Fatalf("broadcast method mismatch: %s", upstreamMethod)
	}
	if upstreamPath != "/cosmos/tx/v1beta1/txs" {
		t.Fatalf("broadcast path mismatch: %s", upstreamPath)
	}
	if !strings.Contains(upstreamBody, `"tx_bytes":"AA=="`) {
		t.Fatalf("broadcast body mismatch: %s", upstreamBody)
	}
}

func TestWalletAPIContractRouteConsistency(t *testing.T) {
	upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("content-type", "application/json")
		_, _ = w.Write([]byte(`{"ok":true}`))
	}))
	defer upstream.Close()
	t.Setenv("API_CHAIN_REST_ENDPOINT", upstream.URL)

	contractPath := filepath.Join("..", "..", "contracts", "wallet-api-v1.json")
	content, err := os.ReadFile(contractPath)
	if err != nil {
		t.Fatalf("read contract failed: %v", err)
	}
	var contract walletAPIContract
	if err := json.Unmarshal(content, &contract); err != nil {
		t.Fatalf("parse contract failed: %v", err)
	}

	server := NewServer(":0", "testdata/events.jsonl", "file", "", "", 200)
	for _, endpoint := range contract.Endpoints {
		path := endpoint.Path
		path = strings.ReplaceAll(path, "{delegatorAddress}", "soulon1testdelegator")
		path = strings.ReplaceAll(path, "{proposalId}", "11")
		path = strings.ReplaceAll(path, "{txHash}", "AABBCCDD")
		var body *bytes.Buffer
		if endpoint.Method == http.MethodPost {
			body = bytes.NewBufferString(`{}`)
		} else {
			body = bytes.NewBuffer(nil)
		}
		request := httptest.NewRequest(endpoint.Method, path, body)
		if endpoint.Path == "/v1/notifications/stream" {
			requestContext, cancel := context.WithCancel(request.Context())
			cancel()
			request = request.WithContext(requestContext)
		}
		recorder := httptest.NewRecorder()
		server.http.Handler.ServeHTTP(recorder, request)
		if recorder.Code == http.StatusNotFound || recorder.Code == http.StatusMethodNotAllowed {
			t.Fatalf("contract endpoint is not routable: %s %s => %d", endpoint.Method, endpoint.Path, recorder.Code)
		}
	}
}
