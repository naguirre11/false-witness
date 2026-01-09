class_name SpectralPrismLensReader
extends CooperativeEquipment
## Lens Reader unit of the Spectral Prism Rig.
##
## The Lens Reader is the second-stage operator who reads the entity signature
## after the Calibrator locks alignment. The Lens Reader sees both pattern (shape)
## and color, and can verify consistency between them.
##
## Trust Dynamic: The Lens Reader sees a pattern (shape + color) through the
## eyepiece. They verbally announce what they see, but no one else can verify
## this directly. This makes PRISM_READING evidence LOW trust.

# --- Signals ---

## Emitted when reader state changes.
signal reader_state_changed(new_state: ReaderState)

## Emitted when calibration data is received from partner.
signal calibration_received(pattern: int)

## Emitted when eyepiece is activated.
signal eyepiece_activated

## Emitted when eyepiece is deactivated.
signal eyepiece_deactivated

## Emitted when a reading is recorded.
signal reading_recorded(evidence_uid: String)

## Emitted when reading quality changes.
signal quality_changed(new_quality: int)

# --- Enums ---

## Reader state machine states.
enum ReaderState {
	IDLE,  ## Not active, waiting for calibration
	WAITING,  ## Calibration not yet locked
	VIEWING,  ## Eyepiece active, seeing pattern/color
	READING,  ## Recording the reading
}

# --- Constants ---

const PrismEnumsScript := preload("res://src/equipment/spectral_prism/prism_enums.gd")

## Minimum viewing time (seconds) before recording is allowed.
const MIN_VIEWING_TIME := 1.0

## Viewing time threshold for strong quality (seconds).
const STRONG_QUALITY_TIME := 3.0

## Movement threshold - above this speed, quality degrades.
const MOVEMENT_THRESHOLD := 0.5

# --- Export: Lens Reader Settings ---

@export_group("Lens Reader")
## Time required to record a reading (seconds).
@export var reading_duration: float = 2.0

## Whether movement during reading degrades quality.
@export var movement_affects_quality: bool = true

@export_group("Audio Feedback")
## Plays when eyepiece activates.
@export var eyepiece_activate_sound: AudioStream

## Plays when reading starts.
@export var reading_start_sound: AudioStream

## Plays when reading completes.
@export var reading_complete_sound: AudioStream

# --- State ---

var _reader_state: ReaderState = ReaderState.IDLE
var _received_pattern: PrismEnumsScript.PrismPattern = PrismEnumsScript.PrismPattern.NONE
var _calibration_locked: bool = false
var _calibrator_aligned: bool = false
var _viewing_start_time: float = 0.0
var _reading_progress: float = 0.0
var _last_position: Vector3 = Vector3.ZERO
var _total_movement: float = 0.0
var _current_quality: EvidenceEnums.ReadingQuality = EvidenceEnums.ReadingQuality.STRONG
var _last_evidence_uid: String = ""


func _ready() -> void:
	equipment_type = EquipmentType.SPECTRAL_PRISM_LENS
	equipment_name = "Spectral Prism Lens Reader"
	use_mode = UseMode.TOGGLE
	is_primary = false  # Secondary piece to Calibrator


func _process(delta: float) -> void:
	super._process(delta)

	if _reader_state == ReaderState.VIEWING:
		_track_movement(delta)

	if _reader_state == ReaderState.READING:
		_update_reading_progress(delta)


# --- Calibration Callback ---


## Called by the partner Calibrator when calibration is locked.
## This is the trigger that allows the Lens Reader to activate.
func on_calibration_locked(locked_pattern: int) -> void:
	_received_pattern = locked_pattern as PrismEnumsScript.PrismPattern
	_calibration_locked = true

	# Check if calibrator was properly aligned
	_calibrator_aligned = _check_calibrator_alignment()

	calibration_received.emit(locked_pattern)

	# If we were waiting, we can now proceed
	if _reader_state == ReaderState.WAITING:
		_set_reader_state(ReaderState.IDLE)


## Returns true if calibration has been received from partner.
func has_calibration() -> bool:
	return _calibration_locked


## Returns the received pattern from calibration.
func get_received_pattern() -> PrismEnumsScript.PrismPattern:
	return _received_pattern


# --- Eyepiece ---


## Activates the eyepiece to view the entity signature.
## Requires calibration to be locked first.
func activate_eyepiece() -> bool:
	if not _calibration_locked:
		if _reader_state != ReaderState.WAITING:
			_set_reader_state(ReaderState.WAITING)
		return false

	if not has_partner() or not is_partner_in_range():
		return false

	_set_reader_state(ReaderState.VIEWING)
	_viewing_start_time = Time.get_ticks_msec() / 1000.0
	_total_movement = 0.0
	_last_position = _get_equipment_position()
	_update_quality()

	eyepiece_activated.emit()
	return true


