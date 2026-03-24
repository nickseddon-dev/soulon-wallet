import fs from "node:fs";
import path from "node:path";

const root = process.cwd();
const envPath = path.join(root, "deploy", "deploy.env");
const examplePath = path.join(root, "deploy", "deploy.env.example");

if (!fs.existsSync(examplePath)) {
  console.error("缺少 deploy/deploy.env.example");
  process.exit(1);
}

if (!fs.existsSync(envPath)) {
  console.error("缺少 deploy/deploy.env，请从 deploy.env.example 复制并修改。");
  process.exit(1);
}

const content = fs.readFileSync(envPath, "utf8");
const requiredKeys = [
  "SOULON_ENV",
  "SOULON_RPC",
  "SOULON_REST",
  "SOULON_GRPC",
  "SOULON_CHAIN_ID",
  "SOULON_BECH32_PREFIX",
  "SOULON_DENOM",
  "SOULON_GAS_PRICE"
];

const keySet = new Set(
  content
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line && !line.startsWith("#"))
    .map((line) => line.split("=", 1)[0])
);

const missing = requiredKeys.filter((key) => !keySet.has(key));
if (missing.length > 0) {
  console.error(`deploy.env 缺少字段: ${missing.join(", ")}`);
  process.exit(1);
}

console.log("deploy.env 配置校验通过");
