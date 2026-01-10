---
id: FW-091
title: "Establish audio system foundation"
epic: AUDIO
priority: high
estimated_complexity: medium
dependencies: [FW-001]
created: 2026-01-07
---

## Description

Set up the core audio system including spatial audio, audio buses, and the foundation for environmental and entity sounds.

## Acceptance Criteria

- [x] Audio bus structure (Master, SFX, Music, Voice, Ambient)
- [x] Spatial audio configuration for 3D sounds
- [x] AudioManager autoload for playing sounds
- [x] Sound pooling for frequently played sounds
- [x] Volume controls per bus
- [x] Footstep audio system tied to player movement
- [x] Surface-based footstep variation

## Technical Notes

Per GDD: "Audio is the primary horror delivery mechanism."

Use AudioStreamPlayer3D for spatial sounds. Configure appropriate falloff curves for horror atmosphere.

## Out of Scope

- Entity-specific sounds
- Voice chat system (Network epic)
- Music/soundtrack

## Implementation Notes

### Files Created

- `default_bus_layout.tres` - Audio bus configuration (Master, SFX, Music, Voice, Ambient)
- `src/core/audio_manager.gd` - AudioManager autoload for centralized audio control
- `src/core/audio/surface_audio.gd` - SurfaceAudio resource for surface-based footstep configuration
- `src/core/audio/footstep_manager.gd` - FootstepManager component for player footstep handling
- `tests/test_audio_manager.gd` - Tests for AudioManager (33 tests)
- `tests/test_surface_audio.gd` - Tests for SurfaceAudio (21 tests)
- `tests/test_footstep_manager.gd` - Tests for FootstepManager (16 tests)

### Files Modified

- `project.godot` - Added AudioManager autoload and audio bus resource path
- `scenes/player/player.tscn` - Added FootstepManager node with footstep signal connection

### AudioManager Features

- Volume control (dB and linear) per bus with clamping
- Bus muting
- Sound pooling with configurable pool size
- One-shot 2D sounds (non-spatial)
- One-shot 3D spatial sounds at position
- Attached 3D sounds that follow nodes
- Spatial audio presets: close-range, medium-range, long-range
- Auto-cleanup of finished sounds

### FootstepManager Features

- Surface detection via raycast (checks for `surface_type` metadata on colliders)
- Surface type hierarchy: DEFAULT, WOOD, CONCRETE, CARPET, TILE, METAL, GRASS, GRAVEL, WATER
- Volume modifiers per surface type
- Crouch volume reduction
- Sprint volume boost
- Pitch variation for natural sound
- Configurable SurfaceAudio resources per surface type

### Usage

To configure a surface for footsteps, add metadata to the StaticBody3D or parent node:
```gdscript
node.set_meta("surface_type", "WOOD")  # or SurfaceAudio.SurfaceType.WOOD
```

To play sounds via AudioManager:
```gdscript
# 2D sound
AudioManager.play_sound(stream, "SFX", -5.0)

# 3D spatial sound
AudioManager.play_sound_3d(stream, position, "SFX", 0.0)

# Attached to node
AudioManager.play_sound_attached(stream, node, "SFX")
```

### Test Commands

```bash
# Run all audio tests
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=test_audio_manager.gd -gtest=test_surface_audio.gd -gtest=test_footstep_manager.gd -gexit

# Lint
gdlint src/core/audio_manager.gd src/core/audio/

# Format check
gdformat --check src/core/audio_manager.gd src/core/audio/
```

All 1683 tests pass (including 70 new audio tests).
