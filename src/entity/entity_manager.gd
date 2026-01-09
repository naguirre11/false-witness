extends Node
## Manages entity lifecycle, spawning, and server-authoritative behavior.
## Autoload: EntityManager
##
## Handles:
## - Entity registry and lifecycle
## - Server-authoritative entity updates
## - Hunt initiation and coordination with protection items
## - Aggression escalation over match time
##
## Note: No class_name to avoid conflicts with autoload singleton name.

# --- Signals ---

## Emitted when an entity is spawned into the match.
signal entity_spawned(entity: Node)

## Emitted when an entity is removed from the match.
signal entity_removed(entity: Node)

## Emitted when entity aggression level changes.
signal aggression_changed(level: int, phase_name: String)

# --- Constants ---

## Aggression phases based on match time
enum AggressionPhase {
	DORMANT,     ## 0-5 min: Passive manifestations only
	ACTIVE,      ## 5-10 min: Occasional hunts
	AGGRESSIVE,  ## 10-15 min: Frequent hunts
	FURIOUS,     ## 15+ min: Near-constant hunting
}

## Time thresholds for aggression phases (in seconds)
const AGGRESSION_THRESHOLDS := {
	AggressionPhase.DORMANT: 0.0,
	AggressionPhase.ACTIVE: 300.0,      # 5 minutes
	AggressionPhase.AGGRESSIVE: 600.0,  # 10 minutes
	AggressionPhase.FURIOUS: 900.0,     # 15 minutes
}

## Base hunt cooldowns per aggression phase (in seconds)
const HUNT_COOLDOWNS := {
	AggressionPhase.DORMANT: INF,       # Cannot hunt
	AggressionPhase.ACTIVE: 120.0,      # 2 minutes
	AggressionPhase.AGGRESSIVE: 60.0,   # 1 minute
	AggressionPhase.FURIOUS: 25.0,      # 25 seconds
}

# --- State ---

## Currently active entity (only one per match)
var _active_entity: Node = null

## Match elapsed time tracker
var _match_time: float = 0.0

## Current aggression phase
var _aggression_phase: AggressionPhase = AggressionPhase.DORMANT

## Time since last hunt ended
var _hunt_cooldown_timer: float = 0.0

## Whether a hunt is currently active
var _is_hunting: bool = false

## Whether hunt was prevented this cycle (for cooldown tracking)
var _hunt_was_prevented: bool = false

## Designated entity room (favorite room)
var _favorite_room: String = ""

## Server authority flag
var _is_server: bool = false


func _ready() -> void:
	# Connect to game state changes
	if EventBus:
		EventBus.game_state_changed.connect(_on_game_state_changed)
		EventBus.hunt_prevented.connect(_on_hunt_prevented)
	print("[EntityManager] Initialized")


func _process(delta: float) -> void:
	if not _is_in_match():
		return

	# Only server processes entity logic
	if not _is_server:
		return

	_match_time += delta
	_update_aggression_phase()
	_update_hunt_cooldown(delta)


# --- Public API ---


## Spawns an entity into the match. Server-only.
## entity_scene: PackedScene of the entity to spawn
## spawn_position: Where to spawn the entity
## favorite_room: The room ID the entity will prefer
func spawn_entity(entity_scene: PackedScene, spawn_position: Vector3,
		favorite_room: String = "") -> Node:
	if not _is_server:
		push_warning("[EntityManager] Only server can spawn entities")
		return null

	if _active_entity != null:
		push_warning("[EntityManager] Entity already active, despawn first")
		return null

	var entity: Node = entity_scene.instantiate()
	if entity == null:
		push_error("[EntityManager] Failed to instantiate entity scene")
		return null

	# Configure entity
	if entity.has_method("set_manager"):
		entity.set_manager(self)

	if entity is Node3D:
		(entity as Node3D).global_position = spawn_position

	_favorite_room = favorite_room
	if entity.has_method("set_favorite_room"):
		entity.set_favorite_room(favorite_room)

	# Add to scene tree
	add_child(entity)
	_active_entity = entity

	entity_spawned.emit(entity)

	# Emit EventBus signal
	var entity_type_name := "Unknown"
	if entity.has_method("get_entity_type"):
		entity_type_name = entity.get_entity_type()
	EventBus.entity_spawned.emit(entity_type_name, favorite_room)

	print("[EntityManager] Entity spawned at %v in room '%s'" % [spawn_position, favorite_room])

	return entity


## Removes the active entity from the match.
func despawn_entity() -> void:
	if _active_entity == null:
		return

	var entity := _active_entity
	_active_entity = null

	if is_instance_valid(entity):
		entity_removed.emit(entity)
		entity.queue_free()

	EventBus.entity_removed.emit()
	print("[EntityManager] Entity despawned")


## Gets the currently active entity, or null if none.
func get_active_entity() -> Node:
	return _active_entity


## Checks if an entity is currently active in the match.
func has_active_entity() -> bool:
	return _active_entity != null and is_instance_valid(_active_entity)


## Gets the current aggression phase.
func get_aggression_phase() -> AggressionPhase:
	return _aggression_phase


## Gets the name of the current aggression phase.
func get_aggression_phase_name() -> String:
	match _aggression_phase:
		AggressionPhase.DORMANT:
			return "Dormant"
		AggressionPhase.ACTIVE:
			return "Active"
		AggressionPhase.AGGRESSIVE:
			return "Aggressive"
		AggressionPhase.FURIOUS:
			return "Furious"
	return "Unknown"


## Returns true if the entity is currently hunting.
func is_hunting() -> bool:
	return _is_hunting


