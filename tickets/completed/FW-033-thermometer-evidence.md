---
id: FW-033
title: "Implement Thermometer equipment"
epic: EVIDENCE
priority: high
estimated_complexity: medium
dependencies: [FW-031]
created: 2026-01-07
updated: 2026-01-08
---

## Description

Create the Thermometer equipment for detecting freezing temperatures. This is a solo-operation tool with a shared display (visible to nearby players), making it high-trust evidence.

**Trust Dynamic:** Solo — Low Risk (display visible to all nearby)

## Acceptance Criteria

### Equipment Implementation
- [x] Thermometer as EquipmentItem extending equipment system
- [ ] 3D model with visible digital display (deferred: art asset dependency)
- [x] Display shows temperature in Celsius
- [ ] Display visible to all nearby players (deferred: UI system dependency)

### Temperature Detection
- [x] Room-based temperature zones
- [x] Entity's active room has modified temperature
- [x] Freezing threshold: below 3°C triggers FREEZING_TEMPERATURE evidence
- [x] Natural variance: rooms have baseline 15-22°C with minor fluctuation

### Visible Breath Effect (Readily-Apparent)
- [ ] Player breath becomes visible below 3°C (deferred to FW-040)
- [ ] Breath effect visible to ALL players in room (deferred to FW-040)
- [ ] This is a Readily-Apparent evidence indicator (deferred to FW-040)
- [ ] Cannot be faked by Cultist (deferred to FW-040)

### Reading Quality System
- [x] **Strong Reading**: Stable temperature, player stationary, multiple samples
- [x] **Weak Reading**: Fluctuating, player moving through zones
- [x] Quality affects evidence confidence

### Extreme Cold Indicators
- [x] Frost detection threshold at -5°C (is_extreme_cold() method)
- [ ] Frost visual effect on windows/surfaces (deferred to FW-040)
- [ ] Visual effect visible to all (deferred to FW-040)

### Audio/Visual Feedback
- [x] Beep when reaching freezing threshold (EventBus signal)
- [ ] Display color shifts (deferred: visual system dependency)
- [x] Ambient cold audio cue (EventBus signal)

### Network Sync
- [x] Temperature zones server-authoritative
- [x] Display state synced to nearby players
- [x] Evidence registration with EvidenceManager

## Technical Notes

**Dual Evidence Nature:**
The Thermometer provides Equipment-Derived evidence (the reading), but the visible breath effect is Readily-Apparent evidence that anyone can observe without equipment. This creates redundancy that catches Cultist lies.

**Temperature Zone Design:**
- Each room has a base temperature
- Entity presence modifies the room's temperature
- Cold entities (Mare, etc.) drop temp significantly
- Temperature changes aren't instant - gradual shift over 10-20 seconds

**Cultist Consideration:**
With shared display AND visible breath, Cultist has very limited ability to lie:
- Can't claim freezing when everyone sees no breath
- Can't deny freezing when everyone sees breath
- Can only lie when alone, and even then breath is visible

## Out of Scope

- Thermal camera variant (different equipment)
- Temperature manipulation (Cultist ability - FW-052)

## Implementation Notes

### Files Created

| File | Purpose |
|------|---------|
| `src/equipment/temperature_zone.gd` | TemperatureZone class for room-based temperature areas |
| `src/equipment/thermometer.gd` | Thermometer equipment extending Equipment base class |
| `tests/test_temperature_zone.gd` | 29 unit tests for TemperatureZone |
| `tests/test_thermometer.gd` | 33 unit tests for Thermometer |

### EventBus Updates

Added 6 new signals to `src/core/managers/event_bus.gd`:

**EMF Reader (formalized existing signals):**
- `emf_beep(level: int)`
- `emf_level_5_spike`
- `emf_state_changed(player_id, level, direction, quality)`

**Thermometer:**
- `thermometer_freezing(temperature: float)`
- `thermometer_extreme_cold(temperature: float)`
- `thermometer_state_changed(player_id, temperature, quality)`

### Testing Commands

```bash
# Run thermometer tests only
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=test_thermometer.gd -gtest=test_temperature_zone.gd -gexit

# Lint thermometer source files
gdlint src/equipment/thermometer.gd src/equipment/temperature_zone.gd
```

### Test Results

All 646 project tests pass (62 new tests for thermometer system):
- test_temperature_zone.gd: 29/29 passed
- test_thermometer.gd: 33/33 passed

### Key Design Decisions

1. **TemperatureZone similar to EMFSource** - Node3D added to "temperature_zone" group, provides get_temperature() method
2. **Gradual temperature changes** - set_target_influence() for smooth transitions when entity enters/leaves
3. **Natural variance** - Sinusoidal fluctuation around base temperature for realism
4. **Reading quality** - Strong requires stationary + stable readings + inside a zone
5. **Visual effects deferred to FW-040** - Breath/frost are Readily-Apparent evidence, better handled in that ticket
6. **3D model deferred** - Requires art assets; core detection logic complete

### Usage Example

```gdscript
# Create a cold room
var zone := TemperatureZone.new()
zone.base_temperature = 18.0
zone.zone_radius = 5.0
add_child(zone)

# Simulate entity entering (cold entity)
zone.entity_enter(-20.0)  # Drops temp to -2°C over time

# Player with thermometer detects freezing
if thermometer.is_freezing():
    print("Evidence collected: FREEZING_TEMPERATURE")
```
