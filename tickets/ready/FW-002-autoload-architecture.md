---
id: FW-002
title: "Create core autoload architecture"
epic: FOUNDATION
priority: high
estimated_complexity: medium
dependencies: [FW-001]
created: 2026-01-07
---

## Description

Establish the autoload singleton pattern for core game managers. These autoloads will be the backbone of the game's architecture, handling state, events, and cross-system communication.

## Acceptance Criteria

- [ ] GameManager autoload created - central game state machine
- [ ] EventBus autoload created - global signal hub for decoupled communication
- [ ] All autoloads registered in project.godot
- [ ] Autoloads follow GODOT_REFERENCE.md patterns (no class_name, extend Node)
- [ ] Basic signals defined on EventBus for core events
- [ ] Unit tests for autoload initialization

## Technical Notes

Autoload structure:
```
src/core/
  managers/
    GameManager.gd      # Game state machine, match lifecycle
    EventBus.gd         # Global signal bus
```

EventBus initial signals:
- `game_state_changed(old_state, new_state)`
- `player_joined(player_id)`
- `player_left(player_id)`

## Out of Scope

- Networking-specific managers (separate epic)
- Evidence/Entity managers (separate epics)
