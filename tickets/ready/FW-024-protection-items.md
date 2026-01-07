---
id: FW-024
title: "Implement hunt protection items"
epic: FPS
priority: high
estimated_complexity: medium
dependencies: [FW-022, FW-023]
created: 2026-01-07
---

## Description

Create protection items that provide counterplay against entity hunts. These items add strategic depth and resource management to the investigation.

## Acceptance Criteria

### Crucifix
- [ ] Prevents hunt if entity attempts to hunt within 3m radius
- [ ] 2 charges per crucifix
- [ ] Must be placed BEFORE hunt begins
- [ ] Does not stop active hunts
- [ ] Visual feedback when charge consumed
- [ ] Demon has reduced range (2m)

### Sage Bundle
- [ ] Blinds entity for 5 seconds during active hunt
- [ ] Prevents new hunts for 60 seconds after use
- [ ] 1 charge per bundle
- [ ] Demon: reduced to 30 seconds prevention
- [ ] Smoke visual effect
- [ ] Can be used while moving

### Salt Line
- [ ] Reveals entity footsteps when crossed
- [ ] Slows some entities temporarily
- [ ] 3 uses per salt pile
- [ ] Wraith ignores salt entirely (behavioral tell)
- [ ] Footprint UV-visible for identification

## Technical Notes

Protection items are selected during equipment phase like other equipment. Limited uses create resource management decisions.

Salt is unique - primarily for entity identification (Wraith ignores it) rather than protection. Creates tactical placement decisions.

Items integrate with FW-042 hunt system for trigger prevention and FW-041 behavioral tells.

## Out of Scope

- Equipment variants/upgrades
- Additional protection item types
