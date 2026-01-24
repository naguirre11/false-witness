class_name VideoCamera
extends Equipment
## Video Camera equipment for capturing photos of manifestations.
##
## Video camera uses film-based system - 6 photos maximum per match.
## Enter aim mode via toggle, take photos while aiming.
## Photos capture entity manifestations visible within view frustum.
##
## Features:
## - Film counter (6 max)
## - Aim mode toggle
## - Server-authoritative photo capture with RPCs
## - PhotoRecord storage
## - Evidence integration

# --- Signals ---

## Emitted when a photo successfully captures evidence.
signal photo_captured(record: PhotoRecord)

## Emitted when photo is taken but nothing captured.
signal photo_missed()

## Emitted when attempting to take photo with no film.
signal film_depleted()

## Emitted when aim mode is activated.
signal aim_started()

## Emitted when aim mode is deactivated.
signal aim_ended()

## Emitted when film count changes (after photo taken).
signal film_changed(remaining: int, max_film: int)

## Emitted during cooldown after taking photo.
signal cooldown_changed(time_remaining: float, total_time: float)

# --- Constants ---

const EvidenceEnums := preload("res://src/evidence/evidence_enums.gd")

## Maximum film capacity.
const MAX_FILM: int = 6

## Detection range for photo capture.
const CAPTURE_RANGE: float = 20.0

## Field of view for capture (dot product threshold).
## 0.5 = cos(60 degrees) = 120 degree FOV
const CAPTURE_FOV_DOT: float = 0.5

## Entity state constant for MANIFESTING state.
const MANIFESTING_STATE: int = 3  # EntityState.MANIFESTING

# --- State ---

var _film_remaining: int = MAX_FILM
var _is_aiming: bool = false
var _photos: Array[PhotoRecord] = []


func _ready() -> void:
	equipment_type = EquipmentType.VIDEO_CAMERA
	equipment_name = "Video Camera"
	use_mode = UseMode.TOGGLE
	cooldown_time = 2.5


func _process(delta: float) -> void:
	super._process(delta)

	# Emit cooldown updates for UI
	if _current_state == EquipmentState.COOLDOWN:
		var remaining: float = get_cooldown_remaining()
		cooldown_changed.emit(remaining, cooldown_time)


# --- Virtual Method Overrides ---


func _use_impl() -> void:
	_is_aiming = not _is_aiming
	if _is_aiming:
		aim_started.emit()
		print("[VideoCamera] Aim mode activated")
	else:
		aim_ended.emit()
		print("[VideoCamera] Aim mode deactivated")


func _stop_using_impl() -> void:
	if _is_aiming:
		_is_aiming = false
		aim_ended.emit()
		print("[VideoCamera] Aim mode deactivated (stopped)")


func _can_use_impl(_player: Node) -> bool:
	# Can enter aim mode even with 0 film (to allow looking through viewfinder)
	return true


func get_detectable_evidence() -> Array[String]:
	return ["VISUAL_MANIFESTATION"]


func _on_equipped(_player: Node) -> void:
	# Reset state when equipped
	_film_remaining = MAX_FILM
	_is_aiming = false
	_photos.clear()
	film_changed.emit(_film_remaining, MAX_FILM)


func _on_unequipped(_player: Node) -> void:
	# Exit aim mode when unequipped
	if _is_aiming:
		_is_aiming = false
		aim_ended.emit()


# --- Public API ---


## Returns true if camera is in aim mode.
## Part of Phantom interface - Phantom calls this to detect active photography.
func is_aiming() -> bool:
	return _is_aiming


## Returns true if camera is equipped and in aim mode.
## This is the interface method for Phantom detection.
func is_using_camera() -> bool:
	return _is_equipped and _is_aiming


