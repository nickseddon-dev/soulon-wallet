package api

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"soulon-backend/internal/indexer"
	"strconv"
	"strings"
	"sync"
	"time"

	_ "github.com/jackc/pgx/v5/stdlib"
)

type Server struct {
	http           *http.Server
	eventStorePath string
	storeBackend   string
	postgresDSN    string
	chainRESTURL   string
	chainClient    *http.Client
	notifyToken    string
	notifyCapacity int
	challengeTTL   time.Duration
	challenges     map[string]signatureChallenge
	notifications  []notificationMessage
	subscribers    map[int]chan notificationMessage
	subscriberSeq  int
	mu             sync.Mutex
}

type eventQuery struct {
	limit     int
	offset    int
	order     string
	eventType string
	minHeight int64
	maxHeight int64
	hasMin    bool
	hasMax    bool
}

type signatureChallenge struct {
	RequestID        string
	AccountID        string
	ChallengeMessage string
	ExpiresAt        time.Time
}

type notificationMessage struct {
	ID          string    `json:"id"`
	Type        string    `json:"type"`
	Height      int64     `json:"height"`
	BlockHash   string    `json:"blockHash"`
	ParentHash  string    `json:"parentHash,omitempty"`
	Payload     string    `json:"payload"`
	ProducedAt  time.Time `json:"producedAt"`
	PersistedAt time.Time `json:"persistedAt"`
	ReceivedAt  time.Time `json:"receivedAt"`
}

