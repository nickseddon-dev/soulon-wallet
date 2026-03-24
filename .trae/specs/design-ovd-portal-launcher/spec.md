# OVD（Overdrive）钱包 & 游戏启动器（Launcher）Spec

## Why
当前钱包的“资产”体验与 OVD 品牌叙事不一致，需要引入从“资产”到“次元”的入口与启动器，以承载游戏与生态功能，同时保持现有项目 UI 风格一致。

## What Changes
- 新增 OVD Portal 入口：钱包首页右上角“四格”图标作为“入口点”，触发 Portal Transition 动效进入 Launcher。
- 新增 Launcher 页面：顶部动态余额 + 充值/提现/兑换按钮；中部 3D 轮播游戏卡片 + 陀螺仪视差；底部磨砂磁贴功能栏。
- 新增 Status Stream（数据流槽）：模仿 Matrix 代码流的滚动实时日志（前端 Mock 数据）。
- 统一动效规范：曲线 `Curves.easeOutQuart`；页面切换 600ms；磁贴反馈 150ms。
- **BREAKING**：自建链在前端显示名称统一重命名为 “Overdrive Chian”（按需求原文）。

## Impact
- Affected specs: 钱包首页入口、Portal 动效系统、Launcher 信息架构、品牌视觉与动效规范
- Affected code: `wallet-app-flutter/lib/pages/*`、`wallet-app-flutter/lib/widgets/*`、`wallet-app-flutter/lib/theme/*`、`wallet-app-flutter/pubspec.yaml`

## ADDED Requirements
### Requirement: Portal 入口与动效（The Portal Transition）
系统 SHALL 在钱包首页右上角提供“四格”图标作为 Portal 入口点，并以“入口点扩张覆盖 + 背景缩放位移 + 图标变形”为核心动效进入 Launcher。

#### Scenario: 进入 Launcher（Success）
- **WHEN** 用户在钱包首页点击右上角“四格”入口图标
- **THEN** 入口图标快速扩大覆盖全屏
- **AND THEN** 钱包背景产生缩放与位移，向左上角收拢
- **AND THEN** 入口图标在左上角变形为“三条杠”图案（Hamburger）
- **AND THEN** 动效完成后展示 Launcher 主页面

#### Scenario: 退出 Launcher（Success）
- **WHEN** 用户在 Launcher 点击返回或关闭入口
- **THEN** 动画以反向过渡回到钱包首页（保持同曲线与时长规范）

#### Scenario: 音效（Optional）
- **WHEN** 用户触发 Portal 进入动效
- **THEN** 播放短促电磁加速声（High-frequency hum）
- **AND** 若设备静音/无权限/无资源，流程仍可正常完成

### Requirement: Launcher 页面布局（Launcher Layout）
系统 SHALL 提供符合 “Cyber-Minimalism + Glassmorphism 2.0” 且沿用当前项目 UI 风格的 Launcher 页面。

#### Scenario: 顶部区域（Success）
- **WHEN** 用户进入 Launcher
- **THEN** 左侧展示动态余额（等价法币）
- **AND THEN** 下方并排展示三个按钮：充值 / 提现 / 兑换

#### Scenario: Status Stream（Success）
- **WHEN** Launcher 展示顶部内容
- **THEN** 最上方显示一条持续滚动的“实时日志流”
- **AND** 日志内容包含：链上大额交易、游戏内掉落等（前端 Mock，滚动展示）

#### Scenario: Hero Horizon（Success）
- **WHEN** 用户进入 Launcher 主视觉区域
- **THEN** 使用 `PageView.builder` 展示 3D 轮播卡片（至少 3 张）
- **AND** 焦点卡片随滚动有景深/缩放层次变化
- **AND** 焦点卡片启用 `flutter_tilt`（或同类能力）实现陀螺仪视差：手机倾斜时卡片内容微晃动

#### Scenario: 底部功能磁贴栏（Success）
- **WHEN** Launcher 展示底部区域
- **THEN** 使用 `BackdropFilter` 提供磨砂玻璃背景
- **AND THEN** 以磁贴布局展示 4 个入口：
  - Tavern（酒馆）：社交与任务入口
  - Vault（种子库）：钱包私钥与身份根证明入口
  - Bazaar（交易所）：x402 资产买卖中心入口
  - Lab（代理实验室）：AI 执行策略配置入口
- **AND** 点击后进入对应占位页面（前端先行，不接后端）

### Requirement: UI 深度与层级（Depth & Layers）
系统 SHALL 使用 `Stack` 构建背景粒子层/氛围灯光层/交互 UI 层，并通过渐变遮罩营造纵深感（效果以现有项目设计风格为准）。

## MODIFIED Requirements
### Requirement: 链名称展示
系统 SHALL 在所有链名称显示位置将“自建链”统一显示为 “Overdrive Chian”。

## REMOVED Requirements
### Requirement: 无
**Reason**: 本次为新增 Launcher 与 Portal 体验，不移除既有功能。  
**Migration**: 不涉及后端迁移；仅前端显示与入口交互调整。

