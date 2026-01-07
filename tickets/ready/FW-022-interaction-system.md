---
id: FW-022
title: "Implement player interaction system"
epic: FPS
priority: high
estimated_complexity: medium
dependencies: [FW-021]
created: 2026-01-07
---

## Description

Create the raycast-based interaction system allowing players to interact with objects, doors, equipment, and evidence in the environment.

## Acceptance Criteria

- [ ] Raycast from camera center detects interactables
- [ ] Interaction prompt UI when looking at interactable
- [ ] E key triggers interaction
- [ ] Interactable base class/interface for objects
- [ ] Different interaction types (use, pickup, toggle)
- [ ] Interaction range configurable per object
- [ ] Network-synced interactions (doors, switches)
- [ ] Interaction cooldown to prevent spam

## Technical Notes

Interactable interface:
```gdscript
func can_interact(player: Player) -> bool
func get_interaction_prompt() -> String
func interact(player: Player) -> void
```

Use Area3D or raycast layers for detection.

## Out of Scope

- Specific interactable implementations (doors, evidence)
- Inventory system
- Equipment usage
