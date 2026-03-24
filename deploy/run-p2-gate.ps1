param(
  [string]$Version = "v2.0.0",
  [string]$Milestone = "P2-Complete",
  [string]$TemplatePath = "deploy/v2-acceptance-template.json"
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
    throw "P2 gate run failed"
  }
} finally {
  Pop-Location
}
