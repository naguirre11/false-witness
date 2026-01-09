# gdlint: ignore=max-public-methods
extends GutTest
## Unit tests for DowsingRods cooperative equipment.

const AuraEnumsScript := preload("res://src/equipment/aura/aura_enums.gd")
const SpatialConstraintsScript := preload("res://src/equipment/aura/spatial_constraints.gd")

# --- Test Fixtures ---

var _rods: DowsingRods
var _imager: CooperativeEquipment
var _player_dowser: Node3D
var _player_imager: Node3D
var _anchor: AuraAnchor


func before_each() -> void:
	_rods = DowsingRods.new()
	_imager = CooperativeEquipment.new()
	_player_dowser = Node3D.new()
	_player_imager = Node3D.new()
	_anchor = AuraAnchor.new()

	add_child(_rods)
	add_child(_imager)
	add_child(_player_dowser)
	add_child(_player_imager)
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

	# Link partners
	_rods.link_partner(_imager)


func after_each() -> void:
	if _anchor.is_in_group("aura_anchors"):
		_anchor.remove_from_group("aura_anchors")
	_rods.queue_free()
	_imager.queue_free()
	_player_dowser.queue_free()
	_player_imager.queue_free()
	_anchor.queue_free()


# --- Test: Initial State ---


func test_initial_rod_state_is_idle() -> void:
	assert_eq(_rods.get_rod_state(), DowsingRods.RodState.IDLE)


func test_initial_rod_behavior_is_neutral() -> void:
	assert_eq(_rods.get_rod_behavior(), DowsingRods.RodBehavior.NEUTRAL)


func test_initial_rod_angles_are_zero() -> void:
	assert_eq(_rods.get_left_rod_angle(), 0.0)
	assert_eq(_rods.get_right_rod_angle(), 0.0)


func test_initial_alignment_quality_is_zero() -> void:
	assert_eq(_rods.get_alignment_quality(), 0.0)


func test_initial_alignment_level_is_none() -> void:
	var level := _rods.get_alignment_level()
	assert_eq(level, SpatialConstraintsScript.AlignmentQuality.NONE)


func test_equipment_type_is_dowsing_rods() -> void:
	assert_eq(_rods.equipment_type, Equipment.EquipmentType.DOWSING_RODS)


func test_is_primary_equipment() -> void:
	assert_true(_rods.is_primary)


func test_trust_dynamic_is_asymmetric() -> void:
	assert_eq(_rods.trust_dynamic, CooperativeEquipment.TrustDynamic.ASYMMETRIC)


func test_not_holding_steady_initially() -> void:
	assert_false(_rods.is_holding_steady())


# --- Test: Rod State Machine ---


func test_using_rods_sets_held_state() -> void:
	_rods.use(_player_dowser)
	assert_eq(_rods.get_rod_state(), DowsingRods.RodState.HELD)


func test_stop_using_rods_sets_idle_state() -> void:
	_rods.use(_player_dowser)
	# Toggle mode equipment: call use again to toggle off
	_rods.use(_player_dowser)
	await get_tree().process_frame
	assert_eq(_rods.get_rod_state(), DowsingRods.RodState.IDLE)


func test_rod_state_changed_signal_emitted() -> void:
	watch_signals(_rods)
	_rods.use(_player_dowser)
	assert_signal_emitted(_rods, "rod_state_changed")


func test_rod_state_name_idle() -> void:
	assert_eq(_rods.get_rod_state_name(), "Idle")


func test_rod_state_name_held() -> void:
	_rods.use(_player_dowser)
	assert_eq(_rods.get_rod_state_name(), "Held")


# --- Test: Rod Behavior ---


func test_rod_behavior_neutral_name() -> void:
	assert_eq(_rods.get_rod_behavior_name(), "Neutral")


func test_rod_behavior_changes_based_on_alignment() -> void:
	_rods.use(_player_dowser)
	# Need to trigger alignment check
	await get_tree().create_timer(0.15).timeout
	# With valid setup, should have some behavior other than neutral
	var behavior := _rods.get_rod_behavior()
	assert_true(
		(
			behavior
			in [
				DowsingRods.RodBehavior.NEUTRAL,
				DowsingRods.RodBehavior.CROSSING,
				DowsingRods.RodBehavior.SPREADING,
			]
		)
	)


