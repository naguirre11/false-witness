---
id: FW-011
title: "Set up P2P networking foundation with ENet"
epic: NET
priority: high
estimated_complexity: large
dependencies: [FW-002]
created: 2026-01-07
---

## Description

Establish the core peer-to-peer networking architecture using Godot's ENet multiplayer API. This creates the foundation for all networked gameplay with host-authoritative architecture.

## Acceptance Criteria

- [ ] NetworkManager autoload created
- [ ] Host/join functionality implemented
- [ ] Player connection/disconnection handling
- [ ] Basic player data synchronization (position, rotation)
- [ ] Network ID assignment for players
- [ ] Connection state signals (connected, disconnected, failed)
- [ ] Works on LAN without external services
- [ ] Unit tests for connection lifecycle

## Technical Notes

Architecture decisions from GDD:
- P2P with player-hosted sessions (no dedicated servers)
- Host is authoritative for game state
- Use Godot's MultiplayerSpawner/MultiplayerSynchronizer

```
src/core/
  managers/
    NetworkManager.gd   # Connection management, host/join
  networking/
    PlayerData.gd       # Synchronized player info
```

## Out of Scope

- Steam integration (separate ticket)
- Voice chat
- Lobby system UI
