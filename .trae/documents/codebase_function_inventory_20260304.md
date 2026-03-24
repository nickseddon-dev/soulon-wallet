# Soulon 代码库功能清单（权威基线）

更新日期：2026-03-04  
适用范围：`soulon-backend`、`wallet-app`、`soulon-wallet`、`soulon-deep-chain`、顶层 `deploy`

## 1. 审查方法与证据来源
- 代码结构与实现：逐模块读取源码入口、内部实现与脚本。
- 测试与门禁：执行 `go test ./...`、`wallet-app npm run validate`、`soulon-wallet npm run check/build`，并核对现有报告。
- 规格与任务：核对 `.trae/specs/*` 的 `tasks.md`、`checklist.md`、`verification*.md`。
- 注释与待办：检索 `TODO/FIXME/下一步`。
- 提交记录：当前工作区无 `.git` 元数据，无法基于真实 commit 历史生成演进图谱。

实现程度说明：
- 已完成：可运行、可验证，且有测试/门禁或报告支撑。
- 部分完成：核心能力存在，但存在明显缺口或仅脚本层实现。
- 未完成：代码/模块未落地，仅文档计划或占位。

---

## 2. 功能清单（按系统分组）

### 2.1 soulon-backend

| 功能名称 | 关键文件路径 | 实现程度 | 依赖关系 | 状态说明 |
|---|---|---|---|---|
| Gateway 节点网关与转发 | `cmd/gateway/main.go`；`internal/gateway/server.go`；`internal/gateway/router.go` | 已完成 | 依赖链节点 RPC；依赖配置加载 | 支持健康检查、节点轮询、RPC 转发与节点状态查询 |
| Indexer 工作流（生产/消费/持久化） | `cmd/indexer/main.go`；`internal/indexer/worker.go` | 已完成 | 依赖 Queue + Store 抽象；可选 Kafka/Postgres | 支持事件生成、消费、重试、DLQ、维护与指标 |
| Queue 后端：内存队列 | `internal/indexer/queue.go` | 部分完成 | 被 Worker 调用 | 可用于本地；DLQ/分区暂停为占位实现 |
| Queue 后端：Kafka | `internal/indexer/kafka_queue.go` | 已完成（有缺口） | 依赖 `kafka-go` 与 Kafka 集群 | 主能力完整；`Backlog()` 当前固定返回 0 |
| Store 后端：文件存储 | `internal/indexer/store.go` | 已完成 | 被 API/Indexer 复用 | 支持追加、过滤、回滚、状态重建 |
| Store 后端：PostgreSQL | `internal/indexer/postgres_store.go` | 已完成 | 依赖 `pgx/v5` 与 PostgreSQL | 支持 schema、upsert、状态、归档清理、指标 |
| API 查询服务 | `cmd/api/main.go`；`internal/api/server.go` | 已完成 | 依赖 indexer 类型与文件事件库 | 提供健康、事件查询、状态查询接口 |
| API 契约冻结 | `contracts/wallet-api-v1.json`；`internal/api/contract_freeze_test.go` | 已完成 | 依赖测试门禁 | 契约 v1 冻结并有一致性校验 |
| 集成验证（Kafka+Postgres） | `scripts/run-integration.ps1`；`docker-compose.integration.yml`；`internal/indexer/integration_e2e_test.go` | 已完成 | 依赖 Docker、Kafka、Postgres、Go 测试 | 可一键起环境并跑 E2E |
| 混沌/演练/告警生成 | `scripts/run-chaos-report.ps1`；`scripts/run-staging-drill.ps1`；`deploy/monitoring/generated/chaos-alert-rules.yaml` | 已完成 | 依赖集成脚本与报告目录 | 报告产物齐全，形成演练闭环 |

### 2.2 wallet-app（前端 UI）

