import { EncodeObject } from "@cosmjs/proto-signing";
import { coin } from "@cosmjs/stargate";
import { SigningStargateClient, StargateClient } from "@cosmjs/stargate";
import { MsgSend } from "cosmjs-types/cosmos/bank/v1beta1/tx.js";
import { broadcastWithRetry } from "../core/broadcast.js";
import { waitForTx } from "../core/tx.js";
import { NetworkConfig, TransferInput } from "../core/types.js";

export type TransferConfirmInput = TransferInput & {
  timeoutMs?: number;
  pollIntervalMs?: number;
};

export const buildNativeTransferMessage = (
  network: NetworkConfig,
  input: TransferInput
): EncodeObject => {
  return {
    typeUrl: "/cosmos.bank.v1beta1.MsgSend",
    value: MsgSend.fromPartial({
      fromAddress: input.fromAddress,
      toAddress: input.toAddress,
      amount: [coin(input.amount, network.denom)]
    })
  };
};

export const sendNativeToken = async (
  client: SigningStargateClient,
  network: NetworkConfig,
  input: TransferInput
) => {
  const message = buildNativeTransferMessage(network, input);
  return broadcastWithRetry(async () => {
    return client.signAndBroadcast(
      input.fromAddress,
      [message],
      "auto",
      input.memo ?? ""
    );
  });
};

export const sendNativeTokenAndConfirm = async (
  signingClient: SigningStargateClient,
  queryClient: StargateClient,
  network: NetworkConfig,
  input: TransferConfirmInput
) => {
  const txResult = await sendNativeToken(signingClient, network, input);
  const receipt = await waitForTx(queryClient, {
    hash: txResult.transactionHash,
    timeoutMs: input.timeoutMs,
    pollIntervalMs: input.pollIntervalMs
  });
  return {
    txResult,
    receipt
  };
};
