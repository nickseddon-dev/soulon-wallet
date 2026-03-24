package app

import (
	"encoding/json"
	"testing"
	"time"

	"soulon-deep-chain/x/bank"
	"soulon-deep-chain/x/distribution"
	"soulon-deep-chain/x/gov"
	"soulon-deep-chain/x/staking"
)

func TestExecuteTx(t *testing.T) {
	chainApp := NewChainApp()
	genesis := Genesis{
		ChainID:     "soulon-test-1",
		GenesisTime: time.Now().UTC(),
		AppState: AppState{
			Bank: bank.GenesisState{
				Params: bank.Params{
					DefaultSendEnabled: true,
				},
				Balances: []bank.Balance{
					{Address: "alice", Amount: 100},
				},
			},
			Staking: staking.GenesisState{
				Params: staking.Params{
					BondDenom:     "usoul",
					MaxValidators: 100,
					UnbondingTime: "1814400s",
				},
			},
			Distribution: distribution.GenesisState{
				Params: distribution.Params{},
			},
			Gov: gov.GenesisState{
				Params: gov.Params{
					VotingPeriod: "172800s",
					Quorum:       "0.334",
				},
			},
		},
	}
	if err := chainApp.InitFromGenesis(genesis); err != nil {
		t.Fatalf("init from genesis failed: %v", err)
	}
	if _, err := chainApp.ExecuteTx(Tx{
		Type:   TxBankSend,
		From:   "alice",
		To:     "bob",
		Amount: 30,
	}); err != nil {
		t.Fatalf("execute bank send failed: %v", err)
	}
	if chainApp.BankKeeper.Balance("bob") != 30 {
		t.Fatalf("unexpected bob balance: %d", chainApp.BankKeeper.Balance("bob"))
	}
	submitResult, err := chainApp.ExecuteTx(Tx{
		Type:  TxGovSubmit,
		From:  "alice",
		Title: "enable transfer",
	})
	if err != nil {
		t.Fatalf("submit proposal failed: %v", err)
	}
	if _, err := chainApp.ExecuteTx(Tx{
		Type:       TxGovVote,
		ProposalID: submitResult.ProposalID,
		Option:     gov.VoteYes,
		Amount:     60,
	}); err != nil {
		t.Fatalf("vote proposal failed: %v", err)
	}
	tallyResult, err := chainApp.ExecuteTx(Tx{
		Type:        TxGovTally,
		ProposalID:  submitResult.ProposalID,
		VotingPower: 100,
	})
	if err != nil {
		t.Fatalf("tally proposal failed: %v", err)
	}
	if !tallyResult.Accepted {
		t.Fatalf("proposal should be accepted: %+v", tallyResult)
	}
}

func TestExecuteTxValidationError(t *testing.T) {
	chainApp := NewChainApp()
	_, err := chainApp.ExecuteTx(Tx{
		Type: TxBankSend,
		From: "alice",
		To:   "bob",
	})
	if err == nil {
		t.Fatal("expected validation error")
	}
	appErr, ok := err.(*AppError)
	if !ok {
		t.Fatalf("unexpected error type: %T", err)
	}
	if appErr.Code != ErrCodeInvalidField {
		t.Fatalf("unexpected error code: %s", appErr.Code)
	}
}

func TestExecuteTxUnknownType(t *testing.T) {
	chainApp := NewChainApp()
	_, err := chainApp.ExecuteTx(Tx{
		Type: "unknown",
	})
	if err == nil {
		t.Fatal("expected unknown tx type error")
	}
	appErr, ok := err.(*AppError)
	if !ok {
		t.Fatalf("unexpected error type: %T", err)
	}
	if appErr.Code != ErrCodeInvalidTx {
		t.Fatalf("unexpected error code: %s", appErr.Code)
	}
}

