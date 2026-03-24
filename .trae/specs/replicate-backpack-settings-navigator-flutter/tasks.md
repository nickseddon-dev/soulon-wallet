# Tasks
- [x] Task 1: 冻结 Backpack SettingsNavigator 对照表
  - [x] SubTask 1.1: 提取 SettingsNavigator 路由枚举与页面族清单
  - [x] SubTask 1.2: 输出 Flutter 路由命名与页面文件映射（Settings Root/Wallets/YourAccount/Preferences/About）

- [x] Task 2: 扩展 Flutter Settings 路由体系并接入 AppRouter
  - [x] SubTask 2.1: 增加 Settings 子路由常量（/replica/mobile/settings/*）
  - [x] SubTask 2.2: 在 AppRouter 注册所有 Settings 子页面路由

- [x] Task 3: 重构 Settings Root 页面为 Backpack 信息架构
  - [x] SubTask 3.1: 将 ReplicaSettingsPage 拆为 Root + 复用组件（分组/列表项/开关项）
  - [x] SubTask 3.2: Root 内各入口跳转至对应子页面

- [x] Task 4: 实现 Wallets 页面族（可达占位）
  - [x] SubTask 4.1: Wallets 列表页与钱包 mock 数据
  - [x] SubTask 4.2: Wallet 详情页 + Rename/Remove/Remove Confirm
  - [x] SubTask 4.3: Add Wallet 流程页面可达（链选择/助记词/私钥/硬件钱包等占位）

- [x] Task 5: 实现 Your Account 页面族（可达占位）
  - [x] SubTask 5.1: Account 概览页与导航入口
  - [x] SubTask 5.2: Update Name / Change Password 页面与表单校验占位
  - [x] SubTask 5.3: Show Recovery Phrase Warning / Remove Account 页面

- [x] Task 6: 实现 Preferences 页面族（可达占位）
  - [x] SubTask 6.1: Preferences Root（开关/选择项）与本地状态持久（mock）
  - [x] SubTask 6.2: Auto Lock / Trusted Sites / Language / Hidden Tokens 页面
  - [x] SubTask 6.3: Blockchain 偏好页族（RPC/Commitment/Explorer/Custom RPC）可达

- [x] Task 7: 实现 About 页面并完成视觉一致性微调
  - [x] SubTask 7.1: About 页面信息块与链接占位
  - [x] SubTask 7.2: 统一分组标题、卡片、分割线、按钮样式（令牌驱动）

- [x] Task 8: 验收与可测试交付
  - [x] SubTask 8.1: 编写/补齐关键手工验收步骤（从 Settings Root 走通全部入口）
  - [x] SubTask 8.2: 运行 flutter analyze 与基础运行验证（web-server）

# Task Dependencies
- [Task 2] depends on [Task 1]
- [Task 3] depends on [Task 2]
- [Task 4] depends on [Task 3]
- [Task 5] depends on [Task 3]
- [Task 6] depends on [Task 3]
- [Task 7] depends on [Task 3]
- [Task 8] depends on [Task 4]
- [Task 8] depends on [Task 5]
- [Task 8] depends on [Task 6]
- [Task 8] depends on [Task 7]
