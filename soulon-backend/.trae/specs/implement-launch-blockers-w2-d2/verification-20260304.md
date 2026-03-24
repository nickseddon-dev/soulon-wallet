# Task4 门禁复验记录（2026-03-04）

## 执行命令

1. 前端质量门禁（wallet-app）
   - `npm run validate`
2. 后端基础测试（soulon-backend）
   - `go test ./...`
3. 链端测试网启动脚本 DryRun（soulon-deep-chain）
   - `powershell -ExecutionPolicy Bypass -File .\soulon-deep-chain\scripts\start-testnet.ps1 -EnvFile ..\deploy\testnet\testnet.env.example -DryRun`
4. 链端运维状态检查（soulon-deep-chain）
   - `powershell -ExecutionPolicy Bypass -File .\soulon-deep-chain\scripts\testnet-ops.ps1 -Action status -EnvFile ..\deploy\testnet\testnet.env.example`
5. W2+D2 一体化入口复验（workspace）
   - `powershell -ExecutionPolicy Bypass -File .\deploy\run-deploy-test.ps1`

## 结果摘要

- `npm run validate`：exit code 0（lint/typecheck/build 全部通过）
- `go test ./...`：exit code 0（全量通过）
- `start-testnet.ps1 -DryRun`：exit code 0
- `testnet-ops.ps1 -Action status`：exit code 0
- `run-deploy-test.ps1`：exit code 0

## 上线结论

W2 与 D2 阻断项关键门禁命令复验通过，Task4 与 checklist 可勾选完成，当前规格满足“可正式上线”判定。
