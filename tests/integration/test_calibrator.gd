extends GutTest
## Unit tests for SpectralPrismCalibrator.

const PrismEnumsScript := preload("res://src/equipment/spectral_prism/prism_enums.gd")

# --- Test Helpers ---

var _calibrator: SpectralPrismCalibrator
var _lens_reader: CooperativeEquipment
var _player_a: Node3D
var _player_b: Node3D
var _anchor: SpectralAnchor


func before_each() -> void:
	_calibrator = SpectralPrismCalibrator.new()
	_lens_reader = CooperativeEquipment.new()
	_player_a = Node3D.new()
	_player_b = Node3D.new()
	_anchor = SpectralAnchor.new()

	add_child(_calibrator)
	add_child(_lens_reader)
	add_child(_player_a)
	add_child(_player_b)
	add_child(_anchor)

	# Position players within range
	_player_a.position = Vector3(0, 0, 0)
	_player_b.position = Vector3(3, 0, 0)

	# Position anchor within range
	_anchor.position = Vector3(5, 0, 0)
	_anchor.add_to_group("spectral_anchors")
	_anchor.set_pattern(PrismEnumsScript.PrismPattern.TRIANGLE)

	# Equip to players
	_calibrator.equip(_player_a)
	_lens_reader.equip(_player_b)

	# Link partners
	_calibrator.link_partner(_lens_reader)


func after_each() -> void:
	# Remove from groups before freeing to avoid group leaks
	if _anchor.is_in_group("spectral_anchors"):
		_anchor.remove_from_group("spectral_anchors")
	_calibrator.queue_free()
	_lens_reader.queue_free()
	_player_a.queue_free()
	_player_b.queue_free()
	_anchor.queue_free()


# --- Helpers ---


func _setup_aligned_calibrator() -> void:
	# Reset first to clear any previous state
	_calibrator.reset_calibration()
	_calibrator.activate_viewfinder()
	# Align all filters to target positions
	for i in range(_calibrator.FILTER_COUNT):
		var target: int = _calibrator._target_positions[i]
		var current: int = _calibrator.get_filter_position(i)
		var rotations := target - current
		if rotations < 0:
			rotations += _calibrator.POSITIONS_PER_FILTER
		for j in range(rotations):
			_calibrator.rotate_filter(i, 1)


# --- Test: Initial State ---


func test_initial_state_is_idle() -> void:
	var state := _calibrator.get_calibration_state()
	assert_eq(state, SpectralPrismCalibrator.CalibrationState.IDLE)


func test_initial_locked_pattern_is_none() -> void:
	var pattern := _calibrator.get_locked_pattern()
	assert_eq(pattern, PrismEnumsScript.PrismPattern.NONE)


func test_initial_filters_at_zero() -> void:
	var positions := _calibrator.get_all_filter_positions()
	assert_eq(positions, [0, 0, 0])


func test_equipment_type_is_calibrator() -> void:
	var eq_type := _calibrator.equipment_type
	assert_eq(eq_type, Equipment.EquipmentType.SPECTRAL_PRISM_CALIBRATOR)


func test_is_primary_equipment() -> void:
	assert_true(_calibrator.is_primary)


func test_viewfinder_not_active_initially() -> void:
	assert_false(_calibrator.is_viewfinder_active())


func test_not_aligned_initially() -> void:
	assert_false(_calibrator.is_aligned())


# --- Test: Viewfinder Activation ---


func test_activate_viewfinder_succeeds_with_anchor() -> void:
	var result := _calibrator.activate_viewfinder()
	assert_true(result)


func test_activate_viewfinder_sets_viewing_state() -> void:
	_calibrator.activate_viewfinder()
	var state := _calibrator.get_calibration_state()
	assert_eq(state, SpectralPrismCalibrator.CalibrationState.VIEWING)


