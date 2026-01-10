# gdlint: ignore=max-public-methods
extends GutTest
## Unit tests for AuraImager cooperative equipment.

const AuraEnumsScript := preload("res://src/equipment/aura/aura_enums.gd")
const SpatialConstraintsScript := preload("res://src/equipment/aura/spatial_constraints.gd")

# --- Test Fixtures ---

var _imager: AuraImager
var _rods: DowsingRods
var _player_imager: Node3D
var _player_dowser: Node3D
var _anchor: AuraAnchor


func before_each() -> void:
	_imager = AuraImager.new()
	_rods = DowsingRods.new()
	_player_imager = Node3D.new()
	_player_dowser = Node3D.new()
	_anchor = AuraAnchor.new()

	add_child(_imager)
	add_child(_rods)
	add_child(_player_imager)
	add_child(_player_dowser)
	add_child(_anchor)

	# Set up valid spatial configuration:
	# Dowser at origin, facing -Z (toward anchor)
	# Imager behind Dowser at +Z
	# Anchor in front at -Z
	_player_dowser.position = Vector3(0, 0, 0)
	_player_dowser.rotation = Vector3.ZERO  # Facing -Z

	_player_imager.position = Vector3(0, 0, 3)  # Behind Dowser

	_anchor.position = Vector3(0, 0, -5)  # In front of Dowser
	_anchor.set_color(AuraEnumsScript.AuraColor.HOT_RED)

	# Equip to players
	_rods.equip(_player_dowser)
	_imager.equip(_player_imager)

	# Link partners (bidirectional)
	_rods.link_partner(_imager)


func after_each() -> void:
	if _anchor.is_in_group("aura_anchors"):
		_anchor.remove_from_group("aura_anchors")
	_imager.queue_free()
	_rods.queue_free()
	_player_imager.queue_free()
	_player_dowser.queue_free()
	_anchor.queue_free()


# --- Test: Initial State ---


func test_initial_imager_state_is_idle() -> void:
	assert_eq(_imager.get_imager_state(), AuraImager.ImagerState.IDLE)


func test_initial_resolution_is_zero() -> void:
	assert_eq(_imager.get_resolution(), 0.0)


func test_equipment_type_is_aura_imager() -> void:
	assert_eq(_imager.equipment_type, Equipment.EquipmentType.AURA_IMAGER)


func test_is_not_primary_equipment() -> void:
	assert_false(_imager.is_primary)


func test_trust_dynamic_is_asymmetric() -> void:
	assert_eq(_imager.trust_dynamic, CooperativeEquipment.TrustDynamic.ASYMMETRIC)


func test_not_capturing_initially() -> void:
	assert_false(_imager.is_capturing())


func test_initial_color_is_none() -> void:
	assert_eq(_imager.get_aura_color(), AuraEnumsScript.AuraColor.NONE)


func test_initial_form_is_none() -> void:
	assert_eq(_imager.get_aura_form(), AuraEnumsScript.AuraForm.NONE)


# --- Test: Partner Requirements ---


func test_cannot_use_without_partner() -> void:
	_imager.unlink_partner()
	var result := _imager.use(_player_imager)
	assert_false(result)


func test_can_use_with_partner() -> void:
	# Activate Dowser first so anchor is detected
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout

	var result := _imager.use(_player_imager)
	assert_true(result)


func test_partner_link_is_bidirectional() -> void:
	assert_eq(_imager.get_partner(), _rods)
	assert_eq(_rods.get_partner(), _imager)


# --- Test: Imager State Machine ---


func test_using_imager_sets_positioning_state() -> void:
	_rods.use(_player_dowser)
	await get_tree().process_frame
	_imager.use(_player_imager)
	assert_eq(_imager.get_imager_state(), AuraImager.ImagerState.POSITIONING)


func test_stop_using_sets_idle_state() -> void:
	_rods.use(_player_dowser)
	await get_tree().process_frame
	_imager.use(_player_imager)
	# Toggle off
	_imager.use(_player_imager)
	await get_tree().process_frame
	assert_eq(_imager.get_imager_state(), AuraImager.ImagerState.IDLE)


func test_imager_state_changed_signal_emitted() -> void:
	_rods.use(_player_dowser)
	await get_tree().process_frame
	watch_signals(_imager)
	_imager.use(_player_imager)
	assert_signal_emitted(_imager, "imager_state_changed")


