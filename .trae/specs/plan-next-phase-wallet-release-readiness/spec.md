# 下一步开发计划（钱包发布就绪）Spec

## Why
钱包 P1 主线能力已收口并通过门禁，但距离“可发布可运营”仍缺少端到端用户流、预发布演练与发布候选产物。需要进入“联调与发布就绪”阶段，降低上线风险。

## What Changes
- 统一 wallet-app 与 soulon-wallet 的调用契约与错误语义。
- 完成转账、质押、治理三条用户主流程的页面接入与联调闭环。
- 建立发布就绪门禁：E2E、回归、性能基线、失败回滚演练。
- 产出候选版本发布包与验收报告，作为正式上线前置输入。

## Impact
- Affected specs: 钱包前后端联调、用户主流程体验、发布门禁、预发布演练
- Affected code: `wallet-app/src/*`、`soulon-wallet/src/*`、`soulon-backend/internal/api/*`、`deploy/*`、`.trae/documents/*`

## ADDED Requirements
### Requirement: 钱包主流程联调闭环
系统 SHALL 打通转账、质押、治理三条端到端流程，并保证页面行为与链端结果一致。

#### Scenario: 主流程联调通过
- **WHEN** 执行钱包主流程联调脚本
- **THEN** 三条流程全部通过且无阻断缺陷

### Requirement: 错误语义统一
系统 SHALL 在 SDK、前端、后端三层使用统一错误码与展示映射。

#### Scenario: 错误一致性通过
- **WHEN** 注入典型失败场景（余额不足、gas不足、参数非法）
- **THEN** 三层错误码一致，前端提示符合预期

### Requirement: 发布就绪门禁
系统 SHALL 提供可重复执行的发布门禁，包括 E2E、回归、性能基线与回滚演练。

#### Scenario: 发布门禁通过
- **WHEN** 执行发布门禁命令
- **THEN** 所有检查通过并输出通过结论

#### Scenario: 门禁失败
- **WHEN** 任一检查失败
- **THEN** 输出失败明细与阻断项，不允许进入发布候选阶段

### Requirement: 发布候选产物
系统 SHALL 生成版本化发布候选包、变更摘要与验收报告。

#### Scenario: 候选包生成成功
- **WHEN** 发布门禁通过
- **THEN** 生成可追溯的 RC 产物并归档

## MODIFIED Requirements
### Requirement: 钱包阶段开发目标
钱包阶段目标由“P1 主线可用”扩展为“发布就绪”，新增联调闭环、错误统一与发布候选产物要求。

## REMOVED Requirements
### Requirement: 无
**Reason**: 本次为阶段升级，不移除既有要求。  
**Migration**: 不涉及迁移。
