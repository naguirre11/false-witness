---
id: FW-042d
title: "Entity-specific hunt variations"
epic: ENTITY
priority: high
estimated_complexity: medium
dependencies: [FW-042b, FW-042c]
created: 2026-01-09
updated: 2026-01-09
parent_ticket: FW-042
---

## Description

Create the framework for entity-specific hunt behaviors. Each entity type should have distinct hunt characteristics that affect sanity thresholds, detection, speed, duration, and special conditions.

## Acceptance Criteria

- [ ] Entity-specific sanity thresholds (Demon: 70%, Shade: 35%)
- [ ] Banshee ignores team sanity, only checks target's sanity
- [ ] Listener bypasses sanity threshold if voice-triggered
- [ ] Speed variations framework (Revenant: 1 m/s → 3 m/s when chasing)
- [ ] Duration variations (base 20-40s, scales with map)
- [ ] Special hunt conditions (Mare: can't hunt in lit rooms)
- [ ] Hunt cooldown variations (Demon: 20s instead of 25s)

## Technical Notes

**Implementation**: Virtual methods in Entity.gd that subclasses override

**Entity Virtual Methods**:
```gdscript
# Sanity threshold
func get_hunt_sanity_threshold() -> float:
    return hunt_sanity_threshold  # Default 50.0

func should_ignore_team_sanity() -> bool:
    return false  # Banshee: true

func can_voice_trigger_hunt() -> bool:
    return false  # Listener: true

# Speed
func get_hunt_speed_for_awareness(aware: bool) -> float:
    return hunt_aware_speed if aware else hunt_unaware_speed

func _update_hunt_speed(delta: float) -> void:
    pass  # Revenant: accelerate over time

# Conditions
func can_hunt_in_current_conditions() -> bool:
    return true  # Mare: check room lighting

func can_ignore_hiding_spots() -> bool:
    return false  # Some entities: true
```

**Entity-Specific Values Table**:
| Entity | Threshold | Cooldown | Speed | Special |
|--------|-----------|----------|-------|---------|
| Standard | 50% | 25s | 2.5 m/s | - |
| Demon | 70% | 20s | 2.5 m/s | Hunts early/often |
| Shade | 35% | 25s | 2.5 m/s | Very reluctant |
| Banshee | Target 50% | 25s | 2.0→3.0 m/s | Single target, ignores team |
| Mare | 50% | 25s | 2.5 m/s | No hunt in lit rooms |
| Revenant | 50% | 25s | 1.0→3.0 m/s | Accelerates when chasing |
| Listener | Any/Voice | 25s | 2.5 m/s | Voice triggers hunt |

**EntityManager Integration**:
- Check entity's `can_hunt_in_current_conditions()` before hunt
- Use entity's `get_hunt_sanity_threshold()` for threshold check
- Support voice-triggered hunts from FW-014 (Voice Chat)

## Out of Scope

- Actual entity implementations (FW-044, FW-046, etc.)
- Voice chat system integration details (FW-014)
- Room lighting system (needed for Mare)
