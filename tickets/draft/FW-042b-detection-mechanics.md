---
id: FW-042b
title: "Hunt detection mechanics"
epic: ENTITY
priority: high
estimated_complexity: medium
dependencies: [FW-041, FW-042a]
created: 2026-01-09
updated: 2026-01-09
parent_ticket: FW-042
---

## Description

Implement the detection system that allows the entity to find and track players during hunts. This includes distance-based detection, line-of-sight checks, and modifiers for player behavior (electronics, voice activity).

## Acceptance Criteria

- [ ] Base detection radius of 7 meters
- [ ] Electronics in hand modifier: +3m detection (10m total)
- [ ] Voice activity modifier: +5m detection (12m total)
- [ ] Line-of-sight detection triggers chase (aware state)
- [ ] Entity tracks last known position when LoS is broken
- [ ] Entity transitions to unaware (searching) when target lost
- [ ] Detection modifiers stack appropriately

## Technical Notes

**Implementation Location**: New file `src/entity/hunt_detection.gd` + Entity.gd modifications

**Detection Constants**:
```gdscript
const BASE_DETECTION_RADIUS := 7.0
const ELECTRONICS_DETECTION_BONUS := 3.0
const VOICE_DETECTION_BONUS := 5.0
```

**Line-of-Sight Check**:
- Use raycast from entity eye position to player
- Consider occlusion by walls/doors
- Ignore transparent surfaces (glass)

**Player State Queries**:
- Need method to check if player has electronics equipped
- Need method to check if player is using voice (from VoiceChat system)

**Entity Integration**:
- `_process_hunting_behavior()` calls detection checks
- Updates `_is_aware_of_target` based on LoS
- Updates `_last_known_target_position` when losing LoS
- Adjusts movement speed based on awareness

## Out of Scope

- Hiding spot detection (FW-042c)
- Entity-specific detection variations (FW-042d)
- Voice chat integration (depends on FW-014)
