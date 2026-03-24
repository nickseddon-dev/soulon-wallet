# Task1 验证记录（2026-03-06）

## 执行范围

- SubTask 1.1：对齐 wallet-app 与 SDK 调用模型
- SubTask 1.2：统一后端错误码并建立映射表
- SubTask 1.3：增加契约一致性与错误语义测试

## 执行命令

- `go test ./...`（cwd: `soulon-backend`）
- `npm run check`（cwd: `soulon-wallet`）
- `npm run test:unit`（cwd: `soulon-wallet`）
- `npm run lint`（cwd: `wallet-app`）
- `npm run typecheck`（cwd: `wallet-app`）
- `npm run test`（cwd: `wallet-app`）

## 结果摘要

- `go test ./...` 通过，`internal/api` 新增错误语义测试通过。
- `soulon-wallet` 类型检查与单测通过，新增 `INVALID_ARGUMENT` 映射用例通过。
- `wallet-app` lint、typecheck、vitest 全部通过，新增结构化错误码解析测试通过。
- 工作区诊断结果为 `[]`，无新增 IDE 诊断错误。

## 关键证据路径

- `soulon-backend/internal/api/error_semantics.go`
- `soulon-backend/internal/api/error_semantics_test.go`
- `soulon-backend/internal/api/server.go`
- `soulon-backend/contracts/wallet-api-v1.json`
- `soulon-wallet/src/core/errors.ts`
- `soulon-wallet/tests/transfer-flow.test.mjs`
- `wallet-app/src/api/chainApiContract.ts`
- `wallet-app/src/api/client.ts`
- `wallet-app/src/api/errors.ts`
- `wallet-app/src/api/client.test.ts`
- `.trae/specs/plan-next-phase-wallet-release-readiness/tasks.md`
