param(
  [switch]$Install
)

$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")

Push-Location $root
if ($Install -or -not (Test-Path (Join-Path $root "node_modules"))) {
  npm install
}
npm run dev
Pop-Location
