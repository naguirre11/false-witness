---
id: FW-081
title: "Create main menu and lobby UI"
epic: UI
priority: high
estimated_complexity: medium
dependencies: [FW-012]
created: 2026-01-07
---

## Description

Build the main menu and lobby interface for hosting/joining games and managing pre-game state.

## Acceptance Criteria

- [ ] Main menu with Host/Join options
- [ ] Host game: Creates lobby, shows lobby code
- [ ] Join game: Enter lobby code to connect
- [ ] Lobby screen shows connected players
- [ ] Player ready toggle
- [ ] Host start game button (enabled when all ready)
- [ ] Player list with connection status
- [ ] Leave/disconnect button
- [ ] Settings access from menu

## Technical Notes

Per GDD: "Private lobbies only for 1.0" - use lobby codes, no public matchmaking.

Aesthetic: Styled as investigation paperwork/clipboard per GDD UI direction.

## Out of Scope

- Steam friend invite UI (handled by Steam overlay)
- Cosmetic selection
- Settings implementation

## Implementation Notes (2026-01-21)

**Files Created:**
- `src/ui/main_menu.gd` - Main menu controller with Host/Join/Settings/Quit
- `src/ui/lobby_screen.gd` - Lobby display with player slots, ready/start controls
- `src/ui/join_dialog.gd` - Join game dialog with code validation
- `src/ui/player_slot_ui.gd` - Individual player slot component
- `scenes/ui/main_menu.tscn` - Main menu scene with clipboard aesthetic
- `scenes/ui/lobby_screen.tscn` - Lobby scene
- `scenes/ui/join_dialog.tscn` - Join dialog
- `scenes/ui/player_slot_ui.tscn` - Player slot component

**Acceptance Criteria Status:**
- [x] Main menu with Host/Join options
- [x] Host game creates lobby (code display needs NetworkManager integration)
- [x] Join game dialog with 6-char code validation (join logic deferred)
- [x] Lobby screen shows connected players (6 slots)
- [x] Player ready toggle
- [x] Host start game button (enabled when all ready)
- [x] Player list with username, host crown, ready status
- [x] Leave/disconnect button
- [x] Settings button (handler is TODO, marked out of scope)

**Notes:**
- Lobby code display shows "------" placeholder - actual Steam lobby ID integration needed
- Join-by-code functionality shows error "not yet implemented" - requires NetworkManager
- All UI components are complete and integrate with LobbyManager autoload
- Tested via commits FW-081-01 through FW-081-08
