---
id: FW-037a
title: "Spectral Prism Equipment Base"
epic: EVIDENCE
parent: FW-037
priority: high
estimated_complexity: medium
dependencies: [FW-031, FW-023]
created: 2026-01-09
---

## Description

Create the base cooperative equipment pattern for the Spectral Prism Rig. This establishes the paired-equipment architecture where two separate equipment pieces (Calibrator and Lens Reader) must work together, with proximity validation and shared state.

This is the foundation for FW-037b (Calibrator) and FW-037c (Lens Reader).

## Acceptance Criteria

### Equipment Base Class
- [x] Create `CooperativeEquipment` base class extending `Equipment`
- [x] Paired equipment reference system (partner_equipment property)
- [x] Proximity validation (configurable max_partner_distance, default 5m)
- [x] Partner connection/disconnection signals

### Prism Data Structures
- [x] `PrismPattern` enum: TRIANGLE, CIRCLE, SQUARE, SPIRAL
- [x] `PrismColor` enum: BLUE_VIOLET, RED_ORANGE, GREEN, YELLOW
- [x] Pattern-to-entity-category mapping:
  - Triangle = Passive (Shade, Spirit-type)
  - Circle = Aggressive (Demon, Oni-type)
  - Square = Territorial (Goryo, Hantu-type)
  - Spiral = Mobile (Wraith, Phantom-type)
- [x] Color-to-category confirmation mapping (secondary verification)

### Proximity System
- [x] Real-time distance tracking between paired equipment holders
- [x] Warning signal when approaching max distance
- [x] Automatic operation failure if players separate during use
- [x] `is_partner_in_range()` check method

### Equipment Types
- [x] Add `SPECTRAL_PRISM_CALIBRATOR` to Equipment.EquipmentType
- [x] Add `SPECTRAL_PRISM_LENS` to Equipment.EquipmentType

## Technical Notes

**Design Pattern**: The cooperative equipment pattern should be reusable for FW-038 (Dowsing Rods + Aura Imager). Consider how the base class can support both symmetric (Prism) and asymmetric (Aura) trust dynamics.

**Proximity Validation**: Players must remain within 5m of each other during the entire operation. If either moves too far, the operation fails and must restart.

**File Structure**:
```
src/equipment/
  cooperative_equipment.gd       # Base class for paired equipment
  spectral_prism/
    prism_enums.gd               # Pattern and color enums
    calibrator.gd                # FW-037b
    lens_reader.gd               # FW-037c
```

## Out of Scope

- Calibrator viewfinder mechanics (FW-037b)
- Lens Reader display and evidence collection (FW-037c)
- 3D models and visual effects
- Network synchronization (handled at equipment level)

## Testing

```bash
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=test_cooperative_equipment.gd -gexit
$GODOT --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gprefix=test_prism -gexit
```

Test scenarios:
- Partner pairing and unpairing
- Proximity threshold detection
- Operation failure on distance exceeded
- Pattern/color enum completeness

---

## Implementation Notes

**Files Created:**
- `src/equipment/cooperative_equipment.gd` - Base class for two-player equipment
- `src/equipment/spectral_prism/prism_enums.gd` - Pattern/color enums with category mappings
- `tests/test_cooperative_equipment.gd` - 39 tests for cooperative equipment
- `tests/test_prism_enums.gd` - 52 tests for prism enums

**Files Modified:**
- `src/equipment/equipment.gd` - Added 4 new equipment types (SPECTRAL_PRISM_CALIBRATOR, SPECTRAL_PRISM_LENS, DOWSING_RODS, AURA_IMAGER)
- `gdlintrc` - Excluded tests directory from max-public-methods check

**Key Design Decisions:**

1. **CooperativeEquipment** extends Equipment with:
   - `link_partner()` / `unlink_partner()` for reciprocal pairing
   - `TrustDynamic` enum (SYMMETRIC vs ASYMMETRIC) for future Aura Imager support
   - `OperationState` enum for tracking multi-step operations
   - Configurable `max_partner_distance` (default 5m) and `proximity_warning_distance` (4m)
   - Signals: `partner_linked`, `partner_unlinked`, `proximity_warning`, `proximity_failed`, `operation_cancelled`

2. **PrismEnums** provides:
   - Bidirectional mappings: Pattern <-> EntityCategory <-> Color
   - `is_consistent()` helper for detecting shape/color mismatches (key deception detection mechanic)
   - `get_all_patterns()` / `get_all_colors()` helpers excluding NONE values

3. **Position handling** uses `position` when not in scene tree (for testing) and `global_position` when in tree.

**Test Results:** 840/840 tests passing (91 new tests for this ticket)
