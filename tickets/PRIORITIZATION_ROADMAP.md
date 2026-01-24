# Roadmap & Prioritization

Detailed planning and dependency information. For quick status checks, see `STATUS.md`.

## Current Progress (2026-01-24)

**Phase 0 & 1 COMPLETE.** All 64 tickets reviewed and moved to `completed/`.

| Status | Count | Notes |
|--------|-------|-------|
| completed | 64 | Phase 0 & 1 done |
| ready | 19 | Phase 2 backlog |
| draft | 6 | Post-MVP and deferred items |
| dev_in_progress | 0 | - |

**Now entering Phase 2: Content Expansion**

---

## Epic Overview

| Epic | Ticket Range | Description | Status |
|------|--------------|-------------|--------|
| FOUNDATION | FW-001 - FW-010 | Project setup, autoloads, state machine | ✅ Complete |
| NET | FW-011 - FW-020 | Networking, lobbies, voice chat | ✅ Complete |
| FPS | FW-021 - FW-030 | First-person controller, interaction, equipment | ✅ Complete |
| EVIDENCE | FW-031 - FW-040 | Evidence system, equipment, cross-verification | ✅ Complete |
| ENTITY | FW-041 - FW-060 | Entity AI, behavioral tells, hunt mechanics | 🔄 Expanding |
| CULTIST | FW-051 - FW-060 | Traitor role, contamination with decay | ✅ Complete |
| FLOW | FW-061 - FW-070 | Win conditions, deliberation, results | ✅ Complete |
| MAP | FW-071 - FW-080 | Map development | 🔄 Expanding |
| UI | FW-081 - FW-100 | Menus, HUD, settings, polish | 🔄 Expanding |
| AUDIO | FW-091 - FW-100 | Sound systems | 🔄 Expanding |
| POST-LAUNCH | FW-101+ | Portent deck, physics, additional content | 📋 Draft |

---

## Phase 2: Content Expansion (CURRENT)

### Priority 1: Core Polish & Tools

| Ticket | Title | Size | Notes |
|--------|-------|------|-------|
| FW-035e | Evidence Board Polish | Small | DesignTokens cleanup, animations |
| FW-103 | Equipment Constants Cleanup | Small | Update stale type mappings |
| FW-095 | Balance Tuning Pass | Medium | Playtesting-informed adjustments |
| FW-096 | Playtesting Tools | Medium | Debug console, overlays, shortcuts |

### Priority 2: Essential UI

| Ticket | Title | Size | Notes |
|--------|-------|------|-------|
| FW-088 | Settings Menu | Medium | Audio, video, controls, accessibility |
| FW-089 | Keybind System | Medium | Full rebinding support |
| FW-097 | Loading Screens | Small | Transitions, tips, polish |
| FW-098 | Pause Menu | Small | In-game settings access |
| FW-040d | Photo Gallery UI | Small | View captured photos |

### Priority 3: Additional Entities (8 remaining)

All entities follow the GDD evidence matrix. Each has unique behavioral tells.

| Ticket | Entity | Evidence Profile | Key Mechanic |
|--------|--------|------------------|--------------|
| FW-045 | Wraith | EMF, PRISM, AURA | Teleportation, salt immunity |
| FW-047 | Shade | EMF, GHOST_WRITING, FREEZING | Shy, solo-hunter |
| FW-048 | Revenant | FREEZING, GHOST_WRITING, HUNT_BEHAVIOR | Speed differential (0.5→3.0 m/s) |
| FW-049 | Demon | FREEZING, PHYSICAL, AURA | Aggressive, protection resistance |
| FW-050 | Banshee | AURA, VISUAL, HUNT_BEHAVIOR | Single-target focus |
| FW-054 | Poltergeist | PHYSICAL, PRISM, GHOST_WRITING | Multi-throw, chaos |
| FW-055 | Mare | PRISM, AURA, GHOST_WRITING | Light aversion, darkness power |
| FW-056 | Goryo | AURA, VISUAL, EMF | Camera-only manifestation |

### Priority 4: Additional Maps

| Ticket | Title | Size | Rooms | Difficulty |
|--------|-------|------|-------|------------|
| FW-072 | Office Building | Large | 25-30 | Medium |
| FW-073 | Hospital Wing | Large | 20-25 | Hard |

### Priority 5: Polish & Extras

| Ticket | Title | Size | Notes |
|--------|-------|------|-------|
| FW-093 | Environmental Audio | Medium | Ambient zones, spatial audio |
| FW-094 | Player Customization | Medium | Cosmetic character options |

