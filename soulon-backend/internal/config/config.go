package config

import (
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

type ConfigSensitivity string

const (
	ConfigSensitivityPublic   ConfigSensitivity = "public"
	ConfigSensitivityInternal ConfigSensitivity = "internal"
	ConfigSensitivityHigh     ConfigSensitivity = "high"
)

type ConfigSource string

const (
	ConfigSourceDefault ConfigSource = "default"
	ConfigSourceEnv     ConfigSource = "env"
	ConfigSourceFile    ConfigSource = "file"
)

type ConfigFieldPolicy struct {
	Key            string
	Sensitivity    ConfigSensitivity
	AllowedSources []ConfigSource
}

type ConfigValidationError struct {
	Key     string
	Message string
}

func (e ConfigValidationError) Error() string {
	return fmt.Sprintf("config validation failed for %s: %s", e.Key, e.Message)
}

var configFieldPolicies = []ConfigFieldPolicy{
	{Key: "GATEWAY_LISTEN_ADDR", Sensitivity: ConfigSensitivityPublic, AllowedSources: []ConfigSource{ConfigSourceDefault, ConfigSourceEnv}},
	{Key: "GATEWAY_NODE_ENDPOINTS", Sensitivity: ConfigSensitivityInternal, AllowedSources: []ConfigSource{ConfigSourceDefault, ConfigSourceEnv}},
	{Key: "GATEWAY_HEALTH_CHECK_MS", Sensitivity: ConfigSensitivityInternal, AllowedSources: []ConfigSource{ConfigSourceDefault, ConfigSourceEnv}},
	{Key: "GATEWAY_FORWARD_TIMEOUT_MS", Sensitivity: ConfigSensitivityInternal, AllowedSources: []ConfigSource{ConfigSourceDefault, ConfigSourceEnv}},
	{Key: "INDEXER_STORE_BACKEND", Sensitivity: ConfigSensitivityInternal, AllowedSources: []ConfigSource{ConfigSourceDefault, ConfigSourceEnv}},
	{Key: "INDEXER_POSTGRES_DSN", Sensitivity: ConfigSensitivityHigh, AllowedSources: []ConfigSource{ConfigSourceEnv, ConfigSourceFile}},
	{Key: "INDEXER_NOTIFY_AUTH_TOKEN", Sensitivity: ConfigSensitivityHigh, AllowedSources: []ConfigSource{ConfigSourceEnv, ConfigSourceFile}},
	{Key: "API_STORE_BACKEND", Sensitivity: ConfigSensitivityInternal, AllowedSources: []ConfigSource{ConfigSourceDefault, ConfigSourceEnv}},
	{Key: "API_POSTGRES_DSN", Sensitivity: ConfigSensitivityHigh, AllowedSources: []ConfigSource{ConfigSourceEnv, ConfigSourceFile}},
	{Key: "API_NOTIFY_WEBHOOK_TOKEN", Sensitivity: ConfigSensitivityHigh, AllowedSources: []ConfigSource{ConfigSourceEnv, ConfigSourceFile}},
}

var configFieldPolicyMap = buildConfigFieldPolicyMap(configFieldPolicies)

type GatewayConfig struct {
	ListenAddr          string
	NodeEndpoints       []string
	HealthCheckInterval time.Duration
	ForwardTimeout      time.Duration
}

type IndexerConfig struct {
	PollInterval            time.Duration
	ReorgInterval           int64
	QueueBackend            string
	KafkaBrokers            []string
	KafkaTopic              string
	KafkaDLQTopic           string
	KafkaGroupID            string
	KafkaKeyStrategy        string
	KafkaWriteTimeoutMs     int
	KafkaWriteRetries       int
	StoreBackend            string
	PostgresDSN             string
	PostgresRetentionBlocks int64
	QueueBuffer             int
	EventStorePath          string
	PersistMaxRetries       int
	PersistRetryBackoffMs   int
	PersistFailurePolicy    string
	ConsumePauseMs          int
	MaintenanceIntervalMs   int
	MetricsListenAddr       string
	NotifyWebhookURL        string
	NotifyTimeoutMs         int
	NotifyRetries           int
	NotifyAuthToken         string
}

type APIConfig struct {
	ListenAddr           string
	EventStorePath       string
	StoreBackend         string
	PostgresDSN          string
	NotifyWebhookToken   string
	NotificationCapacity int
}

func LoadGatewayConfigFromEnv() (GatewayConfig, error) {
	listenAddr := getEnv("GATEWAY_LISTEN_ADDR", ":8081")
	rawEndpoints := getEnv("GATEWAY_NODE_ENDPOINTS", "http://127.0.0.1:26657")
	endpoints := splitCSV(rawEndpoints)
	healthMs := getEnvInt("GATEWAY_HEALTH_CHECK_MS", 5000)
	forwardMs := getEnvInt("GATEWAY_FORWARD_TIMEOUT_MS", 4000)
	return GatewayConfig{
		ListenAddr:          listenAddr,
		NodeEndpoints:       endpoints,
		HealthCheckInterval: time.Duration(healthMs) * time.Millisecond,
		ForwardTimeout:      time.Duration(forwardMs) * time.Millisecond,
	}, nil
}

func LoadIndexerConfigFromEnv() (IndexerConfig, error) {
	pollMs := getEnvInt("INDEXER_POLL_INTERVAL_MS", 2000)
	reorgInterval := getEnvInt("INDEXER_REORG_INTERVAL", 0)
	queueBackend := getEnv("INDEXER_QUEUE_BACKEND", "memory")
	kafkaBrokers := splitCSV(getEnv("INDEXER_KAFKA_BROKERS", "127.0.0.1:9092"))
	kafkaTopic := getEnv("INDEXER_KAFKA_TOPIC", "soulon.indexer.events")
	kafkaDLQTopic := getEnv("INDEXER_KAFKA_DLQ_TOPIC", "soulon.indexer.events.dlq")
	kafkaGroupID := getEnv("INDEXER_KAFKA_GROUP_ID", "soulon-indexer")
	kafkaKeyStrategy := getEnv("INDEXER_KAFKA_KEY_STRATEGY", "id")
	kafkaWriteTimeoutMs := getEnvInt("INDEXER_KAFKA_WRITE_TIMEOUT_MS", 3000)
	kafkaWriteRetries := getEnvInt("INDEXER_KAFKA_WRITE_RETRIES", 3)
	storeBackend := getEnv("INDEXER_STORE_BACKEND", "file")
	postgresDSN, _, err := loadConfigValue("INDEXER_POSTGRES_DSN", "")
	if err != nil {
		return IndexerConfig{}, err
	}
	postgresRetentionBlocks := int64(getEnvInt("INDEXER_POSTGRES_RETENTION_BLOCKS", 0))
	queueBuffer := getEnvInt("INDEXER_QUEUE_BUFFER", 128)
	eventStorePath := getEnv("INDEXER_EVENT_STORE_PATH", "data/indexer-events.jsonl")
	persistMaxRetries := getEnvInt("INDEXER_PERSIST_MAX_RETRIES", 3)
	persistRetryBackoffMs := getEnvInt("INDEXER_PERSIST_RETRY_BACKOFF_MS", 500)
	persistFailurePolicy := getEnv("INDEXER_PERSIST_FAILURE_POLICY", "stop")
	consumePauseMs := getEnvInt("INDEXER_CONSUME_PAUSE_MS", 3000)
	maintenanceIntervalMs := getEnvInt("INDEXER_MAINTENANCE_INTERVAL_MS", 60000)
	metricsListenAddr := getEnv("INDEXER_METRICS_LISTEN_ADDR", "")
	notifyWebhookURL := getEnv("INDEXER_NOTIFY_WEBHOOK_URL", "")
	notifyTimeoutMs := getEnvInt("INDEXER_NOTIFY_TIMEOUT_MS", 3000)
	notifyRetries := getEnvInt("INDEXER_NOTIFY_RETRIES", 2)
	notifyAuthToken, _, err := loadConfigValue("INDEXER_NOTIFY_AUTH_TOKEN", "")
	if err != nil {
		return IndexerConfig{}, err
	}
	cfg := IndexerConfig{
		PollInterval:            time.Duration(pollMs) * time.Millisecond,
		ReorgInterval:           int64(reorgInterval),
		QueueBackend:            queueBackend,
		KafkaBrokers:            kafkaBrokers,
		KafkaTopic:              kafkaTopic,
		KafkaDLQTopic:           kafkaDLQTopic,
		KafkaGroupID:            kafkaGroupID,
		KafkaKeyStrategy:        kafkaKeyStrategy,
		KafkaWriteTimeoutMs:     kafkaWriteTimeoutMs,
		KafkaWriteRetries:       kafkaWriteRetries,
		StoreBackend:            storeBackend,
		PostgresDSN:             postgresDSN,
		PostgresRetentionBlocks: postgresRetentionBlocks,
		QueueBuffer:             queueBuffer,
		EventStorePath:          eventStorePath,
		PersistMaxRetries:       persistMaxRetries,
		PersistRetryBackoffMs:   persistRetryBackoffMs,
		PersistFailurePolicy:    persistFailurePolicy,
		ConsumePauseMs:          consumePauseMs,
		MaintenanceIntervalMs:   maintenanceIntervalMs,
		MetricsListenAddr:       metricsListenAddr,
		NotifyWebhookURL:        notifyWebhookURL,
		NotifyTimeoutMs:         notifyTimeoutMs,
		NotifyRetries:           notifyRetries,
		NotifyAuthToken:         notifyAuthToken,
	}
	if err := validateIndexerConfig(cfg); err != nil {
		return IndexerConfig{}, err
	}
	return cfg, nil
}

func LoadAPIConfigFromEnv() (APIConfig, error) {
	listenAddr := getEnv("API_LISTEN_ADDR", ":8082")
	eventStorePath := getEnv("INDEXER_EVENT_STORE_PATH", "data/indexer-events.jsonl")
	storeBackend := strings.ToLower(strings.TrimSpace(getEnv("API_STORE_BACKEND", "auto")))
	if storeBackend != "auto" && storeBackend != "file" && storeBackend != "postgres" {
		storeBackend = "auto"
	}
	postgresDSN, _, err := loadConfigValue("API_POSTGRES_DSN", "")
	if err != nil {
		return APIConfig{}, err
	}
	if strings.TrimSpace(postgresDSN) == "" {
		postgresDSN, _, err = loadConfigValue("INDEXER_POSTGRES_DSN", "")
		if err != nil {
			return APIConfig{}, err
		}
	}
	notifyWebhookToken, _, err := loadConfigValue("API_NOTIFY_WEBHOOK_TOKEN", "")
	if err != nil {
		return APIConfig{}, err
	}
	if strings.TrimSpace(notifyWebhookToken) == "" {
		notifyWebhookToken, _, err = loadConfigValue("INDEXER_NOTIFY_AUTH_TOKEN", "")
		if err != nil {
			return APIConfig{}, err
		}
	}
	notificationCapacity := getEnvInt("API_NOTIFICATION_CAPACITY", 200)
	cfg := APIConfig{
		ListenAddr:           listenAddr,
		EventStorePath:       eventStorePath,
		StoreBackend:         storeBackend,
		PostgresDSN:          postgresDSN,
		NotifyWebhookToken:   notifyWebhookToken,
		NotificationCapacity: notificationCapacity,
	}
	if err := validateAPIConfig(cfg); err != nil {
		return APIConfig{}, err
	}
	return cfg, nil
}

func getEnv(key string, fallback string) string {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}
	return value
}

