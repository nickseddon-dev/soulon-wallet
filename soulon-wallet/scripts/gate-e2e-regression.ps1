$ErrorActionPreference = "Stop"

$env:SOULON_SKIP_NETWORK_TEST = "1"

Write-Output "Release gate: offline e2e"
npm run test:e2e
if ($LASTEXITCODE -ne 0) {
  throw "test:e2e failed"
}

Write-Output "Release gate: offline business regression"
npm run test:business
if ($LASTEXITCODE -ne 0) {
  throw "test:business failed"
}

Write-Output "Release gate: e2e regression passed"
