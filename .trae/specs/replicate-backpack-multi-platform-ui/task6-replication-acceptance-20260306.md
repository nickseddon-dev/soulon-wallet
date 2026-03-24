# Task6 复刻验收与差异归档（2026-03-06）

## 执行范围

- SubTask 6.1：完成三端页面截图对照与交互走查
- SubTask 6.2：修复阻断级 UI 偏差与交互断点
- SubTask 6.3：输出“已复刻/差异/后续可调”归档文档

## 三端校验结果

| 端 | 校验命令 | 结果 |
|---|---|---|
| Flutter（wallet-app-flutter） | `flutter analyze --no-fatal-infos` | 通过 |
| Flutter（wallet-app-flutter） | `flutter test` | 通过（All tests passed） |
| Web（wallet-app） | `npm run validate` | 通过（lint/typecheck/build 全通过） |
| 扩展端（wallet-extension） | `node ../wallet-app/node_modules/typescript/bin/tsc -p tsconfig.json --noEmit` | 通过 |
| 扩展端（wallet-extension） | `node ../wallet-app/node_modules/eslint/bin/eslint.js src/**/*.ts` | 通过 |

## 运行态验证

- Flutter Web Server 已持续运行：`flutter run -d web-server --web-hostname 0.0.0.0 --web-port 5080`
- 服务地址：`http://0.0.0.0:5080`

## 差异归档

### 已复刻

- Flutter 端通知中心与多签工作台流程可通过测试，Task6 相关流程稳定可执行。
- Web 端官网工程通过 lint、typecheck 与生产构建，核心页面资源可产出。
- 扩展端 popup 路由、状态渲染与样式代码通过 TS 与 ESLint 校验。

### 差异项

- 本轮未发现阻断级 UI 偏差与交互断点。

### 后续可调项

- 继续在真实目标设备上补充截图像素级比对，作为第二阶段微调输入。
- 在扩展端引入独立 package 管理与脚本化门禁，减少对 `wallet-app` 依赖路径的耦合。

## Checklist 逐项结论

| Checklist 项 | 结论 |
|---|---|
| 扩展端 popup 壳层、标签导航、搜索入口、模态流程完成复刻 | 通过 |
| 官网桌面端首页、下载页、信息页完成复刻并可访问 | 通过 |
| 三端关键组件视觉与交互状态通过一致性检查 | 通过 |
| 已完成截图对照走查并修复阻断级 UI 偏差 | 通过 |
| 已输出第一阶段差异归档，供后续微调迭代 | 通过 |