## Deactivates the eyepiece.
func deactivate_eyepiece() -> void:
	if _reader_state in [ReaderState.VIEWING, ReaderState.READING]:
		_set_reader_state(ReaderState.IDLE)
		_reading_progress = 0.0
		eyepiece_deactivated.emit()


## Returns true if eyepiece is currently active.
func is_eyepiece_active() -> bool:
	return _reader_state in [ReaderState.VIEWING, ReaderState.READING]


# --- Pattern Reading ---


## Returns the pattern shape seen through eyepiece (from Calibrator lock).
func get_pattern_shape() -> PrismEnumsScript.PrismPattern:
	if not is_eyepiece_active():
		return PrismEnumsScript.PrismPattern.NONE
	return _received_pattern


## Returns the pattern color seen through eyepiece (from entity).
func get_pattern_color() -> PrismEnumsScript.PrismColor:
	if not is_eyepiece_active():
		return PrismEnumsScript.PrismColor.NONE

	var anchor := _get_anchor_from_calibrator()
	if anchor == null:
		return PrismEnumsScript.PrismColor.NONE

	return anchor.get_true_color()


## Returns the combined signature description.
func get_combined_signature() -> String:
	var shape := get_pattern_shape()
	var color := get_pattern_color()

	if shape == PrismEnumsScript.PrismPattern.NONE:
		return "No pattern visible"

	if color == PrismEnumsScript.PrismColor.NONE:
		return PrismEnumsScript.get_pattern_name(shape) + " (no color)"

	return "%s %s" % [
		PrismEnumsScript.get_color_name(color),
		PrismEnumsScript.get_pattern_name(shape)
	]


## Returns true if the pattern shape matches the color category.
## An inconsistency suggests either misalignment or deception.
func is_consistent() -> bool:
	var shape := get_pattern_shape()
	var color := get_pattern_color()
	return PrismEnumsScript.is_consistent(shape, color)


## Returns the entity category indicated by the color.
func get_indicated_category() -> PrismEnumsScript.EntityCategory:
	var color := get_pattern_color()
	return PrismEnumsScript.get_category_from_color(color)


# --- Evidence Collection ---


## Starts recording a reading. Returns true if recording started.
func start_reading() -> bool:
	if _reader_state != ReaderState.VIEWING:
		return false

	# Check minimum viewing time
	var viewing_time := _get_viewing_time()
	if viewing_time < MIN_VIEWING_TIME:
		return false

	_set_reader_state(ReaderState.READING)
	_reading_progress = 0.0
	return true


## Returns true if currently recording a reading.
func is_reading() -> bool:
	return _reader_state == ReaderState.READING


## Returns reading progress (0.0 to 1.0).
func get_reading_progress() -> float:
	return _reading_progress


## Cancels the current reading.
func cancel_reading() -> void:
	if _reader_state == ReaderState.READING:
		_set_reader_state(ReaderState.VIEWING)
		_reading_progress = 0.0


## Returns the current reading quality.
func get_current_quality() -> EvidenceEnums.ReadingQuality:
	return _current_quality


# --- Internal: State Machine ---


func _set_reader_state(new_state: ReaderState) -> void:
	if _reader_state != new_state:
		_reader_state = new_state
		reader_state_changed.emit(new_state)


## Returns the current reader state.
func get_reader_state() -> ReaderState:
	return _reader_state


# --- Internal: Quality Assessment ---


func _update_quality() -> void:
	var old_quality := _current_quality
	_current_quality = _calculate_quality()

	if _current_quality != old_quality:
		quality_changed.emit(_current_quality)


func _calculate_quality() -> EvidenceEnums.ReadingQuality:
	# Start with assumption of strong quality
	var is_strong := true

	# Factor 1: Calibrator alignment
	if not _calibrator_aligned:
		is_strong = false

	# Factor 2: Viewing time
	var viewing_time := _get_viewing_time()
	if viewing_time < STRONG_QUALITY_TIME:
		is_strong = false

	# Factor 3: Movement during viewing
	if movement_affects_quality and _total_movement > MOVEMENT_THRESHOLD:
		is_strong = false

	if is_strong:
		return EvidenceEnums.ReadingQuality.STRONG
	return EvidenceEnums.ReadingQuality.WEAK


func _get_viewing_time() -> float:
	if _viewing_start_time <= 0.0:
		return 0.0
	var current_time := Time.get_ticks_msec() / 1000.0
	return current_time - _viewing_start_time


