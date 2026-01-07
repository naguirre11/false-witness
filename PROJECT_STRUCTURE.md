# Project Structure

**Last Updated**: 2026-01-08

## Directory Overview

```
false_witness/
├── addons/                    # Third-party addons
│   ├── godotsteam/           # GodotSteam GDExtension (Steam integration)
│   └── gut/                  # GUT v9.3.0 (testing framework)
├── assets/                    # Game assets (textures, models, sounds)
├── cc_workflow/              # Claude Code workflow configuration
├── docs/                     # Project documentation
│   ├── False_Witness_GDD.docx
│   ├── False_Witness_GDD.md
│   └── False_Witness_Design_Supplement.md
├── handoffs/                 # Session handoffs for context management
│   └── session_summaries/    # End-of-session context dumps
├── scenes/                   # Godot scene files (.tscn)
│   ├── player/              # Player-related scenes
│   └── ui/                  # UI scenes
├── src/                      # Source code
│   ├── core/                 # Core systems
│   │   ├── managers/         # Autoload managers
│   │   ├── networking/       # Network-related resources
│   │   ├── steam_manager.gd  # Steam initialization
│   │   └── network_manager.gd # Lobby & P2P networking
│   ├── interaction/          # Interaction system
│   └── player/              # Player systems
├── tests/                    # GUT test files
├── tickets/                  # Development tickets
│   ├── completed/           # Finished tickets
│   ├── dev_in_progress/     # Active ticket (only ONE)
│   ├── draft/               # Tickets being drafted
│   ├── for_review/          # Completed, awaiting review
│   ├── ready/               # Ready to work on
│   └── PRIORITIZATION.md    # Ticket queue
└── project.godot            # Godot project configuration
```

## Core Files

### Autoloads (Load Order)

| #  | Autoload | Path | Purpose |
|----|----------|------|---------|
| 1 | SteamManager | `src/core/steam_manager.gd` | Steam API initialization |
| 2 | NetworkManager | `src/core/network_manager.gd` | Dual backend (Steam + ENet) networking |
| 3 | EventBus | `src/core/managers/event_bus.gd` | Global signal hub |
| 4 | GameManager | `src/core/managers/game_manager.gd` | Game state machine |

### Source Code Structure

```
src/
├── core/
│   ├── managers/
│   │   ├── event_bus.gd      # Global signals
│   │   └── game_manager.gd   # State machine
│   ├── networking/
│   │   └── player_data.gd    # Synchronized player state (PlayerData resource)
│   ├── steam_manager.gd      # Steam init
│   └── network_manager.gd    # Dual backend networking (Steam + ENet)
├── interaction/
│   ├── interactable.gd       # Base class for interactable objects
│   ├── interaction_manager.gd # Raycast detection and input handling
│   └── interaction_prompt_ui.gd # UI component for interaction prompts
└── player/
    └── player_controller.gd  # First-person movement, look, sprint, crouch
```

### Scene Files

```
scenes/
├── player/
│   └── player.tscn           # Player scene (CharacterBody3D + InteractionManager)
└── ui/
    └── interaction_prompt.tscn # Interaction prompt UI
```

### Test Files

```
tests/
├── test_example.gd            # Example test (can be deleted)
├── test_event_bus.gd          # EventBus signal tests (19 tests)
├── test_game_manager.gd       # GameManager state tests (15 tests)
├── test_game_manager_timer.gd # GameManager timer tests (14 tests)
├── test_network_manager.gd    # NetworkManager + PlayerData tests (17 tests)
├── test_player_controller.gd  # PlayerController tests (45 tests)
├── test_interactable.gd       # Interactable base class tests (30 tests)
├── test_interaction_manager.gd # InteractionManager tests (24 tests)
└── test_interaction_prompt_ui.gd # InteractionPromptUI tests (12 tests)
```

## Key Systems

### GameManager States

```
NONE -> LOBBY -> SETUP -> INVESTIGATION <-> HUNT -> RESULTS
                              |                       |
                              v                       |
                        DELIBERATION -----------------+
```

### PlayerController

First-person character controller with:
- WASD movement (walk 4.0, sprint 7.0, crouch 2.0 m/s)
- Mouse look with sensitivity settings
- Sprint with stamina (100 max, 20/s drain, 15/s regen after 1s)
- Crouch with collision height adjustment
- Head bob (optional, configurable)
- Footstep signals for audio

**Signals:**
- `stamina_changed(current: float, maximum: float)`
- `crouched(is_crouching: bool)`
- `footstep`

**Player Scene Structure:**
```
Player (CharacterBody3D)
  - CollisionShape3D (CapsuleShape3D)
  - Head (Node3D)
    - Camera3D
    - EquipmentHolder (Node3D)
  - FootstepPlayer (AudioStreamPlayer3D)
  - InteractionManager (Node)
```

### Interaction System

Raycast-based interaction system for interacting with environment objects.

**Interactable** (Node3D base class):
- Interaction types: USE, PICKUP, TOGGLE, EXAMINE
- Configurable: prompt, range (2.5m), cooldown (0.2s), one_shot
- Network sync via EventBus signals
- Virtual methods: `_can_interact_impl()`, `_interact_impl()`, `_sync_interaction()`

**Signals:**
- `interacted(player: Node)`
- `interaction_enabled_changed(enabled: bool)`

**InteractionManager** (Node):
- Raycasts from camera center at 20Hz
- Physics layer 4 detection (mask = 8)
- E key triggers interaction

**Signals:**
- `target_changed(new_target: Interactable)`
- `interaction_performed(target: Interactable, success: bool)`

### EventBus Signals

**Game State:**
- `game_state_changed(old_state: int, new_state: int)`

**Player:**
- `player_joined(player_id: int)`
- `player_left(player_id: int)`
- `player_died(player_id: int)`
- `player_became_echo(player_id: int)`

**Evidence:**
- `evidence_detected(evidence_type: String, location: Vector3, strength: float)`
- `evidence_recorded(evidence_type: String, equipment_type: String)`

**Entity:**
- `hunt_started()`
- `hunt_ended()`
- `entity_tell_triggered(tell_type: String)`

**Cultist:**
- `cultist_ability_used(ability_type: String)`
- `evidence_contaminated(evidence_type: String)`

**Interaction:**
- `player_interacted(player_id: int, interactable_path: String)`
- `interactable_state_changed(interactable_path: String, state: Dictionary)`

**Match Flow:**
- `deliberation_started()`
- `vote_cast(voter_id: int, target_id: int)`
- `match_ended(result: String)`

**Timer:**
- `phase_timer_tick(time_remaining: float)` - Every second during timed phases
- `phase_timer_expired(state: int)` - When timer hits zero
- `phase_timer_extended(additional_seconds: float)` - On time extension

## Configuration Files

| File | Purpose |
|------|---------|
| `project.godot` | Godot project settings, autoloads |
| `.gutconfig.json` | GUT test framework settings |
| `gdlintrc` | GDScript linting rules |
| `gdformatrc` | GDScript formatting rules |

## Physics Layers

| Layer | Name | Purpose |
|-------|------|---------|
| 1 | World | Static environment |
| 2 | Player | Player collision |
| 3 | Entity | Ghost/entity collision |
| 4 | Interactable | Interactive objects |
| 5 | Equipment | Held equipment |

## Input Actions

| Action | Default Key |
|--------|-------------|
| move_forward | W |
| move_backward | S |
| move_left | A |
| move_right | D |
| sprint | Left Shift |
| crouch | Left Ctrl |
| interact | E |
| use_equipment | Left Mouse |
| toggle_flashlight | F |
