$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$chaosDir = Join-Path $repoRoot "reports\chaos"
$stagingDir = Join-Path $repoRoot "reports\staging"
$outputDir = Join-Path $repoRoot "reports\release-readiness"
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

$latestChaos = Get-ChildItem -Path $chaosDir -Filter "chaos-validation-summary-*.md" -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $latestChaos) {
  throw "No chaos validation summary found under $chaosDir"
}

$latestRollback = Get-ChildItem -Path $stagingDir -Filter "rollback-drill-*.md" -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $latestRollback) {
  throw "No rollback drill report found under $stagingDir"
}

$chaosContent = Get-Content -Path $latestChaos.FullName -Raw
$metricValidationPass = $chaosContent -match "metricValidation:\s+pass"
$alertRuleValidationPass = $chaosContent -match "alertRuleValidation:\s+pass"
if (-not $metricValidationPass) {
  throw "Chaos metric validation is not pass in $($latestChaos.Name)"
}
if (-not $alertRuleValidationPass) {
  throw "Chaos alert rule validation is not pass in $($latestChaos.Name)"
}

$rollbackContent = Get-Content -Path $latestRollback.FullName -Raw
$rollbackSuccess = $rollbackContent -match "rollbackSuccess:\s+True"
if (-not $rollbackSuccess) {
  throw "Rollback drill is not successful in $($latestRollback.Name)"
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$summaryPath = Join-Path $outputDir "release-readiness-check-$timestamp.md"
$lines = @()
$lines += "# Release Readiness Check"
$lines += ""
$lines += "- generatedAt: $(Get-Date -Format o)"
$lines += "- performanceBaselineSummary: $($latestChaos.FullName)"
$lines += "- rollbackDrillReport: $($latestRollback.FullName)"
$lines += "- metricValidation: pass"
$lines += "- alertRuleValidation: pass"
$lines += "- rollbackDrill: pass"
$lines += ""
$lines += "## Gate Result"
$lines += ""
$lines += "- status: pass"

Set-Content -Path $summaryPath -Value $lines -Encoding UTF8
Write-Output "Release readiness check summary generated: $summaryPath"
