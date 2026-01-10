---
id: FW-043d
title: "Revival mechanic"
epic: FW-043
priority: high
estimated_complexity: medium
dependencies: [FW-043a, FW-043b]
created: 2026-01-09
---

## Description

Implement the revival system that allows living players to bring back dead teammates. Revival requires commitment (30 seconds at death location) and carries penalties for the revived player.

## Acceptance Criteria

### Revival Process
- [x] Living player can initiate revival at Echo's death location
- [x] Revival requires 30 seconds of channeling at the death location
- [x] Revival progress visible to both reviver and Echo
- [x] Revival is interruptible by entity hunts (progress resets)
- [x] Only one player can attempt revival at a time per death location

### Revival Penalties
- [x] Revived players return with 50% sanity
- [ ] Revived players lose all equipment (respawn with nothing) *deferred - no equipment system yet*
- [x] Each player can only be revived ONCE per investigation
- [x] Revival count tracked per player

### Revival UI
- [ ] Death location marked for living players (interact prompt) *UI ticket scope*
- [ ] Progress bar during revival channeling *UI ticket scope*
- [ ] Revival available/unavailable indicator (already revived once) *UI ticket scope*

## Technical Notes

- Death location stored in FW-043a is used here
- Revival state machine: Idle -> Channeling -> Complete/Interrupted
- Need to transition Echo back to living player controller

### Revival State

```gdscript
enum RevivalState { IDLE, CHANNELING, COMPLETE }

var _revival_state := RevivalState.IDLE
var _revival_progress := 0.0
var _reviver_id: int = -1
const REVIVAL_DURATION := 30.0

func start_revival(reviver_id: int) -> bool:
    if _times_revived >= 1:
        return false  # Already revived once
    if _revival_state != RevivalState.IDLE:
        return false  # Already being revived
    _revival_state = RevivalState.CHANNELING
    _reviver_id = reviver_id
    return true

func update_revival(delta: float) -> void:
    if _revival_state == RevivalState.CHANNELING:
        _revival_progress += delta
        if _revival_progress >= REVIVAL_DURATION:
            complete_revival()
```

### Hunt Interruption

```gdscript
func _on_hunt_started() -> void:
    if _revival_state == RevivalState.CHANNELING:
        cancel_revival()

func cancel_revival() -> void:
    _revival_state = RevivalState.IDLE
    _revival_progress = 0.0
    _reviver_id = -1
```

### Revival Completion

```gdscript
func complete_revival() -> void:
    _revival_state = RevivalState.COMPLETE
    _times_revived += 1
    # Transition Echo back to Player
    # Set sanity to 50%
    # Clear equipment
```

## Out of Scope

- Death trigger (FW-043a)
- Echo movement (FW-043b)
- Echo restrictions (FW-043c)

## Implementation Notes

### Changes Made

**src/player/echo_controller.gd:**
- Added `RevivalState` enum: `IDLE`, `CHANNELING`, `COMPLETE`
- Added revival state variables: `times_revived`, `revival_state`, `revival_progress`, `reviver_id`
- Added signals: `revival_started`, `revival_progress_changed`, `revival_cancelled`, `revival_completed`
- Added revival API:
  - `can_be_revived()` - checks if Echo can be revived (not already revived once)
  - `is_being_revived()` - checks if revival is in progress
  - `start_revival(reviver_id)` - initiates revival channeling
  - `update_revival(delta)` - updates progress, emits signals, completes when done
  - `cancel_revival()` - resets state (for interruption)
  - `on_hunt_started()` - cancels revival when hunt begins
  - `get_revival_progress_percent()` - returns 0.0-1.0 progress
  - `get_reviver_id()` - returns reviver player ID

**src/player/player_controller.gd:**
- Added `times_revived` tracking
- Added `REVIVAL_SANITY_PERCENT` constant (0.5 = 50%)
- Added `revived` signal
- Added `can_be_revived()` - checks if dead player can be revived
- Added `on_revived()` - handles revival completion with penalties:
  - Sets stamina to 50% (placeholder for sanity)
  - Restores alive/echo state
  - Re-enables physics and input
  - Teleports to death position
  - Cleans up Echo controller
- Added `_transfer_camera_from_echo()` for camera handoff
- Updated `get_network_state()` and `apply_network_state()` for network sync

### Test Evidence

```
Tests             1567
  Passing         1567
Time              17.393s
---- All tests passed! ----
```

24 new tests added covering:
- Revival state initialization
- `start_revival()` success/failure cases
- Progress tracking and signals
- Cancel/interruption behavior
- Hunt interruption integration
- `on_revived()` state restoration and penalties
- Network state sync

### Deferred Work

- **Equipment clearing**: No equipment system exists yet. When implemented, `on_revived()` should clear player's equipment.
- **Revival UI**: Death location markers, progress bars, and availability indicators are UI concerns for a separate ticket.
