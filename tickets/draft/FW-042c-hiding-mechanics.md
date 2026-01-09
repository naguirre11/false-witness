---
id: FW-042c
title: "Hunt hiding mechanics"
epic: ENTITY
priority: high
estimated_complexity: medium
dependencies: [FW-042b]
created: 2026-01-09
updated: 2026-01-09
parent_ticket: FW-042
---

## Description

Implement hiding mechanics that allow players to break line of sight and evade the entity during hunts. This includes hiding spots (closets, lockers), entity search behavior, and the tactical interplay between hiding and being found.

## Acceptance Criteria

- [ ] Hiding spots (closets, lockers) defined as Area3D zones
- [ ] Players inside hiding spots block entity entry/detection
- [ ] Closing hiding spot door breaks line of sight
- [ ] Entity searches nearby hiding spot area for ~5 seconds
- [ ] Entity moves on if player not found after search
- [ ] Breaking line of sight resets entity tracking
- [ ] Entity-specific hiding variations hook (some ignore spots)

## Technical Notes

**Implementation Location**: New `src/entity/hiding_spot.gd` + Entity.gd modifications

**HidingSpot Component**:
```gdscript
class_name HidingSpot extends Area3D

@export var blocks_entity_entry := true
@export var search_duration := 5.0

func get_occupants() -> Array[int]:  # player_ids inside
func is_door_closed() -> bool:
```

**Entity Search Behavior**:
1. Entity approaches hiding spot
2. `blocks_entity_entry = true` prevents pathfinding inside
3. Entity waits at entrance for `search_duration`
4. If player not detected (door closed = no LoS), entity moves on
5. If player opens door or makes noise, entity detects

**Entity Integration**:
- `can_ignore_hiding_spots() -> bool` - Virtual method for entity variations
- Entity pathfinding avoids HidingSpot volumes unless ignoring

**Player Awareness**:
- Player sees "Hiding" indicator when in spot with door closed
- Player can peek (open door slightly) at risk

## Out of Scope

- Actual closet/locker 3D models (map implementation)
- Door interaction system (FW-022 handles that)
- Entity-specific variations beyond the hook (FW-042d)
