# OMC Plugin: Task Tools Patch

This document describes modifications made to the oh-my-claudecode plugin to enable Task tool access for subagents.

## Problem

OMC subagents (executor, build-fixer, tdd-guide) originally had `TodoWrite` in their tool list, but Claude Code's persistent Task system uses different tools: `TaskCreate`, `TaskList`, `TaskUpdate`, `TaskGet`.

Without Task tools, OMC agents couldn't:
- Read the shared task list
- Update task status (in_progress, completed)
- Coordinate with the main session or other agents

## Solution

Agent tool access is defined in Markdown files with YAML frontmatter in the plugin's `agents/` directory. We patched these files to replace `TodoWrite` with Task tools.

## Location

```
~/.claude/plugins/cache/omc/oh-my-claudecode/<VERSION>/agents/
```

Current version: `3.3.10`

## Files Modified

### 1. executor.md

**Line 5** - YAML frontmatter `tools:` field:
```yaml
# BEFORE
tools: Read, Glob, Grep, Edit, Write, Bash, TodoWrite

# AFTER
tools: Read, Glob, Grep, Edit, Write, Bash, TaskCreate, TaskList, TaskUpdate, TaskGet
```

**Line 43** - Prompt reference:
```
# BEFORE
- 2+ steps → TodoWrite FIRST, atomic breakdown

# AFTER
- 2+ steps → TaskCreate FIRST, atomic breakdown
```

### 2. executor-low.md

**Line 4** - YAML frontmatter:
```yaml
# BEFORE
tools: Read, Glob, Grep, Edit, Write, Bash, TodoWrite

# AFTER
tools: Read, Glob, Grep, Edit, Write, Bash, TaskCreate, TaskList, TaskUpdate, TaskGet
```

**Lines 43, 49** - Prompt references to TodoWrite → TaskCreate

### 3. executor-high.md

**Line 4** - YAML frontmatter:
```yaml
# BEFORE
tools: Read, Glob, Grep, Edit, Write, Bash, TodoWrite

# AFTER
tools: Read, Glob, Grep, Edit, Write, Bash, TaskCreate, TaskList, TaskUpdate, TaskGet
```

**Prompt references** - TodoWrite → TaskCreate

### 4. build-fixer.md

**Line 5** - YAML frontmatter:
```yaml
# BEFORE
tools: Read, Grep, Glob, Edit, Write, Bash

# AFTER
tools: Read, Grep, Glob, Edit, Write, Bash, TaskCreate, TaskList, TaskUpdate, TaskGet
```

### 5. build-fixer-low.md

**Line 4** - YAML frontmatter:
```yaml
# BEFORE
tools: Read, Grep, Glob, Edit, Write, Bash

# AFTER
tools: Read, Grep, Glob, Edit, Write, Bash, TaskCreate, TaskList, TaskUpdate, TaskGet
```

### 6. tdd-guide.md

**Line 5** - YAML frontmatter:
```yaml
# BEFORE
tools: Read, Grep, Glob, Edit, Write, Bash

# AFTER
tools: Read, Grep, Glob, Edit, Write, Bash, TaskCreate, TaskList, TaskUpdate, TaskGet
```

### 7. tdd-guide-low.md

**Line 4** - YAML frontmatter:
```yaml
# BEFORE
tools: Read, Grep, Glob, Bash

# AFTER
tools: Read, Grep, Glob, Bash, TaskCreate, TaskList, TaskUpdate, TaskGet
```

## Re-Apply Patch Script

Run this after OMC plugin updates:

