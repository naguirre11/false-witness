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
- [ ] Cannot activate until paired Calibrator has locked
- [ ] Receives `calibration_locked` signal from partner
- [ ] Clear feedback when waiting for Calibrator

### Eyepiece Display
- [ ] Shows entity signature when activated (shape + color)
- [ ] Shape determined by Calibrator's locked pattern
- [ ] Color determined by entity's true category
- [ ] Color provides secondary verification opportunity

### Pattern Reading
- [ ] Display combines shape (from Calibrator) and color (from entity)
- [ ] If Calibrator misaligned, shape may not match color meaning
- [ ] Discrepancy is visible to Lens Reader but not enforced

### Evidence Collection
- [ ] Player action to "record reading"
- [ ] Creates PRISM_READING evidence via EvidenceManager
- [ ] Evidence includes both collector IDs (cooperative evidence)
- [ ] Reading quality based on:
  - STRONG: Calibrator properly aligned, players stationary
  - WEAK: Misaligned or movement during read

### Reading Quality Factors
- [ ] Calibrator alignment accuracy affects quality
- [ ] Player movement during read affects quality
- [ ] Time spent on reading (rushed = weak)

### Entity Signature Data
- [ ] `get_pattern_shape()` - what Calibrator locked
- [ ] `get_pattern_color()` - entity's true color
- [ ] `get_combined_signature()` - full reading description
- [ ] `is_consistent()` - shape category matches color category

### Cultist Deception
- [ ] Lens Reader can announce wrong signature
- [ ] Can claim inconsistency when there is none (or vice versa)
- [ ] No gameplay enforcement - pure social deduction

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
