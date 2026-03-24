# Tasks
- [x] Task 1: 建立三端复刻对照基线
  - [x] SubTask 1.1: 产出页面清单与路由映射表（移动端/扩展端/官网）
  - [x] SubTask 1.2: 产出交互矩阵（主导航、弹层、搜索、发送流程）
  - [x] SubTask 1.3: 明确第一阶段不改动项（业务规则、后端契约、风控策略）

- [x] Task 2: 建立统一设计令牌与组件映射
  - [x] SubTask 2.1: 建立颜色、字体、间距、圆角、阴影、动效令牌
  - [x] SubTask 2.2: 定义按钮、输入、卡片、标签、弹层组件映射
  - [x] SubTask 2.3: 在三端工程中接入统一令牌消费方式

- [x] Task 3: 完成 Flutter 移动端 UI 复刻
  - [x] SubTask 3.1: 复刻主容器、主导航与首页信息架构
  - [x] SubTask 3.2: 复刻资产/收藏/活动主视图与关键列表样式
  - [x] SubTask 3.3: 复刻发送接收、设置、安全确认等核心流程页面

- [x] Task 4: 完成浏览器扩展端 UI 复刻
  - [x] SubTask 4.1: 搭建扩展 popup UI 壳层与路由容器
  - [x] SubTask 4.2: 复刻标签导航、搜索入口与模态流程组织
  - [x] SubTask 4.3: 复刻扩展端核心页面样式与交互反馈

- [x] Task 5: 完成官网电脑端 UI 复刻
  - [x] SubTask 5.1: 复刻首页与主视觉区块（桌面端优先）
  - [x] SubTask 5.2: 复刻下载页与关键信息页布局
  - [x] SubTask 5.3: 完成桌面端响应式断点与视觉一致性修正

- [x] Task 6: 执行复刻验收与差异归档
  - [x] SubTask 6.1: 完成三端页面截图对照与交互走查
  - [x] SubTask 6.2: 修复阻断级 UI 偏差与交互断点
  - [x] SubTask 6.3: 输出“已复刻/差异/后续可调”归档文档

- [x] Task 7: 完成 Flutter 全量交互与动效实现
  - [x] SubTask 7.1: 补齐导航切换、页面转场、列表入场与反馈动效
  - [x] SubTask 7.2: 补齐发送接收与安全确认流程的状态过渡动效
  - [x] SubTask 7.3: 增加 Flutter 交互与动效回归测试

- [x] Task 8: 完成扩展端全量交互与动效实现
  - [x] SubTask 8.1: 补齐 popup 标签切换、搜索展开与模态开合动效
  - [x] SubTask 8.2: 补齐表单校验、提交反馈与焦点管理交互
  - [x] SubTask 8.3: 增加扩展端交互与动效回归校验

- [x] Task 9: 完成官网桌面端全量交互与动效实现
  - [x] SubTask 9.1: 补齐首页区块入场、按钮悬停、页面过渡动效
  - [x] SubTask 9.2: 补齐下载页与信息页的交互动效细节
  - [x] SubTask 9.3: 增加官网端交互与响应式回归校验

- [x] Task 10: 执行三端动效一致性验收与归档
  - [x] SubTask 10.1: 按统一令牌核对三端动效时长、曲线与触发条件
  - [x] SubTask 10.2: 修复阻断级交互与动效不一致问题
  - [x] SubTask 10.3: 输出第二阶段完整交互与动效验收归档

- [x] Task 11: 修复验证阻塞并完成复验
  - [x] SubTask 11.1: 处理 Flutter 测试磁盘空间阻塞并恢复三端校验环境
  - [x] SubTask 11.2: 修复 Flutter Analyze 信息级告警并完成全量复验

# Task Dependencies
- [Task 2] depends on [Task 1]
- [Task 3] depends on [Task 2]
- [Task 4] depends on [Task 2]
- [Task 5] depends on [Task 2]
- [Task 6] depends on [Task 3]
- [Task 6] depends on [Task 4]
- [Task 6] depends on [Task 5]
- [Task 7] depends on [Task 3]
- [Task 8] depends on [Task 4]
- [Task 9] depends on [Task 5]
- [Task 10] depends on [Task 7]
- [Task 10] depends on [Task 8]
- [Task 10] depends on [Task 9]
- [Task 11] depends on [Task 10]
