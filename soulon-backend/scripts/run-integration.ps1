param(
  [string]$ComposeFile = "docker-compose.integration.yml",
  [string]$ProjectName = "soulon-int-$PID"
)

function Find-FreePort {
  param([int]$Start)
  for ($port = $Start; $port -lt ($Start + 200); $port++) {
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

$kafkaPort = Find-FreePort 9092
$postgresPort = Find-FreePort 5432
$zookeeperPort = Find-FreePort 2181

$env:KAFKA_HOST_PORT = "$kafkaPort"
$env:POSTGRES_HOST_PORT = "$postgresPort"
$env:ZOOKEEPER_HOST_PORT = "$zookeeperPort"

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

  $env:RUN_E2E = "1"
  $env:INDEXER_KAFKA_BROKERS = "127.0.0.1:$kafkaPort"
  $env:INDEXER_POSTGRES_DSN = "postgres://postgres:postgres@127.0.0.1:$postgresPort/soulon_indexer?sslmode=disable"
  go test ./internal/indexer -run TestKafkaAndPostgresIntegration -v
  if ($LASTEXITCODE -ne 0) {
    throw "integration test failed"
  }
}
finally {
  docker compose -f $ComposeFile -p $ProjectName down -v | Out-Null
}
