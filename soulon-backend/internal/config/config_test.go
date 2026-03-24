package config

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestLoadIndexerConfigFromEnv_AllowsHighSensitiveFromFile(t *testing.T) {
	t.Setenv("INDEXER_STORE_BACKEND", "postgres")
	t.Setenv("INDEXER_NOTIFY_WEBHOOK_URL", "https://notify.soulon.test/hook")
	dsnFile := writeTempSecretFile(t, "postgres://user:pwd@127.0.0.1:5432/soulon?sslmode=disable")
	tokenFile := writeTempSecretFile(t, "token-from-secret-file")
	t.Setenv("INDEXER_POSTGRES_DSN_FILE", dsnFile)
	t.Setenv("INDEXER_NOTIFY_AUTH_TOKEN_FILE", tokenFile)
	cfg, err := LoadIndexerConfigFromEnv()
	if err != nil {
		t.Fatalf("expected config to load from file source, got error: %v", err)
	}
	if cfg.PostgresDSN != "postgres://user:pwd@127.0.0.1:5432/soulon?sslmode=disable" {
		t.Fatalf("unexpected postgres dsn: %s", cfg.PostgresDSN)
	}
	if cfg.NotifyAuthToken != "token-from-secret-file" {
		t.Fatalf("unexpected notify auth token: %s", cfg.NotifyAuthToken)
	}
}

func TestLoadIndexerConfigFromEnv_BlockOnMissingHighSensitive(t *testing.T) {
	t.Setenv("INDEXER_STORE_BACKEND", "postgres")
	cfg, err := LoadIndexerConfigFromEnv()
	if err == nil {
		t.Fatalf("expected missing high-sensitive config to block startup, got cfg=%+v", cfg)
	}
	if !strings.Contains(err.Error(), "INDEXER_POSTGRES_DSN") {
		t.Fatalf("expected INDEXER_POSTGRES_DSN error, got: %v", err)
	}
}

func TestLoadIndexerConfigFromEnv_BlockOnRelativeFileSource(t *testing.T) {
	t.Setenv("INDEXER_STORE_BACKEND", "postgres")
	t.Setenv("INDEXER_POSTGRES_DSN_FILE", "relative-secret.txt")
	cfg, err := LoadIndexerConfigFromEnv()
	if err == nil {
		t.Fatalf("expected relative file source to be rejected, got cfg=%+v", cfg)
	}
	if !strings.Contains(err.Error(), "absolute path") {
		t.Fatalf("expected absolute path error, got: %v", err)
	}
}

func TestLoadAPIConfigFromEnv_AllowsFallbackFromIndexerSensitiveSource(t *testing.T) {
	t.Setenv("API_STORE_BACKEND", "postgres")
	t.Setenv("INDEXER_POSTGRES_DSN", "postgres://indexer:pwd@127.0.0.1:5432/soulon?sslmode=disable")
	cfg, err := LoadAPIConfigFromEnv()
	if err != nil {
		t.Fatalf("expected api config to use indexer sensitive source, got error: %v", err)
	}
	if cfg.PostgresDSN != "postgres://indexer:pwd@127.0.0.1:5432/soulon?sslmode=disable" {
		t.Fatalf("unexpected postgres dsn fallback: %s", cfg.PostgresDSN)
	}
}

func TestLoadAPIConfigFromEnv_BlockOnDualSensitiveSource(t *testing.T) {
	t.Setenv("API_STORE_BACKEND", "postgres")
	dsnFile := writeTempSecretFile(t, "postgres://file:pwd@127.0.0.1:5432/soulon?sslmode=disable")
	t.Setenv("API_POSTGRES_DSN", "postgres://env:pwd@127.0.0.1:5432/soulon?sslmode=disable")
	t.Setenv("API_POSTGRES_DSN_FILE", dsnFile)
	cfg, err := LoadAPIConfigFromEnv()
	if err == nil {
		t.Fatalf("expected dual source conflict to block startup, got cfg=%+v", cfg)
	}
	if !strings.Contains(err.Error(), "only one source") {
		t.Fatalf("expected dual source error, got: %v", err)
	}
}

func TestConfigFieldPolicies_ContainsHighSensitivePolicies(t *testing.T) {
	policies := ConfigFieldPolicies()
	policyMap := map[string]ConfigFieldPolicy{}
	for _, item := range policies {
		policyMap[item.Key] = item
	}
	required := []string{"INDEXER_POSTGRES_DSN", "INDEXER_NOTIFY_AUTH_TOKEN", "API_POSTGRES_DSN", "API_NOTIFY_WEBHOOK_TOKEN"}
	for _, key := range required {
		policy, exists := policyMap[key]
		if !exists {
			t.Fatalf("policy missing for key: %s", key)
		}
		if policy.Sensitivity != ConfigSensitivityHigh {
			t.Fatalf("policy sensitivity mismatch for key=%s: %s", key, policy.Sensitivity)
		}
		if !sourceAllowed(policy, ConfigSourceEnv) || !sourceAllowed(policy, ConfigSourceFile) {
			t.Fatalf("high-sensitive policy source mismatch for key=%s", key)
		}
		if sourceAllowed(policy, ConfigSourceDefault) {
			t.Fatalf("high-sensitive policy should not allow default source for key=%s", key)
		}
	}
}

func writeTempSecretFile(t *testing.T, value string) string {
	t.Helper()
	file, err := os.CreateTemp(t.TempDir(), "secret-*.txt")
	if err != nil {
		t.Fatalf("failed to create temp file: %v", err)
	}
	path := file.Name()
	if err := file.Close(); err != nil {
		t.Fatalf("failed to close temp file: %v", err)
	}
	if err := os.WriteFile(path, []byte(value), 0o600); err != nil {
		t.Fatalf("failed to write temp secret file: %v", err)
	}
	absPath, err := filepath.Abs(path)
	if err != nil {
		t.Fatalf("failed to resolve absolute path: %v", err)
	}
	return absPath
}
