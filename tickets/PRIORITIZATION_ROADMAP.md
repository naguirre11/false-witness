# Roadmap & Prioritization

Detailed planning and dependency information. For quick status checks, see `STATUS.md`.

## Current Progress (2026-01-23)

**Phase 0 & 1 largely complete.** Most tickets through FW-092 are in `for_review`.

| Status | Count | Notes |
|--------|-------|-------|
| for_review | 61 | Awaiting human review |
| ready | 2 | FW-040c (Photo Evidence), FW-035e (UI Polish) |
| draft | 8 | Post-MVP and deferred items |
| dev_in_progress | 0 | - |

**Remaining ready work:**
- FW-040c: Photo Evidence System (camera equipment)
- FW-035e: Evidence Board Polish (DesignTokens cleanup, animations)

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

| Priority | Improvement | Target | Ticket(s) |
|----------|-------------|--------|-----------|
| 1 | Echo System (dead players) | MVP | FW-043 |
| 2 | Entity Behavioral Tells | MVP | FW-041, FW-044 |
| 3 | Hunt Mechanic Depth | MVP | FW-042, FW-024 |
| 4 | Evidence Decay | MVP | FW-052 |
| 5 | Cross-Verification | MVP | FW-036 |
| 6 | Banishment Phase | Post-MVP | FW-064 |
| 7 | Tutorial/Onboarding | Post-MVP | FW-084, FW-085 |
| 8 | Portent Deck | Post-Launch | FW-101 |
| 9 | Basic Physics | Post-Launch | FW-102 |

---

## Phase 0: Pre-Production

### Foundation & Prototyping

| Priority | Ticket | Title | Blocked By |
|----------|--------|-------|------------|
| 1 | FW-001 | Initialize Godot 4.4 project with folder structure | - |
| 2 | FW-002 | Create core autoload architecture | FW-001 |
| 3 | FW-003 | Implement core game state machine | FW-002 |
| 4 | FW-011 | Set up P2P networking foundation | FW-002 |
| 5 | FW-021 | Create first-person player controller | FW-001 |
| 6 | FW-022 | Implement player interaction system | FW-021 |
| 7 | FW-023 | Create equipment slot system | FW-022 |
| 8 | FW-091 | Establish audio system foundation | FW-001 |

**Milestone**: Basic networked movement with 4 players.

---

## Phase 1: Vertical Slice

### Core Systems (Priority 1)

| Priority | Ticket | Title | Blocked By |
|----------|--------|-------|------------|
| 1 | FW-012 | Implement lobby system | FW-011 |
| 1 | FW-024 | Implement hunt protection items | FW-023 |
| 2 | FW-031 | Create core evidence system | FW-002, FW-023 |
| 2 | FW-041 | Create core entity AI with behavioral tells | FW-002, FW-003 |
| 2 | FW-081 | Create main menu and lobby UI | FW-012 |

### Evidence Implementation (Priority 2)

| Priority | Ticket | Title | Blocked By |
|----------|--------|-------|------------|
| 1 | FW-032 | Implement EMF Reader | FW-031 |
| 1 | FW-033 | Implement Thermometer | FW-031 |
| 1 | FW-037 | Implement Spectral Prism Rig (cooperative symmetric) | FW-031, FW-023 |
| 1 | FW-038 | Implement Dowsing Rods + Aura Imager (cooperative asymmetric) | FW-031, FW-023 |
| 1 | FW-039 | Implement Ghost Writing Book (triggered test) | FW-031, FW-023 |
| 1 | FW-040 | Implement Readily-Apparent Evidence system | FW-031, FW-041 |
| 2 | FW-035 | Create evidence board UI | FW-031 |
| 2 | FW-036 | Implement cross-verification system | FW-031, FW-035 |

### Entity & Hunt (Priority 2)

