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
- [ ] `RodState` enum: IDLE, HELD, SEEKING, ALIGNED
- [ ] Rods held loosely in both hands, extended forward
- [ ] Rod angle positions (left rod, right rod) as normalized values
- [ ] Rod positions visible to all nearby players (public state)

### Physical Response
- [ ] Rods respond to proximity/alignment with anchor point
- [ ] `RodBehavior` patterns:
  - NEUTRAL: Rods parallel, no pull
  - CROSSING: Rods cross inward (strong signal)
  - SPREADING: Rods spread outward (weak signal)
  - TWITCHING: Rods oscillate (interference)
- [ ] Response intensity based on alignment quality

### Positioning Mechanics
- [ ] Dowser must face anchor point (validated by SpatialConstraints)
- [ ] Step movement in response to Imager directions
- [ ] Height adjustment (raise/lower rods)
- [ ] "Hold steady" action to lock position for reading

### Alignment Detection
- [ ] Each anchor point has ideal Dowser position
- [ ] Alignment quality: NONE, WEAK, MODERATE, STRONG
- [ ] Quality based on position accuracy and stability
- [ ] Alignment data transmitted to paired Aura Imager

### Signals for Partner Communication
- [ ] `position_changed(position, facing)` - Dowser moved
- [ ] `rods_adjusted(left_angle, right_angle)` - Rod positions changed
- [ ] `alignment_achieved(quality)` - Good alignment reached
- [ ] `alignment_lost()` - Moved out of alignment
- [ ] `hold_steady_started()` / `hold_steady_ended()` - Lock state

### Observable State (Anti-Deception)
- [ ] All rod positions sync to nearby players
- [ ] Facing direction visible to observers
- [ ] Third parties can see if Dowser is properly positioned
- [ ] No "private" state - everything the Dowser does is visible

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
