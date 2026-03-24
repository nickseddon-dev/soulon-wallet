# Soulon Deep Chain 本地部署测试

## 准备

1. 复制 `localnet.env.example` 为 `localnet.env`。
2. 确保链二进制可执行文件可用。

## 初始化链脚手架

在 `soulon-deep-chain/scripts` 下执行：

```powershell
.\bootstrap-chain.ps1 -ChainName soulon -ModulePath github.com/soulon/soulon
```

## 启动本地链

在 `soulon-deep-chain/scripts` 下执行：

```powershell
.\start-localnet.ps1 -ChainBinary soulond -EnvFile ..\deploy\localnet\localnet.env -Reset
```

## 仅验证脚本流程

```powershell
.\start-localnet.ps1 -ChainBinary soulond -EnvFile ..\deploy\localnet\localnet.env -DryRun
```
