---
id: FW-021
title: "Create first-person player controller"
epic: FPS
priority: high
estimated_complexity: medium
dependencies: [FW-001]
created: 2026-01-07
---

## Description

Implement the core first-person character controller with smooth movement, mouse look, and basic physics interaction.

## Acceptance Criteria

- [ ] WASD movement with configurable speed
- [ ] Mouse look with sensitivity settings
- [ ] Sprint (shift) with stamina cost
- [ ] Crouch (ctrl) for hiding
- [ ] Smooth acceleration/deceleration
- [ ] Collision with environment
- [ ] Footstep sounds tied to movement
- [ ] Head bob (optional, configurable)
- [ ] Works in networked context (local prediction)

## Technical Notes

Player scene structure:
```
Player (CharacterBody3D)
  - CollisionShape3D
  - Head (Node3D) - pivot for look
    - Camera3D
    - EquipmentHolder (Node3D)
  - FootstepPlayer (AudioStreamPlayer3D)
```

## Out of Scope

- Equipment/item system
- Interaction system
- Death/respawn
