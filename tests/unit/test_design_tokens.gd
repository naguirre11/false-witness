extends GutTest
## Unit tests for DesignTokens autoload.
##
## Verifies that all design tokens are accessible and have correct value types.


# --- Test: Autoload Accessibility ---


func test_design_tokens_autoload_is_accessible() -> void:
	var tokens: Node = get_node_or_null("/root/DesignTokens")
	assert_not_null(tokens, "DesignTokens autoload should be accessible")


# --- Test: COLORS Dictionary ---


func test_colors_dictionary_exists() -> void:
	assert_true(
		DesignTokens.COLORS is Dictionary, "COLORS should be a Dictionary"
	)


func test_colors_contains_background_colors() -> void:
	assert_has(DesignTokens.COLORS, "bg_primary")
	assert_has(DesignTokens.COLORS, "bg_secondary")
	assert_has(DesignTokens.COLORS, "bg_surface")
	assert_has(DesignTokens.COLORS, "bg_overlay")


func test_colors_contains_text_colors() -> void:
	assert_has(DesignTokens.COLORS, "text_primary")
	assert_has(DesignTokens.COLORS, "text_secondary")
	assert_has(DesignTokens.COLORS, "text_muted")
	assert_has(DesignTokens.COLORS, "text_danger")


func test_colors_contains_accent_colors() -> void:
	assert_has(DesignTokens.COLORS, "accent_primary")
	assert_has(DesignTokens.COLORS, "accent_secondary")
	assert_has(DesignTokens.COLORS, "accent_warning")
	assert_has(DesignTokens.COLORS, "accent_success")


func test_colors_contains_horror_colors() -> void:
	assert_has(DesignTokens.COLORS, "horror_blood")
	assert_has(DesignTokens.COLORS, "horror_ethereal")
	assert_has(DesignTokens.COLORS, "horror_corruption")


func test_colors_contains_trust_level_colors() -> void:
	assert_has(DesignTokens.COLORS, "trust_unfalsifiable")
	assert_has(DesignTokens.COLORS, "trust_high")
	assert_has(DesignTokens.COLORS, "trust_variable")
	assert_has(DesignTokens.COLORS, "trust_low")
	assert_has(DesignTokens.COLORS, "trust_sabotage")


func test_colors_contains_evidence_category_colors() -> void:
	assert_has(DesignTokens.COLORS, "evidence_equipment")
	assert_has(DesignTokens.COLORS, "evidence_apparent")
	assert_has(DesignTokens.COLORS, "evidence_triggered")
	assert_has(DesignTokens.COLORS, "evidence_behavior")


func test_colors_values_are_color_type() -> void:
	for key: String in DesignTokens.COLORS:
		var value: Variant = DesignTokens.COLORS[key]
		assert_true(value is Color, "COLORS['%s'] should be a Color" % key)


# --- Test: PLAYER_COLORS Array ---


func test_player_colors_array_exists() -> void:
	assert_true(
		DesignTokens.PLAYER_COLORS is Array, "PLAYER_COLORS should be an Array"
	)


func test_player_colors_has_eight_entries() -> void:
	assert_eq(
		DesignTokens.PLAYER_COLORS.size(), 8, "PLAYER_COLORS should have 8 colors"
	)


func test_player_colors_values_are_color_type() -> void:
	for i in range(DesignTokens.PLAYER_COLORS.size()):
		var color: Variant = DesignTokens.PLAYER_COLORS[i]
		assert_true(color is Color, "PLAYER_COLORS[%d] should be a Color" % i)


# --- Test: SPACING Dictionary ---


func test_spacing_dictionary_exists() -> void:
	assert_true(
		DesignTokens.SPACING is Dictionary, "SPACING should be a Dictionary"
	)


func test_spacing_contains_all_sizes() -> void:
	assert_has(DesignTokens.SPACING, "xs")
	assert_has(DesignTokens.SPACING, "sm")
	assert_has(DesignTokens.SPACING, "md")
	assert_has(DesignTokens.SPACING, "lg")
	assert_has(DesignTokens.SPACING, "xl")
	assert_has(DesignTokens.SPACING, "xxl")


