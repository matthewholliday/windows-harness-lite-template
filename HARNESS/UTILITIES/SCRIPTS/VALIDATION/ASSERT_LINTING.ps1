# HARNESS validation: assert linting passes
# Wires to the project's linter(s). Exit non-zero if lint fails.
# Uses ruff if available; otherwise Python compileall as a minimal syntax check.

$ErrorActionPreference = "Stop"

$HarnessRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
$ProjectRoot = Split-Path -Parent $HarnessRoot

Push-Location $ProjectRoot
try {
    # Prefer ruff if installed (pip or uv)
    $ruff = $null
    if (Get-Command ruff -ErrorAction SilentlyContinue) { $ruff = "ruff" }
    if (-not $ruff -and (Get-Command python -ErrorAction SilentlyContinue)) {
        $r = python -c "import ruff; print('ok')" 2>$null
        if ($r -eq "ok") { $ruff = "python -m ruff" }
    }
    if ($ruff) {
        if ($ruff -eq "ruff") {
            ruff check . --output-format=concise
        } else {
            python -m ruff check . --output-format=concise
        }
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        exit 0
    }
    # Fallback: Python syntax check via compileall (no extra deps)
    if (Test-Path "statesim") {
        python -m compileall -q statesim
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
    Write-Host "Lint check completed (compileall; add ruff for full linting)." -ForegroundColor Cyan
} finally {
    Pop-Location
}
