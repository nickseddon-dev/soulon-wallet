# Soulon Wallet 修复与开发计划

> 生成时间: 2026-03-24
> 最后更新: 2026-03-24 (全部任务完成)
> 项目路径: /root/soulon-wallet/wallet-app-flutter/
> 代码规模: 101 个 Dart 文件, ~19500 行总代码
> 路由数量: 79 条 (WalletRoutes, 含 /search)
> Store 文件: 15 个 (state/), 4253 行

---

## 一、已完成任务清单

| 编号 | 任务 | 状态 |
|------|------|------|
| F1.1 | PIN 摘要算法替换为 SHA-256 | DONE — security_confirm_store.dart 已使用 `package:crypto/crypto.dart` 的 sha256 |
| F1.3 | React 会话安全加固 | DONE |
| F2.1 | 拼写错误修复 | DONE |
| 3.3  | 密钥管理模块 | DONE — crypto/ 目录 5 个文件 533 行 |
| -    | 创建项目根 README.md | DONE |
| F2.2 | 大型 Store 文件拆分 | DONE — 3 文件拆为 7 模块 + 3 barrel export |
| 3.2  | Flutter DI (get_it) | DONE — di/service_locator.dart, 12 个 Store 注册 |
| 3.1  | go_router 路由重构 | DONE — app/router_config.dart, 79 条声明式路由 |
| D1.4 | Flutter 全局搜索页 | DONE — search_store.dart + global_search_page.dart |
| F1.3 | React 会话安全加固 | DONE |
| F2.1 | 拼写错误修复 | DONE |
| 3.3  | 密钥管理模块 | DONE — crypto/ 目录 5 个文件 533 行 (address_codec, hd_key_derivation, keystore_manager, mnemonic_generator, signer) |
| -    | 创建项目根 README.md | DONE |

---

## 二、待执行任务 (按优先级排序)

### 任务 F2.2: 拆分大型 Store 文件 [高优先级]

**当前状态**: 部分完成 — `security_interop_demo_store.dart` 已变成 barrel export

**问题分析**:
3 个 Store 文件过大，违反单一职责原则，难以维护和测试:

| 文件 | 行数 | 包含的类 | 职责混合 |
|------|------|----------|----------|
| `interop_demo_store.dart` | 957 行 | 12 个类 + 3 个枚举 | Staking + Governance + IBC 三个完全独立的领域 |
| `notification_multisig_demo_store.dart` | 881 行 | 14 个类 + 2 个枚举 + 1 个 typedef | Notification Center + Multisig Workbench 两个独立领域 |
| `transaction_demo_store.dart` | 820 行 | 14 个类 + 2 个枚举 | Transaction 模型/仓库/用例 + TransferFormDraft + TransactionDemoStore |

**拆分方案**:

#### interop_demo_store.dart (957L) → 3 个文件

1. **`state/staking_store.dart`** (~250 行)
   - 枚举: `StakeActionType`
   - 模型: `StakeFlowResult`, `StakeFlowState`, `StakeExecutionSnapshot`
   - 抽象: `StakeGovernanceRepository`
   - 用例: `StakeGovernanceUseCase`
   - 仓库: `ChainStakeGovernanceRepository`
   - Store: `StakeDemoStore`
   - 依赖: chain_api_client, chain_api_contract, wallet_runtime_config, api_error_mapper, security_interop_demo_store

2. **`state/governance_store.dart`** (~200 行)
   - 枚举: `GovernanceVoteOption`
   - 模型: `GovernanceProposal`, `GovernanceVoteResult`, `GovernanceVoteState`
   - Store: `GovernanceDemoStore`
   - 依赖: 复用 staking_store.dart 中的 `StakeGovernanceUseCase` (共享 repository)

3. **`state/ibc_store.dart`** (~250 行)
   - 枚举: `IbcPacketStep`
   - 模型: `IbcChannelItem`, `IbcPacketResult`, `IbcTransferState`
   - Store: `IbcDemoStore`
   - 依赖: chain_api_client, chain_api_contract, wallet_runtime_config, dapp_interop_store

