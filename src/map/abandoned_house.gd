class_name AbandonedHouseMap
extends Node3D
## The Abandoned House map scene controller.
##
## Handles map initialization including:
## - Navigation mesh baking on startup
## - Room configuration
## - Entity favorite room selection
## - Spawn point management

# --- Signals ---

## Emitted when map initialization is complete.
signal map_ready

## Emitted when navigation mesh baking completes.
signal navigation_ready

# --- Export Settings ---

@export_group("Rooms")
## List of room names that can be the entity's favorite.
@export var candidate_favorite_rooms: Array[String] = [
	"MasterBedroom",
	"SecondBedroom",
	"Basement",
	"Attic"
]

## Currently selected favorite room (set at match start).
var favorite_room: String = ""

# --- Node References ---

@onready var _navigation: NavigationRegion3D = $Navigation
@onready var _spawns: Node3D = $Spawns
@onready var _evidence_points: Node3D = $EvidencePoints
@onready var _hiding_spots: Node3D = $HidingSpots
@onready var _rooms: Node3D = $Rooms


func _ready() -> void:
	# Bake navigation mesh
	_bake_navigation()

	# Select random favorite room
	_select_favorite_room()

	# Emit ready signal
	call_deferred("emit_signal", "map_ready")


## Bakes the navigation mesh from scene geometry.
func _bake_navigation() -> void:
	if _navigation == null:
		push_warning("[AbandonedHouse] No NavigationRegion3D found")
		return

	var nav_mesh: NavigationMesh = _navigation.navigation_mesh
	if nav_mesh == null:
		push_warning("[AbandonedHouse] No NavigationMesh assigned")
		return

	# Connect to baking finished signal
	if not _navigation.bake_finished.is_connected(_on_bake_finished):
		_navigation.bake_finished.connect(_on_bake_finished)

	# Bake the navigation mesh
	_navigation.bake_navigation_mesh()


func _on_bake_finished() -> void:
	print("[AbandonedHouse] Navigation mesh baked")
	navigation_ready.emit()


## Selects a random favorite room for the entity.
func _select_favorite_room() -> void:
	if candidate_favorite_rooms.is_empty():
		push_warning("[AbandonedHouse] No candidate favorite rooms configured")
		favorite_room = "MasterBedroom"  # Fallback
		return

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var idx: int = rng.randi_range(0, candidate_favorite_rooms.size() - 1)
	favorite_room = candidate_favorite_rooms[idx]
	print("[AbandonedHouse] Favorite room: %s" % favorite_room)


# --- Public API ---


## Returns all spawn points as an array of positions.
func get_spawn_positions() -> Array[Vector3]:
	var positions: Array[Vector3] = []
	if _spawns == null:
		return positions

	for child in _spawns.get_children():
		if child is Marker3D:
			positions.append(child.global_position)

	return positions


## Returns a specific spawn point by index.
func get_spawn_point(index: int) -> Vector3:
	if _spawns == null:
		return Vector3.ZERO

	var children := _spawns.get_children()
	if index < 0 or index >= children.size():
		return Vector3.ZERO

	var marker := children[index] as Marker3D
	return marker.global_position if marker else Vector3.ZERO


## Returns the number of spawn points.
func get_spawn_count() -> int:
	return _spawns.get_child_count() if _spawns else 0


## Returns all evidence spawn points.
func get_evidence_points() -> Array[Marker3D]:
	var points: Array[Marker3D] = []
	if _evidence_points == null:
		return points

	for child in _evidence_points.get_children():
		if child is Marker3D:
			points.append(child)

	return points


## Returns all hiding spots.
func get_hiding_spots() -> Array[Node]:
	var spots: Array[Node] = []
	if _hiding_spots == null:
		return spots

	for child in _hiding_spots.get_children():
		spots.append(child)

	return spots


## Returns the Room node by name.
func get_room(room_name: String) -> Node3D:
	if _rooms == null:
		return null
	return _rooms.get_node_or_null(room_name) as Node3D


## Returns the entity's favorite room name.
func get_favorite_room() -> String:
	return favorite_room


## Returns the favorite room node.
func get_favorite_room_node() -> Node3D:
	return get_room(favorite_room)


## Returns evidence points in a specific room.
func get_evidence_points_in_room(room_name: String) -> Array[Marker3D]:
	var points: Array[Marker3D] = []
	for child in _evidence_points.get_children():
		if child is Marker3D and child.name.begins_with(room_name):
			points.append(child)
	return points


## Returns hiding spots in a specific room.
func get_hiding_spots_in_room(room_name: String) -> Array[Node]:
	var spots: Array[Node] = []
	for child in _hiding_spots.get_children():
		if room_name.to_lower() in child.name.to_lower():
			spots.append(child)
	return spots


## Gets network state for synchronization.
func get_network_state() -> Dictionary:
	return {
		"favorite_room": favorite_room,
	}


## Applies network state from host.
func apply_network_state(state: Dictionary) -> void:
	if state.has("favorite_room"):
		favorite_room = state.favorite_room
