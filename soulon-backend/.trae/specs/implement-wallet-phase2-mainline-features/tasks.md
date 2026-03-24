# Tasks
- [x] Task 1: 实现签名/授权主流程页面与状态管理。
  - [x] SubTask 1.1: 增加授权请求页面与确认交互
  - [x] SubTask 1.2: 接入签名/授权 API 占位调用与结果展示
- [x] Task 2: 实现交易详情页与路由跳转链路。
  - [x] SubTask 2.1: 从事件列表增加详情入口
  - [x] SubTask 2.2: 新增详情页并展示结构化交易信息
- [x] Task 3: 增强事件列表分页与筛选能力。
  - [x] SubTask 3.1: 增加分页参数控制与查询状态显示
  - [x] SubTask 3.2: 增加关键筛选条件并联动请求
- [x] Task 4: 增强重试策略与观测埋点。
  - [x] SubTask 4.1: 为可重试失败增加受控重试策略
  - [x] SubTask 4.2: 增加请求生命周期埋点与错误归因字段
- [x] Task 5: 完成二阶段联调与质量门禁验证。
  - [x] SubTask 5.1: 执行前端校验与关键接口联调
  - [x] SubTask 5.2: 归档验证结果并更新任务与清单勾选

# Task Dependencies
- Task 2 depends on Task 1
- Task 3 depends on Task 1
- Task 4 depends on Task 1 and Task 3
- Task 5 depends on Task 2, Task 3 and Task 4
