---
id: FW-041
title: "Create core entity AI system"
epic: ENTITY
priority: high
estimated_complexity: large
dependencies: [FW-002, FW-003]
created: 2026-01-07
---

## Description

Build the foundation for entity AI including behavior trees, state management, and the aggression escalation system that creates time pressure.

## Acceptance Criteria

- [ ] EntityManager autoload for entity lifecycle
- [ ] Entity base class with behavior tree structure
- [ ] Entity states: Dormant, Active, Hunting, Manifesting
- [ ] Aggression escalation over time (per GDD schedule)
- [ ] Entity spawns in designated room
- [ ] Basic pathfinding with NavMesh
- [ ] Server-authoritative entity behavior
- [ ] Client-side prediction for responsiveness

## Technical Notes

Aggression schedule from GDD:
- 0-5 min: Dormant (passive manifestations)
- 5-10 min: Active (occasional hunts)
- 10-15 min: Aggressive (frequent hunts)
- 15+ min: Furious (near-constant hunting)

Entity behavior must be deterministic given same seed for fair gameplay.

## Out of Scope

- Specific entity types (separate tickets)
- Hunt mechanics (separate ticket)
- Entity visual/audio design
