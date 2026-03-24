import fs from "node:fs";
import path from "node:path";
import {
  createWalletFromMnemonic,
  getFirstAccountAddress,
  createSigningClient,
  createQueryClient,
  sendNativeToken,
  waitForTx
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

const loadE2EData = (root) => {
  const dataPath = path.join(root, "deploy", "e2e-test-data.json");
  const examplePath = path.join(root, "deploy", "e2e-test-data.example.json");
  const targetPath = fs.existsSync(dataPath) ? dataPath : examplePath;
  if (!fs.existsSync(targetPath)) {
    throw new Error("缺少 deploy/e2e-test-data.json 或 deploy/e2e-test-data.example.json");
  }
  return JSON.parse(fs.readFileSync(targetPath, "utf8"));
};

const root = process.cwd();
const deployEnvPath = path.join(root, "deploy", "deploy.env");
if (!fs.existsSync(deployEnvPath)) {
  throw new Error("缺少 deploy/deploy.env");
}

const env = { ...parseEnvFile(deployEnvPath), ...process.env };
const data = loadE2EData(root);
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

const runOfflineDrill = async () => {
  const offlineMnemonic =
    data.offlineMnemonic ||
    "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
  const signer = await createWalletFromMnemonic({
    mnemonic: offlineMnemonic,
    prefix: network.bech32Prefix
  });
  const fromAddress = await getFirstAccountAddress(signer);
  const toAddress = data.offlineRecipientAddress || fromAddress;
  const mockSigningClient = {
    async signAndBroadcast() {
      return {
        code: 0,
        transactionHash: "OFFLINE_E2E_HASH",
        rawLog: ""
      };
    }
  };
  const txResult = await sendNativeToken(mockSigningClient, network, {
    fromAddress,
    toAddress,
    amount: String(data.transferAmount || "1"),
    memo: "wallet-e2e-offline"
  });
  assertOk(txResult.code === 0, "离线转账演练失败");
  const mockQueryClient = {
    async getTx(hash) {
      return {
        hash,
        height: Number(data.offlineConfirmedHeight || 1)
      };
    }
  };
  const receipt = await waitForTx(mockQueryClient, {
    hash: txResult.transactionHash,
    timeoutMs: Number(data.timeoutMs || 5_000),
    pollIntervalMs: Number(data.pollIntervalMs || 500)
  });
  assertOk(receipt.status === "confirmed", "离线回执确认失败");
  console.log(`离线模式通过: address=${fromAddress}, hash=${txResult.transactionHash}`);
};

const runOnlineE2E = async () => {
  assertOk(Boolean(data.senderMnemonic), "在线模式缺少 senderMnemonic");
  assertOk(Boolean(data.recipientAddress), "在线模式缺少 recipientAddress");
  assertOk(Boolean(data.transferAmount), "在线模式缺少 transferAmount");
  const signer = await createWalletFromMnemonic({
    mnemonic: data.senderMnemonic,
    prefix: network.bech32Prefix
  });
  const fromAddress = await getFirstAccountAddress(signer);
  console.log(`账户读取成功: ${fromAddress}`);
  const signingClient = await createSigningClient(network, signer);
  const txResult = await sendNativeToken(signingClient, network, {
    fromAddress,
    toAddress: data.recipientAddress,
    amount: String(data.transferAmount),
    memo: String(data.memo || "wallet-e2e-testnet")
  });
  assertOk(txResult.code === 0, `转账提交失败: code=${txResult.code}`);
  console.log(`转账提交成功: hash=${txResult.transactionHash}`);
  const queryClient = await createQueryClient(network);
  const receipt = await waitForTx(queryClient, {
    hash: txResult.transactionHash,
    timeoutMs: Number(data.timeoutMs || 60_000),
    pollIntervalMs: Number(data.pollIntervalMs || 2_000)
  });
  assertOk(receipt.status === "confirmed", "在线模式回执确认超时");
  console.log(`回执确认成功: height=${receipt.height}`);
};

const main = async () => {
  console.log("钱包测试网 E2E 开始");
  if (skipNetwork) {
    await runOfflineDrill();
  } else {
    await runOnlineE2E();
  }
  console.log("钱包测试网 E2E 完成");
};

main().catch((error) => {
  console.error("钱包测试网 E2E 失败");
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
