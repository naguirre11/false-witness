---
id: FW-055
title: "Implement Mare entity"
epic: ENTITY
priority: high
estimated_complexity: medium
dependencies: [FW-044]
created: 2026-01-24
phase: 2
---

## Description

Implement the Mare entity - a ghost that thrives in darkness and has power over lights. The Mare turns off lights, hunts more in dark rooms, and is weakened by light.

## Evidence Profile

| Evidence Type | Category |
|---------------|----------|
| PRISM_READING | Equipment-Derived (Cooperative) |
| AURA_PATTERN | Equipment-Derived (Cooperative) |
| GHOST_WRITING | Triggered Test |

**Overlap with:** Poltergeist (PRISM + GHOST_WRITING) - differentiate by AURA vs PHYSICAL

## Acceptance Criteria

### Core Behavior
- [ ] Extends Entity base class
- [ ] Prefers dark rooms for favorite room selection
- [ ] Turns off lights frequently
- [ ] Reduced activity when lights are on

### Unique Behavioral Tells
- [ ] **Light aversion**: Will turn off lights within 30s of them being turned on
- [ ] **Dark preference**: 2x activity in dark rooms, 0.5x in lit rooms
- [ ] **Light switch targeting**: Prioritizes light switches over other interactions

### Light Manipulation
- [ ] Can turn off lights from up to 8m away
- [ ] Fuse box targeting: Will trip breakers periodically
- [ ] Cannot turn lights ON (only off)
- [ ] Lights flicker before turning off (warning tell)

### Hunt Behavior
- [ ] Hunt speed: 1.7 m/s
- [ ] Hunt threshold: Lower in dark rooms (hunts at higher sanity)
- [ ] Hunt threshold: Higher in lit rooms (rarely hunts)
- [ ] Will NOT start hunt if player is in fully lit room

### Evidence Generation
- [ ] Produces spectral anchor for PRISM_READING
- [ ] Produces aura anchor for AURA_PATTERN
- [ ] Responds to ghost writing book

### Counterplay
- [ ] **Light protection**: Keeping lights on prevents hunts
- [ ] **Candles work**: Any light source provides protection
- [ ] Flashlight pointed at Mare slows it during hunt

### Visual Design
- [ ] Dark, shadowy form
- [ ] Glowing eyes visible in darkness
- [ ] Dissipates slightly in bright light

## Technical Notes

Light level detection:
```gdscript
func get_room_light_level(room: Node3D) -> float:
    var lights := room.get_node("Lights").get_children()
    var lit_count := lights.filter(func(l): return l.visible).size()
    return float(lit_count) / float(lights.size())
```

## Out of Scope

- Destroying light sources
- Complete immunity to light
- Nightmare/sleep mechanics
