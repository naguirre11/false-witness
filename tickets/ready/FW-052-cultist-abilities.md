---
id: FW-052
title: "Implement Cultist contamination abilities"
epic: CULTIST
priority: high
estimated_complexity: large
dependencies: [FW-051, FW-031]
created: 2026-01-07
---

## Description

Create the Cultist's special abilities to plant false evidence and sabotage investigation. These abilities are the core of the traitor gameplay.

## Acceptance Criteria

- [ ] Ability system framework for Cultist-only actions
- [ ] EMF Spoof (2 uses): Plant false EMF 5 readings, lasts 60s
- [ ] Temperature Manipulation (2 uses): Create freezing zone, lasts 90s
- [ ] Spirit Box Interference (1 use): Force false positive response
- [ ] Fingerprint Planting (2 uses): Leave fake UV traces
- [ ] Equipment Sabotage (1 use): Disable teammate equipment for 30s
- [ ] Ability UI visible only to Cultist
- [ ] 5-second placement animation (can be spotted)
- [ ] Limited uses tracked and synced

## Technical Notes

Per GDD constraints:
- Limited uses prevent spam
- Placement has brief animation (observable)
- Some contaminated evidence has subtle tells
- Using abilities too aggressively creates inconsistencies

False evidence should have ContaminatedEvidence subclass with decay timer.

## Out of Scope

- Social engineering (player skill, not system)
- Discovery consequences
