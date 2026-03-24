# Soulon Wallet 代码审查报告

> 审查时间: 2026-03-24
> 审查范围: wallet-app-flutter (全量), wallet-app (React, API 层)
> 涵盖: 101 个 Dart 文件, ~19500 行

---

## 严重程度分级: P0 (必须修) / P1 (应该修) / P2 (建议修)

---

## P0 — 必须修复

### 1. HD 密钥派生路径错误 (BIP-44 不合规)

**文件**: `lib/crypto/hd_key_derivation.dart:73-76`

**问题**: BIP-44 标准路径 `m/44'/118'/0'/0/N` 中，最后两级 `0` 和 `N` 应为**非硬化派生** (normal derivation)。当前实现对所有层级都使用了硬化派生 (`| 0x80000000`)。

```dart
// 当前代码 (错误):
(key, chainCode) = deriveHardenedChild(key, chainCode, 0 | 0x80000000);  // m/44'/118'/0'/0' ← 应该是 0
(key, chainCode) = deriveHardenedChild(key, chainCode, index | 0x80000000);  // index' ← 应该是 index
```

**影响**: 派生出的地址与标准钱包 (Keplr, Cosmostation, Leap) 不兼容。用户从其他钱包导入助记词后得到的地址不同。

**修复方案**: 需要实现非硬化子密钥派生 (`deriveNormalChild`)，但这要求 secp256k1 椭圆曲线点运算（需要公钥），当前 `SigningBackend` 是抽象的，缺少原生实现。

**临时标注**: 代码注释说 "hardened for compatibility" 但实际上是不兼容的。需要在代码中添加明确警告。

### 2. 地址派生使用截断 SHA-256 代替 RIPEMD-160

**文件**: `lib/crypto/signer.dart:47-51`

**问题**: Cosmos 地址计算公式是 `RIPEMD160(SHA256(pubKey))`，当前代码使用 `SHA256(pubKey).sublist(0, 20)` 作为 placeholder，会生成与标准 Cosmos 链不兼容的地址。

```dart
// 当前代码 (错误):
final addressBytes = Uint8List.fromList(sha256Hash.bytes.sublist(0, 20));
// 注释已说明: "In production, use pointycastle's RIPEMD160 or a platform channel"
```

**影响**: 所有链上签名的地址都是错误的，链上交易会被拒绝。

### 3. `create_wallet_page.dart` 被 import 但未在路由中使用

**文件**: `lib/app/app_router.dart:5`

**问题**: `import '../pages/create_wallet_page.dart'` 存在于 app_router 中，但 `createWallet` 路由实际映射到 `ReplicaOnboardingNetworksPage`，而非 `CreateWalletPage`。这意味着 `create_wallet_page.dart` (675 行) 可能是死代码。

---

## P1 — 应该修复

### 4. `_ActivityRow` 中 `icon` 变量被赋值但从未使用

**文件**: `lib/pages/replica_mobile_home_page.dart:634-646`

```dart
IconData icon;            // 声明
Color iconBg = ...;
Widget inner;
if (item.type == _ActivityType.nft) {
  inner = const Icon(Icons.hub_outlined, ...);
  icon = Icons.hub_outlined;   // 赋值但从未读取
} else if (item.type == _ActivityType.received) {
  icon = Icons.arrow_downward;  // 赋值但从未读取
  inner = const Icon(Icons.arrow_downward, ...);
} else {
  icon = Icons.arrow_upward;    // 赋值但从未读取
  inner = const Icon(Icons.arrow_upward, ...);
}
```

**影响**: 浪费，flutter analyze 会报 unused variable warning。

### 5. 登录页无输入校验 — 空格可绕过

**文件**: `lib/pages/ovd_auth_login_page.dart:27-31`

```dart
bool get _canSubmit => _email.text.trim().isNotEmpty && _password.text.trim().isNotEmpty;
void _submit() {
  Navigator.pushReplacementNamed(context, WalletRoutes.ovdLauncher);
}
```

**问题**:
- 无邮箱格式校验 — 任意非空字符串即可登录
- 无密码强度校验
- `_submit` 没有任何后端验证，直接跳转
- 在实际部署时可能导致安全问题

