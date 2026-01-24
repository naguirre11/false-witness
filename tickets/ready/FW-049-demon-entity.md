---
id: FW-049
title: "Implement Demon entity"
epic: ENTITY
priority: high
estimated_complexity: medium
dependencies: [FW-044]
created: 2026-01-24
phase: 2
---

## Description

Implement the Demon entity - the most aggressive ghost that hunts frequently and is resistant to protection items. The Demon's aggression is its identifying characteristic.

## Evidence Profile

| Evidence Type | Category |
|---------------|----------|
| FREEZING_TEMPERATURE | Equipment-Derived |
| PHYSICAL_INTERACTION | Readily-Apparent |
| AURA_PATTERN | Equipment-Derived (Cooperative) |

**Overlap with:** Listener (FREEZING + AURA) - differentiate by PHYSICAL vs GHOST_WRITING

## Acceptance Criteria

### Core Behavior
- [ ] Extends Entity base class
- [ ] Highest hunt frequency of all entities
- [ ] Aggressive physical interactions (throws objects harder/faster)

### Unique Behavioral Tells
- [ ] **Early hunting**: Can hunt at higher sanity than other entities
- [ ] **Crucifix resistance**: Reduced crucifix effective radius (2m vs 3m)
- [ ] **Shorter hunt cooldown**: Hunts more frequently

### Hunt Behavior
- [ ] Hunt threshold: Low (hunts even at 70% sanity)
- [ ] Hunt speed: 1.7 m/s
- [ ] Hunt cooldown: 20s (vs 25s baseline)
- [ ] Smudge stick effect reduced to 60s (vs 90s)

### Protection Item Modifiers
- [ ] Crucifix radius: 2m (vs 3m standard)
- [ ] Smudge duration: 60s (vs 90s)
- [ ] Salt: Normal effect

### Evidence Generation
- [ ] Freezing temperature zone
- [ ] Frequent physical interactions (doors, objects)
- [ ] Produces aura anchor for AURA_PATTERN

### Visual Design
- [ ] Imposing, larger appearance
- [ ] Red-tinted visual effects
- [ ] More aggressive animations

## Technical Notes

Hunt threshold calculation:
```gdscript
func can_hunt() -> bool:
    var threshold := 0.7 if entity_type == EntityType.DEMON else 0.5
    return SanityManager.get_team_sanity() <= threshold
```

## Out of Scope

- Immunity to protection items
- Special demon-only abilities