| Priority | Ticket | Title | Blocked By |
|----------|--------|-------|------------|
| 1 | FW-042 | Implement hunt mechanics with depth | FW-041, FW-024 |
| 2 | FW-043 | Implement Echo system (dead players) | FW-042, FW-014 |
| 2 | FW-044 | Implement first entity: Phantom | FW-041, FW-042 |
| 3 | FW-046 | Implement Listener entity (voice-reactive) | FW-044, FW-014 |
| 2 | FW-092 | Implement entity audio | FW-091, FW-041 |

### Cultist System (Priority 2)

| Priority | Ticket | Title | Blocked By |
|----------|--------|-------|------------|
| 1 | FW-051 | Implement Cultist role assignment | FW-012, FW-003 |
| 2 | FW-052 | Implement Cultist abilities with decay | FW-051, FW-031, FW-042 |
| 3 | FW-053 | Implement Cultist discovery | FW-052, FW-061 |

### Game Flow (Priority 2)

| Priority | Ticket | Title | Blocked By |
|----------|--------|-------|------------|
| 1 | FW-061 | Implement win/loss conditions | FW-003, FW-031, FW-051 |
| 2 | FW-062 | Implement deliberation phase | FW-061, FW-035 |
| 3 | FW-063 | Implement results screen | FW-061 |

### Map & UI (Priority 2)

| Priority | Ticket | Title | Blocked By |
|----------|--------|-------|------------|
| 1 | FW-071 | Create first map: Abandoned House | FW-021, FW-041 |
| 2 | FW-082 | Create equipment selection UI | FW-023, FW-003 |
| 2 | FW-083 | Implement in-game HUD | FW-021, FW-023 |
| 3 | FW-086 | Implement design token system | - |
| 3 | FW-087 | Refactor UI to use design tokens | FW-086 |

### Voice & Steam (Priority 3 - can ship without)

| Priority | Ticket | Title | Blocked By |
|----------|--------|-------|------------|
| 1 | FW-013 | Integrate GodotSteam | FW-012 |
| 2 | FW-014 | Implement voice chat | FW-013 |

**Milestone**: Complete vertical slice - one map, two entities (Phantom + Listener), full evidence system with cross-verification, Cultist role with decay mechanics, Echo system, 4-player networked play.

---

## Phase 2: Content Expansion (Post-MVP)

### Ready for Development

*Tickets to be created after Phase 1 completion:*
- Additional entities (4-6 more: Banshee, Revenant, Shade, etc.)
- Second map: Office Building
- Third map: Hospital Wing
- Balance tuning
- Spirit Box equipment (FW-034 in draft - requires voice chat)

### In Draft

| Ticket | Title | Priority | Notes |
|--------|-------|----------|-------|
| FW-064 | Banishment phase endgame | Medium | Optional extended gameplay |
| FW-084 | Solo training mode tutorial | Medium | Addresses competitor weakness |
| FW-085 | Cultist School tutorial | Low | Unlocks at Level 5 |

---

## Phase 3: Post-Launch Content

### In Draft

| Ticket | Title | Priority | Notes |
|--------|-------|----------|-------|
| FW-101 | Portent Deck match modifiers | Low | Roguelike variance |
| FW-102 | Basic physics interactions | Low | Clip potential, emergent play |

---

## Dependency Graph

