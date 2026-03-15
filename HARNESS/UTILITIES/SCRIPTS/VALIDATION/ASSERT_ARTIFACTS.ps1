<#
.SYNOPSIS
    Asserts that the HARNESS ARTIFACTS directory is intact and that all files are either empty or conform to their schemas.
.DESCRIPTION
    Verifies: (1) all required artifact paths exist; (2) each file is either empty/whitespace or valid and schema-compliant.
    Uses UTF-8. Exits with 0 if all checks pass, non-zero otherwise.
.PARAMETER ArtifactsRoot
    Root of the ARTIFACTS directory (e.g. .../HARNESS/ARTIFACTS). Default: resolved from script location.
.PARAMETER Strict
    If set, PROGRESS.SCHEMA.json is required; when present, PROGRESS.jsonl event lines are validated against it.
#>

param(
    [string]$ArtifactsRoot = '',
    [switch]$Strict
)

$ErrorActionPreference = 'Stop'

# Resolve ARTIFACTS root: script is .../HARNESS/UTILITIES/SCRIPTS/VALIDATION/ASSERT_ARTIFACTS.ps1
if (-not $ArtifactsRoot) {
    $HarnessDir = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..\..')).Path
    $ArtifactsRoot = Join-Path $HarnessDir 'ARTIFACTS'
}
$ArtifactsRoot = (Resolve-Path -LiteralPath $ArtifactsRoot).Path

# ---------------------------------------------------------------------------
# Canonical required paths (relative to ArtifactsRoot)
# ---------------------------------------------------------------------------
$RequiredPaths = @(
    'GUARDRAILS\GUARDRAILS.jsonl',
    'GUARDRAILS\GUARDRAILS.SCHEMA.json',
    'TASKS\TASKS.jsonl',
    'TASKS\TASKS.SCHEMA.json',
    'SNAPSHOT\SNAPSHOT.json',
    'SNAPSHOT\SNAPSHOT.SCHEMA.json',
    'PROGRESS\PROGRESS.jsonl'
)
if ($Strict) {
    $RequiredPaths += 'PROGRESS\PROGRESS.SCHEMA.json'
}

$ProgressSchemaPath = Join-Path $ArtifactsRoot 'PROGRESS\PROGRESS.SCHEMA.json'
$HasProgressSchema = (Test-Path -LiteralPath $ProgressSchemaPath -PathType Leaf)

# ---------------------------------------------------------------------------
# Helpers: empty check, JSON parse, schema validation
# ---------------------------------------------------------------------------

function Test-FileEmptyOrWhitespace {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    return ($null -eq $raw) -or ([string]::IsNullOrWhiteSpace($raw))
}

function Read-FileUtf8 {
    param([string]$Path)
    return Get-Content -LiteralPath $Path -Raw -Encoding UTF8
}

function Get-JsonLines {
    param([string]$Path)
    $lines = Get-Content -LiteralPath $Path -Encoding UTF8
    $result = @()
    foreach ($line in $lines) {
        $t = $line.Trim()
        if ($t -eq '') { continue }
        $result += $t
    }
    return $result
}

