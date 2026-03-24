package gov

import (
	"fmt"
	"strconv"
	"time"
)

type Params struct {
	VotingPeriod string `json:"voting_period"`
	Quorum       string `json:"quorum"`
}

type GenesisState struct {
	Params Params `json:"params"`
}

type VoteOption string

const (
	VoteYes     VoteOption = "yes"
	VoteNo      VoteOption = "no"
	VoteAbstain VoteOption = "abstain"
	VoteVeto    VoteOption = "veto"
)

type Proposal struct {
	ID          uint64               `json:"id"`
	Title       string               `json:"title"`
	Proposer    string               `json:"proposer"`
	SubmittedAt time.Time            `json:"submitted_at"`
	Votes       map[VoteOption]int64 `json:"votes"`
}

type TallyResult struct {
	PassRate    float64 `json:"pass_rate"`
	QuorumMet   bool    `json:"quorum_met"`
	Accepted    bool    `json:"accepted"`
	TotalVoted  int64   `json:"total_voted"`
	VotingPower int64   `json:"voting_power"`
}

type Keeper struct {
	params       Params
	votingPeriod time.Duration
	quorum       float64
	proposals    map[uint64]Proposal
	nextID       uint64
}

func NewKeeper() *Keeper {
	return &Keeper{
		proposals: map[uint64]Proposal{},
		nextID:    1,
	}
}

func (k *Keeper) InitGenesis(state GenesisState) error {
	votingPeriod, err := time.ParseDuration(state.Params.VotingPeriod)
	if err != nil {
		return fmt.Errorf("gov invalid voting_period: %w", err)
	}
	quorum, err := strconv.ParseFloat(state.Params.Quorum, 64)
	if err != nil {
		return fmt.Errorf("gov invalid quorum: %w", err)
	}
	if quorum <= 0 || quorum > 1 {
		return fmt.Errorf("gov quorum out of range")
	}
	k.params = state.Params
	k.votingPeriod = votingPeriod
	k.quorum = quorum
	k.proposals = map[uint64]Proposal{}
	k.nextID = 1
	return nil
}

func (k *Keeper) SubmitProposal(proposer string, title string) (Proposal, error) {
	if proposer == "" || title == "" {
		return Proposal{}, fmt.Errorf("gov proposer or title empty")
	}
	proposal := Proposal{
		ID:          k.nextID,
		Title:       title,
		Proposer:    proposer,
		SubmittedAt: time.Now().UTC(),
		Votes: map[VoteOption]int64{
			VoteYes:     0,
			VoteNo:      0,
			VoteAbstain: 0,
			VoteVeto:    0,
		},
	}
	k.nextID++
	k.proposals[proposal.ID] = proposal
	return proposal, nil
}

func (k *Keeper) Vote(proposalID uint64, option VoteOption, weight int64) error {
	if weight <= 0 {
		return fmt.Errorf("gov vote weight must be positive")
	}
	proposal, exists := k.proposals[proposalID]
	if !exists {
		return fmt.Errorf("gov proposal not found")
	}
	if option != VoteYes && option != VoteNo && option != VoteAbstain && option != VoteVeto {
		return fmt.Errorf("gov invalid vote option")
	}
	proposal.Votes[option] += weight
	k.proposals[proposalID] = proposal
	return nil
}

func (k *Keeper) Tally(proposalID uint64, votingPower int64) (TallyResult, error) {
	proposal, exists := k.proposals[proposalID]
	if !exists {
		return TallyResult{}, fmt.Errorf("gov proposal not found")
	}
	if votingPower <= 0 {
		return TallyResult{}, fmt.Errorf("gov voting power must be positive")
	}
	totalVoted := int64(0)
	for _, amount := range proposal.Votes {
		totalVoted += amount
	}
	passRate := float64(0)
	if totalVoted > 0 {
		passRate = float64(proposal.Votes[VoteYes]) / float64(totalVoted)
	}
	quorumMet := float64(totalVoted)/float64(votingPower) >= k.quorum
	return TallyResult{
		PassRate:    passRate,
		QuorumMet:   quorumMet,
		Accepted:    quorumMet && proposal.Votes[VoteYes] > proposal.Votes[VoteNo],
		TotalVoted:  totalVoted,
		VotingPower: votingPower,
	}, nil
}

func (k *Keeper) VotingPeriod() time.Duration {
	return k.votingPeriod
}
