package api

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestHandleSignatureChallengeAndConfirm(t *testing.T) {
	server := NewServer(":0", "testdata/events.jsonl", "file", "", "", 200)
	challengeReqBody := bytes.NewBufferString(`{"accountId":"demo-user"}`)
	challengeReq := httptest.NewRequest(http.MethodPost, "/v1/auth/signature/challenge", challengeReqBody)
	challengeRecorder := httptest.NewRecorder()
	server.http.Handler.ServeHTTP(challengeRecorder, challengeReq)
	if challengeRecorder.Code != http.StatusOK {
		t.Fatalf("unexpected challenge status: %d body=%s", challengeRecorder.Code, challengeRecorder.Body.String())
	}
	var challengeResp struct {
		RequestID string `json:"requestId"`
		AccountID string `json:"accountId"`
	}
	if err := json.Unmarshal(challengeRecorder.Body.Bytes(), &challengeResp); err != nil {
		t.Fatalf("decode challenge response failed: %v", err)
	}
	if challengeResp.RequestID == "" || challengeResp.AccountID != "demo-user" {
		t.Fatalf("unexpected challenge response: %+v", challengeResp)
	}
	signature := challengeResp.RequestID + ".demo-user." + time.Now().Format("150405")
	confirmReqBody := bytes.NewBufferString(`{"accountId":"demo-user","requestId":"` + challengeResp.RequestID + `","signature":"` + signature + `"}`)
	confirmReq := httptest.NewRequest(http.MethodPost, "/v1/auth/signature/confirm", confirmReqBody)
	confirmRecorder := httptest.NewRecorder()
	server.http.Handler.ServeHTTP(confirmRecorder, confirmReq)
	if confirmRecorder.Code != http.StatusOK {
		t.Fatalf("unexpected confirm status: %d body=%s", confirmRecorder.Code, confirmRecorder.Body.String())
	}
	var confirmResp struct {
		Success bool `json:"success"`
	}
	if err := json.Unmarshal(confirmRecorder.Body.Bytes(), &confirmResp); err != nil {
		t.Fatalf("decode confirm response failed: %v", err)
	}
	if !confirmResp.Success {
		t.Fatal("confirm should be success")
	}
}

func TestHandleSignatureConfirmExpired(t *testing.T) {
	server := NewServer(":0", "testdata/events.jsonl", "file", "", "", 200)
	server.challengeTTL = -time.Second
	challengeReq := httptest.NewRequest(http.MethodPost, "/v1/auth/signature/challenge", bytes.NewBufferString(`{"accountId":"demo-user"}`))
	challengeRecorder := httptest.NewRecorder()
	server.http.Handler.ServeHTTP(challengeRecorder, challengeReq)
	var challengeResp struct {
		RequestID string `json:"requestId"`
	}
	if err := json.Unmarshal(challengeRecorder.Body.Bytes(), &challengeResp); err != nil {
		t.Fatalf("decode challenge response failed: %v", err)
	}
	signature := challengeResp.RequestID + ".demo-user.x"
	confirmReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/auth/signature/confirm",
		bytes.NewBufferString(`{"accountId":"demo-user","requestId":"`+challengeResp.RequestID+`","signature":"`+signature+`"}`),
	)
	confirmRecorder := httptest.NewRecorder()
	server.http.Handler.ServeHTTP(confirmRecorder, confirmReq)
	if confirmRecorder.Code != http.StatusUnauthorized {
		t.Fatalf("unexpected confirm status: %d body=%s", confirmRecorder.Code, confirmRecorder.Body.String())
	}
}
