class_name GhostWritingBook
extends Equipment
## Ghost Writing Book - Triggered Test Equipment
##
## A placeable journal that entities can write in. Players place the book in
## the entity's anchor room and wait for writing to appear.
##
## Trust Dynamic: SABOTAGE_RISK - The book can be moved, removed, or checked
## too early by a Cultist to corrupt the evidence.
##
## Sabotage Vectors:
## - Wrong Room: Cultist moves book to incorrect room
## - Book Removal: Cultist picks up book before writing occurs
## - False Positive: Cultist claims writing when book is blank
## - Timing Manipulation: Cultist retrieves book too early, claims "no writing"
##
## Counter-Strategy: Buddy system - one player places, another watches.

# --- Signals ---

## Emitted when book state changes.
signal book_state_changed(new_state: BookState)

## Emitted when book is placed in the world.
signal book_placed(location: Vector3, placer_id: int)

## Emitted when book is picked up from the world.
signal book_picked_up(picker_id: int)

## Emitted when book is moved by someone other than original placer.
signal book_moved(mover_id: int, from_pos: Vector3, to_pos: Vector3)

## Emitted when writing begins appearing.
signal writing_started

## Emitted when writing is complete and visible.
signal writing_completed(writing_style: WritingStyle)

## Emitted when book is checked (examined for writing).
signal book_checked(checker_id: int, has_writing: bool)

## Emitted when evidence is collected from the book.
signal evidence_collected_from_book(evidence_type: int, quality: int)

# --- Enums ---

## Book state machine states.
enum BookState {
	HELD,  ## In player's inventory/hand
	PLACED,  ## Placed in world, waiting for entity
	WRITING,  ## Entity is actively writing
	WRITTEN,  ## Writing complete, visible to players
	CHECKED,  ## Book has been checked, evidence recorded
}

## Writing style determines evidence quality and entity hints.
enum WritingStyle {
	NONE,  ## No writing (entity doesn't have ghost writing)
	CRUDE_SCRAWLS,  ## Basic confirmation of entity
	SYMBOLS,  ## Entity category hints
	WORDS,  ## Strong entity identification
}

# --- Constants ---

## Minimum time book must be placed before entity can write (seconds).
const MIN_PLACEMENT_TIME := 30.0

## Maximum time to wait before declaring negative evidence (seconds).
const MAX_WAIT_TIME := 120.0

## Time it takes for entity to complete writing (seconds).
const WRITING_DURATION := 3.0

## Interval for checking if writing should occur (seconds).
const WRITE_CHECK_INTERVAL := 1.0

# --- Export: Book Settings ---

@export_group("Book Settings")
## Maximum range for placement raycast.
@export var placement_range: float = 2.5

## Minimum placement time can be configured for testing.
@export var min_placement_time: float = MIN_PLACEMENT_TIME

## Maximum wait time can be configured for testing.
@export var max_wait_time: float = MAX_WAIT_TIME

@export_group("Audio Feedback")
## Sound when book is placed.
@export var place_sound: AudioStream

## Sound when writing appears.
@export var writing_sound: AudioStream

## Sound when book is picked up.
@export var pickup_sound: AudioStream

# --- State ---

var _book_state: BookState = BookState.HELD
var _placed_position: Vector3 = Vector3.ZERO
var _placed_time: float = 0.0
var _writing_progress: float = 0.0
var _current_writing_style: WritingStyle = WritingStyle.NONE
var _write_check_timer: float = 0.0
var _placed_visual: Node3D = null

## Tracking for sabotage detection
var _original_placer_id: int = 0
var _setup_witness_id: int = 0
var _result_witness_id: int = 0
var _was_moved: bool = false
var _move_history: Array[Dictionary] = []  # [{mover_id, from, to, time}]

## Room tracking
var _placed_room_id: String = ""
var _entity_room_id: String = ""

## Evidence collection state
var _evidence_uid: String = ""
var _has_collected_evidence: bool = false


func _ready() -> void:
	equipment_type = EquipmentType.GHOST_WRITING_BOOK
	equipment_name = "Ghost Writing Book"
	use_mode = UseMode.INSTANT


