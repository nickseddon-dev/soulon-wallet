# wallet-extension

浏览器扩展端 UI 复刻模块（已覆盖 Task4 popup 壳层、标签导航、搜索入口、模态流程与核心样式交互）。

## 目录
- `src/popup/routes.ts`：popup 路由定义
- `src/popup/index.html`：popup 入口骨架
- `src/popup/main.ts`：popup 页面状态、标签导航、搜索过滤、发送模态三步流程
- `src/global.d.ts`：样式模块类型声明
- `src/styles/design-tokens.css`：统一设计令牌
- `src/styles/base.css`：基础样式接入层
- `src/styles/popup.css`：popup 壳层与页面交互样式
- `tsconfig.json`：扩展端 typecheck 配置
