package bank

import "testing"

func TestSend(t *testing.T) {
	keeper := NewKeeper()
	if err := keeper.InitGenesis(GenesisState{
		Params: Params{
			DefaultSendEnabled: true,
		},
		Balances: []Balance{
			{Address: "alice", Amount: 20},
		},
	}); err != nil {
		t.Fatalf("init bank failed: %v", err)
	}
	if err := keeper.Send("alice", "bob", 5); err != nil {
		t.Fatalf("send failed: %v", err)
	}
	if keeper.Balance("alice") != 15 || keeper.Balance("bob") != 5 {
		t.Fatalf("unexpected balances: alice=%d bob=%d", keeper.Balance("alice"), keeper.Balance("bob"))
	}
}
