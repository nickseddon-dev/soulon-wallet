import test from "node:test";
import assert from "node:assert/strict";
import {
  SoulonWalletError,
  broadcastWithRetry,
  buildNativeTransferMessage,
  mapTxError,
  sendNativeToken,
  sendNativeTokenAndConfirm
} from "../dist/index.js";

const network = {
  chainId: "soulon-testnet-1",
  bech32Prefix: "cosmos",
  rpcEndpoint: "http://127.0.0.1:26657",
  restEndpoint: "http://127.0.0.1:1317",
  grpcEndpoint: "http://127.0.0.1:9090",
  denom: "usoul",
  gasPrice: "0.025usoul"
};

const transferInput = {
  fromAddress: "cosmos1sender000000000000000000000000000000000",
  toAddress: "cosmos1receiver0000000000000000000000000000000",
  amount: "12345",
  memo: "unit-test-transfer"
};

test("buildNativeTransferMessage: 构建 MsgSend 交易消息", () => {
  const message = buildNativeTransferMessage(network, transferInput);
  assert.equal(message.typeUrl, "/cosmos.bank.v1beta1.MsgSend");
  assert.equal(message.value.fromAddress, transferInput.fromAddress);
  assert.equal(message.value.toAddress, transferInput.toAddress);
  assert.equal(message.value.amount[0].amount, transferInput.amount);
  assert.equal(message.value.amount[0].denom, network.denom);
});

test("sendNativeToken: 使用 signAndBroadcast 提交签名广播", async () => {
  const calls = [];
  const mockSigningClient = {
    async signAndBroadcast(address, messages, fee, memo) {
      calls.push({ address, messages, fee, memo });
      return {
        code: 0,
        transactionHash: "TX_HASH_1",
        rawLog: ""
      };
    }
  };
  const result = await sendNativeToken(mockSigningClient, network, transferInput);
  assert.equal(result.code, 0);
  assert.equal(calls.length, 1);
  assert.equal(calls[0].address, transferInput.fromAddress);
  assert.equal(calls[0].fee, "auto");
  assert.equal(calls[0].memo, transferInput.memo);
  assert.equal(calls[0].messages[0].typeUrl, "/cosmos.bank.v1beta1.MsgSend");
});

test("sendNativeTokenAndConfirm: 返回交易哈希和确认状态", async () => {
  const mockSigningClient = {
    async signAndBroadcast() {
      return {
        code: 0,
        transactionHash: "TX_HASH_2",
        rawLog: ""
      };
    }
  };
  let queryCount = 0;
  const mockQueryClient = {
    async getTx(hash) {
      queryCount += 1;
      if (queryCount < 2) {
        return null;
      }
      return {
        hash,
        height: 88
      };
    }
  };
  const result = await sendNativeTokenAndConfirm(
    mockSigningClient,
    mockQueryClient,
    network,
    {
      ...transferInput,
      timeoutMs: 100,
      pollIntervalMs: 1
    }
  );
  assert.equal(result.txResult.transactionHash, "TX_HASH_2");
  assert.equal(result.receipt.status, "confirmed");
  assert.equal(result.receipt.height, 88);
  assert.equal(result.receipt.hash, "TX_HASH_2");
});

test("broadcastWithRetry: 节点异常可重试并最终成功", async () => {
  let attempts = 0;
  const result = await broadcastWithRetry(
    async () => {
      attempts += 1;
      if (attempts === 1) {
        throw new Error("connect ECONNREFUSED 127.0.0.1:26657");
      }
      return {
        code: 0,
        transactionHash: "TX_HASH_3",
        rawLog: "",
        events: [],
        msgResponses: [],
        gasUsed: BigInt(0),
        gasWanted: BigInt(0),
        height: 0
      };
    },
    {
      maxAttempts: 2,
      baseDelayMs: 0
    }
  );
  assert.equal(result.code, 0);
  assert.equal(attempts, 2);
});

test("broadcastWithRetry: 非可重试异常抛出标准错误", async () => {
  await assert.rejects(
    async () => {
      await broadcastWithRetry(
        async () => {
          throw new Error("invalid signature format");
        },
        {
          maxAttempts: 2,
          baseDelayMs: 0
        }
      );
    },
    (error) => {
      assert.ok(error instanceof SoulonWalletError);
      assert.equal(error.code, "INVALID_ARGUMENT");
      return true;
    }
  );
});

test("mapTxError: 未知 code 按日志映射 sequence 错误", () => {
  const mapped = mapTxError(99, "account sequence mismatch, expected 10, got 9");
  assert.ok(mapped instanceof SoulonWalletError);
  assert.equal(mapped.code, "INVALID_SEQUENCE");
});

test("mapTxError: 参数非法映射 INVALID_ARGUMENT", () => {
  const mapped = mapTxError(2, "invalid request: memo cannot exceed 256 chars");
  assert.ok(mapped instanceof SoulonWalletError);
  assert.equal(mapped.code, "INVALID_ARGUMENT");
});