---

## Phase 3: Post-MVP (Draft)

| Ticket | Title | Priority | Notes |
|--------|-------|----------|-------|
| FW-064 | Banishment Phase | Medium | Optional endgame ritual |
| FW-084 | Solo Tutorial | Medium | Training mode with AI |
| FW-085 | Cultist Tutorial | Low | Unlocks at Level 5 |
| FW-034 | Spirit Box | Low | Deferred - needs voice analysis |

---

## Phase 4: Post-Launch (Draft)

| Ticket | Title | Priority | Notes |
|--------|-------|----------|-------|
| FW-101 | Portent Deck | Low | Match modifier cards |
| FW-102 | Basic Physics | Low | Throwable objects, clip potential |

---

## Entity-Evidence Matrix

Each entity produces exactly 3 evidence types. Overlaps are intentional for Cultist gameplay.

| Entity | Evidence 1 | Evidence 2 | Evidence 3 | Overlap With | Status |
|--------|-----------|-----------|-----------|--------------|--------|
| **Phantom** | EMF | PRISM | VISUAL | Wraith | ✅ FW-044 |
| **Listener** | FREEZING | GHOST_WRITING | AURA | Demon | ✅ FW-046 |
| **Wraith** | EMF | PRISM | AURA | Phantom | 📋 FW-045 |
| **Shade** | EMF | GHOST_WRITING | FREEZING | Revenant | 📋 FW-047 |
| **Revenant** | FREEZING | GHOST_WRITING | HUNT_BEHAVIOR | Shade | 📋 FW-048 |
| **Demon** | FREEZING | PHYSICAL | AURA | Listener | 📋 FW-049 |
| **Banshee** | AURA | VISUAL | HUNT_BEHAVIOR | Goryo | 📋 FW-050 |
| **Poltergeist** | PHYSICAL | PRISM | GHOST_WRITING | Mare | 📋 FW-054 |
| **Mare** | PRISM | AURA | GHOST_WRITING | Poltergeist | 📋 FW-055 |
| **Goryo** | AURA | VISUAL | EMF | Banshee | 📋 FW-056 |

**Legend:** ✅ = Complete | 📋 = Ready | 🔄 = In Progress

---

## Dependency Graph (Phase 2)

```
Phase 1 Complete (FW-001 through FW-092)
│
├── Entity Expansion
│   ├── FW-045 (Wraith) ─┐
│   ├── FW-047 (Shade)  ─┤
│   ├── FW-048 (Revenant)┤── All depend on FW-044 (Phantom base)
│   ├── FW-049 (Demon)  ─┤
│   ├── FW-050 (Banshee)─┤
│   ├── FW-054 (Poltergeist)
│   ├── FW-055 (Mare)   ─┤
│   └── FW-056 (Goryo)  ─┘
│
├── Map Expansion
│   ├── FW-072 (Office) ─── depends on FW-071 (House patterns)
│   └── FW-073 (Hospital) ─ depends on FW-071
│
├── UI Expansion
│   ├── FW-088 (Settings) ─┬─ depends on FW-086 (DesignTokens)
│   ├── FW-089 (Keybinds) ─┘
│   ├── FW-097 (Loading)
│   ├── FW-098 (Pause Menu) ─ depends on FW-088
│   └── FW-040d (Photo Gallery) ─ depends on FW-040c
│
└── Audio Expansion
    └── FW-093 (Environmental) ─ depends on FW-091
```

---

## Milestones

### ✅ Milestone 1: Vertical Slice (Phase 0+1)
- Basic networked movement
- 2 entities (Phantom, Listener)
- Full evidence system (8 types)
- Cross-verification
- Cultist role with abilities
- Echo system
- One map (Abandoned House)
- Core UI (menu, lobby, HUD, evidence board)

### 🎯 Milestone 2: Content Complete (Phase 2)
- All 10 entities playable
- 3 maps total
- Settings and keybinds
- Balance tuning
- Polish and loading screens

### 📋 Milestone 3: Launch Ready (Phase 3)
- Tutorials
- Optional banishment phase
- Final polish pass

---

## Notes

- Phase 2 tickets can be worked in parallel (no blocking dependencies within priorities)
- Entity tickets are independent - can implement in any order
- Balance tuning (FW-095) should happen after 4+ entities are playable
- Maps can be developed alongside entity work
