# Ticket Prioritization Queue

This file tracks the order in which tickets should be worked on.

## Current Status

**NEXT**: FW-001

*Note: MVP focuses on vertical slice - one map, one entity, core evidence system, basic Cultist mechanics, 4-player networking. Design Supplement priorities 1-5 integrated into MVP.*

---

## Epic Overview

| Epic | Ticket Range | Description |
|------|--------------|-------------|
| FOUNDATION | FW-001 - FW-010 | Project setup, autoloads, state machine |
| NET | FW-011 - FW-020 | Networking, lobbies, voice chat |
| FPS | FW-021 - FW-030 | First-person controller, interaction, equipment, protection items |
| EVIDENCE | FW-031 - FW-040 | Evidence system, equipment, cross-verification |
| ENTITY | FW-041 - FW-050 | Entity AI, behavioral tells, hunt mechanics, Echo system |
| CULTIST | FW-051 - FW-060 | Traitor role, contamination with decay, hunt manipulation |
| FLOW | FW-061 - FW-070 | Win conditions, deliberation, results |
| MAP | FW-071 - FW-080 | Map development |
| UI | FW-081 - FW-090 | Menus, HUD, tutorials |
| AUDIO | FW-091 - FW-100 | Sound systems |
| POST-LAUNCH | FW-101+ | Portent deck, physics, additional content |

---

## Design Supplement Integration

Based on competitive analysis (Phasmophobia, R.E.P.O., Demonologist):

| Priority | Improvement | Status | Ticket(s) |
|----------|-------------|--------|-----------|
| 1 | Echo System (dead players) | MVP | FW-043 (updated) |
| 2 | Entity Behavioral Tells | MVP | FW-041, FW-044 (updated) |
| 3 | Hunt Mechanic Depth | MVP | FW-042, FW-024 (new) |
| 4 | Evidence Decay | MVP | FW-052 (updated) |
| 5 | Cross-Verification | MVP | FW-036 (new) |
| 6 | Banishment Phase | Post-MVP | FW-064 (draft) |
| 7 | Tutorial/Onboarding | Post-MVP | FW-084, FW-085 (draft) |
| 8 | Portent Deck | Post-Launch | FW-101 (draft) |
| 9 | Basic Physics | Post-Launch | FW-102 (draft) |

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
| 2 | FW-024 | Implement hunt protection items | ready | FW-022, FW-023 |
| 2 | FW-031 | Create core evidence system | ready | FW-002, FW-023 |
| 2 | FW-041 | Create core entity AI with behavioral tells | ready | FW-002, FW-003 |
| 2 | FW-081 | Create main menu and lobby UI | ready | FW-012 |

### Evidence Implementation (Priority 2)

| Priority | Ticket | Title | Status | Blocked By |
|----------|--------|-------|--------|------------|
| 1 | FW-032 | Implement EMF Reader | ready | FW-031 |
| 1 | FW-033 | Implement Thermometer | ready | FW-031 |
| 1 | FW-034 | Implement Spirit Box | ready | FW-031 |
| 2 | FW-035 | Create evidence board UI | ready | FW-031 |
| 2 | FW-036 | Implement cross-verification system | ready | FW-031, FW-035 |

### Entity & Hunt (Priority 2)

| Priority | Ticket | Title | Status | Blocked By |
|----------|--------|-------|--------|------------|
| 1 | FW-042 | Implement hunt mechanics with depth | ready | FW-041, FW-024 |
| 2 | FW-043 | Implement Echo system (dead players) | ready | FW-042, FW-014 |
| 2 | FW-044 | Implement first entity: Phantom | ready | FW-041, FW-042 |
| 3 | FW-046 | Implement Listener entity (voice-reactive) | ready | FW-044, FW-014 |
| 2 | FW-092 | Implement entity audio | ready | FW-091, FW-041 |

### Cultist System (Priority 2)

| Priority | Ticket | Title | Status | Blocked By |
|----------|--------|-------|--------|------------|
| 1 | FW-051 | Implement Cultist role assignment | ready | FW-012, FW-003 |
| 2 | FW-052 | Implement Cultist abilities with decay | ready | FW-051, FW-031, FW-042 |
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

**Milestone**: Complete vertical slice - one map, two entities (Phantom + Listener), full evidence system with cross-verification, Cultist role with decay mechanics, Echo system, 4-player networked play.

---

## Phase 2: Content Expansion (Post-MVP)

### Ready for Development

*Tickets to be created after Phase 1 completion:*
- Additional entities (4-6 more: Banshee, Revenant, Shade, etc.)
- Second map: Office Building
- Third map: Hospital Wing
- Additional evidence types (UV, DOTS, Ghost Orbs, etc.)
- Balance tuning

### In Draft (Design Supplement Priorities 6-7)

| Ticket | Title | Priority | Notes |
|--------|-------|----------|-------|
| FW-064 | Banishment phase endgame | Medium | Optional extended gameplay |
| FW-084 | Solo training mode tutorial | Medium | Addresses competitor weakness |
| FW-085 | Cultist School tutorial | Low | Unlocks at Level 5 |

---

## Phase 3: Post-Launch Content

### In Draft (Design Supplement Priorities 8-9)

| Ticket | Title | Priority | Notes |
|--------|-------|----------|-------|
| FW-101 | Portent Deck match modifiers | Low | Roguelike variance |
| FW-102 | Basic physics interactions | Low | Clip potential, emergent play |

---

## Dependency Graph (Simplified)

```
FW-001 (Project Init)
├── FW-002 (Autoloads)
│   ├── FW-003 (State Machine)
│   │   ├── FW-041 (Entity Core + Behavioral Tells)
│   │   │   ├── FW-042 (Hunt Mechanics)
│   │   │   │   ├── FW-043 (Echo System)
│   │   │   │   └── FW-044 (Phantom) → FW-046 (Listener)
│   │   ├── FW-051 (Cultist Role)
│   │   │   └── FW-052 (Cultist Abilities + Decay)
│   │   └── FW-061 (Win Conditions)
│   └── FW-011 (Networking)
│       └── FW-012 (Lobby)
│           ├── FW-013 (Steam)
│           │   └── FW-014 (Voice Chat)
│           └── FW-081 (Menu UI)
├── FW-021 (FPS Controller)
│   ├── FW-022 (Interaction)
│   │   ├── FW-023 (Equipment)
│   │   │   ├── FW-024 (Protection Items)
│   │   │   └── FW-031 (Evidence Core)
│   │   │       ├── FW-032-034 (Evidence Types)
│   │   │       ├── FW-035 (Evidence Board)
│   │   │       └── FW-036 (Cross-Verification)
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
- Design Supplement priorities 1-5 integrated into MVP
- Priorities 6-9 in draft for post-MVP/post-launch
