---
id: FW-042b
title: "Hunt detection mechanics"
epic: ENTITY
priority: high
estimated_complexity: medium
dependencies: [FW-041, FW-042a]
created: 2026-01-09
updated: 2026-01-09
parent_ticket: FW-042
---

## Description

Implement the detection system that allows the entity to find and track players during hunts. This includes distance-based detection, line-of-sight checks, and modifiers for player behavior (electronics, voice activity).

## Acceptance Criteria

- [x] Base detection radius of 7 meters
- [x] Electronics in hand modifier: +3m detection (10m total)
- [x] Voice activity modifier: +5m detection (12m total)
- [x] Line-of-sight detection triggers chase (aware state)
- [x] Entity tracks last known position when LoS is broken
- [x] Entity transitions to unaware (searching) when target lost
- [x] Detection modifiers stack appropriately

## Technical Notes

**Implementation Location**: New file `src/entity/hunt_detection.gd` + Entity.gd modifications

**Detection Constants**:
```gdscript
const BASE_DETECTION_RADIUS := 7.0
const ELECTRONICS_DETECTION_BONUS := 3.0
const VOICE_DETECTION_BONUS := 5.0
```

**Line-of-Sight Check**:
- Use raycast from entity eye position to player
- Consider occlusion by walls/doors
- Ignore transparent surfaces (glass)

**Player State Queries**:
- Need method to check if player has electronics equipped
- Need method to check if player is using voice (from VoiceChat system)

**Entity Integration**:
- `_process_hunting_behavior()` calls detection checks
- Updates `_is_aware_of_target` based on LoS
- Updates `_last_known_target_position` when losing LoS
- Adjusts movement speed based on awareness

## Out of Scope

- Hiding spot detection (FW-042c)
- Entity-specific detection variations (FW-042d)
- Voice chat integration (depends on FW-014)

## Implementation Notes

### Files Changed

- **`src/entity/hunt_detection.gd`** (NEW): Static detection utility class
  - `BASE_DETECTION_RADIUS = 7.0`, `ELECTRONICS_DETECTION_BONUS = 3.0`, `VOICE_DETECTION_BONUS = 5.0`
  - `get_detection_radius(player)` - calculates effective radius with modifiers
  - `is_player_in_range(entity_pos, player)` - distance check
  - `has_line_of_sight(entity, player, space_state)` - raycast LoS check
  - `find_nearest_player(entity, players, space_state)` - finds closest detectable player
  - `detect_players(entity, players, space_state)` - returns all detection results
  - `_player_has_electronics_equipped(player)` - checks for electronic equipment
  - `_player_is_using_voice(player)` - placeholder for voice chat (FW-014)
  - `_is_electronic_equipment(type)` - equipment type classification

- **`src/entity/entity.gd`**: Hunt detection integration
  - Added `_update_hunt_detection()` - called during `_process_hunting()`
  - Added `_get_alive_players()` - retrieves players for detection
  - Added `is_aware_of_target()` - public API for awareness state
  - Added `get_last_known_target_position()` - public API
  - Added `get_target_detection_radius()` - public API
  - Modified `_process_hunting()` - uses detection for target tracking

- **`tests/test_hunt_detection.gd`** (NEW): 22 unit tests
- **`tests/test_entity.gd`**: 9 new detection integration tests

### Test Evidence

```bash
# Run detection tests
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_hunt_detection.gd -gexit
# Result: 22/22 passed

# Run entity tests
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_entity.gd -gexit
# Result: 42/42 passed (including 9 new detection tests)

# Full test suite
$GODOT --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
# Result: 1353/1353 passed
```

### Design Decisions

1. **Static utility class**: HuntDetection uses static methods for easy testing and reuse
2. **Duck typing for equipment**: Uses untyped variables to support both real Equipment and test mocks
3. **Voice placeholder**: `_player_is_using_voice()` returns false until FW-014 (voice chat) is implemented
4. **Electronic equipment list**: Hardcoded equipment types (EMF Reader, Thermometer, Calibrator, Lens Reader, Aura Imager)
