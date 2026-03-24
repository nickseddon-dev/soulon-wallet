import { SigningStargateClient } from "@cosmjs/stargate";
import { MsgBeginRedelegate, MsgDelegate, MsgUndelegate } from "cosmjs-types/cosmos/staking/v1beta1/tx.js";
import { MsgWithdrawDelegatorReward } from "cosmjs-types/cosmos/distribution/v1beta1/tx.js";
import { coin } from "@cosmjs/stargate";
import { broadcastWithRetry } from "../core/broadcast.js";
import { SoulonWalletError } from "../core/errors.js";
import { isAddressForPrefix } from "../core/wallet.js";
import {
  DelegateInput,
  NetworkConfig,
  RedelegateInput,
  UndelegateInput,
  WithdrawRewardsInput
} from "../core/types.js";

export const STAKING_ERROR_CODES = {
  INVALID_DELEGATOR_ADDRESS: "INVALID_DELEGATOR_ADDRESS",
  INVALID_VALIDATOR_ADDRESS: "INVALID_VALIDATOR_ADDRESS",
  INVALID_SOURCE_VALIDATOR_ADDRESS: "INVALID_SOURCE_VALIDATOR_ADDRESS",
  INVALID_DESTINATION_VALIDATOR_ADDRESS: "INVALID_DESTINATION_VALIDATOR_ADDRESS",
  INVALID_AMOUNT: "INVALID_AMOUNT"
} as const;

const normalizeRequired = (value: string, code: string, fieldLabel: string): string => {
  const normalized = value.trim();
  if (!normalized) {
    throw new SoulonWalletError(code, `${fieldLabel} is required`);
  }
  return normalized;
};

const buildValidatorAddressPattern = (bech32Prefix: string): RegExp => {
  const escapedPrefix = bech32Prefix.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  return new RegExp(`^${escapedPrefix}valoper1[02-9ac-hj-np-z]{10,}$`);
};

const validateDelegatorAddress = (network: NetworkConfig, address: string): string => {
  const normalized = normalizeRequired(
    address,
    STAKING_ERROR_CODES.INVALID_DELEGATOR_ADDRESS,
    "Delegator address"
  );
  if (!isAddressForPrefix(normalized, network.bech32Prefix)) {
    throw new SoulonWalletError(
      STAKING_ERROR_CODES.INVALID_DELEGATOR_ADDRESS,
      "Delegator address format is invalid"
    );
  }
  return normalized;
};

const validateValidatorAddress = (network: NetworkConfig, address: string, code: string): string => {
  const normalized = normalizeRequired(address, code, "Validator address");
  if (!buildValidatorAddressPattern(network.bech32Prefix).test(normalized)) {
    throw new SoulonWalletError(code, "Validator address format is invalid");
  }
  return normalized;
};

const validateAmount = (amount: string): string => {
  const normalized = normalizeRequired(amount, STAKING_ERROR_CODES.INVALID_AMOUNT, "Amount");
  if (!/^[0-9]+$/.test(normalized) || BigInt(normalized) <= 0n) {
    throw new SoulonWalletError(
      STAKING_ERROR_CODES.INVALID_AMOUNT,
      "Amount must be a positive integer string"
    );
  }
  return normalized;
};

export const delegateToValidator = async (
  client: SigningStargateClient,
  network: NetworkConfig,
  input: DelegateInput
) => {
  const delegatorAddress = validateDelegatorAddress(network, input.delegatorAddress);
  const validatorAddress = validateValidatorAddress(
    network,
    input.validatorAddress,
    STAKING_ERROR_CODES.INVALID_VALIDATOR_ADDRESS
  );
  const amount = validateAmount(input.amount);
  return broadcastWithRetry(async () => {
    return client.signAndBroadcast(
      delegatorAddress,
      [
        {
          typeUrl: "/cosmos.staking.v1beta1.MsgDelegate",
          value: MsgDelegate.fromPartial({
            delegatorAddress,
            validatorAddress,
            amount: coin(amount, network.denom)
          })
        }
      ],
      "auto",
      input.memo ?? ""
    );
  });
};

