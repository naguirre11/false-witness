# PowerShell script to patch OMC plugin with Task tools
# Run after OMC plugin updates: ./cc_workflow/scripts/patch-omc-task-tools.ps1

$agentsDir = "$env:USERPROFILE\.claude\plugins\cache\omc\oh-my-claudecode\*\agents"

# Find the actual version directory
$actualDir = Get-Item $agentsDir -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $actualDir) {
    Write-Error "OMC agents directory not found at: $agentsDir"
    exit 1
}

Write-Host "Patching agents in: $($actualDir.FullName)" -ForegroundColor Cyan

$patchCount = 0

# Patch executor files - replace TodoWrite with Task tools
$executorFiles = @("executor.md", "executor-low.md", "executor-high.md")
foreach ($file in $executorFiles) {
    $path = Join-Path $actualDir.FullName $file
    if (Test-Path $path) {
        $content = Get-Content $path -Raw
        $newContent = $content -replace 'tools: Read, Glob, Grep, Edit, Write, Bash, TodoWrite', 'tools: Read, Glob, Grep, Edit, Write, Bash, TaskCreate, TaskList, TaskUpdate, TaskGet'
        $newContent = $newContent -replace 'TodoWrite', 'TaskCreate'
        if ($newContent -ne $content) {
            Set-Content $path $newContent -NoNewline
            Write-Host "  Patched: $file" -ForegroundColor Green
            $patchCount++
        } else {
            Write-Host "  Already patched: $file" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  Not found: $file" -ForegroundColor Red
    }
}

# Patch build-fixer files - add Task tools
$buildFixerFiles = @("build-fixer.md", "build-fixer-low.md")
foreach ($file in $buildFixerFiles) {
    $path = Join-Path $actualDir.FullName $file
    if (Test-Path $path) {
        $content = Get-Content $path -Raw
        # Match line ending with Bash (no Task tools yet)
        $newContent = $content -replace '(?m)^(tools: Read, Grep, Glob, Edit, Write, Bash)$', '$1, TaskCreate, TaskList, TaskUpdate, TaskGet'
        if ($newContent -ne $content) {
            Set-Content $path $newContent -NoNewline
            Write-Host "  Patched: $file" -ForegroundColor Green
            $patchCount++
        } else {
            Write-Host "  Already patched: $file" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  Not found: $file" -ForegroundColor Red
    }
}

# Patch tdd-guide.md - add Task tools
$path = Join-Path $actualDir.FullName "tdd-guide.md"
if (Test-Path $path) {
    $content = Get-Content $path -Raw
    $newContent = $content -replace '(?m)^(tools: Read, Grep, Glob, Edit, Write, Bash)$', '$1, TaskCreate, TaskList, TaskUpdate, TaskGet'
    if ($newContent -ne $content) {
        Set-Content $path $newContent -NoNewline
        Write-Host "  Patched: tdd-guide.md" -ForegroundColor Green
        $patchCount++
    } else {
        Write-Host "  Already patched: tdd-guide.md" -ForegroundColor Yellow
    }
} else {
    Write-Host "  Not found: tdd-guide.md" -ForegroundColor Red
}

# Patch tdd-guide-low.md - add Task tools (different base tools)
$path = Join-Path $actualDir.FullName "tdd-guide-low.md"
if (Test-Path $path) {
    $content = Get-Content $path -Raw
    $newContent = $content -replace '(?m)^(tools: Read, Grep, Glob, Bash)$', '$1, TaskCreate, TaskList, TaskUpdate, TaskGet'
    if ($newContent -ne $content) {
        Set-Content $path $newContent -NoNewline
        Write-Host "  Patched: tdd-guide-low.md" -ForegroundColor Green
        $patchCount++
    } else {
        Write-Host "  Already patched: tdd-guide-low.md" -ForegroundColor Yellow
    }
} else {
    Write-Host "  Not found: tdd-guide-low.md" -ForegroundColor Red
}

Write-Host ""
if ($patchCount -gt 0) {
    Write-Host "Patched $patchCount file(s). Restart Claude Code for changes to take effect." -ForegroundColor Cyan
} else {
    Write-Host "All files already patched." -ForegroundColor Green
}
