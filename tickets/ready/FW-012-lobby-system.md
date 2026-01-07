---
id: FW-012
title: "Implement lobby system with player slots"
epic: NET
priority: high
estimated_complexity: medium
dependencies: [FW-011]
created: 2026-01-07
---

## Description

Create the lobby system that manages pre-game player gathering. Supports 4-6 players with ready states and host controls.

## Acceptance Criteria

- [ ] LobbyManager handles player slots (4-6 players)
- [ ] Player ready/unready toggle
- [ ] Host can start game when all players ready (minimum 4)
- [ ] Player list synchronized across all clients
- [ ] Late join prevention once game starts
- [ ] Host migration if host disconnects in lobby
- [ ] Lobby state broadcasts to all players

## Technical Notes

Player configurations from GDD:
- 4 Players: 3 Investigators, 1 Cultist
- 5 Players: 4 Investigators, 1 Cultist
- 6 Players: 4-5 Investigators, 1-2 Cultists

Lobby should track:
- Player name
- Ready state
- Slot position
- Connection quality indicator

## Out of Scope

- Cultist assignment (happens at game start, not in lobby)
- Equipment selection UI
- Steam lobby integration
