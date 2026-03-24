# 执行整合计划首批 P0 开发任务 Spec

## Why
整合开发计划已形成，但当前代码库仍存在 P0 缺口：事件详情页刷新丢失上下文、wallet-app 缺少自动化测试基线。需要先完成可快速落地且阻断风险高的首批任务。

## What Changes
- 新增按事件 ID 查询接口，支持详情页刷新后回源加载
- 改造前端事件详情页，优先使用路由态，缺失时自动回源
- 为 wallet-app 建立测试基线（Vitest + RTL）并接入 npm 脚本
- 将测试纳入前端验证流程，形成可执行质量门禁

## Impact
- Affected specs: 钱包查询可用性、前端质量门禁、联调稳定性
- Affected code: `soulon-backend/internal/api`、`wallet-app/src/pages/EventDetailPage.tsx`、`wallet-app/package.json`、`wallet-app` 测试配置与测试文件

## ADDED Requirements
### Requirement: 事件详情回源能力
The system SHALL provide event detail fetch by event id for wallet detail page fallback.

#### Scenario: 刷新详情页
- **WHEN** 用户直接访问或刷新 `/events/:eventId`
- **THEN** 前端能够通过后端接口拉取事件详情并渲染

### Requirement: 前端自动化测试基线
The system SHALL provide runnable frontend unit test baseline and include it in validation workflow.

#### Scenario: 执行前端门禁
- **WHEN** 开发者执行前端验证命令
- **THEN** 测试、类型检查、构建均可执行并通过

## MODIFIED Requirements
### Requirement: 事件详情页数据来源
事件详情页从“仅依赖路由 state”修改为“路由 state 优先，缺失时按事件 ID 回源查询”。

## REMOVED Requirements
### Requirement: 详情页必须从列表跳转进入
**Reason**: 刷新或深链访问会导致可用性下降。  
**Migration**: 引入按 ID 查询接口与前端回源逻辑，保持兼容原跳转行为。
