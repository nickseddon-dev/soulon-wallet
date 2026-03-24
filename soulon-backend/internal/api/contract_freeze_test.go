package api

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
)

type contractEndpoint struct {
	Method string `json:"method"`
	Path   string `json:"path"`
}

type walletAPIContract struct {
	Version   string             `json:"version"`
	Frozen    bool               `json:"frozen"`
	Endpoints []contractEndpoint `json:"endpoints"`
}

func TestWalletAPIContractFrozen(t *testing.T) {
	contractPath := filepath.Join("..", "..", "contracts", "wallet-api-v1.json")
	content, err := os.ReadFile(contractPath)
	if err != nil {
		t.Fatalf("read contract failed: %v", err)
	}
	var contract walletAPIContract
	if err := json.Unmarshal(content, &contract); err != nil {
		t.Fatalf("parse contract failed: %v", err)
	}
	if contract.Version != "v1.4.0" {
		t.Fatalf("unexpected contract version: %s", contract.Version)
	}
	if !contract.Frozen {
		t.Fatal("contract must be frozen")
	}
	expected := map[string]struct{}{
		"GET /v1/health":                                                   {},
		"GET /v1/indexer/events":                                           {},
		"GET /v1/indexer/state":                                            {},
		"GET /v1/chain/staking/validators":                                 {},
		"GET /v1/chain/staking/delegations/{delegatorAddress}":             {},
		"GET /v1/chain/distribution/delegators/{delegatorAddress}/rewards": {},
		"GET /v1/chain/gov/proposals":                                      {},
		"GET /v1/chain/gov/proposals/{proposalId}":                         {},
		"GET /v1/chain/gov/proposals/{proposalId}/votes":                   {},
		"GET /v1/chain/txs/{txHash}":                                       {},
		"POST /v1/chain/txs":                                               {},
		"POST /v1/auth/signature/challenge":                                {},
		"POST /v1/auth/signature/confirm":                                  {},
		"GET /v1/notifications":                                            {},
		"GET /v1/notifications/stream":                                     {},
		"POST /v1/notifications/webhook":                                   {},
	}
	got := map[string]struct{}{}
	for _, endpoint := range contract.Endpoints {
		key := endpoint.Method + " " + endpoint.Path
		got[key] = struct{}{}
	}
	if len(got) != len(expected) {
		t.Fatalf("contract endpoint count mismatch: got=%d want=%d", len(got), len(expected))
	}
	for key := range expected {
		if _, exists := got[key]; !exists {
			t.Fatalf("missing endpoint in contract: %s", key)
		}
	}
}
