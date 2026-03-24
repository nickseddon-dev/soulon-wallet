package indexer

import "time"

type Event struct {
	ID           string    `json:"id"`
	Height       int64     `json:"height"`
	Type         string    `json:"type"`
	BlockHash    string    `json:"blockHash,omitempty"`
	ParentHash   string    `json:"parentHash,omitempty"`
	RollbackFrom int64     `json:"rollbackFrom,omitempty"`
	Payload      string    `json:"payload"`
	ProducedAt   time.Time `json:"producedAt"`
	PersistedAt  time.Time `json:"persistedAt,omitempty"`
	Partition    int       `json:"-"`
	Offset       int64     `json:"-"`
}