func test_activate_viewfinder_emits_signal() -> void:
	watch_signals(_calibrator)
	_calibrator.activate_viewfinder()
	assert_signal_emitted(_calibrator, "viewfinder_activated")


func test_activate_viewfinder_fails_without_partner() -> void:
	_calibrator.unlink_partner()
	var result := _calibrator.activate_viewfinder()
	assert_false(result)


func test_activate_viewfinder_fails_without_anchor() -> void:
	_anchor.remove_from_group("spectral_anchors")
	var result := _calibrator.activate_viewfinder()
	_anchor.add_to_group("spectral_anchors")  # Restore for cleanup
	assert_false(result)


func test_activate_viewfinder_fails_when_locked() -> void:
	_calibrator.activate_viewfinder()
	_calibrator.lock_calibration()
	var result := _calibrator.activate_viewfinder()
	assert_false(result)


func test_activate_viewfinder_fails_when_partner_out_of_range() -> void:
	_player_b.position = Vector3(100, 0, 0)
	var result := _calibrator.activate_viewfinder()
	assert_false(result)


func test_activate_viewfinder_fails_when_anchor_out_of_range() -> void:
	var original_pos := _anchor.position
	_anchor.position = Vector3(100, 0, 0)
	var result := _calibrator.activate_viewfinder()
	_anchor.position = original_pos  # Restore
	assert_false(result)


func test_viewfinder_active_after_activation() -> void:
	_calibrator.activate_viewfinder()
	assert_true(_calibrator.is_viewfinder_active())


func test_get_current_anchor_returns_anchor() -> void:
	_calibrator.activate_viewfinder()
	assert_eq(_calibrator.get_current_anchor(), _anchor)


# --- Test: Viewfinder Deactivation ---


func test_deactivate_viewfinder_sets_idle_state() -> void:
	_calibrator.activate_viewfinder()
	_calibrator.deactivate_viewfinder()
	var state := _calibrator.get_calibration_state()
	assert_eq(state, SpectralPrismCalibrator.CalibrationState.IDLE)


func test_deactivate_viewfinder_emits_signal() -> void:
	_calibrator.activate_viewfinder()
	watch_signals(_calibrator)
	_calibrator.deactivate_viewfinder()
	assert_signal_emitted(_calibrator, "viewfinder_deactivated")


func test_deactivate_does_nothing_when_locked() -> void:
	_calibrator.activate_viewfinder()
	_calibrator.lock_calibration()
	_calibrator.deactivate_viewfinder()
	var state := _calibrator.get_calibration_state()
	assert_eq(state, SpectralPrismCalibrator.CalibrationState.LOCKED)


func test_viewfinder_not_active_after_deactivation() -> void:
	_calibrator.activate_viewfinder()
	_calibrator.deactivate_viewfinder()
	assert_false(_calibrator.is_viewfinder_active())


# --- Test: Filter Rotation ---


func test_rotate_filter_changes_position() -> void:
	_calibrator.activate_viewfinder()
	_calibrator.rotate_filter(0, 1)
	var pos := _calibrator.get_filter_position(0)
	assert_eq(pos, 1)


func test_rotate_filter_wraps_around() -> void:
	_calibrator.activate_viewfinder()
	for i in range(SpectralPrismCalibrator.POSITIONS_PER_FILTER):
		_calibrator.rotate_filter(0, 1)
	var pos := _calibrator.get_filter_position(0)
	assert_eq(pos, 0)


func test_rotate_filter_counter_clockwise() -> void:
	_calibrator.activate_viewfinder()
	_calibrator.rotate_filter(0, 1)
	_calibrator.rotate_filter(0, -1)
	var pos := _calibrator.get_filter_position(0)
	assert_eq(pos, 0)


func test_rotate_filter_counter_wraps_correctly() -> void:
	_calibrator.activate_viewfinder()
	_calibrator.rotate_filter(0, -1)
	var pos := _calibrator.get_filter_position(0)
	assert_eq(pos, SpectralPrismCalibrator.POSITIONS_PER_FILTER - 1)