func _process(delta: float) -> void:
	super._process(delta)

	match _book_state:
		BookState.PLACED:
			_process_placed_state(delta)
		BookState.WRITING:
			_process_writing_state(delta)


# --- State Machine Processing ---


func _process_placed_state(delta: float) -> void:
	_write_check_timer += delta

	if _write_check_timer >= WRITE_CHECK_INTERVAL:
		_write_check_timer = 0.0
		_check_for_entity_writing()


func _process_writing_state(delta: float) -> void:
	_writing_progress += delta

	if _writing_progress >= WRITING_DURATION:
		_complete_writing()


func _check_for_entity_writing() -> void:
	if _book_state != BookState.PLACED:
		return

	var time_placed := _get_time_since_placement()
	if time_placed < min_placement_time:
		return

	var entity := _find_entity_in_room()
	if entity == null:
		return

	if not _entity_can_write(entity):
		return

	if not _is_book_in_entity_room(entity):
		return

	_start_writing(entity)


func _start_writing(entity: Node) -> void:
	_writing_progress = 0.0
	_current_writing_style = _determine_writing_style(entity)
	_set_book_state(BookState.WRITING)
	writing_started.emit()


func _complete_writing() -> void:
	_set_book_state(BookState.WRITTEN)
	writing_completed.emit(_current_writing_style)


# --- Public API: Placement ---


## Places the book at the given location. Returns true if successful.
func place_book(location: Vector3, placer_id: int) -> bool:
	if _book_state != BookState.HELD:
		return false

	_placed_position = location
	_placed_time = Time.get_ticks_msec() / 1000.0
	_original_placer_id = placer_id
	_was_moved = false
	_move_history.clear()
	_current_writing_style = WritingStyle.NONE
	_writing_progress = 0.0
	_write_check_timer = 0.0
	_has_collected_evidence = false
	_evidence_uid = ""

	# Determine which room the book is in
	_placed_room_id = _get_room_at_position(location)

	# Create visual representation
	_placed_visual = _create_placed_visual()
	if _placed_visual:
		_placed_visual.global_position = location
		_add_to_world(_placed_visual)

	_set_book_state(BookState.PLACED)
	book_placed.emit(location, placer_id)

	_emit_placement_to_event_bus(location)

	return true


## Picks up the book from its placed position. Returns true if successful.
func pickup_book(picker_id: int) -> bool:
	if _book_state == BookState.HELD:
		return false

	var old_state := _book_state

	# Track if someone other than the placer picks up
	if picker_id != _original_placer_id and old_state == BookState.PLACED:
		_record_move(picker_id, _placed_position, Vector3.ZERO)

	# Clean up visual
	if _placed_visual and is_instance_valid(_placed_visual):
		_placed_visual.queue_free()
		_placed_visual = null

	_set_book_state(BookState.HELD)
	book_picked_up.emit(picker_id)

	return true


## Moves the book to a new location. Records as potential sabotage.
func move_book(mover_id: int, new_location: Vector3) -> bool:
	if _book_state == BookState.HELD:
		return false

	var old_position := _placed_position

	# Track move for sabotage detection
	if mover_id != _original_placer_id:
		_record_move(mover_id, old_position, new_location)
		_was_moved = true

	_placed_position = new_location
	_placed_room_id = _get_room_at_position(new_location)

	# Update visual position
	if _placed_visual and is_instance_valid(_placed_visual):
		_placed_visual.global_position = new_location

	book_moved.emit(mover_id, old_position, new_location)

	return true


## Registers a witness to the book setup.
func register_setup_witness(witness_id: int) -> void:
	if witness_id != _original_placer_id:
		_setup_witness_id = witness_id


## Registers a witness to checking the book result.
func register_result_witness(witness_id: int) -> void:
	if witness_id != _original_placer_id:
		_result_witness_id = witness_id


# --- Public API: Checking the Book ---