| 功能名称 | 关键文件路径 | 实现程度 | 依赖关系 | 状态说明 |
|---|---|---|---|---|
| 应用路由与鉴权守卫 | `src/router.tsx`；`src/auth/RequireAuth.tsx`；`src/auth/AuthContext.tsx` | 已完成 | 依赖 React Router 与 localStorage 会话 | 登录页公开，业务页受保护，支持失效跳转 |
| 登录签名授权流程（两步） | `src/pages/LoginPage.tsx`；`src/api/walletApi.ts` | 已完成（占位回退） | 依赖后端授权接口；网络失败有占位策略 | 可演示发起挑战与确认签名；后端未就绪时可回退 |
| 首页概览与健康检查 | `src/pages/HomePage.tsx` | 已完成 | 依赖 `/v1/health` | 展示环境与快捷入口，可触发健康检查 |
| 链状态页 | `src/pages/StatePage.tsx` | 已完成 | 依赖 `/v1/indexer/state` | 卡片化展示 tip/总量/reorg |
| 事件列表（分页/筛选/重试观测） | `src/pages/EventsPage.tsx`；`src/api/client.ts` | 已完成 | 依赖 `/v1/indexer/events` 与请求生命周期事件 | 支持 limit/order/type/height 区间、分页、错误归因 |
| 事件详情页 | `src/pages/EventDetailPage.tsx` | 已完成 | 依赖路由 state 与按 id 回源查询 | 支持路由态直出与刷新场景按 id 回源 |
| 交易所风格 UI 体系 | `src/index.css`；`src/App.tsx` | 已完成 | 依赖页面 class 约定 | 深色风格、信息分层、窄屏适配已完成 |
| 前端质量门禁 | `package.json`（`validate`） | 已完成 | 依赖 ESLint、TypeScript、Vite | `lint + typecheck + build` 已可通过 |
| 前端自动化测试 | `src/**/*.test.tsx`；`vitest.config.ts` | 已完成 | 依赖 Vitest 与 Testing Library | 已具备鉴权守卫与事件详情回源测试 |

### 2.3 soulon-wallet（TS SDK）

| 功能名称 | 关键文件路径 | 实现程度 | 依赖关系 | 状态说明 |
|---|---|---|---|---|
| SDK 导出与模块组织 | `src/index.ts` | 已完成 | 依赖 core/services/config | 对外统一导出 |
| 链客户端工厂 | `src/core/client.ts` | 已完成 | 依赖 CosmJS | Query/Signing 客户端创建 |
| 钱包与地址能力 | `src/core/wallet.ts` | 已完成 | 依赖 `@cosmjs/proto-signing` | 助记词导入、路径派生、地址读取 |
| 交易广播重试与确认轮询 | `src/core/broadcast.ts`；`src/core/tx.ts` | 已完成 | 依赖 Signing Client | 支持重试和交易结果确认 |
| 错误映射 | `src/core/errors.ts` | 已完成 | 依赖广播/服务层 | 统一错误码映射 |
| Nonce/Gas 辅助能力 | `src/core/nonce.ts`；`src/core/gas.ts` | 已完成 | 依赖链查询客户端 | 提供 nonce 与 gas 计算能力 |
| 身份与签名器抽象 | `src/core/identity.ts` | 部分完成 | 依赖外部签名实现 | 平台/硬件签名器为占位，调用会抛错 |
| 转账/质押/治理服务 | `src/services/transfer.ts`；`src/services/staking.ts`；`src/services/governance.ts` | 已完成 | 依赖 CosmJS 与 REST | 基础业务服务可用 |
| 部署/业务/E2E 脚本 | `scripts/*.mjs`；`package.json` | 已完成 | 依赖 `deploy.env` 与测试数据 | 支持 check/build/smoke/business/e2e（在线/离线） |
| 单元测试体系 | 无专门测试框架 | 未完成 | - | 以脚本化验证为主，缺少单测覆盖 |

### 2.4 soulon-deep-chain（链工程）

| 功能名称 | 关键文件路径 | 实现程度 | 依赖关系 | 状态说明 |
|---|---|---|---|---|
| 链配置模板 | `config/chain.config.json`；`config/genesis.template.json` | 已完成 | 被脚本与文档引用 | 提供参数基线 |
| 本地/测试网启动脚本 | `scripts/start-localnet.ps1`；`scripts/start-testnet.ps1` | 已完成 | 依赖 `soulond` 二进制 | 支持 init/gentx/start 与 DryRun |
| 测试网运维脚本 | `scripts/testnet-ops.ps1` | 已完成 | 依赖 PID/日志路径 | 支持 status/logs/stop |
| 链脚手架初始化 | `scripts/bootstrap-chain.ps1` | 已完成 | 依赖 `ignite` | 可初始化链工程骨架 |
| Cosmos 业务模块实现（x/bank 等） | `x/bank`；`x/staking`；`x/distribution`；`x/gov` | 已完成 | 依赖链应用装配与交易路由 | 模块代码、应用装配与测试已落地 |

