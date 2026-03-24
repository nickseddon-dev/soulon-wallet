import test from "node:test";
import assert from "node:assert/strict";
import {
  SoulonWalletError,
  GOVERNANCE_ERROR_CODES,
  STAKING_ERROR_CODES,
  sendNativeToken,
  delegateToValidator,
  voteProposal
} from "../dist/index.js";

const network = {
  chainId: "soulon-testnet-1",
  bech32Prefix: "soulon",
  rpcEndpoint: "http://127.0.0.1:26657",
  restEndpoint: "http://127.0.0.1:1317",
  grpcEndpoint: "http://127.0.0.1:9090",
  denom: "usoul",
  gasPrice: "0.025usoul"
};

const transferInput = {
  fromAddress: "soulon1x9j33g5z6vxy8y5g4z2n6f0a9y8a5y7h3k7p9",
  toAddress: "soulon1h7k9g6p4w5x9v8n3m2t6y4u1q9s8r7l5d2e6f",
  amount: "1000",
  memo: "mainflow-transfer"
};

const stakeInput = {
  delegatorAddress: "soulon1x9j33g5z6vxy8y5g4z2n6f0a9y8a5y7h3k7p9",
  validatorAddress: "soulonvaloper1x9j33g5z6vxy8y5g4z2n6f0a9y8a5y7h4q9",
  amount: "1000",
  memo: "mainflow-delegate"
};

const governanceInput = {
  voterAddress: "soulon1x9j33g5z6vxy8y5g4z2n6f0a9y8a5y7h3k7p9",
  proposalId: 1n,
  option: "yes",
  memo: "mainflow-vote"
};

const createMockSigningClient = () => {
  const state = {
    calls: [],
    responses: []
  };
  return {
    pushResponses(...responses) {
      state.responses.push(...responses);
    },
    getCallCount() {
      return state.calls.length;
    },
    async signAndBroadcast(address, messages, fee, memo) {
      state.calls.push({ address, messages, fee, memo });
      if (state.responses.length > 0) {
        return state.responses.shift();
      }
      return {
        code: 0,
        transactionHash: "MOCK_HASH",
        rawLog: ""
      };
    }
  };
};

test("mainflow: 转账、质押、治理三条主流程联调通过", async () => {
  const client = createMockSigningClient();

  const transferCallsBefore = client.getCallCount();
  client.pushResponses(
    { code: 11, transactionHash: "TX_TRANSFER_1", rawLog: "out of gas" },
    { code: 0, transactionHash: "TX_TRANSFER_2", rawLog: "" }
  );
  const transferResult = await sendNativeToken(client, network, transferInput);
  assert.equal(transferResult.code, 0);
  assert.equal(client.getCallCount(), transferCallsBefore + 2);

  client.pushResponses({ code: 0, transactionHash: "TX_STAKE_1", rawLog: "" });
  const delegateResult = await delegateToValidator(client, network, stakeInput);
  assert.equal(delegateResult.code, 0);

  client.pushResponses({ code: 0, transactionHash: "TX_GOV_1", rawLog: "" });
  const voteResult = await voteProposal(client, network, governanceInput);
  assert.equal(voteResult.code, 0);
});

test("mainflow: 三条主流程异常处理映射正确", async () => {
  const client = createMockSigningClient();

  client.pushResponses({ code: 4, transactionHash: "TX_TRANSFER_FAIL", rawLog: "insufficient funds" });
  await assert.rejects(
    async () => {
      await sendNativeToken(client, network, transferInput);
    },
    (error) => {
      assert.ok(error instanceof SoulonWalletError);
      assert.equal(error.code, "INSUFFICIENT_FUNDS");
      return true;
    }
  );

  await assert.rejects(
    async () => {
      await delegateToValidator(client, network, {
        ...stakeInput,
        amount: "0"
      });
    },
    (error) => {
      assert.ok(error instanceof SoulonWalletError);
      assert.equal(error.code, STAKING_ERROR_CODES.INVALID_AMOUNT);
      return true;
    }
  );

  await assert.rejects(
    async () => {
      await voteProposal(client, network, {
        ...governanceInput,
        proposalId: 0n
      });
    },
    (error) => {
      assert.ok(error instanceof SoulonWalletError);
      assert.equal(error.code, GOVERNANCE_ERROR_CODES.INVALID_PROPOSAL_ID);
      return true;
    }
  );
});
