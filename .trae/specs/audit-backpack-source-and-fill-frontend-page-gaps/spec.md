# Backpack 源码清查与前端缺口补齐 Spec

## Why
当前复刻工程已具备钱包首页样式，但缺少“创建钱包、兑换、更多流程页”的完整闭环。需要基于上游 Backpack 源码做结构化清查，明确已实现与未实现范围，避免遗漏关键页面与交互。

## What Changes
- 在 D 盘克隆上游 Backpack 仓库并完成目录级能力盘点。
- 建立“上游页面/流程 → 本项目页面/路由”的一一映射矩阵。
- 识别当前前端已完成部分与缺失部分，形成可执行缺口清单。
- 按优先级补齐缺失页面（先钱包创建与兑换，再高频流程页）。
- 补齐对应测试与验收清单，确保页面可访问、可交互、可回归。

## Impact
- Affected specs: replicate-backpack-multi-platform-ui
- Affected code:
  - wallet-app-flutter/lib/app/app_router.dart
  - wallet-app-flutter/lib/pages/replica_*.dart
  - wallet-extension/src/popup/main.ts
  - wallet-app/src/pages/*.tsx
  - wallet-app-flutter/test/*.dart

## ADDED Requirements
### Requirement: 上游源码结构清查能力
系统 SHALL 能够基于上游 Backpack 仓库输出“目录-模块-页面流程”的结构化清单，并标注每个模块的用途与前端可见入口。

#### Scenario: 成功完成源码清查
- **WHEN** 执行上游仓库拉取并扫描关键目录（app-extension、web、packages）
- **THEN** 输出可追溯的模块清单与页面流程映射，不遗漏钱包创建、导入、兑换等核心入口

### Requirement: 前端页面缺口识别能力
系统 SHALL 能够对比“上游能力清单”与“本项目已实现页面”，输出未实现页面、未连线路由、未完成交互三类缺口。

#### Scenario: 成功识别缺口
- **WHEN** 对比上游页面流程与本地 Flutter/Web/扩展前端实现
- **THEN** 生成缺口列表并给出优先级（P0/P1/P2）与落地目标文件

### Requirement: 缺口页面补齐能力
系统 SHALL 按优先级补齐缺口页面，至少覆盖钱包创建流程与兑换流程，并保证导航可达。

#### Scenario: 钱包创建与兑换页面可用
- **WHEN** 用户进入钱包首页并执行“创建钱包/兑换”相关入口
- **THEN** 页面可正常打开，流程可走通，关键状态（空态/错误态/成功态）可见

### Requirement: 差异验收与回归能力
系统 SHALL 为新增或改造页面补充测试，确保后续迭代不会回退。

#### Scenario: 回归通过
- **WHEN** 执行 analyze 与 test
- **THEN** 不出现阻断级错误，关键页面断言全部通过

## MODIFIED Requirements
### Requirement: 多端复刻范围定义
复刻范围从“首页与少量流程”扩展为“覆盖上游钱包核心流程集合”，包含但不限于创建钱包、导入钱包、兑换、资产详情、设置与安全相关入口。

## REMOVED Requirements
### Requirement: 仅首页可视复刻即可验收
**Reason**: 无法满足真实钱包使用路径，用户进入后缺乏关键操作页面。  
**Migration**: 验收标准迁移为“核心流程页可达且可交互”，并以缺口清单归零作为完成标志。
