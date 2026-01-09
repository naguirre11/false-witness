class_name DowsingRods
extends CooperativeEquipment
## Dowsing Rods unit for the Aura detection system.
##
## The Dowser holds L-shaped rods that physically react based on their position
## relative to an anchor point. Rod positions are visible to ALL nearby players,
## preventing the Dowser from lying about what they observe.
##
## Trust Dynamic: The Dowser CANNOT effectively deceive - their rod positions
## and facing direction are visible to everyone. They receive verbal directions
## from the Imager and adjust accordingly.

# --- Signals ---

## Emitted when rod state changes.
signal rod_state_changed(new_state: RodState)

## Emitted when the Dowser moves or changes facing.
signal position_changed(pos: Vector3, facing: Vector3)

## Emitted when rod angles change (due to alignment feedback).
signal rods_adjusted(left_angle: float, right_angle: float)

## Emitted when good alignment is achieved.
signal alignment_achieved(quality: SpatialConstraints.AlignmentQuality)

## Emitted when alignment is lost.
signal alignment_lost

## Emitted when hold steady starts.
signal hold_steady_started

## Emitted when hold steady ends.
signal hold_steady_ended

## Emitted when rod behavior changes.
signal rod_behavior_changed(behavior: RodBehavior)

# --- Enums ---

## State machine for rod operation.
enum RodState {
	IDLE,  ## Rods at rest, not in use
	HELD,  ## Rods held but no anchor in range
	SEEKING,  ## Rods actively responding to nearby anchor
	ALIGNED,  ## Rods indicate proper alignment with anchor
}

## Physical behavior patterns of the rods (visible feedback).
enum RodBehavior {
	NEUTRAL,  ## Rods parallel, no pull (no anchor or too far)
	CROSSING,  ## Rods cross inward (strong signal - good alignment)
	SPREADING,  ## Rods spread outward (weak signal - poor alignment)
	TWITCHING,  ## Rods oscillate (interference - entity activity)
}

# --- Constants ---

const SpatialConstraintsScript := preload("res://src/equipment/aura/spatial_constraints.gd")
const AuraEnumsScript := preload("res://src/equipment/aura/aura_enums.gd")

## Update interval for position/alignment checks.
const ALIGNMENT_CHECK_INTERVAL := 0.1

# --- Export: Dowsing Rods Settings ---

@export_group("Dowsing Rods")
## Maximum range to detect anchor points.
@export var max_anchor_range: float = 15.0

## How long to hold steady before alignment is confirmed.
@export var hold_steady_duration: float = 1.5

@export_group("Audio Feedback")
## Plays when rods start responding.
@export var rod_respond_sound: AudioStream

## Plays when alignment is achieved.
@export var alignment_sound: AudioStream

# --- State ---

var _rod_state: RodState = RodState.IDLE
var _rod_behavior: RodBehavior = RodBehavior.NEUTRAL
var _current_anchor: Node3D = null
var _left_rod_angle: float = 0.0  ## -1.0 (spread) to 1.0 (crossed)
var _right_rod_angle: float = 0.0  ## -1.0 (spread) to 1.0 (crossed)
var _alignment_quality: float = 0.0  ## 0.0 to 1.0
var _alignment_level: SpatialConstraintsScript.AlignmentQuality = (
	SpatialConstraintsScript.AlignmentQuality.NONE
)
var _is_holding_steady: bool = false
var _hold_steady_timer: float = 0.0
var _alignment_check_timer: float = 0.0
var _last_position: Vector3 = Vector3.ZERO
var _last_facing: Vector3 = Vector3.FORWARD


func _ready() -> void:
	equipment_type = EquipmentType.DOWSING_RODS
	equipment_name = "Dowsing Rods"
	use_mode = UseMode.TOGGLE
	is_primary = true  # Dowser is primary, Imager is secondary
	trust_dynamic = TrustDynamic.ASYMMETRIC


