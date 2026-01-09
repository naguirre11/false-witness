extends GutTest
## Unit tests for SpatialConstraints validation system.


# --- Test Helpers ---


func _make_dowser_facing_anchor() -> Dictionary:
	## Creates a setup where Dowser is facing anchor perfectly.
	return {
		"dowser_pos": Vector3(0, 0, 0),
		"dowser_forward": Vector3(0, 0, -1),  # Facing -Z
		"imager_pos": Vector3(0, 0, 2),  # Behind Dowser (+Z)
		"anchor_pos": Vector3(0, 0, -5),  # In front of Dowser
	}


func _make_valid_setup() -> Dictionary:
	## Creates a fully valid spatial setup.
	return _make_dowser_facing_anchor()


# --- Test: Dowser Facing Anchor ---


func test_dowser_facing_anchor_directly_is_valid() -> void:
	var setup := _make_valid_setup()
	var result := SpatialConstraints.check_dowser_facing_anchor(
		setup.dowser_pos, setup.dowser_forward, setup.anchor_pos
	)
	assert_true(result.is_valid)
	assert_almost_eq(result.angle, 0.0, 0.01)


func test_dowser_facing_anchor_within_tolerance_is_valid() -> void:
	var setup := _make_valid_setup()
	# Rotate forward slightly (15 degrees)
	var forward: Vector3 = setup.dowser_forward
	var rotated_forward: Vector3 = forward.rotated(Vector3.UP, deg_to_rad(15))
	var result := SpatialConstraints.check_dowser_facing_anchor(
		setup.dowser_pos, rotated_forward, setup.anchor_pos
	)
	assert_true(result.is_valid)


func test_dowser_facing_away_from_anchor_is_invalid() -> void:
	var setup := _make_valid_setup()
	# Face opposite direction
	var wrong_forward := Vector3(0, 0, 1)  # Facing +Z instead of -Z
	var result := SpatialConstraints.check_dowser_facing_anchor(
		setup.dowser_pos, wrong_forward, setup.anchor_pos
	)
	assert_false(result.is_valid)
	assert_true(result.violation.length() > 0)


func test_dowser_facing_perpendicular_is_invalid() -> void:
	var setup := _make_valid_setup()
	# Face 90 degrees off
	var perpendicular := Vector3(1, 0, 0)
	var result := SpatialConstraints.check_dowser_facing_anchor(
		setup.dowser_pos, perpendicular, setup.anchor_pos
	)
	assert_false(result.is_valid)


func test_dowser_at_boundary_tolerance() -> void:
	var setup := _make_valid_setup()
	var forward: Vector3 = setup.dowser_forward
	# Rotate exactly to boundary (30 degrees default)
	var boundary_forward: Vector3 = forward.rotated(Vector3.UP, deg_to_rad(29))
	var result := SpatialConstraints.check_dowser_facing_anchor(
		setup.dowser_pos, boundary_forward, setup.anchor_pos
	)
	assert_true(result.is_valid)

	# Just over boundary
	var over_boundary: Vector3 = forward.rotated(Vector3.UP, deg_to_rad(31))
	var result2 := SpatialConstraints.check_dowser_facing_anchor(
		setup.dowser_pos, over_boundary, setup.anchor_pos
	)
	assert_false(result2.is_valid)


func test_custom_facing_tolerance() -> void:
	var setup := _make_valid_setup()
	var forward: Vector3 = setup.dowser_forward
	# Rotate 45 degrees
	var rotated: Vector3 = forward.rotated(Vector3.UP, deg_to_rad(45))

	# Should fail with default (30 degree) tolerance
	var result1 := SpatialConstraints.check_dowser_facing_anchor(
		setup.dowser_pos, rotated, setup.anchor_pos, deg_to_rad(30)
	)
	assert_false(result1.is_valid)

	# Should pass with larger (60 degree) tolerance
	var result2 := SpatialConstraints.check_dowser_facing_anchor(
		setup.dowser_pos, rotated, setup.anchor_pos, deg_to_rad(60)
	)
	assert_true(result2.is_valid)