func TestExecuteTxResponseSuccess(t *testing.T) {
	chainApp := NewChainApp()
	genesis := Genesis{
		ChainID:     "soulon-test-1",
		GenesisTime: time.Now().UTC(),
		AppState: AppState{
			Bank: bank.GenesisState{
				Params: bank.Params{
					DefaultSendEnabled: true,
				},
				Balances: []bank.Balance{
					{Address: "alice", Amount: 50},
				},
			},
			Staking: staking.GenesisState{
				Params: staking.Params{
					BondDenom:     "usoul",
					MaxValidators: 100,
					UnbondingTime: "1814400s",
				},
			},
			Distribution: distribution.GenesisState{
				Params: distribution.Params{},
			},
			Gov: gov.GenesisState{
				Params: gov.Params{
					VotingPeriod: "172800s",
					Quorum:       "0.334",
				},
			},
		},
	}
	if err := chainApp.InitFromGenesis(genesis); err != nil {
		t.Fatalf("init from genesis failed: %v", err)
	}
	response := chainApp.ExecuteTxResponse(Tx{
		Type:   TxBankSend,
		From:   "alice",
		To:     "bob",
		Amount: 10,
	})
	if response.Code != "OK" || response.Data == nil || response.Error != nil {
		t.Fatalf("unexpected response: %+v", response)
	}
	if response.Version != TxResponseVersion {
		t.Fatalf("unexpected response version: %s", response.Version)
	}
	if response.Meta.TxType != TxBankSend || response.Meta.GeneratedAt == "" {
		t.Fatalf("unexpected response meta: %+v", response.Meta)
	}
	if _, ok := response.Data.(BankSendData); !ok {
		t.Fatalf("unexpected response data type: %T", response.Data)
	}
}

func TestExecuteTxResponseError(t *testing.T) {
	chainApp := NewChainApp()
	response := chainApp.ExecuteTxResponse(Tx{
		Type: TxBankSend,
		From: "alice",
		To:   "bob",
	})
	if response.Code != string(ErrCodeInvalidField) {
		t.Fatalf("unexpected response code: %s", response.Code)
	}
	if response.Version != TxResponseVersion {
		t.Fatalf("unexpected response version: %s", response.Version)
	}
	if response.Meta.TxType != TxBankSend || response.Meta.GeneratedAt == "" {
		t.Fatalf("unexpected response meta: %+v", response.Meta)
	}
	if response.Error == nil || response.Error.Code != ErrCodeInvalidField {
		t.Fatalf("unexpected response error: %+v", response)
	}
}

func TestExecuteTxResponseJSONShape(t *testing.T) {
	chainApp := NewChainApp()
	genesis := Genesis{
		ChainID:     "soulon-test-1",
		GenesisTime: time.Now().UTC(),
		AppState: AppState{
			Bank: bank.GenesisState{
				Params: bank.Params{
					DefaultSendEnabled: true,
				},
				Balances: []bank.Balance{
					{Address: "alice", Amount: 100},
				},
			},
			Staking: staking.GenesisState{
				Params: staking.Params{
					BondDenom:     "usoul",
					MaxValidators: 100,
					UnbondingTime: "1814400s",
				},
			},
			Distribution: distribution.GenesisState{
				Params: distribution.Params{},
			},
			Gov: gov.GenesisState{
				Params: gov.Params{
					VotingPeriod: "172800s",
					Quorum:       "0.334",
				},
			},
		},
	}
	if err := chainApp.InitFromGenesis(genesis); err != nil {
		t.Fatalf("init from genesis failed: %v", err)
	}
	submitResponse := chainApp.ExecuteTxResponse(Tx{
		Type:  TxGovSubmit,
		From:  "alice",
		Title: "shape-check",
	})
	payload, err := json.Marshal(submitResponse)
	if err != nil {
		t.Fatalf("marshal response failed: %v", err)
	}
	var raw map[string]any
	if err := json.Unmarshal(payload, &raw); err != nil {
		t.Fatalf("unmarshal response failed: %v", err)
	}
	data, ok := raw["data"].(map[string]any)
	if !ok {
		t.Fatalf("unexpected response data shape: %#v", raw["data"])
	}
	if raw["version"] != TxResponseVersion {
		t.Fatalf("version missing or invalid: %#v", raw["version"])
	}
	meta, ok := raw["meta"].(map[string]any)
	if !ok {
		t.Fatalf("unexpected meta shape: %#v", raw["meta"])
	}
	if meta["tx_type"] != TxGovSubmit {
		t.Fatalf("unexpected tx_type: %#v", meta["tx_type"])
	}
	if _, exists := meta["generated_at"]; !exists {
		t.Fatalf("generated_at missing in meta: %#v", meta)
	}
	if _, exists := data["proposal_id"]; !exists {
		t.Fatalf("proposal_id missing in data: %#v", data)
	}
	if _, exists := data["ProposalID"]; exists {
		t.Fatalf("unexpected legacy field in data: %#v", data)
	}
}

