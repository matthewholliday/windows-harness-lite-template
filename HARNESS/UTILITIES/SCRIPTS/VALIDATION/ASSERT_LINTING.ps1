# HARNESS validation: assert linting passes
# Wires to the project's linter(s). Exit non-zero if lint fails.
# Tries: ESLint (npm/pnpm/yarn lint or eslint .), Ruff (Python), then minimal fallback.
# If no linter detected, prints a message and exits 0 so template passes.

$ErrorActionPreference = "Stop"

$HarnessRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
$ProjectRoot = Split-Path -Parent $HarnessRoot

Push-Location $ProjectRoot
try {
    $ran = $false

    # 1. Node: npm/pnpm/yarn run lint or eslint
    $pkgJson = Join-Path $ProjectRoot "package.json"
    if (Test-Path $pkgJson) {
        $pkg = Get-Content $pkgJson -Raw | ConvertFrom-Json
        $scripts = if ($pkg.scripts) { $pkg.scripts.PSObject.Properties } else { $null }
        $lintScript = $null
        if ($scripts) {
            foreach ($s in $scripts) {
                if ($s.Name -eq 'lint' -or $s.Name -eq 'lint:check') {
                    $lintScript = $s.Value
                    break
                }
            }
        }
        if ($lintScript) {
            if (Get-Command pnpm -ErrorAction SilentlyContinue) {
                pnpm run lint
            } elseif (Get-Command yarn -ErrorAction SilentlyContinue) {
                yarn run lint
            } else {
                npm run lint
            }
            $ran = $true
        } elseif (Get-Command eslint -ErrorAction SilentlyContinue) {
            eslint .
            $ran = $true
        }
    }

    # 2. Python: ruff
    if (-not $ran) {
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
            $ran = $true
        }
    }

    # 3. Minimal fallback: Python compileall on first package-like dir (e.g. src/)
    if (-not $ran -and (Get-Command python -ErrorAction SilentlyContinue)) {
        $dirs = @("src", "lib", "app")
        foreach ($d in $dirs) {
            if (Test-Path $d) {
                python -m compileall -q $d 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Lint check completed (Python compileall on $d/; add a linter for full checks)." -ForegroundColor Cyan
                    $ran = $true
                }
                break
            }
        }
    }

    if (-not $ran) {
        Write-Host "No linter detected; wire this script to your project's linter." -ForegroundColor Yellow
        Write-Host "  Add a 'lint' script in package.json, or install ESLint/Ruff/etc." -ForegroundColor Gray
        exit 0
    }

    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Pop-Location
}