#### notification_multisig_demo_store.dart (881L) → 2 个文件

4. **`state/notification_store.dart`** (~210 行)
   - 枚举: `NotificationCategory`
   - 模型: `NotificationItem`, `NotificationCenterState`
   - Store: `NotificationCenterStore`
   - 无外部 Store 依赖

5. **`state/multisig_store.dart`** (~470 行)
   - 枚举: `MultisigTaskStatus`
   - 模型: `OfflineSignatureEntry`, `MultisigTask`, `MultisigOnChainReceipt`, `MultisigWorkbenchState`
   - typedef: `MultisigTaskSubmitter`
   - Store: `MultisigWorkbenchStore`
   - 依赖: chain_api_client, chain_api_contract, wallet_runtime_config, api_error_mapper

#### transaction_demo_store.dart (820L) → 2 个文件

6. **`state/transaction_models.dart`** (~220 行)
   - 枚举: `AssetProtocol`, `ExportFormat`
   - 模型: `TransferFormDraft`, `TransferFormDraftBridge`, `AssetBalanceItem`, `FeeTierSuggestion`, `BuildResult`, `SimulationResult`, `SignResult`, `BroadcastResult`, `HistoryRecord`, `ExportResult`, `TransferExecutionSnapshot`
   - 抽象: `TransactionRepository`
   - 用例: `TransactionUseCase`

7. **`state/transaction_store.dart`** (~400 行)
   - 仓库: `ChainTransactionRepository`
   - 模型: `TransactionDemoState`
   - Store: `TransactionDemoStore`
   - 依赖: transaction_models.dart, chain_api_client, chain_api_contract, wallet_runtime_config, api_error_mapper

**迁移注意**:
- 原 `interop_demo_store.dart` 保留为 barrel export, 导出新的 3 个文件
- 原 `notification_multisig_demo_store.dart` 保留为 barrel export, 导出新的 2 个文件
- 原 `transaction_demo_store.dart` 保留为 barrel export, 导出新的 2 个文件
- 所有页面 import 不需要修改 (barrel export 保持兼容)
- 测试文件的 import 也通过 barrel export 保持兼容

**重复代码消除**:
- `_asList`, `_asMap`, `_toInt` 在 3 个文件中重复出现 (interop 2处, transaction 1处)
- `_digest` 方法在 4 个文件中独立实现, 使用不同的乘数 (29, 31, 33, 37, 41)
- 建议: 在 `lib/api/` 下新增 `json_helpers.dart` 提取公共解析方法
- 注意: `_digest` 不能统一，因为各处使用不同乘数以生成不同哈希，统一会破坏现有数据

---

### 任务 3.2: Flutter 依赖注入引入 get_it [中优先级]

**当前状态**: 未开始

**问题分析**:
- 所有 Store 使用 `static final instance = ...` 单例模式
- `ChainApiClient` 在 6+ 个 Store 中重复创建
- `WalletRuntimeConfig` 被 hard-reference, 无法测试替换
- 测试中需要 `.test()` 工厂方法绕过单例

**涉及的单例实例** (需注册到 get_it):

| 类 | 当前位置 | 依赖 |
|----|----------|------|
| `ChainApiClient` | 各 Store 内部创建 | WalletRuntimeConfig |
| `SecurityConfirmStore` | security_confirm_store.dart:279 | HardwareKeyStoreFacade, BiometricVerifier, SecurityAuditRepository |
| `StakeDemoStore` | interop_demo_store.dart:432 | StakeGovernanceUseCase |
| `GovernanceDemoStore` | interop_demo_store.dart:594 | StakeGovernanceUseCase |
| `IbcDemoStore` | interop_demo_store.dart:748 | ChainApiClient |
| `TransactionDemoStore` | transaction_demo_store.dart:662 | TransactionUseCase |
| `DappInteropStore` | dapp_interop_store.dart:144 | ChainApiClient |
| `WalletConnectStore` | walletconnect_store.dart:153 | ChainApiClient |
| `NotificationCenterStore` | notification_multisig_demo_store.dart:120 | 无 |
| `MultisigWorkbenchStore` | notification_multisig_demo_store.dart:388 | MultisigTaskSubmitter |
| `IdentityDemoStore` | identity_demo_store.dart:66 | 无 |
| `TransferFormDraftBridge` | transaction_demo_store.dart:34 | 无 |

