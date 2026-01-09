<#
.SYNOPSIS
    Outputs session context for Claude Code initialization
.DESCRIPTION
    Gathers and displays:
    - Most recent handoff (with summary excerpt)
    - Active ticket in dev_in_progress
    - NEXT ticket from STATUS.md
    - Most recent test run results
    - Git status
    - Ticket counts by status
    - Documented blockers
    - Last commit info

    Also writes environment variables to CLAUDE_ENV_FILE for use in subsequent commands.
.EXAMPLE
    .\session-context.ps1
#>

$ErrorActionPreference = "SilentlyContinue"
$projectRoot = "$PSScriptRoot\..\.."
$ticketsRoot = "$projectRoot\tickets"
$handoffsRoot = "$projectRoot\handoffs"

# Environment variables to persist
$envVars = @{}

Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "  SESSION CONTEXT SUMMARY" -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host ""

# --------------------------------------------------------------
# 1. Most Recent Handoff
# --------------------------------------------------------------
Write-Host "[MOST RECENT HANDOFF]" -ForegroundColor Yellow
$handoffDir = "$handoffsRoot\session_summaries"
$latestHandoff = Get-ChildItem -Path $handoffDir -Filter "*.md" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if ($latestHandoff) {
    Write-Host "  File: $($latestHandoff.Name)"
    Write-Host "  Date: $($latestHandoff.LastWriteTime.ToString('yyyy-MM-dd HH:mm'))"
    $envVars["SESSION_HANDOFF_FILE"] = $latestHandoff.Name
    $envVars["SESSION_HANDOFF_PATH"] = $latestHandoff.FullName

    # Extract summary section (first 5 non-empty lines after ## Summary)
    $content = Get-Content $latestHandoff.FullName -Raw
    if ($content -match "(?s)## Summary\s*\n(.+?)(?=\n## |\z)") {
        $summaryText = $matches[1].Trim()
        $summary = $summaryText -split "`n" | Select-Object -First 5
        Write-Host "  Summary:" -ForegroundColor Gray
        foreach ($line in $summary) {
            $trimmed = $line.Trim()
            if ($trimmed) {
                Write-Host "    $trimmed"
            }
        }
        # Store first line of summary as env var
        $firstLine = ($summaryText -split "`n" | Where-Object { $_.Trim() } | Select-Object -First 1).Trim()
        $envVars["SESSION_HANDOFF_SUMMARY"] = $firstLine
    }
} else {
    Write-Host "  No handoffs found" -ForegroundColor DarkGray
    $envVars["SESSION_HANDOFF_FILE"] = ""
}
Write-Host ""

# --------------------------------------------------------------
# 2. Active Ticket in dev_in_progress
# --------------------------------------------------------------
Write-Host "[ACTIVE TICKET (dev_in_progress)]" -ForegroundColor Yellow
$inProgressDir = "$ticketsRoot\dev_in_progress"
$activeTicket = Get-ChildItem -Path $inProgressDir -Filter "FW-*.md" -ErrorAction SilentlyContinue |
    Select-Object -First 1

if ($activeTicket) {
    $ticketName = [System.IO.Path]::GetFileNameWithoutExtension($activeTicket.Name)
    Write-Host "  ACTIVE: $ticketName" -ForegroundColor Green
    $envVars["SESSION_ACTIVE_TICKET"] = $ticketName
    $envVars["SESSION_ACTIVE_TICKET_PATH"] = $activeTicket.FullName

    # Extract title from frontmatter
    $ticketContent = Get-Content $activeTicket.FullName -Raw
    if ($ticketContent -match 'title:\s*"([^"]+)"') {
        Write-Host "  Title: $($matches[1])"
        $envVars["SESSION_ACTIVE_TICKET_TITLE"] = $matches[1]
    }
} else {
    Write-Host "  No active ticket" -ForegroundColor DarkGray
    $envVars["SESSION_ACTIVE_TICKET"] = ""
}
Write-Host ""

# --------------------------------------------------------------
# 3. NEXT Ticket from STATUS.md
# --------------------------------------------------------------
Write-Host "[NEXT TICKET]" -ForegroundColor Yellow
$statusFile = "$ticketsRoot\STATUS.md"
if (Test-Path $statusFile) {
    $statusContent = Get-Content $statusFile -Raw
    if ($statusContent -match "\*\*NEXT\*\*:\s*(\S+)") {
        $nextTicket = $matches[1]
        Write-Host "  NEXT: $nextTicket" -ForegroundColor Magenta
        $envVars["SESSION_NEXT_TICKET"] = $nextTicket

        # Find the title from the table
        if ($statusContent -match "\|\s*$nextTicket\s*\|\s*([^|]+)\s*\|") {
            Write-Host "  Title: $($matches[1].Trim())"
            $envVars["SESSION_NEXT_TICKET_TITLE"] = $matches[1].Trim()
        }
    } else {
        Write-Host "  No NEXT ticket defined" -ForegroundColor DarkGray
        $envVars["SESSION_NEXT_TICKET"] = ""
    }
} else {
    Write-Host "  STATUS.md not found" -ForegroundColor Red
    $envVars["SESSION_NEXT_TICKET"] = ""
}
Write-Host ""

