# Task3 验证记录（2026-03-06）

## 执行范围

- SubTask 3.1：增加 E2E 与回归门禁命令
- SubTask 3.2：增加性能基线与回滚演练检查
- SubTask 3.3：产出门禁汇总报告与失败明细

## 代码变更

- `soulon-wallet/scripts/gate-e2e-regression.ps1`：新增钱包 E2E+回归统一门禁脚本，离线串行执行 `test:e2e` 与 `test:business`。
- `soulon-wallet/package.json`：新增 `gate:e2e-regression` 门禁命令。
- `soulon-backend/scripts/check-release-readiness.ps1`：新增性能基线与回滚演练检查脚本，校验 chaos 验证与 rollback 成功状态并产出检查报告。
- `deploy/v2-acceptance-template.json`：新增 `perf_baseline_rollback` 与 `e2e_regression` 门禁项。
- `deploy/README.md`、`soulon-wallet/README.md`、`soulon-backend/README.md`：补充门禁脚本入口说明。
- `.trae/specs/plan-next-phase-wallet-release-readiness/tasks.md`：Task3 及三子项勾选完成。
- `.trae/specs/plan-next-phase-wallet-release-readiness/checklist.md`：门禁相关三项检查勾选完成。

## 执行命令

- `npm run gate:e2e-regression`（cwd: `soulon-wallet`）
- `powershell -ExecutionPolicy Bypass -File .\scripts\check-release-readiness.ps1`（cwd: `soulon-backend`）
- `powershell -NoProfile -ExecutionPolicy Bypass -File D:\soulon_wallet\deploy\run-p2-gate.ps1 -Version v2.1.0 -Milestone Wallet-Release-Readiness`（cwd: `D:\soulon_wallet`）

## 结果摘要

- `gate:e2e-regression` 通过，输出“离线模式通过”“转账链路集成测试通过”“质押与治理链路集成测试通过”。
- `check-release-readiness.ps1` 通过，生成 `release-readiness-check-20260306-194525.md`，结果包含 `metricValidation: pass`、`alertRuleValidation: pass`、`rollbackDrill: pass`。
- `run-p2-gate.ps1` 通过，生成 `v2.1.0` 门禁汇总；`totalGates: 7`、`failedGates: 0`，并保留失败明细段落（本次为 `none`）。

## 关键证据路径

- `deploy/reports/p2-acceptance/archive/v2.1.0/20260306-194523/v2-acceptance-summary.md`
- `deploy/reports/p2-acceptance/archive/v2.1.0/20260306-194523/v2-acceptance-summary.json`
- `soulon-backend/reports/release-readiness/release-readiness-check-20260306-194525.md`
- `soulon-wallet/scripts/gate-e2e-regression.ps1`
- `soulon-backend/scripts/check-release-readiness.ps1`
- `deploy/v2-acceptance-template.json`
- `.trae/specs/plan-next-phase-wallet-release-readiness/tasks.md`
- `.trae/specs/plan-next-phase-wallet-release-readiness/checklist.md`
