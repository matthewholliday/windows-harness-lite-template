# HARNESS validation: assert E2E tests pass
# Wires to the project's E2E test runner (Playwright in electron/)
# Exit non-zero if any E2E test fails

$ErrorActionPreference = "Stop"

$HarnessRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
$ProjectRoot = Split-Path -Parent $HarnessRoot
$ElectronDir = Join-Path $ProjectRoot "electron"

if (-not (Test-Path $ElectronDir)) {
    Write-Host "No electron/ directory; skipping E2E (no E2E tests)." -ForegroundColor Yellow
    exit 0
}

Push-Location $ElectronDir
try {
    if (-not (Test-Path "node_modules")) {
        npm install
    }
    npm run test:e2e
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Pop-Location
}
