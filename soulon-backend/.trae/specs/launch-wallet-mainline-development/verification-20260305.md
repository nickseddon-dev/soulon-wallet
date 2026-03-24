# Checklist 核验记录（2026-03-05）

## 1) 钱包主线工程可本地启动，基础页面与路由可访问
- 验证命令:
  - `npm run validate`（wallet-app）
- 结果:
  - lint、typecheck、build 全部通过，产物构建成功。
- 勾选结论:
  - [x] 通过

## 2) 网络访问层已统一封装，并具备超时与错误模型
- 核验证据:
  - `wallet-app/src/api/client.ts` 提供统一请求入口、超时与错误分类。
  - `wallet-app/src/api/errors.ts` 提供标准错误模型与会话失效识别。
- 勾选结论:
  - [x] 通过

## 3) 钱包已成功对接冻结 API 契约并通过契约一致性校验
- 验证命令:
  - `go test ./internal/api -run TestWalletAPIContractFrozen -v`
  - `go test ./internal/api -run TestWalletAPIContractRouteConsistency -v`
- 结果:
  - 两项测试均 PASS，冻结契约与可路由能力一致。
- 核验证据:
  - `contracts/wallet-api-v1.json` 当前版本 `v1.4.0`，`frozen=true`。
- 勾选结论:
  - [x] 通过

## 4) 资产与交易查询页面在联调环境可稳定展示结果
- 验证命令:
  - `powershell -ExecutionPolicy Bypass -File .\scripts\run-integration.ps1`（soulon-backend）
- 结果:
  - `TestKafkaAndPostgresIntegration` PASS。
- 勾选结论:
  - [x] 通过

## 5) 鉴权壳与会话失效处理流程可验证
- 核验证据:
  - `wallet-app/src/auth/RequireAuth.tsx`、`wallet-app/src/auth/AuthContext.tsx`、`wallet-app/src/pages/HomePage.tsx`、`wallet-app/src/pages/StatePage.tsx`、`wallet-app/src/pages/EventsPage.tsx` 已实现登录守卫与会话失效统一处理。
- 勾选结论:
  - [x] 通过

## 6) 钱包-后端联调清单已完成并记录阻塞项处理结果
- 核验证据:
  - `.trae/specs/launch-wallet-mainline-development/task5-audit-20260305.md` 已归档本轮联调与门禁结果。
- 勾选结论:
  - [x] 通过

## 7) 测试、构建与基础质量门禁通过，可进入下一迭代
- 验证命令:
  - `npm run validate`（wallet-app）
  - `go test ./...`（soulon-backend）
  - `powershell -ExecutionPolicy Bypass -File .\scripts\run-staging-drill.ps1 -Iterations 2 -TrendWindow 5`（soulon-backend）
  - 工作区诊断检查
- 结果:
  - 全部命令 exit code 0。
  - `reports/staging/staging-drill-20260305-212033.md` 显示 pass=4, fail=0。
  - 诊断结果 `[]`（0 条）。
- 勾选结论:
  - [x] 通过
