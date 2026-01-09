class_name AuraImager
extends CooperativeEquipment
## Aura Imager unit for the Aura detection system.
##
## The Imager positions behind the Dowser, aims at their back/rods, and reads
## the aura pattern that resolves on their screen. Only the Imager can see the
## screen clearly, making them the sole source of truth for the evidence.
##
## Trust Dynamic: The Imager CAN lie - they alone see the screen, they control
## the direction commands, and they interpret the results. A third player can
## watch over their shoulder (but this costs coverage elsewhere).

# --- Signals ---

## Emitted when imager state changes.
signal imager_state_changed(new_state: ImagerState)

## Emitted when aura resolution changes.
signal resolution_changed(new_resolution: float)

## Emitted when aura becomes fully resolved.
signal aura_resolved(color: int, form: int)

## Emitted when a direction command is issued (social/voice).
signal direction_issued(command: DirectionCommand)

## Emitted when a reading is captured.
signal reading_captured(quality: int)

## Emitted when positioning status changes.
signal positioning_changed(is_valid: bool, violations: Array)

# --- Enums ---

## State machine for imager operation.
enum ImagerState {
	IDLE,  ## Not in use
	POSITIONING,  ## Moving to get behind Dowser
	DIRECTING,  ## Giving directions to Dowser
	VIEWING,  ## Watching aura resolve on screen
	RECORDING,  ## Capturing the reading
}

## Direction commands that Imager can give to Dowser.
## These are social (voice chat) - not enforced by game.
enum DirectionCommand {
	STEP_LEFT,
	STEP_RIGHT,
	STEP_FORWARD,
	STEP_BACK,
	RAISE_RODS,
	LOWER_RODS,
	HOLD_STEADY,
}

## Quality of the captured reading.
enum ReadingQuality {
	NONE,  ## No reading
	WEAK,  ## Poor alignment, movement, incomplete resolution
	STRONG,  ## Good alignment, steady hold, clear resolution
}

# --- Constants ---

const AuraEnumsScript := preload("res://src/equipment/aura/aura_enums.gd")
const SpatialConstraintsScript := preload("res://src/equipment/aura/spatial_constraints.gd")

## Update interval for position/alignment checks.
const POSITIONING_CHECK_INTERVAL := 0.1

## Resolution threshold for color visibility (0.0-1.0).
const COLOR_VISIBLE_THRESHOLD := 0.3

## Resolution threshold for form visibility (0.0-1.0).
const FORM_VISIBLE_THRESHOLD := 0.5

## Resolution threshold for full clarity (0.0-1.0).
const FULL_CLARITY_THRESHOLD := 0.7

## Viewing angle for third-party observation (radians).
const THIRD_PARTY_VIEW_ANGLE := deg_to_rad(45.0)

## Maximum distance for third-party observation.
const THIRD_PARTY_MAX_DISTANCE := 2.0

# --- Export: Aura Imager Settings ---

@export_group("Aura Imager")
## How long to hold recording before evidence is captured.
@export var capture_duration: float = 1.0

## Resolution smoothing factor (how quickly resolution changes).
@export var resolution_smoothing: float = 2.0

@export_group("Audio Feedback")
## Plays when resolution improves.
@export var resolution_up_sound: AudioStream

## Plays when reading is captured.
@export var capture_sound: AudioStream

# --- State ---

var _imager_state: ImagerState = ImagerState.IDLE
var _current_resolution: float = 0.0  ## 0.0 to 1.0
var _target_resolution: float = 0.0
var _is_capturing: bool = false
var _capture_timer: float = 0.0
var _positioning_timer: float = 0.0
var _current_anchor: Node3D = null
var _last_issued_command: DirectionCommand = DirectionCommand.HOLD_STEADY
var _positioning_valid: bool = false
var _positioning_violations: Array[String] = []

# --- Cached Readings ---

var _resolved_color: AuraEnumsScript.AuraColor = AuraEnumsScript.AuraColor.NONE
var _resolved_form: AuraEnumsScript.AuraForm = AuraEnumsScript.AuraForm.NONE


func _ready() -> void:
	equipment_type = EquipmentType.AURA_IMAGER
	equipment_name = "Aura Imager"
	use_mode = UseMode.TOGGLE
	is_primary = false  # Dowser is primary, Imager is secondary
	trust_dynamic = TrustDynamic.ASYMMETRIC


