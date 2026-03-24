package gateway

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"sync"
	"sync/atomic"
	"time"
)

type NodeStatus struct {
	Endpoint      string    `json:"endpoint"`
	Healthy       bool      `json:"healthy"`
	LastCheckedAt time.Time `json:"lastCheckedAt"`
	LastError     string    `json:"lastError,omitempty"`
}

type Router struct {
	client         *http.Client
	forwardTimeout time.Duration
	nodes          []NodeStatus
	rr             uint64
	mu             sync.RWMutex
}

func NewRouter(endpoints []string, forwardTimeout time.Duration) *Router {
	nodes := make([]NodeStatus, 0, len(endpoints))
	for _, endpoint := range endpoints {
		nodes = append(nodes, NodeStatus{
			Endpoint: endpoint,
			Healthy:  true,
		})
	}
	return &Router{
		client:         &http.Client{Timeout: 3 * time.Second},
		forwardTimeout: forwardTimeout,
		nodes:          nodes,
	}
}

func (r *Router) CheckHealth(ctx context.Context) {
	r.mu.Lock()
	defer r.mu.Unlock()
	for index := range r.nodes {
		node := &r.nodes[index]
		request, err := http.NewRequestWithContext(ctx, http.MethodGet, node.Endpoint+"/health", nil)
		if err != nil {
			node.Healthy = false
			node.LastError = err.Error()
			node.LastCheckedAt = time.Now()
			continue
		}
		response, err := r.client.Do(request)
		if err != nil {
			node.Healthy = false
			node.LastError = err.Error()
			node.LastCheckedAt = time.Now()
			continue
		}
		_ = response.Body.Close()
		node.Healthy = response.StatusCode >= 200 && response.StatusCode < 500
		if node.Healthy {
			node.LastError = ""
		} else {
			node.LastError = "node health check failed"
		}
		node.LastCheckedAt = time.Now()
	}
}

func (r *Router) Snapshot() []NodeStatus {
	r.mu.RLock()
	defer r.mu.RUnlock()
	result := make([]NodeStatus, len(r.nodes))
	copy(result, r.nodes)
	return result
}

func (r *Router) NextNode() (NodeStatus, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	if len(r.nodes) == 0 {
		return NodeStatus{}, errors.New("no nodes configured")
	}
	start := int(atomic.AddUint64(&r.rr, 1))
	for offset := 0; offset < len(r.nodes); offset++ {
		index := (start + offset) % len(r.nodes)
		node := r.nodes[index]
		if node.Healthy {
			return node, nil
		}
	}
	return NodeStatus{}, errors.New("no healthy nodes available")
}

func (r *Router) ForwardRPC(ctx context.Context, payload []byte) (json.RawMessage, int, error) {
	node, err := r.NextNode()
	if err != nil {
		return nil, http.StatusServiceUnavailable, err
	}
	forwardCtx, cancel := context.WithTimeout(ctx, r.forwardTimeout)
	defer cancel()
	request, err := http.NewRequestWithContext(forwardCtx, http.MethodPost, node.Endpoint, bytes.NewReader(payload))
	if err != nil {
		return nil, http.StatusInternalServerError, err
	}
	request.Header.Set("content-type", "application/json")
	response, err := r.client.Do(request)
	if err != nil {
		return nil, http.StatusBadGateway, err
	}
	defer response.Body.Close()
	body, err := io.ReadAll(response.Body)
	if err != nil {
		return nil, http.StatusBadGateway, err
	}
	return body, response.StatusCode, nil
}
