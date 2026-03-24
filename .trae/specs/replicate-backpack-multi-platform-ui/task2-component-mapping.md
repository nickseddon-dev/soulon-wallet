# Task2 统一组件映射

| 组件类型 | Flutter | Web（wallet-app） | 扩展端（wallet-extension） | 统一规范 |
|---|---|---|---|---|
| 按钮 | `WalletPrimaryButton` | `button`/`.ghost-button` | `.ext-button` | 主按钮使用 `primary` 色，禁用态降低透明度 |
| 输入框 | `WalletTextField` | `input`/`select` | `.ext-input` | 统一圆角、边框与焦点环样式 |
| 卡片 | `WalletCard` | `.state-card`/`.exchange-card` | `.ext-card` | 统一卡片背景、边框、阴影 |
| 标签 | 状态文案 + `Container`（规划） | `.status-badge` | `.ext-badge` | 统一胶囊形态与状态色映射 |
| 弹层 | `WalletAlertDialog` | modal（规划） | `.ext-modal` | 统一遮罩、面板圆角与确认按钮样式 |

## 状态映射

| 状态 | 颜色令牌 | 用途 |
|---|---|---|
| 默认 | `--token-color-primary` | 主操作、主导航高亮 |
| 成功 | `--token-color-success` | 成功状态、可完成提示 |
| 警告 | `--token-color-warning` | 风险提醒、可恢复异常 |
| 危险 | `--token-color-danger` | 错误、不可逆操作 |

## 消费约束
- 三端必须从统一令牌层消费颜色、字体、间距、圆角、阴影、动效。
- 组件内禁止直接写死色值与关键尺寸。
- 新增组件时需先在本映射补充规范，再进入页面实现。
