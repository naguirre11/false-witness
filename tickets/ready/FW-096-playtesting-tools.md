---
id: FW-096
title: "Implement playtesting and debug tools"
epic: FOUNDATION
priority: medium
estimated_complexity: medium
dependencies: [FW-003]
created: 2026-01-24
phase: 2
---

## Description

Create developer tools for playtesting, debugging, and QA. Console commands, debug overlays, and testing shortcuts to accelerate iteration.

## Acceptance Criteria

### Debug Console
- [ ] Toggle with ` (backtick) key
- [ ] Command input with autocomplete
- [ ] Command history (up/down arrows)
- [ ] Output log with scrollback
- [ ] Only available in debug builds or with flag

### Essential Commands
```
# Game State
set_state <state>          # Force game state
skip_phase                 # Skip to next phase
set_timer <seconds>        # Set phase timer
end_match <result>         # Force match end

# Entity
spawn_entity <type>        # Spawn specific entity
tp_entity <x> <y> <z>      # Teleport entity
force_hunt                 # Trigger immediate hunt
stop_hunt                  # End current hunt
set_activity <0-1>         # Set entity activity level

# Player
set_sanity <0-100>         # Set team sanity
god_mode                   # Toggle invincibility
noclip                     # Toggle collision
tp <x> <y> <z>             # Teleport player
give_equipment <type>      # Add equipment

# Evidence
spawn_evidence <type>      # Spawn evidence
reveal_entity              # Show entity type
list_evidence              # Print collected evidence

# Cultist
set_role <investigator|cultist>
use_ability <ability>      # Force ability use
reveal_cultist             # Show who is cultist

# Network
fake_players <count>       # Add AI players
kick_player <id>           # Remove player
set_latency <ms>           # Simulate lag
```

### Debug Overlays
- [ ] F1: Performance stats (FPS, memory, draw calls)
- [ ] F2: Network stats (ping, packet loss, bandwidth)
- [ ] F3: Entity debug (position, state, target, path)
- [ ] F4: Evidence debug (spawned, collected, trust levels)
- [ ] F5: Player debug (sanity, equipment, state)

### Quick Testing Shortcuts
- [ ] F9: Quick restart match
- [ ] F10: Toggle entity visibility
- [ ] F11: Skip to deliberation
- [ ] F12: Take debug screenshot with overlay data

### Logging System
- [ ] Log levels (DEBUG, INFO, WARN, ERROR)
- [ ] Per-system log filtering
- [ ] Write to file for analysis
- [ ] Include timestamps and frame numbers

### Replay System (Stretch)
- [ ] Record game state each frame
- [ ] Playback with timeline scrubbing
- [ ] Export replay file

## Technical Notes

Console command registration:
```gdscript
DebugConsole.register_command("set_sanity", _cmd_set_sanity, "Set team sanity (0-100)")

func _cmd_set_sanity(args: Array) -> String:
    if args.size() < 1:
        return "Usage: set_sanity <value>"
    var value := float(args[0])
    SanityManager.set_sanity(value)
    return "Sanity set to %d%%" % value
```

## Out of Scope

- Public-facing cheat protection
- Automated testing framework
- Performance profiling tools
