extends GutTest
## Unit tests for PrismEnums helper methods.


# --- Test: Pattern to Category Mapping ---


func test_triangle_maps_to_passive() -> void:
	var category := PrismEnums.get_category_from_pattern(PrismEnums.PrismPattern.TRIANGLE)
	assert_eq(category, PrismEnums.EntityCategory.PASSIVE)


func test_circle_maps_to_aggressive() -> void:
	var category := PrismEnums.get_category_from_pattern(PrismEnums.PrismPattern.CIRCLE)
	assert_eq(category, PrismEnums.EntityCategory.AGGRESSIVE)


func test_square_maps_to_territorial() -> void:
	var category := PrismEnums.get_category_from_pattern(PrismEnums.PrismPattern.SQUARE)
	assert_eq(category, PrismEnums.EntityCategory.TERRITORIAL)


func test_spiral_maps_to_mobile() -> void:
	var category := PrismEnums.get_category_from_pattern(PrismEnums.PrismPattern.SPIRAL)
	assert_eq(category, PrismEnums.EntityCategory.MOBILE)


func test_none_pattern_maps_to_unknown() -> void:
	var category := PrismEnums.get_category_from_pattern(PrismEnums.PrismPattern.NONE)
	assert_eq(category, PrismEnums.EntityCategory.UNKNOWN)


# --- Test: Color to Category Mapping ---


func test_blue_violet_maps_to_passive() -> void:
	var category := PrismEnums.get_category_from_color(PrismEnums.PrismColor.BLUE_VIOLET)
	assert_eq(category, PrismEnums.EntityCategory.PASSIVE)


func test_red_orange_maps_to_aggressive() -> void:
	var category := PrismEnums.get_category_from_color(PrismEnums.PrismColor.RED_ORANGE)
	assert_eq(category, PrismEnums.EntityCategory.AGGRESSIVE)


func test_green_maps_to_territorial() -> void:
	var category := PrismEnums.get_category_from_color(PrismEnums.PrismColor.GREEN)
	assert_eq(category, PrismEnums.EntityCategory.TERRITORIAL)


func test_yellow_maps_to_mobile() -> void:
	var category := PrismEnums.get_category_from_color(PrismEnums.PrismColor.YELLOW)
	assert_eq(category, PrismEnums.EntityCategory.MOBILE)


func test_none_color_maps_to_unknown() -> void:
	var category := PrismEnums.get_category_from_color(PrismEnums.PrismColor.NONE)
	assert_eq(category, PrismEnums.EntityCategory.UNKNOWN)


# --- Test: Expected Color for Pattern ---


func test_triangle_expects_blue_violet() -> void:
	var color := PrismEnums.get_expected_color(PrismEnums.PrismPattern.TRIANGLE)
	assert_eq(color, PrismEnums.PrismColor.BLUE_VIOLET)


func test_circle_expects_red_orange() -> void:
	var color := PrismEnums.get_expected_color(PrismEnums.PrismPattern.CIRCLE)
	assert_eq(color, PrismEnums.PrismColor.RED_ORANGE)


func test_square_expects_green() -> void:
	var color := PrismEnums.get_expected_color(PrismEnums.PrismPattern.SQUARE)
	assert_eq(color, PrismEnums.PrismColor.GREEN)


func test_spiral_expects_yellow() -> void:
	var color := PrismEnums.get_expected_color(PrismEnums.PrismPattern.SPIRAL)
	assert_eq(color, PrismEnums.PrismColor.YELLOW)


func test_none_pattern_expects_none_color() -> void:
	var color := PrismEnums.get_expected_color(PrismEnums.PrismPattern.NONE)
	assert_eq(color, PrismEnums.PrismColor.NONE)


# --- Test: Expected Pattern for Color ---


func test_blue_violet_expects_triangle() -> void:
	var pattern := PrismEnums.get_expected_pattern(PrismEnums.PrismColor.BLUE_VIOLET)
	assert_eq(pattern, PrismEnums.PrismPattern.TRIANGLE)


func test_red_orange_expects_circle() -> void:
	var pattern := PrismEnums.get_expected_pattern(PrismEnums.PrismColor.RED_ORANGE)
	assert_eq(pattern, PrismEnums.PrismPattern.CIRCLE)


func test_green_expects_square() -> void:
	var pattern := PrismEnums.get_expected_pattern(PrismEnums.PrismColor.GREEN)
	assert_eq(pattern, PrismEnums.PrismPattern.SQUARE)


func test_yellow_expects_spiral() -> void:
	var pattern := PrismEnums.get_expected_pattern(PrismEnums.PrismColor.YELLOW)
	assert_eq(pattern, PrismEnums.PrismPattern.SPIRAL)


func test_none_color_expects_none_pattern() -> void:
	var pattern := PrismEnums.get_expected_pattern(PrismEnums.PrismColor.NONE)
	assert_eq(pattern, PrismEnums.PrismPattern.NONE)


# --- Test: Consistency Check ---


func test_triangle_blue_violet_is_consistent() -> void:
	assert_true(PrismEnums.is_consistent(
		PrismEnums.PrismPattern.TRIANGLE,
		PrismEnums.PrismColor.BLUE_VIOLET
	))


func test_circle_red_orange_is_consistent() -> void:
	assert_true(PrismEnums.is_consistent(
		PrismEnums.PrismPattern.CIRCLE,
		PrismEnums.PrismColor.RED_ORANGE
	))


func test_square_green_is_consistent() -> void:
	assert_true(PrismEnums.is_consistent(
		PrismEnums.PrismPattern.SQUARE,
		PrismEnums.PrismColor.GREEN
	))


