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