## Checks the book for writing. Returns the evidence if writing was found.
func check_book(checker_id: int) -> Dictionary:
	# Register checker as result witness FIRST if not the placer
	# This way quality calculation includes the checker as witness
	if checker_id != _original_placer_id:
		register_result_witness(checker_id)

	var result := {
		"has_writing": _book_state == BookState.WRITTEN,
		"writing_style": _current_writing_style,
		"time_placed": _get_time_since_placement(),
		"was_moved": _was_moved,
		"quality": EvidenceEnums.ReadingQuality.WEAK,
	}

	if _book_state == BookState.WRITTEN:
		result["quality"] = _calculate_evidence_quality()
	elif _book_state == BookState.PLACED:
		# No writing yet - could be negative evidence if waited long enough
		if _get_time_since_placement() >= max_wait_time:
			result["is_negative_evidence"] = true

	book_checked.emit(checker_id, result.has_writing)

	return result


## Collects evidence from the book. Can only be done once per placement.
func collect_evidence(collector_id: int) -> Evidence:
	if _has_collected_evidence:
		return null

	var check_result := check_book(collector_id)

	if not check_result.has_writing and not check_result.get("is_negative_evidence", false):
		return null

	var evidence_manager := _get_evidence_manager()
	if evidence_manager == null:
		return null

	var quality: EvidenceEnums.ReadingQuality = check_result.quality
	var evidence: Evidence = evidence_manager.collect_evidence(
		EvidenceEnums.EvidenceType.GHOST_WRITING,
		collector_id,
		_placed_position,
		quality,
		equipment_name
	)

	if evidence:
		_apply_sabotage_flags(evidence)
		_apply_witness_info(evidence)
		_evidence_uid = evidence.uid
		_has_collected_evidence = true
		_set_book_state(BookState.CHECKED)
		evidence_collected_from_book.emit(evidence.type, evidence.quality)

	return evidence


# --- Public API: State Queries ---


## Returns the current book state.
func get_book_state() -> BookState:
	return _book_state


## Returns true if book has writing.
func has_writing() -> bool:
	return _book_state == BookState.WRITTEN or _book_state == BookState.CHECKED


## Returns the current writing style.
func get_writing_style() -> WritingStyle:
	return _current_writing_style


## Returns the placed position (only valid if placed).
func get_placed_position() -> Vector3:
	return _placed_position


## Returns time since book was placed (seconds).
func get_time_since_placement() -> float:
	return _get_time_since_placement()


## Returns true if the book was moved after placement.
func was_moved() -> bool:
	return _was_moved


## Returns the move history for sabotage analysis.
func get_move_history() -> Array[Dictionary]:
	return _move_history.duplicate()


## Returns true if setup was witnessed.
func has_setup_witness() -> bool:
	return _setup_witness_id != 0


## Returns true if result check was witnessed.
func has_result_witness() -> bool:
	return _result_witness_id != 0


## Returns the original placer's ID.
func get_placer_id() -> int:
	return _original_placer_id


## Returns writing progress (0.0 to 1.0) during WRITING state.
func get_writing_progress() -> float:
	if _book_state != BookState.WRITING:
		return 0.0 if _book_state == BookState.PLACED else 1.0
	return clampf(_writing_progress / WRITING_DURATION, 0.0, 1.0)


# --- Equipment Overrides ---


func _use_impl() -> void:
	if _book_state == BookState.HELD:
		# Place the book
		var place_location := _get_placement_location()
		if place_location != Vector3.ZERO:
			var placer_id := _get_player_id(_owning_player)
			place_book(place_location, placer_id)
	else:
		# Pick up the book
		var picker_id := _get_player_id(_owning_player)
		pickup_book(picker_id)


func _can_use_impl(_player: Node) -> bool:
	return true  # Can always use to place or pick up


func get_detectable_evidence() -> Array[String]:
	return ["ghost_writing"]


func get_network_state() -> Dictionary:
	var state := super.get_network_state()
	state["book_state"] = _book_state
	state["placed_position"] = {
		"x": _placed_position.x,
		"y": _placed_position.y,
		"z": _placed_position.z,
	}
	state["placed_time"] = _placed_time
	state["writing_style"] = _current_writing_style
	state["writing_progress"] = _writing_progress
	state["original_placer_id"] = _original_placer_id
	state["was_moved"] = _was_moved
	state["setup_witness_id"] = _setup_witness_id
	state["result_witness_id"] = _result_witness_id
	state["placed_room_id"] = _placed_room_id
	state["has_collected_evidence"] = _has_collected_evidence
	return state


