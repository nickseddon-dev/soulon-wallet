# Chaos 恢复策略与告警阈值 Spec

## Why
当前 Chaos 报告已具备明细与趋势，但缺少可直接执行的恢复建议与告警阈值，团队仍需手工判断风险并编写规则。

## What Changes
- 在 Chaos 报告中新增按场景的风险分级与恢复动作建议。
- 在 Chaos 报告中新增基于历史窗口的告警阈值建议（错误率、耗时、连续失败）。
- 新增机器可读输出，生成与 Markdown 同步的 JSON 报告结构。
- 在 CI 中暴露建议摘要，便于审阅与后续接入告警系统。

## Impact
- Affected specs: 可观测性、故障注入自动化、运维告警建议
- Affected code: `scripts/run-chaos-report.ps1`、`.github/workflows/chaos.yml`、`README.md`

## ADDED Requirements
### Requirement: Chaos 报告恢复建议
系统 SHALL 在每次 Chaos 报告中输出按场景聚合的风险等级与恢复建议。

#### Scenario: 场景失败率升高
- **WHEN** 某场景在当前报告中的失败率超过预设阈值
- **THEN** 报告输出该场景的风险等级与建议恢复动作（例如重试参数、暂停时长、健康检查策略）

#### Scenario: 场景稳定
- **WHEN** 某场景失败率低且耗时无明显异常
- **THEN** 报告输出“稳定”风险等级并给出保持策略

### Requirement: Chaos 报告告警阈值建议
系统 SHALL 基于历史窗口报告计算可直接使用的告警建议值。

#### Scenario: 历史性能退化
- **WHEN** 最近 N 次平均耗时显著高于历史基线
- **THEN** 报告输出建议的延迟告警阈值与触发条件

#### Scenario: 历史稳定性退化
- **WHEN** 最近 N 次出现连续失败或失败率上升
- **THEN** 报告输出建议的错误率阈值与连续失败阈值

### Requirement: 机器可读报告
系统 SHALL 生成与 Markdown 对齐的 JSON 报告，包含总览、场景汇总、趋势与建议字段。

#### Scenario: 报告生成成功
- **WHEN** Chaos 脚本执行完成
- **THEN** 在 `reports/chaos/` 下同时输出 `.md` 与 `.json` 报告文件

## MODIFIED Requirements
### Requirement: Chaos CI 报告可见性
Chaos 工作流 SHALL 在执行后输出关键建议摘要并上传完整报告产物。

## REMOVED Requirements
### Requirement: 无
**Reason**: 本次仅扩展能力，不移除现有要求。
**Migration**: 无需迁移。
