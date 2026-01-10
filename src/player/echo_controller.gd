class_name EchoController
extends CharacterBody3D
## Controller for dead players in Echo (spectral observer) state.
##
## Features:
## - Floaty movement with no collision (passes through walls)
## - Can see entity at all times (even when not manifesting)
## - Visible as faint outline to living players
## - Cannot interact with physical objects (handled by FW-043c)
##
## An EchoController is spawned when a PlayerController dies.
## The original body remains at the death location.

# --- Signals ---

## Emitted when Echo starts moving.
signal movement_started

## Emitted when Echo stops moving.
signal movement_stopped

## Emitted when revival channeling starts.
signal revival_started(reviver_id: int)

## Emitted when revival progress updates.
signal revival_progress_changed(progress: float, duration: float)

## Emitted when revival is cancelled (hunt or reviver left).
signal revival_cancelled

## Emitted when revival completes successfully.
signal revival_completed

# --- Enums ---

## States for the revival process.
enum RevivalState { IDLE, CHANNELING, COMPLETE }

# --- Constants ---

## Reduced gravity for floaty feel.
const ECHO_GRAVITY := 2.0

## Default float speed (comparable to player walk speed).
const ECHO_FLOAT_SPEED := 4.0

## Vertical float speed when ascending/descending.
const ECHO_VERTICAL_SPEED := 3.0

## Deceleration factor for glide feel (0.0 = instant stop, 1.0 = no stop).
const ECHO_GLIDE_DECEL := 0.92

## Minimum velocity threshold before stopping.
const VELOCITY_THRESHOLD := 0.1

## Time required to revive an Echo (seconds).
const REVIVAL_DURATION := 30.0

# --- Export Settings ---

@export_group("Movement")
@export var float_speed: float = ECHO_FLOAT_SPEED
@export var vertical_speed: float = ECHO_VERTICAL_SPEED
@export var glide_deceleration: float = ECHO_GLIDE_DECEL

@export_group("Look")
@export_range(0.001, 0.01, 0.001) var mouse_sensitivity: float = 0.003
@export_range(-90.0, 0.0) var min_pitch: float = -89.0
@export_range(0.0, 90.0) var max_pitch: float = 89.0

@export_group("Appearance")
## Outline color for living players to see this Echo.
@export var outline_color: Color = Color(0.7, 0.8, 1.0, 0.3)
## Opacity of the Echo's mesh (translucent/ghostly).
@export var echo_opacity: float = 0.4

# --- State ---

## The player ID this Echo belongs to.
var player_id: int = 0

## Position where the player died (for revival mechanic).
var death_position: Vector3 = Vector3.ZERO

## Whether this Echo is controlled locally.
var is_local: bool = true

## Whether input is enabled.
var input_enabled: bool = true

## Whether the Echo is currently moving.
var is_moving: bool = false

## How many times this player has been revived this investigation.
var times_revived: int = 0

## Current state of revival process.
var revival_state: RevivalState = RevivalState.IDLE

## Progress of current revival (0.0 to REVIVAL_DURATION).
var revival_progress: float = 0.0

## Player ID of the player currently reviving this Echo (-1 if none).
var reviver_id: int = -1

# --- Node References ---

var _head: Node3D
var _camera: Camera3D
var _mesh: MeshInstance3D


func _ready() -> void:
	_setup_nodes()
	_disable_collision()

	if is_local:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _setup_nodes() -> void:
	_head = get_node_or_null("Head")
	if _head:
		_camera = _head.get_node_or_null("Camera3D")

	_mesh = get_node_or_null("MeshInstance3D")


## Disables collision so Echo can pass through walls.
func _disable_collision() -> void:
	# Disable all collision shapes
	for child in get_children():
		if child is CollisionShape3D:
			(child as CollisionShape3D).disabled = true

	# Set collision to not interact with anything
	collision_layer = 0
	collision_mask = 0


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or not is_local:
		return

	if event is InputEventMouseMotion:
		_handle_mouse_look(event)


func _physics_process(delta: float) -> void:
	if not is_local:
		return

	_handle_echo_movement(delta)


func _handle_mouse_look(event: InputEventMouseMotion) -> void:
	if not _head:
		return

	# Horizontal rotation (yaw) - rotate the whole body
	rotate_y(-event.relative.x * mouse_sensitivity)

	# Vertical rotation (pitch) - rotate just the head
	_head.rotate_x(-event.relative.y * mouse_sensitivity)
	_head.rotation.x = clampf(_head.rotation.x, deg_to_rad(min_pitch), deg_to_rad(max_pitch))


func _handle_echo_movement(delta: float) -> void:
	if not input_enabled:
		_apply_glide_deceleration(delta)
		return

	# Get horizontal input
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Get vertical input (ascend with jump, descend with crouch)
	var vertical_input := 0.0
	if Input.is_action_pressed("jump"):
		vertical_input = 1.0
	elif Input.is_action_pressed("crouch"):
		vertical_input = -1.0

	# Apply movement
	if direction.length() > 0.1 or absf(vertical_input) > 0.1:
		# Accelerate towards input direction
		var target_velocity := direction * float_speed
		target_velocity.y = vertical_input * vertical_speed

		velocity = velocity.lerp(target_velocity, 1.0 - glide_deceleration)

		if not is_moving:
			is_moving = true
			movement_started.emit()
	else:
		# Apply floaty deceleration
		_apply_glide_deceleration(delta)

	# Apply very light gravity for floaty feel
	velocity.y -= ECHO_GRAVITY * delta * 0.1

	# Move without collision
	_move_without_collision(delta)