func test_rotate_filter_emits_signal() -> void:
	_calibrator.activate_viewfinder()
	watch_signals(_calibrator)
	_calibrator.rotate_filter(0, 1)
	assert_signal_emitted(_calibrator, "filter_rotated")


func test_rotate_filter_transitions_to_aligning() -> void:
	_calibrator.activate_viewfinder()
	_calibrator.rotate_filter(0, 1)
	var state := _calibrator.get_calibration_state()
	assert_eq(state, SpectralPrismCalibrator.CalibrationState.ALIGNING)


func test_rotate_filter_fails_when_idle() -> void:
	var result := _calibrator.rotate_filter(0, 1)
	assert_false(result)


func test_rotate_filter_fails_when_locked() -> void:
	_calibrator.activate_viewfinder()
	_calibrator.lock_calibration()
	var result := _calibrator.rotate_filter(0, 1)
	assert_false(result)


func test_rotate_invalid_filter_fails() -> void:
	_calibrator.activate_viewfinder()
	var result := _calibrator.rotate_filter(-1, 1)
	assert_false(result)
	result = _calibrator.rotate_filter(99, 1)
	assert_false(result)


func test_rotate_all_filters() -> void:
	_calibrator.activate_viewfinder()
	_calibrator.rotate_all_filters(1)
	var positions := _calibrator.get_all_filter_positions()
	assert_eq(positions, [1, 1, 1])


func test_get_filter_count() -> void:
	var count := _calibrator.get_filter_count()
	assert_eq(count, 3)


func test_get_positions_per_filter() -> void:
	var positions := _calibrator.get_positions_per_filter()
	assert_eq(positions, 8)


# --- Test: Alignment Detection ---


func test_alignment_achieved_when_filters_match() -> void:
	_setup_aligned_calibrator()
	assert_true(_calibrator.is_aligned())


func test_alignment_achieved_emits_signal() -> void:
	_calibrator.activate_viewfinder()
	watch_signals(_calibrator)
	# Get target positions and align
	var target: int = _calibrator._target_positions[0]
	var current: int = _calibrator.get_filter_position(0)
	# Set other filters to aligned first
	for i in range(1, _calibrator.FILTER_COUNT):
		var t: int = _calibrator._target_positions[i]
		var c: int = _calibrator.get_filter_position(i)
		var rot := t - c
		if rot < 0:
			rot += _calibrator.POSITIONS_PER_FILTER
		for j in range(rot):
			_calibrator.rotate_filter(i, 1)
	# Now align the first filter
	var rotations := target - current
	if rotations < 0:
		rotations += _calibrator.POSITIONS_PER_FILTER
	for j in range(rotations):
		_calibrator.rotate_filter(0, 1)
	assert_signal_emitted(_calibrator, "alignment_achieved")


func test_alignment_lost_when_filter_moves() -> void:
	_setup_aligned_calibrator()
	watch_signals(_calibrator)
	_calibrator.rotate_filter(0, 1)
	assert_signal_emitted(_calibrator, "alignment_lost")


func test_get_current_pattern_when_aligned() -> void:
	_setup_aligned_calibrator()
	var pattern := _calibrator.get_current_pattern()
	assert_eq(pattern, PrismEnumsScript.PrismPattern.TRIANGLE)


func test_get_current_pattern_when_not_aligned() -> void:
	_calibrator.activate_viewfinder()
	var pattern := _calibrator.get_current_pattern()
	assert_eq(pattern, PrismEnumsScript.PrismPattern.NONE)


func test_alignment_progress_partial() -> void:
	_calibrator.activate_viewfinder()
	# Align just one filter
	var target: int = _calibrator._target_positions[0]
	var current: int = _calibrator.get_filter_position(0)
	var rotations := target - current
	if rotations < 0:
		rotations += _calibrator.POSITIONS_PER_FILTER
	for j in range(rotations):
		_calibrator.rotate_filter(0, 1)
	var progress := _calibrator.get_alignment_progress()
	# One of three filters aligned
	assert_almost_eq(progress, 1.0 / 3.0, 0.01)


