---
id: FW-043
title: "Implement Echo system (dead player mechanics)"
epic: ENTITY
priority: high
estimated_complexity: large
dependencies: [FW-042, FW-014]
created: 2026-01-07
updated: 2026-01-07
---

## Description

Create the Echo system for dead players. Unlike competitors where dead players become passive spectators, Echoes retain agency while preserving social deduction uncertainty. Dead Cultists can still lie about what they see.

## Acceptance Criteria

### Death Trigger
- [ ] Death on entity contact during hunt
- [ ] Death visual/audio feedback
- [ ] Ragdoll physics on death (body position indicates attack location)
- [ ] Death broadcast to all players

### Echo State
- [ ] Dead players become Echoes (spectral observers)
- [ ] Echo movement: float freely, pass through walls
- [ ] Floaty/spectral feel (reduced gravity, glide movement)
- [ ] Echoes can see entity at ALL times (even when not manifesting)
- [ ] Proximity voice chat works for Echoes (ethereal reverb effect)
- [ ] Faint visual outline shows living players where Echoes are

### Echo Restrictions
- [ ] Cannot use equipment or collect evidence
- [ ] Cannot interact with physical objects
- [ ] Cannot use Cultist abilities (if they were Cultist)
- [ ] Cannot be targeted by entity
- [ ] Entity occasionally "reacts" to Echo presence (head turns, pauses)

### Revival Mechanic
- [ ] Living player spends 30 seconds at Echo's death location to revive
- [ ] Revival interruptible by entity hunts
- [ ] Revived players return with 50% sanity, no equipment
- [ ] Each player can only be revived ONCE per investigation

### Aggression
- [ ] Each death increases entity aggression slightly

## Technical Notes

**Why this works for social deduction**: A dead Cultist loses contamination abilities (significant penalty) but retains their voice. They can still lie: "The entity went to the basement" - but did it really? Living players must weigh Echo testimony against possible deception.

Strategic consideration: Cultist might intentionally die to become a "trusted" Echo who can mislead without suspicion of planting evidence.

## Out of Scope

- Spectator camera for non-Echo viewing
- Death statistics tracking