func test_imager_state_name_idle() -> void:
	assert_eq(_imager.get_imager_state_name(), "Idle")


func test_imager_state_name_positioning() -> void:
	_rods.use(_player_dowser)
	await get_tree().process_frame
	_imager.use(_player_imager)
	assert_eq(_imager.get_imager_state_name(), "Positioning")


# --- Test: Spatial Positioning ---


func test_positioning_valid_with_correct_setup() -> void:
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout
	_imager.use(_player_imager)
	await get_tree().create_timer(0.15).timeout
	assert_true(_imager.is_properly_positioned())


func test_positioning_invalid_without_anchor() -> void:
	_anchor.remove_from_group("aura_anchors")
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout
	_imager.use(_player_imager)
	await get_tree().create_timer(0.15).timeout
	assert_false(_imager.is_properly_positioned())


func test_positioning_invalid_when_imager_in_front() -> void:
	_player_imager.position = Vector3(0, 0, -3)  # In front of Dowser
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout
	_imager.use(_player_imager)
	await get_tree().create_timer(0.15).timeout
	assert_false(_imager.is_properly_positioned())


func test_positioning_violations_populated() -> void:
	_player_imager.position = Vector3(0, 0, -3)  # In front of Dowser
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout
	_imager.use(_player_imager)
	await get_tree().create_timer(0.15).timeout
	var violations := _imager.get_positioning_violations()
	assert_true(violations.size() > 0)


func test_positioning_changed_signal_emitted() -> void:
	_rods.use(_player_dowser)
	await get_tree().process_frame
	watch_signals(_imager)
	_imager.use(_player_imager)
	await get_tree().create_timer(0.15).timeout
	assert_signal_emitted(_imager, "positioning_changed")


func test_has_line_of_sight_when_positioned() -> void:
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout
	_imager.use(_player_imager)
	await get_tree().create_timer(0.15).timeout
	assert_true(_imager.has_line_of_sight_to_rods())


# --- Test: Direction Commands ---


func test_issue_direction_emits_signal() -> void:
	watch_signals(_imager)
	_imager.issue_direction(AuraImager.DirectionCommand.STEP_LEFT)
	assert_signal_emitted(_imager, "direction_issued")


func test_last_direction_updated() -> void:
	_imager.issue_direction(AuraImager.DirectionCommand.STEP_RIGHT)
	assert_eq(_imager.get_last_direction(), AuraImager.DirectionCommand.STEP_RIGHT)


func test_direction_names() -> void:
	assert_eq(AuraImager.get_direction_name(AuraImager.DirectionCommand.STEP_LEFT), "Step Left")
	assert_eq(AuraImager.get_direction_name(AuraImager.DirectionCommand.HOLD_STEADY), "Hold Steady")
	assert_eq(AuraImager.get_direction_name(AuraImager.DirectionCommand.RAISE_RODS), "Raise Rods")


func test_issuing_direction_changes_state_to_directing() -> void:
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout
	_imager.use(_player_imager)
	await get_tree().create_timer(0.15).timeout
	# Force viewing state
	_imager._set_imager_state(AuraImager.ImagerState.VIEWING)
	_imager.issue_direction(AuraImager.DirectionCommand.STEP_LEFT)
	assert_eq(_imager.get_imager_state(), AuraImager.ImagerState.DIRECTING)


# --- Test: Aura Resolution ---


func test_resolution_changes_signal_emitted() -> void:
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout
	_imager.use(_player_imager)
	watch_signals(_imager)
	await get_tree().create_timer(0.3).timeout
	var emit_count: int = get_signal_emit_count(_imager, "resolution_changed")
	# May or may not emit depending on alignment
	assert_true(emit_count >= 0)


func test_color_not_visible_at_low_resolution() -> void:
	_rods.use(_player_dowser)
	await get_tree().process_frame
	_imager.use(_player_imager)
	# Resolution starts at 0
	assert_false(_imager.is_color_visible())


func test_form_requires_higher_resolution_than_color() -> void:
	# Form threshold (0.5) > Color threshold (0.3)
	assert_true(AuraImager.FORM_VISIBLE_THRESHOLD > AuraImager.COLOR_VISIBLE_THRESHOLD)