func _apply_glide_deceleration(_delta: float) -> void:
	velocity *= glide_deceleration

	# Stop if velocity is very small
	if velocity.length() < VELOCITY_THRESHOLD:
		velocity = Vector3.ZERO
		if is_moving:
			is_moving = false
			movement_stopped.emit()


## Moves the Echo without physics collision.
## Since collision is disabled, we can just set position directly.
func _move_without_collision(delta: float) -> void:
	global_position += velocity * delta


# --- Public API ---


## Gets the current horizontal speed.
func get_horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


## Sets whether this is the local player's Echo.
func set_local(local: bool) -> void:
	is_local = local
	if is_local and input_enabled:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Enables or disables player input.
func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled


## Gets network state for synchronization.
func get_network_state() -> Dictionary:
	return {
		"position": position,
		"rotation": rotation,
		"velocity": velocity,
		"player_id": player_id,
	}


## Applies network state from server.
func apply_network_state(state: Dictionary) -> void:
	if state.has("position"):
		position = state.position
	if state.has("rotation"):
		rotation = state.rotation
	if state.has("velocity"):
		velocity = state.velocity


## Returns true since Echoes can always see the entity.
func can_see_entity() -> bool:
	return true


## Returns whether this observer can see entities regardless of visibility state.
## Echoes can see entities even when not manifesting.
func ignores_entity_visibility() -> bool:
	return true


## Returns whether this Echo is visible to a living observer.
## Living players see a faint outline of Echoes.
func is_visible_to_living() -> bool:
	return true


## Returns the outline color for this Echo.
func get_outline_color() -> Color:
	return outline_color


## Returns the opacity for this Echo's mesh.
func get_echo_opacity() -> float:
	return echo_opacity


## Sets up the translucent appearance for the Echo mesh.
## Call after mesh is assigned.
func setup_translucent_appearance() -> void:
	if not _mesh:
		return

	# Create translucent material
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(outline_color.r, outline_color.g, outline_color.b, echo_opacity)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED

	_mesh.material_override = material


# --- Voice Chat (Stub - FW-014) ---


## Returns true if this Echo can use proximity voice chat.
## Echoes can talk to other players, but with ethereal reverb effect (when voice is implemented).
func can_use_voice_chat() -> bool:
	return true


## Returns true if this Echo's voice should have the ethereal reverb effect.
## This is used by the voice chat system (FW-014) to apply audio effects.
func has_ethereal_voice() -> bool:
	return true


## Gets the voice settings for this Echo (stub for FW-014).
## Returns a dictionary that the voice chat system will use.
func get_voice_settings() -> Dictionary:
	return {
		"enabled": true,
		"ethereal_reverb": true,
		"reverb_amount": 0.6,
		"pitch_shift": 0.95,  # Slightly lower pitch for ghostly effect
	}


# --- Echo Restrictions (FW-043c) ---


## Returns false - Echoes cannot use equipment.
func can_use_equipment() -> bool:
	return false


## Returns false - Echoes cannot interact with physical objects.
func can_interact() -> bool:
	return false


## Returns false - Echoes cannot collect evidence.
func can_collect_evidence() -> bool:
	return false


## Returns false - Echoes cannot use Cultist abilities.
## (Even if the player was a Cultist before death, they lose those abilities.)
func can_use_cultist_abilities() -> bool:
	return false


## Returns false - Echoes cannot be targeted by the entity during hunts.
func is_valid_hunt_target() -> bool:
	return false


# --- Revival System (FW-043d) ---


## Returns whether this Echo can be revived.
## Cannot be revived if already revived once this investigation.
func can_be_revived() -> bool:
	return times_revived < 1


## Returns whether revival is currently in progress.
func is_being_revived() -> bool:
	return revival_state == RevivalState.CHANNELING


## Attempts to start revival by a player.
## Returns true if revival started, false if cannot be revived.
## reviver: The player ID attempting to revive.
func start_revival(reviver: int) -> bool:
	if not can_be_revived():
		return false  # Already revived once this investigation
	if revival_state != RevivalState.IDLE:
		return false  # Already being revived

	revival_state = RevivalState.CHANNELING
	revival_progress = 0.0
	reviver_id = reviver
	revival_started.emit(reviver_id)
	return true


## Updates revival progress. Call each frame while channeling.
## delta: Frame time in seconds.
func update_revival(delta: float) -> void:
	if revival_state != RevivalState.CHANNELING:
		return

	revival_progress += delta
	revival_progress_changed.emit(revival_progress, REVIVAL_DURATION)

	if revival_progress >= REVIVAL_DURATION:
		_complete_revival()


## Cancels ongoing revival (hunt interruption or reviver left).
func cancel_revival() -> void:
	if revival_state != RevivalState.CHANNELING:
		return

	revival_state = RevivalState.IDLE
	revival_progress = 0.0
	reviver_id = -1
	revival_cancelled.emit()


## Called when a hunt starts. Interrupts any ongoing revival.
func on_hunt_started() -> void:
	if revival_state == RevivalState.CHANNELING:
		cancel_revival()


## Returns revival progress as a percentage (0.0 to 1.0).
func get_revival_progress_percent() -> float:
	if revival_state != RevivalState.CHANNELING:
		return 0.0
	return revival_progress / REVIVAL_DURATION


## Returns the current reviver's player ID, or -1 if not being revived.
func get_reviver_id() -> int:
	return reviver_id


## Completes the revival process.
func _complete_revival() -> void:
	revival_state = RevivalState.COMPLETE
	times_revived += 1
	revival_completed.emit()
	# Actual transition to PlayerController is handled by caller
