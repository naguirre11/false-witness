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

## In Progress

None - awaiting review of FW-001, FW-002, and FW-003.

## Next Up

| Ticket | Title | Blocked By |
|--------|-------|------------|
| FW-011 | Set up P2P networking foundation | FW-002 |
| FW-021 | Create first-person player controller | FW-001 |
| FW-091 | Establish audio system foundation | FW-001 |

## Technical Decisions Made

### Template Decision (2026-01-07)
- **Base**: GodotSteam Template for Steam lobby/P2P networking
- **FPS Controller**: Build custom, referencing Quality First Person Controller v2
- **Interaction/Inventory**: Build custom, referencing Cogito patterns
- **Evidence/Cultist systems**: Built from scratch

### Networking Architecture
- **Transport**: Steam P2P via GodotSteam
- **Topology**: Host-based (one player hosts, others join via Steam lobby)
- **Sync strategy**: Server-authoritative for game state, client-predicted for movement

## Active Autoloads

| Autoload | Purpose |
|----------|---------|
| SteamManager | Steam initialization and callbacks |
| NetworkManager | Steam lobbies and P2P networking |
| EventBus | Global signal hub for decoupled communication |
| GameManager | Central game state machine with phase timers |

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

- **Total Tests**: 50
- **Passing**: 50
- **Coverage Areas**: GameManager state machine + timers, EventBus signals
