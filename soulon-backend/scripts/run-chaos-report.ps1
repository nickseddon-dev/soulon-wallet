param(
  [string]$ComposeFile = "docker-compose.integration.yml",
  [string]$ProjectName = "soulon-chaos-$PID",
  [int]$Iterations = 2,
  [int]$TrendWindow = 5
)

function Find-FreePort {
  param([int]$Start)
  for ($port = $Start; $port -lt ($Start + 300); $port++) {
    try {
      $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $port)
      $listener.Start()
      $listener.Stop()
      return $port
    } catch {
    }
  }
  throw "No free port found from $Start"
}

function Wait-Healthy {
  param(
    [string]$ComposeFilePath,
    [string]$Project,
    [string]$Service
  )
  $containerId = docker compose -f $ComposeFilePath -p $Project ps -q $Service
  if (-not $containerId) {
    throw "Container not found for service $Service"
  }
  for ($i = 0; $i -lt 60; $i++) {
    $status = docker inspect --format='{{.State.Health.Status}}' $containerId 2>$null
    if ($status -eq "healthy") {
      return
    }
    Start-Sleep -Seconds 2
  }
  throw "Service $Service did not become healthy"
}

function Invoke-E2E {
  param(
    [string]$KafkaPort,
    [string]$PostgresPort
  )
  $started = Get-Date
  $env:RUN_E2E = "1"
  $env:INDEXER_KAFKA_BROKERS = "127.0.0.1:$KafkaPort"
  $env:INDEXER_POSTGRES_DSN = "postgres://postgres:postgres@127.0.0.1:$PostgresPort/soulon_indexer?sslmode=disable"
  $output = & go test ./internal/indexer -run TestKafkaAndPostgresIntegration -v 2>&1
  $duration = [int]((Get-Date) - $started).TotalMilliseconds
  if ($LASTEXITCODE -eq 0) {
    return @{
      status = "pass"
      durationMs = $duration
      message = "ok"
    }
  }
  $joined = ($output | Out-String).Trim()
  if ($joined.Length -gt 280) {
    $joined = $joined.Substring($joined.Length - 280)
  }
  return @{
    status = "fail"
    durationMs = $duration
    message = $joined
  }
}

function Add-Result {
  param(
    [ref]$Rows,
    [string]$Scenario,
    [int]$Iteration,
    [hashtable]$Result
  )
  $Rows.Value += [PSCustomObject]@{
    scenario = $Scenario
    iteration = $Iteration
    status = $Result.status
    durationMs = $Result.durationMs
    message = $Result.message
  }
}

function Get-RiskAssessment {
  param(
    [int]$Fail,
    [int]$Total,
    [int]$AvgDurationMs
  )
  $failRate = 0.0
  if ($Total -gt 0) {
    $failRate = ($Fail * 100.0) / $Total
  }
  if ($failRate -ge 50 -or $AvgDurationMs -ge 15000) {
    return @{
      riskLevel = "high"
      recoveryAction = "Immediate rollback and investigate dependencies"
    }
  }
  if ($failRate -ge 20 -or $AvgDurationMs -ge 8000) {
    return @{
      riskLevel = "medium"
      recoveryAction = "Scale services and rerun scenario with focused logs"
    }
  }
  return @{
    riskLevel = "low"
    recoveryAction = "Continue monitoring with routine verification"
  }
}

function Get-ScenarioSummary {
  param([array]$Rows)
  $summary = @()
  $groups = $Rows | Group-Object -Property scenario
  foreach ($group in $groups) {
    $items = @($group.Group)
    $total = $items.Count
    $pass = ($items | Where-Object { $_.status -eq "pass" }).Count
    $fail = ($items | Where-Object { $_.status -eq "fail" }).Count
    $avg = 0
    if ($total -gt 0) {
      $avg = [int](($items | Measure-Object -Property durationMs -Average).Average)
    }
    $risk = Get-RiskAssessment -Fail $fail -Total $total -AvgDurationMs $avg
    $summary += [PSCustomObject]@{
      scenario = $group.Name
      total = $total
      pass = $pass
      fail = $fail
      passRate = if ($total -gt 0) { [math]::Round(($pass * 100.0) / $total, 2) } else { 0 }
      avgDurationMs = $avg
      riskLevel = $risk.riskLevel
      recoveryAction = $risk.recoveryAction
    }
  }
  return $summary | Sort-Object -Property scenario
}

