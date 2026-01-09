extends GutTest
## Unit tests for SpectralPrismLensReader.

const PrismEnumsScript := preload("res://src/equipment/spectral_prism/prism_enums.gd")

# --- Test Helpers ---

var _calibrator: SpectralPrismCalibrator
var _lens_reader: SpectralPrismLensReader
var _player_a: Node3D
var _player_b: Node3D
var _anchor: SpectralAnchor


func before_each() -> void:
	_calibrator = SpectralPrismCalibrator.new()
	_lens_reader = SpectralPrismLensReader.new()
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
	if _anchor.is_in_group("spectral_anchors"):
		_anchor.remove_from_group("spectral_anchors")
	_calibrator.queue_free()
	_lens_reader.queue_free()
	_player_a.queue_free()
	_player_b.queue_free()
	_anchor.queue_free()


# --- Helpers ---


func _setup_aligned_and_locked_calibrator() -> void:
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
	# Lock the calibration
	_calibrator.lock_calibration()


func _setup_misaligned_and_locked_calibrator() -> void:
	_calibrator.reset_calibration()
	_calibrator.activate_viewfinder()
	# Don't align - just lock in wrong position
	_calibrator.lock_calibration()


# ===========================================================================
# Test: Initial State
# ===========================================================================


func test_initial_state_is_idle() -> void:
	var state := _lens_reader.get_reader_state()
	assert_eq(state, SpectralPrismLensReader.ReaderState.IDLE)


func test_initial_no_calibration() -> void:
	assert_false(_lens_reader.has_calibration())


func test_initial_received_pattern_is_none() -> void:
	var pattern := _lens_reader.get_received_pattern()
	assert_eq(pattern, PrismEnumsScript.PrismPattern.NONE)


func test_equipment_type_is_lens() -> void:
	var eq_type := _lens_reader.equipment_type
	assert_eq(eq_type, Equipment.EquipmentType.SPECTRAL_PRISM_LENS)


func test_is_not_primary_equipment() -> void:
	assert_false(_lens_reader.is_primary)


func test_eyepiece_initially_inactive() -> void:
	assert_false(_lens_reader.is_eyepiece_active())


# ===========================================================================
# Test: Activation Rules
# ===========================================================================


func test_cannot_activate_without_calibration() -> void:
	var result := _lens_reader.activate_eyepiece()
	assert_false(result)


func test_state_becomes_waiting_without_calibration() -> void:
	_lens_reader.activate_eyepiece()
	var state := _lens_reader.get_reader_state()
	assert_eq(state, SpectralPrismLensReader.ReaderState.WAITING)


func test_can_activate_after_calibration_locked() -> void:
	_setup_aligned_and_locked_calibrator()
	var result := _lens_reader.activate_eyepiece()
	assert_true(result)


func test_state_is_viewing_after_activation() -> void:
	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()
	var state := _lens_reader.get_reader_state()
	assert_eq(state, SpectralPrismLensReader.ReaderState.VIEWING)


func test_eyepiece_active_after_activation() -> void:
	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()
	assert_true(_lens_reader.is_eyepiece_active())


func test_cannot_activate_without_partner() -> void:
	_setup_aligned_and_locked_calibrator()
	_lens_reader.unlink_partner()
	var result := _lens_reader.activate_eyepiece()
	assert_false(result)


func test_cannot_activate_if_partner_out_of_range() -> void:
	_setup_aligned_and_locked_calibrator()
	_player_a.position = Vector3(100, 0, 0)  # Far away
	var result := _lens_reader.activate_eyepiece()
	assert_false(result)


# ===========================================================================
# Test: Calibration Callback
# ===========================================================================


func test_receives_calibration_from_partner() -> void:
	_setup_aligned_and_locked_calibrator()
	assert_true(_lens_reader.has_calibration())


func test_received_pattern_matches_locked_pattern() -> void:
	_setup_aligned_and_locked_calibrator()
	var received := _lens_reader.get_received_pattern()
	var locked := _calibrator.get_locked_pattern()
	assert_eq(received, locked)


func test_calibration_received_signal_emitted() -> void:
	var state := {"received": false, "pattern": -1}
	_lens_reader.calibration_received.connect(
		func(pattern: int): state["received"] = true; state["pattern"] = pattern
	)
	_setup_aligned_and_locked_calibrator()
	assert_true(state["received"])


