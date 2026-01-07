---
id: FW-013
title: "Integrate GodotSteam for networking and lobbies"
epic: NET
priority: medium
estimated_complexity: large
dependencies: [FW-012]
created: 2026-01-07
---

## Description

Integrate GodotSteam plugin to enable Steam lobby system, relay networking for NAT traversal, and friend invites.

## Acceptance Criteria

- [ ] GodotSteam plugin installed and configured
- [ ] Steam lobby creation/joining works
- [ ] Friend invite system functional
- [ ] Steam relay fallback for P2P connections
- [ ] Rich Presence shows current game state
- [ ] Private lobby codes for friend groups
- [ ] Graceful fallback if Steam unavailable

## Technical Notes

GodotSteam provides:
- Steam Lobby system for matchmaking
- Steam Networking Sockets (relay fallback)
- Rich Presence for "Join Game"

Per GDD: "Private lobbies only for 1.0" - no public matchmaking.

## Out of Scope

- Steam Voice (separate ticket)
- Steam achievements
- Public matchmaking