func TestExecuteTxResponseVersionFallback(t *testing.T) {
	chainApp := NewChainApp()
	response := chainApp.ExecuteTxResponseWithVersion("", Tx{
		Type: TxBankSend,
		From: "alice",
		To:   "bob",
	})
	if response.Version != TxResponseVersion {
		t.Fatalf("unexpected response version: %s", response.Version)
	}
	if response.Meta.RequestedVersion != "" || response.Meta.ResolvedVersion != TxResponseVersion {
		t.Fatalf("unexpected version meta: %+v", response.Meta)
	}
}

func TestExecuteTxResponseInvalidVersion(t *testing.T) {
	chainApp := NewChainApp()
	response := chainApp.ExecuteTxResponseWithVersion("v9", Tx{
		Type:   TxBankSend,
		From:   "alice",
		To:     "bob",
		Amount: 1,
	})
	if response.Code != string(ErrCodeInvalidVersion) {
		t.Fatalf("unexpected response code: %s", response.Code)
	}
	if response.Error == nil || response.Error.Code != ErrCodeInvalidVersion {
		t.Fatalf("unexpected response error: %+v", response)
	}
	if response.Meta.RequestedVersion != "v9" || response.Meta.ResolvedVersion != "" {
		t.Fatalf("unexpected version meta: %+v", response.Meta)
	}
}

func TestExecuteTxResponseVersionMatrix(t *testing.T) {
	chainApp := NewChainApp()
	testCases := []struct {
		name                   string
		version                string
		expectedCode           string
		expectedResolved       string
		expectRequestedVersion string
	}{
		{name: "empty fallback", version: "", expectedCode: string(ErrCodeInvalidField), expectedResolved: TxResponseVersion, expectRequestedVersion: ""},
		{name: "latest fallback", version: TxResponseVersionLatest, expectedCode: string(ErrCodeInvalidField), expectedResolved: TxResponseVersion, expectRequestedVersion: TxResponseVersionLatest},
		{name: "v1 explicit", version: TxResponseVersion, expectedCode: string(ErrCodeInvalidField), expectedResolved: TxResponseVersion, expectRequestedVersion: TxResponseVersion},
		{name: "v2 enabled", version: TxResponseVersionV2, expectedCode: string(ErrCodeInvalidField), expectedResolved: TxResponseVersionV2, expectRequestedVersion: TxResponseVersionV2},
		{name: "v9 invalid", version: "v9", expectedCode: string(ErrCodeInvalidVersion), expectedResolved: "", expectRequestedVersion: "v9"},
	}
	for _, testCase := range testCases {
		response := chainApp.ExecuteTxResponseWithVersion(testCase.version, Tx{
			Type: TxBankSend,
			From: "alice",
			To:   "bob",
		})
		if response.Code != testCase.expectedCode {
			t.Fatalf("%s: unexpected code: %s", testCase.name, response.Code)
		}
		if response.Meta.ResolvedVersion != testCase.expectedResolved {
			t.Fatalf("%s: unexpected resolved version: %s", testCase.name, response.Meta.ResolvedVersion)
		}
		if response.Meta.RequestedVersion != testCase.expectRequestedVersion {
			t.Fatalf("%s: unexpected requested version: %s", testCase.name, response.Meta.RequestedVersion)
		}
	}
}

func TestExecuteTxResponseV2SuccessShape(t *testing.T) {
	chainApp := NewChainApp()
	genesis := Genesis{
		ChainID:     "soulon-test-1",
		GenesisTime: time.Now().UTC(),
		AppState: AppState{
			Bank: bank.GenesisState{
				Params: bank.Params{DefaultSendEnabled: true},
				Balances: []bank.Balance{
					{Address: "alice", Amount: 20},
				},
			},
			Staking: staking.GenesisState{
				Params: staking.Params{
					BondDenom:     "usoul",
					MaxValidators: 100,
					UnbondingTime: "1814400s",
				},
			},
			Distribution: distribution.GenesisState{Params: distribution.Params{}},
			Gov: gov.GenesisState{
				Params: gov.Params{
					VotingPeriod: "172800s",
					Quorum:       "0.334",
				},
			},
		},
	}
	if err := chainApp.InitFromGenesis(genesis); err != nil {
		t.Fatalf("init from genesis failed: %v", err)
	}
	response := chainApp.ExecuteTxResponseWithVersion(TxResponseVersionV2, Tx{
		Type:   TxBankSend,
		From:   "alice",
		To:     "bob",
		Amount: 5,
	})
	if response.Version != TxResponseVersionV2 || response.Status != "ok" {
		t.Fatalf("unexpected v2 response status/version: %+v", response)
	}
	if response.Meta.MetaSchema != TxMetaSchemaV2 || response.Meta.RequestID == "" {
		t.Fatalf("unexpected v2 meta: %+v", response.Meta)
	}
	if response.DataMeta == nil {
		t.Fatalf("unexpected empty v2 data_meta")
	}
	if response.DataMeta.Encoding != "json" || response.DataMeta.PayloadType != TxBankSend {
		t.Fatalf("unexpected v2 data_meta: %+v", response.DataMeta)
	}
}

