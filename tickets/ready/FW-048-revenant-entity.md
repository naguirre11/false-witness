---
id: FW-048
title: "Implement Revenant entity"
epic: ENTITY
priority: high
estimated_complexity: medium
dependencies: [FW-044]
created: 2026-01-24
phase: 2
---

## Description

Implement the Revenant entity - a slow-moving ghost that becomes extremely fast when it sees a player during a hunt. The speed differential is its key identifying tell.

## Evidence Profile

| Evidence Type | Category |
|---------------|----------|
| FREEZING_TEMPERATURE | Equipment-Derived |
| GHOST_WRITING | Triggered Test |
| HUNT_BEHAVIOR | Behavior-Based (Unfalsifiable) |

**Overlap with:** Shade (GHOST_WRITING + FREEZING) - differentiate by HUNT_BEHAVIOR vs EMF

## Acceptance Criteria

### Core Behavior
- [ ] Extends Entity base class
- [ ] Very slow when not chasing (0.5 m/s)
- [ ] Standard interaction rates

### Unique Behavioral Tells
- [ ] **Speed differential**: Dramatic speed change is primary identification
- [ ] **Slow patrol**: Noticeably slow movement during investigation
- [ ] **Aggressive pursuit**: Relentless once target acquired

### Hunt Behavior
- [ ] Hunt speed (no LOS): 0.5 m/s (very slow)
- [ ] Hunt speed (with LOS): 3.0 m/s (fastest in game)
- [ ] Speed changes within 0.5s of gaining/losing LOS
- [ ] Hunt duration: 50% longer than baseline

### Evidence Generation
- [ ] Freezing temperature in favorite room
- [ ] Responds to ghost writing book
- [ ] HUNT_BEHAVIOR evidence recorded when players observe speed change

### Visual Design
- [ ] Heavy, lumbering appearance
- [ ] Ground shake effect when running fast
- [ ] Intense breathing/growling audio when sprinting

## Technical Notes

Speed transition:
```
var target_speed := 3.0 if has_los_to_target else 0.5
current_speed = lerp(current_speed, target_speed, 0.1)
```

The extreme speed makes hiding essential - running is not viable.

## Out of Scope

- Breaking hiding spot doors faster
- Unique kill animations