func _process(delta: float) -> void:
	super._process(delta)

	if _current_state != EquipmentState.ACTIVE:
		return

	# Track position changes for partner communication
	_update_position_tracking()

	# Throttled alignment check
	_alignment_check_timer += delta
	if _alignment_check_timer >= ALIGNMENT_CHECK_INTERVAL:
		_alignment_check_timer = 0.0
		_check_alignment()

	# Hold steady timer
	if _is_holding_steady:
		_hold_steady_timer += delta


# --- Rod State Machine ---


## Gets the current rod state.
func get_rod_state() -> RodState:
	return _rod_state


## Gets the current rod behavior pattern.
func get_rod_behavior() -> RodBehavior:
	return _rod_behavior


## Sets the rod state and emits signal.
func _set_rod_state(new_state: RodState) -> void:
	if _rod_state != new_state:
		_rod_state = new_state
		rod_state_changed.emit(new_state)


## Sets the rod behavior and emits signal.
func _set_rod_behavior(new_behavior: RodBehavior) -> void:
	if _rod_behavior != new_behavior:
		_rod_behavior = new_behavior
		rod_behavior_changed.emit(new_behavior)


# --- Rod Angle Positions (Observable State) ---


## Gets the left rod angle. Range: -1.0 (spread) to 1.0 (crossed).
func get_left_rod_angle() -> float:
	return _left_rod_angle


## Gets the right rod angle. Range: -1.0 (spread) to 1.0 (crossed).
func get_right_rod_angle() -> float:
	return _right_rod_angle


## Gets both rod angles as a Vector2 (left, right).
func get_rod_angles() -> Vector2:
	return Vector2(_left_rod_angle, _right_rod_angle)


## Updates rod angles based on alignment quality and behavior.
func _update_rod_angles(quality: float, behavior: RodBehavior) -> void:
	var old_left := _left_rod_angle
	var old_right := _right_rod_angle

	match behavior:
		RodBehavior.NEUTRAL:
			_left_rod_angle = 0.0
			_right_rod_angle = 0.0
		RodBehavior.CROSSING:
			# Rods cross inward - positive angles
			_left_rod_angle = quality
			_right_rod_angle = quality
		RodBehavior.SPREADING:
			# Rods spread outward - negative angles
			_left_rod_angle = -quality
			_right_rod_angle = -quality
		RodBehavior.TWITCHING:
			# Oscillation - varies with time
			var osc := sin(Time.get_ticks_msec() * 0.01) * 0.5
			_left_rod_angle = osc
			_right_rod_angle = -osc

	var left_changed := not is_equal_approx(old_left, _left_rod_angle)
	var right_changed := not is_equal_approx(old_right, _right_rod_angle)
	if left_changed or right_changed:
		rods_adjusted.emit(_left_rod_angle, _right_rod_angle)


# --- Alignment Detection ---


## Gets the current alignment quality (0.0 to 1.0).
func get_alignment_quality() -> float:
	return _alignment_quality


## Gets the current alignment quality level.
func get_alignment_level() -> SpatialConstraintsScript.AlignmentQuality:
	return _alignment_level


## Checks alignment with anchor and updates rod behavior.
func _check_alignment() -> void:
	if _current_anchor == null:
		_find_anchor_in_range()

	if _current_anchor == null:
		_set_alignment_state(0.0, SpatialConstraintsScript.AlignmentQuality.NONE)
		_set_rod_behavior(RodBehavior.NEUTRAL)
		_set_rod_state(RodState.HELD)
		return

	# Need partner (Imager) position for full validation
	if not has_partner():
		_set_rod_state(RodState.SEEKING)
		_set_rod_behavior(RodBehavior.SPREADING)
		_update_rod_angles(0.3, RodBehavior.SPREADING)
		return

	var dowser_pos := _get_equipment_position()
	var dowser_forward := _get_facing_direction()
	var imager_pos := _partner._get_equipment_position()
	var anchor_pos: Vector3

	if _current_anchor.is_inside_tree():
		anchor_pos = _current_anchor.global_position
	else:
		anchor_pos = _current_anchor.position

	var quality := SpatialConstraintsScript.calculate_alignment_quality(
		dowser_pos, dowser_forward, imager_pos, anchor_pos
	)

	var quality_level := SpatialConstraintsScript.get_quality_level(quality)
	var old_level := _alignment_level

	_set_alignment_state(quality, quality_level)

	# Update rod behavior based on quality
	var behavior := _get_behavior_for_quality(quality_level)
	_set_rod_behavior(behavior)
	_update_rod_angles(quality, behavior)

	# Update rod state
	if quality_level >= SpatialConstraintsScript.AlignmentQuality.MODERATE:
		if _rod_state != RodState.ALIGNED:
			_set_rod_state(RodState.ALIGNED)
			if old_level < SpatialConstraintsScript.AlignmentQuality.MODERATE:
				alignment_achieved.emit(quality_level)
	else:
		if _rod_state == RodState.ALIGNED:
			alignment_lost.emit()
		_set_rod_state(RodState.SEEKING)


