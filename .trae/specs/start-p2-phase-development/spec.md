# P2阶段启动与首批能力落地 Spec

## Why
P0 已完成并通过门禁验证，项目需要进入增强迭代。当前缺少明确的 P2 执行边界与首批可交付能力，容易造成范围扩散与验收口径不一致。

## What Changes
- 建立 P2 阶段基线与执行边界，明确仅先落地首批可验证能力。
- 落地首个 P2 需求：BIP-21 扫码支付能力（生成与解析）。
- 在钱包 UI 与 SDK 同步提供 BIP-21 输入/输出能力并形成一致错误模型。
- 增加对应单元测试与联调验证步骤，纳入现有门禁流程。

## Impact
- Affected specs: 钱包交易体验增强、SDK 地址协议能力、P2 迭代治理
- Affected code: `wallet-app/src/pages/*`、`wallet-app/src/api/*`、`soulon-wallet/src/*`、相关测试与脚本

## ADDED Requirements
### Requirement: P2阶段执行基线
系统 SHALL 提供可执行的 P2 范围基线，并限定首批开发仅覆盖已确认的 P2 条目。

#### Scenario: 基线建立成功
- **WHEN** 团队启动 P2 开发
- **THEN** 存在明确的范围、任务顺序、验收口径与门禁命令

#### Scenario: 首批范围与门禁冻结
- **WHEN** 团队确认 P2 首批交付范围
- **THEN** 基线仅包含 BIP-21 生成与解析能力，不包含批量转账、地址簿、跨链支付等扩展项
- **THEN** 基线固定首批门禁命令为钱包前端与 SDK 各自既定的 lint、typecheck、test/build 校验命令

#### Scenario: 依赖与风险清单输出
- **WHEN** 团队进入 Task 拆解与执行阶段
- **THEN** 基线文档包含跨项目依赖清单：`wallet-app` 依赖 `soulon-wallet` 提供统一 BIP-21 生成/解析接口与错误模型
- **THEN** 基线文档包含跨项目依赖清单：`wallet-app` 与 `soulon-wallet` 依赖统一的 BIP-21 参数约束（地址、金额、备注）
- **THEN** 基线文档包含风险清单：前端与 SDK 规则不一致导致回填字段偏差
- **THEN** 基线文档包含风险清单：异常输入覆盖不足导致非法 URI 误通过或误报
- **THEN** 基线文档包含风险清单：新增流程影响原有手动输入路径的兼容性

### Requirement: BIP-21 生成能力
系统 SHALL 支持根据地址、金额、备注生成标准 BIP-21 支付 URI。

#### Scenario: 生成成功
- **WHEN** 用户输入合法地址与可选参数
- **THEN** 系统返回格式正确且可复制的 BIP-21 URI

#### Scenario: 参数非法
- **WHEN** 地址为空或金额格式非法
- **THEN** 系统返回可识别的参数错误并阻止生成

### Requirement: BIP-21 解析能力
系统 SHALL 支持解析 BIP-21 URI 并提取地址、金额、备注等字段。

#### Scenario: 解析成功
- **WHEN** 用户输入合法 BIP-21 URI
- **THEN** 系统正确提取字段并回填到交易表单

#### Scenario: URI非法
- **WHEN** 用户输入不符合 BIP-21 规范的字符串
- **THEN** 系统返回标准化解析错误且不污染现有表单状态

### Requirement: SDK与前端一致性
系统 SHALL 保证 wallet-app 与 soulon-wallet 对 BIP-21 的生成与解析规则一致。

#### Scenario: 一致性校验
- **WHEN** 对同一输入分别调用 SDK 与前端能力
- **THEN** 输出字段与错误码语义一致

## MODIFIED Requirements
### Requirement: 钱包交易输入流程
钱包交易输入流程需扩展为“手动输入 + BIP-21 扫码/粘贴解析”双通道，并保持原有转账构建流程兼容。

## REMOVED Requirements
### Requirement: 无
**Reason**: 本次为能力新增与流程扩展，不移除既有需求。  
**Migration**: 不涉及迁移。

## 验收结论（2026-03-04）
- 验证命令执行结果：
  - `npm run test`（wallet-app）通过，7/7 用例通过。
  - `npm run validate`（wallet-app）通过，已串行完成 lint、typecheck、build。
  - `npm run test:unit`（soulon-wallet）通过，7/7 用例通过并完成构建。
  - `npm run check`（soulon-wallet）通过，TypeScript 无类型错误。
- BIP-21 一致性核验结果：
  - `wallet-app/src/lib/bip21.ts` 直接复用 `soulon-wallet/dist/core/bip21.js` 的 `generateBip21Uri` 与 `parseBip21Uri`，未引入前端侧分叉规则。
  - `wallet-app/src/lib/bip21.ts` 与 `soulon-wallet/dist/core/errors.js` 共享 `SoulonWalletError` 与 `BIP21_ERROR_CODES`，保证错误码语义一致。
  - 前端回填逻辑仅做字段映射（`amount/memo` 空值归一），与 SDK 输出约束保持一致。
- 综合判定：P2 首批 BIP-21 范围已满足可追溯验收条件，可进入下一阶段。
