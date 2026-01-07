# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

False Witness is a Godot 4.4 game project. The Game Design Document is located at `docs/False_Witness_GDD.docx`.

## Development Commands

This project uses custom Claude commands defined in `COMMANDS.md`:

| Command | Alias | Purpose |
|---------|-------|---------|
| `%init` | `%i` | Read core docs and latest handoff, pick up next ticket from `/ready` |
| `%init -b` | `%i -b` | Bug fix mode - wait for user to supply specific work |
| `%handoff` | `%h` | Create handoff document for next Claude instance |
| `%git` | `%g` | Commit and push to remote (use `-f` for `--no-verify`) |
| `%tickets` | `%t` | Full workflow: init -> work -> handoff -> eval -> git |
| `%newtickets` | `%n` | Evaluate project state, create new tickets, update prioritization |
| `%eval` | `%e` | Update PROJECT_STRUCTURE.md with session changes |
| `%describe` | `%d` | Update PROJECT_STATE.md with current project analysis |

Shorthand markers (from `SHORTHAND.md`):
- `^future` / `^f`: Document something for future Claude instances
- `^wrong` / `^w`: Something went wrong, investigate the implementation

## Ticket System

Tickets are managed in `tickets/` with the following workflow:
- `tickets/draft/` - Tickets being written
- `tickets/ready/` - Tickets ready to be worked on
- `tickets/dev_in_progress/` - Currently active ticket (only ONE at a time)
- `tickets/for_review/` - Completed work awaiting review
- `tickets/completed/` - Finished tickets

Prioritization is tracked in `tickets/PRIORITIZATION.md`.

## Godot 4.4 Technical Requirements

See `GODOT_REFERENCE.md` for comprehensive Godot patterns. Critical rules:

### Class Hierarchy
- **Node** (or descendants): For anything needing scene tree access, autoloads, managers
- **Resource**: For pure data classes, serializable configs
- **NEVER use RefCounted**: Anti-pattern that breaks type safety

### Autoload Rules
- Autoloads MUST extend Node
- NEVER use `class_name` in autoloaded scripts (conflicts with singleton name)
- Access from Resource classes via `Engine.get_main_loop() as SceneTree`

### Circular Dependency Prevention
- Use `load()` instead of `preload()` to break compile-time cycles
- Use `load("res://path/to/MyClass.gd").new()` in static methods (never `MyClass.new()`)
- Autoloads break circular dependency chains automatically

### Reserved Names
Avoid using these as function names: `assert`, `print`, `str`, `to_string`, `duplicate`

## Build Commands

Godot executable is located at `../tooling/Godot_v4.4.1-stable_win64_console.exe` (relative to project root).

```bash
# Set alias for convenience (optional)
GODOT="../tooling/Godot_v4.4.1-stable_win64_console.exe"

# Import/reimport project (run this after adding new scripts)
$GODOT --headless --import

# Run GUT tests
$GODOT --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gprefix=test_ -gsuffix=.gd -gexit

# Run specific test file
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=test_example.gd -gexit
```
## Code Quality

