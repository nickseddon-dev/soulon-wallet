# Backpack Chrome 扩展 Popup 复刻一致性 Spec

## Why
当前 `wallet-extension` 的 Popup 仅是“演示版 UI”，其导航结构、页面层级、交互关闭逻辑与 Backpack Chrome 扩展不一致，导致三端（Flutter/Extension/Web）复刻无法收敛到同一套基线。需要以 Backpack 的 Chrome 扩展为唯一基准，尽可能“照搬”其信息架构与交互逻辑。

## What Changes
- 将 `wallet-extension` 的 Popup 从“单文件手写状态机 + 伪路由”升级为“与 Backpack 扩展一致的导航结构与页面族”。
- 对齐 Backpack 扩展的 **Root Header**：左侧 AvatarPopover 入口、中间 Active Wallet 下拉、右侧 Settings 入口，并与页面栈的 Back/Close 行为一致。
- 对齐 Backpack 扩展的 **TabsNavigator**：Tokens / Collectibles / Activity 顶部居中 TabBar（无切换动画）。
- 对齐 Backpack 扩展的 **WalletsNavigator** 页面族与 Modal 体系：
  - 资产详情、收藏详情/集合、活动详情
  - Send 流程（Token 选择 → 地址选择 → 金额 → 确认）
  - Receive
  - Search（透明模态）
  - Settings（含深层页族入口占位）
- 将 `wallet-extension/src/styles/design-tokens.css` 的颜色与排版令牌对齐到 Backpack 深色模式（以 Flutter 的 `AppColorTokens` 作为本仓库令牌源，并对齐 Backpack Popup 的背景/字体）。
- 保留“业务 mock”的边界：不引入真实链上交易与真实密钥管理，但 UI/交互节奏/导航关闭行为必须与 Backpack 一致。

## Impact
- Affected specs: `audit-backpack-source-and-fill-frontend-page-gaps`、`replicate-backpack-multi-platform-ui`
- Affected code:
  - `wallet-extension/src/popup/main.ts`（将被拆分/重构为多屏/多路由实现）
  - `wallet-extension/src/popup/routes.ts`（扩展路由契约）
  - `wallet-extension/src/styles/design-tokens.css`、`wallet-extension/src/styles/popup.css`
  - （如需）新增 `wallet-extension/src/popup/screens/*`、`wallet-extension/src/popup/state/*` 等模块化目录

## ADDED Requirements
### Requirement: 扩展端导航结构与 Backpack 一致
系统 SHALL 在扩展端 Popup 内实现与 Backpack 一致的导航结构：
- Root：WalletsNavigator（主栈）
- TabsNavigator：Tokens / Collectibles / Activity
- Modal Group：Send/Receive/Swap/Stake/Settings/Tensor 等以 modal 方式呈现（可先用 mock 内容，但页面结构与关闭行为必须正确）
- Transparent Modal：Search 以透明模态覆盖呈现

#### Scenario: Tabs 导航一致
- **WHEN** 用户在顶部 Tab 切换 Tokens/Collectibles/Activity
- **THEN** TabBar 居中、样式一致、切换不出现额外动画（与 Backpack 一致）

#### Scenario: Root Header 一致
- **WHEN** 用户处于 Tabs 根页面
- **THEN** Header 左侧为 AvatarPopover 入口，中间为 Active Wallet 下拉按钮，右侧为 Settings 入口

### Requirement: Send 流程完全照搬
系统 SHALL 在扩展端提供与 Backpack 一致的 Send 多屏流程：
1) SendTokenSelectScreen（选择 Token）
2) SendAddressSelectScreen（选择/输入收款地址）
3) SendAmountSelectScreen（输入金额/手续费等关键字段）
4) SendConfirmationScreen（确认并提交）

#### Scenario: Send 关闭行为一致
- **WHEN** 用户在 Send 流程任意步骤点击 Close/Back
- **THEN** 行为与 Backpack 的 closeBehavior 一致（go-back / pop-root-twice / reset 等），不会把用户留在“半栈”或错误页面

### Requirement: 详情页族补齐（P0）
系统 SHALL 补齐扩展端 P0 详情页族（允许 mock 数据，但必须可导航可返回）：
- TokensDetailScreen
- ActivityDetailScreen

#### Scenario: 详情页可达
- **WHEN** 用户在 Tokens/Activity 列表点击某条记录
- **THEN** 进入对应详情页，并可通过 Back/Close 返回到正确位置

### Requirement: 设计令牌与视觉一致
系统 SHALL 使用统一设计令牌确保扩展端视觉与 Backpack 深色模式一致（背景、卡片、文本层级、按钮样式、圆角、阴影、动效时长）。

#### Scenario: 令牌对齐
- **WHEN** 对比 Flutter `AppColorTokens` 与扩展端 `design-tokens.css`
- **THEN** 主色/背景/表面/边框/文本的语义与色值一致（允许扩展端以 CSS 变量表达，但语义必须一一映射）

## MODIFIED Requirements
### Requirement: 扩展端“演示 UI”范围调整为“可交付复刻 UI”
现有扩展端 Popup 的“演示列表 + 单一模态流程” SHALL 升级为“Backpack 级页面栈 + 详情页族 + 多屏 Send 流程 + Search 透明模态”。

## REMOVED Requirements
### Requirement: 仅维持单文件 main.ts 即可
**Reason**: 单文件状态机难以承载 Backpack 的导航层级与 closeBehavior，且不利于后续页面族补齐。  
**Migration**: 拆分为 screens/state/navigation 等模块化结构，维持清晰边界与可扩展性。
