param(
  [string]$TargetFile = "deploy/monitoring/generated/chaos-alert-rules.yaml",
  [string]$ReportDir = "reports/staging"
)

if (-not (Test-Path $TargetFile)) {
  throw "Target file not found: $TargetFile"
}

New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupFile = "$TargetFile.bak.$timestamp"
$candidateFile = "$TargetFile.candidate.$timestamp"
$reportFile = Join-Path $ReportDir "rollback-drill-$timestamp.md"

Copy-Item -Path $TargetFile -Destination $backupFile -Force
$originalHash = (Get-FileHash -Path $TargetFile -Algorithm SHA256).Hash
$originalContent = Get-Content -Path $TargetFile -Raw

$badContent = $originalContent + "`n# rollback drill invalid append`n- invalid: true`n"
Set-Content -Path $candidateFile -Value $badContent -Encoding UTF8
Copy-Item -Path $candidateFile -Destination $TargetFile -Force

$afterDrillHash = (Get-FileHash -Path $TargetFile -Algorithm SHA256).Hash
$rolledBack = $false

if ($afterDrillHash -ne $originalHash) {
  Copy-Item -Path $backupFile -Destination $TargetFile -Force
  $restoredHash = (Get-FileHash -Path $TargetFile -Algorithm SHA256).Hash
  if ($restoredHash -eq $originalHash) {
    $rolledBack = $true
  }
}

$lines = @()
$lines += "# Rollback Drill Report"
$lines += ""
$lines += "- generatedAt: $(Get-Date -Format o)"
$lines += "- targetFile: $TargetFile"
$lines += "- backupFile: $backupFile"
$lines += "- candidateFile: $candidateFile"
$lines += "- rollbackSuccess: $rolledBack"
$lines += "- originalHash: $originalHash"
$lines += ""

Set-Content -Path $reportFile -Value $lines -Encoding UTF8
Write-Output "Rollback drill report generated: $reportFile"

if (-not $rolledBack) {
  throw "Rollback drill failed"
}
