import test from "node:test";
import assert from "node:assert/strict";
import {
  SoulonWalletError,
  WALLET_ACCOUNT_ERROR_CODES,
  createIdentityManager,
  createWalletFromMnemonic,
  createWalletFromMnemonicWithPath,
  deriveAddressFromMnemonic,
  deriveHdPath,
  getFirstAccountAddress,
  isAddressForPrefix
} from "../dist/index.js";

const mnemonic = "test test test test test test test test test test test junk";
const prefix = "cosmos";

test("createWalletFromMnemonic: 可创建账户并返回匹配前缀地址", async () => {
  const signer = await createWalletFromMnemonic({
    mnemonic,
    prefix
  });
  const address = await getFirstAccountAddress(signer, prefix);
  assert.equal(address.startsWith(`${prefix}1`), true);
  assert.equal(isAddressForPrefix(address, prefix), true);
});

test("createWalletFromMnemonicWithPath: 不同地址索引会派生不同地址", async () => {
  const signer0 = await createWalletFromMnemonicWithPath({
    mnemonic,
    prefix,
    coinType: 118,
    addressIndex: 0
  });
  const signer1 = await createWalletFromMnemonicWithPath({
    mnemonic,
    prefix,
    coinType: 118,
    addressIndex: 1
  });
  const address0 = await getFirstAccountAddress(signer0, prefix);
  const address1 = await getFirstAccountAddress(signer1, prefix);
  assert.notEqual(address0, address1);
});

test("deriveHdPath: 按输入生成标准 BIP44 路径", () => {
  const hdPath = deriveHdPath({
    coinType: 118,
    account: 2,
    change: 1,
    addressIndex: 9
  });
  assert.equal(hdPath, "m/44'/118'/2'/1/9");
});

test("deriveAddressFromMnemonic: 返回可校验的派生地址", async () => {
  const address = await deriveAddressFromMnemonic({
    mnemonic,
    prefix,
    coinType: 118,
    account: 0,
    change: 0,
    addressIndex: 3
  });
  assert.equal(isAddressForPrefix(address, prefix), true);
});

test("createWalletFromMnemonic: 非法助记词长度返回标准错误", async () => {
  await assert.rejects(
    async () => {
      await createWalletFromMnemonic({
        mnemonic: "too short",
        prefix
      });
    },
    (error) => {
      assert.ok(error instanceof SoulonWalletError);
      assert.equal(error.code, WALLET_ACCOUNT_ERROR_CODES.INVALID_MNEMONIC);
      return true;
    }
  );
});

test("createWalletFromMnemonicWithPath: 非法派生参数返回标准错误", async () => {
  await assert.rejects(
    async () => {
      await createWalletFromMnemonicWithPath({
        mnemonic,
        prefix,
        coinType: -1
      });
    },
    (error) => {
      assert.ok(error instanceof SoulonWalletError);
      assert.equal(error.code, WALLET_ACCOUNT_ERROR_CODES.INVALID_COIN_TYPE);
      return true;
    }
  );
});

test("createIdentityManager: 仅给地址索引但缺少 coinType 时阻断导入", async () => {
  const identityManager = createIdentityManager();
  await assert.rejects(
    async () => {
      await identityManager.createSignerFromMnemonic({
        mnemonic,
        prefix,
        addressIndex: 1
      });
    },
    (error) => {
      assert.ok(error instanceof SoulonWalletError);
      assert.equal(error.code, WALLET_ACCOUNT_ERROR_CODES.INVALID_COIN_TYPE);
      return true;
    }
  );
});
