---
id: FW-064
title: "Implement optional banishment phase endgame"
epic: FLOW
priority: medium
estimated_complexity: large
dependencies: [FW-061, FW-044]
created: 2026-01-07
phase: post-mvp
---

## Description

Add an optional endgame phase after correct entity identification. Teams can choose to extract safely or attempt a risky banishment ritual for bonus rewards. Each entity has a unique banishment requirement.

## Acceptance Criteria

### Post-Identification Choice
- [ ] After correct identification: Extract vs Attempt Banishment prompt
- [ ] Extract safely: Standard rewards, investigation ends
- [ ] Attempt banishment: Risk additional danger for 2x rewards

### Entity-Specific Banishment Rituals
| Entity | Requirement | Risk |
|--------|-------------|------|
| Phantom | Photograph during manifestation 3 times | Must be close; attacks after each photo |
| Demon | Place holy water in 4 corners simultaneously | Requires 4 player coordination; constant hunts |
| Wraith | Complete salt circle around manifestation | Salt must be unbroken |
| Mare | Keep all lights on for 3 minutes | Entity targets fuse box |
| Revenant | Trap in room using crucifix barriers | 3m/s chase speed |
| Listener | Complete ritual in perfect silence | Any voice triggers attack |

### Cultist's Final Chance
- [ ] Even discovered Cultists can sabotage banishment
- [ ] Break salt circles
- [ ] Flip breakers (Mare)
- [ ] Make noise (Listener)
- [ ] Mislead about ritual requirements

### Rewards Structure
| Outcome | XP | Currency |
|---------|-----|----------|
| No identification | 0.5x | 0.5x |
| Correct ID + extract | 1.0x | 1.0x |
| Correct ID + banishment | 2.0x | 2.0x |
| Failed banishment (wipe) | 0.25x | 0.25x |

## Technical Notes

Post-MVP priority because:
- Core social deduction must be solid first
- Requires significant per-entity content
- Can be major update to re-engage players

## Out of Scope

- Additional ritual types
- Ritual item crafting
