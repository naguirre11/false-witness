class_name SpectralPrismCalibrator
extends CooperativeEquipment
## Calibrator unit of the Spectral Prism Rig.
##
## The Calibrator is the first-stage operator who aligns spectral filters to
## reveal a pattern shape. The Calibrator can lie about what shape they aligned to.
##
## Trust Dynamic: The Calibrator sees abstract blobs that resolve into shapes
## when aligned. They verbally announce the shape, but no one else can verify
## this directly.

# --- Signals ---

## Emitted when calibration state changes.
signal calibration_state_changed(new_state: CalibrationState)

## Emitted when filter position changes.
signal filter_rotated(filter_index: int, position: int)

## Emitted when all filters are aligned (blobs resolve into shape).
signal alignment_achieved(pattern: int)

## Emitted when alignment is lost (blobs become abstract again).
signal alignment_lost

## Emitted when calibration is locked.
signal calibration_locked(locked_pattern: int)

## Emitted when viewfinder is activated.
signal viewfinder_activated

## Emitted when viewfinder is deactivated.
signal viewfinder_deactivated

# --- Enums ---

## Calibration state machine states.
enum CalibrationState {
	IDLE,  ## Not viewing or calibrating
	VIEWING,  ## Looking through viewfinder, seeing blobs
	ALIGNING,  ## Actively rotating filters
	LOCKED,  ## Calibration locked (cannot re-lock without reset)
}

# --- Constants ---

const PrismEnumsScript := preload("res://src/equipment/spectral_prism/prism_enums.gd")

## Number of filter stages that need alignment.
const FILTER_COUNT := 3

## Number of positions per filter (like a combination lock).
const POSITIONS_PER_FILTER := 8

# --- Export: Calibrator Settings ---

@export_group("Calibrator")
## Maximum range to detect anchor points.
@export var max_anchor_range: float = 15.0

## Whether to require line-of-sight to anchor.
@export var require_line_of_sight: bool = true

## Layers for line-of-sight raycast.
@export_flags_3d_physics var line_of_sight_mask: int = 1

@export_group("Audio Feedback")
## Plays when a filter clicks into position.
@export var filter_click_sound: AudioStream

## Plays when all filters align (harmony tone).
@export var alignment_sound: AudioStream

## Plays when calibration is locked.
@export var lock_sound: AudioStream

# --- State ---

var _calibration_state: CalibrationState = CalibrationState.IDLE
var _current_anchor: Node3D = null
var _filter_positions: Array[int] = [0, 0, 0]
var _target_positions: Array[int] = [0, 0, 0]  # The "correct" alignment
var _locked_pattern: PrismEnumsScript.PrismPattern = PrismEnumsScript.PrismPattern.NONE
var _is_aligned: bool = false


func _ready() -> void:
	equipment_type = EquipmentType.SPECTRAL_PRISM_CALIBRATOR
	equipment_name = "Spectral Prism Calibrator"
	use_mode = UseMode.TOGGLE
	is_primary = true
	_filter_positions = [0, 0, 0]
	_target_positions = [0, 0, 0]


# --- Viewfinder ---


## Activates the viewfinder to begin viewing spectral patterns.
## Requires a valid anchor point in range with line-of-sight.
func activate_viewfinder() -> bool:
	if _calibration_state == CalibrationState.LOCKED:
		return false

	if not has_partner() or not is_partner_in_range():
		return false

	var anchor := _find_anchor_in_range()
	if anchor == null:
		return false

	if require_line_of_sight and not _has_line_of_sight_to(anchor):
		return false

	_current_anchor = anchor
	_generate_target_positions(anchor)
	_set_calibration_state(CalibrationState.VIEWING)
	viewfinder_activated.emit()
	return true


## Deactivates the viewfinder.
func deactivate_viewfinder() -> void:
	if _calibration_state == CalibrationState.LOCKED:
		return

	if _calibration_state in [CalibrationState.VIEWING, CalibrationState.ALIGNING]:
		_set_calibration_state(CalibrationState.IDLE)
		_current_anchor = null
		_is_aligned = false
		viewfinder_deactivated.emit()


## Returns true if viewfinder is currently active.
func is_viewfinder_active() -> bool:
	return _calibration_state in [CalibrationState.VIEWING, CalibrationState.ALIGNING]


# --- Filter Rotation ---


