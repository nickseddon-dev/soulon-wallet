package app

import (
	"fmt"
	"sync"
	"time"
)

const TxResponseVersion = "v1"
const TxResponseVersionLatest = "latest"
const TxResponseVersionV2 = "v2"
const TxMetaSchemaV2 = "soulon.tx.meta.v2"

var defaultTxDataSchemaV2Registry = map[string]string{
	TxBankSend:          "soulon.tx.data.bank_send.v2",
	TxStakingDelegate:   "soulon.tx.data.staking_delegate.v2",
	TxStakingRedelegate: "soulon.tx.data.staking_redelegate.v2",
	TxGovSubmit:         "soulon.tx.data.gov_submit.v2",
	TxGovVote:           "soulon.tx.data.gov_vote.v2",
	TxGovTally:          "soulon.tx.data.gov_tally.v2",
	TxRewardsAdd:        "soulon.tx.data.rewards_add.v2",
	TxRewardsClaim:      "soulon.tx.data.rewards_claim.v2",
}

var txDataSchemaV2RegistryMu sync.RWMutex
var txDataSchemaV2Registry = cloneSchemaRegistry(defaultTxDataSchemaV2Registry)

type TxMeta struct {
	TxType           string `json:"tx_type"`
	RequestedVersion string `json:"requested_version"`
	ResolvedVersion  string `json:"resolved_version"`
	GeneratedAt      string `json:"generated_at"`
	MetaSchema       string `json:"meta_schema,omitempty"`
	RequestID        string `json:"request_id,omitempty"`
}

type BankSendData struct {
	Message string `json:"message"`
}

type StakingDelegateData struct {
	Message string `json:"message"`
}

type StakingRedelegateData struct {
	Message string `json:"message"`
}

type GovSubmitData struct {
	Message    string `json:"message"`
	ProposalID uint64 `json:"proposal_id"`
}

type GovVoteData struct {
	Message string `json:"message"`
}

type GovTallyData struct {
	Message   string `json:"message"`
	Accepted  bool   `json:"accepted"`
	QuorumMet bool   `json:"quorum_met"`
}

type RewardsAddData struct {
	Message string `json:"message"`
}

type RewardsClaimData struct {
	Message       string `json:"message"`
	ClaimedReward int64  `json:"claimed_reward"`
}

type TxError struct {
	Code    ErrorCode `json:"code"`
	Message string    `json:"message"`
}

type TxResponse struct {
	Version  string      `json:"version"`
	Code     string      `json:"code"`
	Message  string      `json:"message"`
	Status   string      `json:"status,omitempty"`
	Meta     TxMeta      `json:"meta"`
	DataMeta *TxDataMeta `json:"data_meta,omitempty"`
	Data     any         `json:"data,omitempty"`
	Error    *TxError    `json:"error,omitempty"`
}

type TxDataMeta struct {
	Schema      string `json:"schema"`
	Encoding    string `json:"encoding"`
	PayloadType string `json:"payload_type"`
}

func (a *ChainApp) ExecuteTxResponse(tx Tx) TxResponse {
	return a.ExecuteTxResponseWithVersion(TxResponseVersionLatest, tx)
}

func ValidateTxResponseVersion(version string) error {
	_, err := resolveTxResponseVersion(version)
	return err
}

func RegisterTxDataSchemaV2(txType string, schema string) error {
	if txType == "" {
		return newInvalidFieldError("tx type is required")
	}
	if schema == "" {
		return newInvalidFieldError("schema is required")
	}
	txDataSchemaV2RegistryMu.Lock()
	txDataSchemaV2Registry[txType] = schema
	txDataSchemaV2RegistryMu.Unlock()
	return nil
}

func ResetTxDataSchemaV2Registry() {
	txDataSchemaV2RegistryMu.Lock()
	txDataSchemaV2Registry = cloneSchemaRegistry(defaultTxDataSchemaV2Registry)
	txDataSchemaV2RegistryMu.Unlock()
}