# --- Test: Imager Behind Dowser ---


func test_imager_directly_behind_is_valid() -> void:
	var setup := _make_valid_setup()
	var result := SpatialConstraints.check_imager_behind_dowser(
		setup.dowser_pos, setup.dowser_forward, setup.imager_pos
	)
	assert_true(result.is_valid)
	assert_almost_eq(result.angle, 0.0, 0.01)


func test_imager_behind_within_tolerance_is_valid() -> void:
	var setup := _make_valid_setup()
	# Offset imager to the side but still behind (30 degrees)
	var offset_imager := Vector3(1, 0, 2)
	var result := SpatialConstraints.check_imager_behind_dowser(
		setup.dowser_pos, setup.dowser_forward, offset_imager
	)
	assert_true(result.is_valid)


func test_imager_in_front_is_invalid() -> void:
	var setup := _make_valid_setup()
	# Put imager in front of Dowser
	var front_imager := Vector3(0, 0, -2)
	var result := SpatialConstraints.check_imager_behind_dowser(
		setup.dowser_pos, setup.dowser_forward, front_imager
	)
	assert_false(result.is_valid)
	assert_true(result.violation.length() > 0)


func test_imager_to_side_is_invalid() -> void:
	var setup := _make_valid_setup()
	# Put imager directly to the side (90 degrees)
	var side_imager := Vector3(5, 0, 0)
	var result := SpatialConstraints.check_imager_behind_dowser(
		setup.dowser_pos, setup.dowser_forward, side_imager
	)
	assert_false(result.is_valid)


func test_imager_at_boundary_tolerance() -> void:
	var setup := _make_valid_setup()
	# Calculate position at exactly 59 degrees behind (within 60 degree tolerance)
	var angle := deg_to_rad(59)
	var dist := 2.0
	var offset_pos := Vector3(sin(angle) * dist, 0, cos(angle) * dist)
	var result := SpatialConstraints.check_imager_behind_dowser(
		setup.dowser_pos, setup.dowser_forward, offset_pos
	)
	assert_true(result.is_valid)


# --- Test: Imager Distance ---


func test_imager_at_valid_distance() -> void:
	var setup := _make_valid_setup()
	var result := SpatialConstraints.check_imager_distance(
		setup.dowser_pos, setup.imager_pos
	)
	assert_true(result.is_valid)


func test_imager_too_close() -> void:
	var setup := _make_valid_setup()
	var close_imager := Vector3(0, 0, 0.5)  # Only 0.5m away
	var result := SpatialConstraints.check_imager_distance(
		setup.dowser_pos, close_imager
	)
	assert_false(result.is_valid)
	assert_true("too close" in result.violation.to_lower())


func test_imager_too_far() -> void:
	var setup := _make_valid_setup()
	var far_imager := Vector3(0, 0, 10)  # 10m away
	var result := SpatialConstraints.check_imager_distance(
		setup.dowser_pos, far_imager
	)
	assert_false(result.is_valid)
	assert_true("too far" in result.violation.to_lower())


func test_imager_at_min_distance_boundary() -> void:
	var result := SpatialConstraints.check_imager_distance(
		Vector3.ZERO, Vector3(0, 0, 1.0), 1.0, 5.0  # Exactly at min
	)
	assert_true(result.is_valid)


func test_imager_at_max_distance_boundary() -> void:
	var result := SpatialConstraints.check_imager_distance(
		Vector3.ZERO, Vector3(0, 0, 5.0), 1.0, 5.0  # Exactly at max
	)
	assert_true(result.is_valid)


# --- Test: Full Validation ---


func test_validate_positions_all_valid() -> void:
	var setup := _make_valid_setup()
	var result := SpatialConstraints.validate_positions(
		setup.dowser_pos, setup.dowser_forward, setup.imager_pos, setup.anchor_pos
	)
	assert_true(result.is_valid)
	assert_eq(result.violations.size(), 0)


