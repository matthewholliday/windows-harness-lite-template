<#
.SYNOPSIS
    Runs the harness: processes pending tasks from TASKS.jsonl by invoking the Cursor CLI
    with the dev.manager subagent until no pending tasks remain.
.DESCRIPTION
    Reads HARNESS/ARTIFACTS/TASKS/TASKS.jsonl, selects the next pending task (by order),
    marks it in_progress, invokes "agent -p --force" with a prompt that delegates to
    dev.manager, then marks the task completed and repeats until no pending tasks or
    limits are reached.
#>

param(
    [string]$HarnessRoot = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'
$TasksPath = Join-Path $HarnessRoot 'HARNESS\ARTIFACTS\TASKS\TASKS.jsonl'
$SettingsPath = Join-Path $HarnessRoot 'HARNESS\SETTINGS.json'

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Get-Settings {
    if (-not (Test-Path -LiteralPath $SettingsPath)) {
        return @{
            limits = @{
                max_attempts_per_task = -1
                max_total_attempts    = -1
                max_tasks             = -1
                max_task_duration     = 3600
                max_spend             = 25
                delay_between_tasks   = 30
            }
        }
    }
    $raw = Get-Content -LiteralPath $SettingsPath -Raw
    $noComments = $raw -replace '//[^\r\n]*', ''
    return $noComments | ConvertFrom-Json
}

function Get-Tasks {
    if (-not (Test-Path -LiteralPath $TasksPath)) {
        return @()
    }
    $lines = Get-Content -LiteralPath $TasksPath -Encoding UTF8
    $tasks = @()
    foreach ($line in $lines) {
        $line = $line.Trim()
        if (-not $line) { continue }
        try {
            $tasks += $line | ConvertFrom-Json
        } catch {
            Write-Warning "Skipping invalid JSON line in TASKS.jsonl: $line"
        }
    }
    return $tasks
}

function Set-Tasks {
    param([array]$Tasks)
    $dir = Split-Path -Parent $TasksPath
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $content = foreach ($t in $Tasks) {
        $t | ConvertTo-Json -Compress
    }
    $content | Set-Content -LiteralPath $TasksPath -Encoding UTF8 -NoNewline
    # Ensure file ends with newline for JSONL convention
    $bytes = [System.IO.File]::ReadAllBytes($TasksPath)
    if ($bytes.Length -gt 0 -and $bytes[-1] -ne 10) {
        [System.IO.File]::AppendAllText($TasksPath, "`n")
    }
}

function Get-NextPendingTask {
    param([array]$Tasks, [int]$MaxTasks, [int]$ProcessedCount)
    if ($MaxTasks -ge 0 -and $ProcessedCount -ge $MaxTasks) {
        return $null
    }
    $pending = $Tasks | Where-Object { $_.status -eq 'pending' }
    if (-not $pending) { return $null }
    $sorted = $pending | Sort-Object { if ($null -eq $_.order) { [int]::MaxValue } else { $_.order } }
    return $sorted[0]
}

function Update-TaskStatus {
    param([array]$Tasks, [string]$TaskId, [string]$Status)
    $updated = @()
    foreach ($t in $Tasks) {
        if ($t.id -eq $TaskId) {
            $t.status = $Status
        }
        $updated += $t
    }
    Set-Tasks -Tasks $updated
}

# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------

$settings = Get-Settings
$limits = $settings.limits
$maxTasks = if ($limits.max_tasks -ge 0) { $limits.max_tasks } else { [int]::MaxValue }
$maxDurationSec = $limits.max_task_duration
$timeoutMs = if ($maxDurationSec -gt 0) { $maxDurationSec * 1000 } else { [int]::MaxValue }
$delayBetweenTasks = if ($limits.delay_between_tasks -ge 0) { $limits.delay_between_tasks } else { 0 }

$processedCount = 0
$iteration = 0

while ($true) {
    $iteration++
    $tasks = Get-Tasks
    $next = Get-NextPendingTask -Tasks $tasks -MaxTasks $maxTasks -ProcessedCount $processedCount

    if (-not $next) {
        if ($iteration -eq 1) {
            Write-Host 'No pending tasks in TASKS.jsonl. Exiting.'
        } else {
            Write-Host 'No more pending tasks. Harness run complete.'
        }
        exit 0
    }

    $taskId = $next.id
    $taskTitle = $next.title
    $taskDesc = if ($next.description) { $next.description } else { '' }

    Write-Host "Task: [$taskId] $taskTitle"
    Update-TaskStatus -Tasks $tasks -TaskId $taskId -Status 'in_progress'

    $prompt = @"
Execute the following task using the dev.manager subagent pipeline.

Task ID: $taskId
Title: $taskTitle
Description: $taskDesc

The task is marked as in_progress in HARNESS/ARTIFACTS/TASKS/TASKS.jsonl.
Use the Task tool with subagent_type="dev.manager" to run the full development pipeline. When complete, ensure the task status is updated to "completed" in TASKS.jsonl.
"@

    $outFile = [System.IO.Path]::GetTempFileName()
    $errFile = [System.IO.Path]::GetTempFileName()
    try {
        $agentArgs = @(
            '-p',
            '--force',
            '--output-format', 'text',
            $prompt
        )
        $proc = Start-Process -FilePath 'agent' -ArgumentList $agentArgs -PassThru -NoNewWindow `
            -RedirectStandardOutput $outFile `
            -RedirectStandardError $errFile `
            -WorkingDirectory $HarnessRoot

        $exited = $proc.WaitForExit($timeoutMs)
        if (-not $exited) {
            Write-Warning "Task timed out after $maxDurationSec seconds. Stopping agent process."
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        }

        $exitCode = $proc.ExitCode
        if (Test-Path $outFile) {
            Get-Content -LiteralPath $outFile -Raw | Write-Host
        }
        if (Test-Path $errFile) {
            $err = Get-Content -LiteralPath $errFile -Raw
            if ($err) { Write-Host $err -ForegroundColor Yellow }
        }

        $tasksAfter = Get-Tasks
        $taskAfter = $tasksAfter | Where-Object { $_.id -eq $taskId } | Select-Object -First 1
        if (-not $taskAfter -or $taskAfter.status -ne 'completed') {
            Update-TaskStatus -Tasks $tasksAfter -TaskId $taskId -Status 'completed'
            Write-Host "Task $taskId marked completed by script (agent did not update status)."
        }

        if (-not $exited) {
            Write-Warning "Run ended due to timeout. Consider increasing max_task_duration in HARNESS/SETTINGS.json."
        }
        if ($exitCode -ne 0) {
            Write-Warning "Agent exited with code $exitCode."
        }
    } finally {
        if (Test-Path $outFile) { Remove-Item -LiteralPath $outFile -Force -ErrorAction SilentlyContinue }
        if (Test-Path $errFile) { Remove-Item -LiteralPath $errFile -Force -ErrorAction SilentlyContinue }
    }

    $processedCount++
    if ($delayBetweenTasks -gt 0) {
        $remaining = Get-Tasks
        $stillPending = ($remaining | Where-Object { $_.status -eq 'pending' }).Count
        if ($stillPending -gt 0) {
            Write-Host "Waiting $delayBetweenTasks seconds before next task..."
            Start-Sleep -Seconds $delayBetweenTasks
        }
    }
}
