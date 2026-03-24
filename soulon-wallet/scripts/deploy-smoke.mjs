import fs from "node:fs";
import path from "node:path";

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

const root = process.cwd();
const envFile = path.join(root, "deploy", "deploy.env");
if (!fs.existsSync(envFile)) {
  console.error("缺少 deploy/deploy.env");
  process.exit(1);
}

const fileEnv = parseEnvFile(envFile);
const env = { ...fileEnv, ...process.env };
const skipNetworkRaw = String(env.SOULON_SKIP_NETWORK_TEST || "").toLowerCase();
const skipNetwork = skipNetworkRaw === "true" || skipNetworkRaw === "1" || skipNetworkRaw === "yes";

const restEndpoint = env.SOULON_REST;
const chainId = env.SOULON_CHAIN_ID;
if (!restEndpoint || !chainId) {
  console.error("SOULON_REST 或 SOULON_CHAIN_ID 未配置");
  process.exit(1);
}

console.log(`部署冒烟测试开始: env=${env.SOULON_ENV}, chainId=${chainId}`);
console.log(`REST: ${restEndpoint}`);

if (skipNetwork) {
  console.log("已跳过网络连通性测试（SOULON_SKIP_NETWORK_TEST=true/1/yes）");
  process.exit(0);
}

const checkEndpoint = async (url, label) => {
  const response = await fetch(url, { method: "GET" });
  if (!response.ok) {
    throw new Error(`${label} 请求失败: HTTP ${response.status}`);
  }
  return response.json();
};

try {
  const latestBlock = await checkEndpoint(
    `${restEndpoint}/cosmos/base/tendermint/v1beta1/blocks/latest`,
    "latest block"
  );
  const validators = await checkEndpoint(
    `${restEndpoint}/cosmos/staking/v1beta1/validators?pagination.limit=1`,
    "validators"
  );
  const latestHeight = latestBlock?.block?.header?.height ?? "unknown";
  const validatorCount = Array.isArray(validators?.validators) ? validators.validators.length : 0;
  console.log(`链高度: ${latestHeight}`);
  console.log(`验证人查询返回数量: ${validatorCount}`);
  console.log("部署冒烟测试通过");
} catch (error) {
  console.error("部署冒烟测试失败");
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
}
