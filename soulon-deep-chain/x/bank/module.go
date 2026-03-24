package bank

import (
	"fmt"
	"sort"
)

type Params struct {
	DefaultSendEnabled bool `json:"default_send_enabled"`
}

type Balance struct {
	Address string `json:"address"`
	Amount  int64  `json:"amount"`
}

type GenesisState struct {
	Params   Params    `json:"params"`
	Balances []Balance `json:"balances"`
}

type Keeper struct {
	params   Params
	balances map[string]int64
}

func NewKeeper() *Keeper {
	return &Keeper{
		balances: map[string]int64{},
	}
}

func (k *Keeper) InitGenesis(state GenesisState) error {
	k.params = state.Params
	k.balances = map[string]int64{}
	for _, balance := range state.Balances {
		if balance.Address == "" {
			return fmt.Errorf("bank balance address is empty")
		}
		if balance.Amount < 0 {
			return fmt.Errorf("bank balance amount is negative: %s", balance.Address)
		}
		k.balances[balance.Address] += balance.Amount
	}
	return nil
}

func (k *Keeper) Send(from string, to string, amount int64) error {
	if !k.params.DefaultSendEnabled {
		return fmt.Errorf("bank send disabled")
	}
	if amount <= 0 {
		return fmt.Errorf("bank amount must be positive")
	}
	if from == "" || to == "" {
		return fmt.Errorf("bank sender or receiver empty")
	}
	if from == to {
		return nil
	}
	if k.balances[from] < amount {
		return fmt.Errorf("bank insufficient balance")
	}
	k.balances[from] -= amount
	k.balances[to] += amount
	return nil
}

func (k *Keeper) Balance(address string) int64 {
	return k.balances[address]
}

func (k *Keeper) ExportBalances() []Balance {
	addresses := make([]string, 0, len(k.balances))
	for address := range k.balances {
		addresses = append(addresses, address)
	}
	sort.Strings(addresses)
	out := make([]Balance, 0, len(addresses))
	for _, address := range addresses {
		out = append(out, Balance{
			Address: address,
			Amount:  k.balances[address],
		})
	}
	return out
}