func test_validate_positions_dowser_not_facing() -> void:
	var setup := _make_valid_setup()
	setup.dowser_forward = Vector3(1, 0, 0)  # Wrong direction
	var result := SpatialConstraints.validate_positions(
		setup.dowser_pos, setup.dowser_forward, setup.imager_pos, setup.anchor_pos
	)
	assert_false(result.is_valid)
	assert_true(result.violations.size() > 0)


func test_validate_positions_imager_not_behind() -> void:
	var setup := _make_valid_setup()
	setup.imager_pos = Vector3(0, 0, -3)  # In front instead of behind
	var result := SpatialConstraints.validate_positions(
		setup.dowser_pos, setup.dowser_forward, setup.imager_pos, setup.anchor_pos
	)
	assert_false(result.is_valid)


func test_validate_positions_multiple_violations() -> void:
	var setup := _make_valid_setup()
	setup.dowser_forward = Vector3(1, 0, 0)  # Wrong direction
	setup.imager_pos = Vector3(0, 0, -3)  # In front
	var result := SpatialConstraints.validate_positions(
		setup.dowser_pos, setup.dowser_forward, setup.imager_pos, setup.anchor_pos
	)
	assert_false(result.is_valid)
	assert_true(result.violations.size() >= 2)


func test_validate_positions_with_custom_config() -> void:
	var setup := _make_valid_setup()
	# Rotate dowser 45 degrees off
	setup.dowser_forward = setup.dowser_forward.rotated(Vector3.UP, deg_to_rad(45))

	# Should fail with default config
	var result1 := SpatialConstraints.validate_positions(
		setup.dowser_pos, setup.dowser_forward, setup.imager_pos, setup.anchor_pos
	)
	assert_false(result1.is_valid)

	# Should pass with relaxed config
	var config := SpatialConstraints.ConstraintConfig.custom(60.0, 90.0)
	var result2 := SpatialConstraints.validate_positions(
		setup.dowser_pos, setup.dowser_forward, setup.imager_pos, setup.anchor_pos, config
	)
	assert_true(result2.is_valid)


# --- Test: Alignment Quality ---


func test_perfect_alignment_quality_is_one() -> void:
	var setup := _make_valid_setup()
	var quality := SpatialConstraints.calculate_alignment_quality(
		setup.dowser_pos, setup.dowser_forward, setup.imager_pos, setup.anchor_pos
	)
	assert_almost_eq(quality, 1.0, 0.01)


func test_invalid_alignment_quality_is_zero() -> void:
	var setup := _make_valid_setup()
	setup.dowser_forward = Vector3(1, 0, 0)  # Wrong direction
	var quality := SpatialConstraints.calculate_alignment_quality(
		setup.dowser_pos, setup.dowser_forward, setup.imager_pos, setup.anchor_pos
	)
	assert_eq(quality, 0.0)


func test_partial_alignment_quality_is_between_zero_and_one() -> void:
	var setup := _make_valid_setup()
	# Rotate dowser 15 degrees off (half of 30 degree tolerance)
	setup.dowser_forward = setup.dowser_forward.rotated(Vector3.UP, deg_to_rad(15))
	var quality := SpatialConstraints.calculate_alignment_quality(
		setup.dowser_pos, setup.dowser_forward, setup.imager_pos, setup.anchor_pos
	)
	assert_true(quality > 0.0)
	assert_true(quality < 1.0)


# --- Test: Quality Levels ---


func test_quality_level_none() -> void:
	assert_eq(SpatialConstraints.get_quality_level(0.0), SpatialConstraints.AlignmentQuality.NONE)
	assert_eq(SpatialConstraints.get_quality_level(-0.5), SpatialConstraints.AlignmentQuality.NONE)


func test_quality_level_weak() -> void:
	assert_eq(SpatialConstraints.get_quality_level(0.2), SpatialConstraints.AlignmentQuality.WEAK)
	assert_eq(SpatialConstraints.get_quality_level(0.39), SpatialConstraints.AlignmentQuality.WEAK)


func test_quality_level_moderate() -> void:
	assert_eq(SpatialConstraints.get_quality_level(0.4), SpatialConstraints.AlignmentQuality.MODERATE)
	assert_eq(SpatialConstraints.get_quality_level(0.69), SpatialConstraints.AlignmentQuality.MODERATE)


