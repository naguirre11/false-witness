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
- [ ] EntityManager autoload for entity lifecycle
- [ ] Entity base class with behavior tree structure
- [ ] Entity states: Dormant, Active, Hunting, Manifesting
- [ ] Aggression escalation over time (per schedule below)
- [ ] Entity spawns in designated "favorite room"
- [ ] Basic pathfinding with NavMesh
- [ ] Server-authoritative entity behavior
- [ ] Client-side prediction for responsiveness

### Behavioral Tell System
- [ ] Abstract method for entity-specific behavioral tell
- [ ] Tell observation events (for tracking/achievements)
- [ ] Behavioral tells distinguishable from evidence
- [ ] Framework for entity-specific hunt variations

### Sanity System
- [ ] Team average sanity tracking
- [ ] Sanity affects hunt threshold (default 50%)
- [ ] Entity-specific sanity threshold overrides
- [ ] Sanity drain over time and from events

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
