param(
  [string]$ChainBinary = "soulond",
  [string]$EnvFile = "..\deploy\testnet\testnet.env",
  [switch]$Reset,
  [switch]$DryRun
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

function Ensure-Directory {
  param([string]$Path)
  if ($Path -and (-not (Test-Path $Path))) {
    New-Item -ItemType Directory -Path $Path | Out-Null
  }
}

function Run-Step {
  param(
    [string]$File,
    [string[]]$StepArgs,
    [switch]$Dry
  )
  if ($Dry) {
    Write-Output ("DRYRUN: {0} {1}" -f $File, ($StepArgs -join " "))
    return
  }
  & $File @StepArgs
  if ($LASTEXITCODE -ne 0) {
    throw ("执行失败: {0} {1}" -f $File, ($StepArgs -join " "))
  }
}

$envMap = Load-Env -Path $EnvFile
$chainId = Env-Get -Map $envMap -Key "CHAIN_ID" -Default "soulon-testnet-1"
$denom = Env-Get -Map $envMap -Key "DENOM" -Default "usoul"
$moniker = Env-Get -Map $envMap -Key "MONIKER" -Default "soulon-testnet-validator-1"
$keyName = Env-Get -Map $envMap -Key "KEY_NAME" -Default "validator"
$keyring = Env-Get -Map $envMap -Key "KEYRING_BACKEND" -Default "test"
$homeDir = Env-Get -Map $envMap -Key "HOME_DIR" -Default ".testnet"
$rpcPort = Env-Get -Map $envMap -Key "RPC_PORT" -Default "26657"
$grpcPort = Env-Get -Map $envMap -Key "GRPC_PORT" -Default "9090"
$restPort = Env-Get -Map $envMap -Key "REST_PORT" -Default "1317"
$p2pPort = Env-Get -Map $envMap -Key "P2P_PORT" -Default "26656"
$logFile = Env-Get -Map $envMap -Key "LOG_FILE" -Default "logs\testnet-node.log"
$errLogFile = Env-Get -Map $envMap -Key "ERR_LOG_FILE" -Default "logs\testnet-node.err.log"
$pidFile = Env-Get -Map $envMap -Key "PID_FILE" -Default "logs\testnet-node.pid"

$absHome = Join-Path (Get-Location) $homeDir
if ($Reset -and (Test-Path $absHome)) {
  Remove-Item -Recurse -Force $absHome
}

$logDir = Split-Path -Path $logFile -Parent
$pidDir = Split-Path -Path $pidFile -Parent
Ensure-Directory -Path $logDir
Ensure-Directory -Path $pidDir

if (Test-Path $pidFile) {
  $runningPid = (Get-Content $pidFile -ErrorAction SilentlyContinue | Select-Object -First 1)
  if ($runningPid) {
    $proc = Get-Process -Id $runningPid -ErrorAction SilentlyContinue
    if ($proc) {
      throw ("测试网节点已在运行，PID={0}。请先执行 testnet-ops.ps1 -Action stop" -f $runningPid)
    }
  }
  Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
}

if (-not $DryRun) {
  $exists = Get-Command $ChainBinary -ErrorAction SilentlyContinue
  if (-not $exists) {
    Write-Error ("未找到链二进制: {0}" -f $ChainBinary)
    exit 1
  }
}

Run-Step -File $ChainBinary -StepArgs @("init", $moniker, "--chain-id", $chainId, "--home", $homeDir) -Dry:$DryRun
Run-Step -File $ChainBinary -StepArgs @("keys", "add", $keyName, "--keyring-backend", $keyring, "--home", $homeDir) -Dry:$DryRun
Run-Step -File $ChainBinary -StepArgs @("add-genesis-account", $keyName, ("1000000000{0}" -f $denom), "--keyring-backend", $keyring, "--home", $homeDir) -Dry:$DryRun
Run-Step -File $ChainBinary -StepArgs @("gentx", $keyName, ("500000000{0}" -f $denom), "--chain-id", $chainId, "--keyring-backend", $keyring, "--home", $homeDir) -Dry:$DryRun
Run-Step -File $ChainBinary -StepArgs @("collect-gentxs", "--home", $homeDir) -Dry:$DryRun

$startArgs = @(
  "start",
  "--home", $homeDir,
  "--rpc.laddr", ("tcp://0.0.0.0:{0}" -f $rpcPort),
  "--grpc.address", ("0.0.0.0:{0}" -f $grpcPort),
  "--api.enable=true",
  "--api.address", ("tcp://0.0.0.0:{0}" -f $restPort),
  "--p2p.laddr", ("tcp://0.0.0.0:{0}" -f $p2pPort)
)

if ($DryRun) {
  Write-Output ("DRYRUN: Start-Process {0} -ArgumentList {1}" -f $ChainBinary, ($startArgs -join " "))
  Write-Output ("DRYRUN: PID_FILE={0}" -f $pidFile)
  Write-Output ("DRYRUN: LOG_FILE={0}" -f $logFile)
  Write-Output ("DRYRUN: ERR_LOG_FILE={0}" -f $errLogFile)
  exit 0
}

$proc = Start-Process -FilePath $ChainBinary -ArgumentList $startArgs -RedirectStandardOutput $logFile -RedirectStandardError $errLogFile -PassThru -NoNewWindow
Set-Content -Path $pidFile -Value $proc.Id

Write-Output ("测试网节点已启动，PID={0}" -f $proc.Id)
Write-Output ("日志文件: {0}" -f $logFile)
Write-Output ("错误日志: {0}" -f $errLogFile)
Write-Output ("状态命令: .\testnet-ops.ps1 -Action status -EnvFile {0}" -f $EnvFile)
