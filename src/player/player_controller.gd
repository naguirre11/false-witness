class_name PlayerController
extends CharacterBody3D
## First-person player controller with movement, look, sprint, crouch, and head bob.
##
## Features:
## - WASD movement with smooth acceleration/deceleration
## - Mouse look with configurable sensitivity
## - Sprint with stamina system
## - Crouch for hiding
## - Optional head bob
## - Footstep sounds tied to movement
## - Network-ready (local prediction support)

# --- Signals ---

signal stamina_changed(current: float, maximum: float)
signal crouched(is_crouching: bool)
signal footstep
signal died(death_position: Vector3)
signal revived

# --- Constants ---

const GRAVITY: float = 9.8

## Sanity percentage player respawns with after being revived.
const REVIVAL_SANITY_PERCENT := 0.5

# --- Export: Movement Settings ---

@export_group("Movement")
@export var walk_speed: float = 4.0
@export var sprint_speed: float = 7.0
@export var crouch_speed: float = 2.0
@export var acceleration: float = 10.0
@export var deceleration: float = 12.0
@export var air_control: float = 0.3

# --- Export: Look Settings ---

@export_group("Look")
@export_range(0.001, 0.01, 0.001) var mouse_sensitivity: float = 0.003
@export_range(-90.0, 0.0) var min_pitch: float = -89.0
@export_range(0.0, 90.0) var max_pitch: float = 89.0

# --- Export: Sprint/Stamina Settings ---

@export_group("Sprint")
@export var max_stamina: float = 100.0
@export var stamina_drain_rate: float = 20.0
@export var stamina_regen_rate: float = 15.0
@export var stamina_regen_delay: float = 1.0
@export var min_sprint_stamina: float = 10.0

# --- Export: Crouch Settings ---

@export_group("Crouch")
@export var standing_height: float = 1.8
@export var crouch_height: float = 1.0
@export var crouch_transition_speed: float = 10.0

# --- Export: Head Bob Settings ---

@export_group("Head Bob")
@export var head_bob_enabled: bool = true
@export var head_bob_frequency: float = 2.0
@export var head_bob_amplitude: float = 0.05
@export var head_bob_sprint_multiplier: float = 1.4

# --- Export: Audio Settings ---

@export_group("Audio")
@export var footstep_interval: float = 0.5
@export var sprint_footstep_interval: float = 0.35
@export var crouch_footstep_interval: float = 0.7

# --- State ---

var current_stamina: float = 100.0
var is_sprinting: bool = false
var is_crouching: bool = false
var is_alive: bool = true
var is_echo: bool = false
var death_position: Vector3 = Vector3.ZERO
var times_revived: int = 0
var stamina_regen_timer: float = 0.0
var head_bob_time: float = 0.0
var footstep_timer: float = 0.0
var input_enabled: bool = true
var is_local_player: bool = true

## Network peer ID for this player.
var player_id: int = -1

## Display name for this player.
var player_name: String = ""

# --- Node References ---

var _head: Node3D
var _camera: Camera3D
var _collision_shape: CollisionShape3D
var _footstep_player: AudioStreamPlayer3D
var _name_label: Node3D
var _original_head_y: float = 0.0
var _target_height: float = 1.8


func _ready() -> void:
	_setup_nodes()
	current_stamina = max_stamina
	_target_height = standing_height

	if is_local_player:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _setup_nodes() -> void:
	_head = get_node_or_null("Head")
	if _head:
		_camera = _head.get_node_or_null("Camera3D")
		_original_head_y = _head.position.y

	_collision_shape = get_node_or_null("CollisionShape3D")
	_footstep_player = get_node_or_null("FootstepPlayer")
	_name_label = get_node_or_null("NameLabel")


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or not is_local_player:
		return

	if event is InputEventMouseMotion:
		_handle_mouse_look(event)


func _physics_process(delta: float) -> void:
	if not is_local_player:
		return

	# Dead players don't process movement (Echo handled by FW-043b)
	if not is_alive:
		return

	_apply_gravity(delta)
	_handle_movement_input(delta)
	_handle_sprint(delta)
	_handle_crouch(delta)
	_update_head_bob(delta)
	_update_footsteps(delta)

	move_and_slide()


func _handle_mouse_look(event: InputEventMouseMotion) -> void:
	if not _head:
		return

	# Horizontal rotation (yaw) - rotate the whole body
	rotate_y(-event.relative.x * mouse_sensitivity)

	# Vertical rotation (pitch) - rotate just the head
	_head.rotate_x(-event.relative.y * mouse_sensitivity)
	_head.rotation.x = clampf(_head.rotation.x, deg_to_rad(min_pitch), deg_to_rad(max_pitch))


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta


