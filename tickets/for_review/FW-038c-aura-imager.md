---
id: FW-038c
title: "Aura Imager Unit"
epic: EVIDENCE
parent: FW-038
priority: high
estimated_complexity: medium
dependencies: [FW-038a, FW-038b]
created: 2026-01-09
---

## Description

Implement the Aura Imager, the "secret operator" equipment for the Aura system. The Imager positions behind the Dowser, aims at their back/rods, and reads the aura pattern that resolves on their screen. Only the Imager can see the screen clearly, making them the sole source of truth for the evidence.

**Trust Dynamic**: The Imager CAN lie - they alone see the screen, they control the direction commands, and they interpret the results. A third player can watch over their shoulder (but this costs coverage elsewhere).

## Acceptance Criteria

### Imager State
- [x] `ImagerState` enum: IDLE, POSITIONING, DIRECTING, VIEWING, RECORDING
- [x] Camera-style equipment with screen on back
- [x] Screen only clearly visible to operator (viewing angle restriction)
- [x] Must aim at Dowser's back/rods

### Spatial Requirements
- [x] Must be behind Dowser (validated by SpatialConstraints)
- [x] Must have line-of-sight to Dowser's rods
- [x] Position affects reading quality

### Direction Commands
- [x] Imager gives verbal directions to Dowser
- [x] Command types: STEP_LEFT, STEP_RIGHT, STEP_FORWARD, STEP_BACK, RAISE_RODS, LOWER_RODS, HOLD_STEADY
- [x] Commands are social (voice chat) - not enforced by game
- [x] Imager sees how directions affect aura resolution

### Aura Visualization
- [x] Receives alignment data from paired Dowsing Rods
- [x] Aura pattern resolves as alignment improves:
  - Poor alignment: Fuzzy, indistinct colors
  - Moderate alignment: Colors visible, form unclear
  - Strong alignment: Clear color + form visible
- [x] Pattern fully reveals when Dowser holds steady at good alignment

### Pattern Reading
- [x] `get_aura_color()` - entity's aura color
- [x] `get_aura_form()` - entity's aura form
- [x] `get_combined_signature()` - full aura description
- [x] `is_consistent()` - color temperament matches form behavior
- [x] Resolution quality affects reading clarity

### Evidence Collection
- [x] Player action to "capture reading"
- [x] Creates AURA_PATTERN evidence via EvidenceManager
- [x] Evidence includes both collector IDs (cooperative evidence)
- [x] Reading quality based on:
  - STRONG: Good alignment, steady hold, clear resolution
  - WEAK: Poor alignment, movement, incomplete resolution

### Cultist Deception
- [x] Imager can announce wrong color/form
- [x] Can give misleading directions to waste time
- [x] Can claim inconsistency when there is none (or vice versa)
- [x] Can rush the reading to produce weak evidence
- [x] No gameplay enforcement - pure social deduction

### Third-Party Observation
- [x] Another player CAN position to see the screen
- [x] Requires being close and at correct angle
- [x] Provides counter-play to Imager deception
- [x] But costs that player's coverage elsewhere

## Technical Notes

**Why Imager Can Lie:**
The Imager alone sees the screen. They verbally report what they "see." Other players must trust their report or dedicate someone to watch over their shoulder.

**Cultist Strategies (as Imager):**
- Report false color/form
- Give bad directions to delay or prevent good readings
- Claim "I can't get it to resolve" when it already has
- Rush readings to produce weak evidence

**Counter-Strategies:**
- Assign suspected player to Dowser role (neutralizes lying ability)
- Third player watches Imager's screen (but costs coverage)
- Cross-reference Aura Pattern with Hunt Behavior later

**Evidence Integration:**
```gdscript
var evidence = EvidenceManager.collect_cooperative_evidence(
    EvidenceEnums.EvidenceType.AURA_PATTERN,
    dowser_player_id,
    imager_player_id,
    location,
    reading_quality
)
```

**Resolution Mechanic:**
The aura starts as noise/static. As Dowser alignment improves:
1. Colors begin to coalesce
2. Form begins to emerge
3. Full pattern visible when alignment is strong + steady

## Out of Scope

- 3D model for Aura Imager
- Actual visual shader effects for screen
- Voice chat integration for directions (use existing system)
- Entity-specific aura definitions (part of entity system)

## Testing

```bash
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_aura_imager.gd -gexit
```

Test scenarios:
- Cannot activate without Dowser partner
- Spatial constraint validation (behind Dowser)
- Receives alignment data from Dowser
- Aura resolution based on alignment quality
- Evidence created with both collector IDs
- Quality assessment based on alignment and stability
- Consistency detection (color matches form category)
- Third-party observation angle detection

## Implementation Notes

**Files Created:**
- `src/equipment/aura/aura_imager.gd`: AuraImager class extending CooperativeEquipment
- `tests/test_aura_imager.gd`: 64 comprehensive tests covering all acceptance criteria

**Key Implementation Details:**

1. **State Machine**: ImagerState enum (IDLE, POSITIONING, DIRECTING, VIEWING, RECORDING) with signals for state transitions

2. **Spatial Validation**: Uses SpatialConstraints from FW-038a to validate Imager is behind Dowser with proper line-of-sight. Positioning check runs every 0.1s when active.

3. **Resolution System**: Aura resolution smoothly transitions based on Dowser's alignment quality:
   - COLOR_VISIBLE_THRESHOLD = 0.3 (colors start appearing)
   - FORM_VISIBLE_THRESHOLD = 0.5 (form starts appearing)
   - FULL_CLARITY_THRESHOLD = 0.7 (full aura visible)
   - Hold steady by Dowser provides +30% resolution bonus

4. **Direction Commands**: DirectionCommand enum provides social/voice commands. These are purely for human coordination - game does not enforce them.

5. **Evidence Collection**: `start_capture()` begins recording, `create_evidence()` produces a dictionary with:
   - Both collector IDs (Dowser and Imager)
   - Quality (STRONG if good alignment + hold steady complete, WEAK otherwise)
   - Color, form, and consistency flag

6. **Third-Party Observation**: `can_observer_see_screen()` validates observer is close (<2m) and at correct viewing angle (behind/beside Imager, not in front)

7. **Observable State**: The `get_observable_state()` method intentionally excludes screen content (color/form/resolution) - only the Imager sees the screen. This enforces the asymmetric trust dynamic.

8. **Dowser Signal Connections**: Automatically connects to partner Dowser's alignment_achieved, alignment_lost, and hold_steady_started signals.

**Test Evidence:**
```bash
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_aura_imager.gd -gexit
# Result: 64/64 tests passed
```

**Design Decisions:**
- Toggle mode equipment (use() to activate, use() again to deactivate)
- Requires Dowser partner to activate (unlike Dowser which can SEEK alone)
- Network state includes resolution but NOT color/form (each client sees their own screen)
- Cultist deception is purely social - no gameplay detection or prevention
