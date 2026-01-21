extends Node3D
## Deliberation area - safe zone where players discuss findings.
## Players are teleported here during DELIBERATION phase.
##
## Features:
## - Spawn points for 4-6 players
## - Invisible boundary to contain players
## - No entity access (Entity collision mask excludes this area)
## - Evidence board viewing point

const MAX_SPAWN_POINTS: int = 6

# --- Signals ---

signal player_spawned(player: Node3D, spawn_index: int)
signal player_exited_boundary(player: Node3D)

# --- Exported Configuration ---

## Path to the evidence board visual (for camera focus)
@export var evidence_board_focus: Marker3D

# --- State Variables ---

var _spawn_points: Array[Marker3D] = []
var _next_spawn_index: int = 0
var _spawned_players: Dictionary = {}  # player_id -> spawn_index

# --- Node References ---

@onready var _boundary_area: Area3D = $BoundaryArea
@onready var _spawn_container: Node3D = $SpawnPoints


func _ready() -> void:
	_collect_spawn_points()
	_connect_signals()
	print("[DeliberationArea] Initialized with %d spawn points" % _spawn_points.size())


## Returns the spawn position for a given player index (0-5).
func get_spawn_position(index: int) -> Vector3:
	if index < 0 or index >= _spawn_points.size():
		push_warning("[DeliberationArea] Invalid spawn index: %d" % index)
		return global_position

	return _spawn_points[index].global_position


## Returns the spawn transform for a given player index (0-5).
func get_spawn_transform(index: int) -> Transform3D:
	if index < 0 or index >= _spawn_points.size():
		push_warning("[DeliberationArea] Invalid spawn index: %d" % index)
		return global_transform

	return _spawn_points[index].global_transform


## Assigns a spawn point to a player and returns the index.
## Returns -1 if no spawn points available.
func assign_spawn_point(player_id: int) -> int:
	if _next_spawn_index >= _spawn_points.size():
		push_warning("[DeliberationArea] No more spawn points available")
		return -1

	var index := _next_spawn_index
	_spawned_players[player_id] = index
	_next_spawn_index += 1
	return index


## Gets the spawn index for an already-assigned player.
## Returns -1 if player not assigned.
func get_player_spawn_index(player_id: int) -> int:
	return _spawned_players.get(player_id, -1)


## Clears all spawn assignments (call when deliberation ends).
func clear_spawn_assignments() -> void:
	_spawned_players.clear()
	_next_spawn_index = 0


## Returns the total number of spawn points available.
func get_spawn_count() -> int:
	return _spawn_points.size()


## Returns the position to look at when viewing the evidence board.
func get_evidence_board_focus_position() -> Vector3:
	if evidence_board_focus:
		return evidence_board_focus.global_position
	# Fallback: center of the area
	return global_position


## Teleports a player to their assigned spawn point.
func teleport_player(player: Node3D, spawn_index: int) -> void:
	if spawn_index < 0 or spawn_index >= _spawn_points.size():
		push_warning("[DeliberationArea] Invalid spawn index for teleport: %d" % spawn_index)
		return

	var spawn_transform := get_spawn_transform(spawn_index)
	player.global_transform = spawn_transform
	player_spawned.emit(player, spawn_index)
	print(
		"[DeliberationArea] Teleported player to spawn point %d at %s"
		% [spawn_index, spawn_transform.origin]
	)


# --- Private Methods ---


func _collect_spawn_points() -> void:
	_spawn_points.clear()
	for child in _spawn_container.get_children():
		if child is Marker3D:
			_spawn_points.append(child)

	if _spawn_points.size() < MAX_SPAWN_POINTS:
		push_warning(
			"[DeliberationArea] Only %d spawn points found, expected %d"
			% [_spawn_points.size(), MAX_SPAWN_POINTS]
		)


func _connect_signals() -> void:
	if _boundary_area:
		_boundary_area.body_exited.connect(_on_body_exited_boundary)


func _on_body_exited_boundary(body: Node3D) -> void:
	# Only care about players exiting
	if body.is_in_group("players"):
		push_warning("[DeliberationArea] Player exited boundary: %s" % body.name)
		player_exited_boundary.emit(body)
