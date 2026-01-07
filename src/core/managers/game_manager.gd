extends Node
## Central game state machine and match lifecycle manager.
## Autoload: GameManager
##
## Manages the high-level game state transitions:
## - NONE: Initial state, no game active
## - LOBBY: Players gathering, waiting to start
## - SETUP: Match initializing, roles being assigned
## - INVESTIGATION: Main gameplay - players investigating
## - HUNT: Entity is actively hunting players
## - DELIBERATION: Players discussing and voting
## - RESULTS: Match ended, showing results
##
## Note: No class_name to avoid conflicts with autoload singleton name.

enum GameState {
	NONE,
	LOBBY,
	SETUP,
	INVESTIGATION,
	HUNT,
	DELIBERATION,
	RESULTS,
}

var current_state: GameState = GameState.NONE
var _previous_state: GameState = GameState.NONE


func _ready() -> void:
	print("[GameManager] Initialized - State: %s" % _state_to_string(current_state))


## Transitions to a new game state. Returns true if transition was valid.
func change_state(new_state: GameState) -> bool:
	if new_state == current_state:
		push_warning("[GameManager] Already in state: %s" % _state_to_string(new_state))
		return false

	if not _is_valid_transition(current_state, new_state):
		push_error(
			(
				"[GameManager] Invalid transition: %s -> %s"
				% [_state_to_string(current_state), _state_to_string(new_state)]
			)
		)
		return false

	_previous_state = current_state
	current_state = new_state

	print(
		(
			"[GameManager] State changed: %s -> %s"
			% [_state_to_string(_previous_state), _state_to_string(current_state)]
		)
	)

	EventBus.game_state_changed.emit(_previous_state, current_state)
	return true


## Forces a state change without validation. Use sparingly (e.g., error recovery).
func force_state(new_state: GameState) -> void:
	_previous_state = current_state
	current_state = new_state
	print("[GameManager] State forced: %s" % _state_to_string(current_state))
	EventBus.game_state_changed.emit(_previous_state, current_state)


## Returns the previous game state.
func get_previous_state() -> GameState:
	return _previous_state


## Returns true if the game is in an active match (not NONE, LOBBY, or RESULTS).
func is_in_match() -> bool:
	return (
		current_state
		in [
			GameState.SETUP,
			GameState.INVESTIGATION,
			GameState.HUNT,
			GameState.DELIBERATION,
		]
	)


## Returns true if the game is in a state where players can move freely.
func can_players_move() -> bool:
	return current_state in [GameState.INVESTIGATION, GameState.HUNT]


## Resets the game state to NONE. Called when returning to main menu.
func reset() -> void:
	_previous_state = current_state
	current_state = GameState.NONE
	print("[GameManager] State reset to NONE")
	EventBus.game_state_changed.emit(_previous_state, current_state)


## Validates if a state transition is allowed.
func _is_valid_transition(from: GameState, to: GameState) -> bool:
	# Define valid transitions
	var valid_transitions: Dictionary = {
		GameState.NONE: [GameState.LOBBY],
		GameState.LOBBY: [GameState.SETUP, GameState.NONE],
		GameState.SETUP: [GameState.INVESTIGATION, GameState.NONE],
		GameState.INVESTIGATION: [GameState.HUNT, GameState.DELIBERATION, GameState.NONE],
		GameState.HUNT: [GameState.INVESTIGATION, GameState.DELIBERATION, GameState.RESULTS],
		GameState.DELIBERATION: [GameState.INVESTIGATION, GameState.RESULTS, GameState.NONE],
		GameState.RESULTS: [GameState.LOBBY, GameState.NONE],
	}

	if from not in valid_transitions:
		return false

	return to in valid_transitions[from]


## Converts a GameState enum to a readable string.
func _state_to_string(state: GameState) -> String:
	var state_names: Dictionary = {
		GameState.NONE: "NONE",
		GameState.LOBBY: "LOBBY",
		GameState.SETUP: "SETUP",
		GameState.INVESTIGATION: "INVESTIGATION",
		GameState.HUNT: "HUNT",
		GameState.DELIBERATION: "DELIBERATION",
		GameState.RESULTS: "RESULTS",
	}
	return state_names.get(state, "UNKNOWN")