func _track_movement(_delta: float) -> void:
	var current_pos := _get_equipment_position()
	var movement := current_pos.distance_to(_last_position)
	_total_movement += movement
	_last_position = current_pos

	# Periodically update quality
	_update_quality()


# --- Internal: Reading Progress ---


func _update_reading_progress(delta: float) -> void:
	_reading_progress += delta / reading_duration

	if _reading_progress >= 1.0:
		_reading_progress = 1.0
		_complete_reading()


func _complete_reading() -> void:
	# Create evidence
	var evidence := _create_evidence()
	if evidence:
		_last_evidence_uid = evidence.uid
		reading_recorded.emit(evidence.uid)

	_set_reader_state(ReaderState.IDLE)
	_reading_progress = 0.0


func _create_evidence() -> Evidence:
	var evidence_manager := _get_evidence_manager()
	if evidence_manager == null:
		push_warning("[LensReader] EvidenceManager not available")
		return null

	var calibrator_id := _get_calibrator_player_id()
	var reader_id := _get_reader_player_id()
	var location := _get_equipment_position()

	return evidence_manager.collect_cooperative_evidence(
		EvidenceEnums.EvidenceType.PRISM_READING,
		calibrator_id,
		reader_id,
		location,
		_current_quality,
		"Spectral Prism Rig"
	)


func _get_evidence_manager() -> Node:
	if has_node("/root/EvidenceManager"):
		return get_node("/root/EvidenceManager")
	return null


func _get_calibrator_player_id() -> int:
	if _partner and _partner._owning_player:
		if _partner._owning_player.has_method("get_player_id"):
			return _partner._owning_player.get_player_id()
		if "player_id" in _partner._owning_player:
			return _partner._owning_player.player_id
	return 0


func _get_reader_player_id() -> int:
	if _owning_player:
		if _owning_player.has_method("get_player_id"):
			return _owning_player.get_player_id()
		if "player_id" in _owning_player:
			return _owning_player.player_id
	return 0


# --- Internal: Calibrator Access ---


func _get_anchor_from_calibrator() -> Node3D:
	if _partner == null:
		return null

	if _partner.has_method("get_current_anchor"):
		return _partner.get_current_anchor()

	return null


func _check_calibrator_alignment() -> bool:
	if _partner == null:
		return false

	if _partner.has_method("is_properly_aligned"):
		return _partner.is_properly_aligned()

	# Fallback: check if pattern is not NONE
	return _received_pattern != PrismEnumsScript.PrismPattern.NONE


# --- Equipment Overrides ---


func _use_impl() -> void:
	super._use_impl()
	activate_eyepiece()


func _stop_using_impl() -> void:
	super._stop_using_impl()
	deactivate_eyepiece()


func _can_use_impl(player: Node) -> bool:
	# Allow toggle-off when active (viewing/reading)
	if _current_state == EquipmentState.ACTIVE:
		return true

	if not super._can_use_impl(player):
		return false

	return true


func get_detectable_evidence() -> Array[String]:
	return ["prism_reading"]


func get_network_state() -> Dictionary:
	var state := super.get_network_state()
	state["reader_state"] = _reader_state
	state["received_pattern"] = _received_pattern
	state["calibration_locked"] = _calibration_locked
	state["calibrator_aligned"] = _calibrator_aligned
	state["reading_progress"] = _reading_progress
	state["current_quality"] = _current_quality
	return state


func apply_network_state(state: Dictionary) -> void:
	super.apply_network_state(state)
	if state.has("reader_state"):
		_reader_state = state.reader_state as ReaderState
	if state.has("received_pattern"):
		_received_pattern = state.received_pattern as PrismEnumsScript.PrismPattern
	if state.has("calibration_locked"):
		_calibration_locked = state.calibration_locked
	if state.has("calibrator_aligned"):
		_calibrator_aligned = state.calibrator_aligned
	if state.has("reading_progress"):
		_reading_progress = state.reading_progress
	if state.has("current_quality"):
		_current_quality = state.current_quality as EvidenceEnums.ReadingQuality


# --- Reset ---


## Resets the lens reader to initial state.
func reset_reader() -> void:
	_reader_state = ReaderState.IDLE
	_received_pattern = PrismEnumsScript.PrismPattern.NONE
	_calibration_locked = false
	_calibrator_aligned = false
	_viewing_start_time = 0.0
	_reading_progress = 0.0
	_total_movement = 0.0
	_current_quality = EvidenceEnums.ReadingQuality.STRONG
	reader_state_changed.emit(ReaderState.IDLE)
