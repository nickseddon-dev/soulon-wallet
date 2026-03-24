# Soulon 部署测试入口

## 目录

- `../soulon-deep-chain/deploy/testnet`：链端测试网部署参数模板。
- `../soulon-deep-chain/scripts/start-testnet.ps1`：链端测试网启动脚本（D2）。
- `../soulon-deep-chain/scripts/testnet-ops.ps1`：链端测试网运维脚本（D2）。
- `../soulon-wallet/scripts/wallet-testnet-e2e.mjs`：钱包测试网 E2E 联调脚本（W2）。
- `../soulon-wallet/scripts/wallet-business-integration.mjs`：钱包质押/治理业务集成测试脚本。
- `../soulon-wallet/scripts/gate-e2e-regression.ps1`：钱包 E2E+回归统一门禁脚本。
- `../soulon-backend/scripts/check-release-readiness.ps1`：性能基线与回滚演练检查脚本。
- `run-deploy-test.ps1`：W2+D2 一体化部署测试入口。
- `run-p2-gate.ps1`：P2 统一门禁入口（调用版本化验收模板执行全量门禁）。
- `wallet-production-gate-template.json`：Flutter/SDK/后端统一门禁模板。
- `run-wallet-production-gate.ps1`：生产级钱包架构统一门禁入口（输出版本化验收归档）。

## 测试目标

- D2：链端具备测试网启动脚本与运维脚本（状态/日志/停止）能力。
- W2：钱包具备测试网 E2E 联调能力（在线模式）与离线结构化演练能力。
- 发布门禁支持 E2E 回归、性能基线与回滚演练检查，并统一产出汇总报告与失败明细。
- 一体化入口支持默认 DryRun 串联验证，在线模式可执行真实链路验证。
- 可选业务集成测试支持质押与治理链路复验（离线/在线模式）。
