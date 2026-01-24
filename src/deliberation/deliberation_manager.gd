extends Node
## Manages the deliberation phase - teleportation, movement restriction, and transitions.
## Autoload: DeliberationManager
##
## Handles:
## - Teleporting players to deliberation area when DELIBERATION phase starts
## - Preventing players from leaving deliberation area
## - Tracking which players are in the area
## - Coordinating with GameManager state transitions

# --- Signals ---

signal player_teleported(player: Node3D, spawn_index: int)
signal all_players_teleported
signal player_boundary_violation(player: Node3D)

# --- Constants ---

const DELIBERATION_STATE: int = 5  # GameManager.GameState.DELIBERATION
const DeliberationArea := preload("res://src/deliberation/deliberation_area.gd")

# --- State Variables ---

var _deliberation_area: Node3D = null
var _player_nodes: Dictionary = {}  # peer_id -> Node3D
var _is_active: bool = false


func _ready() -> void:
	_connect_signals()
	print("[DeliberationManager] Initialized")


## Registers the deliberation area scene instance.
## Must be called when the level loads the deliberation area.
func register_deliberation_area(area: Node3D) -> void:
	if not area.has_method("get_spawn_position"):
		push_error("[DeliberationManager] Invalid deliberation area - missing required methods")
		return

	_deliberation_area = area

	# Connect boundary signals
	if _deliberation_area.has_signal("player_exited_boundary"):
		_deliberation_area.player_exited_boundary.connect(_on_player_exited_boundary)

	print("[DeliberationManager] Deliberation area registered")


## Unregisters the current deliberation area.
func unregister_deliberation_area() -> void:
	if _deliberation_area:
		if _deliberation_area.has_signal("player_exited_boundary"):
			if _deliberation_area.player_exited_boundary.is_connected(_on_player_exited_boundary):
				_deliberation_area.player_exited_boundary.disconnect(_on_player_exited_boundary)
	_deliberation_area = null


## Registers a player node for teleportation tracking.
func register_player(peer_id: int, player_node: Node3D) -> void:
	_player_nodes[peer_id] = player_node
	print("[DeliberationManager] Player registered: %d" % peer_id)


## Unregisters a player node.
func unregister_player(peer_id: int) -> void:
	_player_nodes.erase(peer_id)


## Returns true if deliberation is currently active.
func is_deliberation_active() -> bool:
	return _is_active


## Returns the deliberation area instance.
func get_deliberation_area() -> Node3D:
	return _deliberation_area


## Teleports all registered players to the deliberation area.
## Called automatically when DELIBERATION state begins.
func teleport_all_players() -> void:
	if not _deliberation_area:
		push_error("[DeliberationManager] No deliberation area registered")
		return

	# Clear previous spawn assignments
	if _deliberation_area.has_method("clear_spawn_assignments"):
		_deliberation_area.clear_spawn_assignments()

	var spawn_index: int = 0
	var teleported_count: int = 0

	for peer_id in _player_nodes:
		var player: Node3D = _player_nodes[peer_id]
		if not is_instance_valid(player):
			continue

		# Assign spawn point
		var assigned_index: int = spawn_index
		if _deliberation_area.has_method("assign_spawn_point"):
			assigned_index = _deliberation_area.assign_spawn_point(peer_id)
			if assigned_index < 0:
				assigned_index = spawn_index  # Fallback

		# Teleport player
		_teleport_player(player, assigned_index)
		teleported_count += 1
		spawn_index += 1

	print("[DeliberationManager] Teleported %d players to deliberation area" % teleported_count)
	all_players_teleported.emit()


## Teleports a single player to their spawn point.
func teleport_player(peer_id: int) -> bool:
	if not _deliberation_area:
		push_error("[DeliberationManager] No deliberation area registered")
		return false

	if peer_id not in _player_nodes:
		push_warning("[DeliberationManager] Player not registered: %d" % peer_id)
		return false

	var player: Node3D = _player_nodes[peer_id]
	if not is_instance_valid(player):
		return false

	var spawn_index: int = -1
	if _deliberation_area.has_method("get_player_spawn_index"):
		spawn_index = _deliberation_area.get_player_spawn_index(peer_id)

	if spawn_index < 0 and _deliberation_area.has_method("assign_spawn_point"):
		spawn_index = _deliberation_area.assign_spawn_point(peer_id)

	if spawn_index >= 0:
		_teleport_player(player, spawn_index)
		return true

	return false


## Restricts player movement to deliberation area boundaries.
## Called when deliberation starts.
func enable_movement_restriction() -> void:
	# TODO: Implement actual movement restriction
	# For now, we rely on boundary detection and teleport-back
	_is_active = true
	print("[DeliberationManager] Movement restriction enabled")


## Removes movement restrictions.
## Called when deliberation ends.
func disable_movement_restriction() -> void:
	_is_active = false

	# Clear spawn assignments
	if _deliberation_area and _deliberation_area.has_method("clear_spawn_assignments"):
		_deliberation_area.clear_spawn_assignments()

	print("[DeliberationManager] Movement restriction disabled")


# --- Private Methods ---


func _connect_signals() -> void:
	# Listen for game state changes
	if has_node("/root/EventBus"):
		EventBus.game_state_changed.connect(_on_game_state_changed)

	# Listen for player death/echo events
	if has_node("/root/EventBus"):
		EventBus.player_died.connect(_on_player_died)


func _on_game_state_changed(old_state: int, new_state: int) -> void:
	if new_state == DELIBERATION_STATE:
		print("[DeliberationManager] DELIBERATION phase started - teleporting players")
		enable_movement_restriction()
		teleport_all_players()
		EventBus.deliberation_started.emit()
	elif old_state == DELIBERATION_STATE:
		print("[DeliberationManager] DELIBERATION phase ended")
		disable_movement_restriction()


func _on_player_died(player_id: int) -> void:
	# Dead players become Echoes but stay in deliberation area
	if _is_active and player_id in _player_nodes:
		var player: Node3D = _player_nodes[player_id]
		if is_instance_valid(player):
			# Player remains at their position - no special handling needed
			print("[DeliberationManager] Player %d died but remains in area as Echo" % player_id)


func _on_player_exited_boundary(player: Node3D) -> void:
	if not _is_active:
		return

	# Find the peer_id for this player
	var peer_id: int = -1
	for pid in _player_nodes:
		if _player_nodes[pid] == player:
			peer_id = pid
			break

	if peer_id < 0:
		return

	# Teleport player back to their spawn point
	push_warning("[DeliberationManager] Player %d left boundary - teleporting back" % peer_id)
	player_boundary_violation.emit(player)
	teleport_player(peer_id)


func _teleport_player(player: Node3D, spawn_index: int) -> void:
	if not _deliberation_area:
		return

	var spawn_transform: Transform3D
	if _deliberation_area.has_method("get_spawn_transform"):
		spawn_transform = _deliberation_area.get_spawn_transform(spawn_index)
	else:
		spawn_transform = Transform3D.IDENTITY
		if _deliberation_area.has_method("get_spawn_position"):
			spawn_transform.origin = _deliberation_area.get_spawn_position(spawn_index)

	# Apply transform
	player.global_transform = spawn_transform

	# If player has velocity, clear it
	if player.has_method("set") and "velocity" in player:
		player.velocity = Vector3.ZERO

	print(
		"[DeliberationManager] Teleported player to spawn %d at %s"
		% [spawn_index, spawn_transform.origin]
	)
	player_teleported.emit(player, spawn_index)
