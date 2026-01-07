---
id: FW-024
title: "Implement hunt protection items"
epic: FPS
priority: high
estimated_complexity: medium
dependencies: [FW-022, FW-023]
created: 2026-01-07
completed: 2026-01-08
---

## Description

Create protection items that provide counterplay against entity hunts. These items add strategic depth and resource management to the investigation.

## Acceptance Criteria

### Crucifix
- [x] Prevents hunt if entity attempts to hunt within 3m radius
- [x] 2 charges per crucifix
- [x] Must be placed BEFORE hunt begins
- [x] Does not stop active hunts
- [x] Visual feedback when charge consumed
- [x] Demon has reduced range (2m)

### Sage Bundle
- [x] Blinds entity for 5 seconds during active hunt
- [x] Prevents new hunts for 60 seconds after use
- [x] 1 charge per bundle
- [x] Demon: reduced to 30 seconds prevention
- [x] Smoke visual effect
- [x] Can be used while moving

### Salt Line
- [x] Reveals entity footsteps when crossed
- [x] Slows some entities temporarily
- [x] 3 uses per salt pile
- [x] Wraith ignores salt entirely (behavioral tell)
- [x] Footprint UV-visible for identification

## Technical Notes

Protection items are selected during equipment phase like other equipment. Limited uses create resource management decisions.

Salt is unique - primarily for entity identification (Wraith ignores it) rather than protection. Creates tactical placement decisions.

Items integrate with FW-042 hunt system for trigger prevention and FW-041 behavioral tells.

## Out of Scope

- Equipment variants/upgrades
- Additional protection item types

## Implementation Notes

### Files Created

| File | Purpose |
|------|---------|
| `src/equipment/protection_item.gd` | ProtectionItem base class extending Equipment |
| `src/equipment/crucifix.gd` | Crucifix implementation |
| `src/equipment/sage_bundle.gd` | Sage Bundle implementation |
| `src/equipment/salt.gd` | Salt implementation |
| `tests/test_protection_item.gd` | 29 unit tests |
| `tests/test_crucifix.gd` | 25 unit tests |
| `tests/test_sage_bundle.gd` | 25 unit tests |
| `tests/test_salt.gd` | 32 unit tests |

### Files Modified

| File | Changes |
|------|---------|
| `src/equipment/equipment.gd` | Added CRUCIFIX, SAGE_BUNDLE, SALT to EquipmentType enum |
| `src/equipment/equipment_slot.gd` | Added type mappings for protection items |
| `src/core/managers/event_bus.gd` | Added protection item signals (hunt_starting, hunt_prevented, entity_blinded, etc.) |
| `CLAUDE.md` | Added Godot executable path and updated build commands |

### Architecture

**ProtectionItem** (extends Equipment):
- Adds charge management (max_charges, consume_charge)
- Adds placement system (place_at, is_placed, get_placed_position)
- Placement modes: HELD (sage) vs PLACED (crucifix, salt)
- Demon modifiers for radius and duration
- Network sync for charges and placement state

**Crucifix**:
- Listens to `hunt_starting` signal from EventBus
- Checks entity distance to placed crucifix
- Emits `hunt_prevented` when successful
- Demon radius reduced via multiplier (0.667)

**Sage Bundle**:
- HELD mode - triggers on use, doesn't require placement
- Emits `entity_blinded` during active hunt
- Starts prevention timer, emits `hunt_prevention_started/ended`
- Creates smoke visual effect

**Salt**:
- Creates Area3D detection zone when placed
- Triggers on entity collision
- Wraith check returns false (doesn't consume charge, emits behavioral tell)
- Creates UV-visible footprints

### Test Results

```
Tests: 111 new tests for protection items
Total: 391 tests across 16 scripts
Passing: 389 (2 pre-existing "risky" tests in test_interaction_manager.gd)
```

### EventBus Signals Added

```gdscript
# Pre-hunt signal for prevention
signal hunt_starting(entity_position: Vector3, entity: Node)

# Protection item signals
signal hunt_prevented(location: Vector3, charges_remaining: int)
signal entity_blinded(duration: float)
signal hunt_prevention_started(duration: float)
signal hunt_prevention_ended
signal salt_triggered(location: Vector3)
signal protection_item_placed(item_type: String, location: Vector3)
signal protection_item_depleted(item_type: String, location: Vector3)
```
