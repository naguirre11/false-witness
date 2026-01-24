---
id: FW-042c
title: "Hunt hiding mechanics"
epic: ENTITY
priority: high
estimated_complexity: medium
dependencies: [FW-042b]
created: 2026-01-09
updated: 2026-01-09
parent_ticket: FW-042
---

## Description

Implement hiding mechanics that allow players to break line of sight and evade the entity during hunts. This includes hiding spots (closets, lockers), entity search behavior, and the tactical interplay between hiding and being found.

## Acceptance Criteria

- [x] Hiding spots (closets, lockers) defined as Area3D zones
- [x] Players inside hiding spots block entity entry/detection
- [x] Closing hiding spot door breaks line of sight
- [x] Entity searches nearby hiding spot area for ~5 seconds
- [x] Entity moves on if player not found after search
- [x] Breaking line of sight resets entity tracking
- [x] Entity-specific hiding variations hook (some ignore spots)

## Technical Notes

**Implementation Location**: New `src/entity/hiding_spot.gd` + Entity.gd modifications

**HidingSpot Component**:
```gdscript
class_name HidingSpot extends Area3D

@export var blocks_entity_entry := true
@export var search_duration := 5.0

func get_occupants() -> Array[int]:  # player_ids inside
func is_door_closed() -> bool:
```

**Entity Search Behavior**:
1. Entity approaches hiding spot
2. `blocks_entity_entry = true` prevents pathfinding inside
3. Entity waits at entrance for `search_duration`
4. If player not detected (door closed = no LoS), entity moves on
5. If player opens door or makes noise, entity detects

**Entity Integration**:
- `can_ignore_hiding_spots() -> bool` - Virtual method for entity variations
- Entity pathfinding avoids HidingSpot volumes unless ignoring

**Player Awareness**:
- Player sees "Hiding" indicator when in spot with door closed
- Player can peek (open door slightly) at risk

## Out of Scope

- Actual closet/locker 3D models (map implementation)
- Door interaction system (FW-022 handles that)
- Entity-specific variations beyond the hook (FW-042d)

## Implementation Notes

### Files Created
- `src/entity/hiding_spot.gd` - HidingSpot Area3D component for tracking player occupancy
- `src/entity/hiding_spot_door.gd` - HidingSpotDoor extending Interactable for door mechanics
- `tests/test_hiding_spot.gd` - Unit tests for HidingSpot
- `tests/test_hiding_spot_door.gd` - Unit tests for HidingSpotDoor

### Files Modified
- `src/entity/entity.gd` - Added hiding spot search behavior and `can_ignore_hiding_spots()` hook
- `src/entity/hunt_detection.gd` - Added hiding spot protection check to line-of-sight detection
- `tests/test_entity.gd` - Added hiding spot integration tests
- `tests/test_hunt_detection.gd` - Added hiding spot protection tests

### Key Implementation Details

**HidingSpot Class**:
- Tracks player occupancy via Area3D body detection
- Supports door state tracking (manual or via connected door node)
- Provides `is_protecting_occupants()` check combining occupancy + door state
- Entity search timer with signals for search start/end

**HidingSpotDoor Class**:
- Extends Interactable with TOGGLE type
- Controls StaticBody3D collision layer to block/allow LoS raycasts
- Emits `door_state_changed` signal for integration with HidingSpot

**Entity Integration**:
- `_find_nearby_hiding_spot()` - Finds hiding spots near last known player position
- `_start_hiding_spot_search()` / `_process_hiding_spot_search()` - Search behavior during hunt
- `can_ignore_hiding_spots()` - Virtual method for entity-specific variations (e.g., Wraith)

**HuntDetection Integration**:
- `_is_player_protected_by_hiding_spot()` - Checks if player is in protected hiding spot
- Line-of-sight check now returns false if player is protected by hiding spot

### Test Evidence

```bash
# Run hiding mechanics tests
$GODOT --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit

# Results: 1422/1422 tests passed
```
