class_name HuntDetection
extends RefCounted
## Handles detection mechanics during entity hunts.
##
## Provides:
## - Distance-based detection with modifiers (electronics, voice)
## - Line-of-sight checks for chase triggers
## - Last known position tracking when LoS is broken
##
## Detection radius formula:
##   base (7m) + electronics (+3m) + voice (+5m)
##
## Used by Entity during HUNTING state to locate and track players.

# --- Constants ---

## Base detection radius in meters
const BASE_DETECTION_RADIUS := 7.0

## Bonus detection radius when player has electronics in hand
const ELECTRONICS_DETECTION_BONUS := 3.0

## Bonus detection radius when player is using voice chat
const VOICE_DETECTION_BONUS := 5.0

## Physics layer for walls/obstacles (Layer 1)
const WORLD_COLLISION_LAYER := 1

## Offset from entity/player position for eye-level raycasts
const EYE_HEIGHT_OFFSET := 1.6


## Calculates the effective detection radius for a player.
## Returns base radius plus any applicable modifiers.
static func get_detection_radius(player: Node) -> float:
	var radius := BASE_DETECTION_RADIUS

	# Check electronics bonus
	if _player_has_electronics_equipped(player):
		radius += ELECTRONICS_DETECTION_BONUS

	# Check voice bonus
	if _player_is_using_voice(player):
		radius += VOICE_DETECTION_BONUS

	return radius


## Returns true if player is within detection radius of entity.
static func is_player_in_range(entity_pos: Vector3, player: Node) -> bool:
	if not is_instance_valid(player):
		return false

	var player_pos := _get_player_position(player)
	var distance := entity_pos.distance_to(player_pos)
	var detection_radius := get_detection_radius(player)

	return distance <= detection_radius


## Checks if entity has line-of-sight to player.
## Uses raycast from entity eye position to player eye position.
## Returns true if there are no obstacles blocking the view.
static func has_line_of_sight(
	entity: Node3D, player: Node, space_state: PhysicsDirectSpaceState3D
) -> bool:
	if not is_instance_valid(entity) or not is_instance_valid(player):
		return false

	var entity_eye := entity.global_position + Vector3.UP * EYE_HEIGHT_OFFSET
	var player_eye := _get_player_position(player) + Vector3.UP * EYE_HEIGHT_OFFSET

	var query := PhysicsRayQueryParameters3D.create(entity_eye, player_eye)
	query.collision_mask = WORLD_COLLISION_LAYER
	query.exclude = [entity.get_rid()]

	# Also exclude the player's body from the raycast
	if player is CollisionObject3D:
		query.exclude.append(player.get_rid())

	var result := space_state.intersect_ray(query)

	# If no collision, we have line of sight
	return result.is_empty()


## Finds the nearest detectable player to the entity.
## Returns the player node and distance, or null if no players detected.
static func find_nearest_player(
	entity: Node3D, players: Array, space_state: PhysicsDirectSpaceState3D = null
) -> Dictionary:
	var nearest_player: Node = null
	var nearest_distance := INF

	for player in players:
		if not is_instance_valid(player):
			continue

		var player_pos := _get_player_position(player)
		var distance := entity.global_position.distance_to(player_pos)
		var detection_radius := get_detection_radius(player)

		# Check if in detection range
		if distance <= detection_radius and distance < nearest_distance:
			nearest_distance = distance
			nearest_player = player

	if nearest_player == null:
		return {}

	# Check line of sight if space state provided
	var has_los := false
	if space_state:
		has_los = has_line_of_sight(entity, nearest_player, space_state)

	return {
		"player": nearest_player,
		"distance": nearest_distance,
		"has_line_of_sight": has_los,
	}


## Checks all players and returns detection results.
## Returns array of dictionaries with player, distance, in_range, and has_los.
static func detect_players(
	entity: Node3D, players: Array, space_state: PhysicsDirectSpaceState3D = null
) -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	for player in players:
		if not is_instance_valid(player):
			continue

		var player_pos := _get_player_position(player)
		var distance := entity.global_position.distance_to(player_pos)
		var detection_radius := get_detection_radius(player)
		var in_range := distance <= detection_radius

		var has_los := false
		if in_range and space_state:
			has_los = has_line_of_sight(entity, player, space_state)

		(
			results
			. append(
				{
					"player": player,
					"distance": distance,
					"detection_radius": detection_radius,
					"in_range": in_range,
					"has_line_of_sight": has_los,
				}
			)
		)

	return results


# --- Private Helpers ---


## Gets the player's global position.
static func _get_player_position(player: Node) -> Vector3:
	if player is Node3D:
		return (player as Node3D).global_position
	return Vector3.ZERO


## Checks if player has electronics equipment in hand.
## Electronics include: EMF Reader, Spirit Box, Thermometer, Video Camera, etc.
static func _player_has_electronics_equipped(player: Node) -> bool:
	# Try to get EquipmentManager from player (use Variant for duck typing)
	var equipment_manager = null  # Untyped to support both Node and mock objects

	if player.has_method("get_equipment_manager"):
		equipment_manager = player.get_equipment_manager()
	elif player.has_node("EquipmentManager"):
		equipment_manager = player.get_node("EquipmentManager")

	if equipment_manager == null:
		return false

	# Check if the active equipment is an electronic device
	if not equipment_manager.has_method("get_active_equipment"):
		return false

	var equipment = equipment_manager.get_active_equipment()  # Untyped for duck typing
	if equipment == null:
		return false

	# Check equipment type against known electronics
	if "equipment_type" in equipment:
		return _is_electronic_equipment(equipment.equipment_type)

	return false


## Returns true if the equipment type is electronic (attracts entity during hunt).
static func _is_electronic_equipment(equipment_type: int) -> bool:
	# Electronic equipment types from Equipment.EquipmentType enum
	const ELECTRONIC_TYPES := [
		0,  # EMF_READER
		1,  # SPIRIT_BOX
		3,  # THERMOMETER
		6,  # VIDEO_CAMERA
		7,  # PARABOLIC_MIC
		8,  # SPECTRAL_PRISM_CALIBRATOR
		9,  # SPECTRAL_PRISM_LENS
		11,  # AURA_IMAGER
	]
	return equipment_type in ELECTRONIC_TYPES


## Checks if player is currently using voice chat.
## Returns false if voice system not available (placeholder for FW-014).
static func _player_is_using_voice(player: Node) -> bool:
	# Check if player has voice activity flag
	if player.has_method("is_voice_active"):
		return player.is_voice_active()

	# Check for voice_active property
	if "voice_active" in player:
		return player.voice_active

	# Placeholder - voice chat integration (FW-014) not yet implemented
	return false
