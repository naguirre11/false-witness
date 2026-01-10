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
