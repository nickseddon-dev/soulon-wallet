param(
  [string]$ChainBinary = "soulond",
  [switch]$Online,
  [switch]$BusinessTest
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$chainScriptDir = Join-Path $repoRoot "soulon-deep-chain\scripts"
$walletDir = Join-Path $repoRoot "soulon-wallet"

Write-Output "Step1(D2): testnet startup script dry run"
Push-Location $chainScriptDir
powershell -ExecutionPolicy Bypass -File .\start-testnet.ps1 -ChainBinary $ChainBinary -EnvFile ..\deploy\testnet\testnet.env.example -DryRun
if ($LASTEXITCODE -ne 0) {
  throw "Testnet startup dry run failed"
}
Write-Output "Step1(D2): testnet ops status check"
powershell -ExecutionPolicy Bypass -File .\testnet-ops.ps1 -Action status -EnvFile ..\deploy\testnet\testnet.env.example
if ($LASTEXITCODE -ne 0) {
  throw "Testnet ops status check failed"
}
Pop-Location

Write-Output "Step2(W2): wallet testnet e2e"
Push-Location $walletDir
if ($Online) {
  Remove-Item Env:SOULON_SKIP_NETWORK_TEST -ErrorAction SilentlyContinue
  npm run test:e2e
} else {
  $env:SOULON_SKIP_NETWORK_TEST = "1"
  npm run test:e2e
}
if ($LASTEXITCODE -ne 0) {
  throw "Wallet testnet e2e failed"
}

if ($BusinessTest) {
  Write-Output "Step3: wallet business integration test (optional)"
  if ($Online) {
    Remove-Item Env:SOULON_SKIP_NETWORK_TEST -ErrorAction SilentlyContinue
  } else {
    $env:SOULON_SKIP_NETWORK_TEST = "1"
  }
  npm run test:business
  if ($LASTEXITCODE -ne 0) {
    throw "Wallet business integration test failed"
  }
}
Pop-Location

Write-Output "W2+D2 integrated deploy flow completed"
