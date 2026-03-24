# Soulon Backend

## 组件

- `cmd/gateway`：节点访问网关服务。
- `cmd/indexer`：索引器进程入口。
- `cmd/api`：对钱包端提供查询 API 的服务入口。

## 当前能力

- Gateway 支持多节点配置、健康检查、轮询路由与 JSON-RPC 转发。
- Indexer 支持 memory/kafka 两种队列后端、file/postgres 两种存储后端、幂等持久化与轻量重组回滚处理。
- API 支持健康检查、索引事件查询与链状态查询接口。

## 完整开发流程（五阶段）

| 阶段 | 目标边界 | 输入 | 输出 | 责任角色 | 准入条件 | 退出条件 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1. 需求澄清 | 明确业务目标与影响范围，不进入实现 | 需求背景、约束、风险 | 需求结论、范围边界、验收目标 | 需求方 + 开发负责人 | 需求来源明确 | 目标、范围、验收口径达成一致 |
| 2. 规格产出 | 形成可执行规格，不进入编码 | 需求结论 | `.trae/specs/<name>/spec.md`、`tasks.md`、`checklist.md` | 开发负责人 | 阶段 1 输出齐全 | 规格、任务、清单三者一致且可验证 |
| 3. 任务执行 | 仅完成实现与状态推进，不做交付放行 | `tasks.md` 已拆解任务 | 代码变更、任务勾选、执行证据 | 开发执行者 | 任务存在依赖定义 | 任务完成且证据可追溯 |
| 4. 系统验证 | 统一完成质量门禁，不进入发布 | 代码变更与任务证据 | 构建/测试/联调结果、清单勾选记录 | 开发执行者 + 评审者 | 任务完成并可运行 | 门禁全部通过且无阻塞缺口 |
| 5. 交付归档 | 形成审计与复盘闭环 | 门禁结果、阻塞处理信息 | 审计记录、遗留风险、下一轮行动项 | 开发负责人 | 阶段 4 全部通过 | 归档完成并可供下一轮输入 |

阶段切换规则：任一阶段输出不完整或关键验证失败时，流程停留当前阶段，补齐缺口后再推进。

## 任务执行机制

- 任务来源：仅从对应规格 `spec.md` 拆解，任务与需求条目一一映射。
- 任务粒度：单项任务必须可独立验收，完成时必须附可复现证据（命令输出、报告文件、结果截图或日志）。
- 依赖约束：先完成依赖任务再推进后置任务；允许并行的任务需不存在输入输出冲突。
- 状态流转：`未开始 -> 进行中 -> 已完成`，状态变化必须同步更新 `tasks.md` 勾选项。
- 勾选规则：仅在代码与验证证据都完成后勾选；部分完成不得提前勾选。

## 质量门禁（统一准入）

- 构建与基础测试：`go test ./...`
- 集成联调：`./scripts/run-integration.ps1`
- 稳定性与演练：`./scripts/run-staging-drill.ps1 -Iterations 2 -TrendWindow 5`
- 清单核验：对应规格目录下 `checklist.md` 全部勾选完成
- 失败处理策略：任一门禁失败立即停止交付，修复后全量重跑失败项及其受影响项
- 交付准入标准：所有门禁通过、任务与清单勾选完整、审计记录可追溯

## 交付审计与复盘机制

- 审计记录路径：每轮交付在对应规格目录新增 `task5-audit-YYYYMMDD.md`。
- 审计内容模板：必须包含“执行范围与时间、验证结果、阻塞处理、遗留风险、后续行动项”。
- 复盘输出要求：必须给出“本轮有效实践、待改进点、自动化补强点”三类结论。
- 下一轮输入约束：复盘行动项必须映射到下一轮 `spec.md` 与 `tasks.md` 的新增或修改条目。
- 失败收敛策略：任一门禁失败时，当前规格 `tasks.md` 必须新增修复任务并在复跑通过后再勾选完成。

## 本地运行

```powershell
go run ./cmd/gateway
go run ./cmd/indexer
go run ./cmd/api
```

- `cmd/gateway` 与 `cmd/api` 支持 `SIGINT/SIGTERM` 优雅停机，按 `Ctrl+C` 可触发有序关闭。

## 环境变量

