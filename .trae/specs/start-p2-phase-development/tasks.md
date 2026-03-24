# Tasks
- [x] Task 1: 建立P2阶段执行基线并冻结首批范围
  - [x] SubTask 1.1: 对齐 P2 目标、验收标准与门禁命令
  - [x] SubTask 1.2: 明确首批仅交付 BIP-21 生成与解析能力
  - [x] SubTask 1.3: 输出跨项目依赖与风险清单

- [x] Task 2: 在 SDK 实现 BIP-21 生成与解析能力
  - [x] SubTask 2.1: 增加 URI 生成函数与参数校验
  - [x] SubTask 2.2: 增加 URI 解析函数与错误模型
  - [x] SubTask 2.3: 补充单元测试覆盖成功与失败场景

- [x] Task 3: 在 wallet-app 接入 BIP-21 输入输出流程
  - [x] SubTask 3.1: 新增支付 URI 生成与展示入口
  - [x] SubTask 3.2: 新增 URI 粘贴/扫码解析并回填表单
  - [x] SubTask 3.3: 接入统一错误提示并保持原流程兼容

- [x] Task 4: 执行联调验证并更新验收记录
  - [x] SubTask 4.1: 执行 wallet-app 与 soulon-wallet 相关测试命令
  - [x] SubTask 4.2: 验证 SDK 与前端输出一致性
  - [x] SubTask 4.3: 更新 P2 启动阶段验证结论

# Task Dependencies
- [Task 2] depends on [Task 1]
- [Task 3] depends on [Task 2]
- [Task 4] depends on [Task 2]
- [Task 4] depends on [Task 3]
