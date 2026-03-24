import { StargateClient } from "@cosmjs/stargate";
import { TxPollResult } from "./types.js";

export type WaitForTxInput = {
  hash: string;
  timeoutMs?: number;
  pollIntervalMs?: number;
};

const sleep = async (ms: number) => {
  await new Promise((resolve) => setTimeout(resolve, ms));
};

export const waitForTx = async (
  client: StargateClient,
  input: WaitForTxInput
): Promise<TxPollResult> => {
  const timeoutMs = input.timeoutMs ?? 60_000;
  const pollIntervalMs = input.pollIntervalMs ?? 2_000;
  const started = Date.now();

  while (Date.now() - started < timeoutMs) {
    const tx = await client.getTx(input.hash);
    if (tx) {
      return {
        hash: input.hash,
        status: "confirmed",
        height: tx.height
      };
    }
    await sleep(pollIntervalMs);
  }

  return {
    hash: input.hash,
    status: "timeout"
  };
};
