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

# --- Map Registry ---
# Maps map identifiers to their scene paths.

const MAP_REGISTRY: Dictionary = {
	"abandoned_house": "res://scenes/maps/abandoned_house.tscn",
}

const DEFAULT_MAP: String = "abandoned_house"

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

# --- Map State Variables ---

var _current_map: Node = null
var _current_map_name: String = ""
var _is_loading_map: bool = false
var _loading_screen: Control = null
var _map_load_thread_id: int = -1


func _ready() -> void:
	print("[GameManager] Initialized - State: %s" % _state_to_string(current_state))


func _process(delta: float) -> void:
	if _timer_active and not _timer_paused:
		_update_timer(delta)

	# Check async map loading progress
	if _is_loading_map:
		_check_map_load_progress()


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


# --- Map Loading ---


## Loads a map by name. Shows loading screen and loads asynchronously.
## Returns true if loading started, false if map not found or already loading.
func load_map(map_name: String = DEFAULT_MAP) -> bool:
	if _is_loading_map:
		push_warning("[GameManager] Already loading a map")
		return false

	if not MAP_REGISTRY.has(map_name):
		push_error("[GameManager] Unknown map: %s" % map_name)
		EventBus.map_load_failed.emit(map_name, "Unknown map name")
		return false

	var scene_path: String = MAP_REGISTRY[map_name]
	if not ResourceLoader.exists(scene_path):
		push_error("[GameManager] Map scene not found: %s" % scene_path)
		EventBus.map_load_failed.emit(map_name, "Scene file not found")
		return false

	print("[GameManager] Loading map: %s" % map_name)
	_current_map_name = map_name
	_is_loading_map = true

	# Emit loading started signal
	EventBus.map_loading_started.emit(map_name)

	# Show loading screen
	_show_loading_screen(map_name)

	# Start async loading
	var error := ResourceLoader.load_threaded_request(scene_path)
	if error != OK:
		push_error("[GameManager] Failed to start async load: %s" % error)
		_is_loading_map = false
		_hide_loading_screen()
		EventBus.map_load_failed.emit(map_name, "Failed to start loading")
		return false

	return true


## Returns the currently loaded map node, or null if no map loaded.
func get_current_map() -> Node:
	return _current_map


## Returns the name of the currently loaded map.
func get_current_map_name() -> String:
	return _current_map_name


## Returns true if a map is currently being loaded.
func is_loading_map() -> bool:
	return _is_loading_map


## Unloads the current map and cleans up resources.
func unload_map() -> void:
	if _current_map != null:
		print("[GameManager] Unloading map: %s" % _current_map_name)
		_current_map.queue_free()
		_current_map = null
		_current_map_name = ""
		EventBus.map_unloaded.emit()


## Returns spawn positions from the current map.
## Returns empty array if no map loaded or map doesn't have spawn points.
func get_spawn_positions() -> Array[Vector3]:
	if _current_map == null:
		return []

	if _current_map.has_method("get_spawn_positions"):
		return _current_map.get_spawn_positions()

	return []


## Returns a specific spawn position by index.
func get_spawn_position(index: int) -> Vector3:
	if _current_map == null:
		return Vector3.ZERO

	if _current_map.has_method("get_spawn_point"):
		return _current_map.get_spawn_point(index)

	return Vector3.ZERO


## Returns the number of spawn points in the current map.
func get_spawn_count() -> int:
	if _current_map == null:
		return 0

	if _current_map.has_method("get_spawn_count"):
		return _current_map.get_spawn_count()

	return 0


# --- Internal Map Loading Methods ---


func _check_map_load_progress() -> void:
	var scene_path: String = MAP_REGISTRY.get(_current_map_name, "")
	if scene_path.is_empty():
		return

	var progress_array: Array = []
	var status := ResourceLoader.load_threaded_get_status(scene_path, progress_array)

	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var progress: float = progress_array[0] if progress_array.size() > 0 else 0.0
			EventBus.map_loading_progress.emit(progress, "Loading map resources...")
			_update_loading_screen(progress, "Loading map resources...")

		ResourceLoader.THREAD_LOAD_LOADED:
			_on_map_load_complete(scene_path)

		ResourceLoader.THREAD_LOAD_FAILED:
			_on_map_load_failed("Resource loading failed")

		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_on_map_load_failed("Invalid resource")


func _on_map_load_complete(scene_path: String) -> void:
	print("[GameManager] Map load complete: %s" % _current_map_name)
	_is_loading_map = false

	# Get the loaded resource
	var map_scene := ResourceLoader.load_threaded_get(scene_path) as PackedScene
	if map_scene == null:
		_on_map_load_failed("Failed to get loaded scene")
		return

	# Update progress
	EventBus.map_loading_progress.emit(0.9, "Instantiating map...")
	_update_loading_screen(0.9, "Instantiating map...")

	# Instantiate the map
	_current_map = map_scene.instantiate()
	if _current_map == null:
		_on_map_load_failed("Failed to instantiate map scene")
		return

	# Add map to scene tree
	get_tree().root.add_child(_current_map)

	# Final progress update
	EventBus.map_loading_progress.emit(1.0, "Map ready!")
	_update_loading_screen(1.0, "Map ready!")

	# Emit map loaded signal
	EventBus.map_loaded.emit(_current_map)

	# Hide loading screen with delay
	call_deferred("_hide_loading_screen")


func _on_map_load_failed(error: String) -> void:
	push_error("[GameManager] Map load failed: %s" % error)
	_is_loading_map = false
	_hide_loading_screen()
	EventBus.map_load_failed.emit(_current_map_name, error)


func _show_loading_screen(map_name: String) -> void:
	if _loading_screen != null:
		return

	var loading_scene := load("res://scenes/ui/loading_screen.tscn") as PackedScene
	if loading_scene == null:
		push_warning("[GameManager] Loading screen scene not found")
		return

	_loading_screen = loading_scene.instantiate() as Control
	get_tree().root.add_child(_loading_screen)

	if _loading_screen.has_method("show_loading"):
		_loading_screen.show_loading(map_name)


func _update_loading_screen(progress: float, status: String) -> void:
	if _loading_screen != null and _loading_screen.has_method("set_progress"):
		_loading_screen.set_progress(progress, status)


func _hide_loading_screen() -> void:
	if _loading_screen != null:
		if _loading_screen.has_method("hide_loading"):
			_loading_screen.hide_loading()
			# Wait for fade out then cleanup
			await get_tree().create_timer(0.6).timeout
		_loading_screen.queue_free()
		_loading_screen = null
