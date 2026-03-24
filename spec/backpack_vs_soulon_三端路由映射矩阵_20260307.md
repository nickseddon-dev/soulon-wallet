# Backpack vs Soulon 三端页面路由映射矩阵（2026-03-07）

## 范围与口径
- 对比范围：`D:\backpack` 与 `D:\soulon_wallet` 的三端页面路由（Web、Extension、Mobile/Flutter）。
- Mobile 对照口径：Backpack 以 `packages/app-extension/src/refactor/navigation/*` 作为移动交互主导航基线；Soulon 以 `wallet-app-flutter/lib/app/app_router.dart` 为路由基线。
- 优先级定义：
  - P0：阻断主流程（资产查看、活动详情、发送接收、解锁、设置主入口、搜索/定位）。
  - P1：增强与补齐（法律页、信息页、偏好深层页、NFT/Swap/Tensor 等扩展流程）。

## A. Web 端路由映射（Backpack → Soulon）

| Backpack 路由（web/pages） | Soulon 路由（wallet-app） | 映射状态 | 备注 |
|---|---|---|---|
| `/` | `/site`（营销壳层） | 部分映射 | 页面语义接近，但路径不一致 |
| `/downloads` | `/site/download` | 已映射 | 下载页已存在 |
| `/about` | `/site/info` | 部分映射 | 信息承载存在，但路径/内容不完全对齐 |
| `/privacy` | 无 | 缺失 | 法务页未落地 |
| `/terms` | 无 | 缺失 | 法务页未落地 |
| `/ul/v1/browse/[...url]` | 无 | 缺失 | 浏览/深链入口未落地 |

## B. Extension 路由映射（Backpack → Soulon）

| Backpack 路由/导航单元 | Soulon 路由（wallet-extension） | 映射状态 | 备注 |
|---|---|---|---|
| `TabsNavigator.TokensScreen` | `/popup/tokens` | 已映射 | 核心资产页已具备 |
| `TabsNavigator.CollectiblesScreen` | `/popup/collectibles` | 已映射 | 核心收藏页已具备 |
| `TabsNavigator.ActivityScreen` | `/popup/activity` | 已映射 | 核心活动页已具备 |
| `WalletsNavigator.SearchScreen` | `/popup/search` | 已映射 | 搜索入口已具备 |
| `SendNavigator.*` | `/popup/send` | 部分映射 | Soulon 为单路由多步骤，Backpack 为多屏栈 |
| `ReceiveNavigator.ReceiveScreen` | `/popup/receive` | 已映射 | 接收入口已具备 |
| `SettingsNavigator.SettingsScreen` | `/popup/settings` | 已映射 | 设置主入口已具备 |
| `TokensDetailScreen` | 无 | 缺失 | 资产详情未独立路由化 |
| `CollectiblesDetail/Collection` | 无 | 缺失 | 收藏详情/集合未独立路由化 |
| `ActivityDetailScreen` | 无 | 缺失 | 活动详情未独立路由化 |
| `SwapNavigator.*` | 无 | 缺失 | 兑换流程未落地 |
| `StakeNavigator.*` | 无 | 缺失 | 质押流程未落地 |
| `TensorNavigator.*` | 无 | 缺失 | Tensor 市场流程未落地 |
| `XnftScreen` | 无 | 缺失 | xNFT 独立页未落地 |
| `SettingsNavigator` 深层偏好/钱包管理页 | 无 | 缺失 | 仅主设置页，未覆盖深层页族 |

## C. Mobile 路由映射（Backpack Refactor → Soulon Flutter）

| Backpack 导航单元 | Soulon Flutter 路由 | 映射状态 | 备注 |
|---|---|---|---|
| `TabsNavigator`（Tokens/Collectibles/Activity） | `/replica/mobile/home` | 部分映射 | Flutter 在单页内做 tab，而非独立路由 |
| `SendNavigator.*` | `/replica/mobile/send` | 部分映射 | 有发送页，但与多屏栈粒度不同 |
| `ReceiveNavigator.ReceiveScreen` | `/replica/mobile/receive` | 已映射 | 接收入口具备 |
| `SettingsNavigator.SettingsScreen` | `/replica/mobile/settings` | 已映射 | 设置主入口具备 |
| `SearchScreen` | 无 | 缺失 | 全局搜索页未落地 |
| `ActivityDetailScreen` | 无 | 缺失 | 活动详情页未落地 |
| `TokensDetailScreen` | 无 | 缺失 | 资产详情页未落地 |
| `CollectiblesDetail/Collection` | 无 | 缺失 | 收藏详情与集合页未落地 |
| `SwapNavigator.*` | 无 | 缺失 | 兑换流程未落地 |
| `StakeNavigator.*` | `/interop/staking` | 部分映射 | Soulon 有 Cosmos 质押页，但非 Backpack 同构路径 |
| `TensorNavigator.*` / `XnftScreen` | 无 | 缺失 | Tensor/xNFT 流程未落地 |

## 缺失页面清单与优先级（P0/P1）

| 端 | 缺失项 | 优先级 | 判定理由 |
|---|---|---|---|
| Web | `/privacy` | P1 | 合规必需但不阻断交易主流程 |
| Web | `/terms` | P1 | 合规必需但不阻断交易主流程 |
| Web | `/ul/v1/browse/[...url]` | P1 | 生态浏览入口缺失，影响功能完整性 |
| Extension | `ActivityDetailScreen` | P0 | 活动追踪无法下钻，阻断问题定位与追单 |
| Extension | `TokensDetailScreen` | P0 | 资产详情缺失，影响持仓与操作闭环 |
| Extension | `CollectiblesDetail/Collection` | P1 | NFT 信息深度不足，非基础资金路径 |
| Extension | `Settings` 深层页族 | P1 | 高级配置缺失，主入口已可用 |
| Extension | `SwapNavigator.*` | P1 | 交易增强能力，非当前最小闭环 |
| Extension | `StakeNavigator.*` | P1 | 生态增强能力，非当前最小闭环 |
| Extension | `TensorNavigator.*` / `XnftScreen` | P1 | 市场与生态扩展能力 |
| Mobile | `SearchScreen` | P0 | 无法快速定位资产/活动，影响高频操作效率 |
| Mobile | `ActivityDetailScreen` | P0 | 活动记录无法下钻验真 |
| Mobile | `TokensDetailScreen` | P0 | 资产详情不可达，影响资产操作闭环 |
| Mobile | `CollectiblesDetail/Collection` | P1 | 收藏品深层页缺失 |
| Mobile | `SwapNavigator.*` | P1 | 兑换路径未对齐 Backpack |
| Mobile | `TensorNavigator.*` / `XnftScreen` | P1 | 生态扩展能力未覆盖 |

## 建议的实施顺序
1. 先补 P0：Extension 活动/资产详情、Mobile 搜索/活动详情/资产详情。
2. 再补 P1：Web 法务与浏览入口、Extension/Mobile 的 Swap/Stake/Tensor/xNFT 与设置深层页族。
3. 路由治理建议：统一维护一个跨端路由契约清单（含别名、参数、跳转来源），避免后续复刻偏移。

