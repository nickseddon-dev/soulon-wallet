package app

import (
	"testing"
	"time"

	"soulon-deep-chain/x/bank"
	"soulon-deep-chain/x/distribution"
	"soulon-deep-chain/x/gov"
	"soulon-deep-chain/x/staking"
)

func TestInitFromGenesisSuccess(t *testing.T) {
	chainApp := NewChainApp()
	genesis := Genesis{
		ChainID:     "soulon-test-1",
		GenesisTime: time.Now().UTC(),
		AppState: AppState{
			Bank: bank.GenesisState{
				Params: bank.Params{
					DefaultSendEnabled: true,
				},
				Balances: []bank.Balance{
					{Address: "alice", Amount: 10},
				},
			},
			Staking: staking.GenesisState{
				Params: staking.Params{
					BondDenom:     "usoul",
					MaxValidators: 100,
					UnbondingTime: "1814400s",
				},
			},
			Distribution: distribution.GenesisState{
				Params: distribution.Params{},
			},
			Gov: gov.GenesisState{
				Params: gov.Params{
					VotingPeriod: "172800s",
					Quorum:       "0.334",
				},
			},
		},
	}
	if err := chainApp.InitFromGenesis(genesis); err != nil {
		t.Fatalf("init from genesis failed: %v", err)
	}
	modules := chainApp.Modules()
	if len(modules) != 4 {
		t.Fatalf("unexpected module size: %d", len(modules))
	}
}

func TestInitFromGenesisInvalid(t *testing.T) {
	chainApp := NewChainApp()
	genesis := Genesis{
		ChainID: "soulon-test-1",
	}
	if err := chainApp.InitFromGenesis(genesis); err == nil {
		t.Fatal("expected init failure")
	}
}