func _handle_movement_input(delta: float) -> void:
	if not input_enabled:
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var target_speed := _get_current_speed()
	var accel := acceleration if direction.length() > 0.1 else deceleration

	# Reduce control in air
	if not is_on_floor():
		accel *= air_control

	var target_velocity := direction * target_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, accel * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, accel * delta)


func _get_current_speed() -> float:
	if is_crouching:
		return crouch_speed
	if is_sprinting and current_stamina > 0:
		return sprint_speed
	return walk_speed


func _handle_sprint(delta: float) -> void:
	var wants_sprint := Input.is_action_pressed("sprint") and input_enabled
	var can_sprint := current_stamina > min_sprint_stamina and _is_moving() and not is_crouching

	var was_sprinting := is_sprinting
	is_sprinting = wants_sprint and can_sprint and is_on_floor()

	if is_sprinting:
		# Drain stamina
		current_stamina = maxf(0.0, current_stamina - stamina_drain_rate * delta)
		stamina_regen_timer = stamina_regen_delay

		if current_stamina <= 0:
			is_sprinting = false
	else:
		# Regenerate stamina after delay
		if stamina_regen_timer > 0:
			stamina_regen_timer -= delta
		else:
			current_stamina = minf(max_stamina, current_stamina + stamina_regen_rate * delta)

	if was_sprinting != is_sprinting or current_stamina != max_stamina:
		stamina_changed.emit(current_stamina, max_stamina)


func _handle_crouch(delta: float) -> void:
	var wants_crouch := Input.is_action_pressed("crouch") and input_enabled

	if wants_crouch and not is_crouching:
		_start_crouch()
	elif not wants_crouch and is_crouching:
		_try_stand_up()

	# Smooth height transition
	_update_collision_height(delta)


func _start_crouch() -> void:
	is_crouching = true
	is_sprinting = false
	_target_height = crouch_height
	crouched.emit(true)


func _try_stand_up() -> void:
	# Check if there's room to stand
	if _can_stand_up():
		is_crouching = false
		_target_height = standing_height
		crouched.emit(false)


func _can_stand_up() -> bool:
	if not _collision_shape:
		return true

	# Raycast upward to check for obstacles
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		global_position,
		global_position + Vector3.UP * (standing_height - crouch_height + 0.1),
		collision_mask,
		[get_rid()]
	)
	var result := space_state.intersect_ray(query)
	return result.is_empty()


func _update_collision_height(delta: float) -> void:
	if not _collision_shape or not _collision_shape.shape is CapsuleShape3D:
		return

	var capsule: CapsuleShape3D = _collision_shape.shape
	var current_height: float = capsule.height
	var new_height := move_toward(current_height, _target_height, crouch_transition_speed * delta)

	if absf(new_height - current_height) > 0.001:
		capsule.height = new_height
		# Adjust collision shape position to keep feet on ground
		_collision_shape.position.y = new_height / 2.0

		# Adjust head position
		if _head:
			var head_offset := new_height - standing_height
			_head.position.y = _original_head_y + head_offset


func _update_head_bob(delta: float) -> void:
	if not head_bob_enabled or not _head or not is_on_floor():
		return

	if _is_moving():
		var bob_speed := head_bob_frequency
		var bob_amount := head_bob_amplitude

		if is_sprinting:
			bob_speed *= head_bob_sprint_multiplier
			bob_amount *= head_bob_sprint_multiplier
		elif is_crouching:
			bob_speed *= 0.7
			bob_amount *= 0.5

		head_bob_time += delta * bob_speed * TAU
		var bob_offset := sin(head_bob_time) * bob_amount

		# Apply bob relative to current head height (accounting for crouch)
		var base_y := _original_head_y
		if is_crouching:
			base_y += (crouch_height - standing_height)
		_head.position.y = base_y + bob_offset
	else:
		# Reset head bob smoothly when stopped
		head_bob_time = 0.0
		var target_y := _original_head_y
		if is_crouching:
			target_y += (crouch_height - standing_height)
		_head.position.y = move_toward(_head.position.y, target_y, delta * 5.0)


func _update_footsteps(delta: float) -> void:
	if not is_on_floor() or not _is_moving():
		footstep_timer = 0.0
		return

	var interval := footstep_interval
	if is_sprinting:
		interval = sprint_footstep_interval
	elif is_crouching:
		interval = crouch_footstep_interval

	footstep_timer += delta
	if footstep_timer >= interval:
		footstep_timer = 0.0
		_play_footstep()


