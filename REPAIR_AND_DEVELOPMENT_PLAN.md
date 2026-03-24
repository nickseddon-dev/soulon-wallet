# Soulon Wallet — 完整修复与开发计划

> 生成日期：2026-03-24
> 基线版本：当前 main 分支（P0 验收已通过，P1/P2 进行中）
> 总代码量：~55,000 行（5 个子项目）

---

## 目录

1. [现状诊断总结](#1-现状诊断总结)
2. [修复计划（BugFix / 技术债）](#2-修复计划)
3. [架构升级计划](#3-架构升级计划)
4. [功能开发计划（按优先级）](#4-功能开发计划)
5. [三端路由补齐计划](#5-三端路由补齐计划)
6. [测试与质量计划](#6-测试与质量计划)
7. [部署与运维计划](#7-部署与运维计划)
8. [里程碑与排期建议](#8-里程碑与排期建议)

---

## 1. 现状诊断总结

### 1.1 子项目成熟度评级

| 子项目 | 代码量 | 成熟度 | 评级 |
|--------|--------|--------|------|
| wallet-app-flutter | ~8,000 行 Dart | 路由最完整(78条)，核心流程闭环 | ★★★★☆ |
| soulon-backend | ~3,500 行 Go | PostgreSQL+Kafka+Prometheus，生产级骨架 | ★★★★☆ |
| soulon-deep-chain | ~1,200 行 Go | 纯内存实现，仅 Demo 可用 | ★★☆☆☆ |
| wallet-app (React) | ~3,000 行 TS | 基础页面+认证，功能薄弱 | ★★☆☆☆ |
| wallet-extension | ~1,500 行 TS | 纯 DOM 手写，路由缺口大 | ★★☆☆☆ |

### 1.2 关键问题清单（20 项）

| # | 类别 | 问题 | 严重度 | 子项目 |
|---|------|------|--------|--------|
| 1 | 安全 | PIN 摘要使用自写哈希(fold*131^code)，非密码学安全 | P0 | Flutter |
| 2 | 安全 | WalletConnect 签名使用拼接字符串模拟，未接入真实密钥签名 | P0 | Flutter |
| 3 | 安全 | AuthProvider 会话存储在 localStorage，可被 XSS 窃取 | P1 | React |
| 4 | 架构 | 链节点纯内存实现，无持久化/共识/P2P，不可上线 | P0 | Chain |
| 5 | 架构 | Flutter 78 条路由全在 switch-case 中手动分发 | P1 | Flutter |
| 6 | 架构 | Flutter Store 使用静态单例，无 DI，不利于测试 | P1 | Flutter |
| 7 | 架构 | Extension 纯 DOM 操作，无组件化框架 | P1 | Extension |
| 8 | 功能 | Extension 缺 8 个 P0/P1 路由（Token详情/Activity详情等） | P0 | Extension |
| 9 | 功能 | Mobile 缺 6 个 P0/P1 路由（搜索/Activity详情/Token详情等） | P0 | Flutter |
| 10 | 功能 | React Web 缺少 Privacy/Terms 法务页 | P1 | React |
| 11 | 功能 | React Web 缺少深链浏览入口 `/ul/v1/browse/` | P1 | React |
| 12 | 代码 | 大型 Store 文件超 1000 行（security_interop_demo_store.dart 1178行） | P2 | Flutter |
| 13 | 代码 | SuggestChainRequest 拼写错误: "Overdrive Chian" → "Overdrive Chain" | P2 | Flutter |
| 14 | 代码 | TransferFormDraftBridge 跨 Store 直接引用，耦合过紧 | P2 | Flutter |
| 15 | 国际化 | 错误消息硬编码中文，无 i18n 框架 | P1 | 全部 |
| 16 | 测试 | 链节点模块测试无持久化场景覆盖 | P1 | Chain |
| 17 | 测试 | Extension 零测试覆盖 | P1 | Extension |
| 18 | 测试 | React Web 测试仅覆盖 3-4 个组件 | P1 | React |
| 19 | 运维 | 部署脚本全部为 PowerShell，Linux/CI 不友好 | P1 | Deploy |
| 20 | 文档 | 项目根目录无 README.md | P2 | Root |

---

## 2. 修复计划

### Phase F1: 安全紧急修复（优先级 P0，建议 1 周内完成）

#### F1.1 PIN 摘要算法替换
- **文件**: `wallet-app-flutter/lib/state/security_interop_demo_store.dart`
- **现状**: `_digest()` 使用 `bytes.fold(0, (hash, code) => ((hash * 131) ^ code) & 0x7fffffff)` — 这是字符串哈希，非密码学安全
- **修复方案**:
  ```dart
  // 替换为 SHA-256 + 盐值
  import 'package:crypto/crypto.dart';  // 添加 crypto 依赖

  String _digest(String seed) {
    final bytes = utf8.encode('soulon.wallet.pin.v1:$seed');
    final hash = sha256.convert(bytes);
    return base64Url.encode(hash.bytes).replaceAll('=', '');
  }
  ```
- **依赖变更**: `pubspec.yaml` 添加 `crypto: ^3.0.0`
- **影响范围**: `SecurityConfirmStore._digest()`, `WalletConnectStore._digest()`（两处独立修复）
- **验收标准**:
  - 旧 PIN 不可复用（首次升级需重新设置）
  - 单测验证碰撞率

#### F1.2 WalletConnect 签名链路真实化
- **文件**: `wallet-app-flutter/lib/state/security_interop_demo_store.dart:757-760`
- **现状**: `'$requestId.$_walletAddress.$digest'` 拼接伪签名
- **修复方案**:
  1. 引入 `ed25519` 或 `secp256k1` 签名库
  2. 从 Keystore 读取私钥
  3. 对 challenge 消息执行真实签名
  4. 签名结果传入 confirm API
- **依赖**: 需先完成密钥管理模块（见 3.2）

#### F1.3 React 会话安全加固
- **文件**: `wallet-app/src/auth/AuthContext.tsx`
- **现状**: 会话数据存 `localStorage`，可被 XSS 读取
- **修复方案**:
  1. 迁移至 `sessionStorage`（关闭标签页自动清除）
  2. 添加 HttpOnly cookie 方案（需后端配合）
  3. 会话 token 添加 CSRF 保护
  4. 添加 `Content-Security-Policy` 头

### Phase F2: 代码缺陷修复（优先级 P1-P2，建议 2 周内完成）

#### F2.1 拼写错误修复
- `security_interop_demo_store.dart:951` — `'Overdrive Chian'` → `'Overdrive Chain'`

#### F2.2 Store 文件拆分
- **目标**: 将 1178 行的 `security_interop_demo_store.dart` 拆分为 3 个独立文件：
  ```
  state/
  ├── security_confirm_store.dart      (~350 行, PIN + 生物识别 + 审计)
  ├── walletconnect_store.dart         (~200 行, WC 会话管理)
  └── dapp_interop_store.dart          (~400 行, SuggestChain + BIP21 + Reorg)
  ```
- 同样拆分 `interop_demo_store.dart` (957行) 和 `notification_multisig_demo_store.dart` (881行)

#### F2.3 跨 Store 耦合解除
- **现状**: `DappInteropStore.parseBip21()` 直接调用 `TransferFormDraftBridge.instance`
- **修复**: 改为事件驱动模式
  ```dart
  // 发布事件而非直接调用
  class Bip21ParsedEvent {
    final String address;
    final String amount;
    final String memo;
  }
  // TransactionDemoStore 监听事件并更新自身状态
  ```

#### F2.4 API Client 异常边界补全
- **Flutter `ChainApiClient`**: `_decodeJsonObject` 对空响应返回空 Map 但不区分 204 vs 错误
- **React `ApiClient`**: `request()` 方法末尾的 unreachable `throw` 应改为编译期断言

---

## 3. 架构升级计划

### 3.1 Flutter 路由系统重构

**现状问题**: 78 条命名路由在 377 行 `switch-case` 中分发，新增页面需修改 3 处（路由常量 + switch 分支 + import）。

**目标**: 迁移到声明式路由

**方案**: 引入 `go_router` 包

```yaml
# pubspec.yaml
dependencies:
  go_router: ^14.0.0
```

**实施步骤**:
1. 定义 `GoRouter` 配置，按模块分组（shell route + nested routes）
2. 保留 `WalletRoutes` 路径常量（向后兼容）
3. 使用 `ShellRoute` 实现 Provider 注入（替代 `_withSettingsProvider` 等 wrapper）
4. 添加 redirect 守卫（认证检查、onboarding 完成检查）
5. 逐模块迁移，可分 3 批：
   - 批次 1: replica 系列（onboarding/import/settings/send/receive）
   - 批次 2: 核心功能页（identity/asset/security/interop）
   - 批次 3: 辅助页面（notification/multisig/ovd/showcase）

**预期收益**: 路由定义从 377 行降至 ~120 行，支持 deep linking、类型安全参数

### 3.2 Flutter 依赖注入引入

**现状问题**: Store 使用 `static final instance` 单例，无法替换/mock

**方案**: 引入轻量 DI（`get_it` 或 `provider`）

```yaml
dependencies:
  get_it: ^8.0.0
  injectable: ^2.5.0  # 可选，用于代码生成
```

**实施步骤**:
1. 创建 `lib/di/service_locator.dart`
2. 注册所有 Store 为 lazy singleton
3. 注册 `ChainApiClient` 为 singleton
4. 页面/Widget 通过 `GetIt.I<T>()` 或 Provider 获取依赖
5. 测试中可 `registerSingleton` 覆盖为 mock

### 3.3 密钥管理模块新建

**现状**: 无真实密钥管理，所有签名为模拟

**目标**: 实现生产级 HD 钱包密钥管理

**模块结构**:
```
lib/crypto/
├── mnemonic_generator.dart     # BIP-39 助记词生成与验证
├── hd_key_derivation.dart      # BIP-32/44 密钥派生 (m/44'/118'/0'/0/N)
├── signer.dart                 # secp256k1 签名 (Cosmos SIGN_MODE_DIRECT)
├── address_codec.dart          # Bech32 地址编解码 (soulon1...)
├── keystore_manager.dart       # 加密存储管理 (AES-256-GCM)
└── secure_random.dart          # CSPRNG 封装
```

**依赖**:
```yaml
dependencies:
  bip39: ^1.0.6
  bip32: ^2.0.0
  pointycastle: ^3.9.0
  convert: ^3.1.0
```

### 3.4 链节点 Cosmos SDK 迁移

**现状**: `soulon-deep-chain` 为纯内存实现（无持久化/共识/P2P），仅适合 Demo

**目标**: 迁移至 Cosmos SDK v0.50+ 真实实现

**分阶段实施**:

| 阶段 | 内容 | 工作量 |
|------|------|--------|
| C1 | 初始化 Cosmos SDK 脚手架 (`ignite scaffold chain`) | 1 周 |
| C2 | 迁移 bank/staking/distribution/gov 参数至 SDK 原生模块 | 2 周 |
| C3 | 接入 CometBFT 共识 + 持久化存储 | 1 周 |
| C4 | 实现创世文件生成 + 验证人接入流程 | 1 周 |
| C5 | gRPC/REST 端点对接后端索引器 | 1 周 |

**保留策略**: 当前 `soulon-deep-chain` 保留为 `soulon-deep-chain-sim/`，用于离线单元测试和 CI 快速验证

### 3.5 Extension 框架化升级

**现状**: 637 行纯 DOM 字符串拼接（`innerHTML = renderAppShell(...)` + `bindEvents`），无组件化

**方案选型**: 引入 Preact (3KB) 或 Lit (5KB)

**推荐 Preact** — 与 React 生态兼容，体积最小

```
wallet-extension/src/
├── popup/
│   ├── components/          # Preact 组件
│   │   ├── TabBar.tsx
│   │   ├── TokenList.tsx
│   │   ├── TokenDetail.tsx    # 新增
│   │   ├── ActivityList.tsx
│   │   ├── ActivityDetail.tsx # 新增
│   │   ├── SendFlow.tsx
│   │   └── Settings.tsx
│   ├── store.ts             # 保留现有 store 模式
│   ├── routes.ts            # 保留
│   └── main.tsx             # Preact render 入口
```

---

## 4. 功能开发计划

### Phase D1: P0 核心功能补齐（建议 3 周）

#### D1.1 Extension — Token 详情页
- **路由**: `/popup/tokens/detail`（已定义但未实现）
- **功能**: 代币余额、价格走势、持仓占比、交易记录、发送/接收快捷入口
- **数据源**: 复用 `ChainApiContract` 端点

#### D1.2 Extension — Activity 详情页
- **路由**: `/popup/activity/detail`（已定义但未实现）
- **功能**: 交易哈希、区块高度、时间戳、金额、手续费、状态、区块浏览器链接

#### D1.3 Extension — Collectibles 详情/集合页
- **路由**: `/popup/collectibles/detail`, `/popup/collectibles/collection`
- **功能**: NFT 元数据展示、所属集合、转移操作

#### D1.4 Flutter — 全局搜索页
- **路由**: `/replica/mobile/search`（新增）
- **功能**: 按代币名/地址/交易哈希搜索，联动跳转到资产详情/活动详情
- **实现**: 底部弹出 + 防抖搜索 + 结果分组

#### D1.5 Flutter — Activity 详情页
- **路由**: `/replica/mobile/activity/detail`（新增）
- **功能**: 同 D1.2 Extension 功能对齐

#### D1.6 Flutter — Token 详情页增强
- **现状**: 已有 `replica_asset_detail_page.dart` 但为静态 mock
- **增强**: 接入真实 API 数据、价格图表、交易列表

### Phase D2: P1 功能扩展（建议 4 周）

#### D2.1 React Web — 法务页面
- `/site/privacy` — 隐私政策页
- `/site/terms` — 服务条款页
- 内容可从 Markdown 文件渲染

#### D2.2 React Web — 深链浏览入口
- `/ul/v1/browse/:url` — DApp 浏览器 iframe 容器
- 添加 URL 白名单 + CSP 沙箱

#### D2.3 Extension — 设置深层页族
```
/popup/settings/wallets           # 钱包列表
/popup/settings/wallets/detail    # 钱包详情
/popup/settings/wallets/add       # 添加钱包
/popup/settings/preferences       # 偏好设置
/popup/settings/preferences/rpc   # RPC 连接
/popup/settings/preferences/lang  # 语言
/popup/settings/about             # 关于
```

#### D2.4 Extension — Swap 兑换流程
```
/popup/swap/select   # 选择代币对
/popup/swap/amount   # 输入金额
/popup/swap/review   # 确认交易
/popup/swap/result   # 交易结果
```

#### D2.5 Extension — Stake 质押流程
```
/popup/stake/validators  # 验证人列表
/popup/stake/delegate    # 委托
/popup/stake/rewards     # 奖励
```

#### D2.6 Flutter — Collectibles 详情与集合
- `/replica/mobile/collectibles/detail`
- `/replica/mobile/collectibles/collection`

#### D2.7 Flutter — Swap 流程 Backpack 对齐
- 当前 `swap_exchange_page.dart` (405行) 存在但为独立实现
- 对齐 Backpack 的 Swap Navigator 多屏栈模式

### Phase D3: 增强功能（建议 3 周）

#### D3.1 国际化 (i18n) 系统
- **Flutter**: 使用 `flutter_localizations` + `intl` + ARB 文件
  ```
  lib/l10n/
  ├── app_zh.arb     # 中文（当前默认）
  ├── app_en.arb     # 英文
  └── app_ja.arb     # 日文（可选）
  ```
- **React**: 使用 `react-intl` 或 `i18next`
- **Extension**: 使用 Chrome i18n API (`chrome.i18n.getMessage`)
- **覆盖范围**: 所有硬编码中文字符串（错误消息、UI 文案）

#### D3.2 通知系统实时化
- **现状**: `NotificationMultisigDemoStore` 为 mock 数据
- **目标**: 接入后端 SSE (`/v1/notifications/stream`) 实现实时推送
- **实现**: Flutter 使用 `EventSource` 库，React 使用原生 `EventSource`

#### D3.3 交易历史导出
- **现状**: `transaction_history_export_page.dart` 存在
- **增强**: 支持 CSV/PDF/JSON 三种格式真实导出

#### D3.4 多链支持基础设施
- **现状**: 仅支持 Soulon Chain (Cosmos)
- **目标**: 预留 EVM / Solana 链的适配接口
  ```dart
  abstract class ChainAdapter {
    Future<Balance> getBalance(String address);
    Future<TxResult> sendTx(SignedTx tx);
    Future<List<Validator>> getValidators();
  }

  class CosmosChainAdapter implements ChainAdapter { ... }
  class EvmChainAdapter implements ChainAdapter { ... }  // 未来
  ```

---

## 5. 三端路由补齐计划

### 5.1 路由补齐矩阵（基于 spec/backpack_vs_soulon 映射）

| 端 | 缺失路由 | 优先级 | 计划阶段 | 工作量 |
|----|----------|--------|----------|--------|
| Extension | TokensDetailScreen | P0 | D1 | 2d |
| Extension | ActivityDetailScreen | P0 | D1 | 2d |
| Extension | CollectiblesDetail/Collection | P1 | D1 | 2d |
| Extension | Settings 深层页族 (8页) | P1 | D2 | 5d |
| Extension | SwapNavigator (4页) | P1 | D2 | 5d |
| Extension | StakeNavigator (3页) | P1 | D2 | 3d |
| Mobile | SearchScreen | P0 | D1 | 2d |
| Mobile | ActivityDetailScreen | P0 | D1 | 2d |
| Mobile | TokensDetailScreen (增强) | P0 | D1 | 2d |
| Mobile | CollectiblesDetail/Collection | P1 | D2 | 3d |
| Web | /privacy | P1 | D2 | 1d |
| Web | /terms | P1 | D2 | 1d |
| Web | /ul/v1/browse/:url | P1 | D2 | 3d |

### 5.2 跨端路由契约

建议创建统一路由契约文件 `spec/route_contract.json`：

```json
{
  "version": "1.0.0",
  "routes": [
    {
      "id": "token_detail",
      "semantics": "显示单个代币详情（余额、价格、交易记录）",
      "platforms": {
        "flutter": "/replica/mobile/asset-detail",
        "extension": "/popup/tokens/detail",
        "web": "/tokens/:tokenId"
      },
      "params": { "tokenId": "string", "network": "string" },
      "priority": "P0"
    }
  ]
}
```

---

## 6. 测试与质量计划

### 6.1 测试覆盖率目标

| 子项目 | 现状 | 目标 | 重点 |
|--------|------|------|------|
| Flutter | 11 测试文件，覆盖率未知 | 行覆盖 >= 60% | Store 逻辑、API 层、路由 |
| React Web | 6 测试文件 | 行覆盖 >= 70% | API Client、Auth、页面渲染 |
| Extension | 0 测试文件 | 行覆盖 >= 50% | Store、Controller、路由逻辑 |
| soulon-deep-chain | 6 测试文件 | 行覆盖 >= 80% | 所有 Keeper 方法、Tx 校验 |
| soulon-backend | 未知 | 行覆盖 >= 60% | API 端点、索引器逻辑 |

### 6.2 新增测试计划

#### Flutter 新增测试
```
test/
├── state/
│   ├── security_confirm_store_test.dart  # PIN/生物识别全路径
│   ├── walletconnect_store_test.dart     # WC 会话生命周期
│   ├── transaction_store_test.dart       # 转账构建与广播
│   └── interop_store_test.dart           # 质押/治理/IBC
├── api/
│   ├── chain_api_client_test.dart        # 网络错误/超时/重试
│   └── api_error_mapper_test.dart        # 错误码映射
├── crypto/                               # 新模块
│   ├── mnemonic_test.dart
│   ├── hd_derivation_test.dart
│   └── signer_test.dart
└── integration/
    └── onboarding_flow_test.dart         # E2E onboarding
```

#### Extension 新增测试
```
test/
├── popup_store.test.ts       # Store CRUD + 状态转换
├── popup_controller.test.ts  # 事件绑定 + 导航逻辑
├── routes.test.ts            # 路由定义完整性
└── send_flow.test.ts         # 发送流程验证
```

#### React Web 新增测试
```
src/
├── api/walletApi.test.ts       # API 包装层
├── auth/AuthContext.test.tsx   # 会话管理全路径
├── pages/StatePage.test.tsx
├── pages/NotificationsPage.test.tsx
└── pages/LoginPage.test.tsx
```

### 6.3 CI/CD 门禁

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  flutter:
    runs-on: ubuntu-latest
    steps:
      - uses: subosito/flutter-action@v2
      - run: cd wallet-app-flutter && flutter test --coverage
      - run: cd wallet-app-flutter && flutter analyze

  react-web:
    runs-on: ubuntu-latest
    steps:
      - run: cd wallet-app && npm ci && npm run validate && npm test

  extension:
    runs-on: ubuntu-latest
    steps:
      - run: cd wallet-extension && npm ci && npm run lint && npm test

  chain:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/setup-go@v5
        with: { go-version: '1.22' }
      - run: cd soulon-deep-chain && go test ./... -race -cover

  backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/setup-go@v5
        with: { go-version: '1.24' }
      - run: cd soulon-backend && go test ./... -race -cover
```

---

## 7. 部署与运维计划

### 7.1 脚本跨平台化

**现状**: 所有部署脚本为 `.ps1` (PowerShell)，Linux/macOS/CI 不友好

**修复方案**:
1. 每个 `.ps1` 脚本提供 `.sh` (Bash) 对应版本
2. 或使用 `Makefile` + `just` (跨平台 task runner) 统一入口
3. 高优先级脚本（先迁移）：
   - `deploy/run-wallet-production-gate.ps1` → `Makefile: production-gate`
   - `deploy/run-v2-acceptance.ps1` → `Makefile: acceptance`
   - `soulon-deep-chain/scripts/start-localnet.ps1` → `Makefile: localnet`

### 7.2 Docker 化

```yaml
# docker-compose.yml (项目根目录)
version: '3.8'
services:
  chain:
    build: ./soulon-deep-chain
    ports: ["26657:26657", "1317:1317", "9090:9090"]

  backend-api:
    build:
      context: ./soulon-backend
      dockerfile: Dockerfile
      target: api
    ports: ["8082:8082"]
    depends_on: [postgres, kafka]
    env_file: ./soulon-backend/.env.example

  backend-indexer:
    build:
      context: ./soulon-backend
      dockerfile: Dockerfile
      target: indexer
    depends_on: [postgres, kafka, chain]

  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: soulon
      POSTGRES_PASSWORD: dev

  kafka:
    image: confluentinc/cp-kafka:7.7.0
    # ... kafka config

  wallet-web:
    build: ./wallet-app
    ports: ["3000:3000"]
```

### 7.3 监控完善

| 指标 | 来源 | 告警阈值 |
|------|------|----------|
| API 请求延迟 P99 | Backend Prometheus | > 2s |
| 索引器 lag | Kafka consumer lag | > 100 blocks |
| 链出块间隔 | Chain RPC | > 10s |
| 前端错误率 | Sentry/自建 | > 1% |
| WalletConnect 签名失败率 | Flutter 审计日志 | > 5% |

---

## 8. 里程碑与排期建议

### 总时间线：12 周（3 个月）

```
Week 1-2:   M1 安全修复与紧急缺陷
Week 3-4:   M2 架构升级基础（路由重构 + DI + 密钥管理）
Week 5-7:   M3 P0 功能补齐（三端核心路由）
Week 8-10:  M4 P1 功能扩展 + 链节点 SDK 迁移启动
Week 11-12: M5 测试补全 + CI/CD + 文档 + 发布准备
```

### 里程碑详情

| 里程碑 | 截止 | 交付物 | 退出标准 |
|--------|------|--------|----------|
| **M1 安全加固** | W2 | PIN 算法替换、会话安全加固、拼写修复 | 安全审计 P0 清零 |
| **M2 架构升级** | W4 | go_router 迁移、DI 引入、密钥管理模块骨架 | Flutter 路由 < 150 行，Store 可 mock |
| **M3 P0 补齐** | W7 | Extension Token/Activity 详情、Flutter 搜索/详情 | 三端路由映射 P0 全部绿色 |
| **M4 P1 扩展** | W10 | Web 法务页、Extension 设置/Swap/Stake、i18n 基础 | 三端路由映射 P1 覆盖 >= 80% |
| **M5 发布就绪** | W12 | CI/CD pipeline、Docker 化、测试覆盖率达标、README | 所有门禁通过，可进入 Beta 测试 |

### 并行工作流

```
Flutter 团队:    [F1.1 PIN修复] → [3.1 路由重构] → [D1.4-D1.6 P0页面] → [D2.6-D2.7] → [D3.1 i18n]
                                   [3.2 DI引入]     [3.3 密钥管理]

Extension 团队:  [F1 安全修复] → [3.5 Preact迁移] → [D1.1-D1.3 P0页面] → [D2.3-D2.5 P1页面]

React 团队:      [F1.3 会话安全] → [D2.1-D2.2 法务+浏览] → [6.2 测试补全] → [D3.1 i18n]

Chain 团队:      [F2.4 边界修复] → [3.4 Cosmos SDK 迁移 C1-C3] → [C4-C5] → [测试+文档]

DevOps:          [7.1 脚本跨平台] → [7.2 Docker化] → [6.3 CI/CD] → [7.3 监控]
```

### 风险与缓解

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| Cosmos SDK 迁移复杂度超预期 | 高 | M4 延期 | 保留现有 sim 链作为降级，SDK 迁移可延至下一季度 |
| Preact 迁移破坏 Extension 现有功能 | 中 | M3 延期 | 先在独立分支验证，保持旧代码可回退 |
| 密钥管理安全审计不通过 | 中 | M5 阻塞 | 引入成熟开源库（如 cosmjs/hdkey）而非自研 |
| Flutter go_router 迁移引入回归 | 低 | M2 延期 | 分 3 批渐进迁移，每批独立测试 |
| 人力不足导致三端并行受阻 | 高 | 全局延期 | 优先 Flutter（用户最多），Extension/Web 可顺延 |

---

## 附录 A: 文件变更清单（预估）

| 操作 | 文件数 | 类型 |
|------|--------|------|
| 修改 | ~30 | 现有文件修复/重构 |
| 新增 | ~45 | 新页面/组件/测试/配置 |
| 拆分 | ~6 | 大型 Store 拆分为多文件 |
| 删除 | ~0 | 无删除（旧代码保留为 sim） |

## 附录 B: 依赖变更汇总

### Flutter (pubspec.yaml)
```yaml
# 新增
crypto: ^3.0.0          # PIN 安全哈希
go_router: ^14.0.0      # 声明式路由
get_it: ^8.0.0          # 依赖注入
bip39: ^1.0.6           # 助记词
bip32: ^2.0.0           # HD 密钥派生
pointycastle: ^3.9.0    # 加密原语
flutter_localizations:  # i18n
  sdk: flutter
intl: ^0.19.0           # i18n
```

### React (package.json)
```json
{
  "dependencies": {
    "react-intl": "^7.0.0"
  }
}
```

### Extension
```json
{
  "dependencies": {
    "preact": "^10.23.0"
  }
}
```

### Chain (go.mod)
```
// 最终目标
require github.com/cosmos/cosmos-sdk v0.50.x
require github.com/cometbft/cometbft v0.38.x
```