func test_waiting_state_clears_on_calibration() -> void:
	# Put lens reader in waiting state
	_lens_reader.activate_eyepiece()
	assert_eq(_lens_reader.get_reader_state(), SpectralPrismLensReader.ReaderState.WAITING)

	# Calibrator locks
	_setup_aligned_and_locked_calibrator()

	# Should return to idle (ready to activate)
	assert_eq(_lens_reader.get_reader_state(), SpectralPrismLensReader.ReaderState.IDLE)


# ===========================================================================
# Test: Eyepiece Display (Shape + Color)
# ===========================================================================


func test_pattern_shape_from_calibrator() -> void:
	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()
	var shape := _lens_reader.get_pattern_shape()
	assert_eq(shape, PrismEnumsScript.PrismPattern.TRIANGLE)


func test_pattern_color_from_anchor() -> void:
	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()
	var color := _lens_reader.get_pattern_color()
	# Triangle pattern maps to BLUE_VIOLET color
	assert_eq(color, PrismEnumsScript.PrismColor.BLUE_VIOLET)


func test_combined_signature_format() -> void:
	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()
	var signature := _lens_reader.get_combined_signature()
	assert_eq(signature, "Blue-Violet Triangle")


func test_pattern_shape_none_when_eyepiece_inactive() -> void:
	_setup_aligned_and_locked_calibrator()
	# Don't activate eyepiece
	var shape := _lens_reader.get_pattern_shape()
	assert_eq(shape, PrismEnumsScript.PrismPattern.NONE)


func test_pattern_color_none_when_eyepiece_inactive() -> void:
	_setup_aligned_and_locked_calibrator()
	# Don't activate eyepiece
	var color := _lens_reader.get_pattern_color()
	assert_eq(color, PrismEnumsScript.PrismColor.NONE)


# ===========================================================================
# Test: Consistency Detection
# ===========================================================================


func test_is_consistent_when_properly_aligned() -> void:
	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()
	assert_true(_lens_reader.is_consistent())


func test_is_inconsistent_when_misaligned() -> void:
	_setup_misaligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()
	# Misaligned = NONE pattern, which is inconsistent with any color
	assert_false(_lens_reader.is_consistent())


func test_indicated_category_from_color() -> void:
	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()
	var category := _lens_reader.get_indicated_category()
	# Blue-violet indicates PASSIVE
	assert_eq(category, PrismEnumsScript.EntityCategory.PASSIVE)


func test_different_patterns_with_colors() -> void:
	# Test with CIRCLE pattern (AGGRESSIVE)
	_anchor.set_pattern(PrismEnumsScript.PrismPattern.CIRCLE)
	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()

	var shape := _lens_reader.get_pattern_shape()
	var color := _lens_reader.get_pattern_color()

	assert_eq(shape, PrismEnumsScript.PrismPattern.CIRCLE)
	assert_eq(color, PrismEnumsScript.PrismColor.RED_ORANGE)
	assert_true(_lens_reader.is_consistent())


func test_square_pattern_with_green_color() -> void:
	_anchor.set_pattern(PrismEnumsScript.PrismPattern.SQUARE)
	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()

	assert_eq(_lens_reader.get_pattern_shape(), PrismEnumsScript.PrismPattern.SQUARE)
	assert_eq(_lens_reader.get_pattern_color(), PrismEnumsScript.PrismColor.GREEN)
	assert_true(_lens_reader.is_consistent())


func test_spiral_pattern_with_yellow_color() -> void:
	_anchor.set_pattern(PrismEnumsScript.PrismPattern.SPIRAL)
	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()

	assert_eq(_lens_reader.get_pattern_shape(), PrismEnumsScript.PrismPattern.SPIRAL)
	assert_eq(_lens_reader.get_pattern_color(), PrismEnumsScript.PrismColor.YELLOW)
	assert_true(_lens_reader.is_consistent())


# ===========================================================================
# Test: Reading / Evidence Collection
# ===========================================================================


func test_cannot_start_reading_before_viewing() -> void:
	_setup_aligned_and_locked_calibrator()
	# Don't activate eyepiece
	var result := _lens_reader.start_reading()
	assert_false(result)


func test_cannot_start_reading_immediately() -> void:
	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()
	# Immediately try to read (before MIN_VIEWING_TIME)
	var result := _lens_reader.start_reading()
	assert_false(result)


func test_can_start_reading_after_min_viewing_time() -> void:
	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()
	# Simulate time passing
	_lens_reader._viewing_start_time = (Time.get_ticks_msec() / 1000.0) - 2.0
	var result := _lens_reader.start_reading()
	assert_true(result)