```powershell
# PowerShell script to re-apply Task tools patch
$agentsDir = "$env:USERPROFILE\.claude\plugins\cache\omc\oh-my-claudecode\*\agents"

# Find the actual version directory
$actualDir = Get-Item $agentsDir | Select-Object -First 1

if (-not $actualDir) {
    Write-Error "OMC agents directory not found"
    exit 1
}

Write-Host "Patching agents in: $($actualDir.FullName)"

# Patch executor files - replace TodoWrite with Task tools
$executorFiles = @("executor.md", "executor-low.md", "executor-high.md")
foreach ($file in $executorFiles) {
    $path = Join-Path $actualDir.FullName $file
    if (Test-Path $path) {
        $content = Get-Content $path -Raw
        $content = $content -replace 'tools: Read, Glob, Grep, Edit, Write, Bash, TodoWrite', 'tools: Read, Glob, Grep, Edit, Write, Bash, TaskCreate, TaskList, TaskUpdate, TaskGet'
        $content = $content -replace 'TodoWrite', 'TaskCreate'
        Set-Content $path $content -NoNewline
        Write-Host "  Patched: $file"
    }
}

# Patch build-fixer files - add Task tools
$buildFixerFiles = @("build-fixer.md", "build-fixer-low.md")
foreach ($file in $buildFixerFiles) {
    $path = Join-Path $actualDir.FullName $file
    if (Test-Path $path) {
        $content = Get-Content $path -Raw
        $content = $content -replace 'tools: Read, Grep, Glob, Edit, Write, Bash$', 'tools: Read, Grep, Glob, Edit, Write, Bash, TaskCreate, TaskList, TaskUpdate, TaskGet'
        Set-Content $path $content -NoNewline
        Write-Host "  Patched: $file"
    }
}

# Patch tdd-guide.md - add Task tools
$path = Join-Path $actualDir.FullName "tdd-guide.md"
if (Test-Path $path) {
    $content = Get-Content $path -Raw
    $content = $content -replace 'tools: Read, Grep, Glob, Edit, Write, Bash$', 'tools: Read, Grep, Glob, Edit, Write, Bash, TaskCreate, TaskList, TaskUpdate, TaskGet'
    Set-Content $path $content -NoNewline
    Write-Host "  Patched: tdd-guide.md"
}

# Patch tdd-guide-low.md - add Task tools (different base tools)
$path = Join-Path $actualDir.FullName "tdd-guide-low.md"
if (Test-Path $path) {
    $content = Get-Content $path -Raw
    $content = $content -replace 'tools: Read, Grep, Glob, Bash$', 'tools: Read, Grep, Glob, Bash, TaskCreate, TaskList, TaskUpdate, TaskGet'
    Set-Content $path $content -NoNewline
    Write-Host "  Patched: tdd-guide-low.md"
}

Write-Host "`nPatch complete. Restart Claude Code for changes to take effect."
```

Save as `cc_workflow/scripts/patch-omc-task-tools.ps1` and run after plugin updates.

## Bash Alternative

```bash
#!/bin/bash
# For Git Bash or WSL

AGENTS_DIR=~/.claude/plugins/cache/omc/oh-my-claudecode/*/agents

# Check if directory exists
if ! ls $AGENTS_DIR 2>/dev/null; then
    echo "OMC agents directory not found"
    exit 1
fi

cd $AGENTS_DIR

# Patch executor files
for file in executor.md executor-low.md executor-high.md; do
    if [ -f "$file" ]; then
        sed -i 's/tools: Read, Glob, Grep, Edit, Write, Bash, TodoWrite/tools: Read, Glob, Grep, Edit, Write, Bash, TaskCreate, TaskList, TaskUpdate, TaskGet/' "$file"
        sed -i 's/TodoWrite/TaskCreate/g' "$file"
        echo "Patched: $file"
    fi
done

# Patch build-fixer files
for file in build-fixer.md build-fixer-low.md; do
    if [ -f "$file" ]; then
        sed -i 's/tools: Read, Grep, Glob, Edit, Write, Bash$/tools: Read, Grep, Glob, Edit, Write, Bash, TaskCreate, TaskList, TaskUpdate, TaskGet/' "$file"
        echo "Patched: $file"
    fi
done

# Patch tdd-guide.md
if [ -f "tdd-guide.md" ]; then
    sed -i 's/tools: Read, Grep, Glob, Edit, Write, Bash$/tools: Read, Grep, Glob, Edit, Write, Bash, TaskCreate, TaskList, TaskUpdate, TaskGet/' tdd-guide.md
    echo "Patched: tdd-guide.md"
fi

# Patch tdd-guide-low.md (different base tools)
if [ -f "tdd-guide-low.md" ]; then
    sed -i 's/tools: Read, Grep, Glob, Bash$/tools: Read, Grep, Glob, Bash, TaskCreate, TaskList, TaskUpdate, TaskGet/' tdd-guide-low.md
    echo "Patched: tdd-guide-low.md"
fi

echo ""
echo "Patch complete. Restart Claude Code for changes to take effect."
```

## Verification

After patching and restarting Claude Code, test with:

```
Spawn oh-my-claudecode:executor-low with prompt:
"Test TaskList access. Report SUCCESS or FAILURE."
```

Expected: Agent reports SUCCESS and shows task list contents.

## Notes

- Changes require Claude Code restart (agent definitions loaded at startup)
- Patches will be overwritten by plugin updates (`/install omc`)
- Consider submitting upstream PR to OMC repo for permanent fix
- Only executor-type agents need Task tools for orchestration workflow

## Why These Files?

Claude Code reads agent definitions from `agents/*.md` files with YAML frontmatter:

```yaml
---
name: executor
description: ...
tools: Read, Glob, Grep, Edit, Write, Bash, TaskCreate, TaskList, TaskUpdate, TaskGet
model: sonnet
---
```

The `tools:` field directly controls which tools the subagent can access. The compiled `.js` files in `dist/agents/` are internal plugin code and do NOT control tool access.
