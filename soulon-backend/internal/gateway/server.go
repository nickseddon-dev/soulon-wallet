package gateway

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"sync"
	"time"
)

type Server struct {
	addr                string
	http                *http.Server
	router              *Router
	healthCheckInterval time.Duration
	healthCancel        context.CancelFunc
	healthWG            sync.WaitGroup
}

func NewServer(
	addr string,
	nodeEndpoints []string,
	healthCheckInterval time.Duration,
	forwardTimeout time.Duration,
) *Server {
	mux := http.NewServeMux()
	router := NewRouter(nodeEndpoints, forwardTimeout)
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok"))
	})
	mux.HandleFunc("/v1/nodes", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("content-type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{
			"nodes": router.Snapshot(),
		})
	})
	mux.HandleFunc("/v1/rpc", func(w http.ResponseWriter, request *http.Request) {
		payload, err := io.ReadAll(request.Body)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		result, statusCode, forwardErr := router.ForwardRPC(request.Context(), payload)
		if forwardErr != nil {
			http.Error(w, forwardErr.Error(), statusCode)
			return
		}
		w.Header().Set("content-type", "application/json")
		w.WriteHeader(statusCode)
		_, _ = w.Write(result)
	})
	return &Server{
		addr:                addr,
		router:              router,
		healthCheckInterval: healthCheckInterval,
		http: &http.Server{
			Addr:              addr,
			Handler:           mux,
			ReadHeaderTimeout: 3 * time.Second,
		},
	}
}

func (s *Server) Start() error {
	ctx := context.Background()
	s.router.CheckHealth(ctx)
	healthCtx, cancel := context.WithCancel(context.Background())
	s.healthCancel = cancel
	s.healthWG.Add(1)
	go func() {
		defer s.healthWG.Done()
		ticker := time.NewTicker(s.healthCheckInterval)
		defer ticker.Stop()
		for {
			select {
			case <-healthCtx.Done():
				return
			case <-ticker.C:
				s.router.CheckHealth(context.Background())
			}
		}
	}()
	return s.http.ListenAndServe()
}

func (s *Server) Shutdown(ctx context.Context) error {
	if s.healthCancel != nil {
		s.healthCancel()
	}
	s.healthWG.Wait()
	return s.http.Shutdown(ctx)
}