func (a *ChainApp) ExecuteTxResponseWithVersion(version string, tx Tx) TxResponse {
	meta := newTxMeta(tx.Type, version)
	resolvedVersion, err := resolveTxResponseVersion(version)
	if err != nil {
		return TxResponse{
			Version:  TxResponseVersion,
			Code:     string(ErrCodeInvalidVersion),
			Message:  "failed",
			Status:   resolveResponseStatus(resolvedVersion, false),
			Meta:     meta,
			DataMeta: resolveResponseDataMeta(resolvedVersion, tx.Type),
			Error: &TxError{
				Code:    ErrCodeInvalidVersion,
				Message: err.Error(),
			},
		}
	}
	meta.ResolvedVersion = resolvedVersion
	result, err := a.ExecuteTx(tx)
	if err == nil {
		return TxResponse{
			Version:  resolvedVersion,
			Code:     "OK",
			Message:  "success",
			Status:   resolveResponseStatus(resolvedVersion, true),
			Meta:     meta,
			DataMeta: resolveResponseDataMeta(resolvedVersion, tx.Type),
			Data:     toTxResponseData(tx.Type, result),
		}
	}
	if appErr, ok := err.(*AppError); ok {
		return TxResponse{
			Version:  resolvedVersion,
			Code:     string(appErr.Code),
			Message:  "failed",
			Status:   resolveResponseStatus(resolvedVersion, false),
			Meta:     meta,
			DataMeta: resolveResponseDataMeta(resolvedVersion, tx.Type),
			Error: &TxError{
				Code:    appErr.Code,
				Message: appErr.Message,
			},
		}
	}
	return TxResponse{
		Version:  resolvedVersion,
		Code:     string(ErrCodeExecutionFailed),
		Message:  "failed",
		Status:   resolveResponseStatus(resolvedVersion, false),
		Meta:     meta,
		DataMeta: resolveResponseDataMeta(resolvedVersion, tx.Type),
		Error: &TxError{
			Code:    ErrCodeExecutionFailed,
			Message: err.Error(),
		},
	}
}

func newTxMeta(txType string, requestedVersion string) TxMeta {
	meta := TxMeta{
		TxType:           txType,
		RequestedVersion: requestedVersion,
		GeneratedAt:      time.Now().UTC().Format(time.RFC3339Nano),
	}
	if requestedVersion == TxResponseVersionV2 {
		meta.MetaSchema = TxMetaSchemaV2
		meta.RequestID = fmt.Sprintf("req-%d", time.Now().UTC().UnixNano())
	}
	return meta
}

func resolveTxResponseVersion(version string) (string, error) {
	if version == "" || version == TxResponseVersionLatest {
		return TxResponseVersion, nil
	}
	if version == TxResponseVersion {
		return TxResponseVersion, nil
	}
	if version == TxResponseVersionV2 {
		return TxResponseVersionV2, nil
	}
	return "", fmt.Errorf("unsupported response version: %s", version)
}

func resolveResponseStatus(version string, success bool) string {
	if version != TxResponseVersionV2 {
		return ""
	}
	if success {
		return "ok"
	}
	return "error"
}

func resolveResponseDataMeta(version string, txType string) *TxDataMeta {
	if version != TxResponseVersionV2 {
		return nil
	}
	return &TxDataMeta{
		Schema:      resolveTxDataSchemaV2(txType),
		Encoding:    "json",
		PayloadType: txType,
	}
}

func resolveTxDataSchemaV2(txType string) string {
	txDataSchemaV2RegistryMu.RLock()
	if schema, exists := txDataSchemaV2Registry[txType]; exists {
		txDataSchemaV2RegistryMu.RUnlock()
		return schema
	}
	txDataSchemaV2RegistryMu.RUnlock()
	return "soulon.tx.data.unknown.v2"
}

func cloneSchemaRegistry(source map[string]string) map[string]string {
	target := make(map[string]string, len(source))
	for key, value := range source {
		target[key] = value
	}
	return target
}

func toTxResponseData(txType string, result TxResult) any {
	switch txType {
	case TxBankSend:
		return BankSendData{
			Message: result.Message,
		}
	case TxStakingDelegate:
		return StakingDelegateData{
			Message: result.Message,
		}
	case TxStakingRedelegate:
		return StakingRedelegateData{
			Message: result.Message,
		}
	case TxGovSubmit:
		return GovSubmitData{
			Message:    result.Message,
			ProposalID: result.ProposalID,
		}
	case TxGovVote:
		return GovVoteData{
			Message: result.Message,
		}
	case TxGovTally:
		return GovTallyData{
			Message:   result.Message,
			Accepted:  result.Accepted,
			QuorumMet: result.QuorumMet,
		}
	case TxRewardsAdd:
		return RewardsAddData{
			Message: result.Message,
		}
	case TxRewardsClaim:
		return RewardsClaimData{
			Message:       result.Message,
			ClaimedReward: result.ClaimedReward,
		}
	default:
		return map[string]any{
			"message":        result.Message,
			"proposal_id":    result.ProposalID,
			"accepted":       result.Accepted,
			"quorum_met":     result.QuorumMet,
			"claimed_reward": result.ClaimedReward,
		}
	}
}
