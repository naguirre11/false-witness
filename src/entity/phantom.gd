class_name Phantom
extends Entity
## Phantom entity - the first entity type implementation.
##
## Evidence: EMF_SIGNATURE, PRISM_READING, VISUAL_MANIFESTATION
##
## Behavioral tell: Disappears instantly when photographed during manifestation.
## This makes the camera a defensive tool against the Phantom.
##
## Unique mechanics:
## - Looking at the Phantom drains sanity 2x faster than other entities
## - Disappears when photographed (not just looked at with camera)
## - Uses default hunt thresholds and behavior

# --- Constants ---

## Enhanced sanity drain multiplier when looking at Phantom
const SANITY_DRAIN_MULTIPLIER: float = 2.0

## Default sanity drain from entity sighting (from SanityManager)
const BASE_ENTITY_SIGHTING_DRAIN: float = 5.0

## Phantom-specific sanity drain per second while visible and looked at
const LOOK_DRAIN_PER_SECOND: float = 2.0

## Interval between player visibility checks during manifestation (seconds)
const VISIBILITY_CHECK_INTERVAL: float = 0.2

# --- State ---

## Timer for visibility checks during manifestation
var _visibility_check_timer: float = 0.0

## Players currently looking at the Phantom (for sanity drain)
var _players_looking: Array = []


func _ready() -> void:
	super._ready()

	# Set Phantom-specific defaults
	entity_type = "Phantom"

	# Default hunt settings (Phantom uses standard values)
	hunt_sanity_threshold = 50.0
	hunt_cooldown_multiplier = 1.0
	hunt_duration = 30.0

	# Default movement (Phantom uses standard speeds)
	base_speed = 1.5
	hunt_aware_speed = 2.5
	hunt_unaware_speed = 1.0


# --- Identity ---


## Returns the entity type identifier.
func get_entity_type() -> String:
	return "Phantom"


## Returns the evidence types for this entity.
## Used by entity identification systems.
func get_evidence_types() -> Array[int]:
	return [
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		EvidenceEnums.EvidenceType.PRISM_READING,
		EvidenceEnums.EvidenceType.VISUAL_MANIFESTATION,
	]


## Returns true if this entity has the given evidence type.
func has_evidence_type(evidence: EvidenceEnums.EvidenceType) -> bool:
	match evidence:
		EvidenceEnums.EvidenceType.EMF_SIGNATURE, EvidenceEnums.EvidenceType.PRISM_READING, EvidenceEnums.EvidenceType.VISUAL_MANIFESTATION:
			return true
		_:
			return false


# --- Behavioral Tell ---


## Returns the behavioral tell type.
## Phantom disappears when photographed during manifestation.
func get_behavioral_tell_type() -> String:
	return "photograph_disappearance"


## Checks if the behavioral tell should trigger.
## For Phantom: triggers if any player photographs it during manifestation.
## Returns true if tell was triggered (and ends manifestation).
func _check_behavioral_tell() -> bool:
	# Only check during manifestation
	if _state != EntityState.MANIFESTING:
		return false

	# Check if any player is photographing us
	var players := _get_all_players()
	for player in players:
		if _is_player_photographing(player):
			# Photograph taken! Disappear immediately.
			end_manifestation()
			return true

	return false


## Checks if a player is actively photographing the Phantom.
## Returns true if player has camera equipped, is aiming, and can see us.
func _is_player_photographing(player: Node) -> bool:
	if not is_instance_valid(player):
		return false

	var is_using_camera := _check_player_using_camera(player)
	if not is_using_camera:
		return false

	# Check line of sight to player
	var space_state := get_world_3d().direct_space_state
	return _has_line_of_sight_to(player, space_state)


## Checks if a player is actively using a camera.
func _check_player_using_camera(player: Node) -> bool:
	# Method 1: Direct camera check
	if player.has_method("is_using_camera"):
		return player.is_using_camera()

	# Method 2: Check equipped item
	if player.has_method("get_equipped_item"):
		var item: Node = player.get_equipped_item()
		if not item:
			return false
		# Check if it's a camera (by method or name)
		var is_camera := item.has_method("take_photo") or "camera" in item.name.to_lower()
		if not is_camera:
			return false
		# Check if camera is in photo mode (if applicable)
		if item.has_method("is_aiming"):
			return item.is_aiming()
		return true

	# Can't determine camera state - assume not photographing
	return false


## Gets all players (alive or dead, for camera checks).
func _get_all_players() -> Array:
	# Try PlayerManager first
	if has_node("/root/PlayerManager"):
		var player_manager := get_node("/root/PlayerManager")
		if player_manager.has_method("get_all_players"):
			return player_manager.get_all_players()

	# Fallback to scene tree search
	return get_tree().get_nodes_in_group("players")


