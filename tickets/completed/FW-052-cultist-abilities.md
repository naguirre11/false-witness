---
id: FW-052
title: "Implement Cultist contamination abilities with decay and hunt manipulation"
epic: CULTIST
priority: high
estimated_complexity: large
dependencies: [FW-051, FW-031, FW-042]
created: 2026-01-07
updated: 2026-01-07
---

## Description

Create the Cultist's special abilities including evidence contamination with decay mechanics and hunt manipulation. Contaminated evidence degrades over time, giving attentive players a chance to notice inconsistencies.

## Acceptance Criteria

### Ability Framework
- [ ] Ability system for Cultist-only actions
- [ ] Ability UI visible only to Cultist
- [ ] 5-second placement animation (can be spotted)
- [ ] Limited uses tracked and synced
- [ ] Abilities disabled after Cultist discovered or dies

### Evidence Contamination Abilities
- [ ] EMF Spoof (2 uses): Plant false EMF_SIGNATURE readings
- [ ] Temperature Manipulation (2 uses): Create false FREEZING_TEMPERATURE zone
- [ ] Prism Interference (1 use): Corrupt PRISM_READING data
- [ ] Aura Disruption (2 uses): Plant false AURA_PATTERN trails

### Evidence Decay System
- [ ] **Planted (0-60s)**: Full strength, identical to real evidence
- [ ] **Unstable (60-120s)**: Shows inconsistencies (flickers, fluctuates)
- [ ] **Degraded (120-180s)**: Clearly inconsistent, obvious tells
- [ ] **Expired (180s+)**: False evidence disappears entirely

### Decay Visual/Audio Tells
| Evidence | Stable | Degraded |
|----------|--------|----------|
| EMF Spoof | Steady Level 5 | Flickers between levels; resets randomly |
| Temperature | Consistent freezing | Swings ±5° every few seconds |
| Prism Interference | Consistent shape/color | Shape flickers; color shifts erratically |
| Aura Disruption | Clear aura trail | Trail fades; direction inconsistent |

### Hunt Manipulation Abilities
- [ ] **Provocation (1 use)**: Force immediate hunt regardless of sanity
  - Observable tell: brief electrical surge on equipment
  - If teammates notice hunt at high sanity, suspicion rises
- [ ] **False Alarm (1 use)**: Trigger hunt warning signs without actual hunt
  - Wastes team resources (hiding, sage)
  - Slightly different flicker pattern than real hunts

### Equipment Sabotage
- [ ] Equipment Sabotage (1 use): Disable teammate equipment for 30s

## Technical Notes

**Strategic implications:**
- For Investigators: Re-check evidence over time. Unstable readings suggest contamination.
- For Cultists: Timing matters. Plant when team is close to decision, not at investigation start. Can refresh contamination (costs additional charges).

ContaminatedEvidence subclass tracks:
- Creation timestamp
- Current decay state
- Source player (for post-game reveal)

## Out of Scope

- Social engineering (player skill)
- Discovery voting mechanics (FW-053)

## Implementation Notes (Ralph - 2026-01-21)

### Files Created

**Core Systems:**
- `src/cultist/cultist_ability.gd` - Base ability class (~185 lines)
- `src/cultist/contaminated_evidence.gd` - Decay-tracking evidence (~200 lines)
- `src/cultist/cultist_placement_controller.gd` - 5s placement animation (~320 lines)

**Ability Implementations:**
- `src/cultist/abilities/emf_spoof.gd` (~100 lines)
- `src/cultist/abilities/temperature_manipulation.gd` (~110 lines)
- `src/cultist/abilities/prism_interference.gd` (~115 lines)
- `src/cultist/abilities/aura_disruption.gd` (~130 lines)
- `src/cultist/abilities/provocation.gd` (~75 lines)
- `src/cultist/abilities/false_alarm.gd` (~80 lines)
- `src/cultist/abilities/equipment_sabotage.gd` (~75 lines)

**Contaminated Sources (with decay visual tells):**
- `src/cultist/contaminated_emf_source.gd` (~230 lines)
- `src/cultist/contaminated_temperature_zone.gd` (~230 lines)
- `src/cultist/contaminated_spectral_anchor.gd` (~255 lines)
- `src/cultist/contaminated_aura_anchor.gd` (~280 lines)

**UI:**
- `src/ui/cultist_ability_bar.gd` + scene (~400 lines)

**Tests:**
- `tests/unit/test_contaminated_evidence.gd` (23 tests)
- `tests/integration/test_cultist_abilities.gd` (36 tests)

### Key Implementation Details
- CultistAbility extends Resource with charges, cooldowns, activation timing
- ContaminatedEvidence extends Evidence with decay state tracking
- Decay calculated via `get_decay_state()` based on Unix timestamps
- Contaminated sources join same groups as legitimate sources (seamless equipment integration)
- Server-authoritative charge tracking in CultistManager
- EventBus signals: `contaminated_evidence_planted`, `equipment_sabotaged`, `cultist_placement_*`

### Test Verification
```
./cc_workflow/scripts/run-tests.ps1 -Mode file -File test_contaminated_evidence.gd
Result: 23/23 passed

./cc_workflow/scripts/run-tests.ps1 -Mode file -File test_cultist_abilities.gd
Result: 36/36 passed
```

### Acceptance Criteria Status

**Ability Framework:**
- [x] Ability system for Cultist-only actions
- [x] Ability UI visible only to Cultist
- [x] 5-second placement animation (can be spotted)
- [x] Limited uses tracked and synced
- [x] Abilities disabled after Cultist discovered or dies

**Evidence Contamination Abilities:**
- [x] EMF Spoof (2 uses)
- [x] Temperature Manipulation (2 uses)
- [x] Prism Interference (1 use)
- [x] Aura Disruption (2 uses)

**Evidence Decay System:**
- [x] Planted (0-60s): Full strength
- [x] Unstable (60-120s): Shows inconsistencies
- [x] Degraded (120-180s): Clearly inconsistent
- [x] Expired (180s+): Evidence disappears

**Decay Visual Tells:**
- [x] EMF: Steady -> Flickers -> Resets
- [x] Temperature: Consistent -> Swings ±5°
- [x] Prism: Consistent -> Shape/color shifts
- [x] Aura: Clear -> Fades/inconsistent

**Hunt Manipulation:**
- [x] Provocation (1 use): Force immediate hunt
- [x] False Alarm (1 use): Trigger warning without hunt

**Equipment Sabotage:**
- [x] Equipment Sabotage (1 use): Disable for 30s
