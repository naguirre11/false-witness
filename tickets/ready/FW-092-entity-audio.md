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

- [ ] Hunt start audio cue (distinctive, terrifying)
- [ ] Entity footsteps during hunt
- [ ] Ambient entity sounds based on proximity
- [ ] Manifestation audio
- [ ] Entity-specific audio variations
- [ ] Audio occlusion through walls
- [ ] Dynamic audio mixing based on entity aggression
- [ ] Silence as horror cue (sudden quiet = danger)

## Technical Notes

Per GDD: "Players learn to recognize [hunt audio] instantly."

Each entity type should have unique audio signatures (footstep patterns, vocalizations).

## Out of Scope

- Corporate narrator announcements
- Equipment sounds
