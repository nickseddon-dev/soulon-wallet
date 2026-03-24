package api

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestMapChainProxyError(t *testing.T) {
	testCases := []struct {
		name      string
		status    int
		body      string
		wantCode  string
		wantRetry bool
	}{
		{
			name:      "insufficient funds",
			status:    http.StatusBadRequest,
			body:      `{"message":"insufficient funds: spendable balance is smaller than 10usoul"}`,
			wantCode:  errorCodeInsufficientFunds,
			wantRetry: false,
		},
		{
			name:      "out of gas",
			status:    http.StatusBadRequest,
			body:      `{"raw_log":"out of gas in location: WritePerByte; gasWanted: 200000, gasUsed: 201201"}`,
			wantCode:  errorCodeOutOfGas,
			wantRetry: false,
		},
		{
			name:      "invalid argument",
			status:    http.StatusBadRequest,
			body:      `{"error":"invalid request body"}`,
			wantCode:  errorCodeInvalidArgument,
			wantRetry: false,
		},
		{
			name:      "invalid sequence",
			status:    http.StatusBadRequest,
			body:      `{"message":"account sequence mismatch, expected 10, got 9"}`,
			wantCode:  errorCodeInvalidSequence,
			wantRetry: true,
		},
		{
			name:      "chain unavailable",
			status:    http.StatusBadGateway,
			body:      `{"error":"upstream timeout"}`,
			wantCode:  errorCodeChainUnavailable,
			wantRetry: true,
		},
	}
	for _, testCase := range testCases {
		testCase := testCase
		t.Run(testCase.name, func(t *testing.T) {
			gotCode, _, gotRetry := mapChainProxyError(testCase.status, []byte(testCase.body))
			if gotCode != testCase.wantCode {
				t.Fatalf("code mismatch: got %s want %s", gotCode, testCase.wantCode)
			}
			if gotRetry != testCase.wantRetry {
				t.Fatalf("retryable mismatch: got %v want %v", gotRetry, testCase.wantRetry)
			}
		})
	}
}

func TestHandleChainTxBroadcastEmptyBodyReturnsStructuredError(t *testing.T) {
	server := NewServer(":0", "testdata/events.jsonl", "file", "", "", 200)
	request := httptest.NewRequest(http.MethodPost, "/v1/chain/txs", nil)
	recorder := httptest.NewRecorder()

	server.http.Handler.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusBadRequest {
		t.Fatalf("unexpected status: %d body=%s", recorder.Code, recorder.Body.String())
	}
	var response apiErrorPayload
	if err := decodeJSONBody(recorder.Result().Body, &response); err != nil {
		t.Fatalf("decode response failed: %v", err)
	}
	if response.Code != errorCodeInvalidArgument {
		t.Fatalf("error code mismatch: %+v", response)
	}
	if response.Message != "request body is required" {
		t.Fatalf("error message mismatch: %+v", response)
	}
}
