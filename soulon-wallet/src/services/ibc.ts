import { SigningStargateClient, coin } from "@cosmjs/stargate";
import { MsgTransfer } from "cosmjs-types/ibc/applications/transfer/v1/tx.js";
import { broadcastWithRetry } from "../core/broadcast.js";
import { IBCTransferInput, NetworkConfig } from "../core/types.js";

export const transferIBC = async (
  client: SigningStargateClient,
  network: NetworkConfig,
  input: IBCTransferInput
) => {
  const timeoutSeconds = input.timeoutSeconds ?? 300;
  const timeoutTimestampNs = (BigInt(Date.now()) + BigInt(timeoutSeconds * 1000)) * 1000000n;
  return broadcastWithRetry(async () => {
    return client.signAndBroadcast(
      input.senderAddress,
      [
        {
          typeUrl: "/ibc.applications.transfer.v1.MsgTransfer",
          value: MsgTransfer.fromPartial({
            sourcePort: input.sourcePort,
            sourceChannel: input.sourceChannel,
            token: coin(input.amount, network.denom),
            sender: input.senderAddress,
            receiver: input.receiverAddress,
            timeoutTimestamp: timeoutTimestampNs
          })
        }
      ],
      "auto",
      input.memo ?? ""
    );
  });
};

export const queryIBCChannels = async (network: NetworkConfig) => {
  const response = await fetch(`${network.restEndpoint}/ibc/core/channel/v1/channels`);
  return response.json();
};