func apply_network_state(state: Dictionary) -> void:
	super.apply_network_state(state)
	if state.has("book_state"):
		_book_state = state.book_state as BookState
	if state.has("placed_position"):
		var pos: Dictionary = state.placed_position
		_placed_position = Vector3(pos.x, pos.y, pos.z)
	if state.has("placed_time"):
		_placed_time = state.placed_time
	if state.has("writing_style"):
		_current_writing_style = state.writing_style as WritingStyle
	if state.has("writing_progress"):
		_writing_progress = state.writing_progress
	if state.has("original_placer_id"):
		_original_placer_id = state.original_placer_id
	if state.has("was_moved"):
		_was_moved = state.was_moved
	if state.has("setup_witness_id"):
		_setup_witness_id = state.setup_witness_id
	if state.has("result_witness_id"):
		_result_witness_id = state.result_witness_id
	if state.has("placed_room_id"):
		_placed_room_id = state.placed_room_id
	if state.has("has_collected_evidence"):
		_has_collected_evidence = state.has_collected_evidence


# --- Internal: State Management ---


func _set_book_state(new_state: BookState) -> void:
	if _book_state != new_state:
		_book_state = new_state
		book_state_changed.emit(new_state)


# --- Internal: Entity Detection ---


func _find_entity_in_room() -> Node:
	var entities := get_tree().get_nodes_in_group("entities")
	for entity in entities:
		if not entity is Node3D:
			continue
		if _is_entity_active(entity):
			return entity
	return null


func _entity_can_write(entity: Node) -> bool:
	# Check if entity has ghost writing capability
	if entity.has_method("has_evidence_type"):
		return entity.has_evidence_type(EvidenceEnums.EvidenceType.GHOST_WRITING)

	# Fallback: check property
	if "evidence_types" in entity:
		var types: Array = entity.evidence_types
		return EvidenceEnums.EvidenceType.GHOST_WRITING in types

	# Fallback: check for explicit can_write property
	if "can_ghost_write" in entity:
		return entity.can_ghost_write

	return true  # Default: assume entity can write


func _is_entity_active(entity: Node) -> bool:
	if entity.has_method("is_active"):
		return entity.is_active()
	if "is_dormant" in entity:
		return not entity.is_dormant
	return true


func _is_book_in_entity_room(entity: Node) -> bool:
	var entity_room := _get_entity_anchor_room(entity)
	if entity_room.is_empty():
		return true  # If no room system, assume correct room

	_entity_room_id = entity_room
	return _placed_room_id == entity_room


func _get_entity_anchor_room(entity: Node) -> String:
	if entity.has_method("get_anchor_room_id"):
		return entity.get_anchor_room_id()
	if "anchor_room_id" in entity:
		return entity.anchor_room_id
	return ""


func _determine_writing_style(entity: Node) -> WritingStyle:
	# Entity can specify writing style
	if entity.has_method("get_ghost_writing_style"):
		return entity.get_ghost_writing_style()

	# Fallback: use entity activity level or random
	var styles := [WritingStyle.CRUDE_SCRAWLS, WritingStyle.SYMBOLS, WritingStyle.WORDS]
	return styles[randi() % styles.size()]


# --- Internal: Room Detection ---


func _get_room_at_position(pos: Vector3) -> String:
	# Find rooms via group
	var rooms := get_tree().get_nodes_in_group("rooms")
	for room in rooms:
		if not room is Node3D:
			continue
		if room.has_method("contains_point"):
			if room.contains_point(pos):
				return room.name if "name" in room else str(room.get_path())
		elif room.has_method("get_room_id"):
			# Simplified check: use room position and size
			var room_pos: Vector3 = room.global_position if room.is_inside_tree() else room.position
			var distance := pos.distance_to(room_pos)
			if distance < 10.0:  # Rough proximity check
				return room.get_room_id()
	return ""


