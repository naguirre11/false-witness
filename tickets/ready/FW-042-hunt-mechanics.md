---
id: FW-042
title: "Implement entity hunt mechanics with depth"
epic: ENTITY
priority: high
estimated_complexity: large
dependencies: [FW-041, FW-024]
created: 2026-01-07
updated: 2026-01-07
---

## Description

Create the comprehensive hunt system with sanity thresholds, detection mechanics, hunt phases, and counterplay depth. This system creates the core tension between evidence collection and survival.

## Acceptance Criteria

### Hunt Triggers
- [ ] Sanity threshold system (default: 50% team average)
- [ ] Entity-specific thresholds (Demon: 70%, Shade: 35%)
- [ ] Banshee ignores team sanity, only checks target's sanity
- [ ] Listener bypasses sanity if voice-triggered

### Hunt Phases
- [ ] **Warning Phase (3s)**: Lights flicker, equipment static, entity vocalizes
- [ ] **Active Hunt (20-40s)**: Entity searches for players; duration scales with map
- [ ] **Cooldown (25s)**: Entity cannot hunt; safe window for evidence collection

### Detection Mechanics
- [ ] Base detection radius: 7 meters
- [ ] Electronics in hand: +3m (10m total)
- [ ] Voice activity: +5m (12m total)
- [ ] Line-of-sight detection triggers chase
- [ ] Entity tracks last known position when LoS broken

### Hiding Mechanics
- [ ] Hiding spots (closets, lockers) prevent entity entry
- [ ] Entity searches nearby hiding spot area then moves on
- [ ] Breaking line of sight resets tracking
- [ ] Entity-specific hiding variations (some ignore spots)

### Hunt Variations
- [ ] Framework for entity-specific hunt behaviors
- [ ] Speed variations (Revenant: 1m/s → 3m/s when chasing)
- [ ] Duration variations
- [ ] Special hunt conditions (Mare: can't hunt in lit rooms)

## Technical Notes

**Entity-specific thresholds:**
| Entity | Hunt Threshold | Cooldown | Notes |
|--------|---------------|----------|-------|
| Standard | 50% | 25s | Default |
| Shade | 35% | 25s | Very reluctant |
| Demon | 70% | 20s | Hunts early and often |
| Banshee | Target's 50% | 25s | Ignores team sanity |
| Listener | Any (voice) | 25s | Voice triggers hunt |

Hunt counterplay depth creates skill expression - experienced players can safely collect evidence during cooldowns, manage sanity, and use protection items effectively.

## Out of Scope

- Protection items (FW-024)
- Death/Echo system (FW-043)
- Specific entity implementations
