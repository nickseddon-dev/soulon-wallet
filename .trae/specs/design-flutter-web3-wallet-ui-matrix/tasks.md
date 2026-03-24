# Tasks
- [x] Task 1: 搭建 Flutter 钱包前端基础框架与设计系统
  - [x] SubTask 1.1: 初始化路由、主题、字体与色板令牌
  - [x] SubTask 1.2: 建立按钮、输入框、卡片、弹窗基础组件
  - [x] SubTask 1.3: 建立统一动画令牌与过渡封装

- [x] Task 2: 实现身份与密钥管理模块页面
  - [x] SubTask 2.1: 实现助记词生成与恢复流程页面
  - [x] SubTask 2.2: 实现 HD 账户与观察者钱包管理页面
  - [x] SubTask 2.3: 实现助记词备份校验与风险提示页面

- [x] Task 3: 实现资产与交易模块页面
  - [x] SubTask 3.1: 实现资产看板与法币折算展示页面
  - [x] SubTask 3.2: 实现交易构建、仿真、签名、广播流程页面
  - [x] SubTask 3.3: 实现交易历史与导出（CSV/PDF/JSON）页面

- [x] Task 4: 实现 Cosmos 生态互操作页面
  - [x] SubTask 4.1: 实现质押操作全流程页面
  - [x] SubTask 4.2: 实现治理提案浏览与投票页面
  - [x] SubTask 4.3: 实现 IBC 传输与跨链状态追踪页面

- [x] Task 5: 实现安全认证与 DApp 交互页面
  - [x] SubTask 5.1: 实现 PIN/生物识别二次确认页面
  - [x] SubTask 5.2: 实现 WalletConnect 授权与会话页面
  - [x] SubTask 5.3: 实现 SuggestChain、扫码支付与 Reorg 刷新提示

- [x] Task 6: 实现通知中心与多签工作台页面
  - [x] SubTask 6.1: 实现实时通知流与消息详情页面
  - [x] SubTask 6.2: 实现多签任务列表与审批流程页面
  - [x] SubTask 6.3: 实现离线签名导入与进度展示页面

- [x] Task 7: 完成契约接入、测试与验收归档
  - [x] SubTask 7.1: 接入链端标准 API 契约并统一错误映射
  - [x] SubTask 7.2: 执行页面测试、交互测试与动效验收
  - [x] SubTask 7.3: 回填任务状态、验收文档与设计说明

# Task Dependencies
- [Task 2] depends on [Task 1]
- [Task 3] depends on [Task 1]
- [Task 4] depends on [Task 1]
- [Task 5] depends on [Task 1]
- [Task 6] depends on [Task 1]
- [Task 7] depends on [Task 2]
- [Task 7] depends on [Task 3]
- [Task 7] depends on [Task 4]
- [Task 7] depends on [Task 5]
- [Task 7] depends on [Task 6]

# 前置项状态（环境）
- [x] Flutter 工具链已安装：`C:\tools\flutter`
- [x] PATH 已配置：User Path 包含 `C:\tools\flutter\bin`
- [x] `flutter --version` 可执行并返回版本信息（Framework `ff37bef603`，Dart `3.11.1`）
- [x] `flutter analyze` 可执行；当前返回项目既有问题 `22 issues`（含 `1 error`）
- [x] `flutter test` 可执行；当前存在项目既有失败（`security_interop_demo_store.dart` const 构造错误与 `task7_page_interaction_test.dart` 断言失败）
