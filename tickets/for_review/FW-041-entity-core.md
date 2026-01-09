---
id: FW-041
title: "Create core entity AI system with behavioral tells"
epic: ENTITY
priority: high
estimated_complexity: large
dependencies: [FW-002, FW-003]
created: 2026-01-07
updated: 2026-01-07
---

## Description

Build the foundation for entity AI including behavior trees, state management, aggression escalation, and the behavioral tell system. Each entity type has unique behavioral signatures beyond evidence, enabling identification through observation.

## Acceptance Criteria

### Core System
- [x] EntityManager autoload for entity lifecycle
- [x] Entity base class with behavior tree structure
- [x] Entity states: Dormant, Active, Hunting, Manifesting
- [x] Aggression escalation over time (per schedule below)
- [x] Entity spawns in designated "favorite room"
- [x] Basic pathfinding with NavMesh
- [x] Server-authoritative entity behavior
- [x] Client-side prediction for responsiveness

### Behavioral Tell System
- [x] Abstract method for entity-specific behavioral tell
- [x] Tell observation events (for tracking/achievements)
- [x] Behavioral tells distinguishable from evidence
- [x] Framework for entity-specific hunt variations

### Sanity System
- [x] Team average sanity tracking
- [x] Sanity affects hunt threshold (default 50%)
- [x] Entity-specific sanity threshold overrides
- [x] Sanity drain over time and from events

## Technical Notes

**Aggression schedule:**
- 0-5 min: Dormant (passive manifestations)
- 5-10 min: Active (occasional hunts)
- 10-15 min: Aggressive (frequent hunts)
- 15+ min: Furious (near-constant hunting)

**Behavioral Tell Matrix (per entity):**
| Entity | Behavioral Tell |
|--------|----------------|
| Phantom | Disappears when photographed during manifestation |
| Banshee | Fixates on one player; ignores others |
| Revenant | 1 m/s unaware, 3 m/s when chasing |
| Shade | Won't hunt if 2+ players in same room |
| Poltergeist | Throws multiple objects simultaneously |
| Wraith | Floats; ignores salt entirely |
| Mare | Cannot hunt in lit rooms |
| Demon | Hunts at 70% sanity; shortest cooldown |
| Listener | Hunts if any player speaks loudly during dormant phase |

Behavioral tells create second verification layer against false evidence: "Evidence says Wraith, but I saw it step in salt. Someone's lying."

## Out of Scope

- Specific entity implementations (separate tickets)
- Hunt mechanics details (FW-042)
- Entity visual/audio design

## Implementation Notes

### Files Created

| File | Lines | Purpose |
|------|-------|---------|
| `src/entity/entity_manager.gd` | ~350 | Autoload: entity lifecycle, spawning, aggression escalation, hunt coordination |
| `src/entity/entity.gd` | ~530 | Base class: state machine, pathfinding, behavioral tells, network sync |
| `src/entity/sanity_manager.gd` | ~310 | Autoload: player/team sanity, hunt thresholds, darkness drain |
| `tests/test_entity_manager.gd` | ~280 | 26 tests for EntityManager |
| `tests/test_entity.gd` | ~270 | 37 tests for Entity base class |
| `tests/test_sanity_manager.gd` | ~360 | 41 tests for SanityManager |

### New Autoloads

Added to `project.godot`:
- `EntityManager` - Manages entity spawning, lifecycle, aggression phases
- `SanityManager` - Tracks player sanity, team average, hunt thresholds

### EventBus Signals Added

Entity signals:
- `entity_spawned(entity_type, room)`
- `entity_removed`
- `entity_aggression_changed(phase, phase_name)`
- `entity_manifesting(position)`
- `entity_manifestation_ended`
- `entity_state_changed(old_state, new_state)`

Sanity signals:
- `player_sanity_changed(player_id, new_sanity)`
- `team_sanity_changed(team_average)`
- `sanity_threshold_crossed(threshold, team_sanity)`

### Key Design Decisions

1. **State Machine**: Entity uses enum-based state (DORMANT/ACTIVE/HUNTING/MANIFESTING) rather than full behavior tree - simpler for base class, subclasses can add complexity

2. **Aggression Phases**: Time-based escalation via constants (0-5m Dormant, 5-10m Active, 10-15m Aggressive, 15m+ Furious) with matching hunt cooldowns

3. **NavigationAgent3D**: Each entity creates its own NavigationAgent3D on ready for pathfinding

4. **Hunt Coordination**: EntityManager emits `hunt_starting` signal before hunt begins, allowing protection items (Crucifix) to prevent via `hunt_prevented` signal

5. **Sanity Thresholds**: Default 50% for hunts, entity-specific override via `hunt_sanity_threshold` export

### Testing Evidence

```bash
# All 38 test scripts pass
../tooling/Godot_v4.4.1-stable_win64_console.exe --headless \
  -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs \
  -gprefix=test_ -gsuffix=.gd -gexit
# Result: All tests passed!

# Lint passes for source files
gdlint src/
# Result: Success: no problems found
```
