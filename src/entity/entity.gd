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

## Emitted when the entity kills a player.
signal player_killed(player: Node)

## Emitted when the entity reacts to an Echo's presence (cosmetic only).
signal echo_reaction_triggered(echo: Node)

# --- Enums ---

## Entity behavior states
enum EntityState {
	DORMANT,  ## Passive state - may cause environmental effects
	ACTIVE,  ## Moving around - occasional interactions
	HUNTING,  ## Actively chasing players
	MANIFESTING,  ## Visible manifestation (can be observed/photographed)
}

# --- Constants ---

## Kill range - distance at which entity kills player during hunt
const KILL_RANGE := 1.0

# --- Echo Reaction Constants (FW-043c) ---

## Interval between Echo reaction checks (seconds).
const ECHO_REACTION_INTERVAL := 30.0

## Probability of reacting to an Echo on each check (0.0 - 1.0).
const ECHO_REACTION_CHANCE := 0.2

## Duration of the reaction animation (seconds).
const ECHO_REACTION_DURATION := 2.0

## Maximum distance to detect Echoes for reactions.
const ECHO_REACTION_RANGE := 15.0

## Speed of head turn during reaction (radians per second).
const ECHO_REACTION_TURN_SPEED := 2.0

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

## Hiding spot currently being searched (null if none).
var _searching_hiding_spot: Node = null

## Sync data for network interpolation
var _sync_position: Vector3 = Vector3.ZERO
var _sync_rotation: float = 0.0

# --- Echo Reaction State (FW-043c) ---

## Timer until next Echo reaction check.
var _echo_reaction_cooldown: float = 0.0

## Whether entity is currently performing an Echo reaction.
var _is_reacting_to_echo: bool = false

## Duration of the current reaction.
var _echo_reaction_timer: float = 0.0

## Target Echo for the current reaction.
var _reaction_target_echo: Node = null

## Original rotation before reaction (to return to).
var _pre_reaction_rotation: float = 0.0


func _ready() -> void:
	# Set up collision layer (Layer 3 = Entity)
	collision_layer = 4  # Layer 3 (bit 2)
	collision_mask = 1 | 2  # World (1) + Player (2)

	# Create navigation agent if not present
	_setup_navigation()

	# Initialize state
	_state = EntityState.DORMANT


func _physics_process(delta: float) -> void:
	# Process Echo reactions (cosmetic - can happen in any state except hunting)
	if _state != EntityState.HUNTING:
		_process_echo_reactions(delta)

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
			return get_hunt_speed_for_awareness(_is_aware_of_target)
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


## Returns true if this entity can ignore hiding spots and detect players inside.
## Override in subclasses for entity-specific behavior (e.g., Wraith ignores hiding).
func can_ignore_hiding_spots() -> bool:
	return false


# --- Hunt Variation Virtual Methods ---
# Override these in subclasses to customize entity-specific hunt behavior.


## Returns the sanity threshold at which this entity can initiate hunts.
## Override for entity-specific thresholds (e.g., Demon: 70%, Shade: 35%).
func get_hunt_sanity_threshold() -> float:
	return hunt_sanity_threshold


## Returns true if this entity ignores team sanity and only checks target's sanity.
## Override in subclasses (e.g., Banshee targets one player, ignores team sanity).
func should_ignore_team_sanity() -> bool:
	return false


## Returns true if voice input can trigger a hunt regardless of sanity threshold.
## Override in subclasses (e.g., Listener can be voice-triggered).
func can_voice_trigger_hunt() -> bool:
	return false


## Returns the hunt speed based on whether the entity is aware of target position.
## Override for entity-specific speed behaviors.
func get_hunt_speed_for_awareness(aware: bool) -> float:
	return hunt_aware_speed if aware else hunt_unaware_speed


## Called each frame during hunt to update speed (e.g., Revenant acceleration).
## Override in subclasses that have dynamic speed changes during hunts.
func _update_hunt_speed(_delta: float) -> void:
	pass