- 复制 `.env.example` 并按需调整。
- Gateway
  - `GATEWAY_LISTEN_ADDR`
  - `GATEWAY_NODE_ENDPOINTS`
  - `GATEWAY_HEALTH_CHECK_MS`
  - `GATEWAY_FORWARD_TIMEOUT_MS`
- Indexer
  - `INDEXER_POLL_INTERVAL_MS`
  - `INDEXER_REORG_INTERVAL`
  - `INDEXER_QUEUE_BACKEND`（`memory` 或 `kafka`）
  - `INDEXER_KAFKA_BROKERS`
  - `INDEXER_KAFKA_TOPIC`
  - `INDEXER_KAFKA_DLQ_TOPIC`
  - `INDEXER_KAFKA_GROUP_ID`
  - `INDEXER_KAFKA_KEY_STRATEGY`（`id`、`height`、`type`）
  - `INDEXER_KAFKA_WRITE_TIMEOUT_MS`
  - `INDEXER_KAFKA_WRITE_RETRIES`
  - `INDEXER_STORE_BACKEND`（`file` 或 `postgres`）
  - `INDEXER_POSTGRES_DSN`
  - `INDEXER_POSTGRES_RETENTION_BLOCKS`
  - `INDEXER_QUEUE_BUFFER`
  - `INDEXER_EVENT_STORE_PATH`
  - `INDEXER_PERSIST_MAX_RETRIES`
  - `INDEXER_PERSIST_RETRY_BACKOFF_MS`
  - `INDEXER_PERSIST_FAILURE_POLICY`（`stop` 或 `skip`）
  - `INDEXER_CONSUME_PAUSE_MS`
  - `INDEXER_MAINTENANCE_INTERVAL_MS`
  - `INDEXER_METRICS_LISTEN_ADDR`
  - `INDEXER_NOTIFY_WEBHOOK_URL`
  - `INDEXER_NOTIFY_TIMEOUT_MS`
  - `INDEXER_NOTIFY_RETRIES`
  - `INDEXER_NOTIFY_AUTH_TOKEN`
- API
  - `API_LISTEN_ADDR`
  - `API_STORE_BACKEND`（`auto`、`file`、`postgres`）
  - `API_POSTGRES_DSN`（当 `API_STORE_BACKEND=postgres` 或 `auto` 且文件不存在时生效）
  - `API_NOTIFY_WEBHOOK_TOKEN`（校验 `/v1/notifications/webhook` 的 Bearer Token）
  - `API_NOTIFICATION_CAPACITY`（内存通知缓冲数量上限）

## 接口

- `GET /healthz`：Gateway 健康检查。
- `GET /v1/nodes`：Gateway 节点健康状态与列表。
- `POST /v1/rpc`：Gateway JSON-RPC 转发入口。
- `GET /v1/health`：API 健康检查。
- `GET /v1/indexer/events?limit=20&offset=0&order=desc&type=new_block&minHeight=100&maxHeight=200`：支持分页、顺序、类型与高度区间过滤，响应包含 `hasMore`。
- `GET /v1/indexer/state`：查询当前索引 tipHeight/tipHash 与 reorg 次数。
- `POST /v1/notifications/webhook`：接收 Indexer 推送通知（支持 Bearer 校验）。
- `GET /v1/notifications?limit=20&offset=0`：分页查询通知消息（按接收时间倒序）。
- `GET /v1/notifications/stream`：SSE 实时订阅通知流（支持 `initialLimit` 回放最近消息；开启令牌时支持 `token` 查询参数）。

## 可观测性

- Indexer 日志分级输出：
  - `[INFO]` 持久化成功与周期指标
  - `[WARN]` 重复事件跳过
  - `[ERROR]` 发布或持久化失败
- 周期指标包含：`produced`、`consumed`、`backlog`、`tipHeight`、`reorgs`、`lastLatencyMs`、`errors`。
- Prometheus 指标出口：配置 `INDEXER_METRICS_LISTEN_ADDR` 后通过 `GET /metrics` 采集。
- 分区暂停指标：`indexer_worker_paused_partitions_total`。
- PostgreSQL 指标：`indexer_postgres_upsert_seconds`、`indexer_postgres_maintenance_seconds`、`indexer_postgres_archived_rows_total`、`indexer_postgres_deleted_rows_total`、`indexer_postgres_maintenance_errors_total`。

## 告警建议

