param(
  [string]$ChainBinary = "soulond",
  [string]$EnvFile = "..\deploy\localnet\localnet.env",
  [switch]$Reset,
  [switch]$DryRun
)

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
$chainId = Env-Get -Map $envMap -Key "CHAIN_ID" -Default "soulon-local-1"
$denom = Env-Get -Map $envMap -Key "DENOM" -Default "usoul"
$moniker = Env-Get -Map $envMap -Key "MONIKER" -Default "soulon-validator-1"
$keyName = Env-Get -Map $envMap -Key "KEY_NAME" -Default "validator"
$keyring = Env-Get -Map $envMap -Key "KEYRING_BACKEND" -Default "test"
$homeDir = Env-Get -Map $envMap -Key "HOME_DIR" -Default ".localnet"
$rpcPort = Env-Get -Map $envMap -Key "RPC_PORT" -Default "26657"
$grpcPort = Env-Get -Map $envMap -Key "GRPC_PORT" -Default "9090"
$restPort = Env-Get -Map $envMap -Key "REST_PORT" -Default "1317"

$absHome = Join-Path (Get-Location) $homeDir
if ($Reset -and (Test-Path $absHome)) {
  Remove-Item -Recurse -Force $absHome
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
Run-Step -File $ChainBinary -StepArgs @(
  "start",
  "--home", $homeDir,
  "--rpc.laddr", ("tcp://0.0.0.0:{0}" -f $rpcPort),
  "--grpc.address", ("0.0.0.0:{0}" -f $grpcPort),
  "--api.enable=true",
  "--api.address", ("tcp://0.0.0.0:{0}" -f $restPort)
) -Dry:$DryRun