## Checks line of sight from entity to a specific node.
func _has_line_of_sight_to(target: Node, space_state: PhysicsDirectSpaceState3D) -> bool:
	if not target is Node3D:
		return false

	var target_pos: Vector3 = (target as Node3D).global_position
	# Aim for upper body (head area)
	var target_point := target_pos + Vector3(0, 1.6, 0)
	var our_point := global_position + Vector3(0, 1.5, 0)

	var query := PhysicsRayQueryParameters3D.create(our_point, target_point)
	query.exclude = [self]
	query.collision_mask = 1  # World only

	var result := space_state.intersect_ray(query)

	# If no hit, we have clear line of sight
	return result.is_empty()


# --- Sanity Mechanics ---


## Called each frame while manifesting.
## Handles enhanced sanity drain for players looking at Phantom.
func _process_manifesting_behavior(delta: float) -> void:
	_visibility_check_timer -= delta

	if _visibility_check_timer <= 0:
		_visibility_check_timer = VISIBILITY_CHECK_INTERVAL
		_update_players_looking()

	# Drain sanity from players currently looking at us
	_apply_look_sanity_drain(delta)


## Updates the list of players currently looking at the Phantom.
func _update_players_looking() -> void:
	_players_looking.clear()

	if not _is_visible:
		return

	var players := _get_alive_players()
	var space_state := get_world_3d().direct_space_state

	for player in players:
		if not is_instance_valid(player) or not player is Node3D:
			continue

		# Check if player is looking in our direction
		if _is_player_looking_at_us(player, space_state):
			_players_looking.append(player)


## Checks if a player is looking at the Phantom.
## Uses dot product of player facing direction and direction to Phantom.
func _is_player_looking_at_us(player: Node3D, space_state: PhysicsDirectSpaceState3D) -> bool:
	# First check line of sight
	if not _has_line_of_sight_to(player, space_state):
		return false

	# Get player's forward direction (assuming -Z is forward in local space)
	var player_forward := -player.global_transform.basis.z.normalized()

	# Direction from player to us
	var to_phantom := (global_position - player.global_position).normalized()

	# Check if player is facing us (within ~60 degrees)
	var dot := player_forward.dot(to_phantom)
	return dot > 0.5  # cos(60) = 0.5


## Applies sanity drain to players looking at the Phantom.
## Phantom drains sanity 2x faster than other entities.
func _apply_look_sanity_drain(delta: float) -> void:
	if _players_looking.is_empty():
		return

	var sanity_manager := _get_sanity_manager()
	if not sanity_manager:
		return

	for player in _players_looking:
		if not is_instance_valid(player):
			continue

		var player_id := _get_player_id(player)
		var drain := LOOK_DRAIN_PER_SECOND * SANITY_DRAIN_MULTIPLIER * delta
		sanity_manager.drain_sanity(player_id, drain)


## Called when manifestation starts.
## Triggers initial sanity drain for players who see us.
func _on_enter_manifesting() -> void:
	# Initial sanity hit for all players who see us
	_visibility_check_timer = 0.0  # Force immediate check
	_update_players_looking()

	var sanity_manager := _get_sanity_manager()
	if sanity_manager:
		# Enhanced initial drain (2x normal)
		var initial_drain := BASE_ENTITY_SIGHTING_DRAIN * SANITY_DRAIN_MULTIPLIER
		for player in _players_looking:
			if is_instance_valid(player):
				var player_id := _get_player_id(player)
				sanity_manager.drain_sanity(player_id, initial_drain)


## Gets the SanityManager autoload.
func _get_sanity_manager() -> Node:
	if has_node("/root/SanityManager"):
		return get_node("/root/SanityManager")
	return null


# --- Hunt Behavior ---
# Phantom uses default hunt behavior from Entity base class.
# No overrides needed for:
# - get_hunt_sanity_threshold() -> 50.0 (default)
# - should_ignore_team_sanity() -> false (default)
# - can_voice_trigger_hunt() -> false (default)
# - get_hunt_speed_for_awareness() -> default speeds
# - can_hunt_in_current_conditions() -> true (default)

# --- Audio Cues (Placeholder) ---
# TODO: Implement Phantom-specific audio cues
# - Unique ambient sounds
# - Hunt chase audio
# - Manifestation appearance sound
# - Disappearance sound (on photograph tell)

# --- Network State ---


## Gets extended network state including Phantom-specific data.
func get_network_state() -> Dictionary:
	var state := super.get_network_state()
	state["players_looking_count"] = _players_looking.size()
	return state
