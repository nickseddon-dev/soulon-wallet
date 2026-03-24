# Tasks
- [x] Task 1: 盘点 Backpack 扩展导航与页面族并冻结对照表
  - [x] SubTask 1.1: 提取 WalletsNavigator/TabsNavigator/SendNavigator 的页面层级与关闭行为
  - [x] SubTask 1.2: 将对照结果映射到本仓库 `wallet-extension/src/popup/routes.ts` 的路由契约

- [x] Task 2: 重构 Popup 架构为“多屏 + 导航栈 + Modal 体系”
  - [x] SubTask 2.1: 拆分 `main.ts` 为 screens/state/navigation 模块
  - [x] SubTask 2.2: 实现 Root Header（AvatarPopover / ActiveWallet / Settings）与回退/关闭逻辑

- [x] Task 3: 实现 TabsNavigator（Tokens/Collectibles/Activity）与基础列表
  - [x] SubTask 3.1: 复刻顶部居中 TabBar（无切换动画）
  - [x] SubTask 3.2: 复刻列表项结构与点击态（用于进入详情页）

- [x] Task 4: 补齐 P0 详情页族（TokensDetail/ActivityDetail）
  - [x] SubTask 4.1: Token 详情页：从列表进入、返回路径正确
  - [x] SubTask 4.2: Activity 详情页：从列表进入、返回路径正确

- [x] Task 5: 实现 Send 多屏流程（与 Backpack 一致）
  - [x] SubTask 5.1: Token 选择页（SendTokenSelectScreen）
  - [x] SubTask 5.2: 地址选择页（SendAddressSelectScreen）
  - [x] SubTask 5.3: 金额页（SendAmountSelectScreen）
  - [x] SubTask 5.4: 确认页（SendConfirmationScreen）
  - [x] SubTask 5.5: 完整 closeBehavior（go-back / pop-root-twice / reset）

- [x] Task 6: Search 透明模态与 Settings 入口对齐
  - [x] SubTask 6.1: Search 透明模态（打开/关闭/键盘 Esc）
  - [x] SubTask 6.2: Settings 主入口 + 深层页族占位路由（可后续补齐）

- [x] Task 7: 对齐扩展端设计令牌与样式细节
  - [x] SubTask 7.1: 将 `design-tokens.css` 与 Flutter `AppColorTokens` 语义对齐
  - [x] SubTask 7.2: 修复 popup.css 中不一致的按钮/输入/卡片样式

- [x] Task 8: 复刻验收与回归
  - [x] SubTask 8.1: 增加关键流程手工验收清单（创建/导入/解锁/发送/搜索/详情）
  - [x] SubTask 8.2: 执行 TypeScript typecheck 与 eslint 校验（确保无阻断问题）

# Task Dependencies
- [Task 2] depends on [Task 1]
- [Task 3] depends on [Task 2]
- [Task 4] depends on [Task 3]
- [Task 5] depends on [Task 2]
- [Task 6] depends on [Task 2]
- [Task 7] depends on [Task 3]
- [Task 8] depends on [Task 4]
- [Task 8] depends on [Task 5]
- [Task 8] depends on [Task 6]