func test_quality_level_strong() -> void:
	assert_eq(SpatialConstraints.get_quality_level(0.7), SpatialConstraints.AlignmentQuality.STRONG)
	assert_eq(SpatialConstraints.get_quality_level(1.0), SpatialConstraints.AlignmentQuality.STRONG)


func test_quality_level_names() -> void:
	var none_name := SpatialConstraints.get_quality_name(SpatialConstraints.AlignmentQuality.NONE)
	assert_eq(none_name, "No Alignment")
	var weak_name := SpatialConstraints.get_quality_name(SpatialConstraints.AlignmentQuality.WEAK)
	assert_eq(weak_name, "Weak")
	var mod_name := SpatialConstraints.get_quality_name(SpatialConstraints.AlignmentQuality.MODERATE)
	assert_eq(mod_name, "Moderate")
	var strong_name := SpatialConstraints.get_quality_name(SpatialConstraints.AlignmentQuality.STRONG)
	assert_eq(strong_name, "Strong")


# --- Test: Config ---


func test_default_config_values() -> void:
	var config := SpatialConstraints.ConstraintConfig.new()
	assert_almost_eq(config.dowser_facing_tolerance, deg_to_rad(30.0), 0.001)
	assert_almost_eq(config.imager_behind_tolerance, deg_to_rad(60.0), 0.001)
	assert_eq(config.min_imager_distance, 1.0)
	assert_eq(config.max_imager_distance, 5.0)


func test_custom_config() -> void:
	var config := SpatialConstraints.ConstraintConfig.custom(45.0, 90.0, 2.0, 10.0)
	assert_almost_eq(config.dowser_facing_tolerance, deg_to_rad(45.0), 0.001)
	assert_almost_eq(config.imager_behind_tolerance, deg_to_rad(90.0), 0.001)
	assert_eq(config.min_imager_distance, 2.0)
	assert_eq(config.max_imager_distance, 10.0)


# --- Test: Constraint Result ---


func test_constraint_result_default() -> void:
	var result := SpatialConstraints.ConstraintResult.new()
	assert_false(result.is_valid)
	assert_eq(result.violations.size(), 0)


func test_constraint_result_valid() -> void:
	var result := SpatialConstraints.ConstraintResult.new(true)
	assert_true(result.is_valid)


# --- Test: Edge Cases ---


func test_zero_forward_vector_handled() -> void:
	var setup := _make_valid_setup()
	setup.dowser_forward = Vector3.ZERO
	var result := SpatialConstraints.check_dowser_facing_anchor(
		setup.dowser_pos, setup.dowser_forward, setup.anchor_pos
	)
	assert_false(result.is_valid)


func test_same_position_dowser_and_anchor() -> void:
	var setup := _make_valid_setup()
	setup.anchor_pos = setup.dowser_pos  # Same position
	var result := SpatialConstraints.check_dowser_facing_anchor(
		setup.dowser_pos, setup.dowser_forward, setup.anchor_pos
	)
	# Should handle gracefully (direction to anchor is zero vector)
	assert_false(result.is_valid)


func test_vertical_angle_ignored_for_facing() -> void:
	var setup := _make_valid_setup()
	# Anchor is above Dowser but in same horizontal direction
	setup.anchor_pos = Vector3(0, 5, -5)
	var result := SpatialConstraints.check_dowser_facing_anchor(
		setup.dowser_pos, setup.dowser_forward, setup.anchor_pos
	)
	# Should still be valid because horizontal facing is correct
	assert_true(result.is_valid)


func test_vertical_position_ignored_for_behind() -> void:
	var setup := _make_valid_setup()
	# Imager is above Dowser but still behind horizontally
	setup.imager_pos = Vector3(0, 3, 2)
	var result := SpatialConstraints.check_imager_behind_dowser(
		setup.dowser_pos, setup.dowser_forward, setup.imager_pos
	)
	# Should still be valid because horizontal position is behind
	assert_true(result.is_valid)
