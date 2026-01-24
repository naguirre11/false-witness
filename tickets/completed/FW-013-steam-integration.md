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

## Implementation Notes (Ralph - 2026-01-22)

### Files Modified/Created
- `src/core/steam_manager.gd` (+330 lines) - Full Steam API integration
- `src/core/lobby_manager.gd` (+176 lines) - Steam lobby coordination
- `tests/integration/test_steam_lobby.gd` (NEW, 216 lines) - 14 tests

### Key Implementation Details
- **Lobby codes**: Base36 encoding of 64-bit Steam lobby IDs → 6-char alphanumeric codes
- **Lobby type**: LOBBY_TYPE_FRIENDS_ONLY (private lobbies per GDD)
- **Member tracking**: Array[int] of Steam IDs, mapped to LobbyManager slots
- **Data sync**: set_lobby_data/get_lobby_data for game settings (map, max_players, mode)
- **Invites**: invite_friend() uses Steam overlay, join_requested callback for accepts
- **Rich Presence**: update_rich_presence() called on game state changes
- **Fallback**: ENet mode via join_lobby_by_ip() when Steam unavailable
- **P2P**: Legacy API with allowP2PPacketRelay(true) for NAT traversal

### Signals Added
- `lobby_created(lobby_id, code)`
- `lobby_joined(lobby_id)`
- `lobby_join_failed(reason)`
- `lobby_member_joined(steam_id)`
- `lobby_member_left(steam_id)`
- `lobby_data_changed(key, value)`
- `lobby_code_received(code)`

### Test Verification
```
./cc_workflow/scripts/run-tests.ps1 -Mode file -File test_steam_lobby.gd
Result: 14/14 passed
```

### Acceptance Criteria Status
- [x] GodotSteam plugin installed and configured
- [x] Steam lobby creation/joining works
- [x] Friend invite system functional
- [x] Steam relay fallback for P2P connections
- [x] Rich Presence shows current game state
- [x] Private lobby codes for friend groups
- [x] Graceful fallback if Steam unavailable
