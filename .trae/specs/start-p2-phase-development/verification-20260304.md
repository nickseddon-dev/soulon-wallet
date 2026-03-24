# Checklist 核验记录（2026-03-04）

## 1) 已建立并确认 P2 首批范围与门禁标准
- 结果：通过
- 证据：
  - `spec.md` 明确首批范围仅含 BIP-21 生成/解析及门禁口径（见 Requirement: P2阶段执行基线）。
  - `tasks.md` Task 1 已完成，包含范围冻结与门禁对齐子任务。

## 2) SDK 已实现 BIP-21 生成能力并通过参数校验测试
- 结果：通过
- 证据：
  - `soulon-wallet/src/core/bip21.ts` 提供 `generateBip21Uri`，并对 address/amount/scheme 执行校验。
  - `soulon-wallet/tests/bip21.test.mjs` 覆盖生成成功、空地址、非法 amount 场景。
  - 命令 `npm run test:unit`（soulon-wallet）通过，7/7 用例通过。

## 3) SDK 已实现 BIP-21 解析能力并通过异常场景测试
- 结果：通过
- 证据：
  - `soulon-wallet/src/core/bip21.ts` 提供 `parseBip21Uri`，覆盖 URI/scheme/address/amount 校验与异常抛错。
  - `soulon-wallet/tests/bip21.test.mjs` 覆盖解析成功、缺少 scheme 分隔符、非法 amount 场景。
  - 命令 `npm run test:unit`（soulon-wallet）通过。

## 4) wallet-app 已接入 BIP-21 生成与解析入口
- 结果：通过
- 证据：
  - `wallet-app/src/pages/HomePage.tsx` 提供“生成支付 URI”“解析并回填表单”入口与 UI 交互。
  - `wallet-app/src/lib/bip21.ts` 提供 `createBip21PaymentUri` 与 `parseBip21Input` 前端调用封装。
  - `wallet-app/src/pages/HomePage.test.tsx` 覆盖生成展示与解析回填。

## 5) wallet-app 在解析失败时提供一致错误反馈且不破坏原表单状态
- 结果：通过
- 证据：
  - `wallet-app/src/lib/bip21.ts` 通过 `toUnifiedBip21Error` 统一错误文案。
  - `wallet-app/src/pages/HomePage.tsx` 解析失败时仅更新错误状态，不覆盖地址/金额/备注状态。
  - `wallet-app/src/pages/HomePage.test.tsx` 用例“解析失败时展示统一错误且不覆盖现有手动输入”通过。

## 6) SDK 与前端对同一输入输出一致
- 结果：通过
- 证据：
  - `wallet-app/src/lib/bip21.ts` 直接复用 `soulon-wallet/dist/core/bip21.js` 的 `generateBip21Uri`、`parseBip21Uri`。
  - `wallet-app/src/lib/bip21.ts` 复用 `soulon-wallet/dist/core/errors.js` 的 `SoulonWalletError`，并映射 `BIP21_ERROR_CODES`。
  - 未发现前端侧独立实现的分叉规则。

## 7) 相关测试与构建门禁全部通过
- 结果：通过
- 执行命令与结果：
  - `npm run test`（wallet-app）：通过，Test Files 3 passed，Tests 7 passed。
  - `npm run validate`（wallet-app）：通过，串行完成 lint、typecheck、build。
  - `npm run test:unit`（soulon-wallet）：通过，tests 7, pass 7。
  - `npm run check`（soulon-wallet）：通过，tsc --noEmit 无错误。

## 8) 验收结论与风险项已记录并可追溯
- 结果：通过
- 证据：
  - `spec.md` 已记录风险项（前后端规则不一致、异常覆盖不足、兼容性影响）。
  - `spec.md` 已记录验收结论（2026-03-04）与门禁执行结果。

## 综合结论
- 本次对 `checklist.md` 8 个条目逐项核验均通过，已全部勾选。
- 未出现失败项，因此 `tasks.md` 无需新增修复任务。