func _process(delta: float) -> void:
	super._process(delta)

	if _current_state != EquipmentState.ACTIVE:
		return

	# Throttled positioning check
	_positioning_timer += delta
	if _positioning_timer >= POSITIONING_CHECK_INTERVAL:
		_positioning_timer = 0.0
		_check_positioning()
		_update_resolution(delta * 10.0)  # Compensate for throttling

	# Smooth resolution transition
	_smooth_resolution(delta)

	# Capture timer
	if _is_capturing:
		_capture_timer += delta
		if _capture_timer >= capture_duration:
			_complete_capture()


# --- Imager State Machine ---


## Gets the current imager state.
func get_imager_state() -> ImagerState:
	return _imager_state


## Sets the imager state and emits signal.
func _set_imager_state(new_state: ImagerState) -> void:
	if _imager_state != new_state:
		_imager_state = new_state
		imager_state_changed.emit(new_state)


## Returns the state name for display.
func get_imager_state_name() -> String:
	match _imager_state:
		ImagerState.IDLE:
			return "Idle"
		ImagerState.POSITIONING:
			return "Positioning"
		ImagerState.DIRECTING:
			return "Directing"
		ImagerState.VIEWING:
			return "Viewing"
		ImagerState.RECORDING:
			return "Recording"
		_:
			return "Unknown"


# --- Spatial Positioning ---


## Returns true if Imager is properly positioned behind Dowser.
func is_properly_positioned() -> bool:
	return _positioning_valid


## Gets the current positioning violations (if any).
func get_positioning_violations() -> Array[String]:
	return _positioning_violations


## Checks positioning relative to Dowser and anchor.
func _check_positioning() -> void:
	if not has_partner():
		_set_positioning_state(false, ["No Dowser partner linked"])
		_set_imager_state(ImagerState.POSITIONING)
		return

	var dowser := _partner as DowsingRods
	if dowser == null:
		_set_positioning_state(false, ["Partner is not Dowsing Rods"])
		_set_imager_state(ImagerState.POSITIONING)
		return

	# Need anchor for full validation
	var anchor := dowser.get_current_anchor()
	if anchor == null:
		_set_positioning_state(false, ["No anchor detected by Dowser"])
		_set_imager_state(ImagerState.POSITIONING)
		return

	_current_anchor = anchor

	# Get positions
	var imager_pos := _get_equipment_position()
	var dowser_pos := dowser._get_equipment_position()
	var dowser_forward := dowser._get_facing_direction()
	var anchor_pos: Vector3

	if anchor.is_inside_tree():
		anchor_pos = anchor.global_position
	else:
		anchor_pos = anchor.position

	# Validate spatial constraints
	var result := SpatialConstraintsScript.validate_positions(
		dowser_pos, dowser_forward, imager_pos, anchor_pos
	)

	_set_positioning_state(result.is_valid, result.violations)

	# Update state based on positioning
	if result.is_valid:
		if _imager_state == ImagerState.POSITIONING:
			_set_imager_state(ImagerState.VIEWING)
	else:
		if _imager_state != ImagerState.IDLE:
			_set_imager_state(ImagerState.POSITIONING)


## Sets the positioning state and emits signal if changed.
func _set_positioning_state(valid: bool, violations: Array) -> void:
	var changed := _positioning_valid != valid
	_positioning_valid = valid

	_positioning_violations.clear()
	for v in violations:
		_positioning_violations.append(str(v))

	if changed:
		positioning_changed.emit(valid, _positioning_violations)


## Checks if this imager has line-of-sight to the Dowser's rods.
func has_line_of_sight_to_rods() -> bool:
	if not has_partner():
		return false

	# For now, use positioning validity as proxy for line-of-sight.
	# Full raycast-based LOS would require physics layers.
	return _positioning_valid


# --- Direction Commands ---


## Issues a direction command to the Dowser.
## These are social commands - not enforced by game.
func issue_direction(command: DirectionCommand) -> void:
	_last_issued_command = command
	direction_issued.emit(command)

	# Update state if actively directing
	if _imager_state == ImagerState.VIEWING:
		_set_imager_state(ImagerState.DIRECTING)


## Gets the last issued direction command.
func get_last_direction() -> DirectionCommand:
	return _last_issued_command


