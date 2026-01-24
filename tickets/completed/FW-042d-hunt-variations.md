---
id: FW-042d
title: "Entity-specific hunt variations"
epic: ENTITY
priority: high
estimated_complexity: medium
dependencies: [FW-042b, FW-042c]
created: 2026-01-09
updated: 2026-01-09
parent_ticket: FW-042
---

## Description

Create the framework for entity-specific hunt behaviors. Each entity type should have distinct hunt characteristics that affect sanity thresholds, detection, speed, duration, and special conditions.

## Acceptance Criteria

- [x] Entity-specific sanity thresholds (Demon: 70%, Shade: 35%)
- [x] Banshee ignores team sanity, only checks target's sanity
- [x] Listener bypasses sanity threshold if voice-triggered
- [x] Speed variations framework (Revenant: 1 m/s → 3 m/s when chasing)
- [x] Duration variations (base 20-40s, scales with map)
- [x] Special hunt conditions (Mare: can't hunt in lit rooms)
- [x] Hunt cooldown variations (Demon: 20s instead of 25s)

## Technical Notes

**Implementation**: Virtual methods in Entity.gd that subclasses override

**Entity Virtual Methods**:
```gdscript
# Sanity threshold
func get_hunt_sanity_threshold() -> float:
    return hunt_sanity_threshold  # Default 50.0

func should_ignore_team_sanity() -> bool:
    return false  # Banshee: true

func can_voice_trigger_hunt() -> bool:
    return false  # Listener: true

# Speed
func get_hunt_speed_for_awareness(aware: bool) -> float:
    return hunt_aware_speed if aware else hunt_unaware_speed

func _update_hunt_speed(delta: float) -> void:
    pass  # Revenant: accelerate over time

# Conditions
func can_hunt_in_current_conditions() -> bool:
    return true  # Mare: check room lighting

func can_ignore_hiding_spots() -> bool:
    return false  # Some entities: true
```

**Entity-Specific Values Table**:
| Entity | Threshold | Cooldown | Speed | Special |
|--------|-----------|----------|-------|---------|
| Standard | 50% | 25s | 2.5 m/s | - |
| Demon | 70% | 20s | 2.5 m/s | Hunts early/often |
| Shade | 35% | 25s | 2.5 m/s | Very reluctant |
| Banshee | Target 50% | 25s | 2.0→3.0 m/s | Single target, ignores team |
| Mare | 50% | 25s | 2.5 m/s | No hunt in lit rooms |
| Revenant | 50% | 25s | 1.0→3.0 m/s | Accelerates when chasing |
| Listener | Any/Voice | 25s | 2.5 m/s | Voice triggers hunt |

**EntityManager Integration**:
- Check entity's `can_hunt_in_current_conditions()` before hunt
- Use entity's `get_hunt_sanity_threshold()` for threshold check
- Support voice-triggered hunts from FW-014 (Voice Chat)

## Out of Scope

- Actual entity implementations (FW-044, FW-046, etc.)
- Voice chat system integration details (FW-014)
- Room lighting system (needed for Mare)

## Implementation Notes

### Changes Made

**Modified `src/entity/entity.gd`:**
- Added "Hunt Variation Virtual Methods" section with 8 new virtual methods:
  - `get_hunt_sanity_threshold()` - Returns sanity threshold for hunt initiation
  - `should_ignore_team_sanity()` - Returns true if entity ignores team sanity (Banshee)
  - `can_voice_trigger_hunt()` - Returns true if voice can trigger hunt (Listener)
  - `get_hunt_speed_for_awareness(aware: bool)` - Returns speed based on awareness
  - `_update_hunt_speed(delta: float)` - Called each frame for dynamic speed (Revenant)
  - `can_hunt_in_current_conditions()` - Returns true if environmental conditions allow hunt (Mare)
  - `get_hunt_duration()` - Returns hunt duration in seconds
  - `get_hunt_cooldown()` - Returns hunt cooldown in seconds (uses 25.0 * multiplier)
- Updated `get_current_speed()` to use `get_hunt_speed_for_awareness()`
- Updated `on_hunt_started()` to use `get_hunt_duration()`
- Added `_update_hunt_speed(delta)` call in `_process_hunting()` for dynamic speed updates
- Note: `can_ignore_hiding_spots()` was already implemented in FW-042c

**Modified `tests/test_entity.gd`:**
- Added 22 new tests for hunt variation virtual methods
- Added `CustomEntity` test class demonstrating subclass override patterns
- Total entity tests: 73 (up from 51)

### Test Commands

```bash
# Run entity tests
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=test_entity.gd -gexit

# Run full test suite
$GODOT --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gprefix=test_ -gsuffix=.gd -gexit
```

### Evidence of Success

- All 73 entity tests pass
- All tests in full suite pass
- Lint passes on modified files

### How to Use (for Entity Subclasses)

```gdscript
class_name DemonEntity
extends Entity

func get_hunt_sanity_threshold() -> float:
    return 70.0  # Demon hunts at 70% sanity

func get_hunt_cooldown() -> float:
    return 20.0  # Demon has 20s cooldown (vs 25s standard)
```

```gdscript
class_name RevenantEntity
extends Entity

var _current_hunt_speed: float = 1.0

func get_hunt_speed_for_awareness(aware: bool) -> float:
    return _current_hunt_speed  # Use dynamic speed

func _update_hunt_speed(delta: float) -> void:
    if _is_aware_of_target:
        _current_hunt_speed = minf(_current_hunt_speed + delta * 0.5, 3.0)
    else:
        _current_hunt_speed = maxf(_current_hunt_speed - delta * 1.0, 1.0)
```
