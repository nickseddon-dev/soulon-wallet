import { SoulonWalletError } from "./errors.js";

export const BIP21_ERROR_CODES = {
  INVALID_URI: "BIP21_INVALID_URI",
  INVALID_SCHEME: "BIP21_INVALID_SCHEME",
  INVALID_ADDRESS: "BIP21_INVALID_ADDRESS",
  INVALID_AMOUNT: "BIP21_INVALID_AMOUNT"
} as const;

export type Bip21ErrorCode = (typeof BIP21_ERROR_CODES)[keyof typeof BIP21_ERROR_CODES];

export type GenerateBip21UriInput = {
  address: string;
  amount?: string;
  memo?: string;
  scheme?: string;
};

export type ParsedBip21Uri = {
  scheme: string;
  address: string;
  amount?: string;
  memo?: string;
};

const DECIMAL_AMOUNT_REGEX = /^(?:0|[1-9]\d*)(?:\.\d+)?$/;
const SCHEME_REGEX = /^[a-z][a-z0-9+.-]*$/;
const ADDRESS_INVALID_CHAR_REGEX = /[\s?#]/;

const createBip21Error = (code: Bip21ErrorCode, message: string): SoulonWalletError => {
  return new SoulonWalletError(code, message);
};

const normalizeNonEmpty = (value: string, code: Bip21ErrorCode, message: string): string => {
  const normalized = value.trim();
  if (!normalized) {
    throw createBip21Error(code, message);
  }
  return normalized;
};

const validateScheme = (scheme: string): string => {
  const normalizedScheme = normalizeNonEmpty(
    scheme,
    BIP21_ERROR_CODES.INVALID_SCHEME,
    "BIP-21 scheme is required"
  ).toLowerCase();
  if (!SCHEME_REGEX.test(normalizedScheme)) {
    throw createBip21Error(BIP21_ERROR_CODES.INVALID_SCHEME, "BIP-21 scheme is invalid");
  }
  return normalizedScheme;
};

const validateAddress = (address: string): string => {
  const normalizedAddress = normalizeNonEmpty(
    address,
    BIP21_ERROR_CODES.INVALID_ADDRESS,
    "BIP-21 address is required"
  );
  if (ADDRESS_INVALID_CHAR_REGEX.test(normalizedAddress)) {
    throw createBip21Error(BIP21_ERROR_CODES.INVALID_ADDRESS, "BIP-21 address is invalid");
  }
  return normalizedAddress;
};

const validateAmount = (amount: string): string => {
  const normalizedAmount = normalizeNonEmpty(
    amount,
    BIP21_ERROR_CODES.INVALID_AMOUNT,
    "BIP-21 amount is required"
  );
  if (!DECIMAL_AMOUNT_REGEX.test(normalizedAmount) || Number(normalizedAmount) <= 0) {
    throw createBip21Error(BIP21_ERROR_CODES.INVALID_AMOUNT, "BIP-21 amount is invalid");
  }
  return normalizedAmount;
};

export const generateBip21Uri = (input: GenerateBip21UriInput): string => {
  const scheme = validateScheme(input.scheme ?? "bitcoin");
  const address = validateAddress(input.address);
  const searchParams = new URLSearchParams();

  if (input.amount !== undefined) {
    searchParams.set("amount", validateAmount(input.amount));
  }
  if (input.memo !== undefined) {
    const normalizedMemo = input.memo.trim();
    if (normalizedMemo) {
      searchParams.set("memo", normalizedMemo);
    }
  }

  const query = searchParams.toString();
  if (!query) {
    return `${scheme}:${address}`;
  }
  return `${scheme}:${address}?${query}`;
};

export const parseBip21Uri = (uri: string): ParsedBip21Uri => {
  const normalizedUri = normalizeNonEmpty(uri, BIP21_ERROR_CODES.INVALID_URI, "BIP-21 URI is required");
  const schemeSeparatorIndex = normalizedUri.indexOf(":");
  if (schemeSeparatorIndex <= 0) {
    throw createBip21Error(BIP21_ERROR_CODES.INVALID_URI, "BIP-21 URI is invalid");
  }

  const scheme = validateScheme(normalizedUri.slice(0, schemeSeparatorIndex));
  const payload = normalizedUri.slice(schemeSeparatorIndex + 1);
  if (!payload) {
    throw createBip21Error(BIP21_ERROR_CODES.INVALID_URI, "BIP-21 URI is invalid");
  }

  const queryIndex = payload.indexOf("?");
  const addressSegment = queryIndex >= 0 ? payload.slice(0, queryIndex) : payload;
  const address = validateAddress(addressSegment);

  const parsed: ParsedBip21Uri = {
    scheme,
    address
  };

  if (queryIndex < 0) {
    return parsed;
  }

  const query = payload.slice(queryIndex + 1);
  const searchParams = new URLSearchParams(query);
  const amount = searchParams.get("amount");
  if (amount !== null) {
    parsed.amount = validateAmount(amount);
  }

  const memo = searchParams.get("memo") ?? searchParams.get("message");
  if (memo !== null) {
    const normalizedMemo = memo.trim();
    if (normalizedMemo) {
      parsed.memo = normalizedMemo;
    }
  }

  return parsed;
};
