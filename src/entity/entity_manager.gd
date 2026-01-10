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
	DORMANT,  ## 0-5 min: Passive manifestations only
	ACTIVE,  ## 5-10 min: Occasional hunts
	AGGRESSIVE,  ## 10-15 min: Frequent hunts
	FURIOUS,  ## 15+ min: Near-constant hunting
}

## Time thresholds for aggression phases (in seconds)
const AGGRESSION_THRESHOLDS := {
	AggressionPhase.DORMANT: 0.0,
	AggressionPhase.ACTIVE: 300.0,  # 5 minutes
	AggressionPhase.AGGRESSIVE: 600.0,  # 10 minutes
	AggressionPhase.FURIOUS: 900.0,  # 15 minutes
}

## Base hunt cooldowns per aggression phase (in seconds)
const HUNT_COOLDOWNS := {
	AggressionPhase.DORMANT: INF,  # Cannot hunt
	AggressionPhase.ACTIVE: 120.0,  # 2 minutes
	AggressionPhase.AGGRESSIVE: 60.0,  # 1 minute
	AggressionPhase.FURIOUS: 25.0,  # 25 seconds
}

## Warning phase duration in seconds before hunt starts
const WARNING_PHASE_DURATION := 3.0

## Aggression boost per player death (reduces cooldowns)
const DEATH_AGGRESSION_MULTIPLIER := 0.9

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

## Whether we're in the warning phase before a hunt
var _in_warning_phase: bool = false

## Timer for warning phase countdown
var _warning_timer: float = 0.0

## Entity position when warning phase started (for hunt_starting signal)
var _warning_entity_position := Vector3.ZERO

## Designated entity room (favorite room)
var _favorite_room: String = ""

## Server authority flag
var _is_server: bool = false

## Death tracking
var _death_locations: Dictionary = {}  # player_id -> Vector3
var _death_count: int = 0
var _death_aggression_modifier: float = 1.0


func _ready() -> void:
	# Connect to game state changes
	if EventBus:
		EventBus.game_state_changed.connect(_on_game_state_changed)
		EventBus.hunt_prevented.connect(_on_hunt_prevented)
		EventBus.player_died.connect(_on_player_died)
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
	_update_warning_phase(delta)


# --- Public API ---


## Spawns an entity into the match. Server-only.
## entity_scene: PackedScene of the entity to spawn
## spawn_position: Where to spawn the entity
## favorite_room: The room ID the entity will prefer
func spawn_entity(
	entity_scene: PackedScene, spawn_position: Vector3, favorite_room: String = ""
) -> Node:
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

	# Connect manifestation witness signal for evidence generation
	if entity.has_signal("manifestation_witnessed"):
		entity.manifestation_witnessed.connect(_on_entity_manifestation_witnessed)

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

	if _in_warning_phase:
		return false

	if _aggression_phase == AggressionPhase.DORMANT:
		return false

	var cooldown: float = _get_effective_cooldown()
	return _hunt_cooldown_timer >= cooldown


## Gets the current hunt cooldown remaining.
func get_hunt_cooldown_remaining() -> float:
	if _aggression_phase == AggressionPhase.DORMANT:
		return INF

	var cooldown: float = _get_effective_cooldown()
	return maxf(0.0, cooldown - _hunt_cooldown_timer)


## Gets effective cooldown with death modifier applied.
func _get_effective_cooldown() -> float:
	var base: float = HUNT_COOLDOWNS[_aggression_phase]
	return base * _death_aggression_modifier


## Gets the match elapsed time in seconds.
func get_match_time() -> float:
	return _match_time


## Gets the entity's favorite room.
func get_favorite_room() -> String:
	return _favorite_room


## Attempts to start a hunt from the entity's current position.
## Returns true if warning phase started, false if cannot hunt.
## Note: Hunt doesn't start immediately - goes through warning phase first.
func attempt_hunt(entity_position: Vector3) -> bool:
	if not _is_server:
		return false

	if not can_initiate_hunt():
		return false

	if not has_active_entity():
		return false

	# Start warning phase
	_start_warning_phase(entity_position)
	return true


## Attempts to start an immediate hunt (skips warning phase).
## Used for ambush scenarios when entity is already at player.
## Returns true if the hunt started, false if prevented.
func attempt_immediate_hunt(entity_position: Vector3) -> bool:
	if not _is_server:
		return false

	if _is_hunting or _in_warning_phase:
		return false

	if not has_active_entity():
		return false

	# Skip warning phase - emit hunt_starting for prevention check
	EventBus.hunt_starting.emit(entity_position, _active_entity)

	# Check if hunt was prevented
	if _hunt_was_prevented:
		_hunt_was_prevented = false
		_hunt_cooldown_timer = 0.0
		print("[EntityManager] Immediate hunt prevented by protection item")
		return false

	# Hunt proceeds immediately
	_start_hunt()
	return true


## Returns true if currently in warning phase.
func is_in_warning_phase() -> bool:
	return _in_warning_phase


