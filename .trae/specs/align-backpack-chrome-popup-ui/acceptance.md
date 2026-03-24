# 手工验收清单（扩展 Popup）

## 基础
- 打开扩展 Popup 后不报错，首屏为 Tabs（Tokens/Collectibles/Activity）
- Root Header 显示：左头像按钮、中间钱包按钮、右设置按钮

## Tabs
- 点击 Tokens/Collectibles/Activity 顶部 Tab 即时切换（无动画）
- 三个列表均可展示多条数据，列表项 hover/click 样式一致

## 详情页（P0）
- Tokens 列表点任意项进入 Token 详情页，点击左上角返回回到 Tabs
- Activity 列表点任意项进入 Activity 详情页，点击左上角返回回到 Tabs

## Wallet Drawer / AvatarPopover / Settings
- 点击 Header 中间钱包按钮：弹出 Wallets 列表，切换钱包后 Header 文案变化
- 点击 Header 左头像按钮：弹出 Account 面板，点击“锁定”进入 Unlock 屏
- 点击 Header 右设置按钮：弹出 Settings 面板，点击“完成”关闭

## Search（透明模态）
- 在 Tabs 或详情页按 `/`：打开 Search 透明模态并自动聚焦输入框
- 输入关键字：结果列表实时更新（匹配 Tokens/Collectibles/Activity）
- 按 `Esc` 或点击遮罩：关闭 Search，并回到原页面

## Send（多屏流程）
- 点击“发送”：进入 SendTokenSelectScreen（模态）
- 选择 Token → 下一步：进入地址页
- 地址页输入非法 cosmos 地址：阻止进入下一步并提示错误
- 输入合法地址 → 下一步：进入金额页
- 金额页输入非法金额/过长 memo：阻止进入下一步并提示错误
- 金额页输入合法值 → 确认：进入确认页
- 确认页点击“确认发送”：出现广播中状态，随后出现成功反馈
- 在任意 Send 步骤按 `Esc`：退出 Send 流程并回到进入前页面
