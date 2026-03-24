# Tasks
- [x] Task 1: 完成钱包三层契约统一与错误语义对齐
  - [x] SubTask 1.1: 对齐 wallet-app 与 SDK 调用模型
  - [x] SubTask 1.2: 统一后端错误码并建立映射表
  - [x] SubTask 1.3: 增加契约一致性与错误语义测试

- [x] Task 2: 打通转账、质押、治理端到端主流程
  - [x] SubTask 2.1: 完成三条主流程页面接入与状态展示
  - [x] SubTask 2.2: 完成链端交互联调与异常处理
  - [x] SubTask 2.3: 补充主流程集成测试

- [x] Task 3: 建立发布就绪门禁流水线
  - [x] SubTask 3.1: 增加 E2E 与回归门禁命令
  - [x] SubTask 3.2: 增加性能基线与回滚演练检查
  - [x] SubTask 3.3: 产出门禁汇总报告与失败明细

- [x] Task 4: 生成发布候选并完成验收归档
  - [x] SubTask 4.1: 生成版本化 RC 包与变更摘要
  - [x] SubTask 4.2: 输出发布验收报告与风险清单
  - [x] SubTask 4.3: 回填执行任务状态与里程碑文档

# Task Dependencies
- [Task 2] depends on [Task 1]
- [Task 3] depends on [Task 2]
- [Task 4] depends on [Task 3]
