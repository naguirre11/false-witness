---
id: FW-072
title: "Create second map: Office Building"
epic: MAP
priority: medium
estimated_complexity: large
dependencies: [FW-071]
created: 2026-01-24
phase: 2
---

## Description

Design and implement the second investigation location - a multi-floor corporate office building. Larger than the Abandoned House with more rooms and vertical gameplay.

## Map Specifications

| Property | Value |
|----------|-------|
| Size | Large (3 floors) |
| Rooms | 25-30 |
| Players | 4-6 |
| Difficulty | Medium |

## Acceptance Criteria

### Layout
- [ ] Ground floor: Lobby, reception, break room, bathrooms, storage
- [ ] Second floor: Open office area, meeting rooms, manager offices
- [ ] Third floor: Executive suite, server room, rooftop access
- [ ] Elevator shaft (entity can use, players cannot)
- [ ] Two stairwells (opposite sides of building)

### Key Locations
- [ ] **Server Room**: Always cold, good for temperature readings
- [ ] **Break Room**: Flickering lights, vending machines for interactions
- [ ] **Executive Office**: Large windows, entity favorite room potential
- [ ] **Open Office**: Cubicle maze, difficult hiding spots
- [ ] **Basement**: Fuse box, generator, cramped spaces

### Interactive Elements
- [ ] Working elevator call buttons (audio cue only - elevator broken)
- [ ] Light switches per room/zone
- [ ] Computer monitors that can flicker
- [ ] Office chairs that can spin/move
- [ ] Vending machine interactions
- [ ] Printer that can activate

### Hiding Spots
- [ ] Under desks (cubicles)
- [ ] Storage closets (3 locations)
- [ ] Server room cabinets
- [ ] Executive bathroom
- [ ] Maintenance closet

### Audio Design
- [ ] HVAC ambient hum
- [ ] Flickering fluorescent buzz
- [ ] Distant elevator dings
- [ ] Computer fan white noise

### Evidence Spawn Points
- [ ] 8-10 spawn points per evidence type
- [ ] Balanced distribution across floors
- [ ] Ghost writing books spawn on desks
- [ ] Temperature zones in server room, break room, basement

### Navigation
- [ ] NavMesh for entity pathfinding
- [ ] Clear floor transitions via stairs
- [ ] Elevator shaft as entity shortcut

## Technical Notes

Building is approximately 50m x 30m footprint, 12m total height.

Vertical design tests entity pathfinding across floors.

## Out of Scope

- Working elevators for players
- Outdoor areas beyond rooftop
- Vehicle parking garage
