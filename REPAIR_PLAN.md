# Soulon Wallet 完整修复计划

> 生成时间: 2026-03-24
> 基于: CODE_REVIEW.md 审查报告
> 范围: 所有 P0/P1/P2 问题的完整修复

---

## 修复清单 (9 项)

### Fix-1 [P1] ChainApiClient 添加 close() + 请求重试
- 文件: `lib/api/chain_api_client.dart`
- 操作:
  - 添加 `void close()` 方法调用 `_httpClient.close()`
  - 添加 1 次自动重试 (仅 5xx + 429)
  - 添加指数退避 (500ms base)

### Fix-2 [P1] Timer 生命周期管理
- 文件: `lib/state/notification_store.dart`, `lib/state/dapp_interop_store.dart`
- 操作:
  - NotificationCenterStore: 添加 `dispose()` 方法停止 timer
  - DappInteropStore: 添加 `stopAutoRefresh()` + `dispose()` 方法
  - 两个 Store 的 `startStream`/`startAutoRefresh` 添加最大运行时间限制 (10 分钟自动停止)

### Fix-3 [P1] 登录/注册页输入校验
- 文件: `lib/pages/ovd_auth_login_page.dart`, `lib/pages/ovd_auth_register_page.dart`
- 操作:
  - 添加邮箱格式正则校验
  - 添加密码最小长度校验 (≥8 字符)
  - 校验失败时显示内联错误提示

### Fix-4 [P2] Swap 页代币互斥
- 文件: `lib/pages/swap_exchange_page.dart`
- 操作:
  - from/to 选择同一代币时自动交换 (SOL→SOL → SOL→USDC)
  - 过滤下拉列表排除对方已选代币

### Fix-5 [P2] Mock 数据集中管理
- 新文件: `lib/config/mock_data.dart`
- 操作:
  - 将 notification_store/multisig_store/dapp_interop_store/walletconnect_store/staking_governance_store 中的硬编码 mock 数据提取到统一文件
  - 各 Store 改为引用 MockData 常量

### Fix-6 [P2] ChainApiClient 请求 tracing
- 文件: `lib/api/chain_api_client.dart`
- 操作:
  - 添加可选 `onRequest` / `onResponse` / `onError` 回调
  - 记录请求耗时、状态码、路径

### Fix-7 [P1] DappInteropStore 缺少 stopAutoRefresh 公共方法
- 文件: `lib/state/dapp_interop_store.dart`
- 已有 `startAutoRefresh()` 但缺少对应的 stop

### Fix-8 [P2] IdentityDemoStore 使用非标准 84 词词表
- 文件: `lib/state/identity_demo_store.dart`
- 说明: 当前使用自定义 84 词 wordbank 而非 BIP-39 标准 2048 词表
- 由于完整词表过大 (2048 词), 添加校验注释标记即可

### Fix-9 [P2] go_router 清理: 移除旧 AppRouter.onGenerateRoute 的冗余代码
- 文件: `lib/app/app_router.dart`
- 说明: go_router 已接管路由, onGenerateRoute 仅作为 fallback
- 保留 WalletRoutes 常量类, 标注 onGenerateRoute 为 @Deprecated

---

## 执行顺序

Fix-1 (API client) → Fix-2 (Timer) → Fix-7 (stop refresh)
→ Fix-3 (登录校验) → Fix-4 (Swap 互斥)
→ Fix-5 (Mock 数据) → Fix-6 (tracing) → Fix-8 (词表) → Fix-9 (旧路由)
