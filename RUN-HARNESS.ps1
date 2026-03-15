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

function Write-HarnessHeader {
    param([string]$Text)
    $line = '=' * [Math]::Min(78, [Math]::Max(40, $Text.Length + 4))
    Write-Host ''
    Write-Host $line -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host $line -ForegroundColor Cyan
}

function Write-HarnessStep {
    param([string]$Text, [string]$Symbol = '>')
    Write-Host "  $Symbol " -ForegroundColor DarkCyan -NoNewline
    Write-Host $Text
}

function Write-HarnessProgress {
    param([string]$Text)
    Write-Host "    " -NoNewline
    Write-Host $Text -ForegroundColor Gray
}

function Format-Elapsed {
    param([int]$TotalSeconds)
    $h = [Math]::Floor($TotalSeconds / 3600)
    $m = [Math]::Floor(($TotalSeconds % 3600) / 60)
    $s = $TotalSeconds % 60
    $parts = @()
    if ($h -eq 1) { $parts += '1 hour' } elseif ($h -gt 1) { $parts += "$h hours" }
    if ($m -eq 1) { $parts += '1 minute' } elseif ($m -gt 1) { $parts += "$m minutes" }
    if ($parts.Count -eq 0 -or $s -gt 0) {
        if ($s -eq 1) { $parts += '1 second' } else { $parts += "$s seconds" }
    }
    return $parts -join ', '
}

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
    $content | Set-Content -LiteralPath $TasksPath -Encoding UTF8
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

# Progress ping interval while waiting for agent (seconds)
$progressIntervalSec = 30

Write-HarnessHeader 'HARNESS RUN'
Write-HarnessStep "Tasks file: $TasksPath"
Write-HarnessStep "Max tasks this run: $(if ($maxTasks -eq [int]::MaxValue) { 'unlimited' } else { $maxTasks })"
Write-HarnessStep "Task timeout: $(if ($maxDurationSec -gt 0) { Format-Elapsed $maxDurationSec } else { 'none' })"
Write-HarnessStep "Delay between tasks: ${delayBetweenTasks}s"
Write-Host ''

while ($true) {
    $iteration++
    $tasks = Get-Tasks
    $totalPending = ($tasks | Where-Object { $_.status -eq 'pending' }).Count
    $next = Get-NextPendingTask -Tasks $tasks -MaxTasks $maxTasks -ProcessedCount $processedCount

    if (-not $next) {
        Write-Host ''
        if ($iteration -eq 1) {
            Write-HarnessStep 'No pending tasks in TASKS.jsonl. Exiting.' '!'
        } else {
            Write-HarnessHeader 'HARNESS RUN COMPLETE'
            Write-HarnessStep "Processed $processedCount task(s). No more pending tasks."
        }
        exit 0
    }

    $taskId = $next.id
    $taskTitle = $next.title
    $taskDesc = if ($next.description) { $next.description } else { '' }

    Write-HarnessHeader "TASK $iteration | $taskId"
    Write-HarnessStep $taskTitle
    Write-HarnessProgress "Pending tasks remaining: $totalPending"
    Write-HarnessStep "Marking task in_progress and invoking agent (timeout: $(Format-Elapsed $maxDurationSec))..." '>'
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
    $promptFile = [System.IO.Path]::GetTempFileName()
    try {
        Set-Content -LiteralPath $promptFile -Value $prompt -Encoding UTF8 -NoNewline
        $promptPathEscaped = $promptFile -replace "'", "''"
        $agentCommand = "& agent -p --force --output-format text (Get-Content -LiteralPath '$promptPathEscaped' -Raw)"
        $agentArgs = @('-NoProfile', '-NonInteractive', '-Command', $agentCommand)
        $proc = Start-Process -FilePath 'powershell.exe' -ArgumentList $agentArgs -PassThru -NoNewWindow `
            -RedirectStandardOutput $outFile `
            -RedirectStandardError $errFile `
            -WorkingDirectory $HarnessRoot

        Write-HarnessProgress "Agent process started (PID $($proc.Id)). Waiting for completion..."
        $startTime = Get-Date
        $exited = $false
        $lastProgress = 0
        while (-not $proc.HasExited) {
            $elapsed = [int]((Get-Date) - $startTime).TotalSeconds
            if ($timeoutMs -lt [int]::MaxValue -and ($elapsed * 1000) -ge $timeoutMs) {
                $exited = $false
                break
            }
            if ($elapsed -ge $lastProgress + $progressIntervalSec -or $elapsed -eq 0) {
                Write-HarnessProgress "Agent still running... $(Format-Elapsed $elapsed) elapsed"
                $lastProgress = $elapsed
            }
            Start-Sleep -Seconds 5
        }
        if (-not $proc.HasExited) {
            $exited = $false
        } else {
            $exited = $true
        }

        if (-not $exited) {
            Write-Host "    ! Task timed out after $(Format-Elapsed $maxDurationSec). Stopping agent process." -ForegroundColor Yellow
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        }

        $exitCode = if ($proc.HasExited) { $proc.ExitCode } else { -1 }
        Write-Host ''
        Write-HarnessStep "Task process finished (exit code: $exitCode). Agent output below:" '='
        Write-Host ''
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
            Write-HarnessProgress "Task $taskId marked completed by script (agent did not update status)."
        }

        Write-Host ''
        if (-not $exited) {
            Write-HarnessStep "Run ended due to timeout. Consider increasing max_task_duration in HARNESS/SETTINGS.json." '!'
        }
        if ($exitCode -ne 0) {
            Write-HarnessStep "Agent exited with code $exitCode." '!'
        }
        Write-HarnessStep "Task $taskId done. Processed: $($processedCount + 1) so far."
    } finally {
        if (Test-Path $outFile) { Remove-Item -LiteralPath $outFile -Force -ErrorAction SilentlyContinue }
        if (Test-Path $errFile) { Remove-Item -LiteralPath $errFile -Force -ErrorAction SilentlyContinue }
        if (Test-Path $promptFile) { Remove-Item -LiteralPath $promptFile -Force -ErrorAction SilentlyContinue }
    }

    $processedCount++
    if ($delayBetweenTasks -gt 0) {
        $remaining = Get-Tasks
        $stillPending = ($remaining | Where-Object { $_.status -eq 'pending' }).Count
        if ($stillPending -gt 0) {
            Write-Host ''
            Write-HarnessStep "Pausing $delayBetweenTasks s before next task ($stillPending pending)..." '...'
            Start-Sleep -Seconds $delayBetweenTasks
        }
    }
}