## Returns true if this entity can hunt under current environmental conditions.
## Override for condition-specific entities (e.g., Mare can't hunt in lit rooms).
func can_hunt_in_current_conditions() -> bool:
	return true


## Returns the hunt duration for this entity (in seconds).
## Override for entity-specific durations.
func get_hunt_duration() -> float:
	return hunt_duration


## Returns the hunt cooldown for this entity (in seconds).
## Base cooldown is 25 seconds, modified by hunt_cooldown_multiplier.
## Override for entity-specific cooldowns (e.g., Demon: 20s).
func get_hunt_cooldown() -> float:
	return 25.0 * hunt_cooldown_multiplier


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


## Returns true if this entity is visible to the given observer.
## Echoes can see entities at all times, living players only when manifesting.
func is_visible_to(observer: Node) -> bool:
	# Check if observer ignores entity visibility (e.g., Echoes)
	if observer.has_method("ignores_entity_visibility"):
		if observer.ignores_entity_visibility():
			return true

	# Check for EchoController (always sees entity)
	if observer is EchoController:
		return true

	# Check for is_echo property on PlayerController
	if observer.get("is_echo") == true:
		return true

	# Default: visible only when manifesting or hunting (visible state)
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
	print(
		(
			"[Entity:%s] State: %s -> %s"
			% [entity_type, _state_to_string(old_state), _state_to_string(new_state)]
		)
	)


## Called by EntityManager when a hunt starts.
func on_hunt_started() -> void:
	change_state(EntityState.HUNTING)
	_hunt_timer = get_hunt_duration()


## Called by EntityManager when a hunt ends.
func on_hunt_ended() -> void:
	_cancel_hiding_spot_search()
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
	# Pause movement during Echo reactions
	if _is_reacting_to_echo:
		return

	# Move around the map
	_process_active_behavior(delta)
	_move_along_path(delta)


func _process_hunting(delta: float) -> void:
	_hunt_timer -= delta

	if _hunt_timer <= 0:
		# Hunt ended - EntityManager will call on_hunt_ended()
		_cancel_hiding_spot_search()
		if _manager and _manager.has_method("end_hunt"):
			_manager.end_hunt()
		return

	# Check if we're searching a hiding spot
	if _searching_hiding_spot and is_instance_valid(_searching_hiding_spot):
		_process_hiding_spot_search(delta)
		return

	# Process detection and target tracking
	_update_hunt_detection()

	# Check for kill range on current target
	if _hunt_target and is_instance_valid(_hunt_target) and _hunt_target is Node3D:
		var distance: float = global_position.distance_to((_hunt_target as Node3D).global_position)
		if distance <= KILL_RANGE:
			_kill_player(_hunt_target)
			return

	# Navigate to target or last known position
	if _is_aware_of_target and _hunt_target and is_instance_valid(_hunt_target):
		if _hunt_target is Node3D:
			_target_last_position = (_hunt_target as Node3D).global_position
		navigate_to(_target_last_position)
	elif _target_last_position != Vector3.ZERO:
		# Lost awareness - navigate to last known position
		navigate_to(_target_last_position)

		# Check for nearby hiding spots when we reach last known position
		if is_navigation_finished():
			var hiding_spot := _find_nearby_hiding_spot(_target_last_position)
			if hiding_spot:
				_start_hiding_spot_search(hiding_spot)
			else:
				_target_last_position = Vector3.ZERO

	_process_hunting_behavior(delta)

	# Allow entity-specific speed updates (e.g., Revenant acceleration)
	_update_hunt_speed(delta)

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


