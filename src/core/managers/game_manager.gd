extends Node
## Central game state machine and match lifecycle manager.
## Autoload: GameManager
##
## Manages the high-level game state transitions:
## - NONE: Initial state, no game active (equivalent to MENU)
## - LOBBY: Players gathering, waiting to start
## - SETUP: Equipment selection and role assignment (EQUIPMENT_SELECT phase)
## - INVESTIGATION: Main gameplay - players investigating (timed: 12-15min default)
## - HUNT: Entity is actively hunting players (interrupts investigation)
## - DELIBERATION: Players discussing and voting (timed: 3-5min default)
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

# --- Timer Configuration Constants ---
# Default durations in seconds (can be configured per-match)

const DEFAULT_INVESTIGATION_TIME: float = 720.0  # 12 minutes
const DEFAULT_DELIBERATION_TIME: float = 180.0  # 3 minutes
const MIN_INVESTIGATION_TIME: float = 720.0  # 12 minutes
const MAX_INVESTIGATION_TIME: float = 900.0  # 15 minutes
const MIN_DELIBERATION_TIME: float = 180.0  # 3 minutes
const MAX_DELIBERATION_TIME: float = 300.0  # 5 minutes

# --- Public State Variables ---

var current_state: GameState = GameState.NONE
var investigation_duration: float = DEFAULT_INVESTIGATION_TIME
var deliberation_duration: float = DEFAULT_DELIBERATION_TIME

# --- Private State Variables ---

var _previous_state: GameState = GameState.NONE
var _time_remaining: float = 0.0
var _timer_active: bool = false
var _timer_paused: bool = false
var _tick_accumulator: float = 0.0
var _timed_states: Array[GameState] = [GameState.INVESTIGATION, GameState.DELIBERATION]


func _ready() -> void:
	print("[GameManager] Initialized - State: %s" % _state_to_string(current_state))


func _process(delta: float) -> void:
	if _timer_active and not _timer_paused:
		_update_timer(delta)


# --- State Management ---


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

	# Stop timer for old state if active
	if _timer_active:
		_stop_timer()

	_previous_state = current_state
	current_state = new_state

	print(
		(
			"[GameManager] State changed: %s -> %s"
			% [_state_to_string(_previous_state), _state_to_string(current_state)]
		)
	)

	# Start timer for new state if it's timed
	if current_state in _timed_states:
		_start_timer_for_state(current_state)

	EventBus.game_state_changed.emit(_previous_state, current_state)
	return true


## Forces a state change without validation. Use sparingly (e.g., error recovery).
func force_state(new_state: GameState) -> void:
	if _timer_active:
		_stop_timer()

	_previous_state = current_state
	current_state = new_state
	print("[GameManager] State forced: %s" % _state_to_string(current_state))

	if current_state in _timed_states:
		_start_timer_for_state(current_state)

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
	if _timer_active:
		_stop_timer()

	_previous_state = current_state
	current_state = GameState.NONE
	print("[GameManager] State reset to NONE")
	EventBus.game_state_changed.emit(_previous_state, current_state)


# --- Timer Management ---


## Returns the time remaining in the current timed phase (in seconds).
func get_time_remaining() -> float:
	return _time_remaining


## Returns true if the timer is currently active.
func is_timer_active() -> bool:
	return _timer_active


## Returns true if the timer is paused.
func is_timer_paused() -> bool:
	return _timer_paused


## Pauses the current phase timer. Only the host should call this.
func pause_timer() -> void:
	if _timer_active and not _timer_paused:
		_timer_paused = true
		print("[GameManager] Timer paused - %.1f seconds remaining" % _time_remaining)


## Resumes a paused timer. Only the host should call this.
func resume_timer() -> void:
	if _timer_active and _timer_paused:
		_timer_paused = false
		print("[GameManager] Timer resumed - %.1f seconds remaining" % _time_remaining)


## Extends the current phase timer by the given amount. Only the host should call this.
func extend_timer(additional_seconds: float) -> void:
	if not _timer_active:
		push_warning("[GameManager] Cannot extend timer - no active timer")
		return

	_time_remaining += additional_seconds
	print(
		(
			"[GameManager] Timer extended by %.1f seconds - now %.1f remaining"
			% [additional_seconds, _time_remaining]
		)
	)
	EventBus.phase_timer_extended.emit(additional_seconds)


## Sets the timer to a specific value. Only the host should call this.
func set_timer(seconds: float) -> void:
	if not _timer_active:
		push_warning("[GameManager] Cannot set timer - no active timer")
		return

	_time_remaining = maxf(0.0, seconds)
	print("[GameManager] Timer set to %.1f seconds" % _time_remaining)


## Configures phase durations before starting a match.
func configure_phase_durations(investigation: float, deliberation: float) -> void:
	investigation_duration = clampf(investigation, MIN_INVESTIGATION_TIME, MAX_INVESTIGATION_TIME)
	deliberation_duration = clampf(deliberation, MIN_DELIBERATION_TIME, MAX_DELIBERATION_TIME)
	print(
		(
			"[GameManager] Phase durations configured - Investigation: %.0fs, Deliberation: %.0fs"
			% [investigation_duration, deliberation_duration]
		)
	)


# --- Internal Timer Methods ---


func _start_timer_for_state(state: GameState) -> void:
	match state:
		GameState.INVESTIGATION:
			_time_remaining = investigation_duration
		GameState.DELIBERATION:
			_time_remaining = deliberation_duration
		_:
			return

	_timer_active = true
	_timer_paused = false
	_tick_accumulator = 0.0
	print(
		(
			"[GameManager] Timer started for %s - %.1f seconds"
			% [_state_to_string(state), _time_remaining]
		)
	)


func _stop_timer() -> void:
	_timer_active = false
	_timer_paused = false
	_time_remaining = 0.0
	_tick_accumulator = 0.0


func _update_timer(delta: float) -> void:
	_time_remaining -= delta
	_tick_accumulator += delta

	# Emit tick signal every second
	if _tick_accumulator >= 1.0:
		_tick_accumulator -= 1.0
		EventBus.phase_timer_tick.emit(_time_remaining)

	# Check for expiration
	if _time_remaining <= 0.0:
		_time_remaining = 0.0
		_on_timer_expired()


func _on_timer_expired() -> void:
	var expired_state: GameState = current_state
	_stop_timer()
	print("[GameManager] Timer expired for %s" % _state_to_string(expired_state))
	EventBus.phase_timer_expired.emit(expired_state)


# --- Validation ---


## Validates if a state transition is allowed.
func _is_valid_transition(from: GameState, to: GameState) -> bool:
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
