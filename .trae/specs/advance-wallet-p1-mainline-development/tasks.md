# Tasks
- [x] Task 1: 补齐链端 API 能力并冻结标准接口
  - [x] SubTask 1.1: 盘点钱包依赖的链端 API 缺口并补齐实现
  - [x] SubTask 1.2: 生成并冻结标准 API 契约文件
  - [x] SubTask 1.3: 增加 API 契约一致性校验测试

- [x] Task 2: 完成 W-04 钱包账户核心能力
  - [x] SubTask 2.1: 完善账户创建与导入接口实现
  - [x] SubTask 2.2: 补齐地址派生与参数校验逻辑
  - [x] SubTask 2.3: 增加账户能力单元测试

- [x] Task 3: 完成 W-05 转账构建与广播链路
  - [x] SubTask 3.1: 实现转账交易构建与签名流程
  - [x] SubTask 3.2: 实现广播确认与错误映射
  - [x] SubTask 3.3: 补充转账主链路测试

- [x] Task 4: 完成 W-06 质押与治理基础服务
  - [x] SubTask 4.1: 实现 Delegate/Undelegate/Claim 服务
  - [x] SubTask 4.2: 实现提案查询与投票服务
  - [x] SubTask 4.3: 补充质押治理测试用例

- [x] Task 5: 完成契约对齐与门禁收口
  - [x] SubTask 5.1: 校验钱包与链端接口契约一致性
  - [x] SubTask 5.2: 执行钱包主线测试与构建门禁
  - [x] SubTask 5.3: 回填执行任务状态与验收文档

# Task Dependencies
- [Task 2] depends on [Task 1]
- [Task 3] depends on [Task 1]
- [Task 3] depends on [Task 2]
- [Task 4] depends on [Task 1]
- [Task 4] depends on [Task 3]
- [Task 5] depends on [Task 2]
- [Task 5] depends on [Task 3]
- [Task 5] depends on [Task 4]
