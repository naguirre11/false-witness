class_name InteractableDoor
extends Interactable
## A door that can be manipulated by both players and entities.
##
## Supports multiple interaction styles:
## - Player: Normal open/close via interaction
## - Entity Slam: Violent, loud door slam (territorial behavior)
## - Entity Slow Open: Creepy slow opening (stalking behavior)
## - Entity Slow Close: Creepy slow closing
##
## Door state is synced across the network. Sound effects play
## for all nearby players based on interaction type.

# --- Signals ---

## Emitted when door state changes.
signal door_state_changed(new_state: DoorState)

## Emitted when door is slammed (entity action).
signal door_slammed(entity_type: String)

## Emitted when door begins slow motion (entity action).
signal door_slow_motion_started(is_opening: bool, entity_type: String)

## Emitted when door slow motion completes.
signal door_slow_motion_finished

# --- Enums ---

## Current state of the door.
enum DoorState {
	CLOSED,  ## Door fully closed
	OPEN,  ## Door fully open
	OPENING,  ## Door in process of opening
	CLOSING,  ## Door in process of closing
	LOCKED,  ## Door locked (cannot open)
}

## Entity manipulation styles.
enum EntityDoorAction {
	SLAM_SHUT,  ## Violent slam (territorial entity)
	SLAM_OPEN,  ## Violent slam open
	SLOW_OPEN,  ## Creepy slow open (stalking entity)
	SLOW_CLOSE,  ## Creepy slow close
}

# --- Constants ---

## Speed for normal player interaction (degrees per second).
const NORMAL_ROTATION_SPEED := 180.0

## Speed for slam action (very fast).
const SLAM_ROTATION_SPEED := 720.0

## Speed for creepy slow action.
const SLOW_ROTATION_SPEED := 15.0

## Audible range for slam sounds (throughout building).
const SLAM_AUDIBLE_RANGE := 50.0

## Audible range for normal door sounds.
const NORMAL_AUDIBLE_RANGE := 15.0

## Visible range for door animations.
const VISIBLE_RANGE := 30.0

# --- Export: Door Settings ---

@export_group("Door")
## Maximum rotation angle when open (degrees).
@export var open_angle: float = 90.0

## Direction of rotation (1 = clockwise, -1 = counter-clockwise).
@export var rotation_direction: float = 1.0

## Whether the door starts open.
@export var starts_open: bool = false

## Axis of rotation (usually Y for standard doors).
@export var rotation_axis: Vector3 = Vector3.UP

@export_group("Locking")
## Whether this door can be locked.
@export var can_lock: bool = false

## Whether door starts locked.
@export var starts_locked: bool = false

## Key item required to unlock (empty = no key required).
@export var required_key: String = ""

@export_group("Audio")
## Sound for normal open/close.
@export var open_close_sound: AudioStream

## Sound for door slam.
@export var slam_sound: AudioStream

## Sound for creepy creak during slow motion.
@export var creak_sound: AudioStream

## Sound when door is locked and player tries to open.
@export var locked_sound: AudioStream

# --- State ---

var _door_state: DoorState = DoorState.CLOSED
var _current_angle: float = 0.0
var _target_angle: float = 0.0
var _rotation_speed: float = NORMAL_ROTATION_SPEED
var _is_entity_action: bool = false
var _last_entity_type: String = ""
var _original_rotation: Vector3 = Vector3.ZERO


func _ready() -> void:
	super._ready()
	add_to_group("doors")
	interaction_type = InteractionType.USE
	interaction_prompt = "Open"

	_original_rotation = rotation

	if starts_locked and can_lock:
		_door_state = DoorState.LOCKED

	if starts_open and _door_state != DoorState.LOCKED:
		_current_angle = open_angle
		_target_angle = open_angle
		_door_state = DoorState.OPEN
		_apply_rotation()
		_update_prompt()


