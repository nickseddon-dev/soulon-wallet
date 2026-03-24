# 上线阻断项补齐（W2+D2）Spec

## Why
当前项目已完成主线能力并通过门禁复验，但仍存在两个正式上线阻断项：钱包测试网 E2E 联调脚本（W2）与链端测试网启动/运维脚本（D2）。需要补齐最小上线闭环并复验。

## What Changes
- 新增钱包测试网 E2E 联调脚本与统一执行入口
- 新增链端测试网启动脚本与节点运维脚本（状态、日志、停止）
- 将新增脚本接入现有文档与执行入口，支持 DryRun 与在线模式
- 执行上线门禁复验并输出可正式上线判定

## Impact
- Affected specs: 钱包 E2E 联调、链端测试网运维、上线门禁判定
- Affected code: `soulon-wallet/scripts`、`soulon-wallet/package.json`、`soulon-wallet/README.md`、`soulon-deep-chain/scripts`、`soulon-deep-chain/README.md`、`deploy/run-deploy-test.ps1`

## ADDED Requirements
### Requirement: 钱包测试网 E2E 联调脚本
系统 SHALL 提供钱包测试网 E2E 脚本，覆盖账户读取、转账提交与回执确认主链路。

#### Scenario: 执行钱包 E2E
- **WHEN** 开发者执行统一入口命令
- **THEN** 能在在线模式完成 E2E 校验，在离线模式完成结构化演练

### Requirement: 链端测试网启动与运维脚本
系统 SHALL 提供测试网启动与运维脚本，至少支持启动、状态检查、日志查看与停止。

#### Scenario: 运维节点
- **WHEN** 运维执行测试网脚本
- **THEN** 可管理节点生命周期并获得明确结果输出

### Requirement: 上线阻断项复验
系统 SHALL 在补齐 W2 与 D2 后执行门禁复验，并更新上线判定结论。

#### Scenario: 复验上线
- **WHEN** W2 与 D2 实现完成
- **THEN** 运行门禁命令通过并可给出正式上线结论

## MODIFIED Requirements
### Requirement: 上线判定条件
上线判定从“有条件上线”修改为“阻断项闭环后可正式上线”。

## REMOVED Requirements
### Requirement: 阻断项未闭环也可推进上线
**Reason**: 会引入测试网联调与运维不可控风险。  
**Migration**: 强制要求 W2、D2 完成并通过复验后再进入正式上线。
