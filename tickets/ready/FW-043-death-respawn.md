---
id: FW-043
title: "Implement player death and respawn system"
epic: ENTITY
priority: high
estimated_complexity: medium
dependencies: [FW-042]
created: 2026-01-07
---

## Description

Create the death and respawn system. Death is not permanent - players become spectators briefly then respawn with reduced equipment.

## Acceptance Criteria

- [ ] Death trigger on entity contact during hunt
- [ ] Death visual/audio feedback
- [ ] 60-second spectator mode after death
- [ ] Spectators can see environment but not interact
- [ ] Spectators cannot communicate with living players
- [ ] Respawn at map entrance after timer
- [ ] Respawn with reduced equipment (lose 1 slot)
- [ ] Each death increases entity aggression slightly

## Technical Notes

Per GDD: "Keeps all players engaged while still making death consequential."

Death is broadcast to all players. Respawn location is fixed (entrance).

## Out of Scope

- Spectator camera controls
- Death statistics tracking
