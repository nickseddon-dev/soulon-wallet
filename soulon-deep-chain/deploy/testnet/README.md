# Soulon Deep Chain 测试网部署参数

## 准备

1. 复制 `testnet.env.example` 为 `testnet.env`。
2. 根据机器资源与端口占用调整参数。
3. 确保链二进制可执行文件可用。

## 启动

```powershell
cd ..\..\scripts
.\start-testnet.ps1 -ChainBinary soulond -EnvFile ..\deploy\testnet\testnet.env -Reset
```

## DryRun

```powershell
cd ..\..\scripts
.\start-testnet.ps1 -ChainBinary soulond -EnvFile ..\deploy\testnet\testnet.env.example -DryRun
```