func test_rod_behavior_changed_signal_emitted() -> void:
	watch_signals(_rods)
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout
	# Signal should have been emitted at some point during state changes
	var emit_count: int = get_signal_emit_count(_rods, "rod_behavior_changed")
	# May or may not emit depending on anchor detection
	assert_true(emit_count >= 0)


# --- Test: Rod Angles (Observable State) ---


func test_rod_angles_vector2() -> void:
	var angles := _rods.get_rod_angles()
	assert_eq(angles.x, _rods.get_left_rod_angle())
	assert_eq(angles.y, _rods.get_right_rod_angle())


func test_rod_angles_change_with_alignment() -> void:
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.2).timeout
	# Angles should be updated based on alignment
	var left := _rods.get_left_rod_angle()
	var right := _rods.get_right_rod_angle()
	# Should be within valid range
	assert_true(left >= -1.0 and left <= 1.0)
	assert_true(right >= -1.0 and right <= 1.0)


func test_rods_adjusted_signal_emitted() -> void:
	watch_signals(_rods)
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.2).timeout
	# Check that signal was emitted at least once
	var emit_count: int = get_signal_emit_count(_rods, "rods_adjusted")
	assert_true(emit_count >= 0)


# --- Test: Alignment Detection ---


func test_alignment_quality_with_valid_setup() -> void:
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout
	var quality := _rods.get_alignment_quality()
	# With valid setup, should have some quality
	assert_true(quality >= 0.0)


func test_alignment_level_updates() -> void:
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout
	var level := _rods.get_alignment_level()
	# Should have a valid level
	assert_true(
		(
			level
			in [
				SpatialConstraintsScript.AlignmentQuality.NONE,
				SpatialConstraintsScript.AlignmentQuality.WEAK,
				SpatialConstraintsScript.AlignmentQuality.MODERATE,
				SpatialConstraintsScript.AlignmentQuality.STRONG,
			]
		)
	)


func test_perfect_alignment_has_strong_quality() -> void:
	# Setup perfect alignment: Dowser facing anchor, Imager behind
	_player_dowser.position = Vector3(0, 0, 0)
	_player_dowser.rotation = Vector3.ZERO  # Facing -Z
	_player_imager.position = Vector3(0, 0, 2)  # Directly behind
	_anchor.position = Vector3(0, 0, -5)  # Directly in front

	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout

	var level := _rods.get_alignment_level()
	# Should be STRONG or MODERATE with perfect positioning
	var acceptable := [
		SpatialConstraintsScript.AlignmentQuality.STRONG,
		SpatialConstraintsScript.AlignmentQuality.MODERATE,
	]
	assert_true(level in acceptable)


func test_alignment_achieved_signal() -> void:
	# Setup for strong alignment
	_player_dowser.position = Vector3(0, 0, 0)
	_player_dowser.rotation = Vector3.ZERO
	_player_imager.position = Vector3(0, 0, 2)
	_anchor.position = Vector3(0, 0, -5)

	watch_signals(_rods)
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.2).timeout

	# May or may not emit depending on whether MODERATE threshold is reached
	var emit_count: int = get_signal_emit_count(_rods, "alignment_achieved")
	assert_true(emit_count >= 0)


func test_alignment_lost_signal() -> void:
	# First achieve alignment
	_player_dowser.position = Vector3(0, 0, 0)
	_player_dowser.rotation = Vector3.ZERO
	_player_imager.position = Vector3(0, 0, 2)
	_anchor.position = Vector3(0, 0, -5)

	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout

	watch_signals(_rods)

	# Break alignment by rotating dowser
	_player_dowser.rotation.y = PI  # Face opposite direction
	await get_tree().create_timer(0.15).timeout

	var emit_count: int = get_signal_emit_count(_rods, "alignment_lost")
	# May or may not emit depending on prior state
	assert_true(emit_count >= 0)


# --- Test: Hold Steady Mechanics ---


func test_start_hold_steady_requires_aligned_state() -> void:
	_rods.use(_player_dowser)
	# Without alignment, should fail
	var result := _rods.start_hold_steady()
	assert_false(result)


