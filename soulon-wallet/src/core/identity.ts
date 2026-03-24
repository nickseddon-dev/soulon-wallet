import { OfflineSigner } from "@cosmjs/proto-signing";
import { createWalletFromMnemonic, createWalletFromMnemonicWithPath, createRandomWallet } from "./wallet.js";
import { SoulonWalletError } from "./errors.js";
import { WALLET_ACCOUNT_ERROR_CODES } from "./wallet.js";

export type PlatformKeySignInput = {
  message: Uint8Array;
  keyAlias: string;
};

export type PlatformKeySigner = {
  signSecp256k1(input: PlatformKeySignInput): Promise<Uint8Array>;
  signEd25519(input: PlatformKeySignInput): Promise<Uint8Array>;
};

export type IdentityManager = {
  createSignerFromMnemonic(input: {
    mnemonic: string;
    prefix: string;
    bip39Passphrase?: string;
    coinType?: number;
    account?: number;
    change?: number;
    addressIndex?: number;
  }): Promise<OfflineSigner>;
  createRandomSigner(prefix: string): Promise<{
    mnemonic: string;
    signer: OfflineSigner;
  }>;
};

export const createIdentityManager = (): IdentityManager => {
  return {
    createSignerFromMnemonic: async (input) => {
      const hasPathIndexes =
        input.account !== undefined || input.change !== undefined || input.addressIndex !== undefined;
      if (input.coinType === undefined) {
        if (hasPathIndexes) {
          throw new SoulonWalletError(
            WALLET_ACCOUNT_ERROR_CODES.INVALID_COIN_TYPE,
            "coinType is required when account/change/addressIndex is provided"
          );
        }
        return createWalletFromMnemonic({
          mnemonic: input.mnemonic,
          prefix: input.prefix,
          bip39Passphrase: input.bip39Passphrase
        });
      }
      return createWalletFromMnemonicWithPath({
        mnemonic: input.mnemonic,
        prefix: input.prefix,
        bip39Passphrase: input.bip39Passphrase,
        coinType: input.coinType,
        account: input.account,
        change: input.change,
        addressIndex: input.addressIndex
      });
    },
    createRandomSigner: async (prefix) => {
      return createRandomWallet(prefix);
    }
  };
};

export const createUnimplementedPlatformKeySigner = (): PlatformKeySigner => {
  return {
    signSecp256k1: async () => {
      throw new Error("Platform secp256k1 signer is not implemented");
    },
    signEd25519: async () => {
      throw new Error("Platform ed25519 signer is not implemented");
    }
  };
};
