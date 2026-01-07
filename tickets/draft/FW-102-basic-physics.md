---
id: FW-102
title: "Implement basic physics interactions"
epic: FPS
priority: low
estimated_complexity: medium
dependencies: [FW-022]
created: 2026-01-07
phase: post-launch
---

## Description

Add targeted physics interactions for emergent gameplay and clip-worthy moments. Not full physics simulation - focused on specific high-value interactions.

## Acceptance Criteria

### Grabbable Objects
- [ ] Small objects (books, bottles, tools) can be picked up
- [ ] Objects can be thrown
- [ ] Throwing creates noise (attracts entity)
- [ ] Use as distraction (throw to draw entity away)
- [ ] Poltergeist throws these at players

### Ragdoll Deaths
- [ ] Player death triggers ragdoll physics
- [ ] Body position indicates attack location
- [ ] Echo spawns at ragdoll position
- [ ] Creates memorable death moments

### Moveable Furniture (Limited)
- [ ] Select heavy objects (chairs, small tables) can be pushed
- [ ] Can block doorways temporarily
- [ ] Entity breaks through after delay
- [ ] Moving furniture creates noise

## Technical Notes

Post-launch priority because:
- Core loop doesn't require physics
- Networking physics adds complexity
- Can add incrementally (ragdoll first, then throwables)
- Nice-to-have for streams, not essential

**What NOT to include:**
- Full physics on all objects
- Object value systems
- Physics puzzles
- Climbable objects

## Out of Scope

- Comprehensive physics simulation
- Physics-based puzzles
