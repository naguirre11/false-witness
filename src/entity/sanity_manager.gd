extends Node
## Manages team sanity tracking and hunt threshold calculations.
## Autoload: SanityManager
##
## Handles:
## - Individual player sanity tracking
## - Team average sanity calculation
## - Sanity drain over time and from events
## - Hunt threshold checks (entity can hunt when sanity <= threshold)
##
## Note: No class_name to avoid conflicts with autoload singleton name.

# --- Signals ---

## Emitted when any player's sanity changes.
signal player_sanity_changed(player_id: int, new_sanity: float)

## Emitted when team average sanity changes significantly.
signal team_sanity_changed(new_average: float)

## Emitted when team sanity crosses below a threshold.
signal sanity_threshold_crossed(threshold: float, team_sanity: float)

# --- Constants ---

## Default starting sanity for all players
const DEFAULT_SANITY: float = 100.0

## Minimum sanity value
const MIN_SANITY: float = 0.0

## Maximum sanity value
const MAX_SANITY: float = 100.0

## Default hunt threshold (entity can hunt when team sanity <= this)
const DEFAULT_HUNT_THRESHOLD: float = 50.0

## Sanity drain per second while in darkness
const DARKNESS_DRAIN_RATE: float = 0.1

## Sanity drain per second during active entity events
const EVENT_DRAIN_RATE: float = 0.5

## Sanity drain from witnessing a hunt
const HUNT_WITNESS_DRAIN: float = 10.0

## Sanity drain from seeing the entity
const ENTITY_SIGHTING_DRAIN: float = 5.0

## Sanity drain from a nearby player dying
const DEATH_WITNESS_DRAIN: float = 15.0

## Sanity drain from ghost event (door slam, light flicker, etc.)
const GHOST_EVENT_DRAIN: float = 2.0

# --- State ---

## Player sanity values by player ID
var _player_sanity: Dictionary = {}

## Cached team average for performance
var _team_average_sanity: float = 100.0

## Whether sanity drain is currently active
var _drain_active: bool = false

## Current darkness drain multiplier per player
var _darkness_multipliers: Dictionary = {}

## Thresholds that have been crossed (to avoid duplicate signals)
var _crossed_thresholds: Array[float] = []

## Server authority flag
var _is_server: bool = false


func _ready() -> void:
	# Connect to relevant events
	if EventBus:
		EventBus.game_state_changed.connect(_on_game_state_changed)
		EventBus.player_died.connect(_on_player_died)
		EventBus.hunt_started.connect(_on_hunt_started)

	print("[SanityManager] Initialized")


func _process(delta: float) -> void:
	if not _drain_active:
		return

	if not _is_server:
		return

	_process_passive_drain(delta)


# --- Public API ---


## Registers a player with starting sanity.
func register_player(player_id: int, starting_sanity: float = DEFAULT_SANITY) -> void:
	_player_sanity[player_id] = clampf(starting_sanity, MIN_SANITY, MAX_SANITY)
	_darkness_multipliers[player_id] = 0.0
	_update_team_average()
	print("[SanityManager] Registered player %d with sanity %.1f" % [player_id, starting_sanity])


## Unregisters a player (on disconnect/death).
func unregister_player(player_id: int) -> void:
	_player_sanity.erase(player_id)
	_darkness_multipliers.erase(player_id)
	_update_team_average()
	print("[SanityManager] Unregistered player %d" % player_id)


## Gets a player's current sanity.
func get_player_sanity(player_id: int) -> float:
	return _player_sanity.get(player_id, DEFAULT_SANITY)


## Gets the team average sanity.
func get_team_sanity() -> float:
	return _team_average_sanity


## Gets all player sanity values.
func get_all_sanity() -> Dictionary:
	return _player_sanity.duplicate()


## Sets a player's sanity directly.
func set_player_sanity(player_id: int, sanity: float) -> void:
	if not _player_sanity.has(player_id):
		register_player(player_id, sanity)
		return

	var clamped := clampf(sanity, MIN_SANITY, MAX_SANITY)
	if absf(_player_sanity[player_id] - clamped) < 0.01:
		return

	_player_sanity[player_id] = clamped
	player_sanity_changed.emit(player_id, clamped)
	if EventBus:
		EventBus.player_sanity_changed.emit(player_id, clamped)
	_update_team_average()


## Drains sanity from a player.
func drain_sanity(player_id: int, amount: float) -> void:
	if not _player_sanity.has(player_id):
		return

	var current: float = _player_sanity[player_id]
	set_player_sanity(player_id, current - amount)


## Restores sanity to a player.
func restore_sanity(player_id: int, amount: float) -> void:
	if not _player_sanity.has(player_id):
		return

	var current: float = _player_sanity[player_id]
	set_player_sanity(player_id, current + amount)


## Drains sanity from all players.
func drain_all_sanity(amount: float) -> void:
	for player_id: int in _player_sanity.keys():
		drain_sanity(player_id, amount)