## Sets alignment state values.
func _set_alignment_state(quality: float, level: SpatialConstraintsScript.AlignmentQuality) -> void:
	_alignment_quality = quality
	_alignment_level = level


## Maps alignment quality to rod behavior.
func _get_behavior_for_quality(quality: SpatialConstraintsScript.AlignmentQuality) -> RodBehavior:
	match quality:
		SpatialConstraintsScript.AlignmentQuality.STRONG:
			return RodBehavior.CROSSING
		SpatialConstraintsScript.AlignmentQuality.MODERATE:
			return RodBehavior.CROSSING
		SpatialConstraintsScript.AlignmentQuality.WEAK:
			return RodBehavior.SPREADING
		_:
			return RodBehavior.NEUTRAL


# --- Hold Steady Mechanics ---


## Starts holding steady to lock position for reading.
func start_hold_steady() -> bool:
	if _rod_state != RodState.ALIGNED:
		return false

	if _is_holding_steady:
		return false

	_is_holding_steady = true
	_hold_steady_timer = 0.0
	hold_steady_started.emit()
	return true


## Stops holding steady.
func stop_hold_steady() -> void:
	if not _is_holding_steady:
		return

	_is_holding_steady = false
	_hold_steady_timer = 0.0
	hold_steady_ended.emit()


## Returns true if currently holding steady.
func is_holding_steady() -> bool:
	return _is_holding_steady


## Returns the hold steady progress (0.0 to 1.0).
func get_hold_steady_progress() -> float:
	if not _is_holding_steady:
		return 0.0
	return clampf(_hold_steady_timer / hold_steady_duration, 0.0, 1.0)


## Returns true if hold steady is complete.
func is_hold_steady_complete() -> bool:
	return _is_holding_steady and _hold_steady_timer >= hold_steady_duration


# --- Position Tracking (for Partner Communication) ---


## Gets the current facing direction.
func get_facing_direction() -> Vector3:
	return _last_facing


## Gets the facing direction of the equipment owner.
func _get_facing_direction() -> Vector3:
	if _owning_player and _owning_player is Node3D:
		var player_3d := _owning_player as Node3D
		if player_3d.is_inside_tree():
			return -player_3d.global_transform.basis.z
		return -player_3d.transform.basis.z
	return Vector3.FORWARD


## Updates position tracking and emits signal if changed.
func _update_position_tracking() -> void:
	var pos := _get_equipment_position()
	var facing := _get_facing_direction()

	# Check for significant position change
	var pos_changed := pos.distance_squared_to(_last_position) > 0.01
	var facing_changed := facing.distance_squared_to(_last_facing) > 0.001

	if pos_changed or facing_changed:
		_last_position = pos
		_last_facing = facing
		position_changed.emit(pos, facing)

		# Movement breaks hold steady
		if _is_holding_steady and pos_changed:
			stop_hold_steady()


# --- Anchor Detection ---


## Finds an anchor point within range.
func _find_anchor_in_range() -> void:
	var anchors := get_tree().get_nodes_in_group("aura_anchors")

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

	_current_anchor = best_anchor


