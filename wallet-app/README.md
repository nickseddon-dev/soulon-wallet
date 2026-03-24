# Wallet App

## 本地开发

1. 复制环境模板：
   - `copy .env.example .env`
2. 安装依赖：
   - `npm install`
3. 启动开发服务器：
   - `npm run start:dev`

## 可用脚本

- `npm run dev`：启动 Vite 开发模式
- `npm run start:dev`：通过 PowerShell 启动脚本运行开发环境
- `npm run lint`：执行 ESLint
- `npm run typecheck`：执行 TypeScript 类型检查
- `npm run build`：构建产物
- `npm run validate`：串行执行 lint、typecheck、build

## 当前能力

- 已创建钱包主线基础工程骨架
- 已接入基础路由，首页为占位页面
- 已实现统一 API 客户端与标准错误模型
