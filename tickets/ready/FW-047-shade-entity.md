---
id: FW-047
title: "Implement Shade entity"
epic: ENTITY
priority: high
estimated_complexity: medium
dependencies: [FW-044]
created: 2026-01-24
phase: 2
---

## Description

Implement the Shade entity - a shy ghost that becomes less active when multiple players are nearby. The Shade is harder to find evidence for but rarely hunts.

## Evidence Profile

| Evidence Type | Category |
|---------------|----------|
| EMF_SIGNATURE | Equipment-Derived |
| GHOST_WRITING | Triggered Test |
| FREEZING_TEMPERATURE | Equipment-Derived |

**Overlap with:** Revenant (GHOST_WRITING + FREEZING) - differentiate by EMF vs HUNT_BEHAVIOR

## Acceptance Criteria

### Core Behavior
- [ ] Extends Entity base class
- [ ] Activity decreases when 2+ players in same room
- [ ] Activity increases when player is alone
- [ ] Prefers dark areas

### Unique Behavioral Tells
- [ ] **Shy behavior**: Will not manifest or interact if 2+ players nearby
- [ ] **Solo hunter**: Only hunts players who are alone
- [ ] **Low activity**: 50% reduced interaction rate compared to baseline

### Hunt Behavior
- [ ] Hunt threshold: Very high (rarely hunts)
- [ ] Hunt speed: 1.5 m/s (slow)
- [ ] Will NOT start hunt if 2+ players in room
- [ ] Hunting player must be alone

### Evidence Generation
- [ ] Generates EMF only when player is alone
- [ ] Ghost writing only responds when single player present
- [ ] Freezing temperature zone appears in favorite room

### Visual Design
- [ ] Dark, shadowy appearance
- [ ] Harder to see than other entities
- [ ] Blends into shadows

## Technical Notes

"Nearby" detection:
- Check for players within 6m radius
- Update activity multiplier based on player count
- Solo = 1.5x activity, 2+ players = 0.3x activity

## Out of Scope

- Special hiding spot interactions
- Light manipulation beyond preference
