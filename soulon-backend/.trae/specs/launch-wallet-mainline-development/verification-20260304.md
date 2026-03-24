# Checklist 核验记录（2026-03-04）

## 1) 钱包主线工程可本地启动，基础页面与路由可访问
- 验证命令：
  - `npm run dev -- --host 127.0.0.1 --port 5173`
  - `Invoke-WebRequest http://127.0.0.1:5173/`
  - `Invoke-WebRequest http://127.0.0.1:5173/state`
  - `Invoke-WebRequest http://127.0.0.1:5173/events`
- 结果：
  - `FRONTEND http://127.0.0.1:5173/ => 200`
  - `FRONTEND http://127.0.0.1:5173/state => 200`
  - `FRONTEND http://127.0.0.1:5173/events => 200`

## 2) 网络访问层已统一封装，并具备超时与错误模型
- 证据：
  - `wallet-app/src/api/client.ts` 统一请求入口 `ApiClient.request`，含 `timeoutMs`、重试与错误分类（`TIMEOUT`/`NETWORK`/`HTTP_ERROR`/`PARSE_ERROR`）。
  - `wallet-app/src/api/errors.ts` 定义标准错误模型 `ApiClientError` 与会话失效判断 `isSessionInvalidError`。

## 3) 钱包已成功对接冻结 API 契约并通过契约一致性校验
- 验证命令：
  - `go test ./internal/api -run TestWalletAPIContractFrozen -v`
- 结果：
  - `=== RUN   TestWalletAPIContractFrozen`
  - `--- PASS: TestWalletAPIContractFrozen (0.00s)`
  - `PASS`
- 证据：
  - `contracts/wallet-api-v1.json` 已冻结 `v1.0.0` 契约。
  - `internal/api/contract_freeze_test.go` 校验版本、冻结状态与端点集合。

## 4) 资产与交易查询页面在联调环境可稳定展示结果
- 验证命令：
  - `go run ./cmd/api`
  - `Invoke-RestMethod http://127.0.0.1:8082/v1/indexer/state`
  - `Invoke-RestMethod http://127.0.0.1:8082/v1/indexer/events?limit=2&offset=0`
- 结果：
  - `API /v1/indexer/state => tipHeight=0; tipHash=; total=0; reorgs=0`
  - `API /v1/indexer/events => total=0; returned=0; hasMore=`
- 证据：
  - `wallet-app/src/pages/StatePage.tsx` 与 `wallet-app/src/pages/EventsPage.tsx` 均已接入对应接口并处理加载/错误/空态。

## 5) 鉴权壳与会话失效处理流程可验证
- 证据：
  - `wallet-app/src/auth/RequireAuth.tsx` 未登录自动跳转 `/login`。
  - `wallet-app/src/auth/AuthContext.tsx` 提供会话存储、过期清理与失效原因。
  - `wallet-app/src/pages/HomePage.tsx`、`StatePage.tsx`、`EventsPage.tsx` 在 401/403 时统一执行 `signOut('会话已失效，请重新登录。')`。

## 6) 钱包-后端联调清单已完成并记录阻塞项处理结果
- 证据：
  - `.trae/specs/launch-wallet-mainline-development/task5-audit-20260304.md` 记录联调过程、门禁结果与阻塞项处理。
  - `wallet-app/.env.example` 与 `wallet-app/src/config/env.ts` 默认 API 地址已对齐 `http://127.0.0.1:8082`。
  - `internal/config/config.go` 默认 `API_LISTEN_ADDR` 为 `:8082`。

## 7) 测试、构建与基础质量门禁通过，可进入下一迭代
- 验证命令：
  - `npm run validate`（wallet-app）
  - `go test ./...`（soulon-backend）
  - 工作区诊断检查
- 结果：
  - `npm run validate` 成功执行 lint、typecheck、build（exit code 0）。
  - `go test ./...` 全量通过（exit code 0）。
  - 诊断结果 `[]`（0 条）。

## 8) Task 5 复验补充（2026-03-04）
- 联调命令：
  - `.\scripts\run-integration.ps1`（soulon-backend）
  - `go run ./cmd/api`（soulon-backend）
  - `Invoke-WebRequest http://127.0.0.1:8082/v1/health`
  - `Invoke-RestMethod http://127.0.0.1:8082/v1/indexer/state`
  - `Invoke-RestMethod http://127.0.0.1:8082/v1/indexer/events?limit=2&offset=0`
- 前端校验命令：
  - `npm run dev -- --host 127.0.0.1 --port 5173`
  - `Invoke-WebRequest http://127.0.0.1:5173/`
  - `Invoke-WebRequest http://127.0.0.1:5173/state`
  - `Invoke-WebRequest http://127.0.0.1:5173/events`
  - `Invoke-WebRequest http://127.0.0.1:5173/login`
- 复验结果：
  - `run-integration.ps1` 通过，`TestKafkaAndPostgresIntegration` 为 `PASS`。
  - `API /v1/health => 200 {"status":"ok"}`。
  - `API /v1/indexer/state => tipHeight=0; tipHash=; total=0; reorgs=0`。
  - `API /v1/indexer/events => total=0; returned=0; hasMore=`。
  - 前端 `/, /state, /events, /login` 路由全部返回 `200`。
