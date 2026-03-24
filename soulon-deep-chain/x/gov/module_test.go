package gov

import "testing"

func TestProposalVoteAndTally(t *testing.T) {
	keeper := NewKeeper()
	if err := keeper.InitGenesis(GenesisState{
		Params: Params{
			VotingPeriod: "3600s",
			Quorum:       "0.33",
		},
	}); err != nil {
		t.Fatalf("init gov failed: %v", err)
	}
	proposal, err := keeper.SubmitProposal("alice", "enable feature")
	if err != nil {
		t.Fatalf("submit proposal failed: %v", err)
	}
	if err := keeper.Vote(proposal.ID, VoteYes, 70); err != nil {
		t.Fatalf("vote yes failed: %v", err)
	}
	if err := keeper.Vote(proposal.ID, VoteNo, 10); err != nil {
		t.Fatalf("vote no failed: %v", err)
	}
	tally, err := keeper.Tally(proposal.ID, 100)
	if err != nil {
		t.Fatalf("tally failed: %v", err)
	}
	if !tally.QuorumMet || !tally.Accepted {
		t.Fatalf("unexpected tally: %+v", tally)
	}
}
