# Tasks
- [x] Task 1: 建立钱包主线工程骨架，提供可启动开发环境与基础路由页面。
  - [x] SubTask 1.1: 初始化项目结构、环境变量模板与启动脚本
  - [x] SubTask 1.2: 搭建基础路由与首页占位页面
- [x] Task 2: 实现统一网络访问层，对接冻结 API 契约并提供标准错误模型。
  - [x] SubTask 2.1: 封装请求客户端、超时策略与重试边界
  - [x] SubTask 2.2: 定义接口响应映射与错误对象规范
- [x] Task 3: 实现钱包主线最小可用业务页面，支持资产与交易查询展示。
  - [x] SubTask 3.1: 接入 `/v1/indexer/state` 并展示链状态摘要
  - [x] SubTask 3.2: 接入 `/v1/indexer/events` 并展示交易/事件列表
- [x] Task 4: 加入鉴权壳与会话占位能力，为后续签名/授权流程预留扩展点。
  - [x] SubTask 4.1: 实现登录态容器与路由守卫
  - [x] SubTask 4.2: 实现会话失效处理与统一跳转策略
- [x] Task 5: 完成联调与门禁验证，输出主线可发布的验收记录。
  - [x] SubTask 5.1: 执行钱包-后端联调清单并修复阻塞问题
  - [x] SubTask 5.2: 执行测试与构建校验并归档结果

# Task Dependencies
- Task 2 depends on Task 1
- Task 3 depends on Task 2
- Task 4 depends on Task 1 and Task 2
- Task 5 depends on Task 3 and Task 4
