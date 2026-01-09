class_name Entity
extends CharacterBody3D
## Base class for all paranormal entities in the game.
##
## Provides:
## - State machine (Dormant, Active, Hunting, Manifesting)
## - Movement and pathfinding via NavigationAgent3D
## - Behavioral tell framework (override in subclasses)
## - Sanity-based hunt threshold
## - Server-authoritative behavior with client interpolation
##
## Subclasses must implement:
## - get_entity_type() -> String
## - get_behavioral_tell_type() -> String
## - _check_behavioral_tell() -> bool (optional logic for tell activation)

# --- Signals ---

## Emitted when entity state changes.
signal state_changed(old_state: EntityState, new_state: EntityState)

## Emitted when the entity performs its behavioral tell.
signal behavioral_tell_triggered(tell_type: String)

## Emitted when entity visibility changes during manifestation.
signal entity_visibility_changed(is_visible: bool)

# --- Enums ---

## Entity behavior states
enum EntityState {
	DORMANT,      ## Passive state - may cause environmental effects
	ACTIVE,       ## Moving around - occasional interactions
	HUNTING,      ## Actively chasing players
	MANIFESTING,  ## Visible manifestation (can be observed/photographed)
}

# --- Export: Entity Settings ---

@export_group("Identity")
## Unique entity type identifier (e.g., "Phantom", "Banshee")
@export var entity_type: String = "Unknown"

@export_group("Movement")
## Base movement speed (m/s) when not hunting
@export var base_speed: float = 1.5
## Movement speed during hunts (m/s)
@export var hunt_speed: float = 2.5
## Speed when aware of player location during hunt
@export var hunt_aware_speed: float = 2.5
## Speed when unaware of player location during hunt
@export var hunt_unaware_speed: float = 1.0

@export_group("Hunt Behavior")
## Default sanity threshold for initiating hunts (0-100)
## Entity can hunt when team sanity <= this value
@export var hunt_sanity_threshold: float = 50.0
## Cooldown modifier (multiplied by base cooldown)
@export var hunt_cooldown_multiplier: float = 1.0
## Duration of hunts in seconds
@export var hunt_duration: float = 30.0

@export_group("Manifestation")
## How long manifestations last (seconds)
@export var manifestation_duration: float = 5.0
## Cooldown between manifestations (seconds)
@export var manifestation_cooldown: float = 20.0

# --- Nodes ---

## Navigation agent for pathfinding
var _nav_agent: NavigationAgent3D = null

# --- State ---

## Current entity state
var _state: EntityState = EntityState.DORMANT

## Reference to EntityManager
var _manager: Node = null

## The room this entity prefers to stay in
var _favorite_room: String = ""

## Current target player (for hunts)
var _hunt_target: Node = null

## Whether entity knows target's position
var _is_aware_of_target: bool = false

## Time remaining in current manifestation
var _manifestation_timer: float = 0.0

## Cooldown until next manifestation
var _manifestation_cooldown_timer: float = 0.0

## Time remaining in current hunt
var _hunt_timer: float = 0.0

## Whether entity is currently visible to players
var _is_visible: bool = false

## Last known position of target (for pathfinding)
var _target_last_position: Vector3 = Vector3.ZERO

## Sync data for network interpolation
var _sync_position: Vector3 = Vector3.ZERO
var _sync_rotation: float = 0.0


func _ready() -> void:
	# Set up collision layer (Layer 3 = Entity)
	collision_layer = 4  # Layer 3 (bit 2)
	collision_mask = 1 | 2  # World (1) + Player (2)

	# Create navigation agent if not present
	_setup_navigation()

	# Initialize state
	_state = EntityState.DORMANT


func _physics_process(delta: float) -> void:
	# State-specific behavior
	match _state:
		EntityState.DORMANT:
			_process_dormant(delta)
		EntityState.ACTIVE:
			_process_active(delta)
		EntityState.HUNTING:
			_process_hunting(delta)
		EntityState.MANIFESTING:
			_process_manifesting(delta)

	# Update manifestation cooldown
	if _manifestation_cooldown_timer > 0:
		_manifestation_cooldown_timer -= delta


# --- Virtual Methods (Override in Subclasses) ---


## Returns the entity type identifier.
func get_entity_type() -> String:
	return entity_type


## Returns the behavioral tell type for this entity.
## Override in subclasses to return specific tell type.
func get_behavioral_tell_type() -> String:
	return "unknown"


## Called to check if behavioral tell should trigger.
## Override in subclasses with entity-specific logic.
## Returns true if tell was triggered.
func _check_behavioral_tell() -> bool:
	return false


## Called when entity enters dormant state.
func _on_enter_dormant() -> void:
	pass


## Called when entity enters active state.
func _on_enter_active() -> void:
	pass