function Get-HistoryTrend {
  param(
    [string]$DirectoryPath,
    [int]$Window
  )
  if (-not (Test-Path $DirectoryPath)) {
    return @()
  }
  $files = Get-ChildItem -Path $DirectoryPath -Filter "chaos-report-*.md" -File | Sort-Object LastWriteTime -Descending | Select-Object -First $Window
  $rows = @()
  foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName
    $totalLine = $content | Where-Object { $_ -match "^- total:\s+\d+" } | Select-Object -First 1
    $passLine = $content | Where-Object { $_ -match "^- pass:\s+\d+" } | Select-Object -First 1
    $failLine = $content | Where-Object { $_ -match "^- fail:\s+\d+" } | Select-Object -First 1
    $avgLine = $content | Where-Object { $_ -match "^- averageDurationMs:\s+\d+" } | Select-Object -First 1
    $total = if ($totalLine) { [int]($totalLine -replace "^- total:\s+", "") } else { 0 }
    $pass = if ($passLine) { [int]($passLine -replace "^- pass:\s+", "") } else { 0 }
    $fail = if ($failLine) { [int]($failLine -replace "^- fail:\s+", "") } else { 0 }
    $avg = if ($avgLine) { [int]($avgLine -replace "^- averageDurationMs:\s+", "") } else { 0 }
    $failRate = if ($total -gt 0) { [math]::Round(($fail * 100.0) / $total, 2) } else { 0 }
    $rows += [PSCustomObject]@{
      report = $file.Name
      total = $total
      pass = $pass
      fail = $fail
      failRate = $failRate
      passRate = if ($total -gt 0) { [math]::Round(($pass * 100.0) / $total, 2) } else { 0 }
      averageDurationMs = $avg
      generatedAt = $file.LastWriteTime.ToString("o")
    }
  }
  return $rows | Sort-Object -Property generatedAt
}

function Get-Percentile {
  param(
    [double[]]$Values,
    [double]$Percentile
  )
  if (-not $Values -or $Values.Count -eq 0) {
    return 0
  }
  $sorted = $Values | Sort-Object
  $index = [int][math]::Ceiling(($Percentile / 100.0) * $sorted.Count) - 1
  if ($index -lt 0) {
    $index = 0
  }
  if ($index -ge $sorted.Count) {
    $index = $sorted.Count - 1
  }
  return [double]$sorted[$index]
}

function Get-HistoricalThresholdSuggestion {
  param([array]$HistoryRows)
  $sortedRows = @($HistoryRows | Sort-Object -Property generatedAt)
  if ($sortedRows.Count -eq 0) {
    return [PSCustomObject]@{
      sampleSize = 0
      errorRate = [PSCustomObject]@{
        latestPct = 0
        p90Pct = 0
        averagePct = 0
        recommendedPct = 20
      }
      duration = [PSCustomObject]@{
        latestMs = 0
        p90Ms = 0
        averageMs = 0
        recommendedMs = 8000
      }
      consecutiveFailures = [PSCustomObject]@{
        latestStreak = 0
        maxObservedStreak = 0
        recommendedCount = 2
      }
    }
  }
  $errorRates = @($sortedRows | ForEach-Object { [double]$_.failRate })
  $durations = @($sortedRows | ForEach-Object { [double]$_.averageDurationMs })
  $errorRateAvg = [double](($errorRates | Measure-Object -Average).Average)
  $durationAvg = [double](($durations | Measure-Object -Average).Average)
  $errorRateP90 = Get-Percentile -Values $errorRates -Percentile 90
  $durationP90 = Get-Percentile -Values $durations -Percentile 90
  $recommendedErrorRate = [math]::Round([math]::Min(60, [math]::Max(5, $errorRateP90 + 5)), 2)
  $recommendedDuration = [int]([math]::Min(60000, [math]::Max(2000, [math]::Ceiling($durationP90 * 1.2))))

  $maxStreak = 0
  $currentStreak = 0
  foreach ($row in $sortedRows) {
    if ([int]$row.fail -gt 0) {
      $currentStreak++
    } else {
      $currentStreak = 0
    }
    if ($currentStreak -gt $maxStreak) {
      $maxStreak = $currentStreak
    }
  }
  $latestStreak = $currentStreak
  $recommendedConsecutive = [int]([math]::Min(6, [math]::Max(2, $maxStreak + 1)))
  $latest = $sortedRows[$sortedRows.Count - 1]

  return [PSCustomObject]@{
    sampleSize = $sortedRows.Count
    errorRate = [PSCustomObject]@{
      latestPct = [math]::Round([double]$latest.failRate, 2)
      p90Pct = [math]::Round($errorRateP90, 2)
      averagePct = [math]::Round($errorRateAvg, 2)
      recommendedPct = $recommendedErrorRate
    }
    duration = [PSCustomObject]@{
      latestMs = [int]$latest.averageDurationMs
      p90Ms = [int][math]::Round($durationP90, 0)
      averageMs = [int][math]::Round($durationAvg, 0)
      recommendedMs = $recommendedDuration
    }
    consecutiveFailures = [PSCustomObject]@{
      latestStreak = $latestStreak
      maxObservedStreak = $maxStreak
      recommendedCount = $recommendedConsecutive
    }
  }
}