**实施步骤**:

1. **添加依赖**: `pubspec.yaml` 添加 `get_it: ^8.0.3`
2. **创建 `lib/di/service_locator.dart`**:
   ```dart
   import 'package:get_it/get_it.dart';
   final sl = GetIt.instance;
   void setupServiceLocator() {
     // 基础设施
     sl.registerLazySingleton<ChainApiClient>(() => ChainApiClient(...));
     // 仓库
     sl.registerLazySingleton<TransactionRepository>(() => ChainTransactionRepository(...));
     sl.registerLazySingleton<StakeGovernanceRepository>(() => ChainStakeGovernanceRepository(...));
     // 用例
     sl.registerLazySingleton<TransactionUseCase>(() => TransactionUseCase(sl()));
     sl.registerLazySingleton<StakeGovernanceUseCase>(() => StakeGovernanceUseCase(sl()));
     // Store
     sl.registerLazySingleton<TransactionDemoStore>(() => TransactionDemoStore(sl()));
     // ... 其他 Store
   }
   ```
3. **修改 `main.dart`**: 调用 `setupServiceLocator()` 在 `runApp()` 之前
4. **逐步替换各 Store 的 `static final instance`**:
   - 保留 `instance` getter 作为过渡 → `static T get instance => sl<T>()`
   - 新代码使用 `sl<StoreName>()` 获取
5. **页面中**: 通过 `sl<StoreName>()` 替代 `StoreName.instance`

**风险**:
- 需要处理循环依赖 (DappInteropStore ↔ IbcDemoStore 的 `bindTrackedTx` 调用)
- 测试中使用 `sl.registerSingleton<T>(mockInstance)` 替代 `.test()` 工厂

---

### 任务 3.1: Flutter 路由重构为 go_router [中优先级]

**前置依赖**: 任务 3.2 (get_it DI)

**当前状态**: 未开始

**问题分析**:
- `app_router.dart` (377 行) 使用 `onGenerateRoute` + 巨大 switch-case
- 78 条路由全在一个 switch 中，不支持 deep link / web URL
- 嵌套路由 (settings, onboarding, import) 需要重复包裹 Provider
- 无路由守卫 (auth guard)

**实施步骤**:

1. **添加依赖**: `pubspec.yaml` 添加 `go_router: ^14.8.1`
2. **创建 `lib/app/router_config.dart`**:
   - 使用 `GoRouter` 声明式路由
   - 分组嵌套路由: `/ovd/`, `/replica/`, `/interop/`, `/asset/`, `/security/`, `/multisig/`, `/notify/`
   - 使用 `ShellRoute` 处理 Provider 包裹 (settings, onboarding, import)
3. **路由分组文件** (可选，若 router_config 过长):
   - `lib/app/routes/replica_routes.dart`
   - `lib/app/routes/settings_routes.dart`
   - `lib/app/routes/interop_routes.dart`
4. **修改 `wallet_app.dart`**: `MaterialApp.router()` 替代 `MaterialApp()`
5. **添加路由守卫**: `redirect` 中检查登录状态
6. **迁移页面导航**: `context.go()` / `context.push()` 替代 `Navigator.pushNamed()`
7. **动画保持**: 将 `fadeSlideRoute` / `fadeScaleRoute` 迁移为 `CustomTransitionPage`