## Called when entity enters hunting state.
func _on_enter_hunting() -> void:
	pass


## Called when entity enters manifesting state.
func _on_enter_manifesting() -> void:
	pass


## Called each frame while dormant.
func _process_dormant_behavior(_delta: float) -> void:
	pass


## Called each frame while active.
func _process_active_behavior(_delta: float) -> void:
	pass


## Called each frame while hunting.
func _process_hunting_behavior(_delta: float) -> void:
	pass


## Called each frame while manifesting.
func _process_manifesting_behavior(_delta: float) -> void:
	pass


## Returns the current movement speed based on state and awareness.
func get_current_speed() -> float:
	match _state:
		EntityState.HUNTING:
			if _is_aware_of_target:
				return hunt_aware_speed
			return hunt_unaware_speed
		EntityState.ACTIVE:
			return base_speed
		_:
			return 0.0


## Called to select a hunt target from available players.
## Override for entity-specific targeting (e.g., Banshee single-target).
func _select_hunt_target(players: Array) -> Node:
	if players.is_empty():
		return null
	# Default: random target
	return players[randi() % players.size()]


# --- Public API ---


## Sets the EntityManager reference.
func set_manager(manager: Node) -> void:
	_manager = manager


## Gets the EntityManager reference.
func get_manager() -> Node:
	return _manager


## Sets the entity's favorite room.
func set_favorite_room(room: String) -> void:
	_favorite_room = room


## Gets the entity's favorite room.
func get_favorite_room() -> String:
	return _favorite_room


## Gets the current entity state.
func get_state() -> EntityState:
	return _state


## Gets the state name as a string.
func get_state_name() -> String:
	match _state:
		EntityState.DORMANT:
			return "Dormant"
		EntityState.ACTIVE:
			return "Active"
		EntityState.HUNTING:
			return "Hunting"
		EntityState.MANIFESTING:
			return "Manifesting"
	return "Unknown"


## Returns true if entity is currently hunting.
func is_hunting() -> bool:
	return _state == EntityState.HUNTING


## Returns true if entity is currently visible.
func is_visible_to_players() -> bool:
	return _is_visible


## Changes the entity state.
func change_state(new_state: EntityState) -> void:
	if new_state == _state:
		return

	var old_state := _state
	_state = new_state

	# Exit old state
	_exit_state(old_state)

	# Enter new state
	_enter_state(new_state)

	state_changed.emit(old_state, new_state)
	print("[Entity:%s] State: %s -> %s" % [entity_type, _state_to_string(old_state),
		_state_to_string(new_state)])


## Called by EntityManager when a hunt starts.
func on_hunt_started() -> void:
	change_state(EntityState.HUNTING)
	_hunt_timer = hunt_duration


## Called by EntityManager when a hunt ends.
func on_hunt_ended() -> void:
	_hunt_target = null
	_is_aware_of_target = false
	change_state(EntityState.ACTIVE)


## Triggers a manifestation if cooldown allows.
## Returns true if manifestation started.
func start_manifestation() -> bool:
	if _state == EntityState.HUNTING:
		return false

	if _manifestation_cooldown_timer > 0:
		return false

	change_state(EntityState.MANIFESTING)
	_manifestation_timer = manifestation_duration
	_set_visible(true)
	return true


## Ends the current manifestation.
func end_manifestation() -> void:
	if _state != EntityState.MANIFESTING:
		return

	_set_visible(false)
	_manifestation_cooldown_timer = manifestation_cooldown
	change_state(EntityState.ACTIVE)


## Sets the current hunt target.
func set_hunt_target(target: Node) -> void:
	_hunt_target = target
	if target and target is Node3D:
		_target_last_position = (target as Node3D).global_position
		_is_aware_of_target = true


## Gets the current hunt target.
func get_hunt_target() -> Node:
	return _hunt_target


## Updates target awareness (for line-of-sight checks).
func set_aware_of_target(aware: bool) -> void:
	_is_aware_of_target = aware


## Triggers the entity's behavioral tell.
## Call this when tell conditions are met.
func trigger_behavioral_tell() -> void:
	var tell_type := get_behavioral_tell_type()
	behavioral_tell_triggered.emit(tell_type)

	if EventBus:
		EventBus.entity_tell_triggered.emit(tell_type)

	print("[Entity:%s] Behavioral tell triggered: %s" % [entity_type, tell_type])


## Gets network state for synchronization.
func get_network_state() -> Dictionary:
	return {
		"state": _state,
		"position": {"x": global_position.x, "y": global_position.y, "z": global_position.z},
		"rotation_y": rotation.y,
		"is_visible": _is_visible,
		"hunt_timer": _hunt_timer,
		"manifestation_timer": _manifestation_timer,
	}