## Gets the remaining warning phase time in seconds.
func get_warning_time_remaining() -> float:
	if not _in_warning_phase:
		return 0.0
	return _warning_timer


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
	_in_warning_phase = false
	_warning_timer = 0.0
	_warning_entity_position = Vector3.ZERO
	_favorite_room = ""
	_death_locations.clear()
	_death_count = 0
	_death_aggression_modifier = 1.0
	print("[EntityManager] Reset for new match")


# --- Death Tracking ---


## Gets the total number of player deaths this match.
func get_death_count() -> int:
	return _death_count


## Gets the death location for a player, or Vector3.ZERO if not dead.
func get_death_location(player_id: int) -> Vector3:
	return _death_locations.get(player_id, Vector3.ZERO)


## Gets all death locations as a dictionary (player_id -> Vector3).
func get_all_death_locations() -> Dictionary:
	return _death_locations.duplicate()


## Registers a player death at a location.
## Called internally via EventBus.player_died signal.
func register_death(player_id: int, location: Vector3) -> void:
	_death_locations[player_id] = location
	_death_count += 1

	# Increase aggression (reduce cooldowns) with each death
	_death_aggression_modifier *= DEATH_AGGRESSION_MULTIPLIER

	print(
		(
			"[EntityManager] Player %d died at %v (deaths: %d, modifier: %.2f)"
			% [player_id, location, _death_count, _death_aggression_modifier]
		)
	)


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
		print(
			(
				"[EntityManager] Aggression phase: %s -> %s (%.1fs)"
				% [_phase_to_string(old_phase), _phase_to_string(new_phase), _match_time]
			)
		)


func _update_hunt_cooldown(delta: float) -> void:
	if not _is_hunting and not _in_warning_phase:
		_hunt_cooldown_timer += delta


func _update_warning_phase(delta: float) -> void:
	if not _in_warning_phase:
		return

	_warning_timer -= delta

	if _warning_timer <= 0.0:
		_end_warning_phase()


func _start_warning_phase(entity_position: Vector3) -> void:
	_in_warning_phase = true
	_warning_timer = WARNING_PHASE_DURATION
	_warning_entity_position = entity_position

	# Emit warning started signal for effects (lights flicker, equipment static)
	EventBus.hunt_warning_started.emit(entity_position, WARNING_PHASE_DURATION)

	# Emit hunt_starting for protection items (crucifix can still prevent)
	EventBus.hunt_starting.emit(entity_position, _active_entity)

	print("[EntityManager] Warning phase started (%.1fs)" % WARNING_PHASE_DURATION)


func _end_warning_phase() -> void:
	_in_warning_phase = false
	_warning_timer = 0.0

	# Check if hunt was prevented during warning phase
	if _hunt_was_prevented:
		_hunt_was_prevented = false
		_hunt_cooldown_timer = 0.0
		EventBus.hunt_warning_ended.emit(false)
		print("[EntityManager] Hunt prevented during warning phase")
		return

	# Hunt proceeds
	EventBus.hunt_warning_ended.emit(true)
	_start_hunt()


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


func _on_player_died(player_id: int) -> void:
	# Get death location from player node if possible
	var death_location := Vector3.ZERO

	# Try to find player node and get position
	var player_group := get_tree().get_nodes_in_group("players")
	for player in player_group:
		var pid := _get_player_id_from_node(player)
		if pid == player_id and player is Node3D:
			death_location = (player as Node3D).global_position
			break

	register_death(player_id, death_location)


func _get_player_id_from_node(player: Node) -> int:
	if player.get("peer_id") != null:
		return player.peer_id as int
	if player.has_method("get_peer_id"):
		return player.get_peer_id()
	return player.get_instance_id()


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


# --- Manifestation Evidence ---


## Called when an entity manifestation ends with witnesses.
## Generates VISUAL_MANIFESTATION evidence through EvidenceManager.
func _on_entity_manifestation_witnessed(witness_ids: Array, location: Vector3) -> void:
	if not _is_server:
		return

	if witness_ids.is_empty():
		return

	var evidence_manager := _get_evidence_manager()
	if not evidence_manager:
		push_warning("[EntityManager] EvidenceManager not available for manifestation evidence")
		return

	# Determine quality based on witness count
	# Multiple witnesses = STRONG (harder for Cultist to dispute)
	# Single witness = WEAK (easier to dispute as "I didn't see it")
	var quality: int = EvidenceEnums.ReadingQuality.STRONG
	if witness_ids.size() == 1:
		quality = EvidenceEnums.ReadingQuality.WEAK

	# Use first witness as primary collector
	var collector_id: int = witness_ids[0]

	# Collect the evidence
	var evidence: Evidence = evidence_manager.collect_evidence(
		EvidenceEnums.EvidenceType.VISUAL_MANIFESTATION, collector_id, location, quality, ""  # No equipment used
	)

	if evidence:
		# Add all witnesses to the evidence
		for witness_id in witness_ids:
			evidence.add_witness(witness_id)

		print(
			(
				"[EntityManager] VISUAL_MANIFESTATION evidence generated: %d witnesses at %v"
				% [witness_ids.size(), location]
			)
		)


func _get_evidence_manager() -> Node:
	if has_node("/root/EvidenceManager"):
		return get_node("/root/EvidenceManager")
	return null
