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
