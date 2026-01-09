---
id: FW-037c
title: "Spectral Prism Lens Reader Unit"
epic: EVIDENCE
parent: FW-037
priority: high
estimated_complexity: medium
dependencies: [FW-037a, FW-037b]
created: 2026-01-09
---

## Description

Implement the Lens Reader Unit of the Spectral Prism Rig. The Lens Reader is the second-stage operator who reads the entity signature after the Calibrator locks alignment. The Lens Reader can also lie about what they see.

**Trust Dynamic**: The Lens Reader sees a pattern (shape + color) through the eyepiece. They verbally announce what they see, but no one else can verify this directly. This makes PRISM_READING evidence LOW trust - both operators can lie.

## Acceptance Criteria

### Activation Rules
- [x] Cannot activate until paired Calibrator has locked
- [x] Receives `calibration_locked` signal from partner
- [x] Clear feedback when waiting for Calibrator

### Eyepiece Display
- [x] Shows entity signature when activated (shape + color)
- [x] Shape determined by Calibrator's locked pattern
- [x] Color determined by entity's true category
- [x] Color provides secondary verification opportunity

### Pattern Reading
- [x] Display combines shape (from Calibrator) and color (from entity)
- [x] If Calibrator misaligned, shape may not match color meaning
- [x] Discrepancy is visible to Lens Reader but not enforced

### Evidence Collection
- [x] Player action to "record reading"
- [x] Creates PRISM_READING evidence via EvidenceManager
- [x] Evidence includes both collector IDs (cooperative evidence)
- [x] Reading quality based on:
  - STRONG: Calibrator properly aligned, players stationary
  - WEAK: Misaligned or movement during read

### Reading Quality Factors
- [x] Calibrator alignment accuracy affects quality
- [x] Player movement during read affects quality
- [x] Time spent on reading (rushed = weak)

### Entity Signature Data
- [x] `get_pattern_shape()` - what Calibrator locked
- [x] `get_pattern_color()` - entity's true color
- [x] `get_combined_signature()` - full reading description
- [x] `is_consistent()` - shape category matches color category

### Cultist Deception
- [x] Lens Reader can announce wrong signature
- [x] Can claim inconsistency when there is none (or vice versa)
- [x] No gameplay enforcement - pure social deduction

## Technical Notes

**Color-Category Mapping**:
| Color | Category | Shapes |
|-------|----------|--------|
| Blue-violet | Passive | Triangle (match) |
| Red-orange | Aggressive | Circle (match) |
| Green | Territorial | Square (match) |
| Yellow | Mobile | Spiral (match) |

If shape doesn't match color category, an alert observer might notice the inconsistency - this is a key verification mechanic.

**Evidence Integration**:
```gdscript
var evidence = EvidenceManager.collect_cooperative_evidence(
    EvidenceEnums.EvidenceType.PRISM_READING,
    calibrator_player_id,
    lens_reader_player_id,
    location,
    reading_quality
)
```

## Out of Scope

- 3D model for Lens Reader unit
- Actual visual shader effects for eyepiece
- Entity-specific signature definitions (part of entity system)

## Testing

```bash
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=test_lens_reader.gd -gexit
```

Test scenarios:
- Cannot activate before Calibrator locks
- Receives calibration data from partner
- Evidence created with both collector IDs
- Quality assessment based on alignment and movement
- Consistency detection (shape matches color category)
- Integration with EvidenceManager

## Implementation Notes

### Files Created
- `src/equipment/spectral_prism/lens_reader.gd` - SpectralPrismLensReader class
- `tests/test_lens_reader.gd` - 57 comprehensive tests

### Key Implementation Details

**State Machine:**
- `IDLE` - Not active, waiting for calibration
- `WAITING` - Calibration not yet locked (shows feedback)
- `VIEWING` - Eyepiece active, seeing pattern/color
- `READING` - Recording the reading (progress bar)

**Calibration Callback:**
- `on_calibration_locked(pattern)` called by partner Calibrator
- Stores received pattern and checks alignment status
- Transitions from WAITING to IDLE when calibration received

**Quality Factors:**
- `MIN_VIEWING_TIME = 1.0s` - Must view before recording
- `STRONG_QUALITY_TIME = 3.0s` - Time threshold for strong quality
- `MOVEMENT_THRESHOLD = 0.5` - Max movement for strong quality
- Misaligned calibrator always yields WEAK quality

**Evidence Creation:**
- Uses `EvidenceManager.collect_cooperative_evidence()`
- Includes both calibrator and reader player IDs
- Equipment noted as "Spectral Prism Rig"

### Test Results
```
$GODOT --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
57/57 passed (test_lens_reader.gd)
971/971 passed (full suite)
```

### Deferred
- Visual shader effects for eyepiece display (requires shader work)
- UI feedback for reading progress (requires HUD integration)
