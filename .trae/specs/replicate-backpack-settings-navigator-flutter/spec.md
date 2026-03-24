# Flutter Settings 全量照搬（Backpack 基准）Spec

## Why
当前 Flutter 端 [replica_settings_page.dart](file:///D:/soulon_wallet/wallet-app-flutter/lib/pages/replica_settings_page.dart) 仅为“示意版 Settings”，缺少 Backpack 设置体系的完整信息架构、深层页面族与交互一致性，无法满足“完整照搬”与后续联调验收。

## What Changes
- 在 Flutter 端实现与 Backpack 扩展端 `SettingsNavigator` 对齐的 Settings 页面族（信息架构与页面可达性为第一优先）。
- 将现有 `ReplicaSettingsPage` 从“单页列表”升级为“Settings Root + 子页面族”，并补齐：Wallets / Your Account / Preferences / About 等核心路径。
- 增加 Settings 专用路由常量与导航入口，保证各子页面可从 Settings Root 进入，并可正确返回。
- 保留 mock 边界：不实现真实助记词/私钥展示与真实链交互，但必须提供安全占位流程与清晰的禁用/确认提示，避免泄露敏感信息。
- 视觉与动效：使用现有 `AppColorTokens` / `AppMotionTokens`，保证 Settings 系列页面风格与 Backpack 深色模式一致，并沿用既有路由转场策略（`fadeSlideRoute`/`fadeScaleRoute` 等）。

## Impact
- Affected specs: `replicate-backpack-multi-platform-ui`（补齐 Settings 深层页族）
- Affected code:
  - [app_router.dart](file:///D:/soulon_wallet/wallet-app-flutter/lib/app/app_router.dart)（新增 Settings 子路由）
  - [replica_settings_page.dart](file:///D:/soulon_wallet/wallet-app-flutter/lib/pages/replica_settings_page.dart)（重构为 Settings Root）
  - 新增 `lib/pages/replica_settings/*`（Settings 子页面族与通用组件）

## ADDED Requirements
### Requirement: Settings 导航结构与 Backpack 对齐
系统 SHALL 在 Flutter 端实现与 Backpack `SettingsNavigator` 等价的 Settings 页面族（以可达性与信息架构为准）。

#### Scenario: Settings Root 可导航
- **WHEN** 用户打开 Settings Root
- **THEN** 能看到与 Backpack 对齐的分组入口（至少包含 Wallets、Your Account、Preferences、About、Security/Lock），且每个入口可进入对应子页面

#### Scenario: 子页面返回行为正确
- **WHEN** 用户从 Settings Root 进入任一子页面并点击返回
- **THEN** 返回到上一级页面，且状态不丢失（例如开关状态、选择项）

### Requirement: Wallets 页面族占位一致
系统 SHALL 提供 Wallets 相关页面族的“可交付占位实现”，覆盖 Backpack SettingsNavigator 中的主要 Wallets 路径：
- Wallets 列表页
- Wallet 详情页
- Rename Wallet
- Remove Wallet（含确认屏）
- Add Wallet 流程（选择链、导入/创建助记词、私钥、硬件钱包等页面可达）

#### Scenario: 钱包管理可走通
- **WHEN** 用户在 Wallets 列表点击任意钱包
- **THEN** 进入详情页，并可继续进入 Rename/Remove 等子流程

### Requirement: Your Account 页面族占位一致
系统 SHALL 提供 Your Account 相关页面族的“可交付占位实现”，覆盖：
- Update Name
- Change Password
- Show Recovery Phrase Warning（仅警告与确认 UI，不展示真实助记词）
- Remove Account

#### Scenario: 敏感操作有明确告警
- **WHEN** 用户进入 Show Recovery Phrase / Show Private Key 相关路径
- **THEN** 必须先看到警告页与二次确认，且默认不展示任何敏感内容

### Requirement: Preferences 页面族占位一致
系统 SHALL 提供 Preferences 相关页面族的“可交付占位实现”，覆盖：
- Auto Lock Timer
- Trusted Sites
- Language
- Hidden Tokens
- Blockchain（包含 RPC Connection / Commitment / Explorer / Custom RPC 等路径可达）

#### Scenario: 偏好项可修改
- **WHEN** 用户在 Preferences 页面修改任意开关/选择项
- **THEN** UI 立即反映，并在返回/再次进入时保持一致（以本地状态 mock 持久为准）

### Requirement: About 页面一致
系统 SHALL 提供 About 页面并展示基础信息（版本号、构建信息占位、链接占位），布局与风格与 Backpack 保持一致。

## MODIFIED Requirements
### Requirement: ReplicaSettingsPage 从“示意页”升级为“Settings Root”
现有 `ReplicaSettingsPage` SHALL 改造为 Settings Root 页面，并将原先内联的开关/选项拆分为可复用的 Settings 组件与子页面导航入口。

## REMOVED Requirements
### Requirement: Settings 仅包含少量固定项即可
**Reason**: 不满足“完整照搬”目标，且无法支撑后续多端一致性验收。  
**Migration**: 按 Backpack SettingsNavigator 页面族拆分路由与页面，允许业务逻辑保持 mock，但页面与交互路径必须完整可达。

