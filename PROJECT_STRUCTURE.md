# Project Structure

**Last Updated**: 2026-01-10

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
│   ├── entity/               # Entity AI and hunt systems
│   ├── equipment/            # Equipment system
│   ├── evidence/             # Evidence system (collection, tracking)
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
| 5 | EvidenceManager | `src/evidence/evidence_manager.gd` | Evidence collection and tracking |
| 6 | VerificationManager | `src/evidence/verification_manager.gd` | Evidence trust-level verification |
| 7 | EntityManager | `src/entity/entity_manager.gd` | Entity spawning and tracking |
| 8 | SanityManager | `src/entity/sanity_manager.gd` | Team sanity tracking |
| 9 | AudioManager | `src/core/audio_manager.gd` | Centralized audio playback and control |

### Source Code Structure

```
src/
├── core/
│   ├── audio/
│   │   ├── footstep_manager.gd  # Footstep sound with surface detection
│   │   └── surface_audio.gd     # Surface audio configuration resource
│   ├── managers/
│   │   ├── event_bus.gd      # Global signals
│   │   └── game_manager.gd   # State machine
│   ├── networking/
│   │   └── player_data.gd    # Synchronized player state (PlayerData resource)
│   ├── audio_manager.gd      # AudioManager autoload
│   ├── steam_manager.gd      # Steam init
│   └── network_manager.gd    # Dual backend networking (Steam + ENet)
├── entity/
│   ├── entity.gd             # Entity base class (CharacterBody3D)
│   ├── entity_manager.gd     # EntityManager autoload
│   ├── hunt_detection.gd     # HuntDetection static utilities
│   ├── sanity_manager.gd     # SanityManager (team sanity tracking)
│   ├── hiding_spot.gd        # HidingSpot for player concealment
│   └── hiding_spot_door.gd   # HidingSpotDoor with search mechanics
├── equipment/
│   ├── equipment.gd          # Equipment base class (Node3D)
│   ├── equipment_slot.gd     # EquipmentSlot resource for slot management
│   ├── equipment_manager.gd  # EquipmentManager for player loadout
│   ├── protection_item.gd    # ProtectionItem base class (extends Equipment)
│   ├── crucifix.gd           # Crucifix hunt prevention item
│   ├── sage_bundle.gd        # Sage Bundle entity blinding item
│   └── salt.gd               # Salt footstep detection item
├── evidence/
│   ├── evidence_enums.gd     # Evidence type/category/trust enums
│   ├── evidence.gd           # Evidence resource class
│   └── evidence_manager.gd   # Evidence collection autoload
├── interaction/
│   ├── interactable.gd       # Base class for interactable objects
│   ├── interaction_manager.gd # Raycast detection and input handling
│   └── interaction_prompt_ui.gd # UI component for interaction prompts
├── player/
│   ├── player_controller.gd  # First-person movement, look, sprint, crouch
│   └── echo_controller.gd    # Dead player Echo state controller
└── ui/
    ├── evidence_board.gd     # Evidence board panel (displays all evidence)
    └── evidence_slot.gd      # Individual evidence type slot
```

### Scene Files

