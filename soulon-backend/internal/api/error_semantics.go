package api

import (
	"encoding/json"
	"net/http"
	"strings"
)

const (
	errorCodeInvalidArgument   = "INVALID_ARGUMENT"
	errorCodeUnauthorized      = "UNAUTHORIZED"
	errorCodeForbidden         = "FORBIDDEN"
	errorCodeNotFound          = "NOT_FOUND"
	errorCodeMethodNotAllowed  = "METHOD_NOT_ALLOWED"
	errorCodeChainUnavailable  = "CHAIN_UNAVAILABLE"
	errorCodeInsufficientFunds = "INSUFFICIENT_FUNDS"
	errorCodeOutOfGas          = "OUT_OF_GAS"
	errorCodeInvalidSequence   = "INVALID_SEQUENCE"
	errorCodeTxRejected        = "TX_REJECTED"
	errorCodeInternal          = "INTERNAL_ERROR"
)

type apiErrorPayload struct {
	Code      string `json:"code"`
	Message   string `json:"message"`
	Status    int    `json:"status"`
	Retryable bool   `json:"retryable"`
}

func writeAPIError(w http.ResponseWriter, status int, code string, message string, retryable bool) {
	w.Header().Set("content-type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(apiErrorPayload{
		Code:      code,
		Message:   strings.TrimSpace(message),
		Status:    status,
		Retryable: retryable,
	})
}

func mapChainProxyError(status int, body []byte) (string, string, bool) {
	message := extractErrorMessage(body)
	normalized := strings.ToLower(message)
	if strings.TrimSpace(normalized) == "" {
		normalized = strings.ToLower(string(body))
	}
	if containsOneOf(normalized, []string{"insufficient funds", "spendable balance", "余额不足", "资金不足"}) {
		return errorCodeInsufficientFunds, fallbackMessage(message, "insufficient funds"), false
	}
	if containsOneOf(normalized, []string{"out of gas", "gas wanted", "gas不足", "燃料不足"}) {
		return errorCodeOutOfGas, fallbackMessage(message, "out of gas"), false
	}
	if containsOneOf(normalized, []string{"invalid account sequence", "account sequence mismatch", "sequence", "nonce"}) {
		return errorCodeInvalidSequence, fallbackMessage(message, "invalid account sequence"), true
	}
	if containsOneOf(normalized, []string{"invalid", "malformed", "illegal", "参数", "request body is required"}) {
		return errorCodeInvalidArgument, fallbackMessage(message, "invalid request"), false
	}
	if status == http.StatusBadGateway || status == http.StatusServiceUnavailable || status == http.StatusGatewayTimeout {
		return errorCodeChainUnavailable, fallbackMessage(message, "chain upstream unavailable"), true
	}
	if status == http.StatusUnauthorized {
		return errorCodeUnauthorized, fallbackMessage(message, "unauthorized"), false
	}
	if status == http.StatusNotFound {
		return errorCodeNotFound, fallbackMessage(message, "resource not found"), false
	}
	return errorCodeTxRejected, fallbackMessage(message, "transaction rejected"), false
}

func extractErrorMessage(body []byte) string {
	trimmed := strings.TrimSpace(string(body))
	if trimmed == "" {
		return ""
	}
	var payload map[string]any
	if err := json.Unmarshal(body, &payload); err != nil {
		return trimmed
	}
	if value, ok := payload["error"].(string); ok && strings.TrimSpace(value) != "" {
		return value
	}
	if value, ok := payload["message"].(string); ok && strings.TrimSpace(value) != "" {
		return value
	}
	if value, ok := payload["raw_log"].(string); ok && strings.TrimSpace(value) != "" {
		return value
	}
	return trimmed
}

func containsOneOf(value string, keywords []string) bool {
	for _, keyword := range keywords {
		if strings.Contains(value, keyword) {
			return true
		}
	}
	return false
}

func fallbackMessage(message string, fallback string) string {
	trimmed := strings.TrimSpace(message)
	if trimmed == "" {
		return fallback
	}
	return trimmed
}
