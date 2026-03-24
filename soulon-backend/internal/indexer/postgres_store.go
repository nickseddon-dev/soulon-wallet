package indexer

import (
	"context"
	"database/sql"
	"fmt"
	"sync"
	"time"

	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

var (
	postgresUpsertSeconds = promauto.NewHistogram(prometheus.HistogramOpts{
		Name:    "indexer_postgres_upsert_seconds",
		Help:    "Duration of postgres upsert operations.",
		Buckets: prometheus.DefBuckets,
	})
	postgresMaintenanceSeconds = promauto.NewHistogram(prometheus.HistogramOpts{
		Name:    "indexer_postgres_maintenance_seconds",
		Help:    "Duration of postgres maintenance operations.",
		Buckets: prometheus.DefBuckets,
	})
	postgresMaintenanceErrorsTotal = promauto.NewCounter(prometheus.CounterOpts{
		Name: "indexer_postgres_maintenance_errors_total",
		Help: "Total number of postgres maintenance failures.",
	})
	postgresArchivedRowsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "indexer_postgres_archived_rows_total",
			Help: "Total number of archived rows by table.",
		},
		[]string{"table"},
	)
	postgresDeletedRowsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "indexer_postgres_deleted_rows_total",
			Help: "Total number of deleted rows by table during retention cleanup.",
		},
		[]string{"table"},
	)
)

type PostgresStore struct {
	db              *sql.DB
	retentionBlocks int64
	initOnce        sync.Once
	initErr         error
	mu              sync.Mutex
}

type cleanupStats struct {
	archivedBlocks int64
	archivedEvents int64
	deletedBlocks  int64
	deletedEvents  int64
}

func NewPostgresStore(dsn string, retentionBlocks int64) (*PostgresStore, error) {
	if dsn == "" {
		return nil, fmt.Errorf("postgres dsn is empty")
	}
	db, err := sql.Open("pgx", dsn)
	if err != nil {
		return nil, err
	}
	db.SetMaxOpenConns(20)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(30 * time.Minute)
	return &PostgresStore{
		db:              db,
		retentionBlocks: retentionBlocks,
	}, nil
}

