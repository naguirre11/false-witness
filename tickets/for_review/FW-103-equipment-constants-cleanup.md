---
id: FW-103
title: "Clean up stale equipment type constants"
epic: FOUNDATION
priority: low
estimated_complexity: small
dependencies: []
created: 2026-01-10
---

## Description

The `EquipmentSlot` class contains equipment type constants from the original GDD that were never implemented. These should be updated to match the actual implemented equipment system.

## Acceptance Criteria

- [ ] Update `equipment_slot.gd` type_to_name() to reflect implemented equipment
- [ ] Update `equipment_slot.gd` name_to_type() to match
- [ ] Update `hunt_detection.gd` electronics list comment
- [ ] Remove references to deferred equipment (Spirit Box, DOTS, UV Flashlight, etc.)
- [ ] Add constants for implemented equipment (Calibrator, Lens Reader, Dowsing Rods, Aura Imager)
- [ ] Update any tests affected by constant changes
- [ ] Run full test suite to verify no regressions

## Technical Notes

**Current stale constants in `equipment_slot.gd`:**
```gdscript
# type_to_name() and name_to_type() contain:
0: "EMF Reader"        # Keep
1: "Spirit Box"        # Remove (deferred FW-034)
2: "Journal"           # Rename to "Ghost Writing Book"
3: "Thermometer"       # Keep
4: "UV Flashlight"     # Remove (not implemented)
5: "DOTS Projector"    # Remove (not implemented)
6: "Video Camera"      # Remove or keep for future?
7: "Parabolic Mic"     # Remove (not implemented)
```

**Should become:**
```gdscript
0: "EMF Reader"              # EMF_SIGNATURE
1: "Thermometer"             # FREEZING_TEMPERATURE
2: "Ghost Writing Book"      # GHOST_WRITING
3: "Spectral Calibrator"     # PRISM_READING (player 1)
4: "Spectral Lens Reader"    # PRISM_READING (player 2)
5: "Dowsing Rods"            # AURA_PATTERN (player 1)
6: "Aura Imager"             # AURA_PATTERN (player 2)
7: "Crucifix"                # Protection
8: "Salt"                    # Protection
9: "Sage Bundle"             # Protection
```

**Also update comment in `hunt_detection.gd:175`:**
```gdscript
## Electronics include: EMF Reader, Spirit Box, Thermometer, Video Camera, etc.
```

## Out of Scope

- Adding new equipment functionality
- Changing equipment behavior
- UI updates (handled by FW-082)

---

## Implementation Notes (2026-01-24)

### Approach Taken

Instead of renumbering equipment types as originally planned, the implementation chose to **sync with the existing `Equipment.EquipmentType` enum** (0-15). This preserves backward compatibility with serialized data and ensures consistency across the codebase.

### Changes Made

1. **equipment_slot.gd**:
   - `type_to_name()`: Now maps all 16 equipment types (0-15) to display names
   - `name_to_type()`: Reverse mapping for all 16 types
   - `get_scene_path()`: Scene paths for 11 implemented equipment, empty string for 5 unimplemented

2. **hunt_detection.gd**:
   - Removed Spirit Box (1) and Parabolic Mic (7) from ELECTRONIC_TYPES array (not implemented)
   - Updated comment at line 175 to list actual implemented electronics

3. **test_equipment_slot.gd**:
   - Added 8 new tests for equipment types 8-15
   - Updated static helper tests to cover broader range

4. **test_hunt_detection.gd**:
   - Updated electronics test to use implemented types only: [0, 3, 6, 8, 9, 11]

5. **video_camera.gd** (bonus fix):
   - Fixed pre-existing bug where `player_pos` was undefined in `_rpc_request_capture()`

### Test Results

- **Smoke tests**: 17/17 passing
- **Full suite**: 2242 tests, 2 pre-existing failures unrelated to FW-103
- **Equipment slot tests**: All passing
- **Hunt detection tests**: 31/31 passing

### Design Decision

The ticket originally suggested renumbering equipment types (e.g., Thermometer becoming type 1). However, this would require:
- Modifying the `Equipment.EquipmentType` enum
- Updating all equipment implementations
- Potential serialization/network compatibility issues

Instead, the implementation keeps the enum values intact and simply adds the missing mappings for implemented equipment (types 8-15), while keeping placeholder names for unimplemented equipment (types 1, 2, 4, 5, 7) for backward compatibility.
