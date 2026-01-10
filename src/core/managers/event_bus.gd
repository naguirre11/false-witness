extends Node
## Global signal hub for decoupled cross-system communication.
## Autoload: EventBus
##
## Provides centralized signals that any system can emit/listen to without
## direct dependencies. This enables loose coupling between game systems.
##
## Note: No class_name to avoid conflicts with autoload singleton name.

# --- Game State Signals ---

## Emitted when the game state changes.
## old_state and new_state use GameManager.GameState enum values.
signal game_state_changed(old_state: int, new_state: int)

# --- Player Signals ---

## Emitted when a player joins the game/lobby.
## player_id is the unique identifier (Steam ID for networked games).
signal player_joined(player_id: int)

## Emitted when a player leaves the game/lobby.
signal player_left(player_id: int)

## Emitted when a player dies during a hunt.
signal player_died(player_id: int)

## Emitted when a player becomes an Echo (dead player observer).
signal player_became_echo(player_id: int)

# --- Evidence Signals ---

## Emitted when evidence is detected by equipment.
signal evidence_detected(evidence_type: String, location: Vector3, strength: float)

## Emitted when evidence is recorded to the board.
signal evidence_recorded(evidence_type: String, equipment_type: String)

## Emitted when evidence is formally collected and added to the board.
## evidence_uid is the unique identifier, evidence_data is the serialized Evidence.
signal evidence_collected(evidence_uid: String, evidence_data: Dictionary)

## Emitted when evidence verification state changes.
signal evidence_verification_changed(evidence_uid: String, new_state: int)

## Emitted when a player disputes collected evidence.
signal evidence_contested(evidence_uid: String, contester_id: int)

# --- Entity Signals ---

## Emitted before a hunt starts, allowing prevention (e.g., by crucifix).
## entity_position is where the entity is trying to start the hunt.
## entity is the Node reference to the entity.
signal hunt_starting(entity_position: Vector3, entity: Node)

## Emitted when the warning phase begins (lights flicker, equipment static, etc.).
## entity_position is where the entity is starting the warning from.
## duration is the warning phase duration in seconds.
signal hunt_warning_started(entity_position: Vector3, duration: float)

## Emitted when the warning phase ends (hunt is about to begin or was prevented).
## hunt_proceeding is true if the hunt will start, false if prevented.
signal hunt_warning_ended(hunt_proceeding: bool)

## Emitted when an entity enters hunt mode (after prevention checks).
signal hunt_started

## Emitted when a hunt ends.
signal hunt_ended

## Emitted when an entity exhibits a behavioral tell.
signal entity_tell_triggered(tell_type: String)

## Emitted when an entity spawns into the match.
signal entity_spawned(entity_type: String, room: String)

## Emitted when an entity is removed from the match.
signal entity_removed

## Emitted when entity aggression level changes.
signal entity_aggression_changed(phase: int, phase_name: String)

## Emitted when entity starts a manifestation (becomes visible).
signal entity_manifesting(position: Vector3)

## Emitted when entity stops manifesting.
signal entity_manifestation_ended

## Emitted when entity state changes.
signal entity_state_changed(old_state: int, new_state: int)

# --- Sanity Signals ---

## Emitted when a player's sanity changes.
signal player_sanity_changed(player_id: int, new_sanity: float)

## Emitted when team average sanity changes significantly.
signal team_sanity_changed(team_average: float)

## Emitted when team sanity crosses below a threshold.
signal sanity_threshold_crossed(threshold: float, team_sanity: float)

# --- Protection Item Signals ---

## Emitted when a crucifix prevents a hunt from starting.
## location is where the crucifix is placed, charges_remaining after prevention.
signal hunt_prevented(location: Vector3, charges_remaining: int)

## Emitted when sage blinds an entity during a hunt.
## duration is how long the entity is blinded.
signal entity_blinded(duration: float)

## Emitted when sage prevents new hunts.
## duration is how long hunts are prevented.
signal hunt_prevention_started(duration: float)

## Emitted when hunt prevention from sage expires.
signal hunt_prevention_ended

## Emitted when salt detects entity footsteps.
## location is where the footsteps appeared.
signal salt_triggered(location: Vector3)

## Emitted when a protection item is placed in the world.
signal protection_item_placed(item_type: String, location: Vector3)

## Emitted when a protection item is depleted (all charges used).
signal protection_item_depleted(item_type: String, location: Vector3)

# --- Cultist Signals ---

## Emitted when a Cultist uses an ability.
signal cultist_ability_used(ability_type: String)

## Emitted when contamination affects evidence.
signal evidence_contaminated(evidence_type: String)

# --- Interaction Signals ---

## Emitted when a player interacts with an object.
## player_id is the peer ID, interactable_path is the node path.
signal player_interacted(player_id: int, interactable_path: String)

## Emitted when an interactable's state changes (for network sync).
signal interactable_state_changed(interactable_path: String, state: Dictionary)

# --- Equipment Signals ---

## Emitted when a player's equipment loadout changes during SETUP.
signal equipment_loadout_changed(player_id: int, loadout: Array)

## Emitted when a player switches their active equipment slot.
signal equipment_slot_changed(player_id: int, slot_index: int)

## Emitted when equipment is used or stopped being used.
signal equipment_used(player_id: int, equipment_path: String, is_using: bool)

# --- EMF Reader Signals ---

## Emitted when EMF reader beeps (for audio system).
signal emf_beep(level: int)

## Emitted when EMF reader hits Level 5 spike (evidence detected).
signal emf_level_5_spike

## Emitted when EMF reader state changes (for network sync).
signal emf_state_changed(player_id: int, level: int, direction: Vector3, quality: int)

# --- Thermometer Signals ---

## Emitted when thermometer detects freezing temperature (for audio system).
signal thermometer_freezing(temperature: float)

## Emitted when thermometer detects extreme cold (for audio/visual effects).
signal thermometer_extreme_cold(temperature: float)

## Emitted when thermometer state changes (for network sync).
signal thermometer_state_changed(player_id: int, temperature: float, quality: int)

# --- Match Flow Signals ---

## Emitted when deliberation phase begins.
signal deliberation_started

## Emitted when a vote is cast during deliberation.
signal vote_cast(voter_id: int, target_id: int)

## Emitted when the match ends with a result.
signal match_ended(result: String)

# --- Lobby Signals ---

## Emitted when a lobby is created or joined.
signal lobby_state_changed(is_in_lobby: bool, is_host: bool)

## Emitted when the player list in lobby updates.
signal lobby_players_updated(player_count: int, slots: Array)

## Emitted when a player's ready state changes.
signal lobby_player_ready_changed(peer_id: int, is_ready: bool)

## Emitted when all players are ready and game can start.
signal lobby_can_start(can_start: bool)

## Emitted when the host changes (migration or new host).
signal lobby_host_changed(new_host_peer_id: int, new_host_username: String)

# --- Timer Signals ---

## Emitted every second during timed phases (investigation, deliberation).
## time_remaining is in seconds.
signal phase_timer_tick(time_remaining: float)

## Emitted when a timed phase expires.
signal phase_timer_expired(state: int)

## Emitted when phase time is extended (e.g., by finding evidence).
signal phase_timer_extended(additional_seconds: float)


func _ready() -> void:
	print("[EventBus] Initialized - Global signal hub ready")
