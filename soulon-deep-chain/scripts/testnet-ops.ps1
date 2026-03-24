param(
  [ValidateSet("status", "logs", "stop")]
  [string]$Action = "status",
  [string]$EnvFile = "..\deploy\testnet\testnet.env",
  [int]$Tail = 120,
  [switch]$Follow
)

$ErrorActionPreference = "Stop"

function Load-Env {
  param([string]$Path)
  $map = @{}
  if (-not (Test-Path $Path)) {
    return $map
  }
  foreach ($lineRaw in Get-Content $Path) {
    $line = $lineRaw.Trim()
    if ($line -eq "" -or $line.StartsWith("#")) {
      continue
    }
    $pair = $line.Split("=", 2)
    if ($pair.Length -eq 2) {
      $map[$pair[0]] = $pair[1]
    }
  }
  return $map
}

function Env-Get {
  param(
    [hashtable]$Map,
    [string]$Key,
    [string]$Default
  )
  if ($Map.ContainsKey($Key) -and $Map[$Key] -ne "") {
    return $Map[$Key]
  }
  return $Default
}

function Get-NodeProcess {
  param([string]$PidFilePath)
  if (-not (Test-Path $PidFilePath)) {
    return $null
  }
  $pidRaw = Get-Content $PidFilePath -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $pidRaw) {
    return $null
  }
  $proc = Get-Process -Id $pidRaw -ErrorAction SilentlyContinue
  return $proc
}

$envMap = Load-Env -Path $EnvFile
$pidFile = Env-Get -Map $envMap -Key "PID_FILE" -Default "logs\testnet-node.pid"
$logFile = Env-Get -Map $envMap -Key "LOG_FILE" -Default "logs\testnet-node.log"
$errLogFile = Env-Get -Map $envMap -Key "ERR_LOG_FILE" -Default "logs\testnet-node.err.log"
$rpcPort = Env-Get -Map $envMap -Key "RPC_PORT" -Default "26657"

if ($Action -eq "status") {
  $proc = Get-NodeProcess -PidFilePath $pidFile
  if ($proc) {
    Write-Output ("Status: running")
    Write-Output ("PID: {0}" -f $proc.Id)
    Write-Output ("Process: {0}" -f $proc.ProcessName)
    Write-Output ("RPC: http://127.0.0.1:{0}" -f $rpcPort)
  } else {
    Write-Output ("Status: stopped")
  }
  Write-Output ("PID file: {0}" -f $pidFile)
  Write-Output ("Log file: {0}" -f $logFile)
  Write-Output ("Err log: {0}" -f $errLogFile)
  exit 0
}

if ($Action -eq "logs") {
  if (-not (Test-Path $logFile)) {
    Write-Error ("Log file not found: {0}" -f $logFile)
    exit 1
  }
  if ($Follow) {
    Write-Output ("Following log: {0}" -f $logFile)
    Get-Content -Path $logFile -Tail $Tail -Wait
    exit 0
  }
  Write-Output ("Last {0} lines from log: {1}" -f $Tail, $logFile)
  Get-Content -Path $logFile -Tail $Tail
  if (Test-Path $errLogFile) {
    Write-Output ("Last {0} lines from err log: {1}" -f $Tail, $errLogFile)
    Get-Content -Path $errLogFile -Tail $Tail
  }
  exit 0
}

if ($Action -eq "stop") {
  $proc = Get-NodeProcess -PidFilePath $pidFile
  if ($proc) {
    Stop-Process -Id $proc.Id -Force
    Write-Output ("Testnet node stopped, PID={0}" -f $proc.Id)
  } else {
    Write-Output "No running testnet node found."
  }
  if (Test-Path $pidFile) {
    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
  }
}