**迁移策略**: 分批迁移
- Phase 1: 核心路由 (ovd auth + replica home) 切到 go_router
- Phase 2: 设置页路由组 (30+ 条 settings 路由)
- Phase 3: 功能页路由 (interop, asset, security, multisig)

---

### 任务 D1.4: Flutter 全局搜索页 [低优先级]

**前置依赖**: 任务 3.1 (go_router)

**当前状态**: 未开始

**实施步骤**:

1. **创建 `lib/state/search_store.dart`**:
   - 搜索范围: tokens (AssetBalanceItem), transactions (HistoryRecord), DApps (WalletConnectSession), settings routes
   - 状态: query, results[], loading, recentSearches[]
   - 方法: `search(query)`, `clearRecent()`, `addRecent(query)`

2. **创建 `lib/pages/global_search_page.dart`**:
   - UI: 顶部搜索栏 + 分类结果列表
   - 分类: Tokens, Transactions, DApps, Settings
   - 空状态/无结果提示
   - 搜索历史

3. **注册路由**: `/search` → GlobalSearchPage
4. **入口**: 在 ReplicaMobileHomePage 添加搜索图标

---

## 三、代码质量问题清单

### 3.1 重复代码 (跨文件)

| 模式 | 出现次数 | 文件 |
|------|----------|------|
| `_asList(Object?)` | 3 | interop (2处), transaction |
| `_asMap(Object?)` | 4 | interop (2处), transaction, dapp_interop |
| `_toInt(Object?)` | 4 | interop (2处), transaction, notification_multisig |
| `_digest(String)` | 5 | interop (2处), notification_multisig, transaction, dapp_interop |
| `ChainApiClient(...)` 构造 | 6 | 各 Store 的 static instance |

**建议**: Store 拆分时提取 `lib/api/json_helpers.dart`:
```dart
extension JsonSafeAccess on Object? {
  List<dynamic> asList() => this is List<dynamic> ? this as List<dynamic> : const [];
  Map<String, dynamic> asMap() => this is Map<String, dynamic> ? this as Map<String, dynamic> : const {};
  int toSafeInt() { ... }
}
```

### 3.2 设计问题

| 问题 | 位置 | 影响 |
|------|------|------|
| Store 之间硬耦合 | `IbcDemoStore.transfer()` 调用 `DappInteropStore.instance.bindTrackedTx()` | 测试困难, 循环依赖 |
| `TransferFormDraftBridge` 被 DappInteropStore 调用 | dapp_interop_store.dart:234 | 跨 Store 直接引用 |
| 所有 Store 用 singleton 模式 | 各 Store 的 `static final instance` | 测试需要特殊 `.test()` 工厂 |
| IbcPacketResult 不可变但需要逐步更新 step | interop_demo_store.dart:830-882 | 大量样板代码创建新实例 |

### 3.3 潜在 Bug

| 问题 | 位置 | 严重度 |
|------|------|--------|
| IbcDemoStore `_autoRefreshTimer` 无 dispose | 无生命周期管理 | 低 — 单例不会被回收 |
| `DappInteropStore._autoRefreshTimer` 同上 | dapp_interop_store.dart:153 | 低 |
| `NotificationCenterStore._timer` 无自动停止 | notification_multisig_demo_store.dart:122 | 低 |
| `_digest` 用简单乘法哈希而非 SHA-256 | interop, notification_multisig, transaction 的非安全 digest | 低 — 非安全用途 |

---

## 四、文件依赖关系图