GDScript linting and formatting is handled by [gdtoolkit](https://github.com/Scony/godot-gdscript-toolkit).

```bash
# Install (one-time)
pip install gdtoolkit

# Lint GDScript files
gdlint src/ tests/

# Check formatting (no changes)
gdformat --check src/ tests/

# Auto-format files
gdformat src/ tests/

# Run all checks (lint + format check)
./scripts/lint.sh

# Run all checks and auto-fix formatting
./scripts/lint.sh --fix

# Install git pre-commit hook (optional)
./scripts/install-hooks.sh
```

Configuration files:
- `gdlintrc` - Linting rules (max line length: 100, tabs)
- `gdformatrc` - Formatting rules (matches lint config)

### Linting Guidelines

**Line length**: Max 100 characters. For long `@onready` node paths, use unique names:

```gdscript
# BAD - exceeds 100 chars
@onready var _btn: Button = $MainPanel/VBox/ContentArea/AudioContent/MasterRow/MasterSlider

# GOOD - use unique name (requires unique_name_in_owner = true in .tscn)
@onready var _btn: Button = %MasterSlider
```

**Class member order** (enforced by `class-definitions-order`):

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

**Common pitfalls**:
- Don't put `var` declarations after `@onready` declarations
- Avoid deeply nested node paths - use `%UniqueNodeName` pattern instead
- Run `gdlint` before committing to catch issues early

## GDScript Gotchas

> **Important**: For comprehensive Godot 4.4 patterns, anti-patterns, and debugging guides, see [`GODOT_REFERENCE.md`](./GODOT_REFERENCE.md). This includes critical information about RefCounted anti-patterns, circular dependencies, autoload quirks, and type safety patterns.

### Lambda Closure Capture

GDScript 4 lambdas capture primitives (`bool`, `int`, `float`, `String`) **by value**, not reference. This causes subtle bugs in signal testing:

```gdscript
# WRONG - bool captures by value, modification doesn't propagate
var signal_received := false
some_signal.connect(func(_args): signal_received = true)
emit_signal()
assert_that(signal_received).is_true()  # FAILS - still false!

# CORRECT - Dictionary captures by reference
var state := {"received": false}
some_signal.connect(func(_args): state["received"] = true)
emit_signal()
assert_that(state["received"]).is_true()  # PASSES
```

### Type Inference with Method Returns

Using `:=` type inference with methods returning primitives can cause parse errors:

```gdscript
var valid := some_object.is_valid()   # Parse Error: Cannot infer type
var valid: bool = some_object.is_valid()  # Works
```

**Rule**: Use explicit type annotations when calling methods that return primitives.

### Function-Scope Variable Naming

The linter forbids underscore-prefixed names for function-scope variables (unlike class members):

```gdscript
var _result := do_something()  # Lint error: name "_result" is not valid
var result := do_something()   # OK
```

If you don't need a return value, omit the assignment entirely.

## Architecture

### Template Decision (2026-01-07)

**Chosen approach**: GodotSteam Template base + custom systems

After evaluating available templates (see `docs/False_Witness_GDD.md` Section 17), we decided:

1. **Base**: [GodotSteam Template](https://github.com/wahan-h/GodotSteam-Template) for Steam lobby/P2P networking
2. **FPS Controller**: Build custom, referencing [Quality First Person Controller v2](https://godotengine.org/asset-library/asset/2418)
3. **Interaction/Inventory**: Build custom, referencing [Cogito](https://github.com/Phazorknight/Cogito) patterns
4. **Evidence/Cultist systems**: Built from scratch (no existing template covers social deduction)

**Why not Cogito directly?** Cogito is single-player focused. The community multiplayer fork (cogito-arcana) has 34 open issues and is experimental. Retrofitting multiplayer into Cogito's architecture would be more work than building systems designed for multiplayer from the start.

**Why GodotSteam?** Steam provides NAT hole-punching with relay fallback, lobby management, and voice chat infrastructure. GodotSteam integrates with Godot's high-level MultiplayerPeer for clean RPC patterns.

### Networking Architecture

- **Transport**: Steam P2P via GodotSteam
- **Topology**: Host-based (one player hosts, others join via Steam lobby)
- **Sync strategy**: Server-authoritative for game state, client-predicted for movement
- **Voice**: Steam voice chat (proximity-based in-game)

### Core Systems

## Repository Structure

- `docs/` - Project planning documents
- `tickets/` - Development tickets organized by status (draft, ready, dev_in_progress, for_review, completed)
- `cc_workflow/` - Claude Code workflow configuration (hooks, scripts)
- `handoffs/` - Session handoffs to manage Claude Code context limits

### Quick Context Files

Two files provide fast context for new sessions:

| File | Purpose | When to Read |
|------|---------|--------------|
| [`PROJECT_STATE.md`](./PROJECT_STATE.md) | Current milestone status, completed work, what's remaining | Start of session to understand where things stand |
| [`PROJECT_STRUCTURE.md`](./PROJECT_STRUCTURE.md) | Folder structure, file purposes, autoloads, scene hierarchy | When navigating unfamiliar code or adding new files |

**Usage**:
- Read `PROJECT_STATE.md` first to understand what's done vs. in-progress
- Reference `PROJECT_STRUCTURE.md` when you need to find specific systems or understand how components connect
- These files complement handoffs - handoffs have session-specific detail, these have project-wide context

## Game Rules Summary


## Design Philosophy



## Core Development Principles

### Single-Agent with Structured Thinking

Before implementing any feature:

1. **Analyze** - Identify requirements, edge cases, and dependencies
2. **Plan** - Outline implementation approach with specific steps
3. **Implement** - Execute step by step, testing incrementally
4. **Document** - Update handoffs and mark tickets appropriately

**Do not skip the analysis and planning phases.** The quality of implementation directly correlates with upfront thinking.

---

## Workflow: Ticket System

### Directory Structure

```
tickets/
├── PRIORITIZATION.md # Ordered queue of next tickets - UPDATE THIS
├── ready/           # Tickets ready to be worked on
├── dev_in_progress/ # Tickets actively being worked on
├── for_review/      # Completed work awaiting review
├── draft/     # Tickets being drafted
└── completed/       # Archived completed tickets

handoffs/
├── session_summaries/   # End-of-session context dumps
├── feature_contexts/    # Living docs for complex features
└── blockers/            # Known issues requiring human input
```

### Ticket Format

Tickets are Markdown files with YAML frontmatter:

```markdown
---
id: CB-001
title: "Implement embeddings connections"
priority: high | medium | low
estimated_complexity: small | medium | large
dependencies: []  # List of ticket IDs that must be completed first
created: 2026-01-05
---

## Description
[Clear description of what needs to be built]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Technical Notes
[Any implementation hints, relevant file paths, or architectural decisions]

## Out of Scope
[Explicitly what this ticket does NOT include]
```

### Ticket Lifecycle

1. **Check `PRIORITIZATION.md`** - Pick the ticket marked as NEXT (or highest unblocked)
2. **Move to `in_progress/`** (only ONE ticket at a time)
3. **Create/update handoff document** in `handoffs/feature_contexts/` if complex
4. **Implement** following the structured thinking phases
5. **Move to `for_review/`** when acceptance criteria are met
6. **Add implementation notes** to the ticket documenting what was done. Provide testing scripts and evidence of success. NEVER try to hack tests or acceptance criteria.
7. **Update `PRIORITIZATION.md`** - Mark completed, set new NEXT, update dependency status
8. **Commit and push** all changes to git with a descriptive commit message (see Git Conventions below)
9. Human reviews and moves to `completed/` or back to `ready/` with feedback

---

## Git Conventions

- **No Claude references**: Commit messages must NOT include Claude branding, "Generated with Claude Code", or Co-Authored-By lines referencing Claude/Anthropic
- Write commit messages as if authored by the repository owner
- Use conventional commit style: `type: description` (e.g., `feat: add embedding loader`, `fix: resolve null reference in AI pipeline`)

---

## Workflow: Handoff Documentation

### Purpose

Handoffs preserve context between Claude Code sessions. A new instance should be able to pick up work with minimal ramp-up time.

### Session Summary (Required at End of Each Session)

Create/update `handoffs/session_summaries/YYYY-MM-DD-HH.md`:

```markdown
---
session_date: 2025-01-15T14:30:00Z
tickets_worked: [CB-001, CB-002]
status: completed | paused | blocked
---

## Summary
[2-3 sentence overview of what was accomplished]

## Changes Made
- `path/to/file.py`: [Brief description of changes]
- `path/to/other.py`: [Brief description of changes]

## Current State
[Where things stand right now - what's working, what's not]

## Next Steps
[Explicit list of what the next session should tackle]

## Open Questions / Decisions Needed
[Any ambiguities that need human input]