func test_state_is_reading_during_read() -> void:
	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()
	_lens_reader._viewing_start_time = (Time.get_ticks_msec() / 1000.0) - 2.0
	_lens_reader.start_reading()
	assert_eq(_lens_reader.get_reader_state(), SpectralPrismLensReader.ReaderState.READING)


func test_is_reading_returns_true_during_read() -> void:
	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()
	_lens_reader._viewing_start_time = (Time.get_ticks_msec() / 1000.0) - 2.0
	_lens_reader.start_reading()
	assert_true(_lens_reader.is_reading())


func test_reading_progress_starts_at_zero() -> void:
	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()
	_lens_reader._viewing_start_time = (Time.get_ticks_msec() / 1000.0) - 2.0
	_lens_reader.start_reading()
	assert_eq(_lens_reader.get_reading_progress(), 0.0)


func test_reading_progress_increases() -> void:
	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()
	_lens_reader._viewing_start_time = (Time.get_ticks_msec() / 1000.0) - 2.0
	_lens_reader.start_reading()

	# Simulate time passing
	_lens_reader._process(1.0)

	assert_gt(_lens_reader.get_reading_progress(), 0.0)


func test_cancel_reading_returns_to_viewing() -> void:
	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()
	_lens_reader._viewing_start_time = (Time.get_ticks_msec() / 1000.0) - 2.0
	_lens_reader.start_reading()
	_lens_reader.cancel_reading()

	assert_eq(_lens_reader.get_reader_state(), SpectralPrismLensReader.ReaderState.VIEWING)


func test_cancel_reading_resets_progress() -> void:
	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()
	_lens_reader._viewing_start_time = (Time.get_ticks_msec() / 1000.0) - 2.0
	_lens_reader.start_reading()
	_lens_reader._process(0.5)  # Some progress
	_lens_reader.cancel_reading()

	assert_eq(_lens_reader.get_reading_progress(), 0.0)


# ===========================================================================
# Test: Quality Assessment
# ===========================================================================


func test_strong_quality_when_aligned_and_stationary() -> void:
	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()
	# Simulate sufficient viewing time
	_lens_reader._viewing_start_time = (Time.get_ticks_msec() / 1000.0) - 5.0
	_lens_reader._update_quality()

	assert_eq(_lens_reader.get_current_quality(), EvidenceEnums.ReadingQuality.STRONG)


func test_weak_quality_when_misaligned() -> void:
	_setup_misaligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()
	_lens_reader._viewing_start_time = (Time.get_ticks_msec() / 1000.0) - 5.0
	_lens_reader._update_quality()

	assert_eq(_lens_reader.get_current_quality(), EvidenceEnums.ReadingQuality.WEAK)


func test_weak_quality_when_viewing_time_short() -> void:
	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()
	# Short viewing time (less than STRONG_QUALITY_TIME)
	_lens_reader._viewing_start_time = (Time.get_ticks_msec() / 1000.0) - 1.0
	_lens_reader._update_quality()

	assert_eq(_lens_reader.get_current_quality(), EvidenceEnums.ReadingQuality.WEAK)


func test_weak_quality_when_moving() -> void:
	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()
	_lens_reader._viewing_start_time = (Time.get_ticks_msec() / 1000.0) - 5.0
	# Simulate significant movement
	_lens_reader._total_movement = 1.0
	_lens_reader._update_quality()

	assert_eq(_lens_reader.get_current_quality(), EvidenceEnums.ReadingQuality.WEAK)


func test_quality_changed_signal_emitted() -> void:
	var state := {"changed": false}
	_lens_reader.quality_changed.connect(func(_q: int): state["changed"] = true)

	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()
	_lens_reader._viewing_start_time = (Time.get_ticks_msec() / 1000.0) - 5.0
	# Force quality recalculation
	_lens_reader._current_quality = EvidenceEnums.ReadingQuality.WEAK
	_lens_reader._update_quality()

	assert_true(state["changed"])


# ===========================================================================
# Test: Deactivation
# ===========================================================================


func test_deactivate_eyepiece_returns_to_idle() -> void:
	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()
	_lens_reader.deactivate_eyepiece()

	assert_eq(_lens_reader.get_reader_state(), SpectralPrismLensReader.ReaderState.IDLE)


