# Tasks
- [x] Task 1: 克隆并盘点上游 Backpack 仓库结构
  - [x] SubTask 1.1: 在 D 盘拉取上游仓库并确认可访问目录
  - [x] SubTask 1.2: 统计关键模块与前端入口（app-extension/web/packages）
  - [x] SubTask 1.3: 产出钱包核心流程页面清单（创建、导入、兑换、设置、安全）

- [x] Task 2: 建立上游与本地三端页面映射矩阵
  - [x] SubTask 2.1: 梳理本地 Flutter/Web/扩展当前路由与页面清单
  - [x] SubTask 2.2: 生成“上游页面 → 本地页面”映射与状态标注（已完成/部分/缺失）
  - [x] SubTask 2.3: 识别未连线路由与不可达入口

- [x] Task 3: 输出缺口清单并确定优先级
  - [x] SubTask 3.1: 输出页面级缺口（缺页、缺状态、缺交互）
  - [x] SubTask 3.2: 输出流程级缺口（创建钱包、兑换、导入等）
  - [x] SubTask 3.3: 确定实现顺序（P0/P1/P2）与目标文件

- [x] Task 4: 实现 P0 缺口页面与路由
  - [x] SubTask 4.1: 实现钱包创建流程页面并接入导航入口
  - [x] SubTask 4.2: 实现兑换流程页面并接入导航入口
  - [x] SubTask 4.3: 补齐关键状态（空态/错误态/成功态）与基础交互

- [x] Task 5: 实现 P1 缺口页面并统一样式
  - [x] SubTask 5.1: 补齐导入钱包与资产详情相关页面
  - [x] SubTask 5.2: 对齐扩展端风格令牌与组件样式
  - [x] SubTask 5.3: 修复跨页导航与回退路径

- [x] Task 6: 回归验证与验收归档
  - [x] SubTask 6.1: 更新/新增页面测试断言
  - [x] SubTask 6.2: 执行 flutter analyze 与 flutter test
  - [x] SubTask 6.3: 输出“已完成/待补齐”最终验收清单

# Task Dependencies
- [Task 2] depends on [Task 1]
- [Task 3] depends on [Task 2]
- [Task 4] depends on [Task 3]
- [Task 5] depends on [Task 4]
- [Task 6] depends on [Task 5]
