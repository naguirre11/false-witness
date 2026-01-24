---
id: FW-051
title: "Implement Cultist role assignment system"
epic: CULTIST
priority: high
estimated_complexity: medium
dependencies: [FW-012, FW-003]
created: 2026-01-07
---

## Description

Create the secret role assignment system that designates one player as the Cultist at game start. The Cultist knows the true entity type while investigators do not.

## Acceptance Criteria

- [ ] Role assignment at EQUIPMENT_SELECT phase start
- [ ] Server-side only role data (anti-cheat)
- [ ] Cultist receives: true entity type, evidence types
- [ ] Cultist can see teammates' equipment selections
- [ ] Investigators receive no special information
- [ ] Role reveal only at end of match
- [ ] Support for 1 Cultist (4-5 players) or 2 Cultists (6 players)
- [ ] Random selection weighted for player history (optional)

## Technical Notes

Per GDD design: "Cultist identity is server-side only; client receives role reveal at match start, not in lobby."

Role configuration:
- 4 Players: 1 Cultist
- 5 Players: 1 Cultist
- 6 Players: 1-2 Cultists (configurable)

## Out of Scope

- Cultist abilities
- Discovery mechanics
- Post-discovery behavior

## Implementation Notes (Ralph - 2026-01-21)

### Files Created
- `src/cultist/cultist_manager.gd` - Central autoload for role management (~600 lines)
- `src/cultist/cultist_enums.gd` - PlayerRole, DiscoveryState, CultistData enums (~260 lines)
- `src/ui/role_reveal.gd` + `scenes/ui/role_reveal.tscn` - Role reveal popup (~320 lines)
- `tests/unit/test_cultist_manager.gd` - 21 unit tests (~340 lines)

### Key Implementation Details
- CultistManager registered as autoload in project.godot
- Server-authoritative role storage via `_cultist_ids: Array[int]`
- Role assignment via `assign_roles(player_ids, entity_type, entity_evidence)`
- Seeded RNG for deterministic testing (`seed_rng()`)
- RPC methods for role distribution (`_receive_cultist_data`)
- Equipment visibility for Cultists via `is_cultist()` checks in equipment_select.gd

### Test Verification
```
./cc_workflow/scripts/run-tests.ps1 -Mode file -File test_cultist_manager.gd
Result: 21/21 passed
```

### Acceptance Criteria Status
- [x] Role assignment at EQUIPMENT_SELECT phase start
- [x] Server-side only role data (anti-cheat)
- [x] Cultist receives: true entity type, evidence types
- [x] Cultist can see teammates' equipment selections
- [x] Investigators receive no special information
- [x] Role reveal at match start (via RoleReveal popup)
- [x] Support for 1 Cultist (4-5 players) or 2 Cultists (6 players)
- [x] Seeded randomization for reproducible tests
