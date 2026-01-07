---
id: FW-101
title: "Implement Portent Deck match modifier system"
epic: FLOW
priority: low
estimated_complexity: medium
dependencies: [FW-003, FW-041]
created: 2026-01-07
phase: post-launch
---

## Description

Add a roguelike variance system where one card is drawn before each investigation, modifying match rules. Creates replay variety beyond entity/map randomization.

## Acceptance Criteria

### Pre-Match Draw
- [ ] One card drawn from Portent Deck at match start
- [ ] Card revealed to ALL players including Cultist
- [ ] 3-second reveal animation

### Card Pool
| Card | Effect |
|------|--------|
| The Moon | Entity hunts 25% less frequently |
| The Tower | One random evidence type won't appear |
| The Hermit | Proximity voice range reduced 50% |
| The Fool | Cultist gets +1 contamination charge |
| The Star | All players start at 75% sanity |
| The Devil | 25% chance entity ignores hiding spots |
| The Lovers | Two players "linked" - if one dies, both die |
| The Wheel | Evidence/entity re-randomized halfway through |
| The Sun | All lights on; entity can't turn them off |
| Blank Card | No modifier (standard match) |

### Lobby Options
- [ ] Portent Deck toggle (enable/disable)
- [ ] Custom lobby can exclude specific cards
- [ ] Rarity weights (Wheel: 2%, Blank: 20%)

## Technical Notes

Post-launch priority because:
- Core mechanics must be balanced first
- Requires extensive playtesting
- Easy to add incrementally (3-4 cards → expand)
- Good for seasonal events

## Out of Scope

- Card collection/unlocks
- Multiple cards per match