func (s *PostgresStore) Upsert(ctx context.Context, event Event) (bool, error) {
	startedAt := time.Now()
	defer postgresUpsertSeconds.Observe(time.Since(startedAt).Seconds())
	if err := s.ensureInitialized(ctx); err != nil {
		return false, err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	tx, err := s.db.BeginTx(ctx, &sql.TxOptions{})
	if err != nil {
		return false, err
	}
	defer tx.Rollback()
	if event.Type == "" {
		event.Type = "new_block"
	}
	if event.ProducedAt.IsZero() {
		event.ProducedAt = time.Now()
	}
	if event.Type == "rollback" {
		if event.RollbackFrom <= 0 {
			return false, fmt.Errorf("invalid rollback height: %d", event.RollbackFrom)
		}
		event.ID = fmt.Sprintf("rollback-%d-%d", event.RollbackFrom, time.Now().UnixNano())
		event.Height = event.RollbackFrom
		if err := s.appendEventTx(ctx, tx, event); err != nil {
			return false, err
		}
		if err := s.applyRollbackTx(ctx, tx, event.RollbackFrom); err != nil {
			return false, err
		}
		if _, err := tx.ExecContext(ctx, `UPDATE indexer_state SET reorgs = reorgs + 1 WHERE id = 1`); err != nil {
			return false, err
		}
		if err := s.refreshStateTx(ctx, tx); err != nil {
			return false, err
		}
		if err := tx.Commit(); err != nil {
			return false, err
		}
		return true, nil
	}
	if event.ID == "" {
		if event.BlockHash != "" {
			event.ID = event.BlockHash
		} else {
			event.ID = fmt.Sprintf("block-%d", event.Height)
		}
	}
	if event.BlockHash == "" {
		event.BlockHash = event.ID
	}
	var exists bool
	if err := tx.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM indexer_blocks WHERE event_id = $1)`, event.ID).Scan(&exists); err != nil {
		return false, err
	}
	if exists {
		if err := tx.Commit(); err != nil {
			return false, err
		}
		return false, nil
	}
	needRollback, rollbackFrom, err := s.requiresRollbackTx(ctx, tx, event)
	if err != nil {
		return false, err
	}
	if needRollback {
		rollbackEvent := Event{
			ID:           fmt.Sprintf("rollback-%d-%d", rollbackFrom, time.Now().UnixNano()),
			Height:       rollbackFrom,
			Type:         "rollback",
			RollbackFrom: rollbackFrom,
			Payload:      fmt.Sprintf(`{"rollbackFrom":%d}`, rollbackFrom),
			ProducedAt:   event.ProducedAt,
		}
		if err := s.appendEventTx(ctx, tx, rollbackEvent); err != nil {
			return false, err
		}
		if err := s.applyRollbackTx(ctx, tx, rollbackFrom); err != nil {
			return false, err
		}
		if _, err := tx.ExecContext(ctx, `UPDATE indexer_state SET reorgs = reorgs + 1 WHERE id = 1`); err != nil {
			return false, err
		}
	}
	if err := s.appendEventTx(ctx, tx, event); err != nil {
		return false, err
	}
	if _, err := tx.ExecContext(
		ctx,
		`INSERT INTO indexer_blocks(height, event_id, block_hash, parent_hash, payload, produced_at, persisted_at)
		 VALUES($1,$2,$3,$4,$5,$6,$7)
		 ON CONFLICT(height) DO UPDATE SET
		     event_id = EXCLUDED.event_id,
		     block_hash = EXCLUDED.block_hash,
		     parent_hash = EXCLUDED.parent_hash,
		     payload = EXCLUDED.payload,
		     produced_at = EXCLUDED.produced_at,
		     persisted_at = EXCLUDED.persisted_at`,
		event.Height,
		event.ID,
		event.BlockHash,
		event.ParentHash,
		event.Payload,
		event.ProducedAt,
		time.Now(),
	); err != nil {
		return false, err
	}
	if err := s.refreshStateTx(ctx, tx); err != nil {
		return false, err
	}
	cleanupStats, err := s.cleanupOldBlocksTx(ctx, tx)
	if err != nil {
		return false, err
	}
	s.observeCleanupStats(cleanupStats)
	if err := s.refreshStateTx(ctx, tx); err != nil {
		return false, err
	}
	if err := tx.Commit(); err != nil {
		return false, err
	}
	return true, nil
}

func (s *PostgresStore) Count() int {
	if err := s.ensureInitialized(context.Background()); err != nil {
		return 0
	}
	var count int
	if err := s.db.QueryRow(`SELECT COUNT(*) FROM indexer_blocks`).Scan(&count); err != nil {
		return 0
	}
	return count
}

func (s *PostgresStore) State() StoreState {
	if err := s.ensureInitialized(context.Background()); err != nil {
		return StoreState{}
	}
	var state StoreState
	if err := s.db.QueryRow(`SELECT tip_height, tip_hash, total, reorgs FROM indexer_state WHERE id = 1`).Scan(
		&state.TipHeight,
		&state.TipHash,
		&state.Total,
		&state.Reorgs,
	); err != nil {
		return StoreState{}
	}
	return state
}

func (s *PostgresStore) RunMaintenance(ctx context.Context) error {
	startedAt := time.Now()
	defer postgresMaintenanceSeconds.Observe(time.Since(startedAt).Seconds())
	if err := s.ensureInitialized(ctx); err != nil {
		postgresMaintenanceErrorsTotal.Inc()
		return err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	tx, err := s.db.BeginTx(ctx, &sql.TxOptions{})
	if err != nil {
		postgresMaintenanceErrorsTotal.Inc()
		return err
	}
	defer tx.Rollback()
	if err := s.refreshStateTx(ctx, tx); err != nil {
		postgresMaintenanceErrorsTotal.Inc()
		return err
	}
	stats, err := s.cleanupOldBlocksTx(ctx, tx)
	if err != nil {
		postgresMaintenanceErrorsTotal.Inc()
		return err
	}
	s.observeCleanupStats(stats)
	if err := s.refreshStateTx(ctx, tx); err != nil {
		postgresMaintenanceErrorsTotal.Inc()
		return err
	}
	if err := tx.Commit(); err != nil {
		postgresMaintenanceErrorsTotal.Inc()
		return err
	}
	return nil
}

func (s *PostgresStore) ensureInitialized(ctx context.Context) error {
	s.initOnce.Do(func() {
		if err := s.db.PingContext(ctx); err != nil {
			s.initErr = err
			return
		}
		s.initErr = s.initSchema(ctx)
	})
	return s.initErr
}

func (s *PostgresStore) initSchema(ctx context.Context) error {
	statements := []string{
		`CREATE TABLE IF NOT EXISTS indexer_schema_migrations(
			version BIGINT PRIMARY KEY,
			applied_at TIMESTAMPTZ NOT NULL
		)`,
	}
	for _, statement := range statements {
		if _, err := s.db.ExecContext(ctx, statement); err != nil {
			return err
		}
	}
	migrations := []struct {
		version int64
		sql     string
	}{
		{
			version: 1,
			sql: `CREATE TABLE IF NOT EXISTS indexer_events(
			id TEXT PRIMARY KEY,
			height BIGINT NOT NULL,
			type TEXT NOT NULL,
			block_hash TEXT,
			parent_hash TEXT,
			rollback_from BIGINT,
			payload TEXT NOT NULL,
			produced_at TIMESTAMPTZ NOT NULL,
			persisted_at TIMESTAMPTZ NOT NULL
		)`,
		},
		{
			version: 2,
			sql: `CREATE TABLE IF NOT EXISTS indexer_events_log(
			seq BIGSERIAL PRIMARY KEY,
			event_id TEXT NOT NULL,
			height BIGINT NOT NULL,
			type TEXT NOT NULL,
			block_hash TEXT,
			parent_hash TEXT,
			rollback_from BIGINT,
			payload TEXT NOT NULL,
			produced_at TIMESTAMPTZ NOT NULL,
			persisted_at TIMESTAMPTZ NOT NULL
		)`,
		},
		{
			version: 3,
			sql: `CREATE TABLE IF NOT EXISTS indexer_blocks(
			height BIGINT PRIMARY KEY,
			event_id TEXT UNIQUE NOT NULL,
			block_hash TEXT UNIQUE NOT NULL,
			parent_hash TEXT,
			payload TEXT NOT NULL,
			produced_at TIMESTAMPTZ NOT NULL,
			persisted_at TIMESTAMPTZ NOT NULL
		)`,
		},
		{
			version: 4,
			sql: `CREATE TABLE IF NOT EXISTS indexer_state(
			id INT PRIMARY KEY,
			tip_height BIGINT NOT NULL DEFAULT 0,
			tip_hash TEXT NOT NULL DEFAULT '',
			total INT NOT NULL DEFAULT 0,
			reorgs INT NOT NULL DEFAULT 0
		)`,
		},
		{
			version: 5,
			sql: `INSERT INTO indexer_state(id, tip_height, tip_hash, total, reorgs)
		 VALUES(1, 0, '', 0, 0)
		 ON CONFLICT(id) DO NOTHING`,
		},
		{
			version: 6,
			sql:     `CREATE INDEX IF NOT EXISTS idx_indexer_events_height ON indexer_events(height)`,
		},
		{
			version: 7,
			sql:     `CREATE INDEX IF NOT EXISTS idx_indexer_events_log_height_seq ON indexer_events_log(height, seq DESC)`,
		},
		{
			version: 8,
			sql:     `CREATE INDEX IF NOT EXISTS idx_indexer_blocks_parent_hash ON indexer_blocks(parent_hash)`,
		},
		{
			version: 9,
			sql: `CREATE TABLE IF NOT EXISTS indexer_events_archive(
			id TEXT PRIMARY KEY,
			height BIGINT NOT NULL,
			type TEXT NOT NULL,
			block_hash TEXT,
			parent_hash TEXT,
			rollback_from BIGINT,
			payload TEXT NOT NULL,
			produced_at TIMESTAMPTZ NOT NULL,
			persisted_at TIMESTAMPTZ NOT NULL,
			archived_at TIMESTAMPTZ NOT NULL
		)`,
		},
		{
			version: 10,
			sql: `CREATE TABLE IF NOT EXISTS indexer_blocks_archive(
			height BIGINT PRIMARY KEY,
			event_id TEXT UNIQUE NOT NULL,
			block_hash TEXT UNIQUE NOT NULL,
			parent_hash TEXT,
			payload TEXT NOT NULL,
			produced_at TIMESTAMPTZ NOT NULL,
			persisted_at TIMESTAMPTZ NOT NULL,
			archived_at TIMESTAMPTZ NOT NULL
		)`,
		},
	}
	for _, migration := range migrations {
		var exists bool
		if err := s.db.QueryRowContext(
			ctx,
			`SELECT EXISTS(SELECT 1 FROM indexer_schema_migrations WHERE version = $1)`,
			migration.version,
		).Scan(&exists); err != nil {
			return err
		}
		if exists {
			continue
		}
		if _, err := s.db.ExecContext(ctx, migration.sql); err != nil {
			return err
		}
		if _, err := s.db.ExecContext(
			ctx,
			`INSERT INTO indexer_schema_migrations(version, applied_at) VALUES($1, $2)`,
			migration.version,
			time.Now().UTC(),
		); err != nil {
			return err
		}
	}
	return nil
}

func (s *PostgresStore) appendEventTx(ctx context.Context, tx *sql.Tx, event Event) error {
	persistedAt := time.Now()
	if _, err := tx.ExecContext(
		ctx,
		`INSERT INTO indexer_events(id, height, type, block_hash, parent_hash, rollback_from, payload, produced_at, persisted_at)
		 VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9)
		 ON CONFLICT(id) DO NOTHING`,
		event.ID,
		event.Height,
		event.Type,
		nullString(event.BlockHash),
		nullString(event.ParentHash),
		nullInt64(event.RollbackFrom),
		event.Payload,
		event.ProducedAt,
		persistedAt,
	); err != nil {
		return err
	}
	if _, err := tx.ExecContext(
		ctx,
		`INSERT INTO indexer_events_log(event_id, height, type, block_hash, parent_hash, rollback_from, payload, produced_at, persisted_at)
		 VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9)`,
		event.ID,
		event.Height,
		event.Type,
		nullString(event.BlockHash),
		nullString(event.ParentHash),
		nullInt64(event.RollbackFrom),
		event.Payload,
		event.ProducedAt,
		persistedAt,
	); err != nil {
		return err
	}
	return nil
}

func (s *PostgresStore) applyRollbackTx(ctx context.Context, tx *sql.Tx, rollbackFrom int64) error {
	rows, err := tx.QueryContext(ctx, `SELECT event_id FROM indexer_blocks WHERE height >= $1`, rollbackFrom)
	if err != nil {
		return err
	}
	eventIDs := make([]string, 0)
	for rows.Next() {
		var eventID string
		if scanErr := rows.Scan(&eventID); scanErr != nil {
			_ = rows.Close()
			return scanErr
		}
		eventIDs = append(eventIDs, eventID)
	}
	if err := rows.Close(); err != nil {
		return err
	}
	if _, err := tx.ExecContext(ctx, `DELETE FROM indexer_blocks WHERE height >= $1`, rollbackFrom); err != nil {
		return err
	}
	for _, eventID := range eventIDs {
		if _, err := tx.ExecContext(ctx, `DELETE FROM indexer_events WHERE id = $1`, eventID); err != nil {
			return err
		}
	}
	return nil
}

func (s *PostgresStore) requiresRollbackTx(ctx context.Context, tx *sql.Tx, event Event) (bool, int64, error) {
	var existingHash sql.NullString
	if err := tx.QueryRowContext(
		ctx,
		`SELECT block_hash FROM indexer_blocks WHERE height = $1`,
		event.Height,
	).Scan(&existingHash); err == nil {
		if existingHash.Valid && existingHash.String != event.BlockHash {
			return true, event.Height, nil
		}
	}
	var tipHeight int64
	var tipHash string
	if err := tx.QueryRowContext(ctx, `SELECT tip_height, tip_hash FROM indexer_state WHERE id = 1`).Scan(&tipHeight, &tipHash); err != nil {
		return false, 0, err
	}
	if tipHeight > 0 && event.Height <= tipHeight {
		return true, event.Height, nil
	}
	if tipHash != "" && event.ParentHash != "" && tipHash != event.ParentHash {
		rollbackFrom := event.Height - 1
		if rollbackFrom <= 0 {
			rollbackFrom = 1
		}
		return true, rollbackFrom, nil
	}
	return false, 0, nil
}

func (s *PostgresStore) refreshStateTx(ctx context.Context, tx *sql.Tx) error {
	var tipHeight int64
	var tipHash string
	tipRow := tx.QueryRowContext(ctx, `SELECT height, block_hash FROM indexer_blocks ORDER BY height DESC LIMIT 1`)
	if err := tipRow.Scan(&tipHeight, &tipHash); err != nil {
		if err == sql.ErrNoRows {
			tipHeight = 0
			tipHash = ""
		} else {
			return err
		}
	}
	var total int
	if err := tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM indexer_blocks`).Scan(&total); err != nil {
		return err
	}
	if _, err := tx.ExecContext(
		ctx,
		`UPDATE indexer_state SET tip_height = $1, tip_hash = $2, total = $3 WHERE id = 1`,
		tipHeight,
		tipHash,
		total,
	); err != nil {
		return err
	}
	return nil
}