# --------------------------------------------------------------
# 4. Most Recent Test Run
# --------------------------------------------------------------
Write-Host "[LAST TEST RUN]" -ForegroundColor Yellow
$testResultsDir = "$projectRoot\.gut_results"
$latestTestResult = Get-ChildItem -Path $testResultsDir -Filter "*.json" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if ($latestTestResult) {
    Write-Host "  Date: $($latestTestResult.LastWriteTime.ToString('yyyy-MM-dd HH:mm'))"
    $envVars["SESSION_TEST_DATE"] = $latestTestResult.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
    try {
        $testJson = Get-Content $latestTestResult.FullName -Raw | ConvertFrom-Json
        $passed = $testJson.passing_count
        $failed = $testJson.failing_count
        $total = $passed + $failed
        $envVars["SESSION_TEST_PASSED"] = "$passed"
        $envVars["SESSION_TEST_FAILED"] = "$failed"
        $envVars["SESSION_TEST_TOTAL"] = "$total"
        if ($failed -eq 0) {
            Write-Host "  Result: $passed/$total PASSED" -ForegroundColor Green
            $envVars["SESSION_TEST_STATUS"] = "PASSED"
        } else {
            Write-Host "  Result: $failed FAILED, $passed passed" -ForegroundColor Red
            $envVars["SESSION_TEST_STATUS"] = "FAILED"
        }
    } catch {
        Write-Host "  Could not parse test results" -ForegroundColor DarkGray
        $envVars["SESSION_TEST_STATUS"] = "UNKNOWN"
    }
} else {
    Write-Host "  No test results found" -ForegroundColor DarkGray
    Write-Host "  Run tests with: `$GODOT --headless -s addons/gut/gut_cmdln.gd ..." -ForegroundColor DarkGray
    $envVars["SESSION_TEST_STATUS"] = "NONE"
}
Write-Host ""

# --------------------------------------------------------------
# 5. Git Status
# --------------------------------------------------------------
Write-Host "[GIT STATUS]" -ForegroundColor Yellow
Push-Location $projectRoot
$branch = git branch --show-current 2>$null
$status = git status --porcelain 2>$null
$uncommitted = ($status | Measure-Object).Count

Write-Host "  Branch: $branch"
$envVars["SESSION_GIT_BRANCH"] = $branch
$envVars["SESSION_GIT_UNCOMMITTED"] = "$uncommitted"

if ($uncommitted -gt 0) {
    Write-Host "  Uncommitted changes: $uncommitted files" -ForegroundColor Yellow
} else {
    Write-Host "  Working tree clean" -ForegroundColor Green
}
Pop-Location
Write-Host ""

# --------------------------------------------------------------
# 6. Ticket Counts by Status
# --------------------------------------------------------------
Write-Host "[TICKET COUNTS]" -ForegroundColor Yellow
$statuses = @("draft", "ready", "dev_in_progress", "for_review", "completed")
foreach ($st in $statuses) {
    $dir = "$ticketsRoot\$st"
    $count = (Get-ChildItem -Path $dir -Filter "FW-*.md" -ErrorAction SilentlyContinue | Measure-Object).Count
    $color = "White"
    if ($st -eq "dev_in_progress" -and $count -gt 0) { $color = "Green" }
    if ($st -eq "for_review" -and $count -gt 0) { $color = "Cyan" }
    if ($st -eq "ready") { $color = "Gray" }
    Write-Host "  $($st.PadRight(18)) $count" -ForegroundColor $color
    $envVars["SESSION_TICKETS_$($st.ToUpper())"] = "$count"
}
Write-Host ""

# --------------------------------------------------------------
# 7. Blockers
# --------------------------------------------------------------
Write-Host "[BLOCKERS]" -ForegroundColor Yellow
$blockersDir = "$handoffsRoot\blockers"
$blockers = Get-ChildItem -Path $blockersDir -Filter "*.md" -ErrorAction SilentlyContinue

