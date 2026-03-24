import { stringToPath } from "@cosmjs/crypto";
import { DirectSecp256k1HdWallet, OfflineSigner } from "@cosmjs/proto-signing";
import { SoulonWalletError } from "./errors.js";

export type CreateWalletInput = {
  mnemonic: string;
  prefix: string;
  bip39Passphrase?: string;
};

export type CreateWalletWithPathInput = CreateWalletInput & {
  coinType: number;
  account?: number;
  change?: number;
  addressIndex?: number;
};

export const WALLET_ACCOUNT_ERROR_CODES = {
  INVALID_MNEMONIC: "INVALID_MNEMONIC",
  INVALID_PREFIX: "INVALID_PREFIX",
  INVALID_COIN_TYPE: "INVALID_COIN_TYPE",
  INVALID_ACCOUNT_INDEX: "INVALID_ACCOUNT_INDEX",
  INVALID_CHANGE_INDEX: "INVALID_CHANGE_INDEX",
  INVALID_ADDRESS_INDEX: "INVALID_ADDRESS_INDEX",
  INVALID_ADDRESS: "INVALID_ADDRESS",
  ACCOUNT_NOT_FOUND: "ACCOUNT_NOT_FOUND"
} as const;

const BIP39_WORD_COUNTS = new Set([12, 24]);

const normalizeNonEmpty = (value: string, code: string, message: string): string => {
  const normalized = value.trim();
  if (!normalized) {
    throw new SoulonWalletError(code, message);
  }
  return normalized;
};

const validateMnemonic = (mnemonic: string): string => {
  const normalizedMnemonic = normalizeNonEmpty(
    mnemonic,
    WALLET_ACCOUNT_ERROR_CODES.INVALID_MNEMONIC,
    "Mnemonic is required"
  );
  const words = normalizedMnemonic.split(/\s+/);
  if (!BIP39_WORD_COUNTS.has(words.length)) {
    throw new SoulonWalletError(
      WALLET_ACCOUNT_ERROR_CODES.INVALID_MNEMONIC,
      "Mnemonic must contain 12 or 24 words"
    );
  }
  return words.join(" ");
};

const validatePrefix = (prefix: string): string => {
  const normalizedPrefix = normalizeNonEmpty(
    prefix,
    WALLET_ACCOUNT_ERROR_CODES.INVALID_PREFIX,
    "Address prefix is required"
  );
  if (!/^[a-z][a-z0-9]{1,31}$/.test(normalizedPrefix)) {
    throw new SoulonWalletError(
      WALLET_ACCOUNT_ERROR_CODES.INVALID_PREFIX,
      "Address prefix format is invalid"
    );
  }
  return normalizedPrefix;
};

const validatePathIndex = (value: number | undefined, code: string, label: string): number => {
  const normalized = value ?? 0;
  if (!Number.isInteger(normalized) || normalized < 0) {
    throw new SoulonWalletError(code, `${label} must be a non-negative integer`);
  }
  return normalized;
};

const validateCoinType = (coinType: number): number => {
  if (!Number.isInteger(coinType) || coinType < 0) {
    throw new SoulonWalletError(
      WALLET_ACCOUNT_ERROR_CODES.INVALID_COIN_TYPE,
      "Coin type must be a non-negative integer"
    );
  }
  return coinType;
};

const escapeForRegex = (value: string): string => {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
};

export const deriveHdPath = (input: {
  coinType: number;
  account?: number;
  change?: number;
  addressIndex?: number;
}): string => {
  const coinType = validateCoinType(input.coinType);
  const account = validatePathIndex(
    input.account,
    WALLET_ACCOUNT_ERROR_CODES.INVALID_ACCOUNT_INDEX,
    "Account index"
  );
  const change = validatePathIndex(
    input.change,
    WALLET_ACCOUNT_ERROR_CODES.INVALID_CHANGE_INDEX,
    "Change index"
  );
  const addressIndex = validatePathIndex(
    input.addressIndex,
    WALLET_ACCOUNT_ERROR_CODES.INVALID_ADDRESS_INDEX,
    "Address index"
  );
  return `m/44'/${coinType}'/${account}'/${change}/${addressIndex}`;
};

export const isAddressForPrefix = (address: string, prefix: string): boolean => {
  const normalizedPrefix = validatePrefix(prefix);
  const normalizedAddress = address.trim();
  if (!normalizedAddress) {
    return false;
  }
  const addressPattern = new RegExp(`^${escapeForRegex(normalizedPrefix)}1[02-9ac-hj-np-z]{6,}$`);
  return addressPattern.test(normalizedAddress);
};

export const createWalletFromMnemonic = async (
  input: CreateWalletInput
): Promise<OfflineSigner> => {
  const mnemonic = validateMnemonic(input.mnemonic);
  const prefix = validatePrefix(input.prefix);
  return DirectSecp256k1HdWallet.fromMnemonic(mnemonic, {
    prefix,
    bip39Password: input.bip39Passphrase
  });
};

export const createWalletFromMnemonicWithPath = async (
  input: CreateWalletWithPathInput
): Promise<OfflineSigner> => {
  const mnemonic = validateMnemonic(input.mnemonic);
  const prefix = validatePrefix(input.prefix);
  const hdPath = stringToPath(
    deriveHdPath({
      coinType: input.coinType,
      account: input.account,
      change: input.change,
      addressIndex: input.addressIndex
    })
  );
  return DirectSecp256k1HdWallet.fromMnemonic(mnemonic, {
    prefix,
    hdPaths: [hdPath],
    bip39Password: input.bip39Passphrase
  });
};

export const createRandomWallet = async (prefix: string): Promise<{
  mnemonic: string;
  signer: OfflineSigner;
}> => {
  const normalizedPrefix = validatePrefix(prefix);
  const wallet = await DirectSecp256k1HdWallet.generate(24, { prefix: normalizedPrefix });
  const mnemonic = wallet.mnemonic;
  return {
    mnemonic,
    signer: wallet
  };
};

export const getFirstAccountAddress = async (signer: OfflineSigner, prefix?: string): Promise<string> => {
  const [account] = await signer.getAccounts();
  if (!account?.address) {
    throw new SoulonWalletError(
      WALLET_ACCOUNT_ERROR_CODES.ACCOUNT_NOT_FOUND,
      "No account available from signer"
    );
  }
  if (prefix !== undefined && !isAddressForPrefix(account.address, prefix)) {
    throw new SoulonWalletError(
      WALLET_ACCOUNT_ERROR_CODES.INVALID_ADDRESS,
      "Derived address does not match expected prefix"
    );
  }
  return account.address;
};

export const deriveAddressFromMnemonic = async (
  input: CreateWalletWithPathInput
): Promise<string> => {
  const signer = await createWalletFromMnemonicWithPath(input);
  return getFirstAccountAddress(signer, input.prefix);
};