## Updates hunt detection - checks for players in range and line of sight.
func _update_hunt_detection() -> void:
	var players := _get_alive_players()
	if players.is_empty():
		return

	var space_state := get_world_3d().direct_space_state

	# If we have a target, check if we still detect them
	if _hunt_target and is_instance_valid(_hunt_target):
		var in_range := HuntDetection.is_player_in_range(global_position, _hunt_target)
		var has_los := false

		if in_range:
			has_los = HuntDetection.has_line_of_sight(self, _hunt_target, space_state)

		if has_los:
			# Maintain awareness
			_is_aware_of_target = true
		elif in_range and _is_aware_of_target:
			# Lost LoS but still in range - record last known position
			if _hunt_target is Node3D:
				_target_last_position = (_hunt_target as Node3D).global_position
			_is_aware_of_target = false
		elif not in_range:
			# Completely lost target - transition to searching
			if _is_aware_of_target and _hunt_target is Node3D:
				_target_last_position = (_hunt_target as Node3D).global_position
			_is_aware_of_target = false
	else:
		# No target - find nearest detectable player
		var detection := HuntDetection.find_nearest_player(self, players, space_state)
		if not detection.is_empty():
			_hunt_target = detection.player
			_is_aware_of_target = detection.has_line_of_sight
			if _hunt_target is Node3D:
				_target_last_position = (_hunt_target as Node3D).global_position


## Gets all alive players for detection checks.
## Override in subclasses for entity-specific targeting (e.g., Banshee).
func _get_alive_players() -> Array:
	# Try to get players from PlayerManager autoload
	if has_node("/root/PlayerManager"):
		var player_manager := get_node("/root/PlayerManager")
		if player_manager.has_method("get_alive_players"):
			var players: Array = player_manager.get_alive_players()
			return _filter_valid_hunt_targets(players)
		if player_manager.has_method("get_all_players"):
			var players: Array = player_manager.get_all_players()
			return _filter_valid_hunt_targets(players)

	# Fallback: find players in scene tree
	var players: Array = []
	var player_group := get_tree().get_nodes_in_group("players")
	for player in player_group:
		# Filter out dead players if they have is_alive property
		if player.get("is_alive") == false:
			continue
		players.append(player)

	return _filter_valid_hunt_targets(players)


## Filters out players that cannot be targeted during hunts (Echoes).
func _filter_valid_hunt_targets(players: Array) -> Array:
	var valid_targets: Array = []
	for player in players:
		if _is_valid_hunt_target(player):
			valid_targets.append(player)
	return valid_targets


## Returns true if the given player is a valid hunt target.
## Echoes and dead players are not valid targets.
func _is_valid_hunt_target(player: Node) -> bool:
	# Check if player is an Echo (EchoController)
	if player is EchoController:
		return false

	# Check if player has is_valid_hunt_target method (for EchoController)
	if player.has_method("is_valid_hunt_target"):
		if not player.is_valid_hunt_target():
			return false

	# Check if player is in Echo state (dead PlayerController)
	if player.get("is_echo") == true:
		return false

	# Check if player is dead
	if player.get("is_alive") == false:
		return false

	return true


## Gets the detection radius for the current target.
func get_target_detection_radius() -> float:
	if _hunt_target and is_instance_valid(_hunt_target):
		return HuntDetection.get_detection_radius(_hunt_target)
	return HuntDetection.BASE_DETECTION_RADIUS


## Returns true if entity is aware of target's current position.
func is_aware_of_target() -> bool:
	return _is_aware_of_target


## Gets the last known position of the target.
func get_last_known_target_position() -> Vector3:
	return _target_last_position


## Returns the hiding spot currently being searched, or null.
func get_searching_hiding_spot() -> Node:
	return _searching_hiding_spot


## Returns true if entity is currently searching a hiding spot.
func is_searching_hiding_spot() -> bool:
	return _searching_hiding_spot != null and is_instance_valid(_searching_hiding_spot)


# --- Hiding Spot Methods ---


