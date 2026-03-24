export class SoulonWalletError extends Error {
  readonly code: string;

  constructor(code: string, message: string) {
    super(message);
    this.code = code;
    this.name = "SoulonWalletError";
  }
}

export const WALLET_SEMANTIC_ERROR_CODES = {
  INVALID_ARGUMENT: "INVALID_ARGUMENT",
  INSUFFICIENT_FUNDS: "INSUFFICIENT_FUNDS",
  OUT_OF_GAS: "OUT_OF_GAS",
  INVALID_SEQUENCE: "INVALID_SEQUENCE",
  UNAUTHORIZED: "UNAUTHORIZED",
  NODE_UNAVAILABLE: "NODE_UNAVAILABLE",
  TX_REJECTED: "TX_REJECTED"
} as const;

export type WalletSemanticErrorCode =
  (typeof WALLET_SEMANTIC_ERROR_CODES)[keyof typeof WALLET_SEMANTIC_ERROR_CODES];

const includesOneOf = (value: string, keywords: string[]): boolean => {
  return keywords.some((keyword) => value.includes(keyword));
};

const normalizeMessage = (message?: string): string => {
  return String(message ?? "").toLowerCase();
};

export const mapTxError = (code: number, rawLog?: string): SoulonWalletError | null => {
  if (code === 0) {
    return null;
  }
  const normalizedRawLog = normalizeMessage(rawLog);
  if (
    includesOneOf(normalizedRawLog, [
      "insufficient funds",
      "spendable balance",
      "不足",
      "余额不足"
    ])
  ) {
    return new SoulonWalletError(
      WALLET_SEMANTIC_ERROR_CODES.INSUFFICIENT_FUNDS,
      rawLog || "insufficient funds"
    );
  }
  if (
    includesOneOf(normalizedRawLog, [
      "out of gas",
      "gas wanted",
      "gas不足",
      "燃料不足"
    ])
  ) {
    return new SoulonWalletError(WALLET_SEMANTIC_ERROR_CODES.OUT_OF_GAS, rawLog || "out of gas");
  }
  if (
    includesOneOf(normalizedRawLog, [
      "invalid account sequence",
      "account sequence mismatch",
      "incorrect account sequence",
      "nonce",
      "sequence"
    ])
  ) {
    return new SoulonWalletError(
      WALLET_SEMANTIC_ERROR_CODES.INVALID_SEQUENCE,
      rawLog || "invalid account sequence"
    );
  }
  if (
    includesOneOf(normalizedRawLog, [
      "invalid",
      "malformed",
      "illegal",
      "参数非法",
      "invalid argument",
      "invalid request"
    ])
  ) {
    return new SoulonWalletError(
      WALLET_SEMANTIC_ERROR_CODES.INVALID_ARGUMENT,
      rawLog || "invalid request"
    );
  }
  if (includesOneOf(normalizedRawLog, ["unauthorized", "权限", "未授权"])) {
    return new SoulonWalletError(WALLET_SEMANTIC_ERROR_CODES.UNAUTHORIZED, rawLog || "unauthorized");
  }
  if (code === 4) {
    return new SoulonWalletError(
      WALLET_SEMANTIC_ERROR_CODES.INSUFFICIENT_FUNDS,
      rawLog || "insufficient funds"
    );
  }
  if (code === 11) {
    return new SoulonWalletError(WALLET_SEMANTIC_ERROR_CODES.OUT_OF_GAS, rawLog || "out of gas");
  }
  if (code === 32) {
    return new SoulonWalletError(
      WALLET_SEMANTIC_ERROR_CODES.INVALID_SEQUENCE,
      rawLog || "invalid account sequence"
    );
  }
  if (code === 2 || code === 3) {
    return new SoulonWalletError(
      WALLET_SEMANTIC_ERROR_CODES.INVALID_ARGUMENT,
      rawLog || "invalid request"
    );
  }
  if (code === 13) {
    return new SoulonWalletError(WALLET_SEMANTIC_ERROR_CODES.UNAUTHORIZED, rawLog || "unauthorized");
  }
  return new SoulonWalletError(WALLET_SEMANTIC_ERROR_CODES.TX_REJECTED, rawLog || "transaction rejected");
};

export const mapBroadcastError = (error: unknown): SoulonWalletError => {
  if (error instanceof SoulonWalletError) {
    return error;
  }
  const message = error instanceof Error ? error.message : String(error);
  const normalized = normalizeMessage(message);
  if (
    includesOneOf(normalized, [
      "econnrefused",
      "fetch failed",
      "network error",
      "deadline exceeded",
      "timeout",
      "timed out",
      "unavailable",
      "connection refused",
      "socket hang up",
      "econnreset"
    ])
  ) {
    return new SoulonWalletError(WALLET_SEMANTIC_ERROR_CODES.NODE_UNAVAILABLE, message || "node unavailable");
  }
  if (
    includesOneOf(normalized, [
      "invalid account sequence",
      "account sequence mismatch",
      "incorrect account sequence",
      "nonce",
      "sequence"
    ])
  ) {
    return new SoulonWalletError(
      WALLET_SEMANTIC_ERROR_CODES.INVALID_SEQUENCE,
      message || "invalid account sequence"
    );
  }
  if (includesOneOf(normalized, ["out of gas", "gas wanted", "gas不足", "燃料不足"])) {
    return new SoulonWalletError(WALLET_SEMANTIC_ERROR_CODES.OUT_OF_GAS, message || "out of gas");
  }
  if (
    includesOneOf(normalized, [
      "insufficient funds",
      "spendable balance",
      "不足",
      "余额不足"
    ])
  ) {
    return new SoulonWalletError(
      WALLET_SEMANTIC_ERROR_CODES.INSUFFICIENT_FUNDS,
      message || "insufficient funds"
    );
  }
  if (
    includesOneOf(normalized, ["invalid", "malformed", "illegal", "参数非法", "invalid argument", "invalid request"])
  ) {
    return new SoulonWalletError(WALLET_SEMANTIC_ERROR_CODES.INVALID_ARGUMENT, message || "invalid request");
  }
  return new SoulonWalletError(WALLET_SEMANTIC_ERROR_CODES.TX_REJECTED, message || "transaction rejected");
};
