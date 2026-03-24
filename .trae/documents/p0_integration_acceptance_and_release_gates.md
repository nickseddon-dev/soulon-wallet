# Soulon P0 联调验收清单与发布门禁

更新日期：2026-03-04
适用阶段：P0
适用范围：`soulon-deep-chain`、`soulon-backend`、`wallet-app`、`soulon-wallet`、`deploy`

## 1. 验收准入标准

| 编号 | 门禁项 | 验收标准 | 验证方式 | 当前结果 |
|---|---|---|---|---|
| G-01 | P0 需求完备性 | P0 清单任务状态均为“已完成” | 核对执行任务清单与计划文档 | 通过 |
| G-02 | 链端核心能力 | 创世校验通过，demo 交易链路通过 | `go test ./...`、`validate-genesis`、`demo` | 通过 |
| G-03 | 后端服务稳定性 | backend 单测通过，API/Indexer核心链路可用 | `go test ./...` | 通过 |
| G-04 | 前端质量门禁 | lint/typecheck/build 全通过 | `npm run validate` | 通过 |
| G-05 | 钱包 SDK 门禁 | check/build 全通过 | `npm run check`、`npm run build` | 通过 |
| G-06 | 跨项目联调入口 | 部署联调脚本可执行且返回成功 | `deploy/run-deploy-test.ps1`（离线模式） | 通过 |
| G-07 | 响应协议稳定性 | v1/v2 并行兼容，非法版本拒绝 | `go test ./app -v` + `demo -response-version` | 通过 |
| G-08 | 发布文档闭环 | 验收结果与任务状态同步更新 | 本文档 + 任务清单 +功能清单 | 通过 |

## 2. 联调检查项

| 维度 | 检查项 | 结果 | 证据 |
|---|---|---|---|
| 链端 | 创世模板可校验 | 通过 | `config/genesis.template.json` |
| 链端 | 交易路由与模块执行链路可运行 | 通过 | `app/tx.go`、`cmd/soulond/main.go` |
| 后端 | API 健康与事件接口可用 | 通过 | `internal/api/server.go` |
| 前端 | 鉴权守卫与事件页可构建 | 通过 | `src/auth/RequireAuth.tsx`、`src/pages/EventsPage.tsx` |
| 前端 | EventDetail 刷新回源可用 | 通过 | `src/pages/EventDetailPage.tsx` |
| SDK | 客户端、签名、广播链路可构建验证 | 通过 | `src/core/*.ts`、`src/services/*.ts` |
| 端到端 | 顶层部署联调入口可执行 | 通过 | `deploy/run-deploy-test.ps1` |

## 3. 发布阻断条件

- 任一 P0 任务非“已完成”
- 任一门禁命令失败
- 出现未关闭高危安全问题
- 核心链路（链端交易、后端查询、前端主路径、SDK广播）存在阻断缺陷

## 4. 标准验证命令

### 4.1 soulon-deep-chain

```powershell
go test ./...
go run .\cmd\soulond validate-genesis -file .\config\genesis.template.json
go run .\cmd\soulond demo -file .\config\genesis.template.json -response-version v1
go run .\cmd\soulond demo -file .\config\genesis.template.json -response-version v2
```

### 4.2 soulon-backend

```powershell
go test ./...
```

### 4.3 wallet-app

```powershell
npm run validate
```

### 4.4 soulon-wallet

```powershell
npm run check
npm run build
```

### 4.5 顶层联调

```powershell
.\deploy\run-deploy-test.ps1 -Offline
```

## 5. 验收结论模板

| 项目 | 结论 |
|---|---|
| 是否满足 P0 发布门禁 | 满足，可进入 P1 主线开发 |
| 风险与遗留项 | P1 仍需推进 Indexer Backlog 指标真实化与 API 数据源策略统一 |
| 建议动作 | 将本清单纳入每次发版前必填项，新增门禁失败自动阻断 |