### 2.5 顶层 deploy 与跨项目编排

| 功能名称 | 关键文件路径 | 实现程度 | 依赖关系 | 状态说明 |
|---|---|---|---|---|
| W2+D2 一体化部署验证入口 | `deploy/run-deploy-test.ps1` | 已完成 | 依赖 deep-chain 脚本 + wallet 脚本 | 支持离线/在线模式，串联核心检查 |
| 部署测试手册 | `deploy/README.md`；`deploy/DEPLOY_TEST.md` | 已完成 | 依赖子项目脚本能力 | 文档与流程基本对齐 |

---

## 3. 接口清单（当前主用）

### 3.1 后端 HTTP 接口
- Gateway：
  - `GET /healthz`
  - `GET /v1/nodes`
  - `POST /v1/rpc`
- API：
  - `GET /v1/health`
  - `GET /v1/indexer/events?limit&offset&order&type&minHeight&maxHeight`
  - `GET /v1/indexer/state`

### 3.2 前端/钱包调用链
- `wallet-app` -> `walletApi.ts` -> `api/client.ts` -> 上述 API。
- `wallet-app` 额外约定授权接口：
  - `POST /v1/auth/signature/challenge`
  - `POST /v1/auth/signature/confirm`
  - 当前可占位回退，真实后端能力待持续对齐。

---

## 4. 测试与验证状态

已验证（本次审查执行）：
- `soulon-backend`: `go test ./...` 通过。
- `wallet-app`: `npm run validate` 通过（lint/typecheck/build）。
- `soulon-wallet`: `npm run check` 与 `npm run build` 通过。

已存在的测试资产：
- backend：API 单测、Indexer 单测、Kafka/Postgres 集成 E2E、契约冻结测试、演练报告。
- wallet-app：已包含自动化测试用例（鉴权守卫、详情回源）与构建门禁。
- soulon-wallet：脚本化业务/部署/E2E 验证，缺少单元测试框架。
- soulon-deep-chain：具备链模块与应用层测试，脚本 DryRun/运维流程可用。

---

## 5. 依赖关系总图（摘要）

- `wallet-app` 运行依赖 `soulon-backend` API 契约与可用性。
- `soulon-wallet` 依赖 `soulon-deep-chain` 的链参数与可访问节点（RPC/REST/GRPC）。
- `soulon-backend` Indexer 依赖 Kafka/Postgres（可选）与链节点数据来源。
- 顶层 `deploy` 通过脚本串联 `soulon-deep-chain + soulon-wallet`，形成部署联调入口。

---

## 6. 关键缺口与后续开发建议

### P0（必须优先）
- 已完成：`soulon-deep-chain` 链业务模块（x/bank、x/staking、x/distribution、x/gov）代码落地与测试。
- 已完成：`wallet-app` 自动化测试基线（鉴权守卫、事件详情回源）。
- 已完成：`EventDetailPage` 刷新丢失修复（按 `eventId` 回源查询）。

### P1（稳定性/一致性）
- Indexer Kafka `Backlog()` 改为真实消费滞后计算，避免指标失真。
- 明确 API 数据源策略：统一文件/DB 双源或切换到单一权威源，避免配置不一致。
- 完善 Gateway/API 优雅停机流程，与 Indexer 行为一致。

### P2（工程治理）
- 统一各子项目测试命令协议（例如均提供 `validate`、`test`、`e2e`）。
- 建立跨仓“最新报告索引”文件，降低排障检索成本。
- 将本清单纳入迭代门禁：功能变更必须同步更新本文件对应项。

---

## 7. 权威维护规则（建议）

为使本清单成为“唯一权威依据”，建议执行：
1. 每次合并前必须更新本清单受影响条目（功能、路径、状态、依赖、建议）。
2. CI 增加文档一致性检查：若改动核心目录但未更新清单则阻断。
3. 每轮演练后同步更新“测试与验证状态”章节。
