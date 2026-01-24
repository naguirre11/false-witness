---
id: FW-042a
title: "Hunt warning phase implementation"
epic: ENTITY
priority: high
estimated_complexity: small
dependencies: [FW-041]
created: 2026-01-09
updated: 2026-01-09
parent_ticket: FW-042
---

## Description

Implement the 3-second warning phase before hunts begin. This gives players a brief window to prepare, hide, or use protection items. The warning phase creates tension and allows skilled players to recognize the signs.

## Acceptance Criteria

- [x] Warning phase lasts 3 seconds before hunt begins
- [x] Lights flicker during warning phase (emit signal for lighting system)
- [x] Equipment interference signal emitted (for equipment static effects)
- [x] Entity vocalization signal emitted (for audio system)
- [x] Hunt cannot be prevented after warning phase ends (only during)
- [x] Warning phase can be skipped if entity is already at player (ambush)

## Technical Notes

**Implementation Location**: EntityManager.gd

**Signals to add/use**:
- `hunt_warning_started(entity_position: Vector3, duration: float)` - New signal
- `hunt_warning_ended()` - New signal
- Existing `hunt_starting` - Emitted during warning for prevention window
- Existing `hunt_started` - Emitted when warning ends

**Warning Phase Flow**:
1. EntityManager calls `attempt_hunt()` → emits `hunt_warning_started`
2. 3-second timer runs, `hunt_starting` emitted at start for Crucifix to prevent
3. If hunt not prevented, `hunt_warning_ended` + `hunt_started` emitted
4. If prevented, `hunt_prevented` emitted, warning cancelled

**Effects** (handled by other systems listening to signals):
- Lighting system: flicker lights in building/nearby rooms
- Equipment: add static/interference to active equipment
- Audio: play entity vocalization (growl, whisper, etc.)

## Out of Scope

- Actual lighting flicker implementation (that's the lighting system's job)
- Equipment static effects (equipment system handles that)
- Audio playback (audio system handles that)
- Detection mechanics (FW-042b)

## Implementation Notes

### Changes Made

**EventBus** (`src/core/managers/event_bus.gd`):
- Added `hunt_warning_started(entity_position: Vector3, duration: float)` signal
- Added `hunt_warning_ended(hunt_proceeding: bool)` signal

**EntityManager** (`src/entity/entity_manager.gd`):
- Added `WARNING_PHASE_DURATION = 3.0` constant
- Added warning phase state tracking (`_in_warning_phase`, `_warning_timer`, `_warning_entity_position`)
- Modified `attempt_hunt()` to start warning phase instead of immediate hunt
- Added `attempt_immediate_hunt()` for ambush scenarios (skips warning phase)
- Added `is_in_warning_phase()` and `get_warning_time_remaining()` public methods
- Added `_update_warning_phase()`, `_start_warning_phase()`, `_end_warning_phase()` internal methods
- Modified `can_initiate_hunt()` to return false during warning phase
- Modified `_update_hunt_cooldown()` to pause during warning phase
- Updated `reset()` to clear warning phase state

**Tests** (`tests/test_entity_manager.gd`):
- Added 7 new tests for warning phase functionality
- Total: 28 tests passing for EntityManager

### Test Commands

```bash
# Run EntityManager tests
$GODOT --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gprefix=test_ -gsuffix=.gd -gexit

# Lint check
gdlint src/entity/entity_manager.gd src/core/managers/event_bus.gd
```

### Signal Flow Diagram

```
attempt_hunt(position)
    │
    ▼
_start_warning_phase()
    │
    ├─► hunt_warning_started(position, 3.0)
    │
    ├─► hunt_starting(position, entity)  ─► Crucifix can prevent
    │
    ▼
[3 seconds elapse in _update_warning_phase()]
    │
    ▼
_end_warning_phase()
    │
    ├─► If prevented: hunt_warning_ended(false) → cooldown reset
    │
    └─► If not prevented: hunt_warning_ended(true) → _start_hunt()
                                                        │
                                                        ▼
                                                   hunt_started
```

### Ambush Flow (skip warning)

```
attempt_immediate_hunt(position)
    │
    ├─► hunt_starting(position, entity)  ─► Crucifix can prevent
    │
    └─► If not prevented: _start_hunt() → hunt_started
```
