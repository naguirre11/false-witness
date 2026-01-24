---
id: FW-050
title: "Implement Banshee entity"
epic: ENTITY
priority: high
estimated_complexity: medium
dependencies: [FW-044]
created: 2026-01-24
phase: 2
---

## Description

Implement the Banshee entity - a ghost that targets one specific player and only hunts that player. The Banshee's single-target focus is its key identifying tell.

## Evidence Profile

| Evidence Type | Category |
|---------------|----------|
| AURA_PATTERN | Equipment-Derived (Cooperative) |
| VISUAL_MANIFESTATION | Readily-Apparent |
| HUNT_BEHAVIOR | Behavior-Based (Unfalsifiable) |

**Overlap with:** Goryo (AURA + VISUAL) - differentiate by HUNT_BEHAVIOR vs EMF

## Acceptance Criteria

### Core Behavior
- [ ] Extends Entity base class
- [ ] Selects one player as target at match start
- [ ] Target changes only if current target dies
- [ ] Only considers target's sanity for hunt threshold

### Unique Behavioral Tells
- [ ] **Single target focus**: Only hunts one specific player
- [ ] **Ignores others during hunt**: Walks past non-targets
- [ ] **Screaming tell**: Unique scream sound when near target

### Hunt Behavior
- [ ] Hunt threshold based ONLY on target's sanity (not team average)
- [ ] Hunt speed: 1.7 m/s
- [ ] During hunt: Ignores all players except target
- [ ] If target hides successfully: Hunt ends early

### Target Selection
- [ ] Random player selected at investigation start
- [ ] Target persists until death
- [ ] On target death: New random target selected
- [ ] Crucifix only works if placed by target

### Evidence Generation
- [ ] Produces aura anchor (weaker near non-targets)
- [ ] Visual manifestation primarily near target
- [ ] HUNT_BEHAVIOR evidence when players observe targeting

### Audio Design
- [ ] Unique Banshee scream (directional, warns target)
- [ ] Scream audible only to target player
- [ ] Scream occurs 5s before hunt near target

### Visual Design
- [ ] Feminine, wailing appearance
- [ ] Long flowing form
- [ ] Ghostly trails when moving

## Technical Notes

Target selection:
```gdscript
var target_player_id: int = -1

func select_target() -> void:
    var players := NetworkManager.get_players()
    target_player_id = players.keys().pick_random()
```

Hunt sanity check uses only target's sanity, not team average.

## Out of Scope

- Multiple targets
- Target switching during hunt
- Immunity to non-target protection items
