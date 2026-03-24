package app

import (
	"encoding/json"
	"fmt"
	"os"
	"time"

	"soulon-deep-chain/x/bank"
	"soulon-deep-chain/x/distribution"
	"soulon-deep-chain/x/gov"
	"soulon-deep-chain/x/staking"
)

type Genesis struct {
	ChainID     string    `json:"chain_id"`
	GenesisTime time.Time `json:"genesis_time"`
	AppState    AppState  `json:"app_state"`
}

type AppState struct {
	Bank         bank.GenesisState         `json:"bank"`
	Staking      staking.GenesisState      `json:"staking"`
	Distribution distribution.GenesisState `json:"distribution"`
	Gov          gov.GenesisState          `json:"gov"`
}

type ChainApp struct {
	BankKeeper         *bank.Keeper
	StakingKeeper      *staking.Keeper
	DistributionKeeper *distribution.Keeper
	GovKeeper          *gov.Keeper
	moduleManager      *ModuleManager
}

func NewChainApp() *ChainApp {
	chainApp := &ChainApp{
		BankKeeper:         bank.NewKeeper(),
		StakingKeeper:      staking.NewKeeper(),
		DistributionKeeper: distribution.NewKeeper(),
		GovKeeper:          gov.NewKeeper(),
	}
	moduleManager := NewModuleManager()
	moduleManager.Register("bank", func(genesis Genesis) error {
		return chainApp.BankKeeper.InitGenesis(genesis.AppState.Bank)
	})
	moduleManager.Register("staking", func(genesis Genesis) error {
		return chainApp.StakingKeeper.InitGenesis(genesis.AppState.Staking)
	})
	moduleManager.Register("distribution", func(genesis Genesis) error {
		return chainApp.DistributionKeeper.InitGenesis(genesis.AppState.Distribution)
	})
	moduleManager.Register("gov", func(genesis Genesis) error {
		return chainApp.GovKeeper.InitGenesis(genesis.AppState.Gov)
	})
	chainApp.moduleManager = moduleManager
	return chainApp
}

func LoadGenesisFromFile(path string) (Genesis, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		return Genesis{}, err
	}
	var genesis Genesis
	if err := json.Unmarshal(content, &genesis); err != nil {
		return Genesis{}, err
	}
	return genesis, nil
}

func (a *ChainApp) InitFromGenesis(genesis Genesis) error {
	if genesis.ChainID == "" {
		return fmt.Errorf("chain_id is empty")
	}
	if genesis.GenesisTime.IsZero() {
		return fmt.Errorf("genesis_time is empty")
	}
	if err := a.moduleManager.InitGenesis(genesis); err != nil {
		return err
	}
	return nil
}

func (a *ChainApp) ValidateGenesis(path string) error {
	genesis, err := LoadGenesisFromFile(path)
	if err != nil {
		return err
	}
	return a.InitFromGenesis(genesis)
}

func (a *ChainApp) Modules() []string {
	return a.moduleManager.Names()
}