## Rotates a specific filter by the given amount (+1 = clockwise, -1 = counter).
func rotate_filter(filter_index: int, direction: int) -> bool:
	if filter_index < 0 or filter_index >= FILTER_COUNT:
		return false

	if _calibration_state not in [CalibrationState.VIEWING, CalibrationState.ALIGNING]:
		return false

	if _calibration_state == CalibrationState.VIEWING:
		_set_calibration_state(CalibrationState.ALIGNING)

	# Rotate with wrap-around
	var new_pos: int = (_filter_positions[filter_index] + direction) % POSITIONS_PER_FILTER
	if new_pos < 0:
		new_pos += POSITIONS_PER_FILTER

	_filter_positions[filter_index] = new_pos
	filter_rotated.emit(filter_index, new_pos)

	_check_alignment()
	return true


## Rotates all filters at once (for quick adjustment).
func rotate_all_filters(direction: int) -> void:
	for i in range(FILTER_COUNT):
		rotate_filter(i, direction)


## Gets the current position of a filter (0 to POSITIONS_PER_FILTER - 1).
func get_filter_position(filter_index: int) -> int:
	if filter_index < 0 or filter_index >= FILTER_COUNT:
		return -1
	return _filter_positions[filter_index]


## Gets all current filter positions.
func get_all_filter_positions() -> Array[int]:
	return _filter_positions.duplicate()


## Returns the number of filters.
func get_filter_count() -> int:
	return FILTER_COUNT


## Returns positions per filter.
func get_positions_per_filter() -> int:
	return POSITIONS_PER_FILTER


# --- Alignment ---


## Returns true if all filters are currently aligned with the anchor's pattern.
func is_aligned() -> bool:
	return _is_aligned


## Returns the pattern currently being displayed (NONE if not aligned).
func get_current_pattern() -> PrismEnumsScript.PrismPattern:
	if not _is_aligned or _current_anchor == null:
		return PrismEnumsScript.PrismPattern.NONE
	return _get_anchor_pattern(_current_anchor)


## Returns alignment progress (0.0 to 1.0).
func get_alignment_progress() -> float:
	var correct_count := 0
	for i in range(FILTER_COUNT):
		if _filter_positions[i] == _target_positions[i]:
			correct_count += 1
	return float(correct_count) / float(FILTER_COUNT)


# --- Lock Action ---


## Locks the calibration at the current filter position.
## Returns true if lock was successful.
func lock_calibration() -> bool:
	if _calibration_state == CalibrationState.LOCKED:
		return false

	if _calibration_state not in [CalibrationState.VIEWING, CalibrationState.ALIGNING]:
		return false

	# Capture the pattern at lock time
	# If aligned, capture the true pattern; if not aligned, capture NONE
	if _is_aligned:
		_locked_pattern = get_current_pattern()
	else:
		_locked_pattern = PrismEnumsScript.PrismPattern.NONE

	_set_calibration_state(CalibrationState.LOCKED)
	calibration_locked.emit(_locked_pattern)

	# Notify partner (Lens Reader)
	if has_partner():
		var partner := get_partner()
		if partner.has_method("on_calibration_locked"):
			partner.on_calibration_locked(_locked_pattern)

	return true


## Returns the pattern that was locked (may differ from true pattern if misaligned).
func get_locked_pattern() -> PrismEnumsScript.PrismPattern:
	return _locked_pattern


## Returns true if calibration was locked at the correct alignment.
func is_properly_aligned() -> bool:
	if _calibration_state != CalibrationState.LOCKED:
		return false
	if _current_anchor == null:
		return false
	return _locked_pattern == _get_anchor_pattern(_current_anchor)


# --- Reset ---


## Resets the calibrator to start over.
func reset_calibration() -> void:
	_calibration_state = CalibrationState.IDLE
	_current_anchor = null
	_filter_positions = [0, 0, 0]
	_locked_pattern = PrismEnumsScript.PrismPattern.NONE
	_is_aligned = false
	calibration_state_changed.emit(CalibrationState.IDLE)


# --- State ---


## Returns the current calibration state.
func get_calibration_state() -> CalibrationState:
	return _calibration_state


## Returns the current anchor (if any).
func get_current_anchor() -> Node3D:
	return _current_anchor


# --- Internal: State Machine ---


func _set_calibration_state(new_state: CalibrationState) -> void:
	if _calibration_state != new_state:
		_calibration_state = new_state
		calibration_state_changed.emit(new_state)


