# 按计划推进钱包P1主线开发 Spec

## Why
P0 与 P2 已形成可运行基线，但钱包主线仍有 P1 关键能力未收口（账户核心、转账主链路、质押治理服务），且部分链端 API 能力与标准接口契约仍需先行补齐。需要先完成链端接口能力与标准化，再推进钱包功能落地，避免联调返工。

## What Changes
- 先补齐钱包依赖的链端 API 能力缺口（查询、交易、治理、质押相关接口）。
- 生成并冻结标准 API 接口契约（OpenAPI/JSON 契约）供钱包统一调用。
- 完成钱包 P1 三项主线任务：W-04、W-05、W-06。
- 明确并固化与链端接口契约的对齐规则，确保请求参数和错误语义一致。
- 补齐单元测试与集成验证命令，形成可复用门禁。
- 回填执行任务状态与阶段验收记录。

## Impact
- Affected specs: 链端 API 能力、标准接口契约、钱包账户管理、转账广播链路、质押/治理服务
- Affected code: `soulon-deep-chain/*`、`soulon-backend/internal/api/*`、`contracts/*`、`soulon-wallet/src/*`、`wallet-app/src/api/*`、`.trae/documents/*`

## ADDED Requirements
### Requirement: 链端 API 能力补齐
系统 SHALL 先提供钱包主线所需的链端 API 能力，并保证查询与交易接口可稳定调用。

#### Scenario: API 缺口补齐完成
- **WHEN** 执行链端 API 能力校验
- **THEN** 钱包所需接口全部可用且返回结构符合约定

### Requirement: 标准 API 接口契约
系统 SHALL 提供版本化标准接口契约并冻结，供钱包 SDK 与前端统一使用。

#### Scenario: 契约发布成功
- **WHEN** 生成并发布接口契约文件
- **THEN** 钱包侧可直接按契约接入且通过一致性校验

### Requirement: W-04 钱包账户核心能力
系统 SHALL 提供稳定的钱包账户创建、导入、地址派生与基础校验能力。

#### Scenario: 账户创建成功
- **WHEN** 用户发起新钱包创建
- **THEN** 返回可用账户信息并可进行后续签名操作

#### Scenario: 导入参数非法
- **WHEN** 助记词或账户参数不合法
- **THEN** 返回标准化错误并拒绝导入

### Requirement: W-05 转账交易构建与广播
系统 SHALL 提供完整的转账交易构建、签名、广播与结果确认流程。

#### Scenario: 转账广播成功
- **WHEN** 输入合法收款地址、金额与链配置
- **THEN** 返回交易哈希与确认状态

#### Scenario: 广播失败
- **WHEN** 出现 nonce/gas/节点异常
- **THEN** 返回可定位错误码并保留重试能力

### Requirement: W-06 质押与治理基础服务
系统 SHALL 提供 Delegate/Undelegate/Claim 与治理提案投票基础能力。

#### Scenario: 质押或投票成功
- **WHEN** 用户提交合法交易参数
- **THEN** 返回链上受理结果并可查询执行状态

#### Scenario: 参数校验失败
- **WHEN** 地址、金额、提案编号等字段不合法
- **THEN** 返回明确字段错误并阻断提交

### Requirement: 钱包与链端契约对齐
系统 SHALL 对钱包调用链端接口进行参数、版本与错误语义对齐校验，并在链端契约变更时触发门禁校验。

#### Scenario: 契约对齐通过
- **WHEN** 执行钱包主线验证命令
- **THEN** 契约校验通过且无阻断差异

## MODIFIED Requirements
### Requirement: 钱包阶段开发范围
钱包开发范围由“P0 基础能力完成”扩展为“P1 主链路可用”，并新增前置条件“链端 API 能力与标准契约先完成”。最终必须覆盖接口可用性、账户、转账、质押、治理五类能力并形成验证证据。

## REMOVED Requirements
### Requirement: 无
**Reason**: 本次仅新增与扩展钱包主线能力，不涉及移除。  
**Migration**: 不涉及迁移。
