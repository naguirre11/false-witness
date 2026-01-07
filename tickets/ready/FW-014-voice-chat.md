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