func test_spacing_values_are_positive_integers() -> void:
	for key: String in DesignTokens.SPACING:
		var value: Variant = DesignTokens.SPACING[key]
		assert_true(value is int, "SPACING['%s'] should be an int" % key)
		assert_gt(value, 0, "SPACING['%s'] should be positive" % key)


func test_spacing_values_are_ascending() -> void:
	assert_lt(DesignTokens.SPACING["xs"], DesignTokens.SPACING["sm"])
	assert_lt(DesignTokens.SPACING["sm"], DesignTokens.SPACING["md"])
	assert_lt(DesignTokens.SPACING["md"], DesignTokens.SPACING["lg"])
	assert_lt(DesignTokens.SPACING["lg"], DesignTokens.SPACING["xl"])
	assert_lt(DesignTokens.SPACING["xl"], DesignTokens.SPACING["xxl"])


# --- Test: FONT_SIZES Dictionary ---


func test_font_sizes_dictionary_exists() -> void:
	assert_true(
		DesignTokens.FONT_SIZES is Dictionary, "FONT_SIZES should be a Dictionary"
	)


func test_font_sizes_contains_all_sizes() -> void:
	assert_has(DesignTokens.FONT_SIZES, "xs")
	assert_has(DesignTokens.FONT_SIZES, "sm")
	assert_has(DesignTokens.FONT_SIZES, "md")
	assert_has(DesignTokens.FONT_SIZES, "lg")
	assert_has(DesignTokens.FONT_SIZES, "xl")
	assert_has(DesignTokens.FONT_SIZES, "xxl")
	assert_has(DesignTokens.FONT_SIZES, "display")


func test_font_sizes_values_are_positive_integers() -> void:
	for key: String in DesignTokens.FONT_SIZES:
		var value: Variant = DesignTokens.FONT_SIZES[key]
		assert_true(value is int, "FONT_SIZES['%s'] should be an int" % key)
		assert_gt(value, 0, "FONT_SIZES['%s'] should be positive" % key)


# --- Test: ANIMATION Dictionary ---


func test_animation_dictionary_exists() -> void:
	assert_true(
		DesignTokens.ANIMATION is Dictionary, "ANIMATION should be a Dictionary"
	)


func test_animation_contains_standard_durations() -> void:
	assert_has(DesignTokens.ANIMATION, "duration_instant")
	assert_has(DesignTokens.ANIMATION, "duration_fast")
	assert_has(DesignTokens.ANIMATION, "duration_normal")
	assert_has(DesignTokens.ANIMATION, "duration_slow")


func test_animation_contains_horror_durations() -> void:
	assert_has(DesignTokens.ANIMATION, "duration_tension")
	assert_has(DesignTokens.ANIMATION, "duration_reveal")
	assert_has(DesignTokens.ANIMATION, "duration_startle")


func test_animation_values_are_positive_floats() -> void:
	for key: String in DesignTokens.ANIMATION:
		var value: Variant = DesignTokens.ANIMATION[key]
		assert_true(
			value is float or value is int, "ANIMATION['%s'] should be numeric" % key
		)
		assert_gt(value, 0.0, "ANIMATION['%s'] should be positive" % key)


# --- Test: BORDERS Dictionary ---


func test_borders_dictionary_exists() -> void:
	assert_true(
		DesignTokens.BORDERS is Dictionary, "BORDERS should be a Dictionary"
	)


func test_borders_contains_radii() -> void:
	assert_has(DesignTokens.BORDERS, "radius_none")
	assert_has(DesignTokens.BORDERS, "radius_sm")
	assert_has(DesignTokens.BORDERS, "radius_md")
	assert_has(DesignTokens.BORDERS, "radius_lg")
	assert_has(DesignTokens.BORDERS, "radius_full")


func test_borders_contains_widths() -> void:
	assert_has(DesignTokens.BORDERS, "width_thin")
	assert_has(DesignTokens.BORDERS, "width_normal")
	assert_has(DesignTokens.BORDERS, "width_thick")


func test_borders_values_are_non_negative_integers() -> void:
	for key: String in DesignTokens.BORDERS:
		var value: Variant = DesignTokens.BORDERS[key]
		assert_true(value is int, "BORDERS['%s'] should be an int" % key)
		assert_gte(value, 0, "BORDERS['%s'] should be non-negative" % key)
