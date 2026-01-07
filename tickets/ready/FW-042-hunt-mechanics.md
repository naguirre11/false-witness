---
id: FW-042
title: "Implement entity hunt mechanics"
epic: ENTITY
priority: high
estimated_complexity: large
dependencies: [FW-041]
created: 2026-01-07
---

## Description

Create the hunt system where the entity actively seeks and can kill players. Hunts create tension and time pressure, forcing players to balance evidence collection with survival.

## Acceptance Criteria

- [ ] Hunt mode trigger conditions (time-based, activity-based)
- [ ] Hunt announcement (audio cue, visual effects)
- [ ] Entity pathfinding toward players during hunt
- [ ] Voice activity detection attracts entity
- [ ] Line-of-sight detection
- [ ] Player death on entity contact during hunt
- [ ] Hunt duration and cooldown timers
- [ ] Hiding spots break entity pursuit

## Technical Notes

Hunt counterplay from GDD:
- Hide in closets/lockers
- Stay silent (stop talking)
- Break line of sight
- Stay still in dark areas

Entity can "hear" voice activity - makes voice chat risky during hunts.

## Out of Scope

- Death/respawn system (separate ticket)
- Specific entity hunt variations
