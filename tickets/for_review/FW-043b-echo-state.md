---
id: FW-043b
title: "Echo state movement and visibility"
epic: FW-043
priority: high
estimated_complexity: medium
dependencies: [FW-043a]
created: 2026-01-09
---

## Description

Implement the Echo state that dead players enter. Echoes are spectral observers who can move freely but have unique visibility rules regarding the entity and other players.

## Acceptance Criteria

### Echo Movement
- [x] Dead players become Echoes (spectral observers)
- [x] Echo movement: float freely through space
- [x] Echo can pass through walls and solid objects
- [x] Floaty/spectral feel (reduced gravity effect, glide movement)
- [x] Movement speed comparable to living players (not faster for balance)

### Echo Visibility
- [x] Echoes can see entity at ALL times (even when not manifesting)
- [x] Entity visibility for Echoes ignores line of sight checks
- [x] Faint visual outline shows living players where Echoes are
- [x] Echo visual appearance is translucent/ghostly

### Voice Chat (Stub)
- [x] Proximity voice chat hook prepared for Echoes (stub until FW-014)
- [x] Note: Ethereal reverb effect will be added when voice chat is implemented

## Technical Notes

- Echo is likely a separate scene/controller that replaces the player controller on death
- Consider using `CollisionShape3D.disabled = true` for wall passing
- Entity visibility override: `entity.is_visible_to_echo() -> bool` always returns true
- Living player outline of Echoes: shader effect or outline material

### Echo Scene Structure

```
Echo (CharacterBody3D)
├── CollisionShape3D (disabled - no collision)
├── MeshInstance3D (translucent ghost mesh)
├── Camera3D (first-person view)
└── EchoController.gd
```

### Movement Feel

```gdscript
# Floaty movement parameters
const ECHO_GRAVITY := 2.0  # Much lower than normal
const ECHO_FLOAT_SPEED := 3.0
const ECHO_GLIDE_DECEL := 0.95  # Slow deceleration for glide feel
```

## Out of Scope

- Death trigger (FW-043a)
- Echo restrictions on actions (FW-043c)
- Revival mechanic (FW-043d)
- Full voice chat integration (FW-014)

## Implementation Notes

### Files Created

**src/player/echo_controller.gd** - EchoController class:
- `CharacterBody3D` with disabled collision (layer=0, mask=0)
- Floaty movement: `ECHO_GRAVITY=2.0`, `ECHO_FLOAT_SPEED=4.0`, `ECHO_GLIDE_DECEL=0.92`
- Vertical movement with jump (ascend) and crouch (descend) inputs
- `can_see_entity()` and `ignores_entity_visibility()` always return true
- Translucent appearance via `setup_translucent_appearance()` method
- Voice chat stub: `can_use_voice_chat()`, `has_ethereal_voice()`, `get_voice_settings()`
- Network state sync support

**tests/test_echo_controller.gd** - 33 tests covering:
- Initialization, collision, entity visibility
- Movement constants and glide deceleration
- Visual appearance and translucent material
- Voice chat stub methods
- Network state

### Files Modified

**src/entity/entity.gd**:
- Added `is_visible_to(observer: Node) -> bool` method
- Checks for `ignores_entity_visibility()` method on observer
- Checks for `EchoController` type or `is_echo=true` property
- 6 new tests in test_entity.gd

**src/player/player_controller.gd**:
- Added `_transition_to_echo()` - disables physics, spawns Echo
- Added `_spawn_echo_controller()` - creates EchoController with nodes
- Added `_transfer_camera_to_echo()` - switches camera to Echo
- Added `get_echo()` - returns associated EchoController
- 8 new tests in test_player_controller.gd

### Test Evidence

```
Tests             1513
  Passing         1513
Time              52.628s
```

### Architecture

When a player dies:
1. `PlayerController.on_killed_by_entity()` sets `is_echo=true`, emits `died` signal
2. `_transition_to_echo()` disables physics on body, spawns new `EchoController`
3. Camera control transfers to Echo; body remains at death location
4. Echo added to "echoes" group for easy lookup
5. Entity's `is_visible_to(echo)` returns true regardless of manifestation state