## Takes a photo. Returns null immediately; actual capture handled via RPC.
## Part of Phantom interface - Phantom uses has_method("take_photo") to detect cameras.
func take_photo() -> PhotoRecord:
	# Can't take photo if no film or on cooldown
	if _film_remaining <= 0:
		push_warning("VideoCamera: No film remaining")
		return null

	if _current_state == EquipmentState.COOLDOWN:
		push_warning("VideoCamera: Camera on cooldown")
		return null

	if not _is_aiming:
		push_warning("VideoCamera: Must be aiming to take photo")
		return null

	# Request capture from server
	_rpc_request_capture.rpc_id(1)

	return null  # Result comes via RPC


## Returns remaining film count.
func get_film_remaining() -> int:
	return _film_remaining


## Returns all captured photos.
func get_photos() -> Array[PhotoRecord]:
	return _photos


# --- Entity Detection ---


## Detects if any manifesting entity is in the camera's capture frame.
## Returns {found: bool, entity: Node, entity_type: String}
func _detect_entity_in_frame() -> Dictionary:
	var result := {"found": false, "entity": null, "entity_type": ""}

	if not is_instance_valid(_owning_player):
		return result

	# Get camera position and direction
	var player_pos: Vector3 = _owning_player.global_position + Vector3(0, 1.6, 0)  # Head height
	var camera_forward: Vector3 = -_owning_player.global_transform.basis.z

	# Get all entities
	var entities := get_tree().get_nodes_in_group("entities")

	var closest_distance: float = CAPTURE_RANGE + 1.0
	var closest_entity: Node = null

	for entity in entities:
		if not entity is Node3D:
			continue

		# Check if manifesting - entity must have _state or get_state() method
		var state: int = -1
		if entity.get("_state") != null:
			state = entity._state
		elif entity.has_method("get_state"):
			state = entity.get_state()

		# EntityState.MANIFESTING = 3 (check entity.gd for enum)
		if state != MANIFESTING_STATE:
			continue

		# Calculate direction and distance
		var entity_pos: Vector3 = entity.global_position + Vector3(0, 1.5, 0)  # Entity center
		var to_entity: Vector3 = entity_pos - player_pos
		var distance: float = to_entity.length()

		# Range check
		if distance > CAPTURE_RANGE:
			continue

		# FOV check (dot product)
		var direction: Vector3 = to_entity.normalized()
		var dot: float = camera_forward.dot(direction)
		if dot < CAPTURE_FOV_DOT:
			continue

		# Line of sight check (raycast)
		if not _has_line_of_sight(player_pos, entity_pos):
			continue

		# Track closest
		if distance < closest_distance:
			closest_distance = distance
			closest_entity = entity

	if closest_entity:
		result.found = true
		result.entity = closest_entity
		# Get entity type name
		if closest_entity.has_method("get_entity_type"):
			result.entity_type = closest_entity.get_entity_type()
		elif closest_entity.get("entity_type") != null:
			result.entity_type = str(closest_entity.entity_type)
		else:
			result.entity_type = closest_entity.get_class()

	return result


## Checks line of sight using raycast.
func _has_line_of_sight(from_pos: Vector3, to_pos: Vector3) -> bool:
	var space_state := get_world_3d().direct_space_state
	if not space_state:
		return false

	var query := PhysicsRayQueryParameters3D.create(from_pos, to_pos)
	query.collision_mask = 1  # World layer only
	query.exclude = [self]  # Exclude camera

	var result := space_state.intersect_ray(query)

	# If nothing hit, we have LOS
	if result.is_empty():
		return true

	# If hit something, check if it's close to target (allow small tolerance)
	var hit_distance: float = (result.position - from_pos).length()
	var target_distance: float = (to_pos - from_pos).length()

	return hit_distance >= target_distance - 0.5  # Allow small tolerance


# --- Network State ---


func get_network_state() -> Dictionary:
	var state := super.get_network_state()
	state["is_aiming"] = _is_aiming
	state["film_remaining"] = _film_remaining
	# Note: Photos are synced separately via network manager
	return state