## Returns the display name for a direction command.
static func get_direction_name(command: DirectionCommand) -> String:
	match command:
		DirectionCommand.STEP_LEFT:
			return "Step Left"
		DirectionCommand.STEP_RIGHT:
			return "Step Right"
		DirectionCommand.STEP_FORWARD:
			return "Step Forward"
		DirectionCommand.STEP_BACK:
			return "Step Back"
		DirectionCommand.RAISE_RODS:
			return "Raise Rods"
		DirectionCommand.LOWER_RODS:
			return "Lower Rods"
		DirectionCommand.HOLD_STEADY:
			return "Hold Steady"
		_:
			return "Unknown"


# --- Aura Resolution ---


## Gets the current resolution level (0.0 to 1.0).
func get_resolution() -> float:
	return _current_resolution


## Returns true if colors are visible at current resolution.
func is_color_visible() -> bool:
	return _current_resolution >= COLOR_VISIBLE_THRESHOLD


## Returns true if form is visible at current resolution.
func is_form_visible() -> bool:
	return _current_resolution >= FORM_VISIBLE_THRESHOLD


## Returns true if aura is fully resolved.
func is_fully_resolved() -> bool:
	return _current_resolution >= FULL_CLARITY_THRESHOLD


## Updates target resolution based on alignment quality.
func _update_resolution(_delta: float) -> void:
	if not has_partner():
		_target_resolution = 0.0
		return

	var dowser := _partner as DowsingRods
	if dowser == null:
		_target_resolution = 0.0
		return

	# Resolution based on Dowser's alignment quality
	var alignment := dowser.get_alignment_quality()

	# Boost resolution if Dowser is holding steady
	var hold_bonus := 0.0
	if dowser.is_holding_steady():
		hold_bonus = dowser.get_hold_steady_progress() * 0.3

	_target_resolution = clampf(alignment + hold_bonus, 0.0, 1.0)

	# Update resolved color/form based on resolution
	_update_resolved_reading()


## Smoothly transitions current resolution toward target.
func _smooth_resolution(delta: float) -> void:
	var old_resolution := _current_resolution
	_current_resolution = move_toward(
		_current_resolution, _target_resolution, delta * resolution_smoothing
	)

	# Check for significant change
	var significant_change := absf(old_resolution - _current_resolution) > 0.01
	if significant_change:
		resolution_changed.emit(_current_resolution)

	# Check for full resolution achieved
	var crossed_threshold := old_resolution < FULL_CLARITY_THRESHOLD
	crossed_threshold = crossed_threshold and _current_resolution >= FULL_CLARITY_THRESHOLD
	if crossed_threshold:
		aura_resolved.emit(_resolved_color, _resolved_form)


## Updates the resolved reading based on current anchor.
func _update_resolved_reading() -> void:
	if _current_anchor == null:
		_resolved_color = AuraEnumsScript.AuraColor.NONE
		_resolved_form = AuraEnumsScript.AuraForm.NONE
		return

	# Get true color/form from anchor
	if _current_anchor.has_method("get_true_color"):
		_resolved_color = _current_anchor.get_true_color()
	if _current_anchor.has_method("get_true_form"):
		_resolved_form = _current_anchor.get_true_form()


# --- Pattern Reading ---


## Gets the aura color (if visible at current resolution).
func get_aura_color() -> AuraEnumsScript.AuraColor:
	if not is_color_visible():
		return AuraEnumsScript.AuraColor.NONE
	return _resolved_color


## Gets the aura form (if visible at current resolution).
func get_aura_form() -> AuraEnumsScript.AuraForm:
	if not is_form_visible():
		return AuraEnumsScript.AuraForm.NONE
	return _resolved_form


## Gets the combined aura signature description.
func get_combined_signature() -> String:
	var color := get_aura_color()
	var form := get_aura_form()
	return AuraEnumsScript.get_combined_signature(color, form)


## Returns true if the current reading is consistent (color matches form).
func is_consistent() -> bool:
	var color := get_aura_color()
	var form := get_aura_form()
	return AuraEnumsScript.is_consistent(color, form)


## Gets the display name for the current color.
func get_color_name() -> String:
	return AuraEnumsScript.get_color_name(get_aura_color())


## Gets the display name for the current form.
func get_form_name() -> String:
	return AuraEnumsScript.get_form_name(get_aura_form())


# --- Evidence Collection ---


## Starts capturing a reading.
func start_capture() -> bool:
	if _imager_state == ImagerState.IDLE:
		return false

	if not _positioning_valid:
		return false

	if _is_capturing:
		return false

	if not is_color_visible():
		return false  # Need at least some resolution

	_is_capturing = true
	_capture_timer = 0.0
	_set_imager_state(ImagerState.RECORDING)
	return true


