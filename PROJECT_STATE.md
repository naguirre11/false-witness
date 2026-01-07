# Project State

**Last Updated**: 2026-01-07

## Current Milestone

**Phase 0: Pre-Production** - Foundation & Prototyping

Target: Basic networked movement with 4 players.

## Completed Work

| Ticket | Title | Status |
|--------|-------|--------|
| FW-001 | Initialize Godot 4.4 project with folder structure | for_review |
| FW-002 | Create core autoload architecture | for_review |
| FW-003 | Implement core game state machine | for_review |
| FW-011 | Set up P2P networking foundation | for_review |

## In Progress

None - awaiting review of FW-001 through FW-011.

## Next Up

| Ticket | Title | Blocked By |
|--------|-------|------------|
| FW-021 | Create first-person player controller | FW-001 |
| FW-091 | Establish audio system foundation | FW-001 |
| FW-012 | Implement lobby system | FW-011 |

## Technical Decisions Made

### Template Decision (2026-01-07)
- **Base**: GodotSteam Template for Steam lobby/P2P networking
- **FPS Controller**: Build custom, referencing Quality First Person Controller v2
- **Interaction/Inventory**: Build custom, referencing Cogito patterns
- **Evidence/Cultist systems**: Built from scratch

### Networking Architecture (2026-01-07)
- **Transport**: Dual backend - Steam P2P (primary) + ENet (LAN fallback)
- **Topology**: Host-based (one player hosts, others join)
- **Sync strategy**: Server-authoritative for game state, 20Hz position updates
- **Player Data**: PlayerData resource tracks identity, transform, and gameplay state

## Active Autoloads

| Autoload | Purpose |
|----------|---------|
| SteamManager | Steam initialization and callbacks |
| NetworkManager | Dual backend networking (Steam + ENet) |
| EventBus | Global signal hub for decoupled communication |
| GameManager | Central game state machine with phase timers |

## NetworkManager API

**Connection:**
- `host_game(max_members, use_enet)` - Create lobby/server
- `join_game(target, port)` - Join by Steam lobby ID or IP address
- `leave_game()` - Disconnect cleanly

**State:**
- `get_connection_state()` - DISCONNECTED, CONNECTING, CONNECTED, HOST
- `get_backend()` - NONE, STEAM, ENET
- `is_game_host()` - True if local player is host

**Players:**
- `get_players()` - Dictionary of PlayerData by peer_id
- `get_player(peer_id)` - Get specific player
- `get_local_player()` - Local player data

## GameManager States

```
NONE -> LOBBY -> SETUP -> INVESTIGATION <-> HUNT -> RESULTS
                              |                       |
                              v                       |
                        DELIBERATION -----------------+
```

**Timed Phases:**
- Investigation: 12-15 minutes (configurable)
- Deliberation: 3-5 minutes (configurable)

## Known Issues

None currently.

## Test Coverage

- **Total Tests**: 67
- **Passing**: 67
- **Coverage Areas**: GameManager state machine + timers, EventBus signals, NetworkManager + PlayerData