# Minimal JSON Schema validation (required, types, enum, additionalProperties)
function Test-ObjectAgainstSchema {
    param(
        $Obj,
        $Schema,
        [string]$Context = ''
    )
    $errs = @()

    $required = $Schema.required
    if ($required -is [array]) {
        foreach ($key in $required) {
            if (-not (Test-ObjectHasKey -Obj $Obj -Key $key)) {
                $errs += "${Context}Missing required property: '$key'"
            }
        }
    }

    $props = $Schema.properties
    if ($null -ne $props) {
        $allowed = @(Get-ObjectKeys -Obj $props)
        foreach ($key in @(Get-ObjectKeys -Obj $Obj)) {
            if ($key -notin $allowed) {
                $addProp = Get-ObjectValue -Obj $Schema -Key 'additionalProperties'
                if ($addProp -eq $false -or ($addProp -is [bool] -and -not $addProp)) {
                    $errs += "${Context}Additional property not allowed: '$key'"
                }
            } else {
                $propSchema = Get-ObjectValue -Obj $props -Key $key
                if ($null -ne $propSchema) {
                    $val = Get-ObjectValue -Obj $Obj -Key $key
                    $enum = Get-ObjectValue -Obj $propSchema -Key 'enum'
                    if ($null -ne $enum -and $enum -is [array]) {
                        if ($null -eq $val -or $val -notin $enum) {
                            $errs += "${Context}Property '$key' must be one of: $($enum -join ', ')"
                        }
                    }
                    $typ = Get-ObjectValue -Obj $propSchema -Key 'type'
                    if ($null -ne $typ) {
                        $ok = $false
                        switch ($typ) {
                            'string'  { $ok = ($null -eq $val) -or ($val -is [string]) }
                            'integer' { $ok = ($null -eq $val) -or ($val -is [int]) -or ($val -is [long]) }
                            'number'  { $ok = ($null -eq $val) -or ($val -is [int]) -or ($val -is [long]) -or ($val -is [double]) }
                            'object'  { $ok = ($null -eq $val) -or ($val -is [System.Collections.IDictionary]) -or ($val -is [PSCustomObject]) }
                            'array'   { $ok = ($null -eq $val) -or ($val -is [array]) }
                            default   { $ok = $true }
                        }
                        if (-not $ok) {
                            $errs += "${Context}Property '$key' must be of type: $typ"
                        }
                    }
                }
            }
        }
    }

    return $errs
}

function Get-ObjectKeys {
    param($Obj)
    if ($null -eq $Obj) { return @() }
    if ($Obj -is [System.Collections.IDictionary]) { return @($Obj.Keys) }
    return @($Obj.PSObject.Properties.Name)
}

function Get-ObjectValue {
    param($Obj, [string]$Key)
    if ($null -eq $Obj) { return $null }
    if ($Obj -is [System.Collections.IDictionary]) { return $Obj[$Key] }
    $p = $Obj.PSObject.Properties | Where-Object { $_.Name -eq $Key } | Select-Object -First 1
    if ($p) { return $p.Value }
    return $null
}

function Test-ObjectHasKey {
    param($Obj, [string]$Key)
    if ($null -eq $Obj) { return $false }
    if ($Obj -is [System.Collections.IDictionary]) { return $Obj.Contains($Key) }
    return (Get-ObjectKeys -Obj $Obj) -contains $Key
}

function ConvertFrom-JsonSafe {
    param([string]$Json, [string]$Context)
    try {
        return $Json | ConvertFrom-Json
    } catch {
        throw "${Context}$($_.Exception.Message)"
    }
}

# ---------------------------------------------------------------------------
# Step 1: Assert directory intact (all required paths exist)
# ---------------------------------------------------------------------------
$missing = @()
foreach ($rel in $RequiredPaths) {
    $full = Join-Path $ArtifactsRoot $rel
    if (-not (Test-Path -LiteralPath $full)) {
        $missing += $rel
    }
}

$allErrors = @()
if ($missing.Count -gt 0) {
    $allErrors += "ARTIFACTS directory not intact. Missing: $($missing -join ', ')"
}

# ---------------------------------------------------------------------------
# Step 2: Per-file validation (empty or schema-compliant)
# ---------------------------------------------------------------------------

# GUARDRAILS.SCHEMA.json
$p = Join-Path $ArtifactsRoot 'GUARDRAILS\GUARDRAILS.SCHEMA.json'
if (-not $allErrors.Count) {
    if (-not (Test-FileEmptyOrWhitespace -Path $p)) {
        try {
            $raw = Read-FileUtf8 -Path $p
            $schema = ConvertFrom-JsonSafe -Json $raw -Context "GUARDRAILS.SCHEMA.json: "
            $hasSchema = Get-ObjectValue -Obj $schema -Key '$schema'
            $hasType = Get-ObjectValue -Obj $schema -Key 'type'
            $hasProps = Get-ObjectValue -Obj $schema -Key 'properties'
            if (-not ($hasSchema -and $hasType -and $hasProps)) {
                $allErrors += "GUARDRAILS.SCHEMA.json: invalid schema (expected `$schema, type, properties)"
            }
        } catch {
            $allErrors += "GUARDRAILS.SCHEMA.json: $($_.Exception.Message)"
        }
    }
}

