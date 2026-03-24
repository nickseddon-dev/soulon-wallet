param(
  [string]$ReportDir = "reports/chaos",
  [string]$OutputFile = "deploy/monitoring/generated/chaos-alert-rules.yaml",
  [switch]$ValidateOnly
)

function Get-LatestRuleJson {
  param([string]$Directory)
  if (-not (Test-Path $Directory)) {
    throw "Report directory not found: $Directory"
  }
  $file = Get-ChildItem -Path $Directory -Filter "chaos-alert-rules-*.json" -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $file) {
    throw "No chaos alert rules json found in $Directory"
  }
  return $file
}

function Test-RuleRange {
  param([object]$Rules)
  foreach ($rule in $Rules.globalRules) {
    if (-not $rule.name -or -not $rule.severity -or $null -eq $rule.threshold) {
      throw "Invalid global rule: $($rule | ConvertTo-Json -Compress)"
    }
    if ($rule.unit -eq "percent") {
      $value = [double]$rule.threshold
      if ($value -lt 1 -or $value -gt 100) {
        throw "Percent threshold out of range in $($rule.name): $value"
      }
    }
    if ($rule.unit -eq "ms") {
      $value = [double]$rule.threshold
      if ($value -lt 1000 -or $value -gt 60000) {
        throw "Duration threshold out of range in $($rule.name): $value"
      }
    }
    if ($rule.unit -eq "count") {
      $value = [double]$rule.threshold
      if ($value -lt 1 -or $value -gt 10) {
        throw "Count threshold out of range in $($rule.name): $value"
      }
    }
  }
}

function Convert-ToPrometheusRuleText {
  param([object]$Rules)
  $lines = @()
  $lines += "groups:"
  $lines += "  - name: chaos-generated-rules"
  $lines += "    rules:"
  foreach ($rule in $Rules.globalRules) {
    $lines += "      - alert: $($rule.name)"
    $lines += "        expr: $($rule.expr)"
    $lines += "        for: $($rule.window)"
    $lines += "        labels:"
    $lines += "          severity: $($rule.severity)"
    $lines += "          source: chaos"
    $lines += "        annotations:"
    $lines += "          summary: $($rule.description)"
    $lines += "          threshold: `"$($rule.threshold)`""
    $lines += "          unit: `"$($rule.unit)`""
  }
  foreach ($rule in $Rules.scenarioRules) {
    $lines += "      - alert: $($rule.name)"
    $lines += "        expr: $($rule.expr)"
    $lines += "        for: 5m"
    $lines += "        labels:"
    $lines += "          severity: $($rule.severity)"
    $lines += "          source: chaos"
    $lines += "          scenario: $($rule.scenario)"
    $lines += "        annotations:"
    $lines += "          summary: $($rule.description)"
    $lines += "          riskLevel: `"$($rule.riskLevel)`""
    $lines += "          recoveryAction: `"$($rule.recoveryAction)`""
  }
  return ($lines -join "`n")
}

$latestFile = Get-LatestRuleJson -Directory $ReportDir
$rules = Get-Content -Path $latestFile.FullName -Raw | ConvertFrom-Json
Test-RuleRange -Rules $rules

if ($ValidateOnly) {
  Write-Output "Alert rule suggestions validated: $($latestFile.Name)"
  exit 0
}

$outputDirectory = Split-Path -Path $OutputFile -Parent
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$yamlText = Convert-ToPrometheusRuleText -Rules $rules
Set-Content -Path $OutputFile -Value $yamlText -Encoding UTF8
Write-Output "Alert rules generated: $OutputFile"
