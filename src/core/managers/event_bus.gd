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

# --- Entity Signals ---

## Emitted before a hunt starts, allowing prevention (e.g., by crucifix).
## entity_position is where the entity is trying to start the hunt.
## entity is the Node reference to the entity.
signal hunt_starting(entity_position: Vector3, entity: Node)

## Emitted when an entity enters hunt mode (after prevention checks).
signal hunt_started

## Emitted when a hunt ends.
signal hunt_ended

## Emitted when an entity exhibits a behavioral tell.
signal entity_tell_triggered(tell_type: String)

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

# --- Match Flow Signals ---

## Emitted when deliberation phase begins.
signal deliberation_started

## Emitted when a vote is cast during deliberation.
signal vote_cast(voter_id: int, target_id: int)

## Emitted when the match ends with a result.
signal match_ended(result: String)

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
