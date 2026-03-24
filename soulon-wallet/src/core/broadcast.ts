import { DeliverTxResponse } from "@cosmjs/stargate";
import { SoulonWalletError, mapBroadcastError, mapTxError } from "./errors.js";

export type BroadcastRetryOptions = {
  maxAttempts?: number;
  baseDelayMs?: number;
  retriableCodes?: number[];
  retriableErrorCodes?: string[];
};

const sleep = async (ms: number) => {
  await new Promise((resolve) => setTimeout(resolve, ms));
};

const defaultRetriableCodes = [11, 32];
const defaultRetriableErrorCodes = ["NODE_UNAVAILABLE", "INVALID_SEQUENCE"];

export const broadcastWithRetry = async (
  execute: () => Promise<DeliverTxResponse>,
  options?: BroadcastRetryOptions
): Promise<DeliverTxResponse> => {
  const maxAttempts = options?.maxAttempts ?? 3;
  const baseDelayMs = options?.baseDelayMs ?? 1200;
  const retriableCodes = options?.retriableCodes ?? defaultRetriableCodes;
  const retriableErrorCodes = options?.retriableErrorCodes ?? defaultRetriableErrorCodes;

  let lastError: SoulonWalletError | null = null;
  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    let result: DeliverTxResponse;
    try {
      result = await execute();
    } catch (error) {
      const mapped = mapBroadcastError(error);
      lastError = mapped;
      const shouldRetry =
        retriableErrorCodes.includes(mapped.code) && attempt < maxAttempts;
      if (!shouldRetry) {
        throw mapped;
      }
      const delayMs = baseDelayMs * attempt;
      await sleep(delayMs);
      continue;
    }
    if (result.code === 0) {
      return result;
    }
    const mapped = mapTxError(result.code, result.rawLog);
    lastError = mapped;
    const shouldRetry = retriableCodes.includes(result.code) && attempt < maxAttempts;
    if (!shouldRetry) {
      throw mapped;
    }
    const delayMs = baseDelayMs * attempt;
    await sleep(delayMs);
  }
  throw lastError ?? new SoulonWalletError("TX_REJECTED", "transaction rejected");
};
