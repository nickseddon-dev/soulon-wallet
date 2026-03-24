# 区块链与钱包上线就绪审查 Spec

## Why
当前仓库已完成多轮主线开发与验证，但尚未形成“是否可正式上线”的统一审查结论。需要对区块链后端与钱包项目进行现状盘点、缺口识别与上线判定。

## What Changes
- 新增上线就绪审查流程，覆盖能力现状、未开发项、风险与上线门禁
- 输出“已完成任务/待开发任务”清单，并按优先级归类
- 给出正式上线判定结论与阻断项
- 明确上线前必须补齐的最小闭环事项

## Impact
- Affected specs: 主线功能审查、上线门禁判定、风险收敛
- Affected code: `.trae/specs` 规格体系、`README.md` 能力与门禁说明、`wallet-app` 与 `soulon-backend` 当前实现状态

## ADDED Requirements
### Requirement: 上线就绪现状盘点
系统 SHALL 基于当前代码与既有规格，输出区块链后端与钱包项目“已完成能力”清单。

#### Scenario: 审查当前能力
- **WHEN** 发起上线审查
- **THEN** 可追溯列出已完成的功能、验证与门禁通过项

### Requirement: 待开发与缺口识别
系统 SHALL 输出“仍需开发/未开发”事项，并标注对上线的影响级别（阻断/非阻断）。

#### Scenario: 识别缺口
- **WHEN** 对照目标规格与当前实现
- **THEN** 明确待开发清单及其优先级

### Requirement: 上线判定结论
系统 SHALL 给出“可上线/不可上线/有条件上线”结论，并附上线前最小改造建议。

#### Scenario: 形成结论
- **WHEN** 完成能力盘点与缺口识别
- **THEN** 输出明确上线判定及下一步执行建议

## MODIFIED Requirements
### Requirement: 交付验收输出
交付验收从“仅验证通过”修改为“验证通过 + 上线判定与缺口清单并行输出”。

## REMOVED Requirements
### Requirement: 无上线判定的验收收口
**Reason**: 缺少上线判定会导致已验收但不可发布的风险。  
**Migration**: 所有验收收口新增上线就绪审查与阻断项结论。
