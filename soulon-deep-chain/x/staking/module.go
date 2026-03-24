package staking

import (
	"fmt"
	"sort"
	"time"
)

type Params struct {
	BondDenom     string `json:"bond_denom"`
	MaxValidators int    `json:"max_validators"`
	UnbondingTime string `json:"unbonding_time"`
}

type GenesisState struct {
	Params Params `json:"params"`
}

type Keeper struct {
	params      Params
	unbonding   time.Duration
	validators  map[string]struct{}
	delegations map[string]map[string]int64
}

func NewKeeper() *Keeper {
	return &Keeper{
		validators:  map[string]struct{}{},
		delegations: map[string]map[string]int64{},
	}
}

func (k *Keeper) InitGenesis(state GenesisState) error {
	if state.Params.BondDenom == "" {
		return fmt.Errorf("staking bond_denom is empty")
	}
	if state.Params.MaxValidators <= 0 {
		return fmt.Errorf("staking max_validators must be positive")
	}
	unbonding, err := time.ParseDuration(state.Params.UnbondingTime)
	if err != nil {
		return fmt.Errorf("staking invalid unbonding_time: %w", err)
	}
	k.params = state.Params
	k.unbonding = unbonding
	k.validators = map[string]struct{}{}
	k.delegations = map[string]map[string]int64{}
	return nil
}

func (k *Keeper) Delegate(delegator string, validator string, amount int64) error {
	if delegator == "" || validator == "" {
		return fmt.Errorf("staking delegator or validator empty")
	}
	if amount <= 0 {
		return fmt.Errorf("staking amount must be positive")
	}
	if len(k.validators) < k.params.MaxValidators {
		k.validators[validator] = struct{}{}
	}
	if _, exists := k.validators[validator]; !exists {
		return fmt.Errorf("staking validator capacity reached")
	}
	validatorDelegations, exists := k.delegations[delegator]
	if !exists {
		validatorDelegations = map[string]int64{}
		k.delegations[delegator] = validatorDelegations
	}
	validatorDelegations[validator] += amount
	return nil
}

func (k *Keeper) Redelegate(delegator string, fromValidator string, toValidator string, amount int64) error {
	if amount <= 0 {
		return fmt.Errorf("staking amount must be positive")
	}
	if fromValidator == "" || toValidator == "" {
		return fmt.Errorf("staking validator is empty")
	}
	validatorDelegations, exists := k.delegations[delegator]
	if !exists || validatorDelegations[fromValidator] < amount {
		return fmt.Errorf("staking insufficient delegation")
	}
	validatorDelegations[fromValidator] -= amount
	return k.Delegate(delegator, toValidator, amount)
}

func (k *Keeper) TotalDelegation(delegator string) int64 {
	validatorDelegations, exists := k.delegations[delegator]
	if !exists {
		return 0
	}
	total := int64(0)
	for _, amount := range validatorDelegations {
		total += amount
	}
	return total
}

func (k *Keeper) Validators() []string {
	validators := make([]string, 0, len(k.validators))
	for validator := range k.validators {
		validators = append(validators, validator)
	}
	sort.Strings(validators)
	return validators
}
