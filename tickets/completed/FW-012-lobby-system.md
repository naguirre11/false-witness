---
id: FW-012
title: "Implement lobby system with player slots"
epic: NET
priority: high
estimated_complexity: medium
dependencies: [FW-011]
created: 2026-01-07
completed: 2026-01-10
---

## Description

Create the lobby system that manages pre-game player gathering. Supports 4-6 players with ready states and host controls.

## Acceptance Criteria

- [x] LobbyManager handles player slots (4-6 players)
- [x] Player ready/unready toggle
- [x] Host can start game when all players ready (minimum 4)
- [x] Player list synchronized across all clients
- [x] Late join prevention once game starts
- [x] Host migration if host disconnects in lobby
- [x] Lobby state broadcasts to all players

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

## Implementation Notes

### Files Created/Modified

| File | Change |
|------|--------|
| `src/core/lobby_manager.gd` | New: LobbyManager autoload (~520 lines) |
| `src/core/networking/lobby_slot.gd` | New: LobbySlot resource for player slot data |
| `src/core/managers/event_bus.gd` | Added lobby-related signals |
| `project.godot` | Added LobbyManager autoload (after NetworkManager) |
| `tests/integration/test_lobby_manager.gd` | New: 35 comprehensive tests |

### LobbyManager API

**Lobby Lifecycle:**
- `create_lobby()` - Create new lobby (caller becomes host)
- `join_lobby()` - Join existing lobby (receives state from host)
- `leave_lobby()` - Leave current lobby

**Ready State:**
- `toggle_ready()` - Toggle local player's ready state
- `set_ready(ready: bool)` - Set ready state explicitly
- `are_all_players_ready()` - Check if all players ready

**Game Start:**
- `start_game()` - Host starts game (requires MIN_PLAYERS and all ready)
- `can_start_game()` - Check if start conditions are met

**Player Management:**
- `kick_player(peer_id, reason)` - Host kicks a player
- `get_slots()` - Get all LobbySlot resources
- `get_slot_by_peer_id(peer_id)` - Find slot by peer ID
- `get_local_slot()` - Get local player's slot
- `get_player_count()` - Count of occupied slots

### LobbySlot Resource

Stores per-player lobby state:
- `slot_index` - Position in lobby (0-5)
- `peer_id` - Network peer ID (0 = empty)
- `username` - Player display name
- `is_ready` - Ready state
- `is_host` - Whether this player is host
- `join_order` - Used for host migration (lower = earlier)
- `connection_quality` - UNKNOWN/POOR/FAIR/GOOD/EXCELLENT

### Signals

**LobbyManager signals:**
- `lobby_created(is_host)` - Lobby created or joined
- `lobby_joined(slot_index)` - Local player assigned to slot
- `lobby_left` - Left lobby
- `lobby_closed(reason)` - Lobby was closed (host left, kicked, etc.)
- `player_slot_updated(slot_index, slot)` - Slot state changed
- `player_ready_changed(peer_id, is_ready)` - Player ready state changed
- `all_players_ready(can_start)` - All ready check updated
- `host_changed(peer_id, username)` - Host migrated
- `game_starting` - Host started the game
- `lobby_state_updated(slots)` - Full state updated
- `player_kicked(peer_id, reason)` - Player was kicked

**EventBus signals (for UI):**
- `lobby_state_changed(is_in_lobby, is_host)`
- `lobby_players_updated(player_count, slots)`
- `lobby_player_ready_changed(peer_id, is_ready)`
- `lobby_can_start(can_start)`
- `lobby_host_changed(peer_id, username)`

### Host Migration

When host disconnects:
1. Find player with lowest `join_order`
2. Promote that player to host
3. New host broadcasts updated state
4. All clients receive `host_changed` signal

### Network Protocol

Lobby uses NetworkManager's packet system with `_lobby: true` flag:

| Action | Direction | Data |
|--------|-----------|------|
| `full_state` | Host → All | slots[], host_peer_id, game_started |
| `ready_changed` | Player → All | peer_id, is_ready |
| `game_starting` | Host → All | - |
| `lobby_closed` | Host → All | reason |
| `kicked` | Host → Player | reason |
| `join_rejected` | Host → Player | reason |

### Test Coverage

35 tests covering:
- LobbySlot initialization, serialization, roundtrip
- Connection quality enum stringification
- LobbyManager constants and initial state
- Signal existence verification
- Player slot management (add, remove, get)
- Ready state checking
- Can start game logic (host check, player count, all ready)
- Late join prevention
- Host migration logic
- Packet handlers (full_state, ready_changed, game_starting)

### Testing Commands

```bash
# Run lobby manager tests
$GODOT --headless -s addons/gut/gut_cmdln.gd \
  -gtest=res://tests/integration/test_lobby_manager.gd -gexit
```

All 1765 tests pass (including 35 new lobby manager tests).