function Normalize-Message {
  param([string]$Value)
  return "$Value".Replace("|", "/").Replace("`r", " ").Replace("`n", " ")
}

function Get-SeverityByRiskLevel {
  param([string]$RiskLevel)
  switch ($RiskLevel) {
    "high" { return "critical" }
    "medium" { return "warning" }
    default { return "info" }
  }
}

function Get-AlertRuleSuggestions {
  param(
    [array]$ScenarioSummary,
    [object]$ThresholdSuggestions
  )
  $globalRules = @()
  $globalRules += [PSCustomObject]@{
    name = "chaos_error_rate_pct_high"
    expr = "chaos_fail_rate_pct > $($ThresholdSuggestions.errorRate.recommendedPct)"
    threshold = $ThresholdSuggestions.errorRate.recommendedPct
    unit = "percent"
    severity = "warning"
    window = "5m"
    description = "Chaos error rate exceeds recommended threshold"
  }
  $globalRules += [PSCustomObject]@{
    name = "chaos_average_duration_ms_high"
    expr = "chaos_average_duration_ms > $($ThresholdSuggestions.duration.recommendedMs)"
    threshold = $ThresholdSuggestions.duration.recommendedMs
    unit = "ms"
    severity = "warning"
    window = "5m"
    description = "Chaos average duration exceeds recommended threshold"
  }
  $globalRules += [PSCustomObject]@{
    name = "chaos_consecutive_failures_high"
    expr = "chaos_consecutive_failures > $($ThresholdSuggestions.consecutiveFailures.recommendedCount)"
    threshold = $ThresholdSuggestions.consecutiveFailures.recommendedCount
    unit = "count"
    severity = "critical"
    window = "10m"
    description = "Chaos consecutive failures exceed recommended threshold"
  }

  $scenarioRules = @()
  foreach ($item in $ScenarioSummary) {
    if ($item.riskLevel -eq "low") {
      continue
    }
    $scenarioExpr = "chaos_scenario_fail_rate_pct{scenario=""" + $item.scenario + """} > 0"
    $scenarioRules += [PSCustomObject]@{
      name = "chaos_scenario_" + $item.scenario + "_" + $item.riskLevel
      scenario = $item.scenario
      expr = $scenarioExpr
      threshold = 0
      unit = "percent"
      severity = Get-SeverityByRiskLevel -RiskLevel $item.riskLevel
      riskLevel = $item.riskLevel
      recoveryAction = $item.recoveryAction
      description = "Scenario $($item.scenario) has $($item.riskLevel) risk"
    }
  }

  return [PSCustomObject]@{
    globalRules = $globalRules
    scenarioRules = $scenarioRules
  }
}

function Get-ConsecutiveFailureStreak {
  param([array]$Rows)
  $maxStreak = 0
  $currentStreak = 0
  foreach ($row in $Rows) {
    if ("$($row.status)" -eq "fail") {
      $currentStreak++
      if ($currentStreak -gt $maxStreak) {
        $maxStreak = $currentStreak
      }
    } else {
      $currentStreak = 0
    }
  }
  return [PSCustomObject]@{
    current = $currentStreak
    max = $maxStreak
  }
}

function Add-MetricCheck {
  param(
    [ref]$Items,
    [string]$Metric,
    [double]$Actual,
    [double]$Threshold,
    [string]$Operator,
    [string]$Scope,
    [string]$Severity
  )
  $passed = $false
  switch ($Operator) {
    "<=" { $passed = $Actual -le $Threshold; break }
    ">=" { $passed = $Actual -ge $Threshold; break }
    default { throw "Unsupported operator: $Operator" }
  }
  $Items.Value += [PSCustomObject]@{
    metric = $Metric
    actual = [math]::Round($Actual, 2)
    threshold = [math]::Round($Threshold, 2)
    operator = $Operator
    status = if ($passed) { "pass" } else { "fail" }
    scope = $Scope
    severity = $Severity
  }
}

function Get-MetricValidation {
  param(
    [array]$Rows,
    [array]$ScenarioSummary,
    [object]$ThresholdSuggestions
  )
  $total = @($Rows).Count
  $fail = @($Rows | Where-Object { $_.status -eq "fail" }).Count
  $avgDuration = if ($total -gt 0) { [double](($Rows | Measure-Object -Property durationMs -Average).Average) } else { 0 }
  $overallFailRate = if ($total -gt 0) { ($fail * 100.0) / $total } else { 0 }
  $maxScenarioFailRate = if (@($ScenarioSummary).Count -gt 0) { [double](($ScenarioSummary | Measure-Object -Property passRate -Minimum).Minimum) } else { 100 }
  $maxScenarioFailRate = [math]::Max(0, 100 - $maxScenarioFailRate)
  $maxScenarioAvgDuration = if (@($ScenarioSummary).Count -gt 0) { [double](($ScenarioSummary | Measure-Object -Property avgDurationMs -Maximum).Maximum) } else { 0 }
  $highRiskCount = @($ScenarioSummary | Where-Object { $_.riskLevel -eq "high" }).Count
  $streak = Get-ConsecutiveFailureStreak -Rows $Rows

  $checks = @()
  Add-MetricCheck -Items ([ref]$checks) -Metric "overall_fail_rate_pct" -Actual $overallFailRate -Threshold ([double]$ThresholdSuggestions.errorRate.recommendedPct) -Operator "<=" -Scope "global" -Severity "critical"
  Add-MetricCheck -Items ([ref]$checks) -Metric "overall_avg_duration_ms" -Actual $avgDuration -Threshold ([double]$ThresholdSuggestions.duration.recommendedMs) -Operator "<=" -Scope "global" -Severity "warning"
  Add-MetricCheck -Items ([ref]$checks) -Metric "overall_consecutive_failures" -Actual ([double]$streak.max) -Threshold ([double]$ThresholdSuggestions.consecutiveFailures.recommendedCount) -Operator "<=" -Scope "global" -Severity "critical"
  Add-MetricCheck -Items ([ref]$checks) -Metric "high_risk_scenarios" -Actual ([double]$highRiskCount) -Threshold 0 -Operator "<=" -Scope "scenario" -Severity "critical"
  Add-MetricCheck -Items ([ref]$checks) -Metric "max_scenario_fail_rate_pct" -Actual $maxScenarioFailRate -Threshold ([double]$ThresholdSuggestions.errorRate.recommendedPct) -Operator "<=" -Scope "scenario" -Severity "warning"
  Add-MetricCheck -Items ([ref]$checks) -Metric "max_scenario_avg_duration_ms" -Actual $maxScenarioAvgDuration -Threshold ([double]$ThresholdSuggestions.duration.recommendedMs) -Operator "<=" -Scope "scenario" -Severity "warning"

  $failedDetails = @()
  foreach ($item in $checks | Where-Object { $_.status -eq "fail" }) {
    $failedDetails += [PSCustomObject]@{
      metric = $item.metric
      actual = $item.actual
      threshold = $item.threshold
      operator = $item.operator
      severity = $item.severity
      message = "$($item.metric) violated threshold: actual=$($item.actual), expected $($item.operator) $($item.threshold)"
      hint = if ($item.scope -eq "global") { "Inspect integration logs and infrastructure bottlenecks." } else { "Check scenario-level playbook and rerun focused scenario." }
    }
  }

  return [PSCustomObject]@{
    totalMetrics = @($checks).Count
    passedMetrics = @($checks | Where-Object { $_.status -eq "pass" }).Count
    failedMetrics = @($checks | Where-Object { $_.status -eq "fail" }).Count
    status = if (@($checks | Where-Object { $_.status -eq "fail" }).Count -gt 0) { "fail" } else { "pass" }
    metricChecks = $checks
    failedDetails = $failedDetails
  }
}

function Get-AlertRuleValidation {
  param([object]$AlertRuleSuggestions)
  $issues = @()
  $requiredGlobalRuleNames = @(
    "chaos_error_rate_pct_high",
    "chaos_average_duration_ms_high",
    "chaos_consecutive_failures_high"
  )
  $globalRules = @($AlertRuleSuggestions.globalRules)
  foreach ($ruleName in $requiredGlobalRuleNames) {
    if (-not ($globalRules | Where-Object { $_.name -eq $ruleName })) {
      $issues += [PSCustomObject]@{
        rule = $ruleName
        issue = "missing required global rule"
      }
    }
  }
  foreach ($rule in $globalRules) {
    if (-not $rule.name -or -not $rule.expr -or -not $rule.severity -or $null -eq $rule.threshold) {
      $issues += [PSCustomObject]@{
        rule = "$($rule.name)"
        issue = "invalid rule fields"
      }
    }
    if ($rule.unit -eq "percent" -and (([double]$rule.threshold) -lt 1 -or ([double]$rule.threshold) -gt 100)) {
      $issues += [PSCustomObject]@{
        rule = "$($rule.name)"
        issue = "percent threshold out of range"
      }
    }
    if ($rule.unit -eq "ms" -and (([double]$rule.threshold) -lt 1000 -or ([double]$rule.threshold) -gt 60000)) {
      $issues += [PSCustomObject]@{
        rule = "$($rule.name)"
        issue = "duration threshold out of range"
      }
    }
    if ($rule.unit -eq "count" -and (([double]$rule.threshold) -lt 1 -or ([double]$rule.threshold) -gt 10)) {
      $issues += [PSCustomObject]@{
        rule = "$($rule.name)"
        issue = "count threshold out of range"
      }
    }
  }

  $scenarioRules = @($AlertRuleSuggestions.scenarioRules)
  foreach ($rule in $scenarioRules) {
    if (-not $rule.name -or -not $rule.scenario -or -not $rule.riskLevel -or -not $rule.recoveryAction) {
      $issues += [PSCustomObject]@{
        rule = "$($rule.name)"
        issue = "invalid scenario rule fields"
      }
    }
  }

  return [PSCustomObject]@{
    totalRules = @($globalRules).Count + @($scenarioRules).Count
    failedRules = @($issues).Count
    status = if (@($issues).Count -gt 0) { "fail" } else { "pass" }
    details = $issues
  }
}

function Get-RecoveryPlaybook {
  param(
    [array]$ScenarioSummary,
    [object]$ThresholdSuggestions
  )
  $templates = @{
    kafka_restart = [PSCustomObject]@{
      preChecks = @("Check Kafka broker health", "Check partition leaders", "Check consumer group rebalance status")
      actions = @("Restart broker and observe for 3 minutes", "Tune consumer retry and timeout settings", "Scale consumers if lag grows")
      postChecks = @("chaos_fail_rate_pct drops below threshold", "Consumer latency stays below threshold", "No new critical alerts")
    }
    postgres_restart = [PSCustomObject]@{
      preChecks = @("Check connection pool saturation", "Check archive and maintenance status", "Check slow query trend")
      actions = @("Restart Postgres instance and verify connectivity", "Review slow queries and indexes", "Verify archive writes recovered")
      postChecks = @("Error rate is below threshold", "Average duration returns to baseline", "No maintenance failures")
    }
    kafka_pause_unpause = [PSCustomObject]@{
      preChecks = @("Check consumer lag", "Check paused partition recovery time", "Check DLQ write rate")
      actions = @("Reduce pause duration and rerun test", "Scale consumers and concurrency", "Inspect whether failures focus on one partition")
      postChecks = @("Partition lag keeps decreasing", "Consecutive failures are below threshold", "DLQ growth returns to normal")
    }
    baseline = [PSCustomObject]@{
      preChecks = @("Check base environment health", "Check test data readiness")
      actions = @("Keep current settings and monitor", "Run baseline chaos checks periodically")
      postChecks = @("Core metrics stay stable")
    }
  }

  $entries = @()
  foreach ($item in $ScenarioSummary) {
    $template = $templates[$item.scenario]
    if (-not $template) {
      $template = [PSCustomObject]@{
        preChecks = @("Check dependency service health")
        actions = @("Run standard troubleshooting by risk level")
        postChecks = @("Core metrics return below thresholds")
      }
    }
    $entries += [PSCustomObject]@{
      scenario = $item.scenario
      riskLevel = $item.riskLevel
      severity = Get-SeverityByRiskLevel -RiskLevel $item.riskLevel
      thresholdReference = [PSCustomObject]@{
        errorRatePct = $ThresholdSuggestions.errorRate.recommendedPct
        averageDurationMs = $ThresholdSuggestions.duration.recommendedMs
        consecutiveFailures = $ThresholdSuggestions.consecutiveFailures.recommendedCount
      }
      preChecks = $template.preChecks
      actions = $template.actions
      postChecks = $template.postChecks
    }
  }
  return $entries
}

$kafkaPort = Find-FreePort 9092
$postgresPort = Find-FreePort 5432
$zookeeperPort = Find-FreePort 2181
$env:KAFKA_HOST_PORT = "$kafkaPort"
$env:POSTGRES_HOST_PORT = "$postgresPort"
$env:ZOOKEEPER_HOST_PORT = "$zookeeperPort"

$rows = @()
$reportDir = Join-Path $PSScriptRoot "..\reports\chaos"
New-Item -ItemType Directory -Path $reportDir -Force | Out-Null

try {
  docker compose -f $ComposeFile -p $ProjectName up -d
  if ($LASTEXITCODE -ne 0) {
    throw "docker compose up failed"
  }

  Wait-Healthy -ComposeFilePath $ComposeFile -Project $ProjectName -Service zookeeper
  Wait-Healthy -ComposeFilePath $ComposeFile -Project $ProjectName -Service kafka
  Wait-Healthy -ComposeFilePath $ComposeFile -Project $ProjectName -Service postgres

  $topic = if ($env:INDEXER_KAFKA_TOPIC) { $env:INDEXER_KAFKA_TOPIC } else { "soulon.indexer.events" }
  $dlqTopic = if ($env:INDEXER_KAFKA_DLQ_TOPIC) { $env:INDEXER_KAFKA_DLQ_TOPIC } else { "soulon.indexer.events.dlq" }
  docker compose -f $ComposeFile -p $ProjectName exec -T kafka kafka-topics --bootstrap-server localhost:9092 --create --if-not-exists --topic $topic --partitions 1 --replication-factor 1 | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "kafka topic create failed: $topic"
  }
  docker compose -f $ComposeFile -p $ProjectName exec -T kafka kafka-topics --bootstrap-server localhost:9092 --create --if-not-exists --topic $dlqTopic --partitions 1 --replication-factor 1 | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "kafka topic create failed: $dlqTopic"
  }

  for ($i = 1; $i -le $Iterations; $i++) {
    $baseline = Invoke-E2E -KafkaPort $kafkaPort -PostgresPort $postgresPort
    Add-Result -Rows ([ref]$rows) -Scenario "baseline" -Iteration $i -Result $baseline

    docker compose -f $ComposeFile -p $ProjectName restart kafka | Out-Null
    Wait-Healthy -ComposeFilePath $ComposeFile -Project $ProjectName -Service kafka
    $kafkaRestart = Invoke-E2E -KafkaPort $kafkaPort -PostgresPort $postgresPort
    Add-Result -Rows ([ref]$rows) -Scenario "kafka_restart" -Iteration $i -Result $kafkaRestart

    docker compose -f $ComposeFile -p $ProjectName restart postgres | Out-Null
    Wait-Healthy -ComposeFilePath $ComposeFile -Project $ProjectName -Service postgres
    $pgRestart = Invoke-E2E -KafkaPort $kafkaPort -PostgresPort $postgresPort
    Add-Result -Rows ([ref]$rows) -Scenario "postgres_restart" -Iteration $i -Result $pgRestart

    $kafkaContainer = docker compose -f $ComposeFile -p $ProjectName ps -q kafka
    docker pause $kafkaContainer | Out-Null
    Start-Sleep -Seconds 3
    docker unpause $kafkaContainer | Out-Null
    Wait-Healthy -ComposeFilePath $ComposeFile -Project $ProjectName -Service kafka
    $kafkaPause = Invoke-E2E -KafkaPort $kafkaPort -PostgresPort $postgresPort
    Add-Result -Rows ([ref]$rows) -Scenario "kafka_pause_unpause" -Iteration $i -Result $kafkaPause
  }
}
finally {
  docker compose -f $ComposeFile -p $ProjectName down -v | Out-Null
}

$passCount = ($rows | Where-Object { $_.status -eq "pass" }).Count
$failCount = ($rows | Where-Object { $_.status -eq "fail" }).Count
$totalCount = $rows.Count
$avgDuration = 0
if ($totalCount -gt 0) {
  $avgDuration = [int](($rows | Measure-Object -Property durationMs -Average).Average)
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportPath = Join-Path $reportDir "chaos-report-$timestamp.md"
$jsonPath = Join-Path $reportDir "chaos-report-$timestamp.json"
$rulesPath = Join-Path $reportDir "chaos-alert-rules-$timestamp.json"
$playbookPath = Join-Path $reportDir "chaos-recovery-playbook-$timestamp.json"
$summaryPath = Join-Path $reportDir "chaos-validation-summary-$timestamp.md"
$scenarioSummary = Get-ScenarioSummary -Rows $rows
$historyTrend = Get-HistoryTrend -DirectoryPath $reportDir -Window $TrendWindow
$generatedAt = Get-Date -Format o
$currentFailRate = if ($totalCount -gt 0) { [math]::Round(($failCount * 100.0) / $totalCount, 2) } else { 0 }
$currentHistoryRow = [PSCustomObject]@{
  report = "chaos-report-$timestamp.md"
  total = $totalCount
  pass = $passCount
  fail = $failCount
  failRate = $currentFailRate
  passRate = if ($totalCount -gt 0) { [math]::Round(($passCount * 100.0) / $totalCount, 2) } else { 0 }
  averageDurationMs = $avgDuration
  generatedAt = $generatedAt
}
$historyForSuggestion = @($historyTrend)
$historyForSuggestion += $currentHistoryRow
$thresholdSuggestions = Get-HistoricalThresholdSuggestion -HistoryRows $historyForSuggestion
$alertRuleSuggestions = Get-AlertRuleSuggestions -ScenarioSummary $scenarioSummary -ThresholdSuggestions $thresholdSuggestions
$alertRuleValidation = Get-AlertRuleValidation -AlertRuleSuggestions $alertRuleSuggestions
$recoveryPlaybook = Get-RecoveryPlaybook -ScenarioSummary $scenarioSummary -ThresholdSuggestions $thresholdSuggestions
$metricValidation = Get-MetricValidation -Rows $rows -ScenarioSummary $scenarioSummary -ThresholdSuggestions $thresholdSuggestions
$resultRows = @()
foreach ($row in $rows) {
  $resultRows += [PSCustomObject]@{
    scenario = $row.scenario
    iteration = $row.iteration
    status = $row.status
    durationMs = $row.durationMs
    message = Normalize-Message -Value $row.message
  }
}

$lines = @()
$lines += "# Chaos Injection Report"
$lines += ""
$lines += "- generatedAt: $generatedAt"
$lines += "- iterations: $Iterations"
$lines += "- total: $totalCount"
$lines += "- pass: $passCount"
$lines += "- fail: $failCount"
$lines += "- averageDurationMs: $avgDuration"
$lines += "- trendWindow: $TrendWindow"
$lines += "- rulesFile: $([System.IO.Path]::GetFileName($rulesPath))"
$lines += "- playbookFile: $([System.IO.Path]::GetFileName($playbookPath))"
$lines += "- validationSummaryFile: $([System.IO.Path]::GetFileName($summaryPath))"
$lines += ""
$lines += "## Historical Threshold Suggestions"
$lines += ""
$lines += "- historySampleSize: $($thresholdSuggestions.sampleSize)"
$lines += ""
$lines += "| metric | latest | p90 | average | recommended |"
$lines += "|---|---:|---:|---:|---:|"
$lines += "| errorRate(%) | $($thresholdSuggestions.errorRate.latestPct) | $($thresholdSuggestions.errorRate.p90Pct) | $($thresholdSuggestions.errorRate.averagePct) | $($thresholdSuggestions.errorRate.recommendedPct) |"
$lines += "| averageDurationMs | $($thresholdSuggestions.duration.latestMs) | $($thresholdSuggestions.duration.p90Ms) | $($thresholdSuggestions.duration.averageMs) | $($thresholdSuggestions.duration.recommendedMs) |"
$lines += "| consecutiveFailures | $($thresholdSuggestions.consecutiveFailures.latestStreak) | $($thresholdSuggestions.consecutiveFailures.maxObservedStreak) | - | $($thresholdSuggestions.consecutiveFailures.recommendedCount) |"
$lines += ""
$lines += "## Metric Threshold Validation"
$lines += ""
$lines += "- status: $($metricValidation.status)"
$lines += "- totalMetrics: $($metricValidation.totalMetrics)"
$lines += "- passedMetrics: $($metricValidation.passedMetrics)"
$lines += "- failedMetrics: $($metricValidation.failedMetrics)"
$lines += ""
$lines += "| metric | scope | severity | actual | operator | threshold | status |"
$lines += "|---|---|---|---:|---|---:|---|"
foreach ($item in $metricValidation.metricChecks) {
  $lines += "| $($item.metric) | $($item.scope) | $($item.severity) | $($item.actual) | $($item.operator) | $($item.threshold) | $($item.status) |"
}
$lines += ""
$lines += "## Metric Failure Details"
$lines += ""
if ($metricValidation.failedMetrics -eq 0) {
  $lines += "- none"
} else {
  $lines += "| metric | severity | actual | operator | threshold | message | hint |"
  $lines += "|---|---|---:|---|---:|---|---|"
  foreach ($item in $metricValidation.failedDetails) {
    $lines += "| $($item.metric) | $($item.severity) | $($item.actual) | $($item.operator) | $($item.threshold) | $($item.message) | $($item.hint) |"
  }
}
$lines += ""
$lines += "## Alert Rule Suggestions"
$lines += ""
$lines += "| name | severity | threshold | unit | window | description |"
$lines += "|---|---|---:|---|---|---|"
foreach ($rule in $alertRuleSuggestions.globalRules) {
  $lines += "| $($rule.name) | $($rule.severity) | $($rule.threshold) | $($rule.unit) | $($rule.window) | $($rule.description) |"
}
foreach ($rule in $alertRuleSuggestions.scenarioRules) {
  $lines += "| $($rule.name) | $($rule.severity) | $($rule.threshold) | $($rule.unit) | scenario | $($rule.description) |"
}
$lines += ""
$lines += "## Alert Rule Validation"
$lines += ""
$lines += "- status: $($alertRuleValidation.status)"
$lines += "- totalRules: $($alertRuleValidation.totalRules)"
$lines += "- failedRules: $($alertRuleValidation.failedRules)"
if ($alertRuleValidation.failedRules -gt 0) {
  $lines += ""
  $lines += "| rule | issue |"
  $lines += "|---|---|"
  foreach ($detail in $alertRuleValidation.details) {
    $lines += "| $($detail.rule) | $($detail.issue) |"
  }
}
$lines += ""
$lines += "## Scenario Summary"
$lines += ""
$lines += "| scenario | total | pass | fail | passRate(%) | avgDurationMs | riskLevel | recoveryAction |"
$lines += "|---|---:|---:|---:|---:|---:|---|---|"
foreach ($row in $scenarioSummary) {
  $lines += "| $($row.scenario) | $($row.total) | $($row.pass) | $($row.fail) | $($row.passRate) | $($row.avgDurationMs) | $($row.riskLevel) | $($row.recoveryAction) |"
}
$lines += ""
$lines += "## History Trend"
$lines += ""
$lines += "| report | generatedAt | total | pass | fail | failRate(%) | passRate(%) | averageDurationMs |"
$lines += "|---|---|---:|---:|---:|---:|---:|---:|"
foreach ($item in $historyTrend) {
  $lines += "| $($item.report) | $($item.generatedAt) | $($item.total) | $($item.pass) | $($item.fail) | $($item.failRate) | $($item.passRate) | $($item.averageDurationMs) |"
}
$lines += ""
$lines += "## Recovery Playbook"
$lines += ""
foreach ($entry in $recoveryPlaybook) {
  $lines += "### $($entry.scenario) ($($entry.riskLevel))"
  $lines += "- severity: $($entry.severity)"
  $lines += "- thresholdRef: errorRate<=$($entry.thresholdReference.errorRatePct), avgDuration<=$($entry.thresholdReference.averageDurationMs), consecutiveFailures<=$($entry.thresholdReference.consecutiveFailures)"
  $lines += "- preChecks: $($entry.preChecks -join '; ')"
  $lines += "- actions: $($entry.actions -join '; ')"
  $lines += "- postChecks: $($entry.postChecks -join '; ')"
  $lines += ""
}
$lines += ""
$lines += "| scenario | iteration | status | durationMs | message |"
$lines += "|---|---:|---|---:|---|"
foreach ($row in $resultRows) {
  $lines += "| $($row.scenario) | $($row.iteration) | $($row.status) | $($row.durationMs) | $($row.message) |"
}

Set-Content -Path $reportPath -Value $lines -Encoding UTF8
$summaryLines = @()
$summaryLines += "# Chaos Validation Summary"
$summaryLines += ""
$summaryLines += "- generatedAt: $generatedAt"
$summaryLines += "- reportFile: $([System.IO.Path]::GetFileName($reportPath))"
$summaryLines += "- resultFile: $([System.IO.Path]::GetFileName($jsonPath))"
$summaryLines += "- alertRulesFile: $([System.IO.Path]::GetFileName($rulesPath))"
$summaryLines += "- playbookFile: $([System.IO.Path]::GetFileName($playbookPath))"
$summaryLines += "- metricValidation: $($metricValidation.status) ($($metricValidation.passedMetrics)/$($metricValidation.totalMetrics))"
$summaryLines += "- alertRuleValidation: $($alertRuleValidation.status) (failed=$($alertRuleValidation.failedRules))"
$summaryLines += ""
$summaryLines += "## Failed Metric Details"
$summaryLines += ""
if ($metricValidation.failedMetrics -eq 0) {
  $summaryLines += "- none"
} else {
  $summaryLines += "| metric | severity | actual | operator | threshold | message |"
  $summaryLines += "|---|---|---:|---|---:|---|"
  foreach ($detail in $metricValidation.failedDetails) {
    $summaryLines += "| $($detail.metric) | $($detail.severity) | $($detail.actual) | $($detail.operator) | $($detail.threshold) | $($detail.message) |"
  }
}
$summaryLines += ""
$summaryLines += "## Alert Rule Validation Details"
$summaryLines += ""
if ($alertRuleValidation.failedRules -eq 0) {
  $summaryLines += "- none"
} else {
  $summaryLines += "| rule | issue |"
  $summaryLines += "|---|---|"
  foreach ($detail in $alertRuleValidation.details) {
    $summaryLines += "| $($detail.rule) | $($detail.issue) |"
  }
}
Set-Content -Path $summaryPath -Value $summaryLines -Encoding UTF8
$jsonReport = [ordered]@{
  generatedAt = $generatedAt
  iterations = $Iterations
  total = $totalCount
  pass = $passCount
  fail = $failCount
  averageDurationMs = $avgDuration
  trendWindow = $TrendWindow
  thresholdSuggestions = $thresholdSuggestions
  metricValidation = $metricValidation
  alertRuleSuggestions = $alertRuleSuggestions
  alertRuleValidation = $alertRuleValidation
  recoveryPlaybook = $recoveryPlaybook
  scenarioSummary = $scenarioSummary
  historyTrend = $historyTrend
  results = $resultRows
}
$jsonReport | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8
$alertRuleSuggestions | ConvertTo-Json -Depth 10 | Set-Content -Path $rulesPath -Encoding UTF8
$recoveryPlaybook | ConvertTo-Json -Depth 10 | Set-Content -Path $playbookPath -Encoding UTF8
Write-Output "Chaos report generated: $reportPath"
Write-Output "Chaos report generated: $jsonPath"
Write-Output "Chaos report generated: $rulesPath"
Write-Output "Chaos report generated: $playbookPath"
Write-Output "Chaos report generated: $summaryPath"

if ($metricValidation.failedMetrics -gt 0) {
  throw "chaos metric validation failed: $($metricValidation.failedMetrics)"
}
if ($alertRuleValidation.failedRules -gt 0) {
  throw "chaos alert rule validation failed: $($alertRuleValidation.failedRules)"
}
if ($failCount -gt 0) {
  throw "chaos report contains scenario failures: $failCount"
}