func getEnvInt(key string, fallback int) int {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}
	parsed, err := strconv.Atoi(value)
	if err != nil {
		return fallback
	}
	return parsed
}

func splitCSV(value string) []string {
	parts := strings.Split(value, ",")
	result := make([]string, 0, len(parts))
	for _, part := range parts {
		trimmed := strings.TrimSpace(part)
		if trimmed != "" {
			result = append(result, trimmed)
		}
	}
	if len(result) == 0 {
		return []string{"http://127.0.0.1:26657"}
	}
	return result
}

func ConfigFieldPolicies() []ConfigFieldPolicy {
	policies := make([]ConfigFieldPolicy, len(configFieldPolicies))
	copy(policies, configFieldPolicies)
	return policies
}

func validateIndexerConfig(cfg IndexerConfig) error {
	if strings.EqualFold(strings.TrimSpace(cfg.StoreBackend), "postgres") && strings.TrimSpace(cfg.PostgresDSN) == "" {
		return ConfigValidationError{
			Key:     "INDEXER_POSTGRES_DSN",
			Message: "required when INDEXER_STORE_BACKEND=postgres",
		}
	}
	if strings.TrimSpace(cfg.NotifyWebhookURL) != "" && strings.TrimSpace(cfg.NotifyAuthToken) == "" {
		return ConfigValidationError{
			Key:     "INDEXER_NOTIFY_AUTH_TOKEN",
			Message: "required when INDEXER_NOTIFY_WEBHOOK_URL is set",
		}
	}
	return nil
}

