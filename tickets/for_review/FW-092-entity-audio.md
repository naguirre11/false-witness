---
id: FW-092
title: "Implement entity audio design"
epic: AUDIO
priority: high
estimated_complexity: medium
dependencies: [FW-091, FW-041]
created: 2026-01-07
---

## Description

Create the audio system for entities including hunt audio, ambient presence, and unique entity sound signatures.

## Acceptance Criteria

- [x] Hunt start audio cue (distinctive, terrifying)
- [x] Entity footsteps during hunt
- [x] Ambient entity sounds based on proximity
- [x] Manifestation audio
- [x] Entity-specific audio variations
- [x] Audio occlusion through walls
- [x] Dynamic audio mixing based on entity aggression
- [x] Silence as horror cue (sudden quiet = danger)

## Technical Notes

Per GDD: "Players learn to recognize [hunt audio] instantly."

Each entity type should have unique audio signatures (footstep patterns, vocalizations).

## Out of Scope

- Corporate narrator announcements
- Equipment sounds

## Implementation Notes

### Architecture

Created a dedicated **EntityAudioManager** autoload that listens to EventBus signals and manages all entity audio. This follows the same pattern as FootstepManager but at a system level.

**New Files:**
- `src/core/audio/entity_audio_config.gd` - Resource class for entity-specific audio configuration
- `src/core/audio/entity_audio_manager.gd` - Autoload managing entity audio
- `tests/integration/test_entity_audio_manager.gd` - 30 tests for the audio system

**Modified Files:**
- `src/entity/phantom.gd` - Added audio configuration and integration
- `project.godot` - Added EntityAudioManager autoload

### Key Features Implemented

1. **Hunt Audio System**
   - Warning phase audio triggered by `hunt_warning_started` signal
   - Hunt start stinger on `hunt_started` signal
   - Hunt ambient loop attached to entity during chase
   - Hunt end audio on `hunt_ended` signal
   - Vocalizations during hunt (random intervals)

2. **Entity Footsteps**
   - Automatic footstep playback when entity is moving
   - Different sounds for normal vs hunt states
   - Configurable intervals and pitch variation
   - Uses close-range spatial settings for localized sound

3. **Ambient Proximity Sounds**
   - Distance-based volume calculation
   - Random vocalization chance on proximity checks
   - Fades in/out based on player distance
   - Disabled during hunts (hunt audio takes over)

4. **Manifestation Audio**
   - Plays manifestation sound when `entity_manifesting` emitted
   - Supports entity-specific manifestation sounds

5. **Audio Occlusion**
   - Raycast-based wall detection between player camera and entity
   - 12dB reduction when occluded
   - Updates every 0.2 seconds for performance

6. **Aggression-Based Mixing**
   - Ambient volume modifier increases with aggression phase
   - DORMANT (0dB) → ACTIVE (+1dB) → AGGRESSIVE (+2dB) → FURIOUS (+3dB)

7. **Silence Horror Cue**
   - Triggered during hunt warning phase
   - Fades ambient bus to near-silence
   - Creates tension before hunt starts
   - Restores ambient on hunt end

### EntityAudioConfig Resource

Each entity type can have a unique `EntityAudioConfig` resource with:
- Footstep sounds (normal/hunt)
- Ambient vocalizations
- Hunt vocalizations
- Manifestation sounds
- Behavioral tell sounds
- Hunt warning/start/end sounds
- Kill sound
- Spatial audio settings (unit size, max distance)

### Phantom Integration

Updated Phantom entity to:
- Accept an exported `EntityAudioConfig`
- Create default config if none provided
- Register with EntityAudioManager on spawn

### Test Results

```
Tests: 1730 total (1728 passing, 2 pending)
New EntityAudioManager tests: 30/30 passing
```

### Testing Commands

```powershell
# Run EntityAudioManager tests
./cc_workflow/scripts/run-tests.ps1 -Mode file -File test_entity_audio_manager.gd

# Run full test suite
./cc_workflow/scripts/run-tests.ps1 -Mode full
```

### Future Work

- Add actual audio files to `assets/audio/entity/`
- Create editor-friendly EntityAudioConfig resources per entity type
- Fine-tune spatial audio settings for horror atmosphere
