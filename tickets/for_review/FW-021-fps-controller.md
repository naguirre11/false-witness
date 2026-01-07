---
id: FW-021
title: "Create first-person player controller"
epic: FPS
priority: high
estimated_complexity: medium
dependencies: [FW-001]
created: 2026-01-07
completed: 2026-01-07
---

## Description

Implement the core first-person character controller with smooth movement, mouse look, and basic physics interaction.

## Acceptance Criteria

- [x] WASD movement with configurable speed
- [x] Mouse look with sensitivity settings
- [x] Sprint (shift) with stamina cost
- [x] Crouch (ctrl) for hiding
- [x] Smooth acceleration/deceleration
- [x] Collision with environment
- [x] Footstep sounds tied to movement
- [x] Head bob (optional, configurable)
- [x] Works in networked context (local prediction)

## Technical Notes

Player scene structure:
```
Player (CharacterBody3D)
  - CollisionShape3D
  - Head (Node3D) - pivot for look
    - Camera3D
    - EquipmentHolder (Node3D)
  - FootstepPlayer (AudioStreamPlayer3D)
```

## Out of Scope

- Equipment/item system
- Interaction system
- Death/respawn

---

## Implementation Notes

### Files Created

| File | Purpose |
|------|---------|
| `src/player/player_controller.gd` | Full FPS controller with movement, look, sprint, crouch, head bob, footsteps |
| `scenes/player/player.tscn` | Player scene with correct node structure |
| `tests/test_player_controller.gd` | 45 unit tests covering all player controller functionality |

### PlayerController Features

**Movement:**
- WASD with smooth acceleration (10.0) and deceleration (12.0)
- Walk speed: 4.0 m/s, Sprint speed: 7.0 m/s, Crouch speed: 2.0 m/s
- Air control reduced to 30%
- Gravity applied when not on floor

**Mouse Look:**
- Horizontal rotation rotates body, vertical rotates head only
- Configurable sensitivity (default 0.003)
- Pitch clamped to +/- 89 degrees

**Sprint System:**
- Left Shift to sprint
- Stamina pool (100 max, drains at 20/s, regens at 15/s after 1s delay)
- Minimum 10 stamina required to start sprinting
- Cannot sprint while crouching or in air

**Crouch System:**
- Left Ctrl to crouch
- Standing height: 1.8m, Crouch height: 1.0m
- Smooth height transition (10.0 speed)
- Raycast check prevents standing when obstructed
- Crouching stops sprinting

**Head Bob:**
- Optional, enabled by default
- Frequency-based sine wave (2.0 Hz, 0.05m amplitude)
- Sprint multiplier: 1.4x speed and amplitude
- Crouch reduces: 0.7x speed, 0.5x amplitude
- Smoothly resets when stopped

**Footsteps:**
- Timer-based footstep signal emission
- Intervals: Walk 0.5s, Sprint 0.35s, Crouch 0.7s
- `footstep` signal for audio system integration
- Optional AudioStreamPlayer3D for direct playback

**Network Support:**
- `get_network_state()` / `apply_network_state()` for sync
- `is_local_player` flag controls input handling
- `set_input_enabled()` for disabling during cutscenes/death
- `teleport()` and `reset_state()` for spawn/round reset

### Signals

| Signal | Parameters | Purpose |
|--------|------------|---------|
| `stamina_changed` | `current: float, maximum: float` | HUD stamina bar |
| `crouched` | `is_crouching: bool` | Animation/sound state |
| `footstep` | none | Audio system trigger |

### Test Coverage

45 tests covering:
- Initialization (4 tests)
- Speed calculations (4 tests)
- Stamina system (4 tests)
- Crouch mechanics (5 tests)
- Movement detection (5 tests)
- Input control (2 tests)
- Network state (7 tests)
- Teleport (3 tests)
- Reset state (5 tests)
- Configuration validation (6 tests)

### Testing Evidence

```
Scripts           6
Tests             112
  Passing         112
Asserts           195
Time              3.747s

---- All tests passed! ----
```
