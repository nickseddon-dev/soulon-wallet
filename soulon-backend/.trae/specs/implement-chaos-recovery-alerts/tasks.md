# Tasks
- [x] Task 1: 扩展 Chaos 报告建议引擎：基于场景失败率与耗时生成风险等级和恢复建议。
  - [x] SubTask 1.1: 为场景聚合结果增加风险分级逻辑
  - [x] SubTask 1.2: 输出对应恢复建议文案与结构化字段
- [x] Task 2: 增加阈值建议计算：基于历史趋势计算错误率、耗时、连续失败建议阈值。
  - [x] SubTask 2.1: 设计历史窗口基线与退化判定规则
  - [x] SubTask 2.2: 将阈值建议写入报告摘要
- [x] Task 3: 生成双格式报告：输出 Markdown 与 JSON 两种报告产物。
  - [x] SubTask 3.1: 设计 JSON 报告结构（overview/scenario/trend/recommendations）
  - [x] SubTask 3.2: 保持 Markdown 与 JSON 内容一致
- [x] Task 4: 更新 CI 与文档：在工作流中展示建议摘要并更新 README 使用说明。
  - [x] SubTask 4.1: 调整 chaos 工作流参数与产物说明
  - [x] SubTask 4.2: 更新 README 中报告结构与解读说明
- [x] Task 5: 完成验证：执行脚本语法校验与 `go test ./...`，确认无回归。
  - [x] SubTask 5.1: 校验 PowerShell 脚本可解析
  - [x] SubTask 5.2: 执行全量测试并记录结果

# Task Dependencies
- Task 2 depends on Task 1
- Task 3 depends on Task 1 and Task 2
- Task 4 depends on Task 3
- Task 5 depends on Task 4
