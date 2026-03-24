import { SigningStargateClient } from "@cosmjs/stargate";
import { VoteOption } from "cosmjs-types/cosmos/gov/v1beta1/gov.js";
import { MsgVote } from "cosmjs-types/cosmos/gov/v1beta1/tx.js";
import { broadcastWithRetry } from "../core/broadcast.js";
import { SoulonWalletError } from "../core/errors.js";
import { isAddressForPrefix } from "../core/wallet.js";
import { NetworkConfig, VoteInput, VoteOptionType } from "../core/types.js";

const voteOptionMap: Record<VoteOptionType, VoteOption> = {
  yes: VoteOption.VOTE_OPTION_YES,
  no: VoteOption.VOTE_OPTION_NO,
  abstain: VoteOption.VOTE_OPTION_ABSTAIN,
  no_with_veto: VoteOption.VOTE_OPTION_NO_WITH_VETO
};

export const GOVERNANCE_ERROR_CODES = {
  INVALID_VOTER_ADDRESS: "INVALID_VOTER_ADDRESS",
  INVALID_PROPOSAL_ID: "INVALID_PROPOSAL_ID",
  INVALID_PROPOSAL_STATUS: "INVALID_PROPOSAL_STATUS"
} as const;

const normalizeRequired = (value: string, code: string, fieldLabel: string): string => {
  const normalized = value.trim();
  if (!normalized) {
    throw new SoulonWalletError(code, `${fieldLabel} is required`);
  }
  return normalized;
};

const validateVoterAddress = (network: NetworkConfig, voterAddress: string): string => {
  const normalized = normalizeRequired(
    voterAddress,
    GOVERNANCE_ERROR_CODES.INVALID_VOTER_ADDRESS,
    "Voter address"
  );
  if (!isAddressForPrefix(normalized, network.bech32Prefix)) {
    throw new SoulonWalletError(
      GOVERNANCE_ERROR_CODES.INVALID_VOTER_ADDRESS,
      "Voter address format is invalid"
    );
  }
  return normalized;
};

const validateProposalId = (proposalId: bigint): bigint => {
  if (proposalId <= 0n) {
    throw new SoulonWalletError(
      GOVERNANCE_ERROR_CODES.INVALID_PROPOSAL_ID,
      "Proposal id must be greater than 0"
    );
  }
  return proposalId;
};

export const voteProposal = async (
  client: SigningStargateClient,
  network: NetworkConfig,
  input: VoteInput
) => {
  const voterAddress = validateVoterAddress(network, input.voterAddress);
  const proposalId = validateProposalId(input.proposalId);
  return broadcastWithRetry(async () => {
    return client.signAndBroadcast(
      voterAddress,
      [
        {
          typeUrl: "/cosmos.gov.v1beta1.MsgVote",
          value: MsgVote.fromPartial({
            proposalId,
            voter: voterAddress,
            option: voteOptionMap[input.option]
          })
        }
      ],
      "auto",
      input.memo ?? ""
    );
  });
};

export const queryProposals = async (network: NetworkConfig, proposalStatus?: string) => {
  const normalizedStatus = proposalStatus?.trim();
  if (proposalStatus !== undefined && !normalizedStatus) {
    throw new SoulonWalletError(
      GOVERNANCE_ERROR_CODES.INVALID_PROPOSAL_STATUS,
      "Proposal status must be a non-empty string"
    );
  }
  const statusQuery = normalizedStatus
    ? `?proposal_status=${encodeURIComponent(normalizedStatus)}`
    : "";
  const response = await fetch(`${network.restEndpoint}/cosmos/gov/v1beta1/proposals${statusQuery}`);
  return response.json();
};

export const queryProposalDetail = async (network: NetworkConfig, proposalId: bigint) => {
  const normalizedProposalId = validateProposalId(proposalId);
  const response = await fetch(
    `${network.restEndpoint}/cosmos/gov/v1beta1/proposals/${normalizedProposalId}`
  );
  return response.json();
};

export const queryProposalVotes = async (network: NetworkConfig, proposalId: bigint) => {
  const normalizedProposalId = validateProposalId(proposalId);
  const response = await fetch(
    `${network.restEndpoint}/cosmos/gov/v1beta1/proposals/${normalizedProposalId}/votes`
  );
  return response.json();
};
