class_name HidingSpot
extends Area3D
## A hiding location where players can evade the entity during hunts.
##
## Features:
## - Tracks player occupancy via Area3D body detection
## - Door state blocks entity detection when closed
## - Configurable search duration for entity behavior
## - Supports entity-specific variations (some can ignore)
##
## Place in scene with a CollisionShape3D child defining the hiding volume.
## Add a HidingSpotDoor child (or reference one via door_path) for door mechanics.

# --- Signals ---

## Emitted when a player enters this hiding spot.
signal player_entered(player_id: int)

## Emitted when a player exits this hiding spot.
signal player_exited(player_id: int)

## Emitted when the door state changes.
signal door_state_changed(is_closed: bool)

## Emitted when entity starts searching this hiding spot.
signal search_started(entity: Node)

## Emitted when entity finishes searching (player not found).
signal search_ended(entity: Node)

# --- Export Settings ---

@export_group("Hiding")
## If true, entity pathfinding cannot enter this volume.
@export var blocks_entity_entry: bool = true

## Duration entity will search this spot before moving on (seconds).
@export var search_duration: float = 5.0

## If true, players inside are protected from entity detection when door is closed.
@export var blocks_detection_when_closed: bool = true

@export_group("Door")
## Path to the door node (HidingSpotDoor or any node with is_door_closed method).
## If empty, will search for child with "door" in name.
@export var door_path: NodePath = NodePath()

## Initial door state if no door node is found.
@export var initial_door_closed: bool = false

# --- State ---

## Player IDs currently inside this hiding spot.
var _occupants: Array[int] = []

## Reference to the door node (if any).
var _door_node: Node = null

## Whether the door is currently closed (cached for performance).
var _is_door_closed: bool = false

## Entity currently searching this spot (null if none).
var _searching_entity: Node = null

## Timer for current entity search.
var _search_timer: float = 0.0


func _ready() -> void:
	# Set up collision - detect players only
	collision_layer = 0  # Not solid
	collision_mask = 2  # Player layer (bit 1)

	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Find door node
	_find_door_node()

	# Set initial door state
	_is_door_closed = initial_door_closed
	if _door_node and _door_node.has_method("is_closed"):
		_is_door_closed = _door_node.is_closed()

	add_to_group("hiding_spots")


func _process(delta: float) -> void:
	# Update search timer if entity is searching
	if _searching_entity and is_instance_valid(_searching_entity):
		_search_timer -= delta
		if _search_timer <= 0.0:
			_end_search()


# --- Public API ---


## Returns array of player IDs currently inside this hiding spot.
func get_occupants() -> Array[int]:
	return _occupants.duplicate()


## Returns true if there are players inside this hiding spot.
func has_occupants() -> bool:
	return not _occupants.is_empty()


## Returns the number of players inside.
func get_occupant_count() -> int:
	return _occupants.size()


## Returns true if the specified player is inside.
func has_player(player_id: int) -> bool:
	return player_id in _occupants


## Returns true if the door is closed.
func is_door_closed() -> bool:
	# Check door node if available
	if _door_node and is_instance_valid(_door_node):
		if _door_node.has_method("is_closed"):
			return _door_node.is_closed()
		if "is_closed" in _door_node:
			return _door_node.is_closed

	return _is_door_closed


## Sets the door state (used when no door node is present).
func set_door_closed(closed: bool) -> void:
	if _is_door_closed != closed:
		_is_door_closed = closed
		door_state_changed.emit(closed)


## Returns true if players inside are protected from entity detection.
## Players are protected if door is closed and detection blocking is enabled.
func is_protecting_occupants() -> bool:
	return blocks_detection_when_closed and is_door_closed() and has_occupants()


## Called by entity to check if it can detect players in this spot.
## Returns true if entity can see inside (door open or detection not blocked).
func can_entity_detect_inside() -> bool:
	if not blocks_detection_when_closed:
		return true
	return not is_door_closed()


## Called when entity starts searching this hiding spot.
func start_entity_search(entity: Node) -> void:
	if _searching_entity != null:
		return  # Already being searched

	_searching_entity = entity
	_search_timer = search_duration
	search_started.emit(entity)


## Returns true if an entity is currently searching this spot.
func is_being_searched() -> bool:
	return _searching_entity != null and is_instance_valid(_searching_entity)


## Returns the entity currently searching, or null.
func get_searching_entity() -> Node:
	return _searching_entity


## Returns remaining search time in seconds.
func get_search_time_remaining() -> float:
	return _search_timer


## Called to immediately end an entity's search (e.g., if entity dies or hunt ends).
func cancel_search() -> void:
	if _searching_entity:
		var entity := _searching_entity
		_searching_entity = null
		_search_timer = 0.0
		search_ended.emit(entity)


## Gets state for network synchronization.
func get_network_state() -> Dictionary:
	return {
		"occupants": _occupants.duplicate(),
		"door_closed": _is_door_closed,
		"being_searched": is_being_searched(),
		"search_timer": _search_timer,
	}


## Applies network state from host.
func apply_network_state(state: Dictionary) -> void:
	if state.has("occupants"):
		_occupants.assign(state.occupants)
	if state.has("door_closed"):
		set_door_closed(state.door_closed)
	if state.has("search_timer"):
		_search_timer = state.search_timer


# --- Private Methods ---


func _find_door_node() -> void:
	# Try explicit path first
	if door_path != NodePath():
		_door_node = get_node_or_null(door_path)
		if _door_node:
			_connect_door_signals()
			return

	# Search children for door node
	for child in get_children():
		if "door" in child.name.to_lower():
			_door_node = child
			_connect_door_signals()
			return


func _connect_door_signals() -> void:
	if _door_node == null:
		return

	# Connect to door state changes if signal exists
	if _door_node.has_signal("door_state_changed"):
		_door_node.door_state_changed.connect(_on_door_state_changed)
	elif _door_node.has_signal("toggled"):
		_door_node.toggled.connect(_on_door_toggled)


func _on_door_state_changed(is_closed: bool) -> void:
	_is_door_closed = is_closed
	door_state_changed.emit(is_closed)


func _on_door_toggled(pressed: bool) -> void:
	# For Toggle-style doors, "pressed" typically means closed
	_is_door_closed = pressed
	door_state_changed.emit(pressed)


func _on_body_entered(body: Node3D) -> void:
	var player_id := _get_player_id(body)
	if player_id >= 0 and player_id not in _occupants:
		_occupants.append(player_id)
		player_entered.emit(player_id)


func _on_body_exited(body: Node3D) -> void:
	var player_id := _get_player_id(body)
	if player_id >= 0:
		_occupants.erase(player_id)
		player_exited.emit(player_id)


func _get_player_id(node: Node) -> int:
	# Check if this is a player node
	if not node.is_in_group("players"):
		return -1

	# Try various ways to get player ID (using early assignment pattern)
	var player_id := -1

	if node.has_method("get_peer_id"):
		player_id = node.get_peer_id()
	elif node.get("peer_id") != null:
		player_id = node.peer_id
	elif node.has_method("get_player_id"):
		player_id = node.get_player_id()
	elif node.get("player_id") != null:
		player_id = node.player_id
	elif node.is_inside_tree():
		player_id = node.get_multiplayer_authority()

	return player_id


func _end_search() -> void:
	var entity := _searching_entity
	_searching_entity = null
	_search_timer = 0.0
	search_ended.emit(entity)
