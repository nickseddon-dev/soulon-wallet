import fs from "node:fs";
import path from "node:path";
import {
  SoulonWalletError,
  sendNativeToken,
  delegateToValidator,
  undelegateFromValidator,
  withdrawValidatorRewards,
  voteProposal,
  queryValidators,
  queryRewards,
  queryProposals
} from "../dist/index.js";

const parseEnvFile = (filePath) => {
  const raw = fs.readFileSync(filePath, "utf8");
  const result = {};
  for (const lineRaw of raw.split(/\r?\n/)) {
    const line = lineRaw.trim();
    if (!line || line.startsWith("#")) {
      continue;
    }
    const pair = line.split("=", 2);
    if (pair.length === 2) {
      result[pair[0]] = pair[1];
    }
  }
  return result;
};

const assertOk = (condition, message) => {
  if (!condition) {
    throw new Error(message);
  }
};

const loadBusinessData = (root) => {
  const dataPath = path.join(root, "deploy", "business-test-data.json");
  const examplePath = path.join(root, "deploy", "business-test-data.example.json");
  const targetPath = fs.existsSync(dataPath) ? dataPath : examplePath;
  if (!fs.existsSync(targetPath)) {
    throw new Error("缺少 deploy/business-test-data.json 或 deploy/business-test-data.example.json");
  }
  return JSON.parse(fs.readFileSync(targetPath, "utf8"));
};

const createMockSigningClient = () => {
  const state = {
    signAndBroadcastCalls: [],
    responses: []
  };
  return {
    pushResponses(...responses) {
      state.responses.push(...responses);
    },
    getCallCount() {
      return state.signAndBroadcastCalls.length;
    },
    async signAndBroadcast(address, msgs, fee, memo) {
      state.signAndBroadcastCalls.push({ address, msgs, fee, memo });
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

const root = process.cwd();
const deployEnvPath = path.join(root, "deploy", "deploy.env");
if (!fs.existsSync(deployEnvPath)) {
  throw new Error("缺少 deploy/deploy.env");
}

const env = { ...parseEnvFile(deployEnvPath), ...process.env };
const data = loadBusinessData(root);
const skipNetworkRaw = String(env.SOULON_SKIP_NETWORK_TEST || "").toLowerCase();
const skipNetwork = skipNetworkRaw === "true" || skipNetworkRaw === "1" || skipNetworkRaw === "yes";

const network = {
  chainId: env.SOULON_CHAIN_ID,
  bech32Prefix: env.SOULON_BECH32_PREFIX,
  rpcEndpoint: env.SOULON_RPC,
  restEndpoint: env.SOULON_REST,
  grpcEndpoint: env.SOULON_GRPC,
  denom: env.SOULON_DENOM,
  gasPrice: env.SOULON_GAS_PRICE
};

const runTxIntegration = async () => {
  const client = createMockSigningClient();
  const transferFromAddress = data.transferFromAddress || data.delegatorAddress;
  const transferToAddress = data.transferToAddress || data.voterAddress || data.delegatorAddress;
  const transferAmount = String(data.transferAmount || "1");

  const transferCallCountBefore = client.getCallCount();
  client.pushResponses(
    { code: 11, transactionHash: "HASH_T1", rawLog: "out of gas" },
    { code: 0, transactionHash: "HASH_T2", rawLog: "" }
  );
  const transferResult = await sendNativeToken(client, network, {
    fromAddress: transferFromAddress,
    toAddress: transferToAddress,
    amount: transferAmount,
    memo: "integration-transfer"
  });
  assertOk(transferResult.code === 0, "transfer 结果应成功");
  assertOk(client.getCallCount() === transferCallCountBefore + 2, "transfer 应触发一次重试");

  client.pushResponses({ code: 4, transactionHash: "HASH_T3", rawLog: "insufficient funds" });
  let insufficientFundsThrown = false;
  try {
    await sendNativeToken(client, network, {
      fromAddress: transferFromAddress,
      toAddress: transferToAddress,
      amount: transferAmount,
      memo: "integration-transfer-insufficient-funds"
    });
  } catch (error) {
    insufficientFundsThrown =
      error instanceof SoulonWalletError && error.code === "INSUFFICIENT_FUNDS";
  }
  assertOk(insufficientFundsThrown, "transfer 余额不足场景应抛出映射错误");
  console.log("转账链路集成测试通过");

  const delegateCallCountBefore = client.getCallCount();
  client.pushResponses(
    { code: 11, transactionHash: "HASH_1", rawLog: "out of gas" },
    { code: 0, transactionHash: "HASH_2", rawLog: "" }
  );
  const delegateResult = await delegateToValidator(client, network, {
    delegatorAddress: data.delegatorAddress,
    validatorAddress: data.validatorAddress,
    amount: data.delegateAmount,
    memo: "integration-delegate"
  });
  assertOk(delegateResult.code === 0, "delegate 结果应成功");
  assertOk(client.getCallCount() === delegateCallCountBefore + 2, "delegate 应触发一次重试");

  client.pushResponses({ code: 0, transactionHash: "HASH_3", rawLog: "" });
  const undelegateResult = await undelegateFromValidator(client, network, {
    delegatorAddress: data.delegatorAddress,
    validatorAddress: data.validatorAddress,
    amount: data.undelegateAmount,
    memo: "integration-undelegate"
  });
  assertOk(undelegateResult.code === 0, "undelegate 结果应成功");

  client.pushResponses({ code: 0, transactionHash: "HASH_4", rawLog: "" });
  const rewardResult = await withdrawValidatorRewards(client, network, {
    delegatorAddress: data.delegatorAddress,
    validatorAddress: data.validatorAddress,
    memo: "integration-withdraw"
  });
  assertOk(rewardResult.code === 0, "withdraw 结果应成功");

  client.pushResponses({ code: 0, transactionHash: "HASH_5", rawLog: "" });
  const voteResult = await voteProposal(client, network, {
    voterAddress: data.voterAddress,
    proposalId: BigInt(data.proposalId),
    option: "yes",
    memo: "integration-vote"
  });
  assertOk(voteResult.code === 0, "vote 结果应成功");

  client.pushResponses({ code: 13, transactionHash: "HASH_6", rawLog: "unauthorized" });
  let unauthorizedThrown = false;
  try {
    await voteProposal(client, network, {
      voterAddress: data.voterAddress,
      proposalId: BigInt(data.proposalId),
      option: "yes",
      memo: "integration-vote-unauthorized"
    });
  } catch (error) {
    unauthorizedThrown =
      error instanceof SoulonWalletError && error.code === "UNAUTHORIZED";
  }
  assertOk(unauthorizedThrown, "unauthorized 场景应抛出映射错误");
  console.log("质押与治理链路集成测试通过");
};

const runQueryIntegration = async () => {
  if (skipNetwork) {
    console.log("已跳过网络查询集成测试（SOULON_SKIP_NETWORK_TEST=true/1/yes）");
    return;
  }
  const validators = await queryValidators(network);
  assertOk(Array.isArray(validators?.validators), "validators 返回结构异常");
  const rewards = await queryRewards(network, data.delegatorAddress);
  assertOk(typeof rewards === "object" && rewards !== null, "rewards 返回结构异常");
  const proposals = await queryProposals(network);
  assertOk(Array.isArray(proposals?.proposals), "proposals 返回结构异常");
  console.log("查询链路集成测试通过");
};

const main = async () => {
  console.log("钱包业务集成测试开始");
  await runTxIntegration();
  await runQueryIntegration();
  console.log("钱包业务集成测试完成");
};

main().catch((error) => {
  console.error("钱包业务集成测试失败");
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
