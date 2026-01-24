# Ralph Agent Instructions

You are an autonomous coding agent working on **False Witness** - a social deduction multiplayer FPS game built in Godot 4.4.

## Project Context

**Repository**: `C:\Users\vinco\Projects\false_witness`
**Stack**:
- Engine: Godot 4.4 + GDScript
- Networking: GodotSteam (Steam P2P)
- Testing: GUT framework
- Linting: gdtoolkit (gdlint + gdformat)

**Key Directories**:
- `src/` - GDScript source files (autoloads, managers, systems)
- `scenes/` - Godot scene files (.tscn)
- `tests/` - GUT test files (unit/ and integration/)
- `assets/` - Game assets (textures, sounds, models)
- `tickets/` - Ticket-based workflow
- `handoffs/` - Session context

## Ralph State Files

All Ralph state files are located at: `cc_workflow/scripts/ralph/`
- **PRD**: `cc_workflow/scripts/ralph/prd.json`
- **Progress**: `cc_workflow/scripts/ralph/progress.txt`

## Your Task

1. **Read the PRD** at `cc_workflow/scripts/ralph/prd.json`
2. **CRITICAL: Learn from previous iterations** - Read `cc_workflow/scripts/ralph/progress.txt`:
   - **START with the "Codebase Patterns" section at the top** - This is consolidated wisdom
   - Read the most recent iteration entries (last 3-5 entries)
   - Pay special attention to "Mistakes made" sections - don't repeat them!
   - Note any "Gotchas" relevant to your current story
   - Check if previous iteration left "What to do next" items for you
3. **Review git history** - Run `git log --oneline -10` to see recent commits
   - If picking up a partial story, read the commit message and diff
   - Use `git show [commit-hash]` to see what the previous iteration did
4. **Check branch** - Verify you're on the correct branch from PRD `branchName`
5. **Pick the highest priority story** where `passes: false`
   - If a story is marked "Partial", continue from where it left off
   - Read that story's progress entry for context
6. **Implement the story** following patterns learned from `cc_workflow/scripts/ralph/progress.txt`
7. **Run quality checks** (typecheck, lint, browser testing for UI changes)
8. **Commit if passing** with message: `feat: [Story ID] - [Story Title]`
9. **Update PRD** (`cc_workflow/scripts/ralph/prd.json`) to set `passes: true` for completed story
10. **CRITICAL: Document learnings** in `cc_workflow/scripts/ralph/progress.txt` (see format below)
    - Include commit hash so future iterations can reference your work
    - Be detailed about patterns, gotchas, and mistakes
    - Think: "What would I want to know if I had to continue this work fresh?"

## IMPORTANT: Context Management

You are running in Claude Code CLI which does NOT have automatic handoff like Amp CLI. If you notice you're running low on context:

1. **Commit what you have** - Even partial progress is valuable
2. **Mark story as incomplete** - Leave `passes: false`
3. **Document clearly** - In `cc_workflow/scripts/ralph/progress.txt`, note exactly what's left to do
4. **Exit gracefully** - The next iteration will continue from your commit

If a story is too large to complete in one context window, note this in `cc_workflow/scripts/ralph/progress.txt` and suggest splitting it into smaller stories.

## Progress Report Format

APPEND to `cc_workflow/scripts/ralph/progress.txt` (never replace, always append):
```
## [Date/Time] - [Story ID] - [Story Title]
**Iteration**: [X]
**Commit**: [git commit hash - use `git log -1 --format=%H`]
**Status**: [Complete/Partial/Blocked]

### What was implemented
- [Detailed description of changes]
- [Be specific about what works]

### Files changed
- path/to/file1.tsx (+45, -10)
- path/to/file2.ts (+20, -5)

### Quality checks
- ✅ Type check: passed
- ✅ Linting: passed
- ✅ Browser verification: [verified on X page / not applicable for backend change]
- ❌ [Any failures]

### **Learnings for future iterations** ⚠️ CRITICAL
**Patterns discovered:**
- [e.g., "This codebase uses DataTable for all table displays"]

**Gotchas encountered:**
- [e.g., "Must run linter before type check or it fails"]

**Dependencies found:**
- [e.g., "Changing page X requires updating layout breadcrumbs"]

**What to do next** (if incomplete):
- [ ] Specific next step

**Mistakes made** (learn from these!):
- [e.g., "Initially tried wrong approach, needed to use pattern X"]

---
```

## Quality Requirements - FALSE WITNESS SPECIFIC

Before committing, run these checks in order:

### Godot Import (after adding new files)
```bash
$GODOT --headless --import
```

### Linting
```bash
# Lint GDScript files
gdlint src/ scenes/ tests/

# Check formatting
gdformat --check src/ scenes/ tests/

# Auto-format (if needed)
gdformat src/ scenes/ tests/
```

