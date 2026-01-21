class_name CultistPlacementController
extends Node
## Manages the 5-second placement animation for Cultist abilities.
##
## Handles:
## - Restricting player movement during placement
## - Cancelling placement if player moves or takes damage
## - Syncing placement animation state across network
## - Providing progress indicator for UI
##
## Attach this to a player node. Requires access to PlayerController.

# --- Signals ---

## Emitted when placement begins.
signal placement_started(ability_type: int)

## Emitted when placement progress updates.
signal placement_progress_changed(progress: float)

## Emitted when placement completes successfully.
signal placement_completed(ability_type: int, position: Vector3)

## Emitted when placement is cancelled.
signal placement_cancelled(reason: String)

# --- Constants ---

## How far the player can move before placement is cancelled (in meters).
const MOVEMENT_THRESHOLD := 0.1

## Progress update interval for UI (in seconds).
const PROGRESS_UPDATE_INTERVAL := 0.1

# --- State ---

## Whether placement is currently in progress.
var is_placing: bool = false

## The ability being placed.
var current_ability: CultistAbility = null

## The ability type being placed.
var current_ability_type: int = -1

## Position where placement started.
var placement_start_position: Vector3 = Vector3.ZERO

## Time remaining for current placement.
var placement_time_remaining: float = 0.0

## Total placement time for current ability.
var total_placement_time: float = 0.0

## Timer for progress updates.
var progress_update_timer: float = 0.0

## Reference to the player controller (for movement restriction).
var _player_controller: PlayerController = null

## Player ID for network sync.
var _player_id: int = -1

## Whether we're the server.
var _is_server: bool = false


func _ready() -> void:
	# Find player controller in parent hierarchy
	_find_player_controller()

	# Connect to EventBus for damage events
	if EventBus:
		EventBus.player_damaged.connect(_on_player_damaged)


func _process(delta: float) -> void:
	if not is_placing or current_ability == null:
		return

	# Check for movement cancellation
	if _has_player_moved():
		cancel_placement("Player moved")
		return

	# Update ability activation timer
	var completed := current_ability.update_activation(delta)

	# Update our timer
	placement_time_remaining -= delta

	# Update progress
	progress_update_timer += delta
	if progress_update_timer >= PROGRESS_UPDATE_INTERVAL:
		progress_update_timer = 0.0
		var progress := current_ability.get_activation_progress()
		placement_progress_changed.emit(progress)
		_emit_progress_to_eventbus(progress)

	# Check for completion
	if completed or placement_time_remaining <= 0.0:
		_complete_placement()


# --- Public API ---


## Starts a placement animation for the given ability.
## Returns true if placement started successfully.
func start_placement(
	ability: CultistAbility,
	ability_type: int,
	player_id: int,
	position: Vector3
) -> bool:
	if is_placing:
		push_warning("[PlacementController] Already placing an ability")
		return false

	if not ability.can_use():
		push_warning("[PlacementController] Ability cannot be used")
		return false

	# Start ability activation
	if not ability.start_activation():
		return false

	# Store state
	current_ability = ability
	current_ability_type = ability_type
	placement_start_position = position
	placement_time_remaining = ability.placement_time
	total_placement_time = ability.placement_time
	progress_update_timer = 0.0
	is_placing = true
	_player_id = player_id

	# Restrict player movement
	_restrict_player_movement()

	# Emit signals
	placement_started.emit(ability_type)
	_emit_placement_started_to_eventbus()

	print("[PlacementController] Started placement: ability=%d, time=%.1fs" % [
		ability_type, ability.placement_time
	])

	return true


## Cancels the current placement.
func cancel_placement(reason: String) -> void:
	if not is_placing:
		return

	# Cancel ability activation
	if current_ability:
		current_ability.cancel_activation()

	# Restore player movement
	_restore_player_movement()

	# Store values before reset
	var ability_type := current_ability_type

	# Reset state
	_reset_state()

	# Emit signals
	placement_cancelled.emit(reason)
	_emit_placement_cancelled_to_eventbus(reason)

	print("[PlacementController] Placement cancelled: reason=%s, ability=%d" % [reason, ability_type])


## Gets the current placement progress (0.0 to 1.0).
func get_placement_progress() -> float:
	if not is_placing or current_ability == null:
		return 0.0
	return current_ability.get_activation_progress()


## Gets the time remaining for placement.
func get_time_remaining() -> float:
	return placement_time_remaining if is_placing else 0.0


## Sets the player controller reference.
func set_player_controller(controller: PlayerController) -> void:
	_player_controller = controller


## Sets whether this is the server instance.
func set_is_server(is_server: bool) -> void:
	_is_server = is_server


# --- Internal Methods ---


func _find_player_controller() -> void:
	# Try to find PlayerController in parent hierarchy
	var parent := get_parent()
	while parent != null:
		if parent is PlayerController:
			_player_controller = parent as PlayerController
			return
		parent = parent.get_parent()


