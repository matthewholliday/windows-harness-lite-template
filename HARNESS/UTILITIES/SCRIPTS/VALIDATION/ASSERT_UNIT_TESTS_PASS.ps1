# HARNESS validation: assert unit tests pass
# Wires to the project's unit test runner (pytest for statesim)
# Exit non-zero if any test fails

$ErrorActionPreference = "Stop"

$HarnessRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
$ProjectRoot = Split-Path -Parent $HarnessRoot

Push-Location $ProjectRoot
try {
    $runScript = Join-Path $ProjectRoot "scripts\Run-Tests.ps1"
    if (Test-Path $runScript) {
        & $runScript
    } else {
        if (Get-Command pytest -ErrorAction SilentlyContinue) {
            pytest tests/ -v
        } else {
            Write-Error "pytest not found and scripts\Run-Tests.ps1 not present. Install pytest or add Run-Tests.ps1."
            exit 1
        }
    }
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Pop-Location
}
