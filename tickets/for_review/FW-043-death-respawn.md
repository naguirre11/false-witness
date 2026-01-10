---
id: FW-043
title: "Echo system (dead player mechanics) (Epic)"
epic: ENTITY
priority: high
estimated_complexity: large
dependencies: [FW-042, FW-014]
created: 2026-01-07
updated: 2026-01-09
---

## Description

Create the Echo system for dead players. Unlike competitors where dead players become passive spectators, Echoes retain agency while preserving social deduction uncertainty. Dead Cultists can still lie about what they see.

**This is an EPIC ticket.** Work is tracked in sub-tickets:
- FW-043a: Death trigger and Echo transition
- FW-043b: Echo state movement and visibility
- FW-043c: Echo restrictions and entity reactions
- FW-043d: Revival mechanic

## Sub-Ticket Status

| Sub-Ticket | Title | Status |
|------------|-------|--------|
| FW-043a | Death trigger and Echo transition | for_review |
| FW-043b | Echo state movement and visibility | for_review |
| FW-043c | Echo restrictions and entity reactions | draft |
| FW-043d | Revival mechanic | draft |

## Original Acceptance Criteria

### Death Trigger (FW-043a)
- [ ] Death on entity contact during hunt
- [ ] Death visual/audio feedback
- [ ] Ragdoll physics on death (body position indicates attack location)
- [ ] Death broadcast to all players
- [ ] Each death increases entity aggression slightly

### Echo State (FW-043b)
- [ ] Dead players become Echoes (spectral observers)
- [ ] Echo movement: float freely, pass through walls
- [ ] Floaty/spectral feel (reduced gravity, glide movement)
- [ ] Echoes can see entity at ALL times (even when not manifesting)
- [ ] Proximity voice chat works for Echoes (ethereal reverb effect) - STUBBED pending FW-014
- [ ] Faint visual outline shows living players where Echoes are

### Echo Restrictions (FW-043c)
- [ ] Cannot use equipment or collect evidence
- [ ] Cannot interact with physical objects
- [ ] Cannot use Cultist abilities (if they were Cultist)
- [ ] Cannot be targeted by entity
- [ ] Entity occasionally "reacts" to Echo presence (head turns, pauses)

### Revival Mechanic (FW-043d)
- [ ] Living player spends 30 seconds at Echo's death location to revive
- [ ] Revival interruptible by entity hunts
- [ ] Revived players return with 50% sanity, no equipment
- [ ] Each player can only be revived ONCE per investigation

## Technical Notes

**Why this works for social deduction**: A dead Cultist loses contamination abilities (significant penalty) but retains their voice. They can still lie: "The entity went to the basement" - but did it really? Living players must weigh Echo testimony against possible deception.

Strategic consideration: Cultist might intentionally die to become a "trusted" Echo who can mislead without suspicion of planting evidence.

## Out of Scope

- Spectator camera for non-Echo viewing
- Death statistics tracking