## Sets the darkness drain multiplier for a player (0.0 = bright, 1.0 = complete darkness).
func set_darkness_level(player_id: int, darkness: float) -> void:
	_darkness_multipliers[player_id] = clampf(darkness, 0.0, 1.0)


## Checks if the team sanity allows hunting (sanity <= threshold).
## threshold: The entity's hunt threshold (default 50)
func can_entity_hunt(threshold: float = DEFAULT_HUNT_THRESHOLD) -> bool:
	return _team_average_sanity <= threshold


## Gets the hunt threshold progress (0.0 = safe, 1.0 = can hunt).
## Returns how close the team is to allowing hunts.
func get_hunt_threshold_progress(threshold: float = DEFAULT_HUNT_THRESHOLD) -> float:
	# At 100 sanity, progress is 0. At threshold, progress is 1.
	var range_size := MAX_SANITY - threshold
	if range_size <= 0:
		return 1.0

	var progress := (MAX_SANITY - _team_average_sanity) / range_size
	return clampf(progress, 0.0, 1.0)


## Triggers sanity drain for a ghost event.
func on_ghost_event(affected_player_ids: Array) -> void:
	for player_id: int in affected_player_ids:
		drain_sanity(player_id, GHOST_EVENT_DRAIN)


## Triggers sanity drain for entity sighting.
func on_entity_sighted(player_id: int) -> void:
	drain_sanity(player_id, ENTITY_SIGHTING_DRAIN)


## Sets whether this instance is the server/host.
func set_is_server(is_server: bool) -> void:
	_is_server = is_server


## Returns whether this instance is the server/host.
func is_server() -> bool:
	return _is_server


## Resets the manager for a new match.
func reset() -> void:
	_player_sanity.clear()
	_darkness_multipliers.clear()
	_team_average_sanity = DEFAULT_SANITY
	_drain_active = false
	_crossed_thresholds.clear()
	print("[SanityManager] Reset for new match")


## Gets network state for synchronization.
func get_network_state() -> Dictionary:
	return {
		"sanity": _player_sanity.duplicate(),
		"team_average": _team_average_sanity,
	}


## Applies network state from server.
func apply_network_state(state: Dictionary) -> void:
	if state.has("sanity"):
		_player_sanity = state.sanity.duplicate()
	if state.has("team_average"):
		_team_average_sanity = state.team_average


# --- Internal Methods ---


func _update_team_average() -> void:
	if _player_sanity.is_empty():
		_team_average_sanity = DEFAULT_SANITY
		return

	var total: float = 0.0
	for sanity: float in _player_sanity.values():
		total += sanity

	var old_average := _team_average_sanity
	_team_average_sanity = total / _player_sanity.size()

	# Check for significant change (more than 1%)
	if absf(old_average - _team_average_sanity) >= 1.0:
		team_sanity_changed.emit(_team_average_sanity)
		if EventBus:
			EventBus.team_sanity_changed.emit(_team_average_sanity)
		_check_threshold_crossings()


func _check_threshold_crossings() -> void:
	# Check common thresholds
	var thresholds: Array[float] = [75.0, 50.0, 25.0, 10.0]

	for threshold in thresholds:
		if _team_average_sanity <= threshold and threshold not in _crossed_thresholds:
			_crossed_thresholds.append(threshold)
			sanity_threshold_crossed.emit(threshold, _team_average_sanity)
			if EventBus:
				EventBus.sanity_threshold_crossed.emit(threshold, _team_average_sanity)
			print("[SanityManager] Team sanity crossed threshold: %.0f%% (now %.1f%%)" % [
				threshold, _team_average_sanity])


func _process_passive_drain(delta: float) -> void:
	# Drain based on darkness level
	for player_id: int in _player_sanity.keys():
		var darkness: float = _darkness_multipliers.get(player_id, 0.0)
		if darkness > 0:
			var drain := DARKNESS_DRAIN_RATE * darkness * delta
			drain_sanity(player_id, drain)


func _on_game_state_changed(old_state: int, new_state: int) -> void:
	const INVESTIGATION := 3
	const HUNT := 4

	if new_state == INVESTIGATION and old_state != HUNT:
		# Starting new investigation - activate drain
		_drain_active = true
		_crossed_thresholds.clear()

		# Determine server status
		if NetworkManager:
			_is_server = NetworkManager.is_game_host()
		else:
			_is_server = true

		print("[SanityManager] Investigation started, drain active")

	elif new_state < INVESTIGATION:
		# Left match state - deactivate
		_drain_active = false


func _on_player_died(player_id: int) -> void:
	# Drain sanity from nearby/witnessing players
	# In production, would check proximity
	for other_id: int in _player_sanity.keys():
		if other_id != player_id:
			drain_sanity(other_id, DEATH_WITNESS_DRAIN)


func _on_hunt_started() -> void:
	# All players lose sanity when hunt starts
	drain_all_sanity(HUNT_WITNESS_DRAIN)