## Cancels the current capture.
func cancel_capture() -> void:
	if not _is_capturing:
		return

	_is_capturing = false
	_capture_timer = 0.0
	_set_imager_state(ImagerState.VIEWING)


## Returns true if currently capturing.
func is_capturing() -> bool:
	return _is_capturing


## Returns capture progress (0.0 to 1.0).
func get_capture_progress() -> float:
	if not _is_capturing:
		return 0.0
	return clampf(_capture_timer / capture_duration, 0.0, 1.0)


## Completes the capture and creates evidence.
func _complete_capture() -> void:
	_is_capturing = false
	_capture_timer = 0.0

	var quality := _get_reading_quality()
	reading_captured.emit(quality)

	# Notify Dowser that reading is complete
	if has_partner() and _partner.has_method("on_reading_complete"):
		_partner.on_reading_complete()

	_set_imager_state(ImagerState.VIEWING)


## Determines reading quality based on alignment and stability.
func _get_reading_quality() -> ReadingQuality:
	if not has_partner():
		return ReadingQuality.NONE

	var dowser := _partner as DowsingRods
	if dowser == null:
		return ReadingQuality.NONE

	var alignment := dowser.get_alignment_level()
	var is_steady := dowser.is_hold_steady_complete()

	# Strong quality requires good alignment AND completed hold steady
	if alignment >= SpatialConstraintsScript.AlignmentQuality.STRONG and is_steady:
		return ReadingQuality.STRONG

	if alignment >= SpatialConstraintsScript.AlignmentQuality.MODERATE:
		return ReadingQuality.STRONG if is_steady else ReadingQuality.WEAK

	return ReadingQuality.WEAK


## Gets quality name for display.
static func get_quality_name(quality: ReadingQuality) -> String:
	match quality:
		ReadingQuality.NONE:
			return "None"
		ReadingQuality.WEAK:
			return "Weak"
		ReadingQuality.STRONG:
			return "Strong"
		_:
			return "Unknown"


## Creates cooperative evidence for the reading.
## Returns the evidence data dictionary.
func create_evidence() -> Dictionary:
	var quality := _get_reading_quality()

	var dowser_id := 0
	var imager_id := 0

	if has_partner() and _partner._owning_player:
		dowser_id = _get_player_id(_partner._owning_player)
	if _owning_player:
		imager_id = _get_player_id(_owning_player)

	var location := _get_equipment_position()

	return {
		"type": "AURA_PATTERN",
		"collector_ids": [dowser_id, imager_id],
		"location": location,
		"quality": quality,
		"color": _resolved_color,
		"form": _resolved_form,
		"is_consistent": is_consistent(),
		"resolution": _current_resolution,
	}


# --- Third-Party Observation ---


## Checks if an observer can see the Imager's screen.
## Returns true if the observer is at the correct angle and distance.
func can_observer_see_screen(observer_position: Vector3) -> bool:
	var imager_pos := _get_equipment_position()
	var distance := imager_pos.distance_to(observer_position)

	# Must be close enough
	if distance > THIRD_PARTY_MAX_DISTANCE:
		return false

	# Must be behind/beside Imager (to see the screen they're holding)
	var imager_forward := _get_facing_direction()
	var to_observer := (observer_position - imager_pos).normalized()

	# Flatten to horizontal plane
	var forward_flat := Vector3(imager_forward.x, 0, imager_forward.z).normalized()
	var to_obs_flat := Vector3(to_observer.x, 0, to_observer.z).normalized()

	if forward_flat.length_squared() < 0.001 or to_obs_flat.length_squared() < 0.001:
		return false

	var angle := forward_flat.angle_to(to_obs_flat)

	# Observer must be roughly behind or beside (not in front)
	# If in front, they'd see the back of the device, not the screen
	return angle > (PI / 2 - THIRD_PARTY_VIEW_ANGLE)


## Gets the facing direction of the Imager.
func _get_facing_direction() -> Vector3:
	if _owning_player and _owning_player is Node3D:
		var player_3d := _owning_player as Node3D
		if player_3d.is_inside_tree():
			return -player_3d.global_transform.basis.z
		return -player_3d.transform.basis.z
	return Vector3.FORWARD


