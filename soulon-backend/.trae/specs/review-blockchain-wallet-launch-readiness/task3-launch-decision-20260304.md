# Task 3 门禁复验与上线判定记录（2026-03-04）

- 执行时间：2026-03-04
- 规格范围：`review-blockchain-wallet-launch-readiness`
- 对应任务：Task 3（SubTask 3.1、SubTask 3.2）

## 1) 当前质量门禁复验

### A. 钱包前端质量门禁
- 命令：`npm run validate`（`wallet-app`）
- 结果：通过（exit code 0）
- 关键输出：已完成 lint、typecheck、build，Vite 构建成功并产出 `dist/`

### B. 后端基础测试门禁
- 命令：`go test ./...`（`soulon-backend`）
- 结果：通过（exit code 0）
- 关键输出：`internal/api`、`internal/indexer` 测试通过

### C. 后端集成联调门禁
- 命令：`powershell -ExecutionPolicy Bypass -File ./scripts/run-integration.ps1`
- 结果：通过（exit code 0）
- 关键输出：`TestKafkaAndPostgresIntegration` PASS，容器编排启动与回收正常

### D. 稳定性与演练门禁
- 命令：`powershell -ExecutionPolicy Bypass -File ./scripts/run-staging-drill.ps1 -Iterations 2 -TrendWindow 5`
- 结果：通过（exit code 0）
- 关键输出：
  - 生成 `reports/staging/staging-drill-20260304-194448.md`
  - 生成 `reports/staging/rollback-drill-20260304-194701.md`
  - 生成 `reports/chaos/chaos-report-20260304-194701.md` 及对应 json 产物

### E. 诊断门禁
- 命令：工作区诊断检查
- 结果：通过（0 条诊断）

## 2) 上线判定结论

- 结论：**有条件上线（不可正式上线）**
- 判定依据：
  1. 当前质量门禁复验已通过，主线能力与二阶段能力可运行。
  2. Task1-2 盘点中的两个阻断项仍未闭环：  
     - 钱包测试网 E2E 联调脚本未落地（W2，阻断）  
     - 链端测试网启动与节点运维脚本未落地（D2，阻断）
- 结论解释：当前更适合进入“准生产/灰度前收敛阶段”，不满足“正式上线”收口条件。

## 3) 上线前最小补齐建议

1. 补齐钱包测试网 E2E 联调脚本与执行入口（阻断项 W2）
   - 最小验收：脚本可一键执行，输出成功/失败状态；至少覆盖登录、资产查询、交易提交与回执确认主链路。
2. 补齐链端测试网启动与节点运维脚本（阻断项 D2）
   - 最小验收：支持初始化、启动、健康检查、停止、日志采集五个动作；具备失败退出码。
3. 补齐后执行一次全量复验并更新审计
   - 最小验收：`npm run validate`、`go test ./...`、`run-integration.ps1`、`run-staging-drill.ps1` 全部通过并产出新报告。

## 4) 最终建议

- 发布策略：在补齐 W2、D2 前，不执行正式对外上线。
- 里程碑建议：以“阻断项补齐 + 全量复验通过 + 本规格 checklist 全勾选”作为正式上线准入条件。