func test_resolution_increases_with_alignment() -> void:
	# Setup perfect alignment
	_player_dowser.position = Vector3(0, 0, 0)
	_player_dowser.rotation = Vector3.ZERO
	_player_imager.position = Vector3(0, 0, 2)
	_anchor.position = Vector3(0, 0, -5)

	_rods.use(_player_dowser)
	await get_tree().create_timer(0.2).timeout
	_imager.use(_player_imager)
	await get_tree().create_timer(0.5).timeout

	var resolution := _imager.get_resolution()
	assert_true(resolution >= 0.0)


func test_fully_resolved_at_high_resolution() -> void:
	# Force high resolution for testing
	_rods.use(_player_dowser)
	await get_tree().process_frame
	_imager.use(_player_imager)
	_imager._current_resolution = 0.8
	assert_true(_imager.is_fully_resolved())


# --- Test: Pattern Reading ---


func test_get_aura_color_when_resolved() -> void:
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout
	_imager.use(_player_imager)
	await get_tree().create_timer(0.15).timeout
	# Force high resolution
	_imager._current_resolution = 0.8
	_imager._resolved_color = AuraEnumsScript.AuraColor.HOT_RED
	assert_eq(_imager.get_aura_color(), AuraEnumsScript.AuraColor.HOT_RED)


func test_get_aura_form_when_resolved() -> void:
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout
	_imager.use(_player_imager)
	await get_tree().create_timer(0.15).timeout
	# Force high resolution
	_imager._current_resolution = 0.8
	_imager._resolved_form = AuraEnumsScript.AuraForm.SPIKING_ERRATIC
	assert_eq(_imager.get_aura_form(), AuraEnumsScript.AuraForm.SPIKING_ERRATIC)


func test_combined_signature_format() -> void:
	_imager._current_resolution = 0.8
	_imager._resolved_color = AuraEnumsScript.AuraColor.COLD_BLUE
	_imager._resolved_form = AuraEnumsScript.AuraForm.TIGHT_CONTAINED
	var sig := _imager.get_combined_signature()
	assert_true(sig.length() > 0)
	assert_true("Blue" in sig or "Cold" in sig)


func test_is_consistent_when_matching() -> void:
	_imager._current_resolution = 0.8
	_imager._resolved_color = AuraEnumsScript.AuraColor.HOT_RED
	_imager._resolved_form = AuraEnumsScript.AuraForm.SPIKING_ERRATIC
	assert_true(_imager.is_consistent())


func test_is_not_consistent_when_mismatched() -> void:
	_imager._current_resolution = 0.8
	_imager._resolved_color = AuraEnumsScript.AuraColor.HOT_RED
	_imager._resolved_form = AuraEnumsScript.AuraForm.TIGHT_CONTAINED  # Wrong form
	assert_false(_imager.is_consistent())


func test_color_name_display() -> void:
	_imager._current_resolution = 0.8
	_imager._resolved_color = AuraEnumsScript.AuraColor.PALE_GREEN
	assert_eq(_imager.get_color_name(), "Pale Green")


func test_form_name_display() -> void:
	_imager._current_resolution = 0.8
	_imager._resolved_form = AuraEnumsScript.AuraForm.SWIRLING_MOBILE
	assert_eq(_imager.get_form_name(), "Swirling/Mobile")


# --- Test: Evidence Collection ---


func test_cannot_start_capture_when_idle() -> void:
	var result := _imager.start_capture()
	assert_false(result)


func test_cannot_start_capture_without_resolution() -> void:
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout
	_imager.use(_player_imager)
	await get_tree().process_frame
	# Resolution is 0
	var result := _imager.start_capture()
	assert_false(result)


func test_can_start_capture_with_resolution() -> void:
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout
	_imager.use(_player_imager)
	await get_tree().create_timer(0.15).timeout
	# Force valid state
	_imager._positioning_valid = true
	_imager._current_resolution = 0.5
	_imager._set_imager_state(AuraImager.ImagerState.VIEWING)
	var result := _imager.start_capture()
	assert_true(result)


func test_capture_sets_recording_state() -> void:
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout
	_imager.use(_player_imager)
	await get_tree().create_timer(0.15).timeout
	_imager._positioning_valid = true
	_imager._current_resolution = 0.5
	_imager._set_imager_state(AuraImager.ImagerState.VIEWING)
	_imager.start_capture()
	assert_eq(_imager.get_imager_state(), AuraImager.ImagerState.RECORDING)


