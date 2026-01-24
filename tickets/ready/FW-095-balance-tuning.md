---
id: FW-095
title: "Balance tuning pass"
epic: FOUNDATION
priority: high
estimated_complexity: medium
dependencies: [FW-044, FW-051, FW-061]
created: 2026-01-24
phase: 2
---

## Description

Comprehensive balance tuning based on playtesting feedback. Adjust entity difficulty, evidence spawn rates, cultist ability power, and win condition timing.

## Acceptance Criteria

### Entity Balance
- [ ] Review hunt frequency per entity
- [ ] Adjust hunt speeds (currently 1.5-3.0 m/s range)
- [ ] Balance sanity drain rates
- [ ] Tune evidence generation rates
- [ ] Verify behavioral tells are observable but not obvious

### Evidence Balance
- [ ] Equipment-derived evidence spawn timing
- [ ] Cooperative evidence difficulty (Prism, Aura)
- [ ] Trust level distribution feels fair
- [ ] Cross-verification timing windows

### Cultist Balance
- [ ] Ability cooldowns (currently 60-120s)
- [ ] Contamination decay rates (currently 30-60s)
- [ ] False evidence believability
- [ ] Discovery difficulty curve

### Timing Balance
- [ ] Investigation phase length (currently 12-15 min)
- [ ] Deliberation phase length (currently 3-5 min)
- [ ] Hunt duration and frequency
- [ ] Entity activity ramping over time

### Win Rate Targets
- [ ] Investigators correct ID: 60-70%
- [ ] Cultist wins via wrong ID: 20-25%
- [ ] Timeout/indecision: 10-15%
- [ ] Cultist caught bonus: 15-20% of investigator wins

### Configuration System
- [ ] Create BalanceConfig resource
- [ ] Expose key variables for easy tuning
- [ ] Support difficulty presets (Easy/Normal/Hard)
- [ ] Host can adjust in lobby (optional)

### Metrics Collection
- [ ] Track win rates per role
- [ ] Track evidence collection rates
- [ ] Track hunt survival rates
- [ ] Track average game length
- [ ] Export for analysis

## Technical Notes

Create centralized balance configuration:
```gdscript
class_name BalanceConfig extends Resource

# Entity
@export var base_hunt_speed: float = 1.7
@export var hunt_frequency_modifier: float = 1.0
@export var sanity_drain_per_second: float = 0.1

# Investigation
@export var investigation_time_seconds: int = 780
@export var evidence_spawn_interval: float = 30.0

# Cultist
@export var ability_cooldown_modifier: float = 1.0
@export var contamination_decay_rate: float = 0.02
```

## Out of Scope

- Per-entity individual tuning (separate tickets)
- Competitive ranked balance
- Anti-cheat considerations
