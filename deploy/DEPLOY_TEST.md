# Soulon 部署测试手册

## 1. 链端测试网部署（D2）

### 1.1 准备

- 复制 `soulon-deep-chain/deploy/testnet/testnet.env.example` 为 `testnet.env`。
- 准备链二进制，例如 `soulond`。

### 1.2 启动

```powershell
cd soulon-deep-chain\scripts
.\start-testnet.ps1 -ChainBinary soulond -EnvFile ..\deploy\testnet\testnet.env -Reset
```

### 1.3 仅脚本校验

```powershell
cd soulon-deep-chain\scripts
.\start-testnet.ps1 -ChainBinary soulond -EnvFile ..\deploy\testnet\testnet.env.example -DryRun
```

### 1.4 运维操作

```powershell
cd soulon-deep-chain\scripts
.\testnet-ops.ps1 -Action status -EnvFile ..\deploy\testnet\testnet.env
.\testnet-ops.ps1 -Action logs -EnvFile ..\deploy\testnet\testnet.env -Tail 120
.\testnet-ops.ps1 -Action stop -EnvFile ..\deploy\testnet\testnet.env
```

## 2. 钱包测试网 E2E（W2）

### 2.1 准备

- 复制 `soulon-wallet/deploy/deploy.env.example` 为 `deploy.env`。
- 根据本地链地址调整 RPC/REST/GRPC 配置。

### 2.2 执行

```powershell
cd soulon-wallet
npm run test:e2e
```

### 2.3 离线流程验证

```powershell
cd soulon-wallet
$env:SOULON_SKIP_NETWORK_TEST="true"
npm run test:e2e
```

## 3. 通过标准

- 链端 `start-testnet.ps1 -DryRun` 输出完整初始化与启动命令链。
- 链端 `testnet-ops.ps1 -Action status` 能输出节点状态信息。
- 钱包 `test:e2e` 可在离线模式完成账户读取、转账与回执确认演练。
- 在线模式可完成真实测试网 E2E 链路验证。

## 4. 一体化执行入口

```powershell
cd deploy
.\run-deploy-test.ps1 -ChainBinary soulond
```

在线连通性模式：

```powershell
cd deploy
.\run-deploy-test.ps1 -ChainBinary soulond -Online
```

追加业务集成测试：

```powershell
cd deploy
.\run-deploy-test.ps1 -ChainBinary soulond -BusinessTest
```

## 5. 钱包业务集成测试（质押/治理，可选）

准备测试数据：

```powershell
cd soulon-wallet\deploy
copy business-test-data.example.json business-test-data.json
```

执行测试：

```powershell
cd soulon-wallet
npm run test:business
```

离线模式（仅交易链路）：

```powershell
cd soulon-wallet
$env:SOULON_SKIP_NETWORK_TEST="1"
npm run test:business
```