func test_deactivate_emits_signal() -> void:
	var state := {"deactivated": false}
	_lens_reader.eyepiece_deactivated.connect(func(): state["deactivated"] = true)

	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()
	_lens_reader.deactivate_eyepiece()

	assert_true(state["deactivated"])


func test_deactivate_during_reading() -> void:
	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()
	_lens_reader._viewing_start_time = (Time.get_ticks_msec() / 1000.0) - 2.0
	_lens_reader.start_reading()
	_lens_reader.deactivate_eyepiece()

	assert_eq(_lens_reader.get_reader_state(), SpectralPrismLensReader.ReaderState.IDLE)
	assert_eq(_lens_reader.get_reading_progress(), 0.0)


# ===========================================================================
# Test: Reset
# ===========================================================================


func test_reset_clears_calibration() -> void:
	_setup_aligned_and_locked_calibrator()
	_lens_reader.reset_reader()

	assert_false(_lens_reader.has_calibration())


func test_reset_clears_pattern() -> void:
	_setup_aligned_and_locked_calibrator()
	_lens_reader.reset_reader()

	assert_eq(_lens_reader.get_received_pattern(), PrismEnumsScript.PrismPattern.NONE)


func test_reset_returns_to_idle() -> void:
	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()
	_lens_reader.reset_reader()

	assert_eq(_lens_reader.get_reader_state(), SpectralPrismLensReader.ReaderState.IDLE)


# ===========================================================================
# Test: Network State
# ===========================================================================


func test_network_state_includes_reader_state() -> void:
	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()

	var state := _lens_reader.get_network_state()

	assert_has(state, "reader_state")
	assert_eq(state["reader_state"], SpectralPrismLensReader.ReaderState.VIEWING)


func test_network_state_includes_calibration() -> void:
	_setup_aligned_and_locked_calibrator()

	var state := _lens_reader.get_network_state()

	assert_has(state, "calibration_locked")
	assert_true(state["calibration_locked"])


func test_network_state_includes_quality() -> void:
	var state := _lens_reader.get_network_state()

	assert_has(state, "current_quality")


func test_apply_network_state() -> void:
	var state := {
		"reader_state": SpectralPrismLensReader.ReaderState.VIEWING,
		"received_pattern": PrismEnumsScript.PrismPattern.CIRCLE,
		"calibration_locked": true,
		"calibrator_aligned": true,
		"reading_progress": 0.5,
		"current_quality": EvidenceEnums.ReadingQuality.WEAK,
	}

	_lens_reader.apply_network_state(state)

	assert_eq(_lens_reader.get_reader_state(), SpectralPrismLensReader.ReaderState.VIEWING)
	assert_eq(_lens_reader.get_received_pattern(), PrismEnumsScript.PrismPattern.CIRCLE)
	assert_true(_lens_reader.has_calibration())
	assert_eq(_lens_reader.get_reading_progress(), 0.5)
	assert_eq(_lens_reader.get_current_quality(), EvidenceEnums.ReadingQuality.WEAK)


# ===========================================================================
# Test: Equipment Overrides
# ===========================================================================


func test_use_activates_eyepiece() -> void:
	_setup_aligned_and_locked_calibrator()
	_lens_reader.use(_player_b)

	assert_true(_lens_reader.is_eyepiece_active())


func test_toggle_off_deactivates_eyepiece() -> void:
	_setup_aligned_and_locked_calibrator()
	_lens_reader.use(_player_b)  # Toggle on
	_lens_reader.use(_player_b)  # Toggle off

	assert_false(_lens_reader.is_eyepiece_active())


func test_detectable_evidence_includes_prism_reading() -> void:
	var evidence := _lens_reader.get_detectable_evidence()
	assert_has(evidence, "prism_reading")


# ===========================================================================
# Test: Signals
# ===========================================================================


func test_reader_state_changed_signal() -> void:
	var state := {"changed": false, "new_state": -1}
	_lens_reader.reader_state_changed.connect(
		func(s: int): state["changed"] = true; state["new_state"] = s
	)

	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()

	assert_true(state["changed"])
	assert_eq(state["new_state"], SpectralPrismLensReader.ReaderState.VIEWING)


func test_eyepiece_activated_signal() -> void:
	var state := {"activated": false}
	_lens_reader.eyepiece_activated.connect(func(): state["activated"] = true)

	_setup_aligned_and_locked_calibrator()
	_lens_reader.activate_eyepiece()

	assert_true(state["activated"])
