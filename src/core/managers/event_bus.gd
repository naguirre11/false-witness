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

## Emitted when an entity enters hunt mode.
signal hunt_started

## Emitted when a hunt ends.
signal hunt_ended

## Emitted when an entity exhibits a behavioral tell.
signal entity_tell_triggered(tell_type: String)

# --- Cultist Signals ---

## Emitted when a Cultist uses an ability.
signal cultist_ability_used(ability_type: String)

## Emitted when contamination affects evidence.
signal evidence_contaminated(evidence_type: String)

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
