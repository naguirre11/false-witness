class_name HidingSpotDoor
extends Interactable
## A door for hiding spots that can be opened/closed by players.
##
## When closed:
## - Blocks entity line-of-sight to players inside
## - Players see "Hiding" indicator
##
## Integrates with HidingSpot for entity detection mechanics.

# --- Signals ---

## Emitted when door state changes. True = closed.
signal door_state_changed(is_closed: bool)

# --- Export Settings ---

@export_group("Door")
## Whether the door starts closed.
@export var starts_closed: bool = false

## Animation player for door open/close animations (optional).
@export var animation_player_path: NodePath = NodePath()

## Name of the open animation.
@export var open_animation: String = "open"

## Name of the close animation.
@export var close_animation: String = "close"

@export_group("Collision")
## The collision shape that blocks LoS when door is closed.
## If empty, will search for StaticBody3D child.
@export var collision_body_path: NodePath = NodePath()

# --- State ---

## Whether the door is currently closed.
var _is_closed: bool = false

## Reference to animation player.
var _anim_player: AnimationPlayer = null

## Reference to collision body (blocks LoS).
var _collision_body: StaticBody3D = null


func _ready() -> void:
	super._ready()

	# Set interaction type to toggle
	interaction_type = InteractionType.TOGGLE

	# Find animation player
	if animation_player_path != NodePath():
		_anim_player = get_node_or_null(animation_player_path)
	else:
		# Search children
		for child in get_children():
			if child is AnimationPlayer:
				_anim_player = child
				break

	# Find collision body
	if collision_body_path != NodePath():
		_collision_body = get_node_or_null(collision_body_path)
	else:
		# Search children
		for child in get_children():
			if child is StaticBody3D:
				_collision_body = child
				break

	# Set initial state
	_is_closed = starts_closed
	_update_collision_state()

	add_to_group("hiding_spot_doors")


# --- Interactable Overrides ---


func _interact_impl(_player: Node) -> bool:
	# Toggle door state
	set_closed(not _is_closed)
	return true


func get_interaction_prompt() -> String:
	if _is_closed:
		return "Open"
	return "Close"


func get_network_state() -> Dictionary:
	var state := super.get_network_state()
	state["door_closed"] = _is_closed
	return state


func apply_network_state(state: Dictionary) -> void:
	super.apply_network_state(state)
	if state.has("door_closed"):
		set_closed(state.door_closed)


# --- Public API ---


## Returns true if the door is closed.
func is_closed() -> bool:
	return _is_closed


## Sets the door state.
func set_closed(closed: bool) -> void:
	if _is_closed == closed:
		return

	_is_closed = closed
	_update_collision_state()
	_play_animation()
	door_state_changed.emit(closed)


## Opens the door.
func open() -> void:
	set_closed(false)


## Closes the door.
func close() -> void:
	set_closed(true)


# --- Private Methods ---


func _update_collision_state() -> void:
	# Enable/disable collision body based on door state
	# When closed, collision should block LoS raycasts
	if _collision_body:
		# Keep physics processing enabled but adjust collision layers
		# World layer (1) is checked by LoS raycasts
		if _is_closed:
			_collision_body.collision_layer = 1  # World layer - blocks LoS
		else:
			_collision_body.collision_layer = 0  # No collision - doesn't block LoS


func _play_animation() -> void:
	if _anim_player == null:
		return

	var anim_name := close_animation if _is_closed else open_animation

	if _anim_player.has_animation(anim_name):
		_anim_player.play(anim_name)
