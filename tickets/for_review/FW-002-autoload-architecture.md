---
id: FW-002
title: "Create core autoload architecture"
epic: FOUNDATION
priority: high
estimated_complexity: medium
dependencies: [FW-001]
created: 2026-01-07
completed: 2026-01-07
---

## Description

Establish the autoload singleton pattern for core game managers. These autoloads will be the backbone of the game's architecture, handling state, events, and cross-system communication.

## Acceptance Criteria

- [x] GameManager autoload created - central game state machine
- [x] EventBus autoload created - global signal hub for decoupled communication
- [x] All autoloads registered in project.godot
- [x] Autoloads follow GODOT_REFERENCE.md patterns (no class_name, extend Node)
- [x] Basic signals defined on EventBus for core events
- [x] Unit tests for autoload initialization

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

---

## Implementation Notes

### Files Created

| File | Purpose |
|------|---------|
| `src/core/managers/game_manager.gd` | Central game state machine with 7 states |
| `src/core/managers/event_bus.gd` | Global signal hub with 13 signals |
| `tests/test_game_manager.gd` | 15 unit tests for GameManager |
| `tests/test_event_bus.gd` | 13 unit tests for EventBus |

### GameManager States

```
NONE -> LOBBY -> SETUP -> INVESTIGATION <-> HUNT -> RESULTS
                              |                       |
                              v                       |
                        DELIBERATION -----------------+
```

- **NONE**: Initial state, no game active
- **LOBBY**: Players gathering, waiting to start
- **SETUP**: Match initializing, roles being assigned
- **INVESTIGATION**: Main gameplay - players investigating
- **HUNT**: Entity is actively hunting players
- **DELIBERATION**: Players discussing and voting
- **RESULTS**: Match ended, showing results

State transitions are validated. Use `force_state()` for testing/error recovery only.

### EventBus Signals

**Game State:**
- `game_state_changed(old_state: int, new_state: int)`

**Player:**
- `player_joined(player_id: int)`
- `player_left(player_id: int)`
- `player_died(player_id: int)`
- `player_became_echo(player_id: int)`

**Evidence:**
- `evidence_detected(evidence_type: String, location: Vector3, strength: float)`
- `evidence_recorded(evidence_type: String, equipment_type: String)`

**Entity:**
- `hunt_started()`
- `hunt_ended()`
- `entity_tell_triggered(tell_type: String)`

**Cultist:**
- `cultist_ability_used(ability_type: String)`
- `evidence_contaminated(evidence_type: String)`

**Match Flow:**
- `deliberation_started()`
- `vote_cast(voter_id: int, target_id: int)`
- `match_ended(result: String)`

### Autoload Order in project.godot

```ini
SteamManager="*res://src/core/steam_manager.gd"
NetworkManager="*res://src/core/network_manager.gd"
EventBus="*res://src/core/managers/event_bus.gd"
GameManager="*res://src/core/managers/game_manager.gd"
```

EventBus must load before GameManager since GameManager emits signals through EventBus.

### Testing

```bash
# Run all tests (30 tests, all passing)
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/

# Test results: 30/30 passed, 45 asserts, 0.032s
```