if ($blockers -and $blockers.Count -gt 0) {
    Write-Host "  BLOCKERS FOUND: $($blockers.Count)" -ForegroundColor Red
    $envVars["SESSION_BLOCKERS_COUNT"] = "$($blockers.Count)"
    $blockerNames = @()
    foreach ($blocker in $blockers) {
        Write-Host "    - $($blocker.Name)" -ForegroundColor Red
        $blockerNames += $blocker.Name
    }
    $envVars["SESSION_BLOCKERS"] = $blockerNames -join ","
} else {
    Write-Host "  No blockers documented" -ForegroundColor Green
    $envVars["SESSION_BLOCKERS_COUNT"] = "0"
    $envVars["SESSION_BLOCKERS"] = ""
}
Write-Host ""

# --------------------------------------------------------------
# 8. Last Commit
# --------------------------------------------------------------
Write-Host "[LAST COMMIT]" -ForegroundColor Yellow
Push-Location $projectRoot
$lastCommitHash = git log -1 --format="%h" 2>$null
$lastCommitMsg = git log -1 --format="%s" 2>$null
$lastCommitDate = git log -1 --format="%ci" 2>$null
if ($lastCommitHash) {
    Write-Host "  $lastCommitDate"
    Write-Host "  $lastCommitHash $lastCommitMsg"
    $envVars["SESSION_LAST_COMMIT_HASH"] = $lastCommitHash
    $envVars["SESSION_LAST_COMMIT_MSG"] = $lastCommitMsg
    $envVars["SESSION_LAST_COMMIT_DATE"] = $lastCommitDate
} else {
    Write-Host "  No commits found" -ForegroundColor DarkGray
}
Pop-Location
Write-Host ""

Write-Host "==============================================================" -ForegroundColor Cyan

# --------------------------------------------------------------
# Write environment variables to CLAUDE_ENV_FILE (if available)
# --------------------------------------------------------------
if ($env:CLAUDE_ENV_FILE) {
    $lines = @()
    foreach ($key in $envVars.Keys) {
        $value = $envVars[$key] -replace '"', '\"'
        $lines += "export $key=`"$value`""
    }
    # Append with Unix line endings (LF only) - must append, not overwrite
    $content = ($lines -join "`n") + "`n"
    [System.IO.File]::AppendAllText($env:CLAUDE_ENV_FILE, $content)
}

# --------------------------------------------------------------
# Write session_start.md for Claude to read
# --------------------------------------------------------------
$sessionFile = "$projectRoot\cc_workflow\session_start.md"
$md = @"
# Session Context

Auto-generated by SessionStart hook. Read this file to understand current project state.

## Active Work

| Key | Value |
|-----|-------|
| Active Ticket | $($envVars["SESSION_ACTIVE_TICKET"]) |
| Active Ticket Title | $($envVars["SESSION_ACTIVE_TICKET_TITLE"]) |
| Next Ticket | $($envVars["SESSION_NEXT_TICKET"]) |
| Next Ticket Title | $($envVars["SESSION_NEXT_TICKET_TITLE"]) |

## Last Handoff

| Key | Value |
|-----|-------|
| File | $($envVars["SESSION_HANDOFF_FILE"]) |
| Path | $($envVars["SESSION_HANDOFF_PATH"]) |
| Summary | $($envVars["SESSION_HANDOFF_SUMMARY"]) |

## Test Status

| Key | Value |
|-----|-------|
| Status | $($envVars["SESSION_TEST_STATUS"]) |
| Passed | $($envVars["SESSION_TEST_PASSED"]) |
| Failed | $($envVars["SESSION_TEST_FAILED"]) |
| Total | $($envVars["SESSION_TEST_TOTAL"]) |
| Date | $($envVars["SESSION_TEST_DATE"]) |

## Git Status

| Key | Value |
|-----|-------|
| Branch | $($envVars["SESSION_GIT_BRANCH"]) |
| Uncommitted Files | $($envVars["SESSION_GIT_UNCOMMITTED"]) |
| Last Commit Hash | $($envVars["SESSION_LAST_COMMIT_HASH"]) |
| Last Commit Message | $($envVars["SESSION_LAST_COMMIT_MSG"]) |
| Last Commit Date | $($envVars["SESSION_LAST_COMMIT_DATE"]) |

## Ticket Counts

| Status | Count |
|--------|-------|
| Draft | $($envVars["SESSION_TICKETS_DRAFT"]) |
| Ready | $($envVars["SESSION_TICKETS_READY"]) |
| In Progress | $($envVars["SESSION_TICKETS_DEV_IN_PROGRESS"]) |
| For Review | $($envVars["SESSION_TICKETS_FOR_REVIEW"]) |
| Completed | $($envVars["SESSION_TICKETS_COMPLETED"]) |

## Blockers

| Key | Value |
|-----|-------|
| Count | $($envVars["SESSION_BLOCKERS_COUNT"]) |
| Files | $($envVars["SESSION_BLOCKERS"]) |
"@

[System.IO.File]::WriteAllText($sessionFile, $md)

exit 0
