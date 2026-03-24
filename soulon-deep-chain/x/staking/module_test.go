package staking

import "testing"

func TestDelegateAndRedelegate(t *testing.T) {
	keeper := NewKeeper()
	if err := keeper.InitGenesis(GenesisState{
		Params: Params{
			BondDenom:     "usoul",
			MaxValidators: 10,
			UnbondingTime: "3600s",
		},
	}); err != nil {
		t.Fatalf("init staking failed: %v", err)
	}
	if err := keeper.Delegate("alice", "v1", 10); err != nil {
		t.Fatalf("delegate failed: %v", err)
	}
	if err := keeper.Redelegate("alice", "v1", "v2", 4); err != nil {
		t.Fatalf("redelegate failed: %v", err)
	}
	if keeper.TotalDelegation("alice") != 10 {
		t.Fatalf("unexpected total delegation: %d", keeper.TotalDelegation("alice"))
	}
}
