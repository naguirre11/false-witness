# Ticket Prioritization Queue

This file tracks the order in which tickets should be worked on.

## Current Status

**NEXT**: FW-001

*Note: MVP focuses on vertical slice - one map, one entity, core evidence system, basic Cultist mechanics, 4-player networking.*

---

## Epic Overview

| Epic | Ticket Range | Description |
|------|--------------|-------------|
| FOUNDATION | FW-001 - FW-010 | Project setup, autoloads, state machine |
| NET | FW-011 - FW-020 | Networking, lobbies, voice chat |
| FPS | FW-021 - FW-030 | First-person controller, interaction, equipment |
| EVIDENCE | FW-031 - FW-040 | Evidence system, equipment implementations |
| ENTITY | FW-041 - FW-050 | Entity AI, hunt mechanics, first entity |
| CULTIST | FW-051 - FW-060 | Traitor role, contamination abilities |
| FLOW | FW-061 - FW-070 | Win conditions, deliberation, results |
| MAP | FW-071 - FW-080 | Map development |
| UI | FW-081 - FW-090 | Menus, HUD, in-game UI |
| AUDIO | FW-091 - FW-100 | Sound systems |

---

## Phase 0: Pre-Production (Weeks 1-4)

### Foundation & Prototyping

| Priority | Ticket | Title | Status | Blocked By |
|----------|--------|-------|--------|------------|
| 1 | FW-001 | Initialize Godot 4.4 project with folder structure | ready | - |
| 2 | FW-002 | Create core autoload architecture | ready | FW-001 |
| 3 | FW-003 | Implement core game state machine | ready | FW-002 |
| 4 | FW-011 | Set up P2P networking foundation | ready | FW-002 |
| 5 | FW-021 | Create first-person player controller | ready | FW-001 |
| 6 | FW-091 | Establish audio system foundation | ready | FW-001 |

**Milestone**: Basic networked movement with 4 players.

---

## Phase 1: Vertical Slice (Weeks 5-16)

### Core Systems (Priority 1)

| Priority | Ticket | Title | Status | Blocked By |
|----------|--------|-------|--------|------------|
| 1 | FW-012 | Implement lobby system | ready | FW-011 |
| 1 | FW-022 | Implement interaction system | ready | FW-021 |
| 1 | FW-023 | Create equipment slot system | ready | FW-022 |
| 2 | FW-031 | Create core evidence system | ready | FW-002, FW-023 |
| 2 | FW-041 | Create core entity AI system | ready | FW-002, FW-003 |
| 2 | FW-081 | Create main menu and lobby UI | ready | FW-012 |

### Evidence Implementation (Priority 2)

| Priority | Ticket | Title | Status | Blocked By |
|----------|--------|-------|--------|------------|
| 1 | FW-032 | Implement EMF Reader | ready | FW-031 |
| 1 | FW-033 | Implement Thermometer | ready | FW-031 |
| 1 | FW-034 | Implement Spirit Box | ready | FW-031 |
| 2 | FW-035 | Create evidence board UI | ready | FW-031 |

### Entity & Hunt (Priority 2)

| Priority | Ticket | Title | Status | Blocked By |
|----------|--------|-------|--------|------------|
| 1 | FW-042 | Implement hunt mechanics | ready | FW-041 |
| 2 | FW-043 | Implement death/respawn | ready | FW-042 |
| 2 | FW-044 | Implement first entity: Phantom | ready | FW-041, FW-042 |
| 2 | FW-092 | Implement entity audio | ready | FW-091, FW-041 |

### Cultist System (Priority 2)

| Priority | Ticket | Title | Status | Blocked By |
|----------|--------|-------|--------|------------|
| 1 | FW-051 | Implement Cultist role assignment | ready | FW-012, FW-003 |
| 2 | FW-052 | Implement Cultist abilities | ready | FW-051, FW-031 |
| 3 | FW-053 | Implement Cultist discovery | ready | FW-052, FW-061 |

### Game Flow (Priority 2)

| Priority | Ticket | Title | Status | Blocked By |
|----------|--------|-------|--------|------------|
| 1 | FW-061 | Implement win/loss conditions | ready | FW-003, FW-031, FW-051 |
| 2 | FW-062 | Implement deliberation phase | ready | FW-061, FW-035 |
| 3 | FW-063 | Implement results screen | ready | FW-061 |

### Map & UI (Priority 2)

| Priority | Ticket | Title | Status | Blocked By |
|----------|--------|-------|--------|------------|
| 1 | FW-071 | Create first map: Abandoned House | ready | FW-021, FW-041 |
| 2 | FW-082 | Create equipment selection UI | ready | FW-023, FW-003 |
| 2 | FW-083 | Implement in-game HUD | ready | FW-021, FW-023 |

### Voice & Steam (Priority 3 - can ship without)

| Priority | Ticket | Title | Status | Blocked By |
|----------|--------|-------|--------|------------|
| 1 | FW-013 | Integrate GodotSteam | ready | FW-012 |
| 2 | FW-014 | Implement voice chat | ready | FW-013 |

**Milestone**: Complete vertical slice - one map, one entity, full evidence system, Cultist role, 4-player networked play.

---

## Phase 2: Content Expansion (Post-MVP)

*Tickets to be created after Phase 1 completion:*
- Additional entities (4-6 more)
- Second map: Office Building
- Third map: Hospital Wing
- Progression system (journal, equipment variants)
- Additional evidence types (UV, DOTS, Ghost Orbs, etc.)
- Balance tuning

---

## Dependency Graph (Simplified)

```
FW-001 (Project Init)
├── FW-002 (Autoloads)
│   ├── FW-003 (State Machine)
│   │   ├── FW-041 (Entity Core)
│   │   ├── FW-051 (Cultist Role)
│   │   └── FW-061 (Win Conditions)
│   └── FW-011 (Networking)
│       └── FW-012 (Lobby)
│           ├── FW-013 (Steam)
│           │   └── FW-014 (Voice)
│           └── FW-081 (Menu UI)
├── FW-021 (FPS Controller)
│   ├── FW-022 (Interaction)
│   │   └── FW-023 (Equipment)
│   │       └── FW-031 (Evidence Core)
│   │           ├── FW-032-034 (Evidence Types)
│   │           └── FW-035 (Evidence Board)
│   └── FW-071 (First Map)
└── FW-091 (Audio Foundation)
    └── FW-092 (Entity Audio)
```

---

## Recently Completed

| Ticket ID | Title |
|-----------|-------|
| - | - |

---

## Notes

- Priorities are relative within each phase
- Same priority number = can be worked in parallel
- Update this file whenever ticket status changes
- Only ONE ticket should be in `dev_in_progress/` at a time
- MVP target: 4 months to playable vertical slice