# --- Internal: Evidence Quality ---


func _calculate_evidence_quality() -> EvidenceEnums.ReadingQuality:
	# Strong quality requires:
	# - No sabotage (book wasn't moved)
	# - Proper buddy system (both witnesses present)
	# - Writing is clear (not just crude scrawls)

	if _was_moved:
		return EvidenceEnums.ReadingQuality.WEAK

	if _setup_witness_id == 0 or _result_witness_id == 0:
		return EvidenceEnums.ReadingQuality.WEAK

	if _current_writing_style == WritingStyle.CRUDE_SCRAWLS:
		return EvidenceEnums.ReadingQuality.WEAK

	return EvidenceEnums.ReadingQuality.STRONG


func _apply_sabotage_flags(evidence: Evidence) -> void:
	if _was_moved:
		evidence.set_sabotage_flag("book_moved", true)

	if _placed_room_id != _entity_room_id and not _entity_room_id.is_empty():
		evidence.set_sabotage_flag("wrong_room", true)

	# Record move history in metadata
	if not _move_history.is_empty():
		evidence.set_verification_meta("move_history", _move_history.duplicate())


func _apply_witness_info(evidence: Evidence) -> void:
	evidence.setup_witness_id = _setup_witness_id
	evidence.result_witness_id = _result_witness_id

	if _setup_witness_id == 0 or _result_witness_id == 0:
		evidence.set_verification_meta("single_witness", true)


# --- Internal: Sabotage Tracking ---


func _record_move(mover_id: int, from_pos: Vector3, to_pos: Vector3) -> void:
	var move_record := {
		"mover_id": mover_id,
		"from": {"x": from_pos.x, "y": from_pos.y, "z": from_pos.z},
		"to": {"x": to_pos.x, "y": to_pos.y, "z": to_pos.z},
		"time": Time.get_ticks_msec() / 1000.0,
	}
	_move_history.append(move_record)
	_was_moved = true


func _get_time_since_placement() -> float:
	if _book_state == BookState.HELD:
		return 0.0
	var current_time := Time.get_ticks_msec() / 1000.0
	return current_time - _placed_time


# --- Internal: Placement ---


func _get_placement_location() -> Vector3:
	if not _owning_player:
		return Vector3.ZERO

	var camera: Camera3D = _get_player_camera()
	if not camera:
		return Vector3.ZERO

	var space_state := camera.get_world_3d().direct_space_state
	if not space_state:
		return Vector3.ZERO

	var from := camera.global_position
	var to := from + (-camera.global_transform.basis.z * placement_range)

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1  # World layer only
	if _owning_player is CollisionObject3D:
		query.exclude = [_owning_player]

	var result := space_state.intersect_ray(query)
	if result:
		# Check if surface is horizontal enough for book placement
		var normal: Vector3 = result.get("normal", Vector3.UP)
		if normal.dot(Vector3.UP) > 0.7:  # Must be relatively flat
			return result.position

	return Vector3.ZERO


func _get_player_camera() -> Camera3D:
	if _owning_player and _owning_player.has_node("Head/Camera3D"):
		return _owning_player.get_node("Head/Camera3D") as Camera3D
	return null


func _create_placed_visual() -> Node3D:
	# Create a simple visual placeholder for the placed book
	# In production, this would load a proper scene
	var visual := Node3D.new()
	visual.name = "PlacedGhostWritingBook"
	visual.add_to_group("placed_equipment")
	visual.add_to_group("ghost_writing_books")
	return visual


func _add_to_world(node: Node3D) -> void:
	var tree := get_tree()
	if tree and tree.current_scene:
		tree.current_scene.add_child(node)


func _emit_placement_to_event_bus(location: Vector3) -> void:
	var event_bus := _get_event_bus()
	if event_bus and event_bus.has_signal("protection_item_placed"):
		# Reuse protection item signal for equipment placement
		event_bus.protection_item_placed.emit(equipment_name, location)


func _get_evidence_manager() -> Node:
	if has_node("/root/EvidenceManager"):
		return get_node("/root/EvidenceManager")
	return null