func _physics_process(delta: float) -> void:
	if _door_state not in [DoorState.OPENING, DoorState.CLOSING]:
		return

	# Move toward target angle
	var move_amount := _rotation_speed * delta
	var angle_diff := _target_angle - _current_angle

	if absf(angle_diff) <= move_amount:
		# Reached target
		_current_angle = _target_angle
		_apply_rotation()
		_finish_motion()
	else:
		# Continue moving
		_current_angle += signf(angle_diff) * move_amount
		_apply_rotation()


# --- Player Interaction ---


func _interact_impl(_player: Node) -> bool:
	if _door_state == DoorState.LOCKED:
		_play_locked_sound()
		return false

	if _door_state in [DoorState.OPENING, DoorState.CLOSING]:
		return false  # Already in motion

	_is_entity_action = false

	if _door_state == DoorState.CLOSED:
		_start_opening(NORMAL_ROTATION_SPEED)
	else:
		_start_closing(NORMAL_ROTATION_SPEED)

	return true


func _can_interact_impl(_player: Node) -> bool:
	# Can interact unless in motion
	return _door_state not in [DoorState.OPENING, DoorState.CLOSING]


func get_interaction_prompt() -> String:
	match _door_state:
		DoorState.LOCKED:
			return "Locked"
		DoorState.OPEN:
			return "Close"
		DoorState.CLOSED:
			return "Open"
		_:
			return ""


# --- Entity Manipulation ---


## Called by entities to manipulate the door.
## Returns true if the action was initiated.
func entity_manipulate(action: EntityDoorAction, entity_type: String) -> bool:
	# Cannot manipulate locked or moving doors
	if _door_state in [DoorState.LOCKED, DoorState.OPENING, DoorState.CLOSING]:
		return false

	_is_entity_action = true
	_last_entity_type = entity_type

	var action_handlers := {
		EntityDoorAction.SLAM_SHUT: _slam_shut,
		EntityDoorAction.SLAM_OPEN: _slam_open,
		EntityDoorAction.SLOW_OPEN: _slow_open,
		EntityDoorAction.SLOW_CLOSE: _slow_close,
	}

	if action in action_handlers:
		return action_handlers[action].call()
	return false


func _slam_shut() -> bool:
	if _door_state == DoorState.CLOSED:
		return false

	_start_closing(SLAM_ROTATION_SPEED)
	_play_slam_sound()
	door_slammed.emit(_last_entity_type)
	_emit_door_event("slam_shut")
	return true


func _slam_open() -> bool:
	if _door_state == DoorState.OPEN:
		return false

	_start_opening(SLAM_ROTATION_SPEED)
	_play_slam_sound()
	door_slammed.emit(_last_entity_type)
	_emit_door_event("slam_open")
	return true


func _slow_open() -> bool:
	if _door_state == DoorState.OPEN:
		return false

	_start_opening(SLOW_ROTATION_SPEED)
	_play_creak_sound()
	door_slow_motion_started.emit(true, _last_entity_type)
	_emit_door_event("slow_open")
	return true


func _slow_close() -> bool:
	if _door_state == DoorState.CLOSED:
		return false

	_start_closing(SLOW_ROTATION_SPEED)
	_play_creak_sound()
	door_slow_motion_started.emit(false, _last_entity_type)
	_emit_door_event("slow_close")
	return true


# --- Door Motion ---


func _start_opening(speed: float) -> void:
	_target_angle = open_angle
	_rotation_speed = speed
	_set_door_state(DoorState.OPENING)

	if not _is_entity_action:
		_play_open_close_sound()


func _start_closing(speed: float) -> void:
	_target_angle = 0.0
	_rotation_speed = speed
	_set_door_state(DoorState.CLOSING)

	if not _is_entity_action:
		_play_open_close_sound()


func _finish_motion() -> void:
	if _current_angle >= open_angle - 0.1:
		_set_door_state(DoorState.OPEN)
	else:
		_set_door_state(DoorState.CLOSED)

	if _is_entity_action and _rotation_speed == SLOW_ROTATION_SPEED:
		door_slow_motion_finished.emit()

	_is_entity_action = false
	_update_prompt()