func _play_footstep() -> void:
	footstep.emit()
	if _footstep_player and _footstep_player.stream:
		_footstep_player.play()


func _is_moving() -> bool:
	var horizontal_velocity := Vector2(velocity.x, velocity.z)
	return horizontal_velocity.length() > 0.5


# --- Public API ---


## Gets the current horizontal speed.
func get_horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


## Gets normalized stamina (0.0 to 1.0).
func get_stamina_percent() -> float:
	return current_stamina / max_stamina if max_stamina > 0 else 0.0


## Sets whether this is the local player (controls input handling).
func set_local_player(is_local: bool) -> void:
	is_local_player = is_local
	if is_local and input_enabled:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Hide name label for local player (can't see own head)
	if _name_label:
		_name_label.visible = not is_local


## Sets the network peer ID for this player.
func set_player_id(id: int) -> void:
	player_id = id
	# Update name label with player ID for discovery tracking
	if _name_label and _name_label.has_method("set_player_id"):
		_name_label.set_player_id(id)


## Sets the display name for this player.
func set_player_name(display_name: String) -> void:
	player_name = display_name
	# Update name label
	if _name_label and _name_label.has_method("set_player_name"):
		_name_label.set_player_name(display_name)


## Gets the network peer ID for this player.
func get_player_id() -> int:
	return player_id


## Gets the display name for this player.
func get_player_name() -> String:
	return player_name


## Enables or disables player input.
func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	if not enabled:
		is_sprinting = false


## Gets player state for network synchronization.
func get_network_state() -> Dictionary:
	return {
		"position": position,
		"rotation": rotation,
		"velocity": velocity,
		"is_crouching": is_crouching,
		"stamina": current_stamina,
		"is_alive": is_alive,
		"is_echo": is_echo,
		"times_revived": times_revived,
	}


## Applies network state from remote player.
func apply_network_state(state: Dictionary) -> void:
	if state.has("position"):
		position = state.position
	if state.has("rotation"):
		rotation = state.rotation
	if state.has("velocity"):
		velocity = state.velocity
	if state.has("is_crouching"):
		if state.is_crouching != is_crouching:
			is_crouching = state.is_crouching
			_target_height = crouch_height if is_crouching else standing_height
	if state.has("is_alive"):
		is_alive = state.is_alive
	if state.has("is_echo"):
		is_echo = state.is_echo
	if state.has("times_revived"):
		times_revived = state.times_revived


## Teleports the player to a position.
func teleport(new_position: Vector3, new_rotation: Vector3 = Vector3.ZERO) -> void:
	global_position = new_position
	rotation = new_rotation
	velocity = Vector3.ZERO


## Resets player state for a new round.
func reset_state() -> void:
	current_stamina = max_stamina
	is_sprinting = false
	is_crouching = false
	is_alive = true
	is_echo = false
	death_position = Vector3.ZERO
	times_revived = 0
	_target_height = standing_height
	velocity = Vector3.ZERO
	head_bob_time = 0.0
	footstep_timer = 0.0
	stamina_regen_timer = 0.0
	stamina_changed.emit(current_stamina, max_stamina)


# --- Death Handling ---


## Called by the entity when this player is killed during a hunt.
## entity: The entity that killed the player.
## position: The position where the player died.
func on_killed_by_entity(entity: Node, kill_position: Vector3) -> void:
	if not is_alive:
		return  # Already dead

	is_alive = false
	is_echo = true
	death_position = kill_position
	velocity = Vector3.ZERO

	# Stop all movement input
	is_sprinting = false
	is_crouching = false

	var entity_name: String = entity.name if entity else "unknown"
	print("[PlayerController] Killed by %s at %v" % [entity_name, kill_position])

	# Emit died signal for other systems to react
	died.emit(death_position)

	# Transition to Echo state
	_transition_to_echo()


## Transitions the player to Echo state after death.
## The body remains at death location; camera control transfers to Echo.
func _transition_to_echo() -> void:
	print("[PlayerController] Transitioning to Echo state")

	# Disable physics processing on the body (remains static at death location)
	# The body could be used for ragdoll later
	set_physics_process(false)

	# Disable input on this controller (Echo will handle input)
	input_enabled = false

	# Make the body visible but player can no longer control it
	# (It stays as a marker of where death occurred)

	# Spawn Echo controller at death position
	var echo := _spawn_echo_controller()
	if echo and is_local_player:
		# Transfer camera control to Echo
		_transfer_camera_to_echo(echo)


## Spawns an EchoController at the death position.
## Returns the spawned Echo or null if spawn failed.
func _spawn_echo_controller() -> EchoController:
	var echo_script: GDScript = load("res://src/player/echo_controller.gd")
	if not echo_script:
		push_error("[PlayerController] Failed to load EchoController script")
		return null

	# Create instance using script's new() method for correct typing
	var echo: EchoController = echo_script.new()
	echo.name = "Echo_%s" % name
	echo.player_id = get_instance_id()
	echo.death_position = death_position
	echo.is_local = is_local_player

	# Copy position and rotation from death location
	echo.global_position = death_position
	echo.rotation = rotation

	# Create a head node for the Echo
	var echo_head := Node3D.new()
	echo_head.name = "Head"
	echo.add_child(echo_head)

	# Copy head rotation
	if _head:
		echo_head.rotation = _head.rotation

	# Create camera for Echo (if local player)
	if is_local_player:
		var echo_camera := Camera3D.new()
		echo_camera.name = "Camera3D"
		echo_camera.current = false  # Will be set current after transfer
		echo_head.add_child(echo_camera)

	# Create a simple translucent mesh for the Echo
	var echo_mesh := MeshInstance3D.new()
	echo_mesh.name = "MeshInstance3D"
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.5
	echo_mesh.mesh = capsule
	echo.add_child(echo_mesh)

	# Add disabled collision shape (Echoes pass through walls)
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.radius = 0.3
	capsule_shape.height = 1.5
	collision.shape = capsule_shape
	collision.disabled = true
	echo.add_child(collision)

	# Add Echo to scene
	get_parent().add_child(echo)

	# Setup translucent appearance after nodes are ready
	echo.setup_translucent_appearance()

	# Add to echoes group for easy lookup
	echo.add_to_group("echoes")

	print("[PlayerController] Spawned Echo: %s" % echo.name)
	return echo


## Transfers camera control from this player to the Echo.
func _transfer_camera_to_echo(echo: EchoController) -> void:
	if not is_local_player:
		return

	# Disable our camera
	if _camera:
		_camera.current = false

	# Enable Echo's camera
	var echo_head := echo.get_node_or_null("Head")
	if echo_head:
		var echo_camera := echo_head.get_node_or_null("Camera3D") as Camera3D
		if echo_camera:
			echo_camera.current = true
			print("[PlayerController] Camera transferred to Echo")


## Gets the Echo controller if this player is dead and has one.
func get_echo() -> EchoController:
	if not is_echo:
		return null

	var echo_name := "Echo_%s" % name
	var parent := get_parent()
	if parent:
		return parent.get_node_or_null(echo_name) as EchoController
	return null


# --- Revival System (FW-043d) ---


## Returns whether this player can be revived.
## Cannot be revived if already revived once this investigation.
func can_be_revived() -> bool:
	if not is_echo:
		return false  # Not dead
	return times_revived < 1


## Called when this player is revived from Echo state.
## Applies revival penalties and restores control.
## _max_sanity: The maximum sanity value (placeholder for sanity system).
func on_revived(_max_sanity: float) -> void:
	if not is_echo:
		return  # Not dead, nothing to revive

	print("[PlayerController] Being revived from Echo state")

	# Increment revival counter
	times_revived += 1

	# Apply revival penalties
	current_stamina = max_stamina * REVIVAL_SANITY_PERCENT

	# Restore alive state
	is_alive = true
	is_echo = false

	# Re-enable physics and input
	set_physics_process(true)
	input_enabled = true

	# Teleport body back to death position (where revival occurred)
	global_position = death_position
	velocity = Vector3.ZERO

	# Clean up Echo
	var echo := get_echo()
	if echo:
		_transfer_camera_from_echo(echo)
		echo.queue_free()

	# Emit revived signal
	revived.emit()
	stamina_changed.emit(current_stamina, max_stamina)

	print("[PlayerController] Revival complete. Times revived: %d" % times_revived)


## Transfers camera control from Echo back to this player.
func _transfer_camera_from_echo(echo: EchoController) -> void:
	if not is_local_player:
		return

	# Disable Echo's camera
	var echo_head := echo.get_node_or_null("Head")
	if echo_head:
		var echo_camera := echo_head.get_node_or_null("Camera3D") as Camera3D
		if echo_camera:
			echo_camera.current = false

	# Re-enable our camera
	if _camera:
		_camera.current = true
		print("[PlayerController] Camera transferred back from Echo")
