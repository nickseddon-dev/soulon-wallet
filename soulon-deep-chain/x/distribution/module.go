package distribution

import "fmt"

type Params struct{}

type GenesisState struct {
	Params Params `json:"params"`
}

type Keeper struct {
	rewards map[string]int64
}

func NewKeeper() *Keeper {
	return &Keeper{
		rewards: map[string]int64{},
	}
}

func (k *Keeper) InitGenesis(_ GenesisState) error {
	k.rewards = map[string]int64{}
	return nil
}

func (k *Keeper) AddReward(delegator string, amount int64) error {
	if delegator == "" {
		return fmt.Errorf("distribution delegator is empty")
	}
	if amount <= 0 {
		return fmt.Errorf("distribution amount must be positive")
	}
	k.rewards[delegator] += amount
	return nil
}

func (k *Keeper) QueryReward(delegator string) int64 {
	return k.rewards[delegator]
}

func (k *Keeper) ClaimReward(delegator string) int64 {
	value := k.rewards[delegator]
	delete(k.rewards, delegator)
	return value
}
