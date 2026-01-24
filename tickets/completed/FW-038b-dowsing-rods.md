---
id: FW-038b
title: "Dowsing Rods Unit"
epic: EVIDENCE
parent: FW-038
priority: high
estimated_complexity: medium
dependencies: [FW-038a]
created: 2026-01-09
---

## Description

Implement the Dowsing Rods, the "visible operator" equipment for the Aura system. The Dowser holds L-shaped rods that physically react based on their position relative to an anchor point. Their rod positions are visible to ALL nearby players, which neutralizes their ability to lie about what they observe.

**Trust Dynamic**: The Dowser CANNOT effectively deceive - their rod positions and facing direction are visible to everyone. They receive verbal directions from the Imager and adjust accordingly.

## Acceptance Criteria

### Rod State
- [x] `RodState` enum: IDLE, HELD, SEEKING, ALIGNED
- [x] Rods held loosely in both hands, extended forward
- [x] Rod angle positions (left rod, right rod) as normalized values
- [x] Rod positions visible to all nearby players (public state)

### Physical Response
- [x] Rods respond to proximity/alignment with anchor point
- [x] `RodBehavior` patterns:
  - NEUTRAL: Rods parallel, no pull
  - CROSSING: Rods cross inward (strong signal)
  - SPREADING: Rods spread outward (weak signal)
  - TWITCHING: Rods oscillate (interference)
- [x] Response intensity based on alignment quality

### Positioning Mechanics
- [x] Dowser must face anchor point (validated by SpatialConstraints)
- [x] Step movement in response to Imager directions (via position tracking)
- [x] Height adjustment (raise/lower rods) - tracked via position_changed signal
- [x] "Hold steady" action to lock position for reading

### Alignment Detection
- [x] Each anchor point has ideal Dowser position (via AuraAnchor)
- [x] Alignment quality: NONE, WEAK, MODERATE, STRONG
- [x] Quality based on position accuracy and stability
- [x] Alignment data transmitted to paired Aura Imager (via signals)

### Signals for Partner Communication
- [x] `position_changed(position, facing)` - Dowser moved
- [x] `rods_adjusted(left_angle, right_angle)` - Rod positions changed
- [x] `alignment_achieved(quality)` - Good alignment reached
- [x] `alignment_lost()` - Moved out of alignment
- [x] `hold_steady_started()` / `hold_steady_ended()` - Lock state

### Observable State (Anti-Deception)
- [x] All rod positions sync to nearby players (via get_observable_state, get_network_state)
- [x] Facing direction visible to observers (get_facing_direction)
- [x] Third parties can see if Dowser is properly positioned (is_properly_positioned)
- [x] No "private" state - everything the Dowser does is visible

## Technical Notes

**Why Visible State Prevents Lying:**
The Dowser's job is mechanical - hold rods, face the anchor, follow directions. They can't lie about what they "see" because they don't see the evidence (the aura). They could intentionally fumble or delay, but observers can detect that.

**Sabotage Options (for Cultist Dowser):**
- Intentionally poor positioning (visible to observers)
- Slow response to directions (detectable delay)
- "Accidentally" breaking alignment (but can't fake alignment)

**Mock Anchor Points:**
For testing, create `AuraAnchor` node similar to `SpectralAnchor`. Defines:
- Ideal Dowser position and facing
- True aura color/form for the Imager to read

**Rod Physics (Simplified):**
Rods don't need full physics simulation. Use animation curves or procedural movement based on alignment quality. The "crossing" and "spreading" behaviors are feedback to all observers.

## Out of Scope

- 3D model for dowsing rods
- Full physics simulation
- Aura visualization (that's the Imager's domain)
- Evidence collection (Imager handles this)

## Testing

```bash
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_dowsing_rods.gd -gexit
```

Test scenarios:
- Rod state transitions
- Alignment quality detection
- Position/facing constraint validation
- Signal emission for partner communication
- Rod behavior patterns based on alignment
- Hold steady mechanics
- Observable state accessibility

## Implementation Notes

### Files Created
- `src/equipment/aura/dowsing_rods.gd` - DowsingRods equipment class (530 lines)
- `src/equipment/aura/aura_anchor.gd` - Mock anchor for testing (98 lines)
- `tests/test_dowsing_rods.gd` - Comprehensive test suite (57 tests)

### Key Design Decisions
1. **Toggle Mode**: DowsingRods uses TOGGLE use_mode (like Calibrator), not HOLD
2. **Partner Optional for Use**: Unlike standard CooperativeEquipment, Rods can activate
   without a partner. This enables seeking/detection alone, but full alignment requires
   the Imager partner.
3. **SpatialConstraints Integration**: Uses the FW-038a spatial constraint system for
   alignment validation (Dowser facing anchor, Imager behind Dowser)
4. **State Machine**: Four states (IDLE, HELD, SEEKING, ALIGNED) with automatic
   transitions based on anchor detection and alignment quality

### Testing Evidence
```
All 57 tests pass in test_dowsing_rods.gd
gdlint: Success, no problems found
gdformat: Files unchanged (properly formatted)
```

### Notes for FW-038c (Aura Imager)
- Imager should connect to DowsingRods signals:
  - `position_changed` to track Dowser movement
  - `alignment_achieved` to begin resolving aura
  - `hold_steady_started/ended` for reading timing
- Call `on_reading_complete()` when evidence is collected
- Use `get_observable_state()` for third-party visibility
