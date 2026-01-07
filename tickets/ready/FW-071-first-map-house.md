---
id: FW-071
title: "Create first map: Abandoned House"
epic: MAP
priority: high
estimated_complexity: large
dependencies: [FW-021, FW-041]
created: 2026-01-07
---

## Description

Build the first playable map - an abandoned house. Small size and low complexity makes it ideal for learning and rapid iteration. This establishes the map creation pipeline.

## Acceptance Criteria

- [ ] Small map layout (8-12 rooms)
- [ ] Entrance/spawn area
- [ ] Multiple room types (bedroom, bathroom, kitchen, etc.)
- [ ] Hiding spots (closets, under beds)
- [ ] Doors that can be opened/closed
- [ ] Light switches functional
- [ ] NavMesh for entity pathfinding
- [ ] Evidence spawn points in each room
- [ ] Entity favorite room designation
- [ ] PS1/PS2 aesthetic (low-poly, vertex lighting)

## Technical Notes

Per GDD: "Tight corridors, limited hiding spots" for high tension.

Art direction: PS1/PS2 era with modern lighting. Low-poly models, 256x256 or 512x512 textures.

Procedural elements:
- Entity spawn room (random)
- Evidence spawn locations
- Item pickup locations

## Out of Scope

- Additional maps
- Environmental storytelling details
- Detailed props/furniture
