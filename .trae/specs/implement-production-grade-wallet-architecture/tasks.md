# Tasks
- [x] Task 1: 完成 Flutter 生产数据分层改造
  - [x] SubTask 1.1: 建立 Repository/UseCase/State 分层骨架
  - [x] SubTask 1.2: 将资产与交易模块替换为真实 API 数据源
  - [x] SubTask 1.3: 将质押与治理模块替换为真实 API 数据源

- [x] Task 2: 完成移动端密钥安全与强认证接入
  - [x] SubTask 2.1: 集成 Android Keystore 与 iOS Keychain 封装
  - [x] SubTask 2.2: 接入 PIN 与生物识别双因子认证流程
  - [x] SubTask 2.3: 增加高风险操作审计事件记录

- [x] Task 3: 完成 DApp 与跨链互操作真实协议链路
  - [x] SubTask 3.1: 打通 WalletConnect 与 SuggestChain 真会话流程
  - [x] SubTask 3.2: 打通 BIP-21 扫码支付与交易构建联动
  - [x] SubTask 3.3: 打通 IBC 状态追踪与 Reorg 自动刷新机制

- [x] Task 4: 完成多签与企业审批流
  - [x] SubTask 4.1: 实现 M-of-N 多签任务模型与阈值推进
  - [x] SubTask 4.2: 实现离线签名导入与合并验证
  - [x] SubTask 4.3: 打通链上提交与审批结果回写

- [x] Task 5: 完成生产门禁、性能安全基线与发布归档
  - [x] SubTask 5.1: 建立 Flutter/SDK/后端统一门禁命令
  - [x] SubTask 5.2: 增加性能与安全基线检查及回滚演练
  - [x] SubTask 5.3: 生成版本化验收报告与审计归档

# Task Dependencies
- [Task 2] depends on [Task 1]
- [Task 3] depends on [Task 1]
- [Task 4] depends on [Task 1]
- [Task 5] depends on [Task 2]
- [Task 5] depends on [Task 3]
- [Task 5] depends on [Task 4]
