# Tasks
- [x] Task 1: 实现钱包测试网 E2E 联调脚本与统一入口。
  - [x] SubTask 1.1: 新增 E2E 脚本覆盖账户读取、转账提交、回执确认
  - [x] SubTask 1.2: 在 package 脚本与文档中暴露统一执行命令
- [x] Task 2: 实现链端测试网启动与运维脚本。
  - [x] SubTask 2.1: 新增测试网启动脚本并支持 DryRun/在线模式
  - [x] SubTask 2.2: 新增运维脚本支持状态、日志、停止操作
- [x] Task 3: 集成一体化执行与文档说明。
  - [x] SubTask 3.1: 更新 deploy 入口串联 W2 与 D2
  - [x] SubTask 3.2: 更新 README 使用说明与注意事项
- [x] Task 4: 完成门禁复验并更新上线判定。
  - [x] SubTask 4.1: 执行前端/后端/集成脚本复验
  - [x] SubTask 4.2: 勾选 tasks/checklist 并输出上线结论

# Task Dependencies
- Task 2 depends on Task 1
- Task 3 depends on Task 1 and Task 2
- Task 4 depends on Task 3
