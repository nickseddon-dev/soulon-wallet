package app

import (
	"fmt"
	"strings"

	"soulon-deep-chain/x/gov"
)

const (
	TxBankSend          = "bank_send"
	TxStakingDelegate   = "staking_delegate"
	TxStakingRedelegate = "staking_redelegate"
	TxGovSubmit         = "gov_submit"
	TxGovVote           = "gov_vote"
	TxGovTally          = "gov_tally"
	TxRewardsAdd        = "rewards_add"
	TxRewardsClaim      = "rewards_claim"
)

type Tx struct {
	Type          string
	From          string
	To            string
	Amount        int64
	Delegator     string
	Validator     string
	FromValidator string
	ToValidator   string
	Title         string
	ProposalID    uint64
	Option        gov.VoteOption
	VotingPower   int64
}

type TxResult struct {
	Message       string
	ProposalID    uint64
	Accepted      bool
	QuorumMet     bool
	ClaimedReward int64
}

func (a *ChainApp) ExecuteTx(tx Tx) (TxResult, error) {
	if err := validateTx(tx); err != nil {
		return TxResult{}, err
	}
	switch tx.Type {
	case TxBankSend:
		if err := a.BankKeeper.Send(tx.From, tx.To, tx.Amount); err != nil {
			return TxResult{}, wrapExecutionError(err.Error())
		}
		return TxResult{Message: "bank send ok"}, nil
	case TxStakingDelegate:
		if err := a.StakingKeeper.Delegate(tx.Delegator, tx.Validator, tx.Amount); err != nil {
			return TxResult{}, wrapExecutionError(err.Error())
		}
		return TxResult{Message: "staking delegate ok"}, nil
	case TxStakingRedelegate:
		if err := a.StakingKeeper.Redelegate(tx.Delegator, tx.FromValidator, tx.ToValidator, tx.Amount); err != nil {
			return TxResult{}, wrapExecutionError(err.Error())
		}
		return TxResult{Message: "staking redelegate ok"}, nil
	case TxGovSubmit:
		proposal, err := a.GovKeeper.SubmitProposal(tx.From, tx.Title)
		if err != nil {
			return TxResult{}, wrapExecutionError(err.Error())
		}
		return TxResult{
			Message:    "gov submit ok",
			ProposalID: proposal.ID,
		}, nil
	case TxGovVote:
		if err := a.GovKeeper.Vote(tx.ProposalID, tx.Option, tx.Amount); err != nil {
			return TxResult{}, wrapExecutionError(err.Error())
		}
		return TxResult{Message: "gov vote ok"}, nil
	case TxGovTally:
		tally, err := a.GovKeeper.Tally(tx.ProposalID, tx.VotingPower)
		if err != nil {
			return TxResult{}, wrapExecutionError(err.Error())
		}
		return TxResult{
			Message:   "gov tally ok",
			Accepted:  tally.Accepted,
			QuorumMet: tally.QuorumMet,
		}, nil
	case TxRewardsAdd:
		if err := a.DistributionKeeper.AddReward(tx.Delegator, tx.Amount); err != nil {
			return TxResult{}, wrapExecutionError(err.Error())
		}
		return TxResult{Message: "reward add ok"}, nil
	case TxRewardsClaim:
		claimed := a.DistributionKeeper.ClaimReward(tx.Delegator)
		return TxResult{
			Message:       "reward claim ok",
			ClaimedReward: claimed,
		}, nil
	default:
		return TxResult{}, newInvalidTxError(fmt.Sprintf("unknown tx type: %s", tx.Type))
	}
}

func validateTx(tx Tx) error {
	if strings.TrimSpace(tx.Type) == "" {
		return newInvalidFieldError("tx type is required")
	}
	switch tx.Type {
	case TxBankSend:
		if strings.TrimSpace(tx.From) == "" || strings.TrimSpace(tx.To) == "" {
			return newInvalidFieldError("bank send requires from and to")
		}
		if tx.Amount <= 0 {
			return newInvalidFieldError("bank send amount must be positive")
		}
	case TxStakingDelegate:
		if strings.TrimSpace(tx.Delegator) == "" || strings.TrimSpace(tx.Validator) == "" {
			return newInvalidFieldError("staking delegate requires delegator and validator")
		}
		if tx.Amount <= 0 {
			return newInvalidFieldError("staking delegate amount must be positive")
		}
	case TxStakingRedelegate:
		if strings.TrimSpace(tx.Delegator) == "" {
			return newInvalidFieldError("staking redelegate requires delegator")
		}
		if strings.TrimSpace(tx.FromValidator) == "" || strings.TrimSpace(tx.ToValidator) == "" {
			return newInvalidFieldError("staking redelegate requires from_validator and to_validator")
		}
		if tx.Amount <= 0 {
			return newInvalidFieldError("staking redelegate amount must be positive")
		}
	case TxGovSubmit:
		if strings.TrimSpace(tx.From) == "" || strings.TrimSpace(tx.Title) == "" {
			return newInvalidFieldError("gov submit requires proposer and title")
		}
	case TxGovVote:
		if tx.ProposalID == 0 {
			return newInvalidFieldError("gov vote requires proposal_id")
		}
		if tx.Amount <= 0 {
			return newInvalidFieldError("gov vote amount must be positive")
		}
		if tx.Option != gov.VoteYes && tx.Option != gov.VoteNo && tx.Option != gov.VoteAbstain && tx.Option != gov.VoteVeto {
			return newInvalidFieldError("gov vote option is invalid")
		}
	case TxGovTally:
		if tx.ProposalID == 0 {
			return newInvalidFieldError("gov tally requires proposal_id")
		}
		if tx.VotingPower <= 0 {
			return newInvalidFieldError("gov tally voting_power must be positive")
		}
	case TxRewardsAdd:
		if strings.TrimSpace(tx.Delegator) == "" {
			return newInvalidFieldError("reward add requires delegator")
		}
		if tx.Amount <= 0 {
			return newInvalidFieldError("reward add amount must be positive")
		}
	case TxRewardsClaim:
		if strings.TrimSpace(tx.Delegator) == "" {
			return newInvalidFieldError("reward claim requires delegator")
		}
	default:
		return newInvalidTxError(fmt.Sprintf("unknown tx type: %s", tx.Type))
	}
	return nil
}
