---
id: FW-023
title: "Create equipment slot and inventory system"
epic: FPS
priority: high
estimated_complexity: medium
dependencies: [FW-022]
created: 2026-01-07
completed: 2026-01-08
---

## Description

Implement the 3-slot equipment system where players select and carry investigation tools. Equipment is selected pre-investigation and determines what evidence types a player can detect.

## Acceptance Criteria

- [x] 3 equipment slots per player
- [x] Equipment selection during EQUIPMENT_SELECT phase
- [x] Scroll wheel / number keys to switch active equipment
- [x] Equipment visually held in first-person view
- [x] Equipment base class with common interface
- [x] Equipment state synced across network
- [x] Cannot change equipment after investigation starts

## Technical Notes

Equipment types from GDD:
- EMF Reader
- Spirit Box
- Journal (Ghost Writing)
- Thermometer
- UV Flashlight
- DOTS Projector
- Video Camera
- Parabolic Mic

Each player selects 3, so team must coordinate coverage.

## Out of Scope

- Individual equipment implementations
- Evidence detection logic
- Equipment variants/upgrades

## Implementation Notes

### Files Created

| File | Purpose |
|------|---------|
| `src/equipment/equipment.gd` | Equipment base class (Node3D) with use/toggle/cooldown system |
| `src/equipment/equipment_slot.gd` | EquipmentSlot resource for slot management |
| `src/equipment/equipment_manager.gd` | EquipmentManager node for player equipment handling |
| `tests/test_equipment.gd` | 36 unit tests for Equipment base class |
| `tests/test_equipment_slot.gd` | 30 unit tests for EquipmentSlot |
| `tests/test_equipment_manager.gd` | 40 unit tests for EquipmentManager |

### Files Modified

| File | Changes |
|------|---------|
| `scenes/player/player.tscn` | Added EquipmentManager node with equipment_holder_path |
| `src/core/managers/event_bus.gd` | Added equipment signals: loadout_changed, slot_changed, equipment_used |

### Architecture

**Equipment** (Node3D base class):
- Three use modes: HOLD, TOGGLE, INSTANT
- States: INACTIVE, ACTIVE, COOLDOWN
- Virtual methods: `_use_impl()`, `_stop_using_impl()`, `get_detectable_evidence()`
- Network sync support via EventBus signals
- Hunt-aware (can disable during hunt)

**EquipmentSlot** (Resource):
- Stores equipment type (-1 for empty)
- Tracks equipment instance reference
- Static helpers for type↔name conversion
- Serialization for network sync

**EquipmentManager** (Node):
- 3-slot loadout management
- Scroll wheel + number keys (1-3) for slot switching
- Loadout locking (prevents changes after investigation starts)
- Instantiates placeholder Equipment when scenes not found
- Equipment holder integration (Head/EquipmentHolder)

### EventBus Signals Added

```gdscript
signal equipment_loadout_changed(player_id: int, loadout: Array)
signal equipment_slot_changed(player_id: int, slot_index: int)
signal equipment_used(player_id: int, equipment_path: String, is_using: bool)
```

### Player Scene Structure

```
Player (CharacterBody3D)
├── CollisionShape3D
├── Head (Node3D)
│   ├── Camera3D
│   └── EquipmentHolder (Node3D)  # Equipment instances added here
├── FootstepPlayer (AudioStreamPlayer3D)
├── InteractionManager (Node)
└── EquipmentManager (Node)  # NEW
```

### Testing

```bash
# Run all tests
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit

# Run equipment tests only
godot --headless -s addons/gut/gut_cmdln.gd -gtest=test_equipment*.gd -gexit
```

**Test Count**: 106 new tests (36 + 30 + 40)
