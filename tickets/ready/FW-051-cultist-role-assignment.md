---
id: FW-051
title: "Implement Cultist role assignment system"
epic: CULTIST
priority: high
estimated_complexity: medium
dependencies: [FW-012, FW-003]
created: 2026-01-07
---

## Description

Create the secret role assignment system that designates one player as the Cultist at game start. The Cultist knows the true entity type while investigators do not.

## Acceptance Criteria

- [ ] Role assignment at EQUIPMENT_SELECT phase start
- [ ] Server-side only role data (anti-cheat)
- [ ] Cultist receives: true entity type, evidence types
- [ ] Cultist can see teammates' equipment selections
- [ ] Investigators receive no special information
- [ ] Role reveal only at end of match
- [ ] Support for 1 Cultist (4-5 players) or 2 Cultists (6 players)
- [ ] Random selection weighted for player history (optional)

## Technical Notes

Per GDD design: "Cultist identity is server-side only; client receives role reveal at match start, not in lobby."

Role configuration:
- 4 Players: 1 Cultist
- 5 Players: 1 Cultist
- 6 Players: 1-2 Cultists (configurable)

## Out of Scope

- Cultist abilities
- Discovery mechanics
- Post-discovery behavior