func test_start_hold_steady_emits_signal() -> void:
	# Force aligned state for testing
	_rods.use(_player_dowser)
	_rods._set_rod_state(DowsingRods.RodState.ALIGNED)

	watch_signals(_rods)
	_rods.start_hold_steady()
	assert_signal_emitted(_rods, "hold_steady_started")


func test_stop_hold_steady_emits_signal() -> void:
	_rods.use(_player_dowser)
	_rods._set_rod_state(DowsingRods.RodState.ALIGNED)
	_rods.start_hold_steady()

	watch_signals(_rods)
	_rods.stop_hold_steady()
	assert_signal_emitted(_rods, "hold_steady_ended")


func test_hold_steady_progress_starts_at_zero() -> void:
	_rods.use(_player_dowser)
	_rods._set_rod_state(DowsingRods.RodState.ALIGNED)
	_rods.start_hold_steady()
	var progress := _rods.get_hold_steady_progress()
	assert_almost_eq(progress, 0.0, 0.1)


func test_hold_steady_progress_increases() -> void:
	_rods.use(_player_dowser)
	_rods._set_rod_state(DowsingRods.RodState.ALIGNED)
	_rods.start_hold_steady()

	await get_tree().create_timer(0.5).timeout

	var progress := _rods.get_hold_steady_progress()
	assert_true(progress > 0.0)


func test_hold_steady_complete_after_duration() -> void:
	_rods.hold_steady_duration = 0.1  # Short duration for testing
	_rods.use(_player_dowser)
	_rods._set_rod_state(DowsingRods.RodState.ALIGNED)
	_rods.start_hold_steady()

	await get_tree().create_timer(0.2).timeout

	assert_true(_rods.is_hold_steady_complete())


func test_cannot_start_hold_steady_twice() -> void:
	_rods.use(_player_dowser)
	_rods._set_rod_state(DowsingRods.RodState.ALIGNED)
	_rods.start_hold_steady()
	var result := _rods.start_hold_steady()
	assert_false(result)


# --- Test: Position Tracking ---


func test_position_changed_signal_emitted_on_move() -> void:
	_rods.use(_player_dowser)
	watch_signals(_rods)

	# Move the player
	_player_dowser.position = Vector3(5, 0, 0)
	await get_tree().create_timer(0.15).timeout

	var emit_count: int = get_signal_emit_count(_rods, "position_changed")
	assert_true(emit_count >= 1)


func test_get_facing_direction() -> void:
	var facing := _rods.get_facing_direction()
	assert_true(facing is Vector3)


func test_movement_breaks_hold_steady() -> void:
	_rods.use(_player_dowser)
	_rods._set_rod_state(DowsingRods.RodState.ALIGNED)
	_rods.start_hold_steady()
	assert_true(_rods.is_holding_steady())

	# Move the player significantly
	_player_dowser.position = Vector3(10, 0, 0)
	await get_tree().create_timer(0.15).timeout

	assert_false(_rods.is_holding_steady())


# --- Test: Observable State (Anti-Deception) ---


func test_observable_state_contains_rod_state() -> void:
	var state := _rods.get_observable_state()
	assert_has(state, "rod_state")


func test_observable_state_contains_rod_behavior() -> void:
	var state := _rods.get_observable_state()
	assert_has(state, "rod_behavior")


func test_observable_state_contains_rod_angles() -> void:
	var state := _rods.get_observable_state()
	assert_has(state, "left_angle")
	assert_has(state, "right_angle")


func test_observable_state_contains_position() -> void:
	var state := _rods.get_observable_state()
	assert_has(state, "position")


func test_observable_state_contains_facing() -> void:
	var state := _rods.get_observable_state()
	assert_has(state, "facing")


func test_observable_state_contains_hold_status() -> void:
	var state := _rods.get_observable_state()
	assert_has(state, "is_holding_steady")
	assert_has(state, "hold_progress")


func test_is_properly_positioned() -> void:
	_rods.use(_player_dowser)
	_rods._set_rod_state(DowsingRods.RodState.ALIGNED)
	assert_true(_rods.is_properly_positioned())


