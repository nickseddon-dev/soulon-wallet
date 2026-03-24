param(
  [int]$Iterations = 2,
  [int]$TrendWindow = 5,
  [string]$ReportDir = "reports/staging"
)

$ErrorActionPreference = "Stop"

New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportFile = Join-Path $ReportDir "staging-drill-$timestamp.md"

$results = New-Object System.Collections.ArrayList
$failed = $false
$failureMessage = ""

function Invoke-Step {
  param(
    [string]$Name,
    [scriptblock]$Action,
    [ref]$ResultList
  )
  $started = Get-Date
  try {
    & $Action
    $duration = [int]((Get-Date) - $started).TotalMilliseconds
    [void]$ResultList.Value.Add([PSCustomObject]@{
      step = $Name
      status = "pass"
      durationMs = $duration
      message = "ok"
    })
  } catch {
    $duration = [int]((Get-Date) - $started).TotalMilliseconds
    [void]$ResultList.Value.Add([PSCustomObject]@{
      step = $Name
      status = "fail"
      durationMs = $duration
      message = $_.Exception.Message
    })
    throw
  }
}

try {
  Invoke-Step -Name "integration_e2e" -ResultList ([ref]$results) -Action {
    & "$PSScriptRoot/run-integration.ps1"
    if ($LASTEXITCODE -ne 0) {
      throw "run-integration failed"
    }
  }

  Invoke-Step -Name "chaos_report" -ResultList ([ref]$results) -Action {
    & "$PSScriptRoot/run-chaos-report.ps1" -Iterations $Iterations -TrendWindow $TrendWindow
    if ($LASTEXITCODE -ne 0) {
      throw "run-chaos-report failed"
    }
  }

  Invoke-Step -Name "publish_alert_rules" -ResultList ([ref]$results) -Action {
    & "$PSScriptRoot/publish-alert-rules.ps1"
    if ($LASTEXITCODE -ne 0) {
      throw "publish-alert-rules failed"
    }
  }

  Invoke-Step -Name "rollback_drill" -ResultList ([ref]$results) -Action {
    & "$PSScriptRoot/run-rollback-drill.ps1"
    if ($LASTEXITCODE -ne 0) {
      throw "run-rollback-drill failed"
    }
  }
} catch {
  $failed = $true
  $failureMessage = $_.Exception.Message
}
finally {
  $passCount = @($results | Where-Object { $_.status -eq "pass" }).Count
  $failCount = @($results | Where-Object { $_.status -eq "fail" }).Count
  $lines = @()
  $lines += "# Staging End-to-End Drill Report"
  $lines += ""
  $lines += "- generatedAt: $(Get-Date -Format o)"
  $lines += "- iterations: $Iterations"
  $lines += "- trendWindow: $TrendWindow"
  $lines += "- pass: $passCount"
  $lines += "- fail: $failCount"
  $lines += ""
  $lines += "| step | status | durationMs | message |"
  $lines += "|---|---|---:|---|"
  foreach ($item in $results) {
    $message = "$($item.message)".Replace("|", "/").Replace("`r", " ").Replace("`n", " ")
    $lines += "| $($item.step) | $($item.status) | $($item.durationMs) | $message |"
  }
  Set-Content -Path $reportFile -Value $lines -Encoding UTF8
  Write-Output "Staging drill report generated: $reportFile"
}

if ($failed) {
  throw $failureMessage
}
