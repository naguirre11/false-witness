---
id: FW-089
title: "Implement keybind remapping system"
epic: UI
priority: medium
estimated_complexity: medium
dependencies: [FW-088]
created: 2026-01-24
phase: 2
---

## Description

Create a robust keybind remapping system that allows players to customize all input actions. Part of the settings menu but complex enough to warrant its own ticket.

## Acceptance Criteria

### Rebindable Actions
- [ ] Movement: Forward, Back, Left, Right
- [ ] Sprint
- [ ] Crouch
- [ ] Jump (if implemented)
- [ ] Interact
- [ ] Use Equipment
- [ ] Toggle Flashlight
- [ ] Toggle Evidence Board
- [ ] Push to Talk
- [ ] Equipment slots 1, 2, 3
- [ ] Scroll equipment (up/down)
- [ ] Open Menu/Pause

### Rebinding UI
- [ ] Click action to start rebinding
- [ ] "Press any key..." prompt
- [ ] ESC to cancel rebinding
- [ ] Show current binding next to action name
- [ ] Highlight conflicts (same key bound twice)
- [ ] Warning when unbinding critical actions

### Conflict Resolution
- [ ] Detect when new binding conflicts with existing
- [ ] Offer to swap bindings or cancel
- [ ] Prevent binding reserved keys (ESC always opens menu)
- [ ] Allow same key for non-conflicting contexts

### Mouse Support
- [ ] Mouse buttons rebindable (LMB, RMB, MMB, M4, M5)
- [ ] Mouse wheel up/down as bindable actions
- [ ] Separate mouse sensitivity from bindings

### Controller Support
- [ ] Gamepad button rebinding
- [ ] Stick deadzone configuration
- [ ] Trigger threshold configuration
- [ ] Preset layouts (Default, Southpaw, Custom)

### Persistence
- [ ] Save bindings to user config file
- [ ] Load bindings on game start
- [ ] Reset to defaults button
- [ ] Reset individual binding option

### Default Bindings
```
Movement:     WASD
Sprint:       Left Shift
Crouch:       Left Ctrl
Interact:     E
Use Equip:    Left Mouse
Flashlight:   F
Evidence:     Tab
Push to Talk: V
Slot 1/2/3:   1/2/3
Menu:         ESC
```

## Technical Notes

Use Godot's InputMap system:
```gdscript
func rebind_action(action: String, event: InputEvent) -> void:
    InputMap.action_erase_events(action)
    InputMap.action_add_event(action, event)
    save_bindings()
```

Store as dictionary in ConfigFile:
```
[keybinds]
move_forward = "W"
move_back = "S"
interact = "E"
```

## Out of Scope

- Macro support
- Key combinations (Ctrl+X)
- Per-context bindings