### Testing
```bash
# Smoke tests (quick sanity check, run before commits)
./cc_workflow/scripts/run-tests.ps1 -Mode smoke

# Specific test file during development
./cc_workflow/scripts/run-tests.ps1 -Mode file -File test_example.gd

# Full test suite (before moving ticket to for_review)
./cc_workflow/scripts/run-tests.ps1 -Mode full

# Raw GUT command (alternative)
$GODOT --headless -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json -gexit
```

### Quick Quality Check Commands
```bash
# Import + lint (most common check)
$GODOT --headless --import && gdlint src/ scenes/

# Smoke tests
./cc_workflow/scripts/run-tests.ps1 -Mode smoke

# Full validation
$GODOT --headless --import && gdlint src/ scenes/ tests/ && ./cc_workflow/scripts/run-tests.ps1 -Mode full
```

**Commit Checklist:**
- ✅ `$GODOT --headless --import` succeeds
- ✅ `gdlint src/ scenes/` passes
- ✅ Smoke tests pass (`run-tests.ps1 -Mode smoke`)
- ✅ Code follows existing patterns
- ✅ Do NOT commit broken code

## False Witness Patterns

### Godot/GDScript Patterns
- **Node for scene tree objects**: Autoloads, managers, anything needing signals
- **Resource for pure data**: Serializable configs, data containers
- **NEVER use RefCounted**: Anti-pattern that breaks type safety
- Autoloads MUST extend Node and MUST NOT use `class_name`
- Use `load()` instead of `preload()` to break circular dependencies
- All signals defined at class level, emitted via EventBus for cross-system communication

### Class Member Order (enforced by gdlint)
```gdscript
# 1. class_name / extends
class_name MyClass
extends Control

# 2. Signals
signal something_happened

# 3. Constants
const MAX_VALUE := 100

# 4. Exported variables
@export var speed: float = 1.0

# 5. Regular variables (STATE)
var _counter: int = 0

# 6. @onready variables (NODE REFERENCES) - MUST come after regular vars
@onready var _label: Label = %MyLabel

# 7. Functions
func _ready() -> void:
    pass
```

### File Locations
```
src/
├── core/managers/       # Autoloads (GameManager, EventBus, LobbyManager)
├── entity/              # Entity-related systems (behaviors, AI)
├── evidence/            # Evidence collection and management
├── equipment/           # Equipment types and handling
├── player/              # Player controller and components
└── ui/                  # UI scripts (menus, HUD, dialogs)

scenes/
├── ui/                  # UI scenes (.tscn)
├── player/              # Player scenes
├── entity/              # Entity scenes
└── levels/              # Level/map scenes

tests/
├── unit/                # Fast unit tests (enums, static methods)
├── integration/         # Integration tests (managers, signals)
└── test_smoke.gd        # Critical sanity checks
```

### Key Autoloads
- `GameManager` - Game state machine, phase transitions
- `EventBus` - Global signal hub for cross-system events
- `LobbyManager` - Steam lobby management, player sync
- `EvidenceManager` - Evidence collection, board state
- `EquipmentManager` - Player loadouts, equipment state

### Git Conventions
- Conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`
- Include ticket ID if applicable: `feat: implement lobby UI (FW-081)`
- **NO** "Generated with Claude Code" or Co-Authored-By lines
- **NEVER** use `--force` or `--no-verify` without explicit permission

### Windows Environment Notes
- Shell: PowerShell (Unix commands available via aliases)
- Godot executable: `$GODOT` environment variable
- Use forward slashes in bash/git commands: `cd C:/Users/vinco/Projects/false_witness`
- Use backslashes for Claude Code Edit/Write tools: `C:\Users\vinco\Projects\false_witness`
- Environment variables: `$env:VARNAME` (not `%VARNAME%`)

## Stop Condition

After completing a user story, check if ALL stories have `passes: true`.

If ALL stories are complete and passing, reply with:
<promise>COMPLETE</promise>

If there are still stories with `passes: false`, end your response normally (another iteration will pick up the next story).

## Important Rules

- Work on **ONE story per iteration**
- Commit frequently (even mid-story if needed for large changes)
- Keep builds green - never commit code that breaks build/lint
- Read the Codebase Patterns section in `cc_workflow/scripts/ralph/progress.txt` before starting
- Monitor context usage - if doing extensive file reads, you may be approaching limits

## Signs You're Running Low on Context

If you notice any of these, commit and exit gracefully:
- You've read more than 20-30 files
- You're doing extensive searching/exploration
- The story requires changes across many files (>10)
- You're refactoring large sections of code

In these cases: commit partial progress, document what's left in `cc_workflow/scripts/ralph/progress.txt`, and let the next iteration continue.