## Returns true if a hunt can be initiated based on cooldown and phase.
func can_initiate_hunt() -> bool:
	if _is_hunting:
		return false

	if _aggression_phase == AggressionPhase.DORMANT:
		return false

	var cooldown: float = HUNT_COOLDOWNS[_aggression_phase]
	return _hunt_cooldown_timer >= cooldown


## Gets the current hunt cooldown remaining.
func get_hunt_cooldown_remaining() -> float:
	if _aggression_phase == AggressionPhase.DORMANT:
		return INF

	var cooldown: float = HUNT_COOLDOWNS[_aggression_phase]
	return maxf(0.0, cooldown - _hunt_cooldown_timer)


## Gets the match elapsed time in seconds.
func get_match_time() -> float:
	return _match_time


## Gets the entity's favorite room.
func get_favorite_room() -> String:
	return _favorite_room


## Attempts to start a hunt from the entity's current position.
## Returns true if the hunt started, false if prevented.
func attempt_hunt(entity_position: Vector3) -> bool:
	if not _is_server:
		return false

	if not can_initiate_hunt():
		return false

	if not has_active_entity():
		return false

	# Emit pre-hunt signal for protection items (crucifix)
	EventBus.hunt_starting.emit(entity_position, _active_entity)

	# Check if hunt was prevented
	if _hunt_was_prevented:
		_hunt_was_prevented = false
		_hunt_cooldown_timer = 0.0
		print("[EntityManager] Hunt prevented by protection item")
		return false

	# Hunt proceeds
	_start_hunt()
	return true


## Ends the current hunt.
func end_hunt() -> void:
	if not _is_hunting:
		return

	_is_hunting = false
	_hunt_cooldown_timer = 0.0

	EventBus.hunt_ended.emit()

	if _active_entity and _active_entity.has_method("on_hunt_ended"):
		_active_entity.on_hunt_ended()

	print("[EntityManager] Hunt ended")


## Sets whether this instance is the server/host.
func set_is_server(is_server: bool) -> void:
	_is_server = is_server


## Returns whether this instance is the server/host.
func is_server() -> bool:
	return _is_server


## Resets the manager state for a new match.
func reset() -> void:
	despawn_entity()
	_match_time = 0.0
	_aggression_phase = AggressionPhase.DORMANT
	_hunt_cooldown_timer = 0.0
	_is_hunting = false
	_hunt_was_prevented = false
	_favorite_room = ""
	print("[EntityManager] Reset for new match")


# --- Internal Methods ---


func _is_in_match() -> bool:
	if not GameManager:
		return false
	return GameManager.is_in_match()


func _update_aggression_phase() -> void:
	var new_phase := _aggression_phase

	# Check thresholds in reverse order (highest first)
	if _match_time >= AGGRESSION_THRESHOLDS[AggressionPhase.FURIOUS]:
		new_phase = AggressionPhase.FURIOUS
	elif _match_time >= AGGRESSION_THRESHOLDS[AggressionPhase.AGGRESSIVE]:
		new_phase = AggressionPhase.AGGRESSIVE
	elif _match_time >= AGGRESSION_THRESHOLDS[AggressionPhase.ACTIVE]:
		new_phase = AggressionPhase.ACTIVE
	else:
		new_phase = AggressionPhase.DORMANT

	if new_phase != _aggression_phase:
		var old_phase := _aggression_phase
		_aggression_phase = new_phase
		aggression_changed.emit(new_phase, get_aggression_phase_name())
		EventBus.entity_aggression_changed.emit(new_phase, get_aggression_phase_name())
		print("[EntityManager] Aggression phase: %s -> %s (%.1fs)" % [
			_phase_to_string(old_phase),
			_phase_to_string(new_phase),
			_match_time
		])


func _update_hunt_cooldown(delta: float) -> void:
	if not _is_hunting:
		_hunt_cooldown_timer += delta


func _start_hunt() -> void:
	_is_hunting = true
	EventBus.hunt_started.emit()

	if _active_entity and _active_entity.has_method("on_hunt_started"):
		_active_entity.on_hunt_started()

	print("[EntityManager] Hunt started")


func _on_game_state_changed(old_state: int, new_state: int) -> void:
	# Use GameManager constants if available, otherwise use raw values
	# INVESTIGATION = 3, based on GameManager.GameState enum
	const INVESTIGATION := 3
	const HUNT := 4

	if new_state == INVESTIGATION and old_state != HUNT:
		# Starting fresh investigation - reset match time
		_match_time = 0.0
		_aggression_phase = AggressionPhase.DORMANT
		_hunt_cooldown_timer = 0.0

		# Determine if we're the server
		if NetworkManager:
			_is_server = NetworkManager.is_game_host()
		else:
			_is_server = true  # Single player fallback

		print("[EntityManager] Investigation started, server=%s" % _is_server)

	elif new_state == HUNT:
		# Transitioning to hunt state - entity manager handles this
		pass

	elif old_state == HUNT and new_state == INVESTIGATION:
		# Returning from hunt to investigation
		end_hunt()


func _on_hunt_prevented(_location: Vector3, _charges_remaining: int) -> void:
	# Called by protection items (crucifix) when they prevent a hunt
	_hunt_was_prevented = true


func _phase_to_string(phase: AggressionPhase) -> String:
	match phase:
		AggressionPhase.DORMANT:
			return "Dormant"
		AggressionPhase.ACTIVE:
			return "Active"
		AggressionPhase.AGGRESSIVE:
			return "Aggressive"
		AggressionPhase.FURIOUS:
			return "Furious"
	return "Unknown"
