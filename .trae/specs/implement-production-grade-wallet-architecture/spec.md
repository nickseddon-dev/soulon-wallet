# 按计划实现生产级架构 Spec

## Why
当前钱包与链端已完成发布就绪阶段，但前端仍存在部分 Demo 驱动流程，移动端安全能力、真实协议链路与可观测运维闭环尚未完全生产化。需要按计划补齐“可上线可运维可审计”的生产级架构。

## What Changes
- 将 Flutter 端核心流程从 Demo Store 迁移到真实 API Repository + 状态管理架构。
- 落地移动端密钥安全体系：Android Keystore / iOS Keychain、PIN/生物识别联动鉴权。
- 打通 WalletConnect、SuggestChain、BIP-21 扫码、Reorg 刷新、通知推送的真实链路。
- 完成多签与企业签名流（x/authz 与离线多签）并提供任务化审批体验。
- 建立生产级质量门禁：单元/集成/E2E、性能基线、安全基线、回滚演练与审计归档。

## Impact
- Affected specs: 钱包生产架构、密钥安全、DApp 互联、跨链互操作、企业多签、发布运维
- Affected code: `wallet-app-flutter/lib/*`、`wallet-app-flutter/test/*`、`soulon-wallet/src/*`、`soulon-backend/internal/api/*`、`deploy/*`

## ADDED Requirements
### Requirement: Flutter 生产数据架构
系统 SHALL 使用可测试、可替换的 Repository + UseCase + 状态管理分层，替代 Demo Store 驱动。

#### Scenario: 交易与资产真实数据驱动
- **WHEN** 用户进入资产与交易页面
- **THEN** 页面数据来自链端真实接口并具备加载、失败、重试状态

### Requirement: 移动端密钥与认证安全
系统 SHALL 在移动端启用硬件安全存储与二次认证，所有资产变更操作必须经过强校验。

#### Scenario: 高风险操作确认
- **WHEN** 用户发起转账、质押、治理投票、多签提交
- **THEN** 强制触发 PIN + 生物识别校验并记录安全审计事件

### Requirement: DApp 与互操作真实链路
系统 SHALL 提供 WalletConnect、SuggestChain、BIP-21、IBC、Reorg 刷新的真实协议与状态同步链路。

#### Scenario: DApp 会话与跨链状态同步
- **WHEN** 用户授权 DApp 并发起跨链操作
- **THEN** 钱包可展示协议会话、交易状态、包确认进度与异常恢复提示

### Requirement: 多签与企业审批流
系统 SHALL 提供 M-of-N 多签任务流，支持在线授权与离线签名导入并可追踪审批进度。

#### Scenario: 多签任务闭环
- **WHEN** 企业用户创建并推进多签任务
- **THEN** 系统可展示签名进度、阈值达成状态与最终链上确认结果

### Requirement: 生产级门禁与可审计发布
系统 SHALL 具备统一门禁与审计归档，覆盖功能正确性、性能、安全与回滚能力。

#### Scenario: 发布前总验收
- **WHEN** 执行生产门禁
- **THEN** 所有检查通过且输出版本化验收报告与风险清单

## MODIFIED Requirements
### Requirement: 钱包交付标准
钱包交付标准由“发布就绪”提升为“生产级架构完成”，新增真实数据链路、安全硬件能力、企业多签与审计可追溯要求。

## REMOVED Requirements
### Requirement: 无
**Reason**: 本次为架构深化，不删除既有能力。  
**Migration**: 不涉及迁移。