## Applies network state from server.
func apply_network_state(state: Dictionary) -> void:
	if state.has("state"):
		var new_state: EntityState = state.state as EntityState
		if new_state != _state:
			change_state(new_state)

	if state.has("position"):
		var pos: Dictionary = state.position
		_sync_position = Vector3(pos.x, pos.y, pos.z)
		global_position = _sync_position

	if state.has("rotation_y"):
		_sync_rotation = state.rotation_y
		rotation.y = _sync_rotation

	if state.has("is_visible"):
		_set_visible(state.is_visible)

	if state.has("hunt_timer"):
		_hunt_timer = state.hunt_timer

	if state.has("manifestation_timer"):
		_manifestation_timer = state.manifestation_timer


# --- Navigation ---


## Sets the navigation target position.
func navigate_to(target_position: Vector3) -> void:
	if _nav_agent:
		_nav_agent.target_position = target_position


## Returns true if navigation has reached the target.
func is_navigation_finished() -> bool:
	if _nav_agent:
		return _nav_agent.is_navigation_finished()
	return true


## Gets the next path position for movement.
func get_next_path_position() -> Vector3:
	if _nav_agent:
		return _nav_agent.get_next_path_position()
	return global_position


# --- Internal Methods ---


func _setup_navigation() -> void:
	# Check for existing NavigationAgent3D
	for child in get_children():
		if child is NavigationAgent3D:
			_nav_agent = child
			return

	# Create one if not present
	_nav_agent = NavigationAgent3D.new()
	_nav_agent.name = "NavigationAgent3D"
	_nav_agent.path_desired_distance = 0.5
	_nav_agent.target_desired_distance = 0.5
	_nav_agent.avoidance_enabled = true
	_nav_agent.radius = 0.4
	add_child(_nav_agent)


func _enter_state(new_state: EntityState) -> void:
	match new_state:
		EntityState.DORMANT:
			_on_enter_dormant()
		EntityState.ACTIVE:
			_on_enter_active()
		EntityState.HUNTING:
			_on_enter_hunting()
		EntityState.MANIFESTING:
			_on_enter_manifesting()


func _exit_state(_old_state: EntityState) -> void:
	# Cleanup when leaving states if needed
	pass


func _process_dormant(delta: float) -> void:
	# Dormant entities don't move but may cause effects
	_process_dormant_behavior(delta)


func _process_active(delta: float) -> void:
	# Move around the map
	_process_active_behavior(delta)
	_move_along_path(delta)


func _process_hunting(delta: float) -> void:
	_hunt_timer -= delta

	if _hunt_timer <= 0:
		# Hunt ended - EntityManager will call on_hunt_ended()
		if _manager and _manager.has_method("end_hunt"):
			_manager.end_hunt()
		return

	# Update target position if we have one
	if _hunt_target and is_instance_valid(_hunt_target) and _hunt_target is Node3D:
		_target_last_position = (_hunt_target as Node3D).global_position
		navigate_to(_target_last_position)

	_process_hunting_behavior(delta)
	_move_along_path(delta)

	# Check for behavioral tell during hunt
	if _check_behavioral_tell():
		trigger_behavioral_tell()


func _process_manifesting(delta: float) -> void:
	_manifestation_timer -= delta

	if _manifestation_timer <= 0:
		end_manifestation()
		return

	_process_manifesting_behavior(delta)

	# Check for behavioral tell during manifestation
	if _check_behavioral_tell():
		trigger_behavioral_tell()


func _move_along_path(_delta: float) -> void:
	if not _nav_agent:
		return

	if _nav_agent.is_navigation_finished():
		return

	var next_pos := _nav_agent.get_next_path_position()
	var direction := (next_pos - global_position).normalized()
	var speed := get_current_speed()

	velocity = direction * speed
	move_and_slide()

	# Face movement direction
	if velocity.length_squared() > 0.01:
		var look_dir := Vector3(velocity.x, 0, velocity.z).normalized()
		if look_dir.length_squared() > 0.01:
			rotation.y = atan2(look_dir.x, look_dir.z)


func _set_visible(visible: bool) -> void:
	if _is_visible == visible:
		return

	_is_visible = visible
	entity_visibility_changed.emit(visible)

	# Update actual visibility - subclasses can override for custom visuals
	for child in get_children():
		if child is MeshInstance3D or child is GPUParticles3D:
			child.visible = visible


func _state_to_string(state: EntityState) -> String:
	match state:
		EntityState.DORMANT:
			return "Dormant"
		EntityState.ACTIVE:
			return "Active"
		EntityState.HUNTING:
			return "Hunting"
		EntityState.MANIFESTING:
			return "Manifesting"
	return "Unknown"
