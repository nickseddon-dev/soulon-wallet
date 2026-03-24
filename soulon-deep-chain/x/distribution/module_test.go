package distribution

import "testing"

func TestClaimReward(t *testing.T) {
	keeper := NewKeeper()
	if err := keeper.InitGenesis(GenesisState{Params: Params{}}); err != nil {
		t.Fatalf("init distribution failed: %v", err)
	}
	if err := keeper.AddReward("alice", 12); err != nil {
		t.Fatalf("add reward failed: %v", err)
	}
	if keeper.QueryReward("alice") != 12 {
		t.Fatalf("unexpected reward: %d", keeper.QueryReward("alice"))
	}
	if keeper.ClaimReward("alice") != 12 {
		t.Fatal("unexpected claim reward")
	}
	if keeper.QueryReward("alice") != 0 {
		t.Fatal("reward should be cleared after claim")
	}
}
