param(
  [string]$ChainName = "soulon",
  [string]$ModulePath = "github.com/soulon/soulon",
  [switch]$Force
)

$igniteCmd = Get-Command ignite -ErrorAction SilentlyContinue
if (-not $igniteCmd) {
  Write-Error "Ignite CLI 未安装，无法执行链脚手架初始化。"
  exit 1
}

$chainDir = Resolve-Path -Path "." | ForEach-Object { Join-Path $_ $ChainName }
if ((Test-Path $chainDir) -and (-not $Force)) {
  Write-Error "目标目录已存在：$chainDir。请使用 -Force 或更换链名。"
  exit 1
}

if ((Test-Path $chainDir) -and $Force) {
  Remove-Item -Recurse -Force $chainDir
}

& ignite scaffold chain $ModulePath --no-module
if ($LASTEXITCODE -ne 0) {
  Write-Error "Ignite 脚手架初始化失败。"
  exit $LASTEXITCODE
}

Write-Output "链脚手架初始化完成：$ModulePath"
