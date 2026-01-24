---
id: FW-098
title: "Implement pause menu"
epic: UI
priority: medium
estimated_complexity: small
dependencies: [FW-081, FW-088]
created: 2026-01-24
phase: 2
---

## Description

Create an in-game pause menu for accessing settings, returning to lobby, or leaving the match. Multiplayer-aware (can't truly pause, but provides access to options).

## Acceptance Criteria

### Pause Menu Access
- [ ] ESC key opens pause menu
- [ ] ESC again closes menu
- [ ] Click outside menu closes it
- [ ] Game continues in background (multiplayer)

### Menu Options
- [ ] Resume Game (closes menu)
- [ ] Settings (opens settings submenu)
- [ ] Controls (quick reference card)
- [ ] Return to Lobby (host only, ends match)
- [ ] Leave Match (returns player to menu)
- [ ] Quit to Desktop (confirmation required)

### Visual Design
- [ ] Semi-transparent overlay (game visible behind)
- [ ] Centered menu panel
- [ ] Uses DesignTokens for consistency
- [ ] Horror-appropriate styling

### Multiplayer Behavior
- [ ] Game does NOT pause (others still playing)
- [ ] "Paused" indicator shown to other players
- [ ] Player still vulnerable during menu access
- [ ] Hunt warnings still visible/audible

### Settings Access
- [ ] Full settings panel accessible
- [ ] Changes apply immediately
- [ ] Can adjust audio mid-game
- [ ] Mouse sensitivity adjustable

### Leave Match Flow
- [ ] Confirmation dialog
- [ ] Warning about abandoning team
- [ ] Clean disconnect from server
- [ ] Return to main menu

### Host Controls
- [ ] "End Match" option (host only)
- [ ] Confirmation required
- [ ] Notifies all players
- [ ] Triggers results screen or lobby return

## Technical Notes

Use UI state in GameManager:
```gdscript
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        if _pause_menu.visible:
            _pause_menu.hide()
        else:
            _pause_menu.show()
```

Don't actually pause in multiplayer:
```gdscript
# NOT get_tree().paused = true in multiplayer!
```

## Out of Scope

- Spectator mode from pause
- Vote to end match
- Reconnect after disconnect
