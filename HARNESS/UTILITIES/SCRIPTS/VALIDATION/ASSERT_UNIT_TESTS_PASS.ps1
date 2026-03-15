# HARNESS validation: assert unit tests pass
# Wires to the project's unit test runner. Exit non-zero if any test fails.
# Tries, in order: scripts/Run-Tests.ps1, npm/pnpm/yarn test, pytest.
# If none are found or run, exits 1 and asks you to wire this script.

$ErrorActionPreference = "Stop"

$HarnessRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
$ProjectRoot = Split-Path -Parent $HarnessRoot

Push-Location $ProjectRoot
try {
    $ran = $false

    # 1. Project-specific script (e.g. scripts/Run-Tests.ps1)
    $runScript = Join-Path $ProjectRoot "scripts\Run-Tests.ps1"
    if (Test-Path $runScript) {
        & $runScript
        $ran = $true
    }

    # 2. Node: npm test / pnpm test / yarn test
    if (-not $ran) {
        $pkgJson = Join-Path $ProjectRoot "package.json"
        if (Test-Path $pkgJson) {
            $pkg = Get-Content $pkgJson -Raw | ConvertFrom-Json
            $scripts = if ($pkg.scripts) { $pkg.scripts.PSObject.Properties } else { $null }
            $testScript = $null
            if ($scripts) {
                foreach ($s in $scripts) {
                    if ($s.Name -eq 'test') { $testScript = $s.Value; break }
                }
            }
            if ($testScript) {
                if (Get-Command pnpm -ErrorAction SilentlyContinue) {
                    pnpm test
                } elseif (Get-Command yarn -ErrorAction SilentlyContinue) {
                    yarn test
                } else {
                    npm test
                }
                $ran = $true
            }
        }
    }

    # 3. Python: pytest
    if (-not $ran -and (Get-Command pytest -ErrorAction SilentlyContinue)) {
        if (Test-Path "tests") {
            pytest tests/ -v
        } else {
            pytest . -v
        }
        $ran = $true
    }

    if (-not $ran) {
        Write-Host "ASSERT_UNIT_TESTS_PASS: Wire this script to your project's unit test runner." -ForegroundColor Red
        Write-Host "  Options: add scripts/Run-Tests.ps1, or ensure 'npm test' / 'pytest' is available." -ForegroundColor Gray
        exit 1
    }

    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Pop-Location
}
