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
- [ ] `ImagerState` enum: IDLE, POSITIONING, DIRECTING, VIEWING, RECORDING
- [ ] Camera-style equipment with screen on back
- [ ] Screen only clearly visible to operator (viewing angle restriction)
- [ ] Must aim at Dowser's back/rods

### Spatial Requirements
- [ ] Must be behind Dowser (validated by SpatialConstraints)
- [ ] Must have line-of-sight to Dowser's rods
- [ ] Position affects reading quality

### Direction Commands
- [ ] Imager gives verbal directions to Dowser
- [ ] Command types: STEP_LEFT, STEP_RIGHT, STEP_FORWARD, STEP_BACK, RAISE_RODS, LOWER_RODS, HOLD_STEADY
- [ ] Commands are social (voice chat) - not enforced by game
- [ ] Imager sees how directions affect aura resolution

### Aura Visualization
- [ ] Receives alignment data from paired Dowsing Rods
- [ ] Aura pattern resolves as alignment improves:
  - Poor alignment: Fuzzy, indistinct colors
  - Moderate alignment: Colors visible, form unclear
  - Strong alignment: Clear color + form visible
- [ ] Pattern fully reveals when Dowser holds steady at good alignment

### Pattern Reading
- [ ] `get_aura_color()` - entity's aura color
- [ ] `get_aura_form()` - entity's aura form
- [ ] `get_combined_signature()` - full aura description
- [ ] `is_consistent()` - color temperament matches form behavior
- [ ] Resolution quality affects reading clarity

### Evidence Collection
- [ ] Player action to "capture reading"
- [ ] Creates AURA_PATTERN evidence via EvidenceManager
- [ ] Evidence includes both collector IDs (cooperative evidence)
- [ ] Reading quality based on:
  - STRONG: Good alignment, steady hold, clear resolution
  - WEAK: Poor alignment, movement, incomplete resolution

### Cultist Deception
- [ ] Imager can announce wrong color/form
- [ ] Can give misleading directions to waste time
- [ ] Can claim inconsistency when there is none (or vice versa)
- [ ] Can rush the reading to produce weak evidence
- [ ] No gameplay enforcement - pure social deduction

### Third-Party Observation
- [ ] Another player CAN position to see the screen
- [ ] Requires being close and at correct angle
- [ ] Provides counter-play to Imager deception
- [ ] But costs that player's coverage elsewhere

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