func _has_player_moved() -> bool:
	if not _player_controller:
		return false

	var current_position := _player_controller.global_position
	var distance := current_position.distance_to(placement_start_position)
	return distance > MOVEMENT_THRESHOLD


func _restrict_player_movement() -> void:
	if _player_controller:
		_player_controller.set_input_enabled(false)
		# Stop any current movement
		_player_controller.velocity = Vector3.ZERO


func _restore_player_movement() -> void:
	if _player_controller:
		_player_controller.set_input_enabled(true)


func _complete_placement() -> void:
	if not is_placing or current_ability == null:
		return

	# Use the ability charge
	var success := current_ability.use(placement_start_position)
	if not success:
		cancel_placement("Ability use failed")
		return

	# Restore player movement
	_restore_player_movement()

	# Store values before reset
	var ability_type := current_ability_type
	var position := placement_start_position

	# Reset state
	_reset_state()

	# Emit signals
	placement_completed.emit(ability_type, position)
	_emit_placement_completed_to_eventbus(ability_type, position)

	print("[PlacementController] Placement completed: ability=%d, position=%v" % [
		ability_type, position
	])


func _reset_state() -> void:
	is_placing = false
	current_ability = null
	current_ability_type = -1
	placement_start_position = Vector3.ZERO
	placement_time_remaining = 0.0
	total_placement_time = 0.0
	progress_update_timer = 0.0


func _on_player_damaged(player_id: int, _damage: float, _source: String) -> void:
	# Cancel placement if this player takes damage
	if is_placing and player_id == _player_id:
		cancel_placement("Player took damage")


# --- EventBus Integration ---


func _emit_placement_started_to_eventbus() -> void:
	if EventBus:
		EventBus.cultist_placement_started.emit(
			_player_id,
			current_ability_type,
			placement_start_position
		)


func _emit_progress_to_eventbus(progress: float) -> void:
	if EventBus:
		EventBus.cultist_placement_progress.emit(_player_id, progress)


func _emit_placement_completed_to_eventbus(ability_type: int, position: Vector3) -> void:
	if EventBus:
		EventBus.cultist_placement_completed.emit(_player_id, ability_type, position)


func _emit_placement_cancelled_to_eventbus(reason: String) -> void:
	if EventBus:
		EventBus.cultist_placement_cancelled.emit(_player_id, reason)


# --- Network Sync (RPC Methods) ---


## Server notifies clients that a player is placing an ability.
@rpc("authority", "call_remote", "reliable")
func _sync_placement_started(
	player_id: int, ability_type: int, position_dict: Dictionary
) -> void:
	var position := Vector3(
		position_dict.get("x", 0.0),
		position_dict.get("y", 0.0),
		position_dict.get("z", 0.0)
	)
	# This is for visual animation on remote clients
	# They see the Cultist performing the placement animation
	if EventBus:
		EventBus.cultist_placement_started.emit(player_id, ability_type, position)


## Server notifies clients of placement progress.
@rpc("authority", "call_remote", "unreliable")
func _sync_placement_progress(player_id: int, progress: float) -> void:
	if EventBus:
		EventBus.cultist_placement_progress.emit(player_id, progress)


## Server notifies clients that placement completed.
@rpc("authority", "call_remote", "reliable")
func _sync_placement_completed(
	player_id: int, ability_type: int, position_dict: Dictionary
) -> void:
	var position := Vector3(
		position_dict.get("x", 0.0),
		position_dict.get("y", 0.0),
		position_dict.get("z", 0.0)
	)
	if EventBus:
		EventBus.cultist_placement_completed.emit(player_id, ability_type, position)


## Server notifies clients that placement was cancelled.
@rpc("authority", "call_remote", "reliable")
func _sync_placement_cancelled(player_id: int, reason: String) -> void:
	if EventBus:
		EventBus.cultist_placement_cancelled.emit(player_id, reason)


## Broadcasts placement start to all clients (server-side).
func broadcast_placement_started() -> void:
	if not _is_server:
		return
	var pos_dict := {
		"x": placement_start_position.x,
		"y": placement_start_position.y,
		"z": placement_start_position.z,
	}
	_sync_placement_started.rpc(_player_id, current_ability_type, pos_dict)


## Broadcasts placement progress to all clients (server-side).
func broadcast_placement_progress() -> void:
	if not _is_server or not is_placing:
		return
	var progress := get_placement_progress()
	_sync_placement_progress.rpc(_player_id, progress)


## Broadcasts placement completion to all clients (server-side).
func broadcast_placement_completed(ability_type: int, position: Vector3) -> void:
	if not _is_server:
		return
	var pos_dict := {"x": position.x, "y": position.y, "z": position.z}
	_sync_placement_completed.rpc(_player_id, ability_type, pos_dict)


## Broadcasts placement cancellation to all clients (server-side).
func broadcast_placement_cancelled(reason: String) -> void:
	if not _is_server:
		return
	_sync_placement_cancelled.rpc(_player_id, reason)
