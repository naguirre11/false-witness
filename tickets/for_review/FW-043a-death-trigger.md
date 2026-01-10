---
id: FW-043a
title: "Death trigger and Echo transition"
epic: FW-043
priority: high
estimated_complexity: medium
dependencies: [FW-042, FW-041]
created: 2026-01-09
---

## Description

Implement the death mechanic when a player contacts the entity during a hunt, and the initial transition to Echo state. This is the foundation for the Echo system.

## Acceptance Criteria

### Death Trigger
- [x] Player dies on entity contact during active hunt
- [x] Death only occurs during hunt phase (entity contact outside hunt is safe)
- [ ] Death visual feedback (screen effect, camera shake) - DEFERRED to visual polish
- [ ] Death audio feedback (death sound, entity kill sound) - DEFERRED to FW-092
- [x] Body position indicates attack location (ragdoll stubbed - static body for now)

### Death Broadcast
- [x] Death event broadcast to all connected players
- [x] Death location stored for revival mechanic
- [x] Dead player count tracked in game state

### Aggression
- [x] Each death increases entity aggression level
- [x] Aggression affects hunt frequency/duration (uses existing hunt variation hooks)

## Implementation Notes

### Design Decisions (2026-01-09)

1. **Death trigger**: Distance-based (~1m during hunt), consistent with existing HuntDetection system
2. **Ragdoll**: Stubbed for now - leave body as static mesh at death location. Ragdoll deferred to polish phase.

### Files Changed

**src/entity/entity.gd**:
- Added `KILL_RANGE` constant (1.0m)
- Added `player_killed` signal
- Added kill range check in `_process_hunting()`
- Added `_kill_player(player)` method
- Added `_get_player_id(player)` helper

**src/player/player_controller.gd**:
- Added `died` signal
- Added `is_alive`, `is_echo`, `death_position` state vars
- Added `on_killed_by_entity(entity, position)` method
- Dead players skip physics processing
- Updated network state to include death info
- Updated `reset_state()` to revive players

**src/entity/entity_manager.gd**:
- Added `DEATH_AGGRESSION_MULTIPLIER` constant (0.9)
- Added death tracking vars (`_death_locations`, `_death_count`, `_death_aggression_modifier`)
- Added `register_death()`, `get_death_count()`, `get_death_location()`, `get_all_death_locations()`
- Connected to `EventBus.player_died` for automatic registration
- Death modifier reduces hunt cooldowns (cumulative 10% reduction per death)
- Updated `reset()` to clear death tracking

### Test Coverage

Added 22 new tests:
- 7 in `test_entity.gd` (kill mechanics)
- 8 in `test_entity_manager.gd` (death tracking)
- 7 in `test_player_controller.gd` (death handling)

All 1468 tests pass.

## Out of Scope

- Echo movement (FW-043b)
- Echo visibility rules (FW-043b)
- Echo restrictions (FW-043c)
- Revival mechanic (FW-043d)
- Death visual/audio effects (deferred)