export const undelegateFromValidator = async (
  client: SigningStargateClient,
  network: NetworkConfig,
  input: UndelegateInput
) => {
  const delegatorAddress = validateDelegatorAddress(network, input.delegatorAddress);
  const validatorAddress = validateValidatorAddress(
    network,
    input.validatorAddress,
    STAKING_ERROR_CODES.INVALID_VALIDATOR_ADDRESS
  );
  const amount = validateAmount(input.amount);
  return broadcastWithRetry(async () => {
    return client.signAndBroadcast(
      delegatorAddress,
      [
        {
          typeUrl: "/cosmos.staking.v1beta1.MsgUndelegate",
          value: MsgUndelegate.fromPartial({
            delegatorAddress,
            validatorAddress,
            amount: coin(amount, network.denom)
          })
        }
      ],
      "auto",
      input.memo ?? ""
    );
  });
};

export const withdrawValidatorRewards = async (
  client: SigningStargateClient,
  network: NetworkConfig,
  input: WithdrawRewardsInput
) => {
  const delegatorAddress = validateDelegatorAddress(network, input.delegatorAddress);
  const validatorAddress = validateValidatorAddress(
    network,
    input.validatorAddress,
    STAKING_ERROR_CODES.INVALID_VALIDATOR_ADDRESS
  );
  return broadcastWithRetry(async () => {
    return client.signAndBroadcast(
      delegatorAddress,
      [
        {
          typeUrl: "/cosmos.distribution.v1beta1.MsgWithdrawDelegatorReward",
          value: MsgWithdrawDelegatorReward.fromPartial({
            delegatorAddress,
            validatorAddress
          })
        }
      ],
      "auto",
      input.memo ?? ""
    );
  });
};

export const queryValidators = async (network: NetworkConfig) => {
  const response = await fetch(
    `${network.restEndpoint}/cosmos/staking/v1beta1/validators?status=BOND_STATUS_BONDED`
  );
  return response.json();
};

export const queryDelegations = async (network: NetworkConfig, delegatorAddress: string) => {
  const normalizedDelegatorAddress = validateDelegatorAddress(network, delegatorAddress);
  const response = await fetch(
    `${network.restEndpoint}/cosmos/staking/v1beta1/delegations/${normalizedDelegatorAddress}`
  );
  return response.json();
};

export const redelegateToValidator = async (
  client: SigningStargateClient,
  network: NetworkConfig,
  input: RedelegateInput
) => {
  const delegatorAddress = validateDelegatorAddress(network, input.delegatorAddress);
  const validatorSrcAddress = validateValidatorAddress(
    network,
    input.validatorSrcAddress,
    STAKING_ERROR_CODES.INVALID_SOURCE_VALIDATOR_ADDRESS
  );
  const validatorDstAddress = validateValidatorAddress(
    network,
    input.validatorDstAddress,
    STAKING_ERROR_CODES.INVALID_DESTINATION_VALIDATOR_ADDRESS
  );
  const amount = validateAmount(input.amount);
  return broadcastWithRetry(async () => {
    return client.signAndBroadcast(
      delegatorAddress,
      [
        {
          typeUrl: "/cosmos.staking.v1beta1.MsgBeginRedelegate",
          value: MsgBeginRedelegate.fromPartial({
            delegatorAddress,
            validatorSrcAddress,
            validatorDstAddress,
            amount: coin(amount, network.denom)
          })
        }
      ],
      "auto",
      input.memo ?? ""
    );
  });
};

export const queryRewards = async (network: NetworkConfig, delegatorAddress: string) => {
  const normalizedDelegatorAddress = validateDelegatorAddress(network, delegatorAddress);
  const response = await fetch(
    `${network.restEndpoint}/cosmos/distribution/v1beta1/delegators/${normalizedDelegatorAddress}/rewards`
  );
  return response.json();
};