func TestExecuteTxResponseV1NoStatusField(t *testing.T) {
	chainApp := NewChainApp()
	response := chainApp.ExecuteTxResponseWithVersion(TxResponseVersion, Tx{
		Type: TxBankSend,
		From: "alice",
		To:   "bob",
	})
	if response.Status != "" {
		t.Fatalf("unexpected v1 status: %s", response.Status)
	}
	if response.DataMeta != nil {
		t.Fatalf("unexpected v1 data_meta: %+v", response.DataMeta)
	}
	payload, err := json.Marshal(response)
	if err != nil {
		t.Fatalf("marshal response failed: %v", err)
	}
	var raw map[string]any
	if err := json.Unmarshal(payload, &raw); err != nil {
		t.Fatalf("unmarshal response failed: %v", err)
	}
	if _, exists := raw["status"]; exists {
		t.Fatalf("status should be omitted for v1: %#v", raw)
	}
	if _, exists := raw["data_meta"]; exists {
		t.Fatalf("data_meta should be omitted for v1: %#v", raw)
	}
}

func TestExecuteTxResponseV2DataMetaJSONShape(t *testing.T) {
	chainApp := NewChainApp()
	response := chainApp.ExecuteTxResponseWithVersion(TxResponseVersionV2, Tx{
		Type: TxBankSend,
		From: "alice",
		To:   "bob",
	})
	payload, err := json.Marshal(response)
	if err != nil {
		t.Fatalf("marshal response failed: %v", err)
	}
	var raw map[string]any
	if err := json.Unmarshal(payload, &raw); err != nil {
		t.Fatalf("unmarshal response failed: %v", err)
	}
	dataMeta, ok := raw["data_meta"].(map[string]any)
	if !ok {
		t.Fatalf("unexpected data_meta shape: %#v", raw["data_meta"])
	}
	if dataMeta["encoding"] != "json" {
		t.Fatalf("unexpected data_meta encoding: %#v", dataMeta)
	}
	if dataMeta["payload_type"] != TxBankSend {
		t.Fatalf("unexpected data_meta payload_type: %#v", dataMeta)
	}
	if dataMeta["schema"] != "soulon.tx.data.bank_send.v2" {
		t.Fatalf("unexpected data_meta schema: %#v", dataMeta)
	}
}

func TestExecuteTxResponseV2DataMetaUnknownSchema(t *testing.T) {
	chainApp := NewChainApp()
	response := chainApp.ExecuteTxResponseWithVersion(TxResponseVersionV2, Tx{
		Type: "custom_tx",
	})
	if response.DataMeta == nil {
		t.Fatalf("unexpected empty data_meta")
	}
	if response.DataMeta.Schema != "soulon.tx.data.unknown.v2" {
		t.Fatalf("unexpected unknown schema: %+v", response.DataMeta)
	}
	if response.Code != string(ErrCodeInvalidTx) {
		t.Fatalf("unexpected response code: %s", response.Code)
	}
}

func TestRegisterTxDataSchemaV2(t *testing.T) {
	ResetTxDataSchemaV2Registry()
	defer ResetTxDataSchemaV2Registry()

	if err := RegisterTxDataSchemaV2("custom_tx", "soulon.tx.data.custom_tx.v2"); err != nil {
		t.Fatalf("register schema failed: %v", err)
	}

	chainApp := NewChainApp()
	response := chainApp.ExecuteTxResponseWithVersion(TxResponseVersionV2, Tx{
		Type: "custom_tx",
	})
	if response.DataMeta == nil {
		t.Fatalf("unexpected empty data_meta")
	}
	if response.DataMeta.Schema != "soulon.tx.data.custom_tx.v2" {
		t.Fatalf("unexpected registered schema: %+v", response.DataMeta)
	}
}

func TestRegisterTxDataSchemaV2Validation(t *testing.T) {
	if err := RegisterTxDataSchemaV2("", "soulon.tx.data.any.v2"); err == nil {
		t.Fatal("expected validation error for empty tx type")
	}
	if err := RegisterTxDataSchemaV2("any_tx", ""); err == nil {
		t.Fatal("expected validation error for empty schema")
	}
}