func _apply_rotation() -> void:
	var angle_radians := deg_to_rad(_current_angle * rotation_direction)
	rotation = _original_rotation + rotation_axis * angle_radians


func _set_door_state(new_state: DoorState) -> void:
	if _door_state != new_state:
		_door_state = new_state
		door_state_changed.emit(new_state)


func _update_prompt() -> void:
	interaction_prompt = get_interaction_prompt()


# --- Locking ---


## Locks the door.
func lock() -> void:
	if not can_lock:
		return
	if _door_state == DoorState.OPEN:
		return  # Can't lock an open door

	_set_door_state(DoorState.LOCKED)
	_update_prompt()


## Unlocks the door.
func unlock() -> void:
	if _door_state != DoorState.LOCKED:
		return

	_set_door_state(DoorState.CLOSED)
	_update_prompt()


## Returns true if door is locked.
func is_locked() -> bool:
	return _door_state == DoorState.LOCKED


# --- Public API ---


## Returns the current door state.
func get_door_state() -> DoorState:
	return _door_state


## Returns true if door is currently open.
func is_open() -> bool:
	return _door_state == DoorState.OPEN


## Returns true if door is currently closed.
func is_closed() -> bool:
	return _door_state == DoorState.CLOSED


## Returns true if door is in motion.
func is_moving() -> bool:
	return _door_state in [DoorState.OPENING, DoorState.CLOSING]


## Returns the current angle (0 = closed, open_angle = open).
func get_current_angle() -> float:
	return _current_angle


## Returns the entity type that last manipulated this door.
func get_last_entity_type() -> String:
	return _last_entity_type


## Forces door to a specific state (for testing/reset).
func set_door_open(is_open: bool) -> void:
	if is_open:
		_current_angle = open_angle
		_target_angle = open_angle
		_set_door_state(DoorState.OPEN)
	else:
		_current_angle = 0.0
		_target_angle = 0.0
		_set_door_state(DoorState.CLOSED)
	_apply_rotation()
	_update_prompt()


# --- Internal: Events ---


func _emit_door_event(action: String) -> void:
	var event_bus := _get_event_bus()
	if event_bus and event_bus.has_signal("door_manipulated"):
		event_bus.door_manipulated.emit(
			get_path(),
			action,
			_last_entity_type,
			global_position
		)


# --- Internal: Audio ---


func _play_open_close_sound() -> void:
	if open_close_sound == null:
		return
	_play_spatial_audio(open_close_sound, NORMAL_AUDIBLE_RANGE)


func _play_slam_sound() -> void:
	if slam_sound == null:
		return
	_play_spatial_audio(slam_sound, SLAM_AUDIBLE_RANGE)


func _play_creak_sound() -> void:
	if creak_sound == null:
		return
	_play_spatial_audio(creak_sound, NORMAL_AUDIBLE_RANGE)


func _play_locked_sound() -> void:
	if locked_sound == null:
		return
	_play_spatial_audio(locked_sound, NORMAL_AUDIBLE_RANGE)


func _play_spatial_audio(stream: AudioStream, max_distance: float) -> void:
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.max_distance = max_distance
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


# --- Network State ---


func get_network_state() -> Dictionary:
	var state := super.get_network_state()
	state["door_state"] = _door_state
	state["current_angle"] = _current_angle
	state["target_angle"] = _target_angle
	state["rotation_speed"] = _rotation_speed
	state["is_entity_action"] = _is_entity_action
	state["last_entity_type"] = _last_entity_type
	return state


func apply_network_state(state: Dictionary) -> void:
	super.apply_network_state(state)
	if state.has("door_state"):
		_door_state = state.door_state as DoorState
	if state.has("current_angle"):
		_current_angle = state.current_angle
		_apply_rotation()
	if state.has("target_angle"):
		_target_angle = state.target_angle
	if state.has("rotation_speed"):
		_rotation_speed = state.rotation_speed
	if state.has("is_entity_action"):
		_is_entity_action = state.is_entity_action
	if state.has("last_entity_type"):
		_last_entity_type = state.last_entity_type
	_update_prompt()
