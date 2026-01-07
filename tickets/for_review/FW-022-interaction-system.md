---
id: FW-022
title: "Implement player interaction system"
epic: FPS
priority: high
estimated_complexity: medium
dependencies: [FW-021]
created: 2026-01-07
completed: 2026-01-08
---

## Description

Create the raycast-based interaction system allowing players to interact with objects, doors, equipment, and evidence in the environment.

## Acceptance Criteria

- [x] Raycast from camera center detects interactables
- [x] Interaction prompt UI when looking at interactable
- [x] E key triggers interaction
- [x] Interactable base class/interface for objects
- [x] Different interaction types (use, pickup, toggle, examine)
- [x] Interaction range configurable per object
- [x] Network-synced interactions (via EventBus signals)
- [x] Interaction cooldown to prevent spam

## Technical Notes

Interactable interface:
```gdscript
func can_interact(player: Player) -> bool
func get_interaction_prompt() -> String
func interact(player: Player) -> void
```

Use Area3D or raycast layers for detection.

## Out of Scope

- Specific interactable implementations (doors, evidence)
- Inventory system
- Equipment usage

## Implementation Notes

### Files Created

| File | Purpose |
|------|---------|
| `src/interaction/interactable.gd` | Base class for all interactable objects |
| `src/interaction/interaction_manager.gd` | Raycast detection and input handling |
| `src/interaction/interaction_prompt_ui.gd` | UI component for showing prompts |
| `scenes/ui/interaction_prompt.tscn` | Interaction prompt scene |
| `tests/test_interactable.gd` | Unit tests for Interactable (30 tests) |
| `tests/test_interaction_manager.gd` | Unit tests for InteractionManager (24 tests) |
| `tests/test_interaction_prompt_ui.gd` | Unit tests for InteractionPromptUI (12 tests) |

### Files Modified

| File | Changes |
|------|---------|
| `scenes/player/player.tscn` | Added InteractionManager node, updated collision_mask to include layer 4 |
| `src/core/managers/event_bus.gd` | Added `player_interacted` and `interactable_state_changed` signals |

### System Architecture

**Interactable** (Node3D base class):
- `InteractionType` enum: USE, PICKUP, TOGGLE, EXAMINE
- Configurable: prompt, range (default 2.5m), cooldown (0.2s), one_shot
- Signals: `interacted(player)`, `interaction_enabled_changed(enabled)`
- Network sync via EventBus `player_interacted` signal
- Virtual methods: `_can_interact_impl()`, `_interact_impl()`, `_sync_interaction()`

**InteractionManager** (Node):
- Attached to Player scene
- Raycasts from Camera3D center at 20Hz (0.05s interval)
- Uses physics layer 4 (Interactable) for detection (mask = 8)
- Handles E key input via `interact` action
- Signals: `target_changed(interactable)`, `interaction_performed(target, success)`

**InteractionPromptUI** (Control):
- Connects to InteractionManager for automatic prompt display
- Smooth fade in/out (0.15s)
- Formats prompt with key hint: "[E] Open Door"

### Physics Layers

- Layer 4: Interactable (collision_mask bit 3 = value 8)
- Player collision_mask updated to 9 (layer 1 World + layer 4 Interactable)

### Testing

```bash
# Lint passes
gdlint src/interaction/

# Unit tests (66 new tests across 3 files)
# Run when Godot is available
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

### Usage Example

```gdscript
# Create a door interactable
class_name Door
extends Interactable

var is_open: bool = false

func _ready() -> void:
    super._ready()
    interaction_type = InteractionType.TOGGLE
    interaction_prompt = "Open Door"

func _interact_impl(_player: Node) -> bool:
    is_open = !is_open
    interaction_prompt = "Close Door" if is_open else "Open Door"
    # Play animation, update collision, etc.
    return true
```
