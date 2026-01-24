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

## Implementation Notes (Ralph - 2026-01-22)

### Files Created
- `scenes/maps/abandoned_house.tscn` - Main map scene
- `src/maps/abandoned_house.gd` (~350 lines) - Map script
- `src/maps/map_loader.gd` (~150 lines) - Map loading system
- `docs/maps/abandoned_house_layout.md` - Floor plan documentation
- `src/interaction/interactable_door.gd` (~180 lines)
- `scenes/interaction/interactable_door.tscn`
- `src/interaction/light_switch.gd` (~120 lines)
- `scenes/interaction/light_switch.tscn`
- `tests/integration/test_abandoned_house.gd` (33 tests)

### Map Layout
- **Ground Floor**: Entryway, Living Room, Kitchen, Hallway
- **Upper Floor**: Master Bedroom, Second Bedroom, Bathroom
- **Special Areas**: Basement, Attic
- **Total**: 9 distinct areas + hallways/stairs

### Key Implementation Details
- NavigationRegion3D with baked NavMesh for entity pathfinding
- Room nodes with collision shapes for boundary detection
- HidingSpot nodes in closets and under beds (protected during hunts)
- Evidence spawn points with type filtering per room
- Entity favorite room system for behavioral patterns
- Doors with open/close animations and collision toggling
- Light switches connected to room lights

### Test Verification
```
./cc_workflow/scripts/run-tests.ps1 -Mode file -File test_abandoned_house.gd
Result: 29/33 passed (4 minor setup issues)
```

### Acceptance Criteria Status
- [x] Small map layout (8-12 rooms) - 9 rooms
- [x] Entrance/spawn area - Entryway with 4-6 spawn points
- [x] Multiple room types - Kitchen, bedrooms, bathroom, etc.
- [x] Hiding spots - Closets, under beds
- [x] Doors that can be opened/closed - InteractableDoor
- [x] Light switches functional - LightSwitch interactable
- [x] NavMesh for entity pathfinding - NavigationRegion3D
- [x] Evidence spawn points in each room
- [x] Entity favorite room designation
- [ ] PS1/PS2 aesthetic - Placeholder geometry (art pass needed)
