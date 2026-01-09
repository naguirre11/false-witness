---
id: FW-038a
title: "Aura Equipment Base"
epic: EVIDENCE
parent: FW-038
priority: high
estimated_complexity: medium
dependencies: [FW-037a]
created: 2026-01-09
---

## Description

Create the base infrastructure for the Dowsing Rods + Aura Imager cooperative equipment pair. This establishes the aura data structures, spatial constraint system (Dowser must face anchor, Imager must be behind Dowser), and asymmetric trust configuration.

This builds on `CooperativeEquipment` from FW-037a, adding support for the ASYMMETRIC trust dynamic where only one operator (the Imager) can meaningfully lie.

## Acceptance Criteria

### Aura Data Structures
- [x] `AuraColor` enum: COLD_BLUE, HOT_RED, PALE_GREEN, DEEP_PURPLE
- [x] `AuraForm` enum: TIGHT_CONTAINED, SPIKING_ERRATIC, DIFFUSE_SPREADING, SWIRLING_MOBILE
- [x] Color-to-temperament mapping:
  - Cold blue = Passive/shy entity
  - Hot red = Aggressive entity
  - Pale green = Territorial entity
  - Deep purple = Roaming entity
- [x] Form-to-behavior mapping:
  - Tight, contained = Passive
  - Spiking, erratic = Aggressive
  - Diffuse, spreading = Territorial
  - Swirling, mobile = Roaming
- [x] `is_consistent()` helper (color temperament matches form behavior)

### Spatial Constraint System
- [x] `SpatialConstraints` class for validating operator positions
- [x] Dowser constraint: must face anchor point (configurable tolerance angle)
- [x] Imager constraint: must be behind Dowser (within cone angle)
- [x] `validate_positions()` method returns constraint violations
- [x] Constraint violations returned as ConstraintResult with violation list

### Asymmetric Trust Support
- [x] `CooperativeEquipment` already has ASYMMETRIC trust dynamic (FW-037a)
- [x] Spatial constraints enforce visibility: Dowser position visible to all
- [x] Imager positioned behind = only they see screen clearly

### Equipment Types
- [x] `DOWSING_RODS` exists in Equipment.EquipmentType
- [x] `AURA_IMAGER` exists in Equipment.EquipmentType

## Technical Notes

**Why Dowser Can't Lie:**
The Dowser faces the anchor point with their back to the Imager. Their rod positions are visible to all nearby players. Turning around breaks alignment. The spatial separation isn't arbitrary - it emerges from the equipment's physical operation.

**Spatial Validation:**
```gdscript
# Dowser must face anchor (within 30° cone)
var facing_anchor := dowser_forward.angle_to(to_anchor) < deg_to_rad(30)

# Imager must be behind Dowser (within 60° rear cone)
var dowser_to_imager := imager_pos - dowser_pos
var behind_dowser := dowser_forward.angle_to(-dowser_to_imager.normalized()) < deg_to_rad(60)
```

**File Structure:**
```
src/equipment/
  aura/
    aura_enums.gd              # Color and form enums with mappings
    spatial_constraints.gd     # Position validation for asymmetric ops
    dowsing_rods.gd            # FW-038b
    aura_imager.gd             # FW-038c
```

## Out of Scope

- Dowsing rod mechanics (FW-038b)
- Aura Imager display and evidence collection (FW-038c)
- 3D models and visual effects
- Network synchronization details

## Testing

```bash
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_aura_enums.gd -gexit
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_spatial_constraints.gd -gexit
```

Test scenarios:
- Color/form enum completeness
- Consistency detection (color matches form category)
- Spatial constraint: Dowser facing anchor
- Spatial constraint: Imager behind Dowser
- Constraint violation signals
- Edge cases: exact boundary angles

## Implementation Notes

### Files Created
- `src/equipment/aura/aura_enums.gd` - AuraEnums class with color/form enums and mappings
- `src/equipment/aura/spatial_constraints.gd` - SpatialConstraints class for position validation
- `tests/test_aura_enums.gd` - 52 tests for aura enum functionality
- `tests/test_spatial_constraints.gd` - 45 tests for spatial constraint validation

### Key Implementation Details

**AuraEnums:**
- `AuraColor`: NONE, COLD_BLUE, HOT_RED, PALE_GREEN, DEEP_PURPLE
- `AuraForm`: NONE, TIGHT_CONTAINED, SPIKING_ERRATIC, DIFFUSE_SPREADING, SWIRLING_MOBILE
- `EntityTemperament`: UNKNOWN, PASSIVE, AGGRESSIVE, TERRITORIAL, ROAMING
- Bidirectional mappings between colors, forms, and temperaments
- `is_consistent()` checks if color and form indicate the same temperament
- `get_combined_signature()` for evidence display text

**SpatialConstraints:**
- `ConstraintConfig`: Configurable tolerance angles and distances
  - Default: 30° facing tolerance, 60° behind tolerance, 1-5m distance
- `ConstraintResult`: Validation result with violations list
- `AlignmentQuality`: NONE, WEAK, MODERATE, STRONG
- `check_dowser_facing_anchor()`: Validates Dowser faces anchor point
- `check_imager_behind_dowser()`: Validates Imager is behind Dowser
- `check_imager_distance()`: Validates Imager distance from Dowser
- `validate_positions()`: Full validation combining all checks
- `calculate_alignment_quality()`: Returns 0.0-1.0 quality score

### Test Results
```
$GODOT --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
52/52 passed (test_aura_enums.gd)
45/45 passed (test_spatial_constraints.gd)
All tests passed!
```

### Deferred
- Signal emissions during operation (will be handled by equipment classes in FW-038b/c)
- Network synchronization (will be handled per-equipment)