func test_alignment_progress_full() -> void:
	_setup_aligned_calibrator()
	var progress := _calibrator.get_alignment_progress()
	assert_eq(progress, 1.0)


# --- Test: Lock Action ---


func test_lock_calibration_succeeds() -> void:
	_calibrator.activate_viewfinder()
	var result := _calibrator.lock_calibration()
	assert_true(result)


func test_lock_sets_locked_state() -> void:
	_calibrator.activate_viewfinder()
	_calibrator.lock_calibration()
	var state := _calibrator.get_calibration_state()
	assert_eq(state, SpectralPrismCalibrator.CalibrationState.LOCKED)


func test_lock_emits_signal() -> void:
	_calibrator.activate_viewfinder()
	watch_signals(_calibrator)
	_calibrator.lock_calibration()
	assert_signal_emitted(_calibrator, "calibration_locked")


func test_lock_captures_aligned_pattern() -> void:
	_setup_aligned_calibrator()
	_calibrator.lock_calibration()
	var pattern := _calibrator.get_locked_pattern()
	assert_eq(pattern, PrismEnumsScript.PrismPattern.TRIANGLE)


func test_lock_captures_none_when_misaligned() -> void:
	_calibrator.activate_viewfinder()
	_calibrator.rotate_filter(0, 1)  # Misalign
	_calibrator.lock_calibration()
	var pattern := _calibrator.get_locked_pattern()
	assert_eq(pattern, PrismEnumsScript.PrismPattern.NONE)


func test_lock_fails_when_idle() -> void:
	var result := _calibrator.lock_calibration()
	assert_false(result)


func test_lock_fails_when_already_locked() -> void:
	_calibrator.activate_viewfinder()
	_calibrator.lock_calibration()
	var result := _calibrator.lock_calibration()
	assert_false(result)


func test_is_properly_aligned_true() -> void:
	_setup_aligned_calibrator()
	_calibrator.lock_calibration()
	assert_true(_calibrator.is_properly_aligned())


func test_is_properly_aligned_false_when_misaligned() -> void:
	_calibrator.activate_viewfinder()
	_calibrator.rotate_filter(0, 1)
	_calibrator.lock_calibration()
	assert_false(_calibrator.is_properly_aligned())


func test_cannot_use_when_locked() -> void:
	_calibrator.activate_viewfinder()
	_calibrator.lock_calibration()
	var can_use: bool = _calibrator.can_use(_player_a)
	assert_false(can_use)


# --- Test: Reset ---


func test_reset_sets_idle_state() -> void:
	_calibrator.activate_viewfinder()
	_calibrator.lock_calibration()
	_calibrator.reset_calibration()
	var state := _calibrator.get_calibration_state()
	assert_eq(state, SpectralPrismCalibrator.CalibrationState.IDLE)


func test_reset_clears_locked_pattern() -> void:
	_setup_aligned_calibrator()
	_calibrator.lock_calibration()
	_calibrator.reset_calibration()
	var pattern := _calibrator.get_locked_pattern()
	assert_eq(pattern, PrismEnumsScript.PrismPattern.NONE)


func test_reset_clears_filter_positions() -> void:
	_calibrator.activate_viewfinder()
	_calibrator.rotate_all_filters(3)
	_calibrator.reset_calibration()
	var positions := _calibrator.get_all_filter_positions()
	assert_eq(positions, [0, 0, 0])


func test_reset_clears_aligned_state() -> void:
	_setup_aligned_calibrator()
	_calibrator.reset_calibration()
	assert_false(_calibrator.is_aligned())


