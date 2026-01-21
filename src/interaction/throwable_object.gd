class_name ThrowableObject
extends Interactable
## An object that can be thrown by entities as part of physical interaction.
##
## ThrowableObjects react to entity activity by being flung across the room.
## Different entities have different throw patterns:
## - Poltergeist: Multiple violent throws, rapid succession
## - Spirit: Gentle single throws, longer intervals
## - Other entities: Occasional random throws
##
## The throw is visible AND audible to all nearby players, making it
## readily-apparent evidence that cannot be faked.

# --- Signals ---

## Emitted when the object is thrown by an entity.
signal thrown(direction: Vector3, force: float, entity_type: String)

## Emitted when the object lands after being thrown.
signal landed(position: Vector3)

## Emitted when the object is at rest after landing.
signal settled

# --- Enums ---

## Throw pattern styles used by different entities.
enum ThrowPattern {
	GENTLE,  ## Slow, deliberate throw (Spirit-like)
	VIOLENT,  ## Fast, aggressive throw (Poltergeist-like)
	ERRATIC,  ## Unpredictable direction/force
}

## Current state of the throwable object.
enum ThrowState {
	RESTING,  ## Object at rest, can be thrown
	FLYING,  ## Object in mid-air
	LANDING,  ## Object just hit something
	COOLDOWN,  ## Object recently thrown, cannot be thrown again yet
}

# --- Constants ---

## Minimum throw force (m/s).
const MIN_THROW_FORCE := 3.0

## Maximum throw force (m/s).
const MAX_THROW_FORCE := 12.0

## Gravity applied during flight.
const THROW_GRAVITY := 9.8

## Time to settle after landing before next throw possible.
const SETTLE_TIME := 2.0

## Maximum audible range for throw sounds.
const AUDIBLE_RANGE := 20.0

## Maximum visible range for throw effects.
const VISIBLE_RANGE := 30.0

# --- Export: Throwable Settings ---

@export_group("Throwable")
## Mass affects how far the object can be thrown.
@export var object_mass: float = 1.0

## Multiplier for throw force based on object type.
@export var throw_force_multiplier: float = 1.0

## Sound played when object is thrown.
@export var throw_sound: AudioStream

## Sound played when object lands.
@export var land_sound: AudioStream

## Whether this object can be thrown multiple times in succession.
@export var allow_rapid_throw: bool = true

## Minimum cooldown between throws (seconds).
@export var throw_cooldown: float = 1.0

@export_group("Physics")
## Enable physics simulation during flight.
@export var use_physics: bool = true

## Bounciness when hitting surfaces (0 = no bounce, 1 = full bounce).
@export var bounciness: float = 0.3

## Friction coefficient when sliding.
@export var friction: float = 0.8

# --- State ---

var _throw_state: ThrowState = ThrowState.RESTING
var _velocity: Vector3 = Vector3.ZERO
var _throw_cooldown_timer: float = 0.0
var _settle_timer: float = 0.0
var _last_throw_entity: String = ""
var _original_position: Vector3 = Vector3.ZERO
var _original_rotation: Vector3 = Vector3.ZERO


func _ready() -> void:
	super._ready()
	add_to_group("throwable_objects")
	interaction_type = InteractionType.EXAMINE
	interaction_prompt = "Examine"
	_original_position = global_position
	_original_rotation = rotation


func _physics_process(delta: float) -> void:
	match _throw_state:
		ThrowState.FLYING:
			_process_flight(delta)
		ThrowState.LANDING:
			_process_landing(delta)
		ThrowState.COOLDOWN:
			_process_cooldown(delta)


# --- Entity Throw Interface ---


## Called by an entity to throw this object.
## Returns true if the throw was initiated successfully.
func entity_throw(
	direction: Vector3,
	force: float,
	entity_type: String,
	pattern: ThrowPattern = ThrowPattern.VIOLENT
) -> bool:
	if _throw_state != ThrowState.RESTING:
		return false

	# Apply pattern modifiers
	var adjusted_force := _apply_pattern_modifiers(force, pattern)
	var adjusted_direction := _apply_pattern_direction(direction, pattern)

	# Clamp force to valid range
	adjusted_force = clampf(
		adjusted_force * throw_force_multiplier / object_mass,
		MIN_THROW_FORCE,
		MAX_THROW_FORCE
	)

	# Start the throw
	_velocity = adjusted_direction.normalized() * adjusted_force
	_throw_state = ThrowState.FLYING
	_last_throw_entity = entity_type

	# Emit signal for evidence system
	thrown.emit(adjusted_direction, adjusted_force, entity_type)

	# Notify EventBus for network sync and evidence
	_emit_throw_event(adjusted_direction, adjusted_force, entity_type)

	# Play throw sound
	_play_throw_sound()

	return true


## Returns true if this object can currently be thrown.
func can_be_thrown() -> bool:
	return _throw_state == ThrowState.RESTING


## Returns the current throw state.
func get_throw_state() -> ThrowState:
	return _throw_state


## Returns the entity type that last threw this object.
func get_last_throw_entity() -> String:
	return _last_throw_entity


## Resets the object to its original position (for testing/reset).
func reset_position() -> void:
	global_position = _original_position
	rotation = _original_rotation
	_velocity = Vector3.ZERO
	_throw_state = ThrowState.RESTING
	_throw_cooldown_timer = 0.0


# --- Internal: Flight Physics ---


func _process_flight(delta: float) -> void:
	# Apply gravity
	_velocity.y -= THROW_GRAVITY * delta

	# Move the object
	var collision := _move_and_collide(delta)

	if collision:
		_handle_collision(collision)


