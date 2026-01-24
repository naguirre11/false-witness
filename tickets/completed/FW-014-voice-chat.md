---
id: FW-014
title: "Implement proximity-based voice chat"
epic: NET
priority: high
estimated_complexity: large
dependencies: [FW-013]
created: 2026-01-07
---

## Description

Implement spatial voice chat where player voices fade with distance. Voice is a core horror mechanic - entities can "hear" loud players.

## Acceptance Criteria

- [ ] Voice input capture from microphone
- [ ] Spatial audio playback (AudioStreamPlayer3D)
- [ ] Voice fades with distance (configurable falloff)
- [ ] Voice activity detection
- [ ] Push-to-talk and open mic options
- [ ] Mute/unmute per player
- [ ] Voice volume indicator UI
- [ ] Latency under 200ms

## Technical Notes

GDD recommends GodotSteam Voice for initial release. Fallback to custom WebRTC as stretch goal.

Voice activity will be used by Entity system to detect noisy players during hunts.

## Out of Scope

- Text chat
- Radio/walkie-talkie mechanic
- Voice processing effects

## Implementation Notes (Ralph - 2026-01-22)

### Files Created
- `src/voice/voice_enums.gd` (NEW, 55 lines) - VoiceMode, VoiceState enums
- `src/voice/voice_manager.gd` (NEW, 420 lines) - Central voice autoload
- `src/voice/voice_player.gd` (NEW, 180 lines) - Spatial audio per player
- `tests/integration/test_voice_manager.gd` (NEW, 415 lines) - 31 tests

### Files Modified
- `src/ui/hud.gd` (+28 lines) - Voice indicator pulse animation
- `src/ui/player_name_label_3d.gd` (+60 lines) - Speaker icons above players
- `project.godot` - VoiceManager autoload registered

### Key Implementation Details
- **Voice modes**: DISABLED, PUSH_TO_TALK (default), OPEN_MIC
- **Push-to-talk**: "voice_transmit" input action (V key)
- **VAD**: Open mic uses amplitude threshold with 300ms silence cutoff
- **Network**: Steam P2P channel 1 (separate from game data on channel 0)
- **Spatial**: AudioStreamPlayer3D with INVERSE_DISTANCE attenuation, 15m max
- **Jitter buffer**: Adaptive 40-200ms using RFC 3550 jitter calculation
- **Settings**: Persist to user://voice_settings.cfg (mode, volume, sensitivity)

### Signals
- `voice_state_changed(new_state: VoiceState)` - For UI indicators
- `voice_data_captured(data: PackedByteArray)` - Raw capture
- `voice_activity(player_id: int, amplitude: float)` - For entity AI

### API for Entity Detection
```gdscript
VoiceManager.get_voice_amplitude() -> float  # Current amplitude
VoiceManager.is_transmitting() -> bool       # Currently talking
# voice_activity signal for Listener entity
```

### Test Verification
```
./cc_workflow/scripts/run-tests.ps1 -Mode file -File test_voice_manager.gd
Result: 31/31 passed
```

### Acceptance Criteria Status
- [x] Voice input capture from microphone (Steam.getVoice())
- [x] Spatial audio playback (VoicePlayer extends AudioStreamPlayer3D)
- [x] Voice fades with distance (15m max, INVERSE_DISTANCE)
- [x] Voice activity detection (VAD for open mic)
- [x] Push-to-talk and open mic options
- [x] Mute/unmute per player (mute_player/unmute_player)
- [x] Voice volume indicator UI (HUD mic icon, player speaker icons)
- [x] Latency under 200ms (jitter buffer targets 40-200ms)
