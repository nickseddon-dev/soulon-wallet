import fs from "node:fs";
import path from "node:path";

const root = process.cwd();
const scanTargets = ["src", "scripts", "deploy"];
const patterns = [
  { name: "私钥明文字段", regex: /private[_-]?key\s*[:=]\s*["'`][^"'`]{16,}/i },
  { name: "助记词明文字段", regex: /mnemonic\s*[:=]\s*["'`][^"'`]{16,}/i },
  { name: "硬编码密钥", regex: /(api[_-]?key|secret)\s*[:=]\s*["'`][^"'`]{12,}/i }
];

const collectFiles = (dir) => {
  if (!fs.existsSync(dir)) {
    return [];
  }
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const absolute = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === "node_modules" || entry.name === "dist") {
        continue;
      }
      files.push(...collectFiles(absolute));
      continue;
    }
    files.push(absolute);
  }
  return files;
};

const allFiles = scanTargets.flatMap((target) => collectFiles(path.join(root, target)));
const hitList = [];

for (const file of allFiles) {
  const content = fs.readFileSync(file, "utf8");
  for (const pattern of patterns) {
    if (pattern.regex.test(content)) {
      hitList.push({ file, rule: pattern.name });
    }
  }
}

if (hitList.length > 0) {
  console.error("安全自查未通过");
  for (const hit of hitList) {
    console.error(`${hit.rule}: ${path.relative(root, hit.file)}`);
  }
  process.exit(1);
}

console.log("安全自查通过");
