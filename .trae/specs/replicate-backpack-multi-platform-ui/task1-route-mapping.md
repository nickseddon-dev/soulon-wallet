# Task1 三端页面与路由对照表

## 目标与范围
- 目标：建立 Flutter 移动端、Web 端、扩展端三端页面与路由对照基线，作为后续 UI 复刻输入。
- 范围：仅定义信息架构与导航路径，不改动业务规则、后端契约、风控策略。

## 三端路由映射（核心流程）

| 业务域 | Flutter 移动端 | Web 端（wallet-app） | 扩展端（wallet-extension） | 说明 |
|---|---|---|---|---|
| 首页容器 | `/` | `/` | `/popup/home` | 三端统一“资产总览入口”语义 |
| 资产看板 | `/asset/dashboard` | `/state` | `/popup/assets` | 统一资产状态视图 |
| 交易历史 | `/asset/history-export` | `/events` | `/popup/activity` | 统一历史与活动流入口 |
| 通知中心 | `/notify/center` | `/notifications` | `/popup/notifications` | 统一通知聚合入口 |
| 通知详情 | `/notify/detail` | `/events/:eventId` | `/popup/notifications/:notificationId` | 统一详情跳转模式 |
| 发送流程 | `/asset/tx-flow` | `/transfer`（规划） | `/popup/send` | 统一发送主流程入口 |
| 接收流程 | `/security/suggestchain-scan-reorg`（扫码入口） | `/receive`（规划） | `/popup/receive` | 统一收款与扫码入口 |
| 登录/会话 | `/security/pin-biometric` | `/login` | `/popup/unlock` | 统一安全解锁流程 |
| 设置中心 | `/security/walletconnect` | `/settings`（规划） | `/popup/settings` | 统一设置与连接管理 |
| 搜索入口 | `/asset/dashboard`（页内搜索） | `/events`（筛选） | `/popup/search` | 统一“列表+筛选”交互语义 |

## 第一阶段不改动项
- 业务规则：交易校验、签名流程、风控判定逻辑保持现状。
- 后端契约：API 路径、响应字段、错误码语义保持现状。
- 安全策略：认证强度、鉴权流程、密钥管理策略保持现状。
- 数据模型：索引事件结构、账户结构、交易结构保持现状。

## 输出约束
- 本表仅作为“复刻阶段结构基线”。
- 后续若新增页面，必须先补充路由映射再进入实现。