func NewServer(
	addr string,
	eventStorePath string,
	storeBackend string,
	postgresDSN string,
	notifyToken string,
	notifyCapacity int,
) *Server {
	if notifyCapacity <= 0 {
		notifyCapacity = 200
	}
	server := &Server{
		eventStorePath: eventStorePath,
		storeBackend:   strings.ToLower(strings.TrimSpace(storeBackend)),
		postgresDSN:    strings.TrimSpace(postgresDSN),
		chainRESTURL:   strings.TrimSpace(os.Getenv("API_CHAIN_REST_ENDPOINT")),
		chainClient: &http.Client{
			Timeout: 4 * time.Second,
		},
		notifyToken:    strings.TrimSpace(notifyToken),
		notifyCapacity: notifyCapacity,
		challengeTTL:   5 * time.Minute,
		challenges:     map[string]signatureChallenge{},
		notifications:  make([]notificationMessage, 0, notifyCapacity),
		subscribers:    map[int]chan notificationMessage{},
	}
	if server.chainRESTURL == "" {
		server.chainRESTURL = "http://127.0.0.1:1317"
	}
	mux := http.NewServeMux()
	mux.HandleFunc("/v1/health", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("content-type", "application/json")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"status":"ok"}`))
	})
	mux.HandleFunc("/v1/indexer/events", server.handleIndexerEvents)
	mux.HandleFunc("/v1/indexer/events/", server.handleIndexerEventByID)
	mux.HandleFunc("/v1/indexer/state", server.handleIndexerState)
	mux.HandleFunc("/v1/chain/staking/validators", server.handleChainValidators)
	mux.HandleFunc("/v1/chain/staking/delegations/", server.handleChainDelegations)
	mux.HandleFunc("/v1/chain/distribution/delegators/", server.handleChainRewards)
	mux.HandleFunc("/v1/chain/gov/proposals", server.handleChainGovProposals)
	mux.HandleFunc("/v1/chain/gov/proposals/", server.handleChainGovProposalByID)
	mux.HandleFunc("/v1/chain/txs", server.handleChainTxBroadcast)
	mux.HandleFunc("/v1/chain/txs/", server.handleChainTxByHash)
	mux.HandleFunc("/v1/notifications", server.handleNotifications)
	mux.HandleFunc("/v1/notifications/stream", server.handleNotificationStream)
	mux.HandleFunc("/v1/notifications/webhook", server.handleNotificationWebhook)
	mux.HandleFunc("/v1/auth/signature/challenge", server.handleSignatureChallenge)
	mux.HandleFunc("/v1/auth/signature/confirm", server.handleSignatureConfirm)
	server.http = &http.Server{
		Addr:              addr,
		Handler:           mux,
		ReadHeaderTimeout: 3 * time.Second,
	}
	return server
}

func (s *Server) Start() error {
	return s.http.ListenAndServe()
}

func (s *Server) Shutdown(ctx context.Context) error {
	return s.http.Shutdown(ctx)
}

func (s *Server) handleIndexerEvents(w http.ResponseWriter, request *http.Request) {
	query, queryErr := parseEventQuery(request)
	if queryErr != nil {
		writeAPIError(w, http.StatusBadRequest, errorCodeInvalidArgument, queryErr.Error(), false)
		return
	}
	sourceEvents, err := s.loadEvents()
	if err != nil {
		if os.IsNotExist(err) {
			w.Header().Set("content-type", "application/json")
			_ = json.NewEncoder(w).Encode(map[string]any{
				"events": []map[string]any{},
				"total":  0,
			})
			return
		}
		writeAPIError(w, http.StatusInternalServerError, errorCodeInternal, err.Error(), false)
		return
	}
	filtered := filterEvents(sourceEvents, query)
	total := len(filtered)
	selected, hasMore := selectEvents(filtered, query)
	outEvents := make([]json.RawMessage, 0, query.limit)
	for _, event := range selected {
		eventBytes, marshalErr := json.Marshal(event)
		if marshalErr != nil {
			writeAPIError(w, http.StatusInternalServerError, errorCodeInternal, marshalErr.Error(), false)
			return
		}
		outEvents = append(outEvents, json.RawMessage(eventBytes))
	}
	w.Header().Set("content-type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"events":  outEvents,
		"total":   total,
		"offset":  query.offset,
		"limit":   query.limit,
		"hasMore": hasMore,
	})
}

func (s *Server) handleIndexerState(w http.ResponseWriter, _ *http.Request) {
	events, err := s.loadEvents()
	if err != nil {
		if os.IsNotExist(err) {
			w.Header().Set("content-type", "application/json")
			_ = json.NewEncoder(w).Encode(map[string]any{
				"tipHeight": 0,
				"tipHash":   "",
				"total":     0,
				"reorgs":    0,
			})
			return
		}
		writeAPIError(w, http.StatusInternalServerError, errorCodeInternal, err.Error(), false)
		return
	}
	state := rebuildState(events)
	w.Header().Set("content-type", "application/json")
	_ = json.NewEncoder(w).Encode(state)
}

func (s *Server) handleNotificationWebhook(w http.ResponseWriter, request *http.Request) {
	if request.Method != http.MethodPost {
		writeAPIError(w, http.StatusMethodNotAllowed, errorCodeMethodNotAllowed, "method not allowed", false)
		return
	}
	if s.notifyToken != "" {
		authHeader := strings.TrimSpace(request.Header.Get("authorization"))
		expected := "Bearer " + s.notifyToken
		if authHeader != expected {
			writeAPIError(w, http.StatusUnauthorized, errorCodeUnauthorized, "unauthorized", false)
			return
		}
	}
	var input notificationMessage
	if err := decodeJSONBody(request.Body, &input); err != nil {
		writeAPIError(w, http.StatusBadRequest, errorCodeInvalidArgument, err.Error(), false)
		return
	}
	if strings.TrimSpace(input.ID) == "" {
		writeAPIError(w, http.StatusBadRequest, errorCodeInvalidArgument, "id is required", false)
		return
	}
	input.ReceivedAt = time.Now().UTC()
	s.pushNotification(input)
	w.Header().Set("content-type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"accepted": true,
	})
}

func (s *Server) handleNotifications(w http.ResponseWriter, request *http.Request) {
	if request.Method != http.MethodGet {
		writeAPIError(w, http.StatusMethodNotAllowed, errorCodeMethodNotAllowed, "method not allowed", false)
		return
	}
	limit := 20
	if raw := strings.TrimSpace(request.URL.Query().Get("limit")); raw != "" {
		parsed, err := strconv.Atoi(raw)
		if err != nil || parsed <= 0 || parsed > 200 {
			writeAPIError(w, http.StatusBadRequest, errorCodeInvalidArgument, "invalid limit", false)
			return
		}
		limit = parsed
	}
	offset := 0
	if raw := strings.TrimSpace(request.URL.Query().Get("offset")); raw != "" {
		parsed, err := strconv.Atoi(raw)
		if err != nil || parsed < 0 {
			writeAPIError(w, http.StatusBadRequest, errorCodeInvalidArgument, "invalid offset", false)
			return
		}
		offset = parsed
	}
	buffer := s.snapshotNotifications()
	total := len(buffer)
	if offset >= total {
		w.Header().Set("content-type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{
			"notifications": []notificationMessage{},
			"total":         total,
			"offset":        offset,
			"limit":         limit,
			"hasMore":       false,
		})
		return
	}
	ordered := make([]notificationMessage, 0, total)
	for index := total - 1; index >= 0; index-- {
		ordered = append(ordered, buffer[index])
	}
	end := offset + limit
	if end > len(ordered) {
		end = len(ordered)
	}
	w.Header().Set("content-type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"notifications": ordered[offset:end],
		"total":         total,
		"offset":        offset,
		"limit":         limit,
		"hasMore":       end < len(ordered),
	})
}

func (s *Server) handleNotificationStream(w http.ResponseWriter, request *http.Request) {
	if request.Method != http.MethodGet {
		writeAPIError(w, http.StatusMethodNotAllowed, errorCodeMethodNotAllowed, "method not allowed", false)
		return
	}
	if s.notifyToken != "" {
		queryToken := strings.TrimSpace(request.URL.Query().Get("token"))
		authHeader := strings.TrimSpace(request.Header.Get("authorization"))
		expected := "Bearer " + s.notifyToken
		if queryToken != s.notifyToken && authHeader != expected {
			writeAPIError(w, http.StatusUnauthorized, errorCodeUnauthorized, "unauthorized", false)
			return
		}
	}
	flusher, ok := w.(http.Flusher)
	if !ok {
		writeAPIError(w, http.StatusInternalServerError, errorCodeInternal, "streaming unsupported", false)
		return
	}
	w.Header().Set("content-type", "text/event-stream")
	w.Header().Set("cache-control", "no-cache")
	w.Header().Set("connection", "keep-alive")
	subscriberID, streamCh := s.addSubscriber()
	defer s.removeSubscriber(subscriberID)
	initialLimit := 20
	if raw := strings.TrimSpace(request.URL.Query().Get("initialLimit")); raw != "" {
		parsed, err := strconv.Atoi(raw)
		if err != nil || parsed <= 0 || parsed > 200 {
			writeAPIError(w, http.StatusBadRequest, errorCodeInvalidArgument, "invalid initialLimit", false)
			return
		}
		initialLimit = parsed
	}
	initialItems := s.snapshotLatestNotifications(initialLimit)
	for _, item := range initialItems {
		payload, err := json.Marshal(item)
		if err != nil {
			continue
		}
		_, _ = fmt.Fprintf(w, "event: notification\ndata: %s\n\n", payload)
	}
	_, _ = w.Write([]byte(": connected\n\n"))
	flusher.Flush()
	pingTicker := time.NewTicker(20 * time.Second)
	defer pingTicker.Stop()
	for {
		select {
		case <-request.Context().Done():
			return
		case message := <-streamCh:
			payload, err := json.Marshal(message)
			if err != nil {
				continue
			}
			_, _ = fmt.Fprintf(w, "event: notification\ndata: %s\n\n", payload)
			flusher.Flush()
		case <-pingTicker.C:
			_, _ = w.Write([]byte(": ping\n\n"))
			flusher.Flush()
		}
	}
}

func (s *Server) pushNotification(message notificationMessage) {
	s.mu.Lock()
	s.notifications = append(s.notifications, message)
	if len(s.notifications) > s.notifyCapacity {
		s.notifications = s.notifications[len(s.notifications)-s.notifyCapacity:]
	}
	subscriberChannels := make([]chan notificationMessage, 0, len(s.subscribers))
	for _, streamCh := range s.subscribers {
		subscriberChannels = append(subscriberChannels, streamCh)
	}
	s.mu.Unlock()
	for _, streamCh := range subscriberChannels {
		select {
		case streamCh <- message:
		default:
		}
	}
}

func (s *Server) snapshotNotifications() []notificationMessage {
	s.mu.Lock()
	defer s.mu.Unlock()
	buffer := make([]notificationMessage, len(s.notifications))
	copy(buffer, s.notifications)
	return buffer
}

func (s *Server) snapshotLatestNotifications(limit int) []notificationMessage {
	buffer := s.snapshotNotifications()
	if len(buffer) == 0 {
		return []notificationMessage{}
	}
	if limit <= 0 {
		limit = 1
	}
	if limit > len(buffer) {
		limit = len(buffer)
	}
	out := make([]notificationMessage, 0, limit)
	start := len(buffer) - 1
	end := len(buffer) - limit
	for index := start; index >= end; index-- {
		out = append(out, buffer[index])
	}
	return out
}

func (s *Server) addSubscriber() (int, chan notificationMessage) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.subscriberSeq++
	subscriberID := s.subscriberSeq
	streamCh := make(chan notificationMessage, 16)
	s.subscribers[subscriberID] = streamCh
	return subscriberID, streamCh
}

func (s *Server) removeSubscriber(subscriberID int) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if _, exists := s.subscribers[subscriberID]; !exists {
		return
	}
	delete(s.subscribers, subscriberID)
}

func (s *Server) handleSignatureChallenge(w http.ResponseWriter, request *http.Request) {
	if request.Method != http.MethodPost {
		writeAPIError(w, http.StatusMethodNotAllowed, errorCodeMethodNotAllowed, "method not allowed", false)
		return
	}
	var input struct {
		AccountID string `json:"accountId"`
	}
	if err := decodeJSONBody(request.Body, &input); err != nil {
		writeAPIError(w, http.StatusBadRequest, errorCodeInvalidArgument, err.Error(), false)
		return
	}
	accountID := strings.TrimSpace(input.AccountID)
	if accountID == "" {
		writeAPIError(w, http.StatusBadRequest, errorCodeInvalidArgument, "accountId is required", false)
		return
	}
	issuedAt := time.Now().UTC()
	requestID := fmt.Sprintf("req_%d", issuedAt.UnixNano())
	challenge := signatureChallenge{
		RequestID:        requestID,
		AccountID:        accountID,
		ChallengeMessage: fmt.Sprintf("Soulon Wallet 授权签名\naccount=%s\nrequestId=%s", accountID, requestID),
		ExpiresAt:        issuedAt.Add(s.challengeTTL),
	}
	s.mu.Lock()
	s.challenges[requestID] = challenge
	s.mu.Unlock()
	w.Header().Set("content-type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"requestId":        challenge.RequestID,
		"accountId":        challenge.AccountID,
		"challengeMessage": challenge.ChallengeMessage,
		"expiresAt":        challenge.ExpiresAt.Format(time.RFC3339),
	})
}

func (s *Server) handleSignatureConfirm(w http.ResponseWriter, request *http.Request) {
	if request.Method != http.MethodPost {
		writeAPIError(w, http.StatusMethodNotAllowed, errorCodeMethodNotAllowed, "method not allowed", false)
		return
	}
	var input struct {
		AccountID string `json:"accountId"`
		RequestID string `json:"requestId"`
		Signature string `json:"signature"`
	}
	if err := decodeJSONBody(request.Body, &input); err != nil {
		writeAPIError(w, http.StatusBadRequest, errorCodeInvalidArgument, err.Error(), false)
		return
	}
	accountID := strings.TrimSpace(input.AccountID)
	requestID := strings.TrimSpace(input.RequestID)
	signature := strings.TrimSpace(input.Signature)
	if accountID == "" || requestID == "" || signature == "" {
		writeAPIError(w, http.StatusBadRequest, errorCodeInvalidArgument, "accountId, requestId and signature are required", false)
		return
	}
	s.mu.Lock()
	challenge, exists := s.challenges[requestID]
	if exists {
		delete(s.challenges, requestID)
	}
	s.mu.Unlock()
	if !exists {
		writeAPIError(w, http.StatusNotFound, errorCodeNotFound, "challenge not found", false)
		return
	}
	if challenge.AccountID != accountID {
		writeAPIError(w, http.StatusBadRequest, errorCodeInvalidArgument, "accountId mismatch", false)
		return
	}
	if time.Now().After(challenge.ExpiresAt) {
		writeAPIError(w, http.StatusUnauthorized, errorCodeUnauthorized, "challenge expired", false)
		return
	}
	expectedPrefix := requestID + "." + accountID + "."
	if !strings.HasPrefix(signature, expectedPrefix) {
		writeAPIError(w, http.StatusUnauthorized, errorCodeUnauthorized, "signature verification failed", false)
		return
	}
	w.Header().Set("content-type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"success":      true,
		"signature":    signature,
		"accountId":    accountID,
		"requestId":    requestID,
		"authorizedAt": time.Now().UTC().Format(time.RFC3339),
	})
}

func (s *Server) handleIndexerEventByID(w http.ResponseWriter, request *http.Request) {
	eventIDPath := strings.TrimSpace(strings.TrimPrefix(request.URL.Path, "/v1/indexer/events/"))
	if eventIDPath == "" {
		http.NotFound(w, request)
		return
	}
	eventID, decodeErr := url.PathUnescape(eventIDPath)
	if decodeErr != nil || strings.TrimSpace(eventID) == "" {
		writeAPIError(w, http.StatusBadRequest, errorCodeInvalidArgument, "invalid event id", false)
		return
	}
	events, err := s.loadEvents()
	if err != nil {
		if os.IsNotExist(err) {
			http.NotFound(w, request)
			return
		}
		writeAPIError(w, http.StatusInternalServerError, errorCodeInternal, err.Error(), false)
		return
	}
	event, found := findEventByID(events, eventID)
	if !found {
		http.NotFound(w, request)
		return
	}
	eventBytes, marshalErr := json.Marshal(event)
	if marshalErr != nil {
		writeAPIError(w, http.StatusInternalServerError, errorCodeInternal, marshalErr.Error(), false)
		return
	}
	w.Header().Set("content-type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"event": json.RawMessage(eventBytes),
	})
}

func (s *Server) handleChainValidators(w http.ResponseWriter, request *http.Request) {
	s.proxyChainRequest(w, request, http.MethodGet, "/cosmos/staking/v1beta1/validators")
}

func (s *Server) handleChainDelegations(w http.ResponseWriter, request *http.Request) {
	delegatorAddress := strings.TrimSpace(strings.TrimPrefix(request.URL.Path, "/v1/chain/staking/delegations/"))
	if delegatorAddress == "" {
		http.NotFound(w, request)
		return
	}
	s.proxyChainRequest(
		w,
		request,
		http.MethodGet,
		"/cosmos/staking/v1beta1/delegations/"+url.PathEscape(delegatorAddress),
	)
}

func (s *Server) handleChainRewards(w http.ResponseWriter, request *http.Request) {
	suffix := strings.TrimSpace(strings.TrimPrefix(request.URL.Path, "/v1/chain/distribution/delegators/"))
	if suffix == "" {
		http.NotFound(w, request)
		return
	}
	parts := strings.Split(suffix, "/")
	if len(parts) != 2 || strings.TrimSpace(parts[0]) == "" || parts[1] != "rewards" {
		http.NotFound(w, request)
		return
	}
	s.proxyChainRequest(
		w,
		request,
		http.MethodGet,
		"/cosmos/distribution/v1beta1/delegators/"+url.PathEscape(parts[0])+"/rewards",
	)
}

func (s *Server) handleChainGovProposals(w http.ResponseWriter, request *http.Request) {
	s.proxyChainRequest(w, request, http.MethodGet, "/cosmos/gov/v1beta1/proposals")
}

func (s *Server) handleChainGovProposalByID(w http.ResponseWriter, request *http.Request) {
	suffix := strings.TrimSpace(strings.TrimPrefix(request.URL.Path, "/v1/chain/gov/proposals/"))
	if suffix == "" {
		http.NotFound(w, request)
		return
	}
	if strings.HasSuffix(suffix, "/votes") {
		proposalID := strings.TrimSuffix(suffix, "/votes")
		proposalID = strings.TrimSpace(strings.TrimSuffix(proposalID, "/"))
		if proposalID == "" {
			http.NotFound(w, request)
			return
		}
		s.proxyChainRequest(
			w,
			request,
			http.MethodGet,
			"/cosmos/gov/v1beta1/proposals/"+url.PathEscape(proposalID)+"/votes",
		)
		return
	}
	proposalID := strings.TrimSpace(strings.TrimSuffix(suffix, "/"))
	if proposalID == "" {
		http.NotFound(w, request)
		return
	}
	s.proxyChainRequest(
		w,
		request,
		http.MethodGet,
		"/cosmos/gov/v1beta1/proposals/"+url.PathEscape(proposalID),
	)
}

func (s *Server) handleChainTxByHash(w http.ResponseWriter, request *http.Request) {
	txHash := strings.TrimSpace(strings.TrimPrefix(request.URL.Path, "/v1/chain/txs/"))
	if txHash == "" {
		http.NotFound(w, request)
		return
	}
	s.proxyChainRequest(
		w,
		request,
		http.MethodGet,
		"/cosmos/tx/v1beta1/txs/"+url.PathEscape(txHash),
	)
}

func (s *Server) handleChainTxBroadcast(w http.ResponseWriter, request *http.Request) {
	if request.Method != http.MethodPost {
		writeAPIError(w, http.StatusMethodNotAllowed, errorCodeMethodNotAllowed, "method not allowed", false)
		return
	}
	body, err := io.ReadAll(request.Body)
	if err != nil {
		writeAPIError(w, http.StatusBadRequest, errorCodeInvalidArgument, "invalid request body", false)
		return
	}
	if len(bytes.TrimSpace(body)) == 0 {
		writeAPIError(w, http.StatusBadRequest, errorCodeInvalidArgument, "request body is required", false)
		return
	}
	s.proxyChainRequestWithBody(w, request, http.MethodPost, "/cosmos/tx/v1beta1/txs", body)
}

func (s *Server) proxyChainRequest(w http.ResponseWriter, request *http.Request, method string, upstreamPath string) {
	if request.Method != method {
		writeAPIError(w, http.StatusMethodNotAllowed, errorCodeMethodNotAllowed, "method not allowed", false)
		return
	}
	s.proxyChainRequestWithBody(w, request, method, upstreamPath, nil)
}

func (s *Server) proxyChainRequestWithBody(
	w http.ResponseWriter,
	request *http.Request,
	method string,
	upstreamPath string,
	body []byte,
) {
	baseURL := strings.TrimRight(strings.TrimSpace(s.chainRESTURL), "/")
	upstreamURL, err := url.Parse(baseURL + upstreamPath)
	if err != nil {
		writeAPIError(w, http.StatusInternalServerError, errorCodeInternal, "invalid chain upstream endpoint", false)
		return
	}
	upstreamURL.RawQuery = request.URL.Query().Encode()
	var requestBody io.Reader
	if len(body) > 0 {
		requestBody = bytes.NewReader(body)
	}
	upstreamRequest, err := http.NewRequestWithContext(request.Context(), method, upstreamURL.String(), requestBody)
	if err != nil {
		writeAPIError(w, http.StatusInternalServerError, errorCodeInternal, "invalid upstream request", false)
		return
	}
	upstreamRequest.Header.Set("accept", "application/json")
	if len(body) > 0 {
		upstreamRequest.Header.Set("content-type", "application/json")
	}
	upstreamResponse, err := s.chainClient.Do(upstreamRequest)
	if err != nil {
		writeAPIError(w, http.StatusBadGateway, errorCodeChainUnavailable, "chain upstream unavailable", true)
		return
	}
	defer upstreamResponse.Body.Close()
	upstreamBody, readErr := io.ReadAll(upstreamResponse.Body)
	if readErr != nil {
		writeAPIError(w, http.StatusBadGateway, errorCodeChainUnavailable, "failed to read chain response", true)
		return
	}
	if upstreamResponse.StatusCode >= http.StatusBadRequest {
		code, message, retryable := mapChainProxyError(upstreamResponse.StatusCode, upstreamBody)
		writeAPIError(w, upstreamResponse.StatusCode, code, message, retryable)
		return
	}
	contentType := strings.TrimSpace(upstreamResponse.Header.Get("content-type"))
	if contentType == "" {
		contentType = "application/json"
	}
	w.Header().Set("content-type", contentType)
	w.WriteHeader(upstreamResponse.StatusCode)
	_, _ = w.Write(upstreamBody)
}

func (s *Server) loadEvents() ([]indexer.Event, error) {
	switch s.storeBackend {
	case "file":
		return s.loadEventsFromFile()
	case "postgres":
		return s.loadEventsFromPostgres()
	default:
		events, err := s.loadEventsFromFile()
		if err == nil {
			return events, nil
		}
		if !errors.Is(err, os.ErrNotExist) {
			return nil, err
		}
		if s.postgresDSN == "" {
			return nil, err
		}
		return s.loadEventsFromPostgres()
	}
}

func (s *Server) loadEventsFromFile() ([]indexer.Event, error) {
	content, err := os.ReadFile(s.eventStorePath)
	if err != nil {
		return nil, err
	}
	rawLines := strings.Split(strings.TrimSpace(string(content)), "\n")
	events := make([]indexer.Event, 0, len(rawLines))
	for _, line := range rawLines {
		trimmed := strings.TrimSpace(line)
		if trimmed == "" {
			continue
		}
		var event indexer.Event
		if unmarshalErr := json.Unmarshal([]byte(trimmed), &event); unmarshalErr != nil {
			return nil, unmarshalErr
		}
		events = append(events, event)
	}
	return events, nil
}

func (s *Server) loadEventsFromPostgres() ([]indexer.Event, error) {
	if s.postgresDSN == "" {
		return nil, fmt.Errorf("postgres dsn is empty")
	}
	db, err := sql.Open("pgx", s.postgresDSN)
	if err != nil {
		return nil, err
	}
	defer db.Close()
	rows, err := db.Query(`
		SELECT id, height, type, block_hash, parent_hash, rollback_from, payload, produced_at, persisted_at
		FROM indexer_events_log
		ORDER BY seq ASC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	events := make([]indexer.Event, 0, 128)
	for rows.Next() {
		var event indexer.Event
		var rollbackFrom sql.NullInt64
		if scanErr := rows.Scan(
			&event.ID,
			&event.Height,
			&event.Type,
			&event.BlockHash,
			&event.ParentHash,
			&rollbackFrom,
			&event.Payload,
			&event.ProducedAt,
			&event.PersistedAt,
		); scanErr != nil {
			return nil, scanErr
		}
		if rollbackFrom.Valid {
			event.RollbackFrom = rollbackFrom.Int64
		}
		events = append(events, event)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return events, nil
}

func rebuildState(events []indexer.Event) indexer.StoreState {
	byHeight := map[int64]string{}
	reorgs := 0
	for _, event := range events {
		if event.Type == "rollback" {
			if event.RollbackFrom > 0 {
				for height := range byHeight {
					if height >= event.RollbackFrom {
						delete(byHeight, height)
					}
				}
			}
			reorgs++
			continue
		}
		if event.Height > 0 && event.BlockHash != "" {
			byHeight[event.Height] = event.BlockHash
		}
	}
	tipHeight := int64(0)
	tipHash := ""
	for height, hash := range byHeight {
		if height >= tipHeight {
			tipHeight = height
			tipHash = hash
		}
	}
	return indexer.StoreState{
		TipHeight: tipHeight,
		TipHash:   tipHash,
		Total:     len(byHeight),
		Reorgs:    reorgs,
	}
}

func parseEventQuery(request *http.Request) (eventQuery, error) {
	query := eventQuery{
		limit:  20,
		offset: 0,
		order:  "desc",
	}
	limitQuery := strings.TrimSpace(request.URL.Query().Get("limit"))
	if limitQuery != "" {
		parsed, err := strconv.Atoi(limitQuery)
		if err != nil {
			return query, fmt.Errorf("invalid limit: %s", limitQuery)
		}
		if parsed <= 0 || parsed > 200 {
			return query, fmt.Errorf("limit out of range: %d", parsed)
		}
		query.limit = parsed
	}
	offsetQuery := strings.TrimSpace(request.URL.Query().Get("offset"))
	if offsetQuery != "" {
		parsed, err := strconv.Atoi(offsetQuery)
		if err != nil {
			return query, fmt.Errorf("invalid offset: %s", offsetQuery)
		}
		if parsed < 0 {
			return query, fmt.Errorf("offset out of range: %d", parsed)
		}
		query.offset = parsed
	}
	order := strings.ToLower(strings.TrimSpace(request.URL.Query().Get("order")))
	if order != "" {
		if order != "asc" && order != "desc" {
			return query, fmt.Errorf("invalid order: %s", order)
		}
		query.order = order
	}
	query.eventType = strings.TrimSpace(request.URL.Query().Get("type"))
	minHeightQuery := strings.TrimSpace(request.URL.Query().Get("minHeight"))
	if minHeightQuery != "" {
		parsed, err := strconv.ParseInt(minHeightQuery, 10, 64)
		if err != nil {
			return query, fmt.Errorf("invalid minHeight: %s", minHeightQuery)
		}
		query.minHeight = parsed
		query.hasMin = true
	}
	maxHeightQuery := strings.TrimSpace(request.URL.Query().Get("maxHeight"))
	if maxHeightQuery != "" {
		parsed, err := strconv.ParseInt(maxHeightQuery, 10, 64)
		if err != nil {
			return query, fmt.Errorf("invalid maxHeight: %s", maxHeightQuery)
		}
		query.maxHeight = parsed
		query.hasMax = true
	}
	if query.hasMin && query.hasMax && query.minHeight > query.maxHeight {
		return query, fmt.Errorf("minHeight cannot be greater than maxHeight")
	}
	return query, nil
}

func filterEvents(events []indexer.Event, query eventQuery) []indexer.Event {
	filtered := make([]indexer.Event, 0, len(events))
	for _, event := range events {
		if query.eventType != "" && event.Type != query.eventType {
			continue
		}
		if query.hasMin && event.Height < query.minHeight {
			continue
		}
		if query.hasMax && event.Height > query.maxHeight {
			continue
		}
		filtered = append(filtered, event)
	}
	return filtered
}

func selectEvents(events []indexer.Event, query eventQuery) ([]indexer.Event, bool) {
	ordered := make([]indexer.Event, 0, len(events))
	if query.order == "asc" {
		ordered = append(ordered, events...)
	} else {
		for index := len(events) - 1; index >= 0; index-- {
			ordered = append(ordered, events[index])
		}
	}
	if query.offset >= len(ordered) {
		return []indexer.Event{}, false
	}
	start := query.offset
	end := start + query.limit
	if end > len(ordered) {
		end = len(ordered)
	}
	hasMore := end < len(ordered)
	result := make([]indexer.Event, 0, query.limit)
	result = append(result, ordered[start:end]...)
	return result, hasMore
}

func findEventByID(events []indexer.Event, eventID string) (indexer.Event, bool) {
	for index := len(events) - 1; index >= 0; index-- {
		if events[index].ID == eventID {
			return events[index], true
		}
	}
	return indexer.Event{}, false
}

func decodeJSONBody(body io.ReadCloser, out any) error {
	defer body.Close()
	decoder := json.NewDecoder(body)
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(out); err != nil {
		return err
	}
	return nil
}
