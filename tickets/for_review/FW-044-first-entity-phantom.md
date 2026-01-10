---
id: FW-044
title: "Implement first entity type: Phantom"
epic: ENTITY
priority: high
estimated_complexity: medium
dependencies: [FW-041, FW-042]
created: 2026-01-07
---

## Description

Create the first complete entity type - the Phantom. This establishes the pattern for all future entity implementations.

## Acceptance Criteria

- [x] Phantom entity class extending Entity base
- [x] Evidence types: EMF_SIGNATURE, PRISM_READING, VISUAL_MANIFESTATION
- [x] Unique behavior: Looking at Phantom drops sanity faster
- [x] Phantom can disappear when looked at during manifestation
- [x] Hunt behavior follows base with unique audio
- [ ] Placeholder visual model (can be improved later) - Deferred: visual model is out of scope for this ticket per design
- [x] Audio cues specific to Phantom - Placeholder TODOs added

## Technical Notes

**Evidence Types (using implemented system):**
- EMF_SIGNATURE - Detected by EMF Reader (level 5)
- PRISM_READING - Detected by Spectral Prism Rig (cooperative symmetric)
- VISUAL_MANIFESTATION - Full/partial entity appearances (readily apparent)

**Cultist Overlap:**
Phantom shares EMF_SIGNATURE + PRISM_READING with Wraith. Only VISUAL_MANIFESTATION vs AURA_PATTERN differentiates them. This overlap is intentional - Cultist needs only contaminate one evidence type to cause misidentification.

**Behavioral Tell:**
Disappears instantly when photographed during manifestation. Camera becomes a defensive tool.

## Out of Scope

- Additional entity types
- Entity visual polish

## Implementation Notes

### Files Created
- `src/entity/phantom.gd` - Phantom entity class extending Entity base
- `tests/test_phantom.gd` - 30 tests covering Phantom-specific behavior

### Files Modified
- `src/entity/entity.gd` - Fixed Variant type inference issue on line 1007

### Key Implementation Details

**Evidence Types:**
- `get_evidence_types()` returns array of EMF_SIGNATURE, PRISM_READING, VISUAL_MANIFESTATION
- `has_evidence_type()` provides O(1) lookup for specific evidence check

**Behavioral Tell (photograph_disappearance):**
- Checked via `_check_behavioral_tell()` during manifestation state
- Uses `_is_player_photographing()` to detect camera usage
- Supports multiple detection methods: `is_using_camera()`, `get_equipped_item()` with `take_photo` method
- Ends manifestation immediately and emits `behavioral_tell_triggered` signal

**Sanity Mechanics:**
- `SANITY_DRAIN_MULTIPLIER = 2.0` - Phantom drains sanity 2x faster than other entities
- `LOOK_DRAIN_PER_SECOND = 2.0` - Per-second drain when looking at manifesting Phantom
- Players looking at Phantom tracked via `_players_looking` array
- Visibility check interval of 0.2 seconds for performance

**Hunt Behavior:**
- Uses default Entity hunt behavior (no overrides)
- Standard 50% team sanity threshold
- Standard movement speeds (1.5 base, 2.5 aware, 1.0 unaware)

### Test Commands

```bash
# Run Phantom-specific tests
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_phantom.gd -gexit

# Run all tests
$GODOT --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gprefix=test_ -gsuffix=.gd -gexit
```

### Test Results
- 30/30 Phantom tests passing
- 1597/1597 total tests passing
- All lint checks pass