func _move_and_collide(delta: float) -> Dictionary:
	var space_state := get_world_3d().direct_space_state
	if space_state == null:
		# No physics space - just move directly
		global_position += _velocity * delta
		return {}

	var from := global_position
	var to := from + _velocity * delta

	# Perform sphere cast for collision detection
	var shape := SphereShape3D.new()
	shape.radius = 0.1  # Small collision radius

	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = Transform3D(Basis.IDENTITY, from)
	params.motion = _velocity * delta
	params.collision_mask = 1  # World layer

	var result := space_state.cast_motion(params)
	if result[0] < 1.0:
		# Collision detected
		var collision_point := from + (_velocity * delta) * result[0]
		global_position = collision_point

		# Get collision normal
		params.transform = Transform3D(Basis.IDENTITY, collision_point)
		var rest := space_state.get_rest_info(params)
		return rest
	else:
		# No collision
		global_position = to
		return {}


func _handle_collision(collision: Dictionary) -> void:
	_throw_state = ThrowState.LANDING
	_settle_timer = 0.0

	# Apply bounce if configured
	if collision.has("normal"):
		var normal: Vector3 = collision.normal
		_velocity = _velocity.bounce(normal) * bounciness

		# If velocity is very low, stop immediately
		if _velocity.length() < 0.5:
			_velocity = Vector3.ZERO

	# Play land sound
	_play_land_sound()

	# Emit landed signal
	landed.emit(global_position)

	# Notify EventBus for evidence
	_emit_land_event()


func _process_landing(delta: float) -> void:
	_settle_timer += delta

	# Continue with reduced velocity (friction)
	if _velocity.length() > 0.1:
		_velocity *= (1.0 - friction * delta)
		global_position += _velocity * delta

		# Apply gravity if still airborne
		var ray_result := _check_ground()
		if ray_result.is_empty():
			_velocity.y -= THROW_GRAVITY * delta
		else:
			# On ground - apply friction more strongly
			_velocity.y = 0
			global_position.y = ray_result.position.y + 0.1

	# Check if settled
	if _settle_timer >= SETTLE_TIME or _velocity.length() < 0.1:
		_throw_state = ThrowState.COOLDOWN
		_throw_cooldown_timer = throw_cooldown
		_velocity = Vector3.ZERO
		settled.emit()


func _process_cooldown(delta: float) -> void:
	_throw_cooldown_timer -= delta
	if _throw_cooldown_timer <= 0.0:
		_throw_cooldown_timer = 0.0
		_throw_state = ThrowState.RESTING


func _check_ground() -> Dictionary:
	var space_state := get_world_3d().direct_space_state
	if space_state == null:
		return {}

	var from := global_position
	var to := from + Vector3.DOWN * 0.2

	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	return space_state.intersect_ray(query)


# --- Internal: Pattern Modifiers ---


func _apply_pattern_modifiers(force: float, pattern: ThrowPattern) -> float:
	match pattern:
		ThrowPattern.GENTLE:
			return force * 0.5
		ThrowPattern.VIOLENT:
			return force * 1.5
		ThrowPattern.ERRATIC:
			return force * randf_range(0.7, 1.3)
		_:
			return force


func _apply_pattern_direction(direction: Vector3, pattern: ThrowPattern) -> Vector3:
	match pattern:
		ThrowPattern.GENTLE:
			# More horizontal, gentle arc
			return Vector3(direction.x, direction.y * 0.5 + 0.3, direction.z).normalized()
		ThrowPattern.VIOLENT:
			# Straight and fast
			return direction.normalized()
		ThrowPattern.ERRATIC:
			# Add random deviation
			var deviation := Vector3(
				randf_range(-0.3, 0.3),
				randf_range(-0.2, 0.2),
				randf_range(-0.3, 0.3)
			)
			return (direction + deviation).normalized()
		_:
			return direction.normalized()


# --- Internal: Events ---


func _emit_throw_event(direction: Vector3, force: float, entity_type: String) -> void:
	var event_bus := _get_event_bus()
	if event_bus and event_bus.has_signal("object_thrown"):
		event_bus.object_thrown.emit(
			get_path(),
			direction,
			force,
			entity_type,
			global_position
		)


func _emit_land_event() -> void:
	var event_bus := _get_event_bus()
	if event_bus and event_bus.has_signal("object_landed"):
		event_bus.object_landed.emit(get_path(), global_position)


# --- Internal: Audio ---


func _play_throw_sound() -> void:
	if throw_sound == null:
		return

	# Create AudioStreamPlayer3D for spatial audio
	var player := AudioStreamPlayer3D.new()
	player.stream = throw_sound
	player.max_distance = AUDIBLE_RANGE
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


func _play_land_sound() -> void:
	if land_sound == null:
		return

	var player := AudioStreamPlayer3D.new()
	player.stream = land_sound
	player.max_distance = AUDIBLE_RANGE
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


# --- Network State ---


func get_network_state() -> Dictionary:
	var state := super.get_network_state()
	state["throw_state"] = _throw_state
	state["velocity_x"] = _velocity.x
	state["velocity_y"] = _velocity.y
	state["velocity_z"] = _velocity.z
	state["last_throw_entity"] = _last_throw_entity
	return state


func apply_network_state(state: Dictionary) -> void:
	super.apply_network_state(state)
	if state.has("throw_state"):
		_throw_state = state.throw_state as ThrowState
	if state.has("velocity_x"):
		_velocity = Vector3(
			state.get("velocity_x", 0.0),
			state.get("velocity_y", 0.0),
			state.get("velocity_z", 0.0)
		)
	if state.has("last_throw_entity"):
		_last_throw_entity = state.last_throw_entity