```
FW-001 (Project Init)
├── FW-002 (Autoloads)
│   ├── FW-003 (State Machine)
│   │   ├── FW-041 (Entity Core + Behavioral Tells)
│   │   │   ├── FW-042 (Hunt Mechanics)
│   │   │   │   ├── FW-043 (Echo System)
│   │   │   │   └── FW-044 (Phantom) → FW-046 (Listener)
│   │   │   └── FW-040 (Readily-Apparent Evidence) ← needs entity events
│   │   ├── FW-051 (Cultist Role)
│   │   │   └── FW-052 (Cultist Abilities + Decay)
│   │   └── FW-061 (Win Conditions)
│   └── FW-011 (Networking)
│       └── FW-012 (Lobby)
│           ├── FW-013 (Steam)
│           │   └── FW-014 (Voice Chat)
│           └── FW-081 (Menu UI)
│               └── FW-086 (Design Tokens)
│                   └── FW-087 (UI Token Refactor)
├── FW-021 (FPS Controller)
│   ├── FW-022 (Interaction)
│   │   ├── FW-023 (Equipment)
│   │   │   ├── FW-024 (Protection Items)
│   │   │   └── FW-031 (Evidence Core)
│   │   │       ├── FW-032 (EMF Reader)
│   │   │       ├── FW-033 (Thermometer)
│   │   │       ├── FW-037 (Spectral Prism Rig - cooperative symmetric)
│   │   │       ├── FW-038 (Dowsing Rods + Aura Imager - cooperative asymmetric)
│   │   │       ├── FW-039 (Ghost Writing Book - triggered test)
│   │   │       ├── FW-035 (Evidence Board)
│   │   │       └── FW-036 (Cross-Verification)
│   └── FW-071 (First Map)
└── FW-091 (Audio Foundation)
    └── FW-092 (Entity Audio)
```

**Evidence System (8 types):**
- Equipment-Derived: EMF (FW-032), Thermometer (FW-033), Prism Rig (FW-037), Aura Imager (FW-038)
- Triggered Test: Ghost Writing (FW-039)
- Readily-Apparent: Visual/Physical Manifestation (FW-040)
- Behavior-Based: Hunt Behavior (tracked by FW-041/FW-042)

---

## Entity-Evidence Matrix

Each entity produces exactly 3 evidence types from the implemented system. Overlaps are intentional for Cultist gameplay.

| Entity | Evidence 1 | Evidence 2 | Evidence 3 | Overlap With |
|--------|-----------|-----------|-----------|--------------|
| **Phantom** | EMF_SIGNATURE | PRISM_READING | VISUAL_MANIFESTATION | Wraith (EMF+PRISM) |
| **Wraith** | EMF_SIGNATURE | PRISM_READING | AURA_PATTERN | Phantom (EMF+PRISM) |
| **Shade** | EMF_SIGNATURE | GHOST_WRITING | FREEZING_TEMPERATURE | Revenant (GHOST+FREEZING) |
| **Banshee** | AURA_PATTERN | VISUAL_MANIFESTATION | HUNT_BEHAVIOR | Goryo (AURA+VISUAL) |
| **Revenant** | FREEZING_TEMPERATURE | GHOST_WRITING | HUNT_BEHAVIOR | Shade (GHOST+FREEZING) |
| **Poltergeist** | PHYSICAL_INTERACTION | PRISM_READING | GHOST_WRITING | Mare (PRISM+GHOST) |
| **Mare** | PRISM_READING | AURA_PATTERN | GHOST_WRITING | Poltergeist (PRISM+GHOST) |
| **Demon** | FREEZING_TEMPERATURE | PHYSICAL_INTERACTION | AURA_PATTERN | Listener (FREEZING+AURA) |
| **Listener** | FREEZING_TEMPERATURE | GHOST_WRITING | AURA_PATTERN | Demon (FREEZING+AURA) |
| **Goryo** | AURA_PATTERN | VISUAL_MANIFESTATION | EMF_SIGNATURE | Banshee (AURA+VISUAL) |

**Design Notes:**
- Phantom/Wraith share 2 evidence; differentiate by VISUAL vs AURA
- Shade/Revenant share 2 evidence; differentiate by EMF vs HUNT_BEHAVIOR
- HUNT_BEHAVIOR is unfalsifiable (all players observe hunts)
- Cooperative evidence (PRISM, AURA) requires trust between players

---

## Notes

- Priorities are relative within each phase
- Same priority number = can be worked in parallel
- Only ONE ticket should be in `dev_in_progress/` at a time
- MVP target: 4 months to playable vertical slice
- Design Supplement priorities 1-5 integrated into MVP
- Priorities 6-9 in draft for post-MVP/post-launch