## Returns all observable state for third-party observers.
## Note: Only position/facing is observable - screen content is NOT.
func get_observable_state() -> Dictionary:
	return {
		"imager_state": _imager_state,
		"position": _get_equipment_position(),
		"facing": _get_facing_direction(),
		"is_capturing": _is_capturing,
		"capture_progress": get_capture_progress(),
		# Note: Color/form/resolution intentionally NOT included
		# Only the Imager can see the screen
	}


# --- Equipment Overrides ---


func _use_impl() -> void:
	super._use_impl()
	_set_imager_state(ImagerState.POSITIONING)
	_current_resolution = 0.0
	_target_resolution = 0.0

	# Connect to Dowser signals if partner exists
	_connect_dowser_signals()


func _stop_using_impl() -> void:
	super._stop_using_impl()
	_set_imager_state(ImagerState.IDLE)
	_disconnect_dowser_signals()
	cancel_capture()
	_current_anchor = null
	_resolved_color = AuraEnumsScript.AuraColor.NONE
	_resolved_form = AuraEnumsScript.AuraForm.NONE


func _can_use_impl(_player: Node) -> bool:
	# Must have a Dowser partner to use
	if not has_partner():
		return false
	return is_partner_in_range()


func get_detectable_evidence() -> Array[String]:
	return ["aura_pattern"]


func get_network_state() -> Dictionary:
	var state := super.get_network_state()
	state["imager_state"] = _imager_state
	state["resolution"] = _current_resolution
	state["is_capturing"] = _is_capturing
	state["capture_progress"] = get_capture_progress()
	state["positioning_valid"] = _positioning_valid
	# Note: Resolved color/form NOT synced - each client sees their own screen
	return state


func apply_network_state(state: Dictionary) -> void:
	super.apply_network_state(state)
	if state.has("imager_state"):
		_imager_state = state.imager_state as ImagerState
	if state.has("resolution"):
		_current_resolution = state.resolution
	if state.has("is_capturing"):
		_is_capturing = state.is_capturing
	if state.has("positioning_valid"):
		_positioning_valid = state.positioning_valid


# --- Partner Signal Connections ---


func _connect_dowser_signals() -> void:
	if not has_partner():
		return

	var dowser := _partner as DowsingRods
	if dowser == null:
		return

	# Connect to relevant signals if not already connected
	if not dowser.alignment_achieved.is_connected(_on_dowser_alignment_achieved):
		dowser.alignment_achieved.connect(_on_dowser_alignment_achieved)
	if not dowser.alignment_lost.is_connected(_on_dowser_alignment_lost):
		dowser.alignment_lost.connect(_on_dowser_alignment_lost)
	if not dowser.hold_steady_started.is_connected(_on_dowser_hold_steady_started):
		dowser.hold_steady_started.connect(_on_dowser_hold_steady_started)


func _disconnect_dowser_signals() -> void:
	if not has_partner():
		return

	var dowser := _partner as DowsingRods
	if dowser == null:
		return

	if dowser.alignment_achieved.is_connected(_on_dowser_alignment_achieved):
		dowser.alignment_achieved.disconnect(_on_dowser_alignment_achieved)
	if dowser.alignment_lost.is_connected(_on_dowser_alignment_lost):
		dowser.alignment_lost.disconnect(_on_dowser_alignment_lost)
	if dowser.hold_steady_started.is_connected(_on_dowser_hold_steady_started):
		dowser.hold_steady_started.disconnect(_on_dowser_hold_steady_started)


func _on_dowser_alignment_achieved(_quality: SpatialConstraintsScript.AlignmentQuality) -> void:
	if _imager_state == ImagerState.POSITIONING:
		_set_imager_state(ImagerState.VIEWING)


func _on_dowser_alignment_lost() -> void:
	# Cancel capture if alignment is lost
	if _is_capturing:
		cancel_capture()


func _on_dowser_hold_steady_started() -> void:
	# Could trigger audio feedback here
	pass


## Resets the imager to initial state.
func reset_imager() -> void:
	_imager_state = ImagerState.IDLE
	_current_resolution = 0.0
	_target_resolution = 0.0
	_is_capturing = false
	_capture_timer = 0.0
	_current_anchor = null
	_positioning_valid = false
	_positioning_violations.clear()
	_resolved_color = AuraEnumsScript.AuraColor.NONE
	_resolved_form = AuraEnumsScript.AuraForm.NONE
	imager_state_changed.emit(ImagerState.IDLE)