func apply_network_state(state: Dictionary) -> void:
	super.apply_network_state(state)
	if state.has("is_aiming"):
		var new_aiming: bool = state.is_aiming
		if new_aiming != _is_aiming:
			_is_aiming = new_aiming
			if _is_aiming:
				aim_started.emit()
			else:
				aim_ended.emit()
	if state.has("film_remaining"):
		var new_film: int = state.film_remaining
		if new_film != _film_remaining:
			_film_remaining = new_film
			film_changed.emit(_film_remaining, MAX_FILM)


# --- RPC Methods ---


## Client -> Server: Request photo capture
@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_capture() -> void:
	if not multiplayer.is_server():
		return

	var sender_id: int = multiplayer.get_remote_sender_id()

	# Validate ownership
	if not is_instance_valid(_owning_player):
		_rpc_capture_result.rpc_id(sender_id, false, {})
		return

	if _owning_player.get_multiplayer_authority() != sender_id:
		push_warning("VideoCamera: RPC from non-owner")
		_rpc_capture_result.rpc_id(sender_id, false, {})
		return

	# Calculate player position for photo capture
	var player_pos: Vector3 = _owning_player.global_position + Vector3(0, 1.6, 0)  # Head height

	# Server-side validation
	if _film_remaining <= 0:
		_rpc_capture_result.rpc_id(sender_id, false, {})
		return

	if _current_state == EquipmentState.COOLDOWN:
		_rpc_capture_result.rpc_id(sender_id, false, {})
		return

	# Decrement film immediately (skill expression - miss wastes film)
	_film_remaining -= 1
	film_changed.emit(_film_remaining, MAX_FILM)
	if _film_remaining <= 0:
		film_depleted.emit()

	# Start cooldown
	_cooldown_timer = cooldown_time
	_set_state(EquipmentState.COOLDOWN)
	cooldown_changed.emit(cooldown_time, cooldown_time)

	# Detect entity
	var detection := _detect_entity_in_frame()

	if detection.found:
		# Create photo record
		var photo := PhotoRecord.create(
			detection.entity_type,
			player_pos,
			sender_id
		)

		# Create evidence via EvidenceManager
		var evidence_manager := _get_evidence_manager()
		if evidence_manager:
			var evidence: Evidence = evidence_manager.collect_evidence(
				EvidenceEnums.EvidenceType.VISUAL_MANIFESTATION,
				sender_id,
				player_pos,
				EvidenceEnums.ReadingQuality.STRONG,
				"Video Camera"
			)
			if evidence:
				evidence.set_metadata("source", "photo")
				evidence.set_metadata("photo_uid", photo.uid)
				photo.evidence_uid = evidence.uid

		_photos.append(photo)

		# Broadcast success to all clients with authoritative film count
		_rpc_capture_result.rpc(true, photo.to_network_dict(), _film_remaining)
	else:
		# Miss - notify sender only with authoritative film count
		_rpc_capture_result.rpc_id(sender_id, false, {}, _film_remaining)


## Server -> Clients: Photo capture result
@rpc("authority", "call_remote", "reliable")
func _rpc_capture_result(success: bool, photo_data: Dictionary, film_remaining: int) -> void:
	if success:
		var photo := PhotoRecord.from_network_dict(photo_data)
		# Check for duplicates by UID
		var already_exists: bool = false
		for existing in _photos:
			if existing.uid == photo.uid:
				already_exists = true
				break
		if not already_exists:
			_photos.append(photo)
		photo_captured.emit(photo)
	else:
		photo_missed.emit()

	# Update local film count from authoritative server state
	if not multiplayer.is_server():
		_film_remaining = film_remaining
		film_changed.emit(_film_remaining, MAX_FILM)


## Gets EvidenceManager autoload
func _get_evidence_manager() -> Node:
	if has_node("/root/EvidenceManager"):
		return get_node("/root/EvidenceManager")
	return null