# TASKS.SCHEMA.json
$p = Join-Path $ArtifactsRoot 'TASKS\TASKS.SCHEMA.json'
if (-not $allErrors.Count) {
    if (-not (Test-FileEmptyOrWhitespace -Path $p)) {
        try {
            $raw = Read-FileUtf8 -Path $p
            $schema = ConvertFrom-JsonSafe -Json $raw -Context "TASKS.SCHEMA.json: "
            $hasSchema = Get-ObjectValue -Obj $schema -Key '$schema'
            $hasType = Get-ObjectValue -Obj $schema -Key 'type'
            $hasProps = Get-ObjectValue -Obj $schema -Key 'properties'
            if (-not ($hasSchema -and $hasType -and $hasProps)) {
                $allErrors += "TASKS.SCHEMA.json: invalid schema (expected `$schema, type, properties)"
            }
        } catch {
            $allErrors += "TASKS.SCHEMA.json: $($_.Exception.Message)"
        }
    }
}

# GUARDRAILS.jsonl
$guardrailsSchemaPath = Join-Path $ArtifactsRoot 'GUARDRAILS\GUARDRAILS.SCHEMA.json'
$guardrailsPath = Join-Path $ArtifactsRoot 'GUARDRAILS\GUARDRAILS.jsonl'
if (-not (Test-FileEmptyOrWhitespace -Path $guardrailsPath)) {
    try {
        $guardSchemaRaw = Read-FileUtf8 -Path $guardrailsSchemaPath
        $guardSchema = ConvertFrom-JsonSafe -Json $guardSchemaRaw -Context "GUARDRAILS.SCHEMA.json: "
    } catch {
        $allErrors += "GUARDRAILS.SCHEMA.json (for validation): $($_.Exception.Message)"
    }
    if ($guardSchema) {
        $lineNum = 0
        foreach ($line in (Get-JsonLines -Path $guardrailsPath)) {
            $lineNum++
            try {
                $obj = ConvertFrom-JsonSafe -Json $line -Context "GUARDRAILS.jsonl line $lineNum`: "
                $errs = Test-ObjectAgainstSchema -Obj $obj -Schema $guardSchema -Context "GUARDRAILS.jsonl line $lineNum`: "
                foreach ($e in $errs) { $allErrors += $e }
            } catch {
                $allErrors += $_.Exception.Message
            }
        }
    }
}

# TASKS.jsonl
$tasksSchemaPath = Join-Path $ArtifactsRoot 'TASKS\TASKS.SCHEMA.json'
$tasksPath = Join-Path $ArtifactsRoot 'TASKS\TASKS.jsonl'
if (-not (Test-FileEmptyOrWhitespace -Path $tasksPath)) {
    try {
        $taskSchemaRaw = Read-FileUtf8 -Path $tasksSchemaPath
        $taskSchema = ConvertFrom-JsonSafe -Json $taskSchemaRaw -Context "TASKS.SCHEMA.json: "
    } catch {
        $allErrors += "TASKS.SCHEMA.json (for validation): $($_.Exception.Message)"
    }
    if ($taskSchema) {
        $lineNum = 0
        foreach ($line in (Get-JsonLines -Path $tasksPath)) {
            $lineNum++
            try {
                $obj = ConvertFrom-JsonSafe -Json $line -Context "TASKS.jsonl line $lineNum`: "
                $errs = Test-ObjectAgainstSchema -Obj $obj -Schema $taskSchema -Context "TASKS.jsonl line $lineNum`: "
                foreach ($e in $errs) { $allErrors += $e }
            } catch {
                $allErrors += $_.Exception.Message
            }
        }
    }
}

