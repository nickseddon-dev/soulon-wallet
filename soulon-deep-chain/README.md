# Soulon Deep Chain

## 目标

- 基于 Cosmos SDK 构建 Soulon 主权应用链。
- 采用 CometBFT 共识并支持治理、质押、资产核心能力。

## 当前结构

- `config/chain.config.json`：链基础参数模板。
- `config/genesis.template.json`：创世参数模板。
- `docs/validator_bootstrap.md`：验证人接入流程。
- `deploy/localnet`：本地部署测试参数模板。
- `deploy/testnet`：测试网部署参数模板。
- `scripts/bootstrap-chain.ps1`：链脚手架初始化脚本。
- `scripts/start-localnet.ps1`：本地链启动脚本。
- `scripts/start-testnet.ps1`：测试网启动脚本。
- `scripts/testnet-ops.ps1`：测试网运维脚本（状态/日志/停止）。
- `cmd/soulond/main.go`：链命令入口（创世校验与基础演示命令）。
- `app/app.go`：链应用初始化与创世加载。
- `app/modules.go`：模块装配与初始化执行器。
- `app/tx.go`：统一交易路由执行入口。
- `app/errors.go`：链应用错误码分层（参数校验与执行失败）。
- `app/response.go`：统一交易响应协议（`version`/`code`/`message`/`meta`/`data`/`error`）。
- `x/bank`、`x/staking`、`x/distribution`、`x/gov`：核心模块参数与基础业务逻辑。

## 部署测试

1. 准备 `deploy/localnet/localnet.env`。
2. 按需初始化链脚手架。
3. 执行本地链启动脚本。

```powershell
cd scripts
.\start-localnet.ps1 -ChainBinary soulond -EnvFile ..\deploy\localnet\localnet.env -Reset
```

```powershell
go test ./...
go run .\cmd\soulond validate-genesis -file .\config\genesis.template.json
go run .\cmd\soulond demo -file .\config\genesis.template.json -response-version latest
```

`demo` 命令会按步骤输出标准化交易响应 JSON，包含协议版本与元信息（`meta.tx_type`、`meta.requested_version`、`meta.resolved_version`、`meta.generated_at`），`data` 字段按交易类型裁剪并使用小写下划线命名。当前支持 `latest`、`v1`、`v2`；其中 `v2` 增加 `status`、`data_meta` 以及 v2 元信息字段（`meta.meta_schema`、`meta.request_id`）。`data_meta.schema` 由集中注册表生成，未注册交易类型会回落到 `soulon.tx.data.unknown.v2`，可通过 `RegisterTxDataSchemaV2`/`ResetTxDataSchemaV2Registry` 扩展与重置映射。

## 测试网脚本

1. 准备 `deploy/testnet/testnet.env`。
2. 执行测试网启动脚本。
3. 使用运维脚本进行状态查看、日志查看与停止。

```powershell
cd scripts
.\start-testnet.ps1 -ChainBinary soulond -EnvFile ..\deploy\testnet\testnet.env -Reset
```

```powershell
cd scripts
.\testnet-ops.ps1 -Action status -EnvFile ..\deploy\testnet\testnet.env
.\testnet-ops.ps1 -Action logs -EnvFile ..\deploy\testnet\testnet.env -Tail 200
.\testnet-ops.ps1 -Action stop -EnvFile ..\deploy\testnet\testnet.env
```

## Tasks

- [x] Task 1: 按模块顺序实现 `x/bank`、`x/staking`、`x/distribution`、`x/gov` 的参数与业务逻辑。
- [x] Task 2: 建立测试网启动脚本和节点运维脚本（状态/日志/停止）。
