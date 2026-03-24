# Tasks
- [x] Task 1: 对齐链名称为 Overdrive Chian
  - [x] 梳理前端链名称来源（常量/枚举/配置/文案）
  - [x] 将自建链显示名统一替换为 “Overdrive Chian”
  - [x] 验证各入口（首页、资产、交易、设置、导入/创建流程）显示一致

- [x] Task 2: 新增 Portal 入口点与过渡动画
  - [x] 在钱包首页 AppBar 右上角加入“四格”入口图标
  - [x] 实现入口点扩张覆盖全屏 + 背景缩放位移到左上角
  - [x] 实现图标从“四格”变形为“三条杠”（可用自绘/路径/逐帧/简化过渡）
  - [x] 实现反向退出动画回到钱包首页
  - [x] 统一过渡曲线 `Curves.easeOutQuart` 与时长 600ms

- [x] Task 3: 实现 Launcher 顶部布局与三按钮
  - [x] 顶部左侧动态余额（法币等价，Mock 数据）
  - [x] 并排按钮：充值 / 提现 / 兑换（前端路由到占位页或既有页面）
  - [x] 磁贴反馈时长 150ms、曲线一致

- [x] Task 4: 实现 Status Stream（Matrix 代码流风格）
  - [x] 设计单行滚动日志组件（Ticker/滚动列表/跑马灯均可）
  - [x] 提供 Mock 数据源（链上大额交易/游戏掉落）
  - [x] 保证长时间运行性能稳定（避免无界重建/内存增长）

- [x] Task 5: 实现 Hero Horizon 3D 轮播 + Tilt 视差
  - [x] 用 `PageView.builder` 实现 3D 卡片轮播（缩放/透视/景深）
  - [x] 焦点卡片启用 `flutter_tilt`（或项目已有替代方案）陀螺仪视差
  - [x] 提供至少 3 个游戏卡片 Mock 数据（图标/名称/状态）

- [x] Task 6: 实现底部磨砂磁贴功能栏与占位页
  - [x] 使用 `BackdropFilter` + 半透明层实现磨砂背景
  - [x] Tavern / Vault / Bazaar / Lab 四入口布局与交互
  - [x] 为四入口提供占位页面骨架（不接后端）

- [x] Task 7: Portal 音效接入（可选，需可降级）
  - [x] 调研项目现有音频播放依赖；若无则选用轻量依赖
  - [x] 入口触发时播放 High-frequency hum
  - [x] 无权限/无资源/静音时降级为无音效但不影响流程

- [x] Task 8: 验证与交付
  - [x] `flutter analyze` 通过
  - [x] Web 端可启动并在新端口验证更新可见
  - [x] 手工走通：钱包首页 → Portal → Launcher → 四入口占位页 → 返回

# Task Dependencies
- Task 2 depends on Task 3/4/5/6（Portal 过渡目标页面需存在基础骨架）
- Task 5 depends on Task 3（视觉层级与布局容器先行）
