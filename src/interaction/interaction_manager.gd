class_name InteractionManager
extends Node
## Manages player interaction with the environment via raycasting.
##
## Attach to a player node to enable interaction with Interactable objects.
## Performs raycasts from the camera center to detect interactables in range.

# --- Signals ---

signal target_changed(new_target: Interactable)
signal interaction_performed(target: Interactable, success: bool)

# --- Constants ---

const DEFAULT_INTERACTION_RANGE: float = 2.5

# --- Export: Settings ---

@export_group("Raycast")
@export var interaction_layer_mask: int = 8  ## Layer 4 (Interactable)
@export var max_range: float = 5.0
@export var raycast_interval: float = 0.05  ## Seconds between raycasts

# --- State ---

var _current_target: Interactable = null
var _player: Node = null
var _camera: Camera3D = null
var _raycast_timer: float = 0.0
var _enabled: bool = true


func _ready() -> void:
	# Find camera in parent hierarchy
	_find_camera()


func _process(delta: float) -> void:
	if not _enabled or not _camera:
		return

	_raycast_timer += delta
	if _raycast_timer >= raycast_interval:
		_raycast_timer = 0.0
		_update_target()


func _unhandled_input(event: InputEvent) -> void:
	if not _enabled:
		return

	if event.is_action_pressed("interact"):
		_try_interact()


# --- Setup ---

func _find_camera() -> void:
	# Look for camera in common player hierarchy patterns
	var parent := get_parent()
	if not parent:
		return

	_player = parent

	# Try Head/Camera3D pattern (from player.tscn)
	var head := parent.get_node_or_null("Head")
	if head:
		_camera = head.get_node_or_null("Camera3D")

	# Fallback: find any Camera3D in the parent
	if not _camera:
		_camera = _find_camera_recursive(parent)


func _find_camera_recursive(node: Node) -> Camera3D:
	if node is Camera3D:
		return node
	for child in node.get_children():
		var found := _find_camera_recursive(child)
		if found:
			return found
	return null


# --- Raycast Detection ---

func _update_target() -> void:
	var new_target := _raycast_for_interactable()

	if new_target != _current_target:
		_current_target = new_target
		target_changed.emit(new_target)


func _raycast_for_interactable() -> Interactable:
	var interactable: Interactable = null

	if _camera and is_instance_valid(_camera):
		interactable = _perform_raycast()

	return interactable


func _perform_raycast() -> Interactable:
	var space_state := _camera.get_world_3d().direct_space_state
	if not space_state:
		return null

	var from := _camera.global_position
	var to := from + (-_camera.global_basis.z) * max_range

	var query := PhysicsRayQueryParameters3D.create(from, to, interaction_layer_mask)
	if _player:
		query.exclude = [_player.get_rid()] if _player.has_method("get_rid") else []

	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return null

	var collider := result.get("collider")
	if not collider:
		return null

	var interactable := _find_interactable(collider)
	if not interactable:
		return null

	return _validate_interactable(interactable, from, result.position)


func _validate_interactable(
	interactable: Interactable, from: Vector3, hit_pos: Vector3
) -> Interactable:
	var distance: float = from.distance_to(hit_pos)
	var in_range: bool = distance <= interactable.get_interaction_range()
	var can_use: bool = interactable.can_interact(_player)

	if in_range and can_use:
		return interactable
	return null


func _find_interactable(node: Node) -> Interactable:
	# Check if node itself is an Interactable
	if node is Interactable:
		return node

	# Walk up parent hierarchy to find Interactable
	var current := node.get_parent()
	while current:
		if current is Interactable:
			return current
		current = current.get_parent()

	return null


# --- Interaction ---

func _try_interact() -> void:
	if not _current_target:
		return

	var success: bool = _current_target.interact(_player)
	interaction_performed.emit(_current_target, success)


## Manually trigger an interaction with the current target.
func interact() -> bool:
	if not _current_target:
		return false

	var success: bool = _current_target.interact(_player)
	interaction_performed.emit(_current_target, success)
	return success


## Interact with a specific target, bypassing the current target.
func interact_with(target: Interactable) -> bool:
	if not target or not target.can_interact(_player):
		return false

	var success: bool = target.interact(_player)
	interaction_performed.emit(target, success)
	return success


# --- Public API ---

## Gets the currently targeted interactable (or null if none).
func get_current_target() -> Interactable:
	return _current_target


## Gets whether there is a valid target.
func has_target() -> bool:
	return _current_target != null and is_instance_valid(_current_target)


## Gets the interaction prompt for the current target.
func get_current_prompt() -> String:
	if not has_target():
		return ""
	return _current_target.get_interaction_prompt()


## Enables or disables the interaction system.
func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	if not enabled:
		if _current_target:
			_current_target = null
			target_changed.emit(null)


## Gets whether the interaction system is enabled.
func is_enabled() -> bool:
	return _enabled


## Sets the camera to use for raycasting.
func set_camera(camera: Camera3D) -> void:
	_camera = camera


## Sets the player node reference.
func set_player(player: Node) -> void:
	_player = player


## Forces an immediate target update (useful after teleporting).
func force_update() -> void:
	_raycast_timer = 0.0
	_update_target()
