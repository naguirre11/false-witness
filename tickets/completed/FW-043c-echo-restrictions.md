---
id: FW-043c
title: "Echo restrictions and entity reactions"
epic: FW-043
priority: high
estimated_complexity: small
dependencies: [FW-043b]
created: 2026-01-09
---

## Description

Implement the restrictions that apply to Echoes and the subtle ways the entity can react to Echo presence. Echoes cannot interact with the physical world but the entity occasionally acknowledges them.

## Acceptance Criteria

### Echo Restrictions
- [x] Echoes cannot use equipment (equipment UI disabled/hidden)
- [x] Echoes cannot collect evidence
- [x] Echoes cannot interact with physical objects (doors, switches, etc.)
- [x] Echoes cannot use Cultist abilities (if they were a Cultist before death)
- [x] Echoes cannot be targeted by entity during hunts

### Entity Reactions to Echoes
- [x] Entity occasionally "reacts" to Echo presence (cosmetic only)
- [x] Reaction types: head turns toward Echo, brief pause in movement
- [x] Reactions are random and infrequent (not reliable tells)
- [x] Reactions do not affect entity behavior or hunt mechanics

## Technical Notes

- Restrictions are enforced by checking `is_echo()` state before allowing actions
- Entity reactions are cosmetic/visual only - no gameplay impact
- Consider using a timer for random reaction checks

### Restriction Implementation

```gdscript
func can_use_equipment() -> bool:
    return not is_echo()

func can_interact() -> bool:
    return not is_echo()

func can_use_cultist_abilities() -> bool:
    return not is_echo() and is_cultist()
```

### Entity Reaction System

```gdscript
# In Entity class
var _echo_reaction_cooldown := 0.0
const ECHO_REACTION_INTERVAL := 30.0  # Check every 30 seconds
const ECHO_REACTION_CHANCE := 0.2  # 20% chance to react

func _process_echo_reactions(delta: float) -> void:
    _echo_reaction_cooldown -= delta
    if _echo_reaction_cooldown <= 0:
        _echo_reaction_cooldown = ECHO_REACTION_INTERVAL
        if randf() < ECHO_REACTION_CHANCE:
            _perform_echo_reaction()

func _perform_echo_reaction() -> void:
    # Look toward nearest Echo, pause briefly
    pass
```

## Out of Scope

- Death trigger (FW-043a)
- Echo movement (FW-043b)
- Revival mechanic (FW-043d)

## Implementation Notes

### Changes Made

**EchoController (`src/player/echo_controller.gd`)**
- Added restriction methods: `can_use_equipment()`, `can_interact()`, `can_collect_evidence()`, `can_use_cultist_abilities()` - all return `false`
- Added `is_valid_hunt_target()` returning `false` - entity ignores Echoes during hunts

**Entity (`src/entity/entity.gd`)**
- Added Echo reaction constants: `ECHO_REACTION_INTERVAL` (30s), `ECHO_REACTION_CHANCE` (20%), `ECHO_REACTION_DURATION` (2s), `ECHO_REACTION_RANGE` (15m)
- Added `echo_reaction_triggered` signal
- Added Echo reaction state variables: `_echo_reaction_cooldown`, `_is_reacting_to_echo`, `_echo_reaction_timer`, `_reaction_target_echo`
- Implemented `_process_echo_reactions()` - periodic check with random chance
- Implemented `_find_nearest_echo()` - finds closest Echo in "echoes" group within range
- Implemented `_start_echo_reaction()`, `_process_echo_reaction_animation()`, `_end_echo_reaction()` - head turn and pause
- Entity pauses movement during reaction (in `_process_active()`)
- Entity does NOT react during hunts (in `_physics_process()`)
- Added hunt target filtering: `_filter_valid_hunt_targets()`, `_is_valid_hunt_target()` - excludes Echoes and dead players

**Tests**
- `test_echo_controller.gd`: 5 new tests for restriction methods
- `test_entity.gd`: 12 new tests for Echo reactions and hunt target filtering
- Added `MockPlayer` inner class for proper property testing

### Test Commands

```powershell
# Run all tests
$GODOT --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gprefix=test_ -gsuffix=.gd -gexit

# Run specific test files
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_echo_controller.gd -gexit
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_entity.gd -gexit
```

### Test Evidence

```
Tests             1531
  Passing         1531
Time              52.434s
---- All tests passed! ----
```
