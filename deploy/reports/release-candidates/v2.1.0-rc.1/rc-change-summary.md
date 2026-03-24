# Wallet-Release-Readiness RC 变更摘要（v2.1.0-rc.1）

- 生成时间：2026-03-06
- 版本：v2.1.0-rc.1
- 里程碑：Wallet-Release-Readiness

## 变更范围

### 1) 契约与错误语义统一
- wallet-app 与 soulon-wallet 完成调用模型对齐，统一 API 契约路径与错误映射。
- soulon-backend 补齐错误语义映射，前端提示与后端错误码保持一致。
- 新增契约一致性与错误语义相关测试，保证三层行为可回归。

### 2) 主流程联调闭环
- 转账、质押、治理三条流程完成页面接入、链端联调与结果展示。
- 主流程异常分支完成处理策略对齐，链端返回可被前端稳定消费。
- 主流程集成验证通过，形成可复验脚本链路。

### 3) 发布门禁与验收
- 门禁模板升级到 4 模块 7 项校验，纳入 E2E 回归与性能/回滚检查。
- 发布门禁汇总报告生成并归档，`overallStatus: pass`、`failedGates: 0`。
- release-readiness 检查通过，性能基线、告警规则、回滚演练均为 pass。

## 关键产物

- 门禁汇总：`deploy/reports/p2-acceptance/archive/v2.1.0/20260306-194523/v2-acceptance-summary.md`
- 门禁明细：`deploy/reports/p2-acceptance/archive/v2.1.0/20260306-194523/v2-acceptance-summary.json`
- 门禁日志目录：`deploy/reports/p2-acceptance/archive/v2.1.0/20260306-194523/logs/`
- 发布就绪检查：`soulon-backend/reports/release-readiness/release-readiness-check-20260306-194525.md`
- RC 包清单：`deploy/reports/release-candidates/v2.1.0-rc.1/manifest.json`
- RC 包文件：`deploy/reports/release-candidates/v2.1.0-rc.1/wallet-release-readiness-v2.1.0-rc.1.zip`