```
main.dart
  └── app/wallet_app.dart
        ├── app/app_router.dart (377L, 78 routes)
        │     ├── pages/* (39 page files)
        │     └── motion/route_motion.dart
        └── theme/app_theme.dart

state/ (8 files, 4039 lines)
  ├── security_confirm_store.dart (488L) — PIN/Biometric/Audit [OK, 不拆]
  ├── identity_demo_store.dart (256L) — Mnemonic/HD/Watch [OK, 不拆]
  ├── walletconnect_store.dart (280L) — WC Session [OK, 不拆]
  ├── dapp_interop_store.dart (351L) — SuggestChain/BIP21/Reorg [OK, 不拆]
  ├── security_interop_demo_store.dart (6L) — barrel export [已拆完]
  ├── interop_demo_store.dart (957L) — 需拆 → staking + governance + ibc
  ├── notification_multisig_demo_store.dart (881L) — 需拆 → notification + multisig
  └── transaction_demo_store.dart (820L) — 需拆 → tx_models + tx_store

api/ (3 files)
  ├── chain_api_client.dart
  ├── chain_api_contract.dart
  └── api_error_mapper.dart

crypto/ (5 files, 533 lines) — 已完成 (3.3)
  ├── address_codec.dart (154L)
  ├── keystore_manager.dart (105L)
  ├── signer.dart (103L)
  ├── mnemonic_generator.dart (91L)
  └── hd_key_derivation.dart (80L)

config/
  └── wallet_runtime_config.dart
```

---

## 五、执行顺序

```
Step 1: F2.2 Store 拆分 (无外部依赖, 纯重构)
  ├── 1a. 拆 interop_demo_store → staking + governance + ibc
  ├── 1b. 拆 notification_multisig_demo_store → notification + multisig
  ├── 1c. 拆 transaction_demo_store → tx_models + tx_store
  ├── 1d. 提取 json_helpers.dart 公共方法
  └── 1e. 验证: flutter analyze + 全部测试通过

Step 2: 3.2 get_it DI
  ├── 2a. 添加 get_it 依赖
  ├── 2b. 创建 service_locator.dart
  ├── 2c. 注册所有服务和 Store
  ├── 2d. 修改 main.dart
  ├── 2e. 逐步替换各 Store singleton
  └── 2f. 验证: flutter analyze + 全部测试通过

Step 3: 3.1 go_router 路由重构
  ├── 3a. 添加 go_router 依赖
  ├── 3b. 创建 router_config.dart (声明式路由)
  ├── 3c. 修改 wallet_app.dart → MaterialApp.router
  ├── 3d. 迁移页面导航调用
  ├── 3e. 添加 auth redirect guard
  └── 3f. 验证: flutter analyze + 全部测试通过

Step 4: D1.4 全局搜索页
  ├── 4a. 创建 search_store.dart
  ├── 4b. 创建 global_search_page.dart
  ├── 4c. 注册路由和 DI
  └── 4d. 验证: flutter analyze + 编写测试
```

---

## 六、pubspec.yaml 变更汇总

```yaml
dependencies:
  # 现有
  flutter: { sdk: flutter }
  flutter_svg: ^2.2.4
  qr_flutter: ^4.1.0
  flutter_tilt: ^3.2.1
  crypto: ^3.0.6
  # 新增
  get_it: ^8.0.3       # Step 2: DI
  go_router: ^14.8.1    # Step 3: Routing
```

---

## 七、测试矩阵

| 测试文件 | 覆盖范围 | 与拆分的关系 |
|----------|----------|-------------|
| security_confirm_store_test.dart | PIN/Biometric/Audit | 无影响 (文件不拆) |
| task3_interop_realflow_test.dart | Staking/Governance/IBC 全流程 | 通过 barrel export 兼容 |
| task3_replica_mobile_ui_test.dart | Mobile UI | 无影响 |
| task4_multisig_workflow_test.dart | 多签审批/离线导入/链上提交 | 通过 barrel export 兼容 |
| task7_contract_and_error_test.dart | API 合约/错误处理 | 无影响 |
| task7_page_interaction_test.dart | 页面交互 | 无影响 |
| task7_replica_motion_regression_test.dart | 动画回归 | 无影响 |
| task8_create_wallet_and_swap_test.dart | 建钱包/兑换 | 无影响 |
| motion_tokens_test.dart | Motion tokens | 无影响 |
| wallet_app_smoke_test.dart | 冒烟测试 | 路由重构后需更新 |
| widget_test.dart | Widget 基础 | 无影响 |