```
scenes/
├── player/
│   └── player.tscn           # Player scene (CharacterBody3D + managers)
└── ui/
    ├── interaction_prompt.tscn # Interaction prompt UI
    ├── evidence_board.tscn     # Evidence board panel
    └── evidence_slot.tscn      # Evidence slot component
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
├── test_interactable.gd       # Interactable base class tests (24 tests)
├── test_interaction_manager.gd # InteractionManager tests (24 tests)
├── test_interaction_prompt_ui.gd # InteractionPromptUI tests (13 tests)
├── test_equipment.gd          # Equipment base class tests (30 tests)
├── test_equipment_slot.gd     # EquipmentSlot tests (36 tests)
├── test_equipment_manager.gd  # EquipmentManager tests (41 tests)
├── test_protection_item.gd    # ProtectionItem tests (29 tests)
├── test_crucifix.gd           # Crucifix tests (25 tests)
├── test_sage_bundle.gd        # SageBundle tests (25 tests)
├── test_salt.gd               # Salt tests (32 tests)
├── test_evidence.gd           # Evidence resource tests (42 tests)
├── test_evidence_enums.gd     # EvidenceEnums tests (51 tests)
├── test_evidence_manager.gd   # EvidenceManager tests (47 tests)
├── test_evidence_board.gd     # EvidenceBoard UI tests (20 tests)
├── test_evidence_slot.gd      # EvidenceSlot UI tests (14 tests)
├── test_audio_manager.gd      # AudioManager tests (33 tests)
├── test_surface_audio.gd      # SurfaceAudio tests (21 tests)
└── test_footstep_manager.gd   # FootstepManager tests (16 tests)
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
├── CollisionShape3D (CapsuleShape3D)
├── Head (Node3D)
│   ├── Camera3D
│   └── EquipmentHolder (Node3D)
├── FootstepPlayer (AudioStreamPlayer3D)
├── InteractionManager (Node)
└── EquipmentManager (Node)
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

### Equipment System

3-slot equipment loadout for investigation tools.

**Equipment** (Node3D base class):
- Evidence Equipment: EMF Reader, Thermometer, Ghost Writing Book, Spectral Calibrator, Spectral Lens Reader, Dowsing Rods, Aura Imager
- Protection Items: Crucifix, Sage Bundle, Salt
- Use modes: HOLD, TOGGLE, INSTANT
- States: INACTIVE, ACTIVE, COOLDOWN
- Virtual methods: `_use_impl()`, `_stop_using_impl()`, `get_detectable_evidence()`
- Network sync support

**Signals:**
- `used(player: Node)`
- `stopped_using(player: Node)`
- `state_changed(new_state: EquipmentState)`

**EquipmentSlot** (Resource):
- Stores equipment type and instance reference
- Serialization for network sync
- Static helpers for type↔name conversion

**EquipmentManager** (Node):
- 3-slot loadout management
- Scroll wheel + number keys (1-3) for slot switching
- Loadout locking (prevents changes after investigation starts)
- Equipment holder integration

**Signals:**
- `loadout_changed(slots: Array[EquipmentSlot])`
- `active_slot_changed(old_slot: int, new_slot: int)`
- `equipment_used(slot: int, equipment: Equipment)`
- `equipment_locked`

### Protection System

Protection items provide counterplay against entity hunts.

**ProtectionItem** (extends Equipment):
- Placement modes: HELD (sage) vs PLACED (crucifix, salt)
- Charge management (max_charges, consume_charge)
- Demon modifiers for radius/duration
- Network sync for charges and placement

**Signals:**
- `charge_used(remaining: int)`
- `placed(location: Vector3)`
- `triggered(location: Vector3)`
- `depleted`

**Crucifix**:
- 2 charges, 3m radius (2m for Demon)
- Must be placed BEFORE hunt begins
- Listens to `hunt_starting`, emits `hunt_prevented`

**Sage Bundle**:
- 1 charge, HELD mode
- Blinds entity 5s during hunt
- Prevents hunts for 60s (30s Demon)

**Salt**:
- 3 charges, creates detection area
- Reveals entity footsteps (UV-visible)
- Wraith ignores salt (behavioral tell)

### Evidence System

Server-authoritative evidence collection and tracking for investigation gameplay.

**Evidence Categories (EvidenceCategory enum):**
- READILY_APPARENT - Visible to all nearby players (visual/physical manifestation)
- EQUIPMENT_DERIVED - Requires equipment to detect (EMF, thermometer, etc.)
- TRIGGERED_TEST - Requires player setup and entity response (ghost writing)
- BEHAVIOR_BASED - Observed through entity actions during hunts

**Evidence Types (8 total):**
| Type | Category | Trust Level | Equipment |
|------|----------|-------------|-----------|
| FREEZING_TEMPERATURE | Equipment-Derived | HIGH | Thermometer |
| EMF_SIGNATURE | Equipment-Derived | HIGH | EMF Reader |
| PRISM_READING | Equipment-Derived | LOW | Spectral Prism (cooperative) |
| AURA_PATTERN | Equipment-Derived | VARIABLE | Dowsing Rods + Imager (cooperative) |
| GHOST_WRITING | Triggered Test | SABOTAGE_RISK | Ghost Writing Book |
| VISUAL_MANIFESTATION | Readily-Apparent | HIGH | None |
| PHYSICAL_INTERACTION | Readily-Apparent | HIGH | None |
| HUNT_BEHAVIOR | Behavior-Based | UNFALSIFIABLE | None |

**Reading Quality:**
- STRONG - Definitive evidence (proper conditions met)
- WEAK - Suggestive only (suboptimal conditions)

**Trust Levels:**
- UNFALSIFIABLE - Cannot be faked (all players witness it)
- HIGH - Difficult to fake (shared displays, omission only)
- VARIABLE - Depends on collection method (one party can lie)
- LOW - Easy to dispute (both parties can lie)
- SABOTAGE_RISK - Can be corrupted before collection

**Verification States:**
- UNVERIFIED - No second opinion yet
- VERIFIED - Corroborated by another player
- CONTESTED - Conflicting reports exist

**EvidenceManager Signals:**
- `evidence_collected(evidence: Evidence)` - New evidence added
- `evidence_verification_changed(evidence: Evidence)` - Verification state changed
- `evidence_contested(evidence: Evidence, contesting_player_id: int)` - Dispute raised
- `evidence_cleared` - All evidence removed (new round)

**Key Methods:**
- `collect_evidence(type, collector_id, location, quality, equipment)` - Collect evidence
- `collect_cooperative_evidence(type, primary, secondary, location, quality, equipment)` - Cooperative
- `verify_evidence(uid, verifier_id)` - Mark as verified
- `contest_evidence(uid, contester_id)` - Dispute evidence
- `get_evidence_by_type(type)` / `get_evidence_by_collector(id)` - Queries
- `get_verified_evidence()` / `get_contested_evidence()` / `get_definitive_evidence()` - Filtered queries

### Audio System

Centralized audio management for horror-appropriate spatial sound.

**Audio Buses:**
- Master - Overall volume control
- SFX - Sound effects (footsteps, equipment, interactions)
- Music - Background music
- Voice - Voice chat and entity vocalizations
- Ambient - Environmental sounds

**AudioManager Features:**
- Volume control (dB and linear) per bus
- Sound pooling for frequently played sounds
- One-shot 2D and 3D spatial sounds with auto-cleanup
- Spatial audio presets: close-range (15m), medium-range (25m), long-range (50m)

**Signals:**
- `volume_changed(bus_name: String, volume_db: float)`
- `sound_played(sound_id: String, position: Vector3)`

**Key Methods:**
- `play_sound(stream, bus, volume_db)` - 2D non-spatial
- `play_sound_3d(stream, position, bus, volume_db)` - 3D spatial at position
- `play_sound_attached(stream, node, bus, volume_db)` - 3D attached to node
- `configure_sound_pool(id, stream, size, bus)` - Create reusable pool
- `play_pooled_sound(id, volume_db)` - Play from pool

**FootstepManager:**
- Attached to player, detects surface via raycast
- Surfaces set `surface_type` metadata on StaticBody3D
- 9 surface types: DEFAULT, WOOD, CONCRETE, CARPET, TILE, METAL, GRASS, GRAVEL, WATER
- Volume modifiers per surface (carpet quieter, metal louder)
- Crouch reduces volume, sprint increases it

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
- `evidence_collected(evidence_uid: String, evidence_data: Dictionary)`
- `evidence_verification_changed(evidence_uid: String, new_state: int)`
- `evidence_contested(evidence_uid: String, contester_id: int)`

**Entity:**
- `hunt_starting(entity_position: Vector3, entity: Node)` - Pre-hunt, allows prevention
- `hunt_started`
- `hunt_ended`
- `entity_tell_triggered(tell_type: String)`

**Protection:**
- `hunt_prevented(location: Vector3, charges_remaining: int)`
- `entity_blinded(duration: float)`
- `hunt_prevention_started(duration: float)`
- `hunt_prevention_ended`
- `salt_triggered(location: Vector3)`
- `protection_item_placed(item_type: String, location: Vector3)`
- `protection_item_depleted(item_type: String, location: Vector3)`

**Cultist:**
- `cultist_ability_used(ability_type: String)`
- `evidence_contaminated(evidence_type: String)`

**Interaction:**
- `player_interacted(player_id: int, interactable_path: String)`
- `interactable_state_changed(interactable_path: String, state: Dictionary)`

**Equipment:**
- `equipment_loadout_changed(player_id: int, loadout: Array)`
- `equipment_slot_changed(player_id: int, slot_index: int)`
- `equipment_used(player_id: int, equipment_path: String, is_using: bool)`

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
| toggle_evidence_board | Tab |