# SNAPSHOT.json (valid JSON and validate against SNAPSHOT.SCHEMA.json)
$snapshotJsonPath = Join-Path $ArtifactsRoot 'SNAPSHOT\SNAPSHOT.json'
$snapshotSchemaPath = Join-Path $ArtifactsRoot 'SNAPSHOT\SNAPSHOT.SCHEMA.json'
if (-not (Test-FileEmptyOrWhitespace -Path $snapshotJsonPath)) {
    try {
        $snapshotSchemaRaw = Read-FileUtf8 -Path $snapshotSchemaPath
        $snapshotSchema = ConvertFrom-JsonSafe -Json $snapshotSchemaRaw -Context "SNAPSHOT.SCHEMA.json: "
        $raw = Read-FileUtf8 -Path $snapshotJsonPath
        $snapshotObj = ConvertFrom-JsonSafe -Json $raw -Context "SNAPSHOT.json: "
        $errs = Test-ObjectAgainstSchema -Obj $snapshotObj -Schema $snapshotSchema -Context "SNAPSHOT.json: "
        foreach ($e in $errs) { $allErrors += $e }
    } catch {
        $allErrors += "SNAPSHOT.json: $($_.Exception.Message)"
    }
}

# SNAPSHOT.SCHEMA.json (validate as JSON)
if (-not (Test-FileEmptyOrWhitespace -Path $snapshotSchemaPath)) {
    try {
        $raw = Read-FileUtf8 -Path $snapshotSchemaPath
        $null = ConvertFrom-JsonSafe -Json $raw -Context "SNAPSHOT.SCHEMA.json: "
    } catch {
        $allErrors += "SNAPSHOT.SCHEMA.json: $($_.Exception.Message)"
    }
}

# PROGRESS.jsonl (valid JSON per line; if PROGRESS.SCHEMA.json exists, validate each line)
$progressJsonlPath = Join-Path $ArtifactsRoot 'PROGRESS\PROGRESS.jsonl'
if (-not (Test-FileEmptyOrWhitespace -Path $progressJsonlPath)) {
    $progressSchema = $null
    if ($HasProgressSchema) {
        try {
            $progressSchemaRaw = Read-FileUtf8 -Path $ProgressSchemaPath
            $progressSchema = ConvertFrom-JsonSafe -Json $progressSchemaRaw -Context "PROGRESS.SCHEMA.json: "
        } catch {
            $allErrors += "PROGRESS.SCHEMA.json (for validation): $($_.Exception.Message)"
        }
    }
    $lineNum = 0
    foreach ($line in (Get-JsonLines -Path $progressJsonlPath)) {
        $lineNum++
        try {
            $obj = ConvertFrom-JsonSafe -Json $line -Context "PROGRESS.jsonl line $lineNum`: "
            if ($progressSchema) {
                $errs = Test-ObjectAgainstSchema -Obj $obj -Schema $progressSchema -Context "PROGRESS.jsonl line $lineNum`: "
                foreach ($e in $errs) { $allErrors += $e }
            }
        } catch {
            $allErrors += $_.Exception.Message
        }
    }
}

# Optional PROGRESS.SCHEMA.json (if present and non-empty, validate as JSON)
if ($HasProgressSchema) {
    if (-not (Test-FileEmptyOrWhitespace -Path $ProgressSchemaPath)) {
        try {
            $raw = Read-FileUtf8 -Path $ProgressSchemaPath
            $null = ConvertFrom-JsonSafe -Json $raw -Context "PROGRESS.SCHEMA.json: "
        } catch {
            $allErrors += "PROGRESS.SCHEMA.json: $($_.Exception.Message)"
        }
    }
}

# ---------------------------------------------------------------------------
# Output and exit
# ---------------------------------------------------------------------------
if ($allErrors.Count -eq 0) {
    Write-Host "ASSERT_ARTIFACTS: ARTIFACTS directory intact; all files empty or schema-compliant." -ForegroundColor Green
    exit 0
} else {
    Write-Host "ASSERT_ARTIFACTS: Validation failed." -ForegroundColor Red
    foreach ($e in $allErrors) {
        Write-Host "  $e" -ForegroundColor Red
    }
    exit 1
}
