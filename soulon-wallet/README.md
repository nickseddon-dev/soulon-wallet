# Soulon Wallet

## 当前能力

- 网络环境配置（dev/testnet/mainnet）。
- CosmJS 查询客户端与签名客户端封装。
- 助记词创建/导入与首地址读取。
- 原生代币转账服务封装。
- 质押服务封装（委托、撤销委托、复投、奖励领取）。
- 治理服务封装（提案查询、投票提交、投票列表查询）。
- IBC 转账与通道查询服务。
- Authz 授权服务封装（grant/exec/revoke）。
- 交易状态轮询确认与链上错误映射。

## 快速开始

1. 安装依赖。
2. 执行类型检查。
3. 在业务应用中导入 `src/index.ts` 的能力并接入 UI 层。

## 部署测试

1. 检查 `deploy/deploy.env` 配置。
2. 执行部署测试命令：

```bash
npm run deploy:test
```

该命令会自动执行安全自查。

3. 若仅验证流程不连网：

```bash
SOULON_SKIP_NETWORK_TEST=true npm run deploy:test
```

## 业务集成测试

1. 检查 `deploy/business-test-data.json` 测试数据模板。
2. 执行转账、质押与治理业务集成测试：

```bash
npm run test:business
```

3. 若仅执行离线主流程集成测试：

```bash
SOULON_SKIP_NETWORK_TEST=1 npm run test:business
```

## 测试网 E2E 联调

1. 复制并填写测试数据模板：

```bash
cp deploy/e2e-test-data.example.json deploy/e2e-test-data.json
```

2. 执行统一入口命令：

```bash
npm run test:e2e
```

3. 离线结构化演练模式：

```bash
SOULON_SKIP_NETWORK_TEST=1 npm run test:e2e
```

## 发布回归门禁

```bash
npm run gate:e2e-regression
```

## 目录结构

- `src/config/network.ts`：网络与链参数配置。
- `src/core/client.ts`：链客户端工厂。
- `src/core/tx.ts`：交易确认轮询。
- `src/core/errors.ts`：交易错误映射。
- `src/core/wallet.ts`：钱包账户核心接口。
- `src/core/identity.ts`：身份管理与硬件签名接口抽象。
- `src/core/nonce.ts`：Nonce 同步与预留管理。
- `src/core/gas.ts`：Gas 估算与费用计算。
- `src/core/broadcast.ts`：交易重试广播策略。
- `src/services/transfer.ts`：转账服务。
- `src/services/staking.ts`：质押服务。
- `src/services/governance.ts`：治理服务。
- `src/services/ibc.ts`：IBC 服务。
- `src/services/authz.ts`：授权服务。

## 下一步开发

- 增加交易历史分页与失败重试策略。
