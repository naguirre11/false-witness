---
id: FW-046
title: "Implement Listener entity (voice-reactive)"
epic: ENTITY
priority: medium
estimated_complexity: medium
dependencies: [FW-044, FW-014]
created: 2026-01-07
---

## Description

Create the Listener entity - a voice-reactive entity that hunts when players speak loudly during its dormant phase. This entity fundamentally changes how teams use voice communication.

## Acceptance Criteria

### Evidence Types
- [ ] FREEZING_TEMPERATURE - Detected by Thermometer
- [ ] GHOST_WRITING - Detected by Ghost Writing Book (triggered test)
- [ ] AURA_PATTERN - Detected by Dowsing Rods + Aura Imager (cooperative asymmetric)

### Behavioral Tell
- [ ] Hunts immediately if any player speaks above normal volume during dormant phase
- [ ] Voice activity detection threshold (louder than whisper)
- [ ] Bypasses sanity threshold when voice-triggered

### Counterplay
- [ ] Whisper mode (lower voice threshold awareness)
- [ ] Text chat becomes viable alternative (if implemented)
- [ ] Monitor for dormant phase indicators before speaking
- [ ] Audio cue indicates Listener is "listening" (faint static when dormant)

### Hunt Behavior
- [ ] Triggered hunts have no warning phase (immediate danger)
- [ ] Normal hunt parameters otherwise
- [ ] Cooldown applies after voice-triggered hunt

### Banishment Requirement (if FW-064 implemented)
- [ ] Complete ritual in perfect silence
- [ ] Any voice activity triggers immediate attack

## Technical Notes

**Evidence Types (using implemented system):**
- FREEZING_TEMPERATURE - Thermometer reading shows sub-zero temps
- GHOST_WRITING - Entity responds to placed Ghost Writing Book
- AURA_PATTERN - Cooperative asymmetric (Imager sees aura, Rods point direction)

**Cultist Overlap:**
Listener shares FREEZING_TEMPERATURE + AURA_PATTERN with Demon. Only GHOST_WRITING vs PHYSICAL_INTERACTION differentiates them.

**Design Intent**: Creates genuine tension around the core communication mechanic. Teams must balance information sharing with survival.

Requires voice chat integration (FW-014) to detect volume levels.

Dormant phase indicator helps players learn when it's safe to speak vs. when to stay quiet.

## Out of Scope

- Voice recognition for specific words
- Other entity implementations

## Implementation Notes (Ralph - 2026-01-22)

### Files Created
- `src/entity/listener_entity.gd` (~450 lines) - Listener class
- `scenes/entity/listener.tscn` - Listener scene
- `src/entity/listener_model.gd` (~100 lines) - Placeholder model
- `tests/unit/test_listener_entity.gd` (44 tests)
- `tests/integration/test_listener_integration.gd` (26 tests)

### Key Implementation Details
- Extends BaseEntity with voice-specific behavior
- Connects to `VoiceManager.voice_activity(player_id, amplitude)` signal
- **Dormant Phase**: 30-60s duration, reduced activity, listening for voices
- **Active Phase**: 45-90s duration, normal entity behavior
- Voice detection range: 15m (VOICE_DETECTION_RANGE constant)
- Voice trigger threshold: 0.3 amplitude (VOICE_TRIGGER_THRESHOLD)
- Voice hunt cooldown: 30s between voice-triggered hunts

### Voice Hunt Behavior
- Triggered when player amplitude > threshold during dormant phase
- Bypasses sanity threshold (immediate hunt)
- No warning phase (instant danger)
- Target prioritization: Speaking player > Nearest player
- Hunt ends after 30s or target killed

### Behavioral Tell
- Voice reaction: Head turn toward speaker before hunt
- Reaction pause: 0.5s before starting chase
- Turn speed: 8 rad/s toward voice source

### Dormant Phase Indicator
- Faint static audio cue (placeholder, needs audio asset)
- Audio volume: 0.3 (subtle but detectable)

### Network State
```gdscript
{
  "is_dormant": bool,
  "phase_timer": float,
  "voice_cooldown": float,
  "is_reacting_to_voice": bool,
  "voice_target_position": Vector3
}
```

### Test Verification
```
./cc_workflow/scripts/run-tests.ps1 -Mode file -File test_listener_entity.gd
Result: 44/44 passed

./cc_workflow/scripts/run-tests.ps1 -Mode file -File test_listener_integration.gd
Result: 26/26 passed
```

### Acceptance Criteria Status

**Evidence Types:**
- [x] FREEZING_TEMPERATURE - Produces sub-zero temps
- [x] GHOST_WRITING - Responds to Ghost Writing Book
- [x] AURA_PATTERN - Produces detectable aura

**Behavioral Tell:**
- [x] Hunts if player speaks during dormant phase
- [x] Voice activity detection threshold (0.3)
- [x] Bypasses sanity threshold when voice-triggered

**Counterplay:**
- [x] Dormant phase indicator (audio cue)
- [ ] Whisper mode - Not implemented (uses raw amplitude)

**Hunt Behavior:**
- [x] No warning phase for voice-triggered hunts
- [x] Normal hunt parameters otherwise
- [x] Cooldown after voice-triggered hunt (30s)