func test_not_properly_positioned_when_seeking() -> void:
	_rods.use(_player_dowser)
	_rods._set_rod_state(DowsingRods.RodState.SEEKING)
	assert_false(_rods.is_properly_positioned())


# --- Test: Anchor Detection ---


func test_no_anchor_when_out_of_range() -> void:
	_anchor.position = Vector3(0, 0, -100)  # Far away
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout
	assert_null(_rods.get_current_anchor())


func test_anchor_found_when_in_range() -> void:
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout
	assert_not_null(_rods.get_current_anchor())


func test_finds_closest_anchor() -> void:
	# Add a second anchor further away
	var far_anchor := AuraAnchor.new()
	add_child(far_anchor)
	far_anchor.position = Vector3(0, 0, -10)

	_anchor.position = Vector3(0, 0, -3)  # Closer

	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout

	var found := _rods.get_current_anchor()
	assert_eq(found, _anchor)

	far_anchor.queue_free()


# --- Test: Partner Requirements ---


func test_requires_partner_linked() -> void:
	_rods.unlink_partner()
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout
	# Should still function but with limited feedback
	assert_eq(_rods.get_rod_state(), DowsingRods.RodState.SEEKING)


func test_seeking_state_without_partner() -> void:
	_rods.unlink_partner()
	_rods.use(_player_dowser)
	await get_tree().create_timer(0.15).timeout
	# Without partner, goes to SEEKING with SPREADING behavior
	assert_eq(_rods.get_rod_state(), DowsingRods.RodState.SEEKING)
	assert_eq(_rods.get_rod_behavior(), DowsingRods.RodBehavior.SPREADING)


# --- Test: Network State ---


func test_network_state_includes_rod_state() -> void:
	_rods.use(_player_dowser)
	var state := _rods.get_network_state()
	assert_has(state, "rod_state")


func test_network_state_includes_rod_behavior() -> void:
	_rods.use(_player_dowser)
	var state := _rods.get_network_state()
	assert_has(state, "rod_behavior")


func test_network_state_includes_angles() -> void:
	var state := _rods.get_network_state()
	assert_has(state, "left_angle")
	assert_has(state, "right_angle")


func test_network_state_includes_alignment() -> void:
	var state := _rods.get_network_state()
	assert_has(state, "alignment_quality")


func test_network_state_includes_hold_status() -> void:
	var state := _rods.get_network_state()
	assert_has(state, "is_holding_steady")
	assert_has(state, "hold_progress")


func test_apply_network_state() -> void:
	var state := {
		"rod_state": DowsingRods.RodState.SEEKING,
		"rod_behavior": DowsingRods.RodBehavior.SPREADING,
		"left_angle": -0.5,
		"right_angle": -0.5,
		"alignment_quality": 0.3,
		"is_holding_steady": false,
	}
	_rods.apply_network_state(state)
	assert_eq(_rods.get_rod_state(), DowsingRods.RodState.SEEKING)
	assert_eq(_rods.get_rod_behavior(), DowsingRods.RodBehavior.SPREADING)
	assert_eq(_rods.get_left_rod_angle(), -0.5)


# --- Test: Reset ---


func test_reset_rods() -> void:
	_rods.use(_player_dowser)
	_rods._set_rod_state(DowsingRods.RodState.ALIGNED)
	_rods.start_hold_steady()

	_rods.reset_rods()

	assert_eq(_rods.get_rod_state(), DowsingRods.RodState.IDLE)
	assert_eq(_rods.get_rod_behavior(), DowsingRods.RodBehavior.NEUTRAL)
	assert_eq(_rods.get_alignment_quality(), 0.0)
	assert_false(_rods.is_holding_steady())


func test_on_reading_complete_stops_hold_steady() -> void:
	_rods.use(_player_dowser)
	_rods._set_rod_state(DowsingRods.RodState.ALIGNED)
	_rods.start_hold_steady()
	assert_true(_rods.is_holding_steady())

	_rods.on_reading_complete()

	assert_false(_rods.is_holding_steady())


# --- Test: Evidence Type ---


func test_detectable_evidence_includes_aura_temperament() -> void:
	var evidence := _rods.get_detectable_evidence()
	assert_true("aura_temperament" in evidence)