func test_reset_emits_state_change_signal() -> void:
	_calibrator.activate_viewfinder()
	watch_signals(_calibrator)
	_calibrator.reset_calibration()
	assert_signal_emitted(_calibrator, "calibration_state_changed")


# --- Test: Different Patterns ---


func test_alignment_with_circle_pattern() -> void:
	# Change pattern and verify calibrator detects new pattern
	_anchor.true_pattern = PrismEnumsScript.PrismPattern.CIRCLE
	_calibrator.reset_calibration()
	_calibrator.activate_viewfinder()
	# Align to new targets
	for i in range(_calibrator.FILTER_COUNT):
		var target: int = _calibrator._target_positions[i]
		var current: int = _calibrator.get_filter_position(i)
		var rotations := target - current
		if rotations < 0:
			rotations += _calibrator.POSITIONS_PER_FILTER
		for j in range(rotations):
			_calibrator.rotate_filter(i, 1)
	var pattern := _calibrator.get_current_pattern()
	assert_eq(pattern, PrismEnumsScript.PrismPattern.CIRCLE)


func test_alignment_with_square_pattern() -> void:
	# Change pattern and verify calibrator detects new pattern
	_anchor.true_pattern = PrismEnumsScript.PrismPattern.SQUARE
	_calibrator.reset_calibration()
	_calibrator.activate_viewfinder()
	# Align to new targets
	for i in range(_calibrator.FILTER_COUNT):
		var target: int = _calibrator._target_positions[i]
		var current: int = _calibrator.get_filter_position(i)
		var rotations := target - current
		if rotations < 0:
			rotations += _calibrator.POSITIONS_PER_FILTER
		for j in range(rotations):
			_calibrator.rotate_filter(i, 1)
	var pattern := _calibrator.get_current_pattern()
	assert_eq(pattern, PrismEnumsScript.PrismPattern.SQUARE)


func test_alignment_with_spiral_pattern() -> void:
	# Change pattern and verify calibrator detects new pattern
	_anchor.true_pattern = PrismEnumsScript.PrismPattern.SPIRAL
	_calibrator.reset_calibration()
	_calibrator.activate_viewfinder()
	# Align to new targets
	for i in range(_calibrator.FILTER_COUNT):
		var target: int = _calibrator._target_positions[i]
		var current: int = _calibrator.get_filter_position(i)
		var rotations := target - current
		if rotations < 0:
			rotations += _calibrator.POSITIONS_PER_FILTER
		for j in range(rotations):
			_calibrator.rotate_filter(i, 1)
	var pattern := _calibrator.get_current_pattern()
	assert_eq(pattern, PrismEnumsScript.PrismPattern.SPIRAL)


# --- Test: Cultist Deception ---


func test_can_lock_at_wrong_alignment() -> void:
	_calibrator.activate_viewfinder()
	# Don't align properly - just rotate randomly
	_calibrator.rotate_filter(0, 2)
	_calibrator.rotate_filter(1, 5)
	var result := _calibrator.lock_calibration()
	assert_true(result)  # Lock succeeds even when misaligned


func test_misaligned_lock_pattern_is_none() -> void:
	_calibrator.activate_viewfinder()
	_calibrator.rotate_filter(0, 2)
	_calibrator.lock_calibration()
	var pattern := _calibrator.get_locked_pattern()
	# When locked while not aligned, pattern is NONE
	assert_eq(pattern, PrismEnumsScript.PrismPattern.NONE)


func test_no_enforcement_of_truthful_reporting() -> void:
	# This test documents that the game doesn't force truthful reporting
	# A cultist can lock at any position and announce any pattern
	_calibrator.activate_viewfinder()
	_calibrator.lock_calibration()  # Lock without aligning
	# The locked pattern is NONE, but verbally the player could say "Triangle"
	# No gameplay mechanic prevents this deception
	var locked := _calibrator.get_locked_pattern()
	# We just verify the mechanic exists - deception is social, not enforced
	assert_eq(locked, PrismEnumsScript.PrismPattern.NONE)