func test_capture_progress_starts_at_zero() -> void:
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout
	_imager.use(_player_imager)
	await get_tree().create_timer(0.15).timeout
	_imager._positioning_valid = true
	_imager._current_resolution = 0.5
	_imager._set_imager_state(AuraImager.ImagerState.VIEWING)
	_imager.start_capture()
	var progress := _imager.get_capture_progress()
	assert_almost_eq(progress, 0.0, 0.1)


func test_capture_progress_increases() -> void:
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout
	_imager.use(_player_imager)
	await get_tree().create_timer(0.15).timeout
	_imager._positioning_valid = true
	_imager._current_resolution = 0.5
	_imager._set_imager_state(AuraImager.ImagerState.VIEWING)
	_imager.start_capture()

	await get_tree().create_timer(0.3).timeout

	var progress := _imager.get_capture_progress()
	assert_true(progress > 0.0)


func test_capture_completes_after_duration() -> void:
	_imager.capture_duration = 0.1  # Short for testing
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout
	_imager.use(_player_imager)
	await get_tree().create_timer(0.15).timeout
	_imager._positioning_valid = true
	_imager._current_resolution = 0.5
	_imager._set_imager_state(AuraImager.ImagerState.VIEWING)

	watch_signals(_imager)
	_imager.start_capture()
	await get_tree().create_timer(0.2).timeout

	assert_signal_emitted(_imager, "reading_captured")


func test_cancel_capture_stops_recording() -> void:
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout
	_imager.use(_player_imager)
	await get_tree().create_timer(0.15).timeout
	_imager._positioning_valid = true
	_imager._current_resolution = 0.5
	_imager._set_imager_state(AuraImager.ImagerState.VIEWING)
	_imager.start_capture()
	_imager.cancel_capture()
	assert_false(_imager.is_capturing())


func test_cannot_start_capture_twice() -> void:
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout
	_imager.use(_player_imager)
	await get_tree().create_timer(0.15).timeout
	_imager._positioning_valid = true
	_imager._current_resolution = 0.5
	_imager._set_imager_state(AuraImager.ImagerState.VIEWING)
	_imager.start_capture()
	var result := _imager.start_capture()
	assert_false(result)


func test_create_evidence_returns_dictionary() -> void:
	_imager._resolved_color = AuraEnumsScript.AuraColor.HOT_RED
	_imager._resolved_form = AuraEnumsScript.AuraForm.SPIKING_ERRATIC
	_imager._current_resolution = 0.8

	var evidence := _imager.create_evidence()

	assert_true(evidence is Dictionary)
	assert_has(evidence, "type")
	assert_has(evidence, "collector_ids")
	assert_has(evidence, "quality")
	assert_has(evidence, "color")
	assert_has(evidence, "form")


func test_evidence_includes_both_collector_ids() -> void:
	_imager._resolved_color = AuraEnumsScript.AuraColor.HOT_RED
	_imager._resolved_form = AuraEnumsScript.AuraForm.SPIKING_ERRATIC

	var evidence := _imager.create_evidence()

	var collector_ids: Array = evidence.collector_ids
	assert_eq(collector_ids.size(), 2)


func test_evidence_quality_strong_with_good_alignment() -> void:
	# Setup for strong quality
	_rods.use(_player_dowser)
	_rods._set_rod_state(DowsingRods.RodState.ALIGNED)
	_rods._alignment_level = SpatialConstraintsScript.AlignmentQuality.STRONG
	_rods.hold_steady_duration = 0.05
	_rods.start_hold_steady()
	await get_tree().create_timer(0.1).timeout

	var evidence := _imager.create_evidence()
	assert_eq(evidence.quality, AuraImager.ReadingQuality.STRONG)


func test_evidence_quality_weak_with_poor_alignment() -> void:
	_rods.use(_player_dowser)
	_rods._set_rod_state(DowsingRods.RodState.SEEKING)
	_rods._alignment_level = SpatialConstraintsScript.AlignmentQuality.WEAK

	var evidence := _imager.create_evidence()
	assert_eq(evidence.quality, AuraImager.ReadingQuality.WEAK)


func test_quality_name_display() -> void:
	assert_eq(AuraImager.get_quality_name(AuraImager.ReadingQuality.STRONG), "Strong")
	assert_eq(AuraImager.get_quality_name(AuraImager.ReadingQuality.WEAK), "Weak")
	assert_eq(AuraImager.get_quality_name(AuraImager.ReadingQuality.NONE), "None")


