import test from "node:test";
import assert from "node:assert/strict";
import {
  GOVERNANCE_ERROR_CODES,
  STAKING_ERROR_CODES,
  SoulonWalletError,
  delegateToValidator,
  queryProposalDetail,
  queryProposals,
  voteProposal,
  withdrawValidatorRewards
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

const validDelegatorAddress = "cosmos1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq4d6v";
const validValidatorAddress = "cosmosvaloper1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqql7r";

const createMockSigningClient = () => {
  const calls = [];
  return {
    calls,
    async signAndBroadcast(address, messages, fee, memo) {
      calls.push({ address, messages, fee, memo });
      return {
        code: 0,
        transactionHash: "MOCK_HASH",
        rawLog: ""
      };
    }
  };
};

test("delegateToValidator: 组装并提交 Delegate 消息", async () => {
  const client = createMockSigningClient();
  const result = await delegateToValidator(client, network, {
    delegatorAddress: validDelegatorAddress,
    validatorAddress: validValidatorAddress,
    amount: "1000",
    memo: "delegate-test"
  });
  assert.equal(result.code, 0);
  assert.equal(client.calls.length, 1);
  assert.equal(client.calls[0].address, validDelegatorAddress);
  assert.equal(client.calls[0].messages[0].typeUrl, "/cosmos.staking.v1beta1.MsgDelegate");
  assert.equal(client.calls[0].messages[0].value.amount.amount, "1000");
  assert.equal(client.calls[0].messages[0].value.amount.denom, network.denom);
});

test("withdrawValidatorRewards: 组装并提交 Claim 消息", async () => {
  const client = createMockSigningClient();
  const result = await withdrawValidatorRewards(client, network, {
    delegatorAddress: validDelegatorAddress,
    validatorAddress: validValidatorAddress,
    memo: "claim-test"
  });
  assert.equal(result.code, 0);
  assert.equal(client.calls.length, 1);
  assert.equal(client.calls[0].messages[0].typeUrl, "/cosmos.distribution.v1beta1.MsgWithdrawDelegatorReward");
});

test("delegateToValidator: 非法 amount 阻断并返回标准错误", async () => {
  const client = createMockSigningClient();
  await assert.rejects(
    async () => {
      await delegateToValidator(client, network, {
        delegatorAddress: validDelegatorAddress,
        validatorAddress: validValidatorAddress,
        amount: "0"
      });
    },
    (error) => {
      assert.ok(error instanceof SoulonWalletError);
      assert.equal(error.code, STAKING_ERROR_CODES.INVALID_AMOUNT);
      return true;
    }
  );
});

test("voteProposal: 组装并提交投票消息", async () => {
  const client = createMockSigningClient();
  const result = await voteProposal(client, network, {
    voterAddress: validDelegatorAddress,
    proposalId: 12n,
    option: "yes",
    memo: "vote-test"
  });
  assert.equal(result.code, 0);
  assert.equal(client.calls.length, 1);
  assert.equal(client.calls[0].messages[0].typeUrl, "/cosmos.gov.v1beta1.MsgVote");
  assert.equal(client.calls[0].messages[0].value.proposalId, 12n);
});

test("voteProposal: 非法 proposalId 阻断并返回标准错误", async () => {
  const client = createMockSigningClient();
  await assert.rejects(
    async () => {
      await voteProposal(client, network, {
        voterAddress: validDelegatorAddress,
        proposalId: 0n,
        option: "yes"
      });
    },
    (error) => {
      assert.ok(error instanceof SoulonWalletError);
      assert.equal(error.code, GOVERNANCE_ERROR_CODES.INVALID_PROPOSAL_ID);
      return true;
    }
  );
});

test("queryProposals/queryProposalDetail: 校验查询参数并发起请求", async () => {
  const requests = [];
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (url) => {
    requests.push(String(url));
    return {
      async json() {
        return {};
      }
    };
  };
  try {
    await queryProposals(network, " VOTING_PERIOD ");
    await queryProposalDetail(network, 9n);
    assert.equal(
      requests[0],
      "http://127.0.0.1:1317/cosmos/gov/v1beta1/proposals?proposal_status=VOTING_PERIOD"
    );
    assert.equal(requests[1], "http://127.0.0.1:1317/cosmos/gov/v1beta1/proposals/9");
    await assert.rejects(
      async () => {
        await queryProposals(network, "   ");
      },
      (error) => {
        assert.ok(error instanceof SoulonWalletError);
        assert.equal(error.code, GOVERNANCE_ERROR_CODES.INVALID_PROPOSAL_STATUS);
        return true;
      }
    );
  } finally {
    globalThis.fetch = originalFetch;
  }
});