func validateAPIConfig(cfg APIConfig) error {
	if strings.EqualFold(strings.TrimSpace(cfg.StoreBackend), "postgres") && strings.TrimSpace(cfg.PostgresDSN) == "" {
		return ConfigValidationError{
			Key:     "API_POSTGRES_DSN",
			Message: "required when API_STORE_BACKEND=postgres",
		}
	}
	return nil
}

func loadConfigValue(key string, fallback string) (string, ConfigSource, error) {
	fileKey := key + "_FILE"
	value := strings.TrimSpace(os.Getenv(key))
	filePath := strings.TrimSpace(os.Getenv(fileKey))
	policy, hasPolicy := configFieldPolicyMap[key]
	if value != "" && filePath != "" {
		return "", "", ConfigValidationError{
			Key:     key,
			Message: "only one source is allowed between env and file",
		}
	}
	if filePath != "" {
		if hasPolicy && !sourceAllowed(policy, ConfigSourceFile) {
			return "", "", ConfigValidationError{
				Key:     key,
				Message: "file source is not allowed",
			}
		}
		if !filepath.IsAbs(filePath) {
			return "", "", ConfigValidationError{
				Key:     key,
				Message: "file source must use absolute path",
			}
		}
		content, err := os.ReadFile(filePath)
		if err != nil {
			return "", "", ConfigValidationError{
				Key:     key,
				Message: fmt.Sprintf("unable to read file source: %v", err),
			}
		}
		trimmed := strings.TrimSpace(string(content))
		if trimmed == "" {
			return "", "", ConfigValidationError{
				Key:     key,
				Message: "file source value is empty",
			}
		}
		return trimmed, ConfigSourceFile, nil
	}
	if value != "" {
		if hasPolicy && !sourceAllowed(policy, ConfigSourceEnv) {
			return "", "", ConfigValidationError{
				Key:     key,
				Message: "env source is not allowed",
			}
		}
		return value, ConfigSourceEnv, nil
	}
	if fallback != "" {
		if hasPolicy && !sourceAllowed(policy, ConfigSourceDefault) {
			return "", "", ConfigValidationError{
				Key:     key,
				Message: "default source is not allowed",
			}
		}
		return fallback, ConfigSourceDefault, nil
	}
	return "", ConfigSourceDefault, nil
}

func sourceAllowed(policy ConfigFieldPolicy, source ConfigSource) bool {
	for _, item := range policy.AllowedSources {
		if item == source {
			return true
		}
	}
	return false
}

func buildConfigFieldPolicyMap(items []ConfigFieldPolicy) map[string]ConfigFieldPolicy {
	policyMap := make(map[string]ConfigFieldPolicy, len(items))
	for _, item := range items {
		policyMap[item.Key] = item
	}
	return policyMap
}