- `indexer_worker_error_total` 在 5 分钟内持续增长。
- `indexer_worker_backlog` 连续 10 分钟高于 1000。
- `indexer_worker_last_latency_ms` 连续 5 分钟高于 5000。

## 集成验证

```powershell
docker compose -f docker-compose.integration.yml up -d
$env:RUN_E2E="1"
go test ./internal/indexer -run TestKafkaAndPostgresIntegration -v
docker compose -f docker-compose.integration.yml down -v
```

```powershell
./scripts/run-integration.ps1
```

```powershell
./scripts/run-chaos-report.ps1 -Iterations 2 -TrendWindow 5
```

```powershell
./scripts/publish-alert-rules.ps1
```

```powershell
./scripts/run-rollback-drill.ps1
```

```powershell
./scripts/run-staging-drill.ps1 -Iterations 2 -TrendWindow 5
```

```powershell
./scripts/check-release-readiness.ps1
```

报告会输出到 `reports/chaos/`，包含场景聚合统计、历史趋势对比、告警规则建议与恢复策略建议。

同时会生成以下机器可读文件：

- `chaos-report-*.json`：主报告（阈值建议、场景风险、趋势、明细）。
- `chaos-alert-rules-*.json`：告警规则建议（全局规则 + 场景规则）。
- `chaos-recovery-playbook-*.json`：按场景恢复策略模板（前置检查、执行动作、验收检查）。
- `deploy/monitoring/generated/chaos-alert-rules.yaml`：Prometheus 风格告警规则建议文件。

示例结构：

```json
{
  "generatedAt": "2026-01-01T00:00:00.0000000+00:00",
  "iterations": 2,
  "total": 8,
  "pass": 8,
  "fail": 0,
  "averageDurationMs": 5123,
  "trendWindow": 5,
  "thresholdSuggestions": {
    "sampleSize": 5,
    "errorRate": {
      "latestPct": 0,
      "p90Pct": 10,
      "averagePct": 4,
      "recommendedPct": 15
    },
    "duration": {
      "latestMs": 5123,
      "p90Ms": 7300,
      "averageMs": 6012,
      "recommendedMs": 8760
    },
    "consecutiveFailures": {
      "latestStreak": 0,
      "maxObservedStreak": 1,
      "recommendedCount": 2
    }
  },
  "scenarioSummary": [],
  "historyTrend": [],
  "results": []
}
```

阈值建议解读：

- `thresholdSuggestions.errorRate.recommendedPct`：建议告警错误率阈值（百分比）。计算逻辑是历史 `p90 + 5`，并限制在 `5~60` 区间。
- `thresholdSuggestions.duration.recommendedMs`：建议平均耗时阈值（毫秒）。计算逻辑是历史耗时 `p90 * 1.2`，并限制在 `2000~60000` 区间。
- `thresholdSuggestions.consecutiveFailures.recommendedCount`：建议连续失败次数阈值。基于历史最大连续失败次数加 1，并限制在 `2~6` 区间。
- 当历史样本不足时，脚本会回退到保守默认值：错误率 `20%`、平均耗时 `8000ms`、连续失败 `2` 次。
- 建议将上述 recommended 字段直接映射到告警规则，并结合 `scenarioSummary.riskLevel` 优先处理 `high` 风险场景。

恢复策略落地建议：

- 对 `scenarioSummary.riskLevel = high` 的场景优先执行 `chaos-recovery-playbook-*.json` 中对应条目。
- 执行顺序建议为：`preChecks -> actions -> postChecks`，执行后再观察阈值是否回落。
- CI 会校验阈值范围与规则关键字段完整性，并在存在高风险场景时给出 warning。

上线前检查清单：

- 完成一次 staging 端到端演练（含故障注入与恢复）：执行 `run-staging-drill.ps1` 并产出 `reports/staging/staging-drill-*.md`。
- 告警规则建议落地并验证：执行 `publish-alert-rules.ps1`，确认生成 `deploy/monitoring/generated/chaos-alert-rules.yaml`。
- 发布回滚流程演练至少 1 次：执行 `run-rollback-drill.ps1` 并检查 `rollbackSuccess: true`。
- 钱包侧 API 契约冻结：以 `contracts/wallet-api-v1.json` 作为冻结基线，变更需显式升级版本并通过测试。

## 下一步

- 将 `chaos-alert-rules-*.json` 与 `chaos-alert-rules.yaml` 的建议规则接入正式告警系统。