func (s *PostgresStore) cleanupOldBlocksTx(ctx context.Context, tx *sql.Tx) (cleanupStats, error) {
	stats := cleanupStats{}
	if s.retentionBlocks <= 0 {
		return stats, nil
	}
	var tipHeight int64
	if err := tx.QueryRowContext(ctx, `SELECT tip_height FROM indexer_state WHERE id = 1`).Scan(&tipHeight); err != nil {
		return stats, err
	}
	keepFrom := tipHeight - s.retentionBlocks + 1
	if keepFrom <= 1 {
		return stats, nil
	}
	result, err := tx.ExecContext(
		ctx,
		`INSERT INTO indexer_blocks_archive(height, event_id, block_hash, parent_hash, payload, produced_at, persisted_at, archived_at)
		 SELECT height, event_id, block_hash, parent_hash, payload, produced_at, persisted_at, $1
		 FROM indexer_blocks
		 WHERE height < $2
		 ON CONFLICT(height) DO NOTHING`,
		time.Now().UTC(),
		keepFrom,
	)
	if err != nil {
		return stats, err
	}
	archivedBlocks, err := result.RowsAffected()
	if err == nil {
		stats.archivedBlocks = archivedBlocks
	}
	result, err = tx.ExecContext(
		ctx,
		`INSERT INTO indexer_events_archive(id, height, type, block_hash, parent_hash, rollback_from, payload, produced_at, persisted_at, archived_at)
		 SELECT e.id, e.height, e.type, e.block_hash, e.parent_hash, e.rollback_from, e.payload, e.produced_at, e.persisted_at, $1
		 FROM indexer_events e
		 JOIN indexer_blocks_archive b ON b.event_id = e.id
		 WHERE e.height < $2
		 ON CONFLICT(id) DO NOTHING`,
		time.Now().UTC(),
		keepFrom,
	)
	if err != nil {
		return stats, err
	}
	archivedEvents, err := result.RowsAffected()
	if err == nil {
		stats.archivedEvents = archivedEvents
	}
	result, err = tx.ExecContext(ctx, `DELETE FROM indexer_events WHERE height < $1`, keepFrom)
	if err != nil {
		return stats, err
	}
	deletedEvents, err := result.RowsAffected()
	if err == nil {
		stats.deletedEvents = deletedEvents
	}
	result, err = tx.ExecContext(ctx, `DELETE FROM indexer_blocks WHERE height < $1`, keepFrom)
	if err != nil {
		return stats, err
	}
	deletedBlocks, err := result.RowsAffected()
	if err == nil {
		stats.deletedBlocks = deletedBlocks
	}
	return stats, nil
}

func (s *PostgresStore) observeCleanupStats(stats cleanupStats) {
	if stats.archivedBlocks > 0 {
		postgresArchivedRowsTotal.WithLabelValues("blocks").Add(float64(stats.archivedBlocks))
	}
	if stats.archivedEvents > 0 {
		postgresArchivedRowsTotal.WithLabelValues("events").Add(float64(stats.archivedEvents))
	}
	if stats.deletedBlocks > 0 {
		postgresDeletedRowsTotal.WithLabelValues("blocks").Add(float64(stats.deletedBlocks))
	}
	if stats.deletedEvents > 0 {
		postgresDeletedRowsTotal.WithLabelValues("events").Add(float64(stats.deletedEvents))
	}
}

func nullString(value string) any {
	if value == "" {
		return nil
	}
	return value
}

func nullInt64(value int64) any {
	if value == 0 {
		return nil
	}
	return value
}
