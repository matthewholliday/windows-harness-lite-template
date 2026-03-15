# HARNESS validation: assert E2E tests pass
# Wires to the project's E2E test runner. Exit non-zero if any E2E test fails.
# Detects: package.json "test:e2e" (or similar), Playwright, Cypress.
# If no E2E setup is detected, prints a message and exits 0 (skip).

$ErrorActionPreference = "Stop"

$HarnessRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
$ProjectRoot = Split-Path -Parent $HarnessRoot

Push-Location $ProjectRoot
try {
    $ran = $false
    $pkgJson = Join-Path $ProjectRoot "package.json"

    if (Test-Path $pkgJson) {
        $pkg = Get-Content $pkgJson -Raw | ConvertFrom-Json
        $scripts = if ($pkg.scripts) { $pkg.scripts.PSObject.Properties } else { $null }
        $e2eScriptName = $null
        if ($scripts) {
            foreach ($s in $scripts) {
                $name = $s.Name
                if ($name -eq 'test:e2e' -or $name -eq 'e2e' -or $name -eq 'test:e2e:ci') {
                    $e2eScriptName = $name
                    break
                }
            }
        }
        if ($e2eScriptName) {
            if (-not (Test-Path "node_modules")) {
                if (Get-Command pnpm -ErrorAction SilentlyContinue) {
                    pnpm install
                } elseif (Get-Command yarn -ErrorAction SilentlyContinue) {
                    yarn install
                } else {
                    npm install
                }
            }
            if (Get-Command pnpm -ErrorAction SilentlyContinue) {
                pnpm run $e2eScriptName
            } elseif (Get-Command yarn -ErrorAction SilentlyContinue) {
                yarn run $e2eScriptName
            } else {
                npm run $e2eScriptName
            }
            $ran = $true
        }
        # Fallback: try Playwright/Cypress by presence of config
        if (-not $ran) {
            if (Test-Path "playwright.config.js") -or (Test-Path "playwright.config.ts") {
                npx playwright test
                $ran = $true
            } elseif (Test-Path "cypress.config.js") -or (Test-Path "cypress.config.ts") {
                npx cypress run
                $ran = $true
            }
        }
    }

    if (-not $ran) {
        Write-Host "No E2E setup detected; wire this script to your E2E runner." -ForegroundColor Yellow
        Write-Host "  Add a 'test:e2e' script in package.json, or configure Playwright/Cypress." -ForegroundColor Gray
        exit 0
    }

    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Pop-Location
}