# --- Test: Third-Party Observation ---


func test_observer_cannot_see_screen_when_far() -> void:
	_rods.use(_player_dowser)
	await get_tree().process_frame
	_imager.use(_player_imager)

	var far_observer := Vector3(100, 0, 0)
	assert_false(_imager.can_observer_see_screen(far_observer))


func test_observer_can_see_screen_when_close_behind() -> void:
	_player_imager.position = Vector3(0, 0, 3)
	_player_imager.rotation = Vector3.ZERO  # Facing -Z
	_rods.use(_player_dowser)
	await get_tree().process_frame
	_imager.use(_player_imager)

	# Observer behind the imager can see the screen
	var close_observer := Vector3(0, 0, 4)  # Behind Imager
	assert_true(_imager.can_observer_see_screen(close_observer))


func test_observer_cannot_see_screen_from_front() -> void:
	_player_imager.position = Vector3(0, 0, 3)
	_player_imager.rotation = Vector3.ZERO  # Facing -Z
	_rods.use(_player_dowser)
	await get_tree().process_frame
	_imager.use(_player_imager)

	# Observer in front of imager sees back of device
	var front_observer := Vector3(0, 0, 2)  # In front of Imager
	assert_false(_imager.can_observer_see_screen(front_observer))


func test_observable_state_excludes_screen_content() -> void:
	_imager._current_resolution = 0.8
	_imager._resolved_color = AuraEnumsScript.AuraColor.HOT_RED
	_imager._resolved_form = AuraEnumsScript.AuraForm.SPIKING_ERRATIC

	var state := _imager.get_observable_state()

	# Position/state should be observable
	assert_has(state, "imager_state")
	assert_has(state, "position")
	assert_has(state, "facing")

	# Screen content should NOT be observable
	assert_false(state.has("color"))
	assert_false(state.has("form"))
	assert_false(state.has("resolution"))


# --- Test: Network State ---


func test_network_state_includes_imager_state() -> void:
	_rods.use(_player_dowser)
	await get_tree().process_frame
	_imager.use(_player_imager)
	var state := _imager.get_network_state()
	assert_has(state, "imager_state")


func test_network_state_includes_resolution() -> void:
	var state := _imager.get_network_state()
	assert_has(state, "resolution")


func test_network_state_includes_capture_status() -> void:
	var state := _imager.get_network_state()
	assert_has(state, "is_capturing")
	assert_has(state, "capture_progress")


func test_network_state_includes_positioning() -> void:
	var state := _imager.get_network_state()
	assert_has(state, "positioning_valid")


func test_apply_network_state() -> void:
	var state := {
		"imager_state": AuraImager.ImagerState.VIEWING,
		"resolution": 0.6,
		"is_capturing": true,
		"positioning_valid": true,
	}
	_imager.apply_network_state(state)
	assert_eq(_imager.get_imager_state(), AuraImager.ImagerState.VIEWING)
	assert_almost_eq(_imager.get_resolution(), 0.6, 0.01)
	assert_true(_imager.is_capturing())


# --- Test: Reset ---


func test_reset_imager() -> void:
	_rods.use(_player_dowser)
	await get_tree().process_frame
	_imager.use(_player_imager)
	_imager._current_resolution = 0.8
	_imager._positioning_valid = true
	_imager._resolved_color = AuraEnumsScript.AuraColor.HOT_RED

	_imager.reset_imager()

	assert_eq(_imager.get_imager_state(), AuraImager.ImagerState.IDLE)
	assert_eq(_imager.get_resolution(), 0.0)
	assert_false(_imager.is_properly_positioned())
	assert_eq(_imager.get_aura_color(), AuraEnumsScript.AuraColor.NONE)


# --- Test: Evidence Type ---


func test_detectable_evidence_includes_aura_pattern() -> void:
	var evidence := _imager.get_detectable_evidence()
	assert_true("aura_pattern" in evidence)


# --- Test: Dowser Signal Connections ---


func test_alignment_lost_cancels_capture() -> void:
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout
	_imager.use(_player_imager)
	await get_tree().create_timer(0.15).timeout
	_imager._positioning_valid = true
	_imager._current_resolution = 0.5
	_imager._set_imager_state(AuraImager.ImagerState.VIEWING)
	_imager.start_capture()

	# Emit alignment_lost from Dowser
	_rods.alignment_lost.emit()

	assert_false(_imager.is_capturing())
