# Project Structure

**Last Updated**: 2026-01-07

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
├── src/                      # Source code
│   └── core/                 # Core systems
│       ├── managers/         # Autoload managers
│       ├── steam_manager.gd  # Steam initialization
│       └── network_manager.gd # Lobby & P2P networking
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
| 2 | NetworkManager | `src/core/network_manager.gd` | Steam lobbies and P2P |
| 3 | EventBus | `src/core/managers/event_bus.gd` | Global signal hub |
| 4 | GameManager | `src/core/managers/game_manager.gd` | Game state machine |

### Source Code Structure

```
src/
└── core/
    ├── managers/
    │   ├── event_bus.gd      # Global signals
    │   └── game_manager.gd   # State machine
    ├── steam_manager.gd      # Steam init
    └── network_manager.gd    # Networking
```

### Test Files

```
tests/
├── test_example.gd           # Example test (can be deleted)
├── test_event_bus.gd         # EventBus signal tests
└── test_game_manager.gd      # GameManager state tests
```

## Key Systems

### GameManager States

```
NONE -> LOBBY -> SETUP -> INVESTIGATION <-> HUNT -> RESULTS
                              |                       |
                              v                       |
                        DELIBERATION -----------------+
```

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

**Match Flow:**
- `deliberation_started()`
- `vote_cast(voter_id: int, target_id: int)`
- `match_ended(result: String)`

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
