param(
  [string]$Version = "v2.2.0",
  [string]$Milestone = "Wallet-Production-Architecture",
  [string]$TemplatePath = "deploy/wallet-production-gate-template.json"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$runnerPath = Join-Path $PSScriptRoot "run-v2-acceptance.ps1"

if (-not (Test-Path $runnerPath)) {
  throw "Runner script not found: $runnerPath"
}

Push-Location $repoRoot
try {
  powershell -ExecutionPolicy Bypass -File $runnerPath -TemplatePath $TemplatePath -Version $Version -Milestone $Milestone
  if ($LASTEXITCODE -ne 0) {
    throw "Wallet production gate run failed"
  }
} finally {
  Pop-Location
}
