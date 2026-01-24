---
id: FW-054
title: "Implement Poltergeist entity"
epic: ENTITY
priority: high
estimated_complexity: medium
dependencies: [FW-044, FW-040b]
created: 2026-01-24
phase: 2
---

## Description

Implement the Poltergeist entity - a ghost that manipulates physical objects aggressively. The Poltergeist throws multiple objects simultaneously and drains sanity through chaos.

## Evidence Profile

| Evidence Type | Category |
|---------------|----------|
| PHYSICAL_INTERACTION | Readily-Apparent |
| PRISM_READING | Equipment-Derived (Cooperative) |
| GHOST_WRITING | Triggered Test |

**Overlap with:** Mare (PRISM + GHOST_WRITING) - differentiate by PHYSICAL vs AURA

## Acceptance Criteria

### Core Behavior
- [ ] Extends Entity base class
- [ ] Highest physical interaction rate of all entities
- [ ] Can throw multiple objects simultaneously (up to 3)
- [ ] Throws objects with more force than other entities

### Unique Behavioral Tells
- [ ] **Multi-throw**: Can throw 2-3 objects at once (unique ability)
- [ ] **Chaos sanity drain**: Each thrown object drains 2% sanity (vs 1% baseline)
- [ ] **Room clearing**: Will throw ALL throwable objects in room during events

### Physical Interaction Details
- [ ] Throw velocity: 8 m/s (vs 5 m/s baseline)
- [ ] Throw frequency: Every 5-10s during active periods
- [ ] Can open/close multiple doors simultaneously
- [ ] Lights flicker more intensely

### Hunt Behavior
- [ ] Hunt speed: 1.7 m/s
- [ ] Throws objects at player during hunt
- [ ] Objects can stun player briefly (0.5s) if hit
- [ ] More active in rooms with many throwable objects

### Evidence Generation
- [ ] Frequent PHYSICAL_INTERACTION evidence
- [ ] Produces spectral anchor for PRISM_READING
- [ ] Responds to ghost writing book

### Weakness
- [ ] **Empty room weakness**: Cannot hunt in rooms with no throwable objects
- [ ] Reduced activity in sparse environments

### Visual Design
- [ ] Chaotic, fragmented appearance
- [ ] Multiple ghostly "arms" during manifestation
- [ ] Objects glow briefly before being thrown

## Technical Notes

Multi-throw implementation:
```gdscript
func throw_objects(count: int = 1) -> void:
    var throwables := get_nearby_throwables()
    for i in range(min(count, throwables.size())):
        throw_object(throwables[i])
        await get_tree().create_timer(0.1).timeout
```

## Out of Scope

- Throwing players
- Breaking objects permanently
- Stacking objects