## Gets distance to a target node.
func _get_distance_to(target: Node3D) -> float:
	var my_pos := _get_equipment_position()
	var target_pos: Vector3

	if target.is_inside_tree():
		target_pos = target.global_position
	else:
		target_pos = target.position

	return my_pos.distance_to(target_pos)


## Returns the current anchor (if any).
func get_current_anchor() -> Node3D:
	return _current_anchor


# --- Observable State (Anti-Deception) ---


## Returns all observable state as a dictionary.
## This state is synced to ALL nearby players, not just the partner.
func get_observable_state() -> Dictionary:
	return {
		"rod_state": _rod_state,
		"rod_behavior": _rod_behavior,
		"left_angle": _left_rod_angle,
		"right_angle": _right_rod_angle,
		"position": _last_position,
		"facing": _last_facing,
		"is_holding_steady": _is_holding_steady,
		"hold_progress": get_hold_steady_progress(),
	}


## Returns true if the Dowser is properly positioned (visible to observers).
func is_properly_positioned() -> bool:
	return _rod_state == RodState.ALIGNED


## Returns the state name for display.
func get_rod_state_name() -> String:
	match _rod_state:
		RodState.IDLE:
			return "Idle"
		RodState.HELD:
			return "Held"
		RodState.SEEKING:
			return "Seeking"
		RodState.ALIGNED:
			return "Aligned"
		_:
			return "Unknown"


## Returns the behavior name for display.
func get_rod_behavior_name() -> String:
	match _rod_behavior:
		RodBehavior.NEUTRAL:
			return "Neutral"
		RodBehavior.CROSSING:
			return "Crossing"
		RodBehavior.SPREADING:
			return "Spreading"
		RodBehavior.TWITCHING:
			return "Twitching"
		_:
			return "Unknown"


# --- Equipment Overrides ---


func _use_impl() -> void:
	super._use_impl()
	_set_rod_state(RodState.HELD)
	_find_anchor_in_range()


func _stop_using_impl() -> void:
	super._stop_using_impl()
	_set_rod_state(RodState.IDLE)
	_set_rod_behavior(RodBehavior.NEUTRAL)
	_current_anchor = null
	stop_hold_steady()


func _can_use_impl(_player: Node) -> bool:
	# Dowsing Rods can be used without partner (limited functionality).
	# Full alignment requires partner, but seeking/detection works alone.
	# Skip CooperativeEquipment's partner requirement check.
	return true


func get_detectable_evidence() -> Array[String]:
	return ["aura_temperament"]


func get_network_state() -> Dictionary:
	var state := super.get_network_state()
	state["rod_state"] = _rod_state
	state["rod_behavior"] = _rod_behavior
	state["left_angle"] = _left_rod_angle
	state["right_angle"] = _right_rod_angle
	state["alignment_quality"] = _alignment_quality
	state["is_holding_steady"] = _is_holding_steady
	state["hold_progress"] = get_hold_steady_progress()
	return state


func apply_network_state(state: Dictionary) -> void:
	super.apply_network_state(state)
	if state.has("rod_state"):
		_rod_state = state.rod_state as RodState
	if state.has("rod_behavior"):
		_rod_behavior = state.rod_behavior as RodBehavior
	if state.has("left_angle"):
		_left_rod_angle = state.left_angle
	if state.has("right_angle"):
		_right_rod_angle = state.right_angle
	if state.has("alignment_quality"):
		_alignment_quality = state.alignment_quality
	if state.has("is_holding_steady"):
		_is_holding_steady = state.is_holding_steady


## Called by partner (Imager) when reading is complete.
func on_reading_complete() -> void:
	stop_hold_steady()
	reset_operation()


## Resets the dowsing rods to initial state.
func reset_rods() -> void:
	_rod_state = RodState.IDLE
	_rod_behavior = RodBehavior.NEUTRAL
	_left_rod_angle = 0.0
	_right_rod_angle = 0.0
	_alignment_quality = 0.0
	_alignment_level = SpatialConstraintsScript.AlignmentQuality.NONE
	_current_anchor = null
	_is_holding_steady = false
	_hold_steady_timer = 0.0
	rod_state_changed.emit(RodState.IDLE)