# --- Internal: Alignment Detection ---


func _check_alignment() -> void:
	var was_aligned := _is_aligned
	_is_aligned = _are_filters_aligned()

	if _is_aligned and not was_aligned:
		var pattern := get_current_pattern()
		alignment_achieved.emit(pattern)
	elif not _is_aligned and was_aligned:
		alignment_lost.emit()


func _are_filters_aligned() -> bool:
	for i in range(FILTER_COUNT):
		if _filter_positions[i] != _target_positions[i]:
			return false
	return true


# --- Internal: Anchor Detection ---


func _find_anchor_in_range() -> Node3D:
	# Find all SpectralAnchors in range
	var anchors := get_tree().get_nodes_in_group("spectral_anchors")

	var best_anchor: Node3D = null
	var best_distance := INF

	for node in anchors:
		if not node is Node3D:
			continue

		var anchor := node as Node3D
		var distance := _get_distance_to(anchor)

		if distance <= max_anchor_range and distance < best_distance:
			best_anchor = anchor
			best_distance = distance

	return best_anchor


func _get_distance_to(target: Node3D) -> float:
	var my_pos := _get_equipment_position()
	var target_pos: Vector3

	if target.is_inside_tree():
		target_pos = target.global_position
	else:
		target_pos = target.position

	return my_pos.distance_to(target_pos)


func _has_line_of_sight_to(target: Node3D) -> bool:
	if not is_inside_tree():
		return true  # Skip check if not in tree (for testing)

	var space_state := get_world_3d().direct_space_state
	if space_state == null:
		return true

	var from := _get_equipment_position()
	var to: Vector3
	if target.is_inside_tree():
		to = target.global_position
	else:
		to = target.position

	var query := PhysicsRayQueryParameters3D.create(from, to, line_of_sight_mask)
	query.exclude = [self]

	var result := space_state.intersect_ray(query)

	# Clear line of sight if we hit nothing, or if we hit the target itself
	if result.is_empty():
		return true

	var collider: Object = result.get("collider")
	return collider == target


func _generate_target_positions(anchor: Node3D) -> void:
	# Generate pseudo-random but deterministic target positions based on anchor
	# This ensures the "correct" alignment is consistent for the same anchor
	var pattern := _get_anchor_pattern(anchor)
	var seed_value: int = pattern  # Use pattern enum value as seed

	# Simple hash-based position generation
	for i in range(FILTER_COUNT):
		_target_positions[i] = (seed_value * (i + 1) * 7) % POSITIONS_PER_FILTER


func _get_anchor_pattern(anchor: Node3D) -> PrismEnumsScript.PrismPattern:
	if anchor == null:
		return PrismEnumsScript.PrismPattern.NONE

	if anchor.has_method("get_true_pattern"):
		return anchor.get_true_pattern()

	# Fallback: check for property
	if "true_pattern" in anchor:
		return anchor.true_pattern

	return PrismEnumsScript.PrismPattern.NONE


# --- Equipment Overrides ---


func _use_impl() -> void:
	super._use_impl()
	activate_viewfinder()


func _stop_using_impl() -> void:
	super._stop_using_impl()
	deactivate_viewfinder()


func _can_use_impl(player: Node) -> bool:
	if not super._can_use_impl(player):
		return false

	# If already locked, cannot use again
	if _calibration_state == CalibrationState.LOCKED:
		return false

	return true


func get_detectable_evidence() -> Array[String]:
	return ["spectral_pattern"]


func get_network_state() -> Dictionary:
	var state := super.get_network_state()
	state["calibration_state"] = _calibration_state
	state["filter_positions"] = _filter_positions.duplicate()
	state["locked_pattern"] = _locked_pattern
	state["is_aligned"] = _is_aligned
	return state


func apply_network_state(state: Dictionary) -> void:
	super.apply_network_state(state)
	if state.has("calibration_state"):
		_calibration_state = state.calibration_state as CalibrationState
	if state.has("filter_positions"):
		var positions: Array = state.filter_positions
		_filter_positions = [positions[0] as int, positions[1] as int, positions[2] as int]
	if state.has("locked_pattern"):
		_locked_pattern = state.locked_pattern as PrismEnumsScript.PrismPattern
	if state.has("is_aligned"):
		_is_aligned = state.is_aligned