func test_spiral_yellow_is_consistent() -> void:
	assert_true(PrismEnums.is_consistent(
		PrismEnums.PrismPattern.SPIRAL,
		PrismEnums.PrismColor.YELLOW
	))


func test_triangle_red_orange_is_inconsistent() -> void:
	assert_false(PrismEnums.is_consistent(
		PrismEnums.PrismPattern.TRIANGLE,
		PrismEnums.PrismColor.RED_ORANGE
	))


func test_circle_green_is_inconsistent() -> void:
	assert_false(PrismEnums.is_consistent(
		PrismEnums.PrismPattern.CIRCLE,
		PrismEnums.PrismColor.GREEN
	))


func test_none_pattern_is_never_consistent() -> void:
	assert_false(PrismEnums.is_consistent(
		PrismEnums.PrismPattern.NONE,
		PrismEnums.PrismColor.BLUE_VIOLET
	))


func test_none_color_is_never_consistent() -> void:
	assert_false(PrismEnums.is_consistent(
		PrismEnums.PrismPattern.TRIANGLE,
		PrismEnums.PrismColor.NONE
	))


# --- Test: Display Names ---


func test_get_pattern_name_triangle() -> void:
	assert_eq(PrismEnums.get_pattern_name(PrismEnums.PrismPattern.TRIANGLE), "Triangle")


func test_get_pattern_name_circle() -> void:
	assert_eq(PrismEnums.get_pattern_name(PrismEnums.PrismPattern.CIRCLE), "Circle")


func test_get_pattern_name_square() -> void:
	assert_eq(PrismEnums.get_pattern_name(PrismEnums.PrismPattern.SQUARE), "Square")


func test_get_pattern_name_spiral() -> void:
	assert_eq(PrismEnums.get_pattern_name(PrismEnums.PrismPattern.SPIRAL), "Spiral")


func test_get_pattern_name_none() -> void:
	assert_eq(PrismEnums.get_pattern_name(PrismEnums.PrismPattern.NONE), "None")


func test_get_color_name_blue_violet() -> void:
	assert_eq(PrismEnums.get_color_name(PrismEnums.PrismColor.BLUE_VIOLET), "Blue-Violet")


func test_get_color_name_red_orange() -> void:
	assert_eq(PrismEnums.get_color_name(PrismEnums.PrismColor.RED_ORANGE), "Red-Orange")


func test_get_color_name_green() -> void:
	assert_eq(PrismEnums.get_color_name(PrismEnums.PrismColor.GREEN), "Green")


func test_get_color_name_yellow() -> void:
	assert_eq(PrismEnums.get_color_name(PrismEnums.PrismColor.YELLOW), "Yellow")


func test_get_color_name_none() -> void:
	assert_eq(PrismEnums.get_color_name(PrismEnums.PrismColor.NONE), "None")


func test_get_category_name_passive() -> void:
	assert_eq(PrismEnums.get_category_name(PrismEnums.EntityCategory.PASSIVE), "Passive")


func test_get_category_name_aggressive() -> void:
	assert_eq(PrismEnums.get_category_name(PrismEnums.EntityCategory.AGGRESSIVE), "Aggressive")


func test_get_category_name_territorial() -> void:
	assert_eq(PrismEnums.get_category_name(PrismEnums.EntityCategory.TERRITORIAL), "Territorial")


func test_get_category_name_mobile() -> void:
	assert_eq(PrismEnums.get_category_name(PrismEnums.EntityCategory.MOBILE), "Mobile")


func test_get_category_name_unknown() -> void:
	assert_eq(PrismEnums.get_category_name(PrismEnums.EntityCategory.UNKNOWN), "Unknown")


# --- Test: Enum Collections ---


func test_get_all_patterns_returns_four() -> void:
	var patterns := PrismEnums.get_all_patterns()
	assert_eq(patterns.size(), 4)


func test_get_all_patterns_excludes_none() -> void:
	var patterns := PrismEnums.get_all_patterns()
	assert_false(patterns.has(PrismEnums.PrismPattern.NONE))


func test_get_all_colors_returns_four() -> void:
	var colors := PrismEnums.get_all_colors()
	assert_eq(colors.size(), 4)


func test_get_all_colors_excludes_none() -> void:
	var colors := PrismEnums.get_all_colors()
	assert_false(colors.has(PrismEnums.PrismColor.NONE))


# --- Test: Enum Counts ---


func test_prism_pattern_has_five_values() -> void:
	assert_eq(PrismEnums.PrismPattern.size(), 5, "Expected 5 PrismPattern values (including NONE)")


func test_prism_color_has_five_values() -> void:
	assert_eq(PrismEnums.PrismColor.size(), 5, "Expected 5 PrismColor values (including NONE)")


func test_entity_category_has_five_values() -> void:
	assert_eq(PrismEnums.EntityCategory.size(), 5, "Expected 5 EntityCategory values")


# --- Test: Bidirectional Mapping Consistency ---


func test_all_pattern_color_mappings_are_bidirectional() -> void:
	for pattern: PrismEnums.PrismPattern in PrismEnums.get_all_patterns():
		var expected_color := PrismEnums.get_expected_color(pattern)
		var reverse_pattern := PrismEnums.get_expected_pattern(expected_color)
		assert_eq(
			reverse_pattern, pattern,
			"Pattern %s -> Color -> Pattern should round-trip" % pattern
		)


func test_all_color_pattern_mappings_are_bidirectional() -> void:
	for color: PrismEnums.PrismColor in PrismEnums.get_all_colors():
		var expected_pattern := PrismEnums.get_expected_pattern(color)
		var reverse_color := PrismEnums.get_expected_color(expected_pattern)
		assert_eq(
			reverse_color, color,
			"Color %s -> Pattern -> Color should round-trip" % color
		)
