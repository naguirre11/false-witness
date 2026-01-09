---
id: FW-037b
title: "Spectral Prism Calibrator Unit"
epic: EVIDENCE
parent: FW-037
priority: high
estimated_complexity: medium
dependencies: [FW-037a]
created: 2026-01-09
---

## Description

Implement the Calibrator Unit of the Spectral Prism Rig. The Calibrator is the first-stage operator who aligns spectral filters to reveal a pattern shape. The Calibrator can lie about what shape they aligned to.

**Trust Dynamic**: The Calibrator sees abstract blobs that resolve into shapes when aligned. They verbally announce the shape, but no one else can verify this directly.

## Acceptance Criteria

### Viewfinder Mechanics
- [x] Viewfinder activation (look through equipment)
- [x] Must have line-of-sight to anchor point (entity location or zone)
- [ ] Visual effect: abstract colored blobs when not aligned (deferred - visual only)

### Filter Rotation
- [x] Player input to rotate filters (left/right or scroll)
- [x] Multiple filter stages (e.g., 3 filters that need alignment)
- [x] Feedback on filter position (visual/audio) - signals implemented

### Alignment Detection
- [x] Each anchor point has a "true pattern" (determined by entity)
- [x] Alignment succeeds when filters match the anchor's pattern
- [ ] Visual feedback: blobs resolve into distinct shape when aligned (deferred - visual only)
- [x] Audio feedback: harmony tone when aligned - signal implemented

### Lock Action
- [x] Player can "lock" calibration at any filter position
- [x] Locking emits signal to paired Lens Reader
- [x] Lock stores the current pattern (may differ from true pattern if misaligned)
- [x] Cannot re-lock without full reset

### Calibration State
- [x] States: IDLE, VIEWING, ALIGNING, LOCKED
- [x] `get_locked_pattern()` returns pattern at lock time
- [x] `is_properly_aligned()` returns whether lock matches true pattern
- [x] Reset method to start over

### Cultist Deception
- [x] Calibrator can lock at wrong alignment intentionally
- [x] Announce a different shape than what they see
- [x] No gameplay enforcement of truthful reporting (social deduction)

## Technical Notes

**Mock Anchor Points**: For testing, create `SpectralAnchor` node that defines true patterns. In full game, entities will provide this.

**Visual Design** (deferred to later ticket):
- Viewfinder shows swirling color blobs
- Blobs coalesce into shapes as filters align
- Each pattern has distinct shape: triangle, circle, square, spiral

**Filter Mechanic**: Think of it like a combination lock - player rotates through positions until the pattern "clicks" into place. A skilled observer can tell if someone rushed vs. carefully aligned.

## Out of Scope

- 3D model for Calibrator unit
- Actual visual shader effects (placeholder visuals OK)
- Network sync details (use base CooperativeEquipment sync)

## Testing

```bash
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=test_calibrator.gd -gexit
```

Test scenarios:
- Filter rotation cycles through positions
- Lock captures current filter state
- Proper alignment detection against anchor
- State transitions (IDLE -> VIEWING -> ALIGNING -> LOCKED)
- Cannot use without line-of-sight
- Partner proximity required

---

## Implementation Notes

**Files Created:**
- `src/equipment/spectral_prism/calibrator.gd` - SpectralPrismCalibrator class (455 lines)
- `src/equipment/spectral_prism/spectral_anchor.gd` - Mock anchor for testing (45 lines)
- `tests/test_calibrator.gd` - 74 comprehensive tests

**Key Design Decisions:**

1. **CalibrationState enum** with 4 states: IDLE, VIEWING, ALIGNING, LOCKED
   - IDLE: Equipment not in use
   - VIEWING: Looking through viewfinder, blobs visible
   - ALIGNING: Actively rotating filters
   - LOCKED: Calibration complete, cannot modify

2. **Filter Mechanic**: 3 filters with 8 positions each (like a combination lock)
   - `rotate_filter(filter_index, direction)` to rotate individual filters
   - `rotate_all_filters(direction)` for quick adjustment
   - Target positions generated deterministically from anchor pattern

3. **Line-of-Sight**: Uses PhysicsRayQueryParameters3D for LOS checks
   - Configurable via `require_line_of_sight` and `line_of_sight_mask`
   - Gracefully skips check when not in scene tree (for testing)

4. **Signals for Feedback**:
   - `alignment_achieved(pattern)` - blobs resolved into shape
   - `alignment_lost` - filters moved away from alignment
   - `calibration_locked(pattern)` - final lock action
   - `filter_rotated(filter_index, position)` - for audio/visual feedback

5. **Deception Support**: Lock action stores whatever pattern is "visible" at lock time
   - If aligned: stores the true pattern
   - If misaligned: stores NONE
   - Player announces pattern verbally - game doesn't enforce truthfulness

**Visual Effects (deferred):** The acceptance criteria for visual effects (blob animation, shape coalescing) are marked as deferred since they require shader work. The signals and state are in place to drive those visuals when implemented.

**Test Results:** 74/74 tests passing

```bash
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_calibrator.gd -gexit
```
