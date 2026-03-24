# 手工验收清单（Flutter Settings）

## 入口
- 从任意入口进入 Settings（路由：`/replica/mobile/settings`）后不报错
- Settings Root 分组入口可见：Your Account / Wallets / Preferences / About / Security

## Wallets
- 进入 Wallets 列表：能看到多条钱包 mock 数据
- 点击任意钱包进入详情：可进入 Rename / Remove / Show Private Key（警告）路径
- Add Wallet 流程：Add Wallet → Select Flow → Create/Import/Private Key/Hardware 页面均可进入并返回

## Your Account
- 进入 Your Account：Update Name / Change Password / Show Recovery Phrase Warning / Remove Account 均可进入并返回
- Show Recovery Phrase：先看到警告，确认后提示 mock 不展示敏感内容

## Preferences
- Preferences Root 可进入：Auto Lock / Language / Hidden Tokens / Trusted Sites / Blockchain
- Auto Lock 与 Language：选择后返回 Root 仍显示最新值
- Blockchain：可进入 RPC Connection / Custom RPC / Commitment / Explorer 并可返回

## About
- About 页面可进入，信息块样式/布局符合深色令牌
