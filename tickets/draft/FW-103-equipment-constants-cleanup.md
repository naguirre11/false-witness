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
