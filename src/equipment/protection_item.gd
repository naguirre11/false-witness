class_name ProtectionItem
extends Equipment
## Base class for protection items that provide counterplay against entity hunts.
##
## Protection items differ from evidence equipment:
## - They have limited charges
## - They can be placed in the world
## - They provide defensive capabilities against hunts
##
## Override `_on_placed()` and `_on_triggered()` in subclasses.

# --- Signals ---

signal charge_used(remaining: int)
signal placed(location: Vector3)
signal triggered(location: Vector3)
signal depleted

# --- Enums ---

enum PlacementMode {
	HELD,  ## Must hold to use (like sage bundle)
	PLACED,  ## Must place in world to work (like crucifix, salt)
}

# --- Export: Protection Settings ---

@export_group("Protection")
@export var max_charges: int = 1
@export var placement_mode: PlacementMode = PlacementMode.PLACED
@export var effective_radius: float = 3.0
@export var placement_range: float = 2.0

@export_group("Demon Modifier")
## Some entities (Demon) have modified protection effects.
## Set to 1.0 for no modification.
@export var demon_radius_multiplier: float = 1.0
@export var demon_duration_multiplier: float = 1.0

# --- State ---

var _charges_remaining: int = 0
var _is_placed: bool = false
var _placed_position: Vector3 = Vector3.ZERO
var _placed_item: Node3D = null


func _ready() -> void:
	_charges_remaining = max_charges
	can_use_during_hunt = true  # Protection items should work during hunts


# --- Virtual Methods (Override These) ---


## Override to implement behavior when item is placed in the world.
func _on_placed(_location: Vector3) -> void:
	pass


## Override to implement behavior when the protection triggers.
## Returns true if the trigger consumed a charge.
func _on_triggered(_target: Node) -> bool:
	return false


## Override to check if the item can be placed at the given location.
func _can_place_at(_location: Vector3) -> bool:
	return true


## Override to create the visual representation when placed.
func _create_placed_visual() -> Node3D:
	return null


# --- Public API ---


## Gets the remaining charges.
func get_charges_remaining() -> int:
	return _charges_remaining


## Returns true if the item has charges left.
func has_charges() -> bool:
	return _charges_remaining > 0


## Returns true if this item has been placed in the world.
func is_placed() -> bool:
	return _is_placed


## Gets the placed position (only valid if is_placed()).
func get_placed_position() -> Vector3:
	return _placed_position


## Gets the effective radius, accounting for entity modifiers.
func get_effective_radius(is_demon: bool = false) -> float:
	if is_demon:
		return effective_radius * demon_radius_multiplier
	return effective_radius


## Attempts to place the item at the given location. Returns true if successful.
func place_at(location: Vector3) -> bool:
	if _is_placed:
		push_warning("[ProtectionItem] Already placed")
		return false

	if not has_charges():
		push_warning("[ProtectionItem] No charges remaining")
		return false

	if not _can_place_at(location):
		return false

	_is_placed = true
	_placed_position = location

	# Create visual representation
	_placed_item = _create_placed_visual()
	if _placed_item:
		_placed_item.global_position = location
		_add_placed_item_to_world(_placed_item)

	_on_placed(location)
	placed.emit(location)

	# Emit EventBus signal
	var event_bus := _get_event_bus()
	if event_bus and event_bus.has_signal("protection_item_placed"):
		event_bus.protection_item_placed.emit(equipment_name, location)

	return true


## Called when something triggers this protection item.
## Returns true if the protection was activated.
func trigger(target: Node = null) -> bool:
	if not has_charges():
		return false

	if placement_mode == PlacementMode.PLACED and not _is_placed:
		return false

	var consumed: bool = _on_triggered(target)
	if consumed:
		_consume_charge()
		triggered.emit(_placed_position if _is_placed else global_position)

	return consumed


## Forcefully consumes a charge (for network sync or special cases).
func consume_charge() -> void:
	_consume_charge()


# --- Overrides ---


func _use_impl() -> void:
	match placement_mode:
		PlacementMode.HELD:
			# For held items, trigger immediately when used
			trigger()
		PlacementMode.PLACED:
			# For placed items, place at raycast target
			var place_location := _get_placement_location()
			if place_location != Vector3.ZERO:
				place_at(place_location)


func _can_use_impl(_player: Node) -> bool:
	return has_charges() and (placement_mode == PlacementMode.HELD or not _is_placed)


func get_network_state() -> Dictionary:
	var state := super.get_network_state()
	state["charges"] = _charges_remaining
	state["is_placed"] = _is_placed
	state["placed_position"] = {
		"x": _placed_position.x,
		"y": _placed_position.y,
		"z": _placed_position.z,
	}
	return state


func apply_network_state(state: Dictionary) -> void:
	super.apply_network_state(state)
	if state.has("charges"):
		_charges_remaining = state.charges
	if state.has("is_placed"):
		_is_placed = state.is_placed
	if state.has("placed_position"):
		var pos: Dictionary = state.placed_position
		_placed_position = Vector3(pos.x, pos.y, pos.z)


# --- Internal Methods ---


func _consume_charge() -> void:
	if _charges_remaining > 0:
		_charges_remaining -= 1
		charge_used.emit(_charges_remaining)

		if _charges_remaining == 0:
			depleted.emit()
			_on_depleted()


func _on_depleted() -> void:
	# Emit EventBus signal
	var event_bus := _get_event_bus()
	if event_bus and event_bus.has_signal("protection_item_depleted"):
		var location := _placed_position if _is_placed else global_position
		event_bus.protection_item_depleted.emit(equipment_name, location)


func _get_placement_location() -> Vector3:
	# Get placement location from camera raycast
	if not _owning_player:
		return Vector3.ZERO

	var camera: Camera3D = _get_player_camera()
	if not camera:
		return Vector3.ZERO

	var space_state := camera.get_world_3d().direct_space_state
	if not space_state:
		return Vector3.ZERO

	var from := camera.global_position
	var to := from + (-camera.global_transform.basis.z * placement_range)

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1  # World layer only
	query.exclude = [_owning_player] if _owning_player is CollisionObject3D else []

	var result := space_state.intersect_ray(query)
	if result:
		return result.position

	return Vector3.ZERO


func _get_player_camera() -> Camera3D:
	if _owning_player and _owning_player.has_node("Head/Camera3D"):
		return _owning_player.get_node("Head/Camera3D") as Camera3D
	return null


func _add_placed_item_to_world(item: Node3D) -> void:
	# Add to scene tree at root level so it persists
	var tree := get_tree()
	if tree and tree.current_scene:
		tree.current_scene.add_child(item)
