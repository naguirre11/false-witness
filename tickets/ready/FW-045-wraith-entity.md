---
id: FW-045
title: "Implement Wraith entity"
epic: ENTITY
priority: high
estimated_complexity: medium
dependencies: [FW-044]
created: 2026-01-24
phase: 2
---

## Description

Implement the Wraith entity with its unique behavioral tells and evidence profile. Wraith is the "floater" - it can teleport to players and never leaves footprints in salt.

## Evidence Profile

| Evidence Type | Category |
|---------------|----------|
| EMF_SIGNATURE | Equipment-Derived |
| PRISM_READING | Equipment-Derived (Cooperative) |
| AURA_PATTERN | Equipment-Derived (Cooperative) |

**Overlap with:** Phantom (EMF + PRISM) - differentiate by VISUAL vs AURA

## Acceptance Criteria

### Core Behavior
- [ ] Extends Entity base class
- [ ] Can teleport to random player location (not through walls, but ignores distance)
- [ ] Teleport has visual/audio tell (brief shimmer, whoosh sound)
- [ ] Movement speed: 1.5 m/s (slower than average)

### Unique Behavioral Tells
- [ ] **Salt immunity**: Never triggers salt piles (key identification tell)
- [ ] **Teleport frequency**: Teleports every 30-60s during investigation
- [ ] **Ghost writing avoidance**: Rarely interacts with ghost writing book

### Hunt Behavior
- [ ] Hunt speed: 1.7 m/s
- [ ] Can teleport once during hunt (after 10s)
- [ ] Salt does NOT slow Wraith during hunt

### Evidence Generation
- [ ] Generates EMF level 2-5 at teleport destination
- [ ] Produces spectral anchor for PRISM_READING
- [ ] Produces aura anchor for AURA_PATTERN
- [ ] Does NOT produce VISUAL_MANIFESTATION (shy entity)

### Visual Design
- [ ] Translucent, wispy appearance
- [ ] Floats slightly above ground
- [ ] No visible feet (reinforces salt immunity)

## Technical Notes

Teleportation should:
1. Pick random player
2. Find valid NavMesh position near player (3-8m away)
3. Fade out at current location
4. Fade in at new location
5. Generate EMF at new location

## Out of Scope

- Teleport through locked doors
- Multiple teleports per hunt