### 6. `AnimatedBuilder` 应该是 `AnimatedBuilder` (Flutter 3.22+ 已废弃?)

**文件**: 多处使用 `AnimatedBuilder`
- `replica_mobile_home_page.dart:54, 174`
- `ovd_launcher_page.dart:197, 785, 850`
- `replica_settings_page.dart:20`

**确认**: `AnimatedBuilder` 在 Flutter 3.22+ 中是正确的名称 (它是 `ListenableBuilder` 的子类)，此处标注供确认。若项目使用更早的 Flutter 版本可能需要检查。

### 7. Timer 无生命周期管理

**文件**:
- `notification_store.dart` — `_timer` 在 `startStream()` 中创建，无自动 dispose
- `dapp_interop_store.dart` — `_autoRefreshTimer` 同上

**影响**: 单例 Store 在 app 生命周期内存在，Timer 不会被回收。如果 `stopStream()` / 对应的 stop 方法未被调用，Timer 会永远运行。

**修复方案**: 在 Store 中添加 `dispose()` 方法，或在 `startStream` 中添加自动超时停止。

### 8. `ChainApiClient` 没有 `close()` 方法

**文件**: `lib/api/chain_api_client.dart`

**问题**: `HttpClient _httpClient` 被创建但从未关闭。在单例模式下可以接受，但如果多次创建 `ChainApiClient` 实例（如测试中），会导致 HTTP 连接泄漏。

---

## P2 — 建议修复

### 9. 硬编码的 Mock 数据散落各处

**影响范围**:
- `notification_store.dart:89-116` — 3 条硬编码通知
- `multisig_store.dart:528-557` — 2 条硬编码多签任务
- `dapp_interop_store.dart:125-141` — 硬编码 SuggestChain 请求
- `walletconnect_store.dart:128-149` — 硬编码 WalletConnect 请求/会话
- `staking_governance_store.dart` — 硬编码验证人地址

**建议**: 将 mock 数据抽取到 `lib/config/mock_data.dart` 或通过 `--dart-define` 控制是否加载。

### 10. `KeystoreManager.deriveKey` 未使用变量 `u`

**文件**: `lib/crypto/keystore_manager.dart:28`

```dart
final u = Uint8List(32);  // 从未使用
```

### 11. 密码类 TextEditingController 可能泄露到内存

**文件**: `ovd_auth_login_page.dart`, `ovd_auth_register_page.dart`

**问题**: `_password` controller 的文本在 dispose 后仍可能残留在内存中。应在 dispose 时 `_password.clear()` 清除敏感数据。

### 12. `SwapExchangePage` 中 `_fromAsset` 和 `_toAsset` 允许选择相同代币

**文件**: `lib/pages/swap_exchange_page.dart:19-20`

```dart
String _fromAsset = 'SOL';
String _toAsset = 'USDC';
```

**问题**: 卖方和买方 token 的下拉列表没有互斥逻辑，用户可以选择 SOL→SOL 兑换。

### 13. 路由参数传递不一致

**问题**: go_router 中 `state.extra` 和 Navigator 中 `settings.arguments` 是不同的机制。如果同时保留两套路由 (app_router + router_config)，页面间跳转可能参数丢失。

**建议**: 统一使用 go_router 的 `context.push(route, extra: args)` 或明确标注哪些页面只支持哪种方式。

---

## 架构观察 (非 Bug)

### A. crypto 模块缺少原生后端
`SigningBackend` 是抽象类，项目中没有任何实现。`MnemonicGenerator` 可以生成 entropy 和校验，但没有 BIP-39 词表。`IdentityDemoStore` 使用自定义 84 词 word bank 而非标准 2048 词 BIP-39 词表。

### B. `security_interop_demo_store.dart` barrel export 导出了无关的文件
该文件导出 `security_confirm_store`, `walletconnect_store`, `dapp_interop_store`，但文件名暗示是 "security + interop" 的合体。实际上这三个 Store 之间并无强关联。

### C. React 端 API client 实现质量高
`wallet-app/src/api/client.ts` 有完整的重试逻辑、超时处理、lifecycle tracing、错误归因层级。相比之下 Flutter 端的 `ChainApiClient` 较简陋 (无重试、无 tracing)。
