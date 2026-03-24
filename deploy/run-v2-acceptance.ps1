param(
  [string]$TemplatePath = "deploy/v2-acceptance-template.json",
  [string]$Version,
  [string]$Milestone
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$resolvedTemplate = if ([System.IO.Path]::IsPathRooted($TemplatePath)) { $TemplatePath } else { Join-Path $repoRoot $TemplatePath }
if (-not (Test-Path $resolvedTemplate)) {
  throw "Template file not found: $resolvedTemplate"
}

$template = Get-Content -Raw -Path $resolvedTemplate | ConvertFrom-Json
$effectiveVersion = if ($Version) { $Version } else { "$($template.version)" }
if ([string]::IsNullOrWhiteSpace($effectiveVersion)) {
  throw "Version is required. Set version in template or pass -Version."
}

$effectiveMilestone = if ($Milestone) { $Milestone } else { "$($template.milestone)" }
if ([string]::IsNullOrWhiteSpace($effectiveMilestone)) {
  $effectiveMilestone = "P2-Complete"
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportRoot = Join-Path $repoRoot "deploy/reports/p2-acceptance"
$archiveDir = Join-Path $reportRoot ("archive/{0}" -f $effectiveVersion)
$runDir = Join-Path $archiveDir $timestamp
$logDir = Join-Path $runDir "logs"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

$moduleResults = New-Object System.Collections.ArrayList
$gateResults = New-Object System.Collections.ArrayList

foreach ($module in $template.modules) {
  $moduleName = "$($module.name)"
  $modulePath = Resolve-Path (Join-Path $repoRoot "$($module.path)")
  $modulePassed = $true
  $moduleGateResults = @()

  foreach ($gate in $module.gates) {
    $gateName = "$($gate.name)"
    $command = "$($gate.command)"
    $safeModule = $moduleName -replace "[^A-Za-z0-9\-_]", "_"
    $safeGate = $gateName -replace "[^A-Za-z0-9\-_]", "_"
    $stdoutPath = Join-Path $logDir ("{0}-{1}-stdout.log" -f $safeModule, $safeGate)
    $stderrPath = Join-Path $logDir ("{0}-{1}-stderr.log" -f $safeModule, $safeGate)

    Write-Output ("[{0}/{1}] {2}" -f $moduleName, $gateName, $command)
    $startedAt = Get-Date
    $proc = Start-Process -FilePath "powershell" -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $command -WorkingDirectory $modulePath -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath -PassThru -Wait
    $endedAt = Get-Date
    $durationMs = [int]($endedAt - $startedAt).TotalMilliseconds
    $exitCode = [int]$proc.ExitCode
    $status = if ($exitCode -eq 0) { "pass" } else { "fail" }

    if ($status -eq "fail") {
      $modulePassed = $false
    }

    $stdoutTail = ""
    $stderrTail = ""
    if (Test-Path $stdoutPath) {
      $stdoutTail = (Get-Content -Path $stdoutPath -Tail 20) -join [Environment]::NewLine
    }
    if (Test-Path $stderrPath) {
      $stderrTail = (Get-Content -Path $stderrPath -Tail 20) -join [Environment]::NewLine
    }

    $record = [ordered]@{
      module = $moduleName
      modulePath = "$modulePath"
      gate = $gateName
      command = $command
      status = $status
      exitCode = $exitCode
      durationMs = $durationMs
      startedAt = $startedAt.ToString("o")
      endedAt = $endedAt.ToString("o")
      stdoutLog = $stdoutPath
      stderrLog = $stderrPath
      stdoutTail = $stdoutTail
      stderrTail = $stderrTail
    }

    [void]$gateResults.Add([PSCustomObject]$record)
    $moduleGateResults += [PSCustomObject]$record
  }

  [void]$moduleResults.Add([PSCustomObject]@{
    module = $moduleName
    modulePath = "$modulePath"
    totalGates = @($module.gates).Count
    passedGates = @($moduleGateResults | Where-Object { $_.status -eq "pass" }).Count
    failedGates = @($moduleGateResults | Where-Object { $_.status -eq "fail" }).Count
    status = if ($modulePassed) { "pass" } else { "fail" }
  })
}

$failedGates = @($gateResults | Where-Object { $_.status -eq "fail" })
$overallStatus = if (@($failedGates).Count -eq 0) { "pass" } else { "fail" }

$jsonReportPath = Join-Path $runDir "v2-acceptance-summary.json"
$markdownReportPath = Join-Path $runDir "v2-acceptance-summary.md"
$templateSnapshotPath = Join-Path $runDir "v2-acceptance-template.snapshot.json"
$latestJsonPath = Join-Path $reportRoot "latest.json"
$latestMarkdownPath = Join-Path $reportRoot "latest.md"

$report = [ordered]@{
  generatedAt = (Get-Date).ToString("o")
  templateVersion = "$($template.templateVersion)"
  milestone = $effectiveMilestone
  version = $effectiveVersion
  overallStatus = $overallStatus
  totalModules = @($moduleResults).Count
  failedModules = @($moduleResults | Where-Object { $_.status -eq "fail" }).Count
  totalGates = @($gateResults).Count
  failedGates = @($failedGates).Count
  reportPath = $markdownReportPath
  archivePath = $runDir
  modules = $moduleResults
  gates = $gateResults
  failedDetails = $failedGates
}

$report | ConvertTo-Json -Depth 8 | Set-Content -Path $jsonReportPath -Encoding UTF8
Get-Content -Raw -Path $resolvedTemplate | Set-Content -Path $templateSnapshotPath -Encoding UTF8

$lines = @()
$lines += "# V2 Acceptance Summary"
$lines += ""
$lines += "- generatedAt: $($report.generatedAt)"
$lines += "- templateVersion: $($report.templateVersion)"
$lines += "- milestone: $($report.milestone)"
$lines += "- version: $($report.version)"
$lines += "- overallStatus: $($report.overallStatus)"
$lines += "- totalModules: $($report.totalModules)"
$lines += "- failedModules: $($report.failedModules)"
$lines += "- totalGates: $($report.totalGates)"
$lines += "- failedGates: $($report.failedGates)"
$lines += "- archivePath: $runDir"
$lines += ""
$lines += "## Module Status"
$lines += ""
$lines += "| module | status | passedGates | failedGates |"
$lines += "|---|---|---:|---:|"
foreach ($module in $moduleResults) {
  $lines += "| $($module.module) | $($module.status) | $($module.passedGates) | $($module.failedGates) |"
}
$lines += ""
$lines += "## Gate Details"
$lines += ""
$lines += "| module | gate | status | exitCode | durationMs |"
$lines += "|---|---|---|---:|---:|"
foreach ($gate in $gateResults) {
  $lines += "| $($gate.module) | $($gate.gate) | $($gate.status) | $($gate.exitCode) | $($gate.durationMs) |"
}
$lines += ""
$lines += "## Failure Details"
$lines += ""
if (@($failedGates).Count -eq 0) {
  $lines += "- none"
} else {
  foreach ($detail in $failedGates) {
    $lines += "### $($detail.module) / $($detail.gate)"
    $lines += "- command: $($detail.command)"
    $lines += "- exitCode: $($detail.exitCode)"
    $lines += "- stdoutLog: $($detail.stdoutLog)"
    $lines += "- stderrLog: $($detail.stderrLog)"
    if (-not [string]::IsNullOrWhiteSpace("$($detail.stdoutTail)")) {
      $lines += "- stdoutTail:"
      $lines += '```'
      $lines += "$($detail.stdoutTail)"
      $lines += '```'
    }
    if (-not [string]::IsNullOrWhiteSpace("$($detail.stderrTail)")) {
      $lines += "- stderrTail:"
      $lines += '```'
      $lines += "$($detail.stderrTail)"
      $lines += '```'
    }
    $lines += ""
  }
}

Set-Content -Path $markdownReportPath -Value $lines -Encoding UTF8
Set-Content -Path $latestMarkdownPath -Value $lines -Encoding UTF8
$report | ConvertTo-Json -Depth 8 | Set-Content -Path $latestJsonPath -Encoding UTF8

Write-Output ("V2 acceptance report generated: {0}" -f $markdownReportPath)
Write-Output ("V2 acceptance json generated: {0}" -f $jsonReportPath)
Write-Output ("V2 acceptance archive directory: {0}" -f $runDir)

if ($overallStatus -eq "fail") {
  throw ("V2 acceptance failed. failedGates={0}" -f @($failedGates).Count)
}