## Finds a hiding spot near the given position.
## Returns the nearest hiding spot within search radius, or null if none.
func _find_nearby_hiding_spot(position: Vector3, search_radius: float = 5.0) -> Node:
	var hiding_spots := get_tree().get_nodes_in_group("hiding_spots")

	var nearest_spot: Node = null
	var nearest_distance := search_radius

	for spot in hiding_spots:
		if not is_instance_valid(spot) or not spot is Node3D:
			continue

		# Skip spots we can ignore (entity-specific)
		if can_ignore_hiding_spots():
			continue

		var distance: float = (spot as Node3D).global_position.distance_to(position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_spot = spot

	return nearest_spot


## Starts searching a hiding spot for hidden players.
func _start_hiding_spot_search(spot: Node) -> void:
	if not is_instance_valid(spot):
		return

	_searching_hiding_spot = spot

	# Tell the hiding spot we're searching it
	if spot.has_method("start_entity_search"):
		spot.start_entity_search(self)

	# Navigate to the hiding spot entrance
	if spot is Node3D:
		navigate_to((spot as Node3D).global_position)


## Processes hiding spot search each frame.
func _process_hiding_spot_search(_delta: float) -> void:
	if not _searching_hiding_spot or not is_instance_valid(_searching_hiding_spot):
		_searching_hiding_spot = null
		return

	var spot := _searching_hiding_spot

	# Check if search is complete
	if spot.has_method("is_being_searched") and not spot.is_being_searched():
		# Search ended (timer expired)
		_end_hiding_spot_search(false)
		return

	# Check if we can now detect players inside (door opened)
	if spot.has_method("can_entity_detect_inside") and spot.can_entity_detect_inside():
		# Door opened! Check for players inside
		if spot.has_method("has_occupants") and spot.has_occupants():
			# Found them! Resume normal detection
			_end_hiding_spot_search(true)
			return

	# Stay at hiding spot entrance during search
	if spot is Node3D:
		var spot_pos: Vector3 = (spot as Node3D).global_position
		var dist := global_position.distance_to(spot_pos)

		# Move towards spot if not close enough
		if dist > 1.5:
			navigate_to(spot_pos)
			_move_along_path(_delta)


## Ends hiding spot search.
## If found_player is true, will resume detection to find the revealed player.
func _end_hiding_spot_search(found_player: bool) -> void:
	if _searching_hiding_spot and is_instance_valid(_searching_hiding_spot):
		if _searching_hiding_spot.has_method("cancel_search"):
			_searching_hiding_spot.cancel_search()

	_searching_hiding_spot = null

	if found_player:
		# Player was revealed - immediately check detection again
		_update_hunt_detection()
	else:
		# Didn't find anyone - clear last known position and wander
		_target_last_position = Vector3.ZERO


## Cancels any active hiding spot search (called when hunt ends).
func _cancel_hiding_spot_search() -> void:
	if _searching_hiding_spot and is_instance_valid(_searching_hiding_spot):
		if _searching_hiding_spot.has_method("cancel_search"):
			_searching_hiding_spot.cancel_search()
	_searching_hiding_spot = null


# --- Echo Reaction System (FW-043c) ---


## Processes Echo reactions - cosmetic acknowledgment of Echo presence.
## Called every frame when not hunting.
func _process_echo_reactions(delta: float) -> void:
	# If currently reacting, continue the reaction animation
	if _is_reacting_to_echo:
		_process_echo_reaction_animation(delta)
		return

	# Decrement reaction cooldown
	_echo_reaction_cooldown -= delta
	if _echo_reaction_cooldown > 0:
		return

	# Reset cooldown for next check
	_echo_reaction_cooldown = ECHO_REACTION_INTERVAL

	# Roll for reaction
	if randf() >= ECHO_REACTION_CHANCE:
		return

	# Find nearest Echo within range
	var echo := _find_nearest_echo()
	if echo:
		_start_echo_reaction(echo)


## Finds the nearest Echo within reaction range.
func _find_nearest_echo() -> Node:
	var echoes := get_tree().get_nodes_in_group("echoes")
	if echoes.is_empty():
		return null

	var nearest_echo: Node = null
	var nearest_distance := ECHO_REACTION_RANGE

	for echo in echoes:
		if not is_instance_valid(echo) or not echo is Node3D:
			continue

		var distance: float = global_position.distance_to((echo as Node3D).global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_echo = echo

	return nearest_echo


## Starts an Echo reaction.
func _start_echo_reaction(echo: Node) -> void:
	_is_reacting_to_echo = true
	_echo_reaction_timer = ECHO_REACTION_DURATION
	_reaction_target_echo = echo
	_pre_reaction_rotation = rotation.y

	echo_reaction_triggered.emit(echo)

	var echo_name := echo.name if echo else "unknown"
	print("[Entity:%s] Reacting to Echo: %s" % [entity_type, echo_name])


## Processes the Echo reaction animation (head turn and pause).
func _process_echo_reaction_animation(delta: float) -> void:
	_echo_reaction_timer -= delta

	# Reaction over - return to normal
	if _echo_reaction_timer <= 0:
		_end_echo_reaction()
		return

	# Turn toward Echo
	if _reaction_target_echo and is_instance_valid(_reaction_target_echo):
		if _reaction_target_echo is Node3D:
			var echo_pos: Vector3 = (_reaction_target_echo as Node3D).global_position
			var direction := (echo_pos - global_position).normalized()
			var target_rotation := atan2(direction.x, direction.z)

			# Smoothly rotate toward Echo
			rotation.y = lerp_angle(rotation.y, target_rotation, ECHO_REACTION_TURN_SPEED * delta)

	# Entity is paused during reaction (no movement happens in state processing)


## Ends the Echo reaction and returns to normal behavior.
func _end_echo_reaction() -> void:
	_is_reacting_to_echo = false
	_echo_reaction_timer = 0.0
	_reaction_target_echo = null
	# Don't reset rotation - let entity continue in new facing


## Returns true if entity is currently reacting to an Echo.
func is_reacting_to_echo() -> bool:
	return _is_reacting_to_echo


## Gets the Echo the entity is currently reacting to (null if not reacting).
func get_reaction_target_echo() -> Node:
	return _reaction_target_echo


## Manually triggers an Echo reaction for testing or scripted events.
## Returns true if reaction started, false if no Echo in range or already reacting.
func trigger_echo_reaction() -> bool:
	if _is_reacting_to_echo:
		return false

	var echo := _find_nearest_echo()
	if not echo:
		return false

	_start_echo_reaction(echo)
	return true


# --- Death Mechanics ---


## Kills a player when within kill range during a hunt.
## This is called when the entity catches a player.
func _kill_player(player: Node) -> void:
	if not is_instance_valid(player):
		return

	# Verify player is still alive (if they have the property)
	if player.get("is_alive") == false:
		# Already dead, find new target
		_hunt_target = null
		return

	var player_id := _get_player_id(player)
	var death_position := Vector3.ZERO
	if player is Node3D:
		death_position = (player as Node3D).global_position

	print("[Entity:%s] Killed player %d at %v" % [entity_type, player_id, death_position])

	# Emit local signal
	player_killed.emit(player)

	# Notify via EventBus
	if EventBus:
		EventBus.player_died.emit(player_id)

	# Tell player to handle death (if they have the method)
	if player.has_method("on_killed_by_entity"):
		player.on_killed_by_entity(self, death_position)

	# Clear this target and continue hunting other players
	_hunt_target = null
	_is_aware_of_target = false
	_target_last_position = Vector3.ZERO


## Gets the player ID from a player node.
## Checks for peer_id property, get_peer_id method, or falls back to instance ID.
func _get_player_id(player: Node) -> int:
	if player.get("peer_id") != null:
		return player.peer_id as int
	if player.has_method("get_peer_id"):
		return player.get_peer_id()
	return player.get_instance_id()