# --- Test: State Transitions ---


func test_state_transitions_idle_to_viewing() -> void:
	watch_signals(_calibrator)
	_calibrator.activate_viewfinder()
	assert_signal_emitted_with_parameters(
		_calibrator, "calibration_state_changed", [SpectralPrismCalibrator.CalibrationState.VIEWING]
	)


func test_state_transitions_viewing_to_aligning() -> void:
	_calibrator.activate_viewfinder()
	watch_signals(_calibrator)
	_calibrator.rotate_filter(0, 1)
	assert_signal_emitted_with_parameters(
		_calibrator,
		"calibration_state_changed",
		[SpectralPrismCalibrator.CalibrationState.ALIGNING]
	)


func test_state_transitions_aligning_to_locked() -> void:
	_calibrator.activate_viewfinder()
	_calibrator.rotate_filter(0, 1)
	watch_signals(_calibrator)
	_calibrator.lock_calibration()
	assert_signal_emitted_with_parameters(
		_calibrator, "calibration_state_changed", [SpectralPrismCalibrator.CalibrationState.LOCKED]
	)


func test_viewfinder_active_in_viewing_state() -> void:
	_calibrator.activate_viewfinder()
	assert_true(_calibrator.is_viewfinder_active())


func test_viewfinder_active_in_aligning_state() -> void:
	_calibrator.activate_viewfinder()
	_calibrator.rotate_filter(0, 1)
	assert_true(_calibrator.is_viewfinder_active())


func test_viewfinder_not_active_in_locked_state() -> void:
	_calibrator.activate_viewfinder()
	_calibrator.lock_calibration()
	assert_false(_calibrator.is_viewfinder_active())


# --- Test: Equipment Integration ---


func test_use_activates_viewfinder() -> void:
	_calibrator.use(_player_a)
	assert_true(_calibrator.is_viewfinder_active())


func test_toggle_off_deactivates_viewfinder() -> void:
	# Equipment uses TOGGLE mode, so use() again to turn off
	_calibrator.use(_player_a)
	_calibrator.use(_player_a)  # Toggle off
	assert_false(_calibrator.is_viewfinder_active())


func test_get_detectable_evidence() -> void:
	var evidence := _calibrator.get_detectable_evidence()
	assert_has(evidence, "spectral_pattern")


# --- Test: Network State ---


func test_network_state_includes_calibration_state() -> void:
	_calibrator.activate_viewfinder()
	var state := _calibrator.get_network_state()
	assert_has(state, "calibration_state")
	assert_eq(state["calibration_state"], SpectralPrismCalibrator.CalibrationState.VIEWING)


func test_network_state_includes_filter_positions() -> void:
	_calibrator.activate_viewfinder()
	_calibrator.rotate_filter(0, 3)
	var state := _calibrator.get_network_state()
	assert_has(state, "filter_positions")
	assert_eq(state["filter_positions"][0], 3)


func test_network_state_includes_locked_pattern() -> void:
	_setup_aligned_calibrator()
	_calibrator.lock_calibration()
	var state := _calibrator.get_network_state()
	assert_has(state, "locked_pattern")
	assert_eq(state["locked_pattern"], PrismEnumsScript.PrismPattern.TRIANGLE)


func test_apply_network_state() -> void:
	var state := {
		"calibration_state": SpectralPrismCalibrator.CalibrationState.LOCKED,
		"filter_positions": [1, 2, 3],
		"locked_pattern": PrismEnumsScript.PrismPattern.CIRCLE,
		"is_aligned": true,
	}
	_calibrator.apply_network_state(state)
	assert_eq(_calibrator.get_calibration_state(), SpectralPrismCalibrator.CalibrationState.LOCKED)
	assert_eq(_calibrator.get_locked_pattern(), PrismEnumsScript.PrismPattern.CIRCLE)
