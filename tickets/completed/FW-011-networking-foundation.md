---
id: FW-011
title: "Set up P2P networking foundation"
epic: NET
priority: high
estimated_complexity: large
dependencies: [FW-002]
created: 2026-01-07
completed: 2026-01-07
---

## Description

Establish the core peer-to-peer networking architecture using dual backends: Steam P2P (primary) and ENet (LAN fallback). This creates the foundation for all networked gameplay with host-authoritative architecture.

## Acceptance Criteria

- [x] NetworkManager autoload created
- [x] Host/join functionality implemented
- [x] Player connection/disconnection handling
- [x] Basic player data synchronization (position, rotation)
- [x] Network ID assignment for players
- [x] Connection state signals (connected, disconnected, failed)
- [x] Works on LAN without external services (ENet fallback)
- [x] Unit tests for connection lifecycle

## Technical Notes

Architecture decisions from GDD:
- P2P with player-hosted sessions (no dedicated servers)
- Host is authoritative for game state
- Dual backend: Steam P2P (primary) + ENet (LAN fallback)

```
src/core/
  network_manager.gd      # Connection management, host/join, dual backend
  networking/
    player_data.gd        # Synchronized player info
```

## Out of Scope

- Voice chat
- Lobby system UI
- Steam lobby browser

## Implementation Notes

### Files Created/Modified

| File | Change |
|------|--------|
| `src/core/network_manager.gd` | Major rewrite: dual backend (Steam + ENet), PlayerData tracking, position sync |
| `src/core/networking/player_data.gd` | New: PlayerData resource for synchronized player state |
| `tests/test_network_manager.gd` | New: 17 tests for PlayerData and NetworkManager |

### NetworkManager API

**Host/Join:**
- `host_game(max_members, use_enet)` - Create lobby/server
- `join_game(target, port)` - Join by Steam lobby ID or IP address
- `leave_game()` - Disconnect cleanly

**Player Data:**
- `get_players()` - Dictionary of all PlayerData by peer_id
- `get_player(peer_id)` - Get specific player
- `get_local_player()` - Get local player
- `send_position_update(pos, rot, vel)` - Update local player transform

**State:**
- `get_connection_state()` - DISCONNECTED, CONNECTING, CONNECTED, HOST
- `get_backend()` - NONE, STEAM, ENET
- `is_game_host()` - True if local player is host

### Signals

- `connection_state_changed(state)` - Connection lifecycle
- `lobby_created(lobby_id)` - Host created lobby/server
- `lobby_joined(lobby_id)` - Joined lobby/server
- `lobby_join_failed(reason)` - Connection failed
- `player_joined_network(peer_id, username)` - Player connected
- `player_left_network(peer_id)` - Player disconnected
- `player_data_updated(peer_id, data)` - Position update received

### Dual Backend Architecture

```
Steam Running? ─┬─ Yes ─> Steam P2P (NAT punch, relay fallback)
                └─ No ──> ENet (LAN only, port 7777)
```

Steam backend uses:
- Steam Lobby API for matchmaking
- Steam P2P for data transfer
- Steam relay servers for NAT traversal

ENet backend uses:
- Direct IP:port connection
- Godot's MultiplayerAPI
- RPC for packet broadcast

### Position Sync

- 20 Hz update rate (50ms interval)
- Unreliable packets for position (low latency)
- Reliable packets for game state
- PlayerData stores: position, rotation, velocity

### Test Coverage

- PlayerData initialization and defaults
- Transform serialization round-trip
- Full state serialization round-trip
- Reset for new round
- Partial dictionary application
- NetworkManager state enums
- Signal existence verification
- Constants verification

### Integration with EventBus

NetworkManager emits to EventBus on:
- `player_joined` - When any player connects
- `player_left` - When any player disconnects

This allows other systems (GameManager, UI) to react to player events without direct NetworkManager coupling.
