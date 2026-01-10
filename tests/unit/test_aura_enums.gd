extends GutTest
## Unit tests for AuraEnums helper methods.


# --- Test: Color to Temperament Mapping ---


func test_cold_blue_maps_to_passive() -> void:
	var temperament := AuraEnums.get_temperament_from_color(AuraEnums.AuraColor.COLD_BLUE)
	assert_eq(temperament, AuraEnums.EntityTemperament.PASSIVE)


func test_hot_red_maps_to_aggressive() -> void:
	var temperament := AuraEnums.get_temperament_from_color(AuraEnums.AuraColor.HOT_RED)
	assert_eq(temperament, AuraEnums.EntityTemperament.AGGRESSIVE)


func test_pale_green_maps_to_territorial() -> void:
	var temperament := AuraEnums.get_temperament_from_color(AuraEnums.AuraColor.PALE_GREEN)
	assert_eq(temperament, AuraEnums.EntityTemperament.TERRITORIAL)


func test_deep_purple_maps_to_roaming() -> void:
	var temperament := AuraEnums.get_temperament_from_color(AuraEnums.AuraColor.DEEP_PURPLE)
	assert_eq(temperament, AuraEnums.EntityTemperament.ROAMING)


func test_none_color_maps_to_unknown() -> void:
	var temperament := AuraEnums.get_temperament_from_color(AuraEnums.AuraColor.NONE)
	assert_eq(temperament, AuraEnums.EntityTemperament.UNKNOWN)


# --- Test: Form to Temperament Mapping ---


func test_tight_contained_maps_to_passive() -> void:
	var temperament := AuraEnums.get_temperament_from_form(AuraEnums.AuraForm.TIGHT_CONTAINED)
	assert_eq(temperament, AuraEnums.EntityTemperament.PASSIVE)


func test_spiking_erratic_maps_to_aggressive() -> void:
	var temperament := AuraEnums.get_temperament_from_form(AuraEnums.AuraForm.SPIKING_ERRATIC)
	assert_eq(temperament, AuraEnums.EntityTemperament.AGGRESSIVE)


func test_diffuse_spreading_maps_to_territorial() -> void:
	var temperament := AuraEnums.get_temperament_from_form(AuraEnums.AuraForm.DIFFUSE_SPREADING)
	assert_eq(temperament, AuraEnums.EntityTemperament.TERRITORIAL)


func test_swirling_mobile_maps_to_roaming() -> void:
	var temperament := AuraEnums.get_temperament_from_form(AuraEnums.AuraForm.SWIRLING_MOBILE)
	assert_eq(temperament, AuraEnums.EntityTemperament.ROAMING)


func test_none_form_maps_to_unknown() -> void:
	var temperament := AuraEnums.get_temperament_from_form(AuraEnums.AuraForm.NONE)
	assert_eq(temperament, AuraEnums.EntityTemperament.UNKNOWN)


# --- Test: Expected Form for Color ---


func test_cold_blue_expects_tight_contained() -> void:
	var form := AuraEnums.get_expected_form(AuraEnums.AuraColor.COLD_BLUE)
	assert_eq(form, AuraEnums.AuraForm.TIGHT_CONTAINED)


func test_hot_red_expects_spiking_erratic() -> void:
	var form := AuraEnums.get_expected_form(AuraEnums.AuraColor.HOT_RED)
	assert_eq(form, AuraEnums.AuraForm.SPIKING_ERRATIC)


func test_pale_green_expects_diffuse_spreading() -> void:
	var form := AuraEnums.get_expected_form(AuraEnums.AuraColor.PALE_GREEN)
	assert_eq(form, AuraEnums.AuraForm.DIFFUSE_SPREADING)


func test_deep_purple_expects_swirling_mobile() -> void:
	var form := AuraEnums.get_expected_form(AuraEnums.AuraColor.DEEP_PURPLE)
	assert_eq(form, AuraEnums.AuraForm.SWIRLING_MOBILE)


func test_none_color_expects_none_form() -> void:
	var form := AuraEnums.get_expected_form(AuraEnums.AuraColor.NONE)
	assert_eq(form, AuraEnums.AuraForm.NONE)


# --- Test: Expected Color for Form ---


func test_tight_contained_expects_cold_blue() -> void:
	var color := AuraEnums.get_expected_color(AuraEnums.AuraForm.TIGHT_CONTAINED)
	assert_eq(color, AuraEnums.AuraColor.COLD_BLUE)


func test_spiking_erratic_expects_hot_red() -> void:
	var color := AuraEnums.get_expected_color(AuraEnums.AuraForm.SPIKING_ERRATIC)
	assert_eq(color, AuraEnums.AuraColor.HOT_RED)


func test_diffuse_spreading_expects_pale_green() -> void:
	var color := AuraEnums.get_expected_color(AuraEnums.AuraForm.DIFFUSE_SPREADING)
	assert_eq(color, AuraEnums.AuraColor.PALE_GREEN)


func test_swirling_mobile_expects_deep_purple() -> void:
	var color := AuraEnums.get_expected_color(AuraEnums.AuraForm.SWIRLING_MOBILE)
	assert_eq(color, AuraEnums.AuraColor.DEEP_PURPLE)


func test_none_form_expects_none_color() -> void:
	var color := AuraEnums.get_expected_color(AuraEnums.AuraForm.NONE)
	assert_eq(color, AuraEnums.AuraColor.NONE)


# --- Test: Consistency Check ---


func test_cold_blue_tight_contained_is_consistent() -> void:
	assert_true(AuraEnums.is_consistent(
		AuraEnums.AuraColor.COLD_BLUE,
		AuraEnums.AuraForm.TIGHT_CONTAINED
	))


func test_hot_red_spiking_erratic_is_consistent() -> void:
	assert_true(AuraEnums.is_consistent(
		AuraEnums.AuraColor.HOT_RED,
		AuraEnums.AuraForm.SPIKING_ERRATIC
	))


func test_pale_green_diffuse_spreading_is_consistent() -> void:
	assert_true(AuraEnums.is_consistent(
		AuraEnums.AuraColor.PALE_GREEN,
		AuraEnums.AuraForm.DIFFUSE_SPREADING
	))


func test_deep_purple_swirling_mobile_is_consistent() -> void:
	assert_true(AuraEnums.is_consistent(
		AuraEnums.AuraColor.DEEP_PURPLE,
		AuraEnums.AuraForm.SWIRLING_MOBILE
	))


func test_cold_blue_spiking_erratic_is_inconsistent() -> void:
	assert_false(AuraEnums.is_consistent(
		AuraEnums.AuraColor.COLD_BLUE,
		AuraEnums.AuraForm.SPIKING_ERRATIC
	))


func test_hot_red_diffuse_spreading_is_inconsistent() -> void:
	assert_false(AuraEnums.is_consistent(
		AuraEnums.AuraColor.HOT_RED,
		AuraEnums.AuraForm.DIFFUSE_SPREADING
	))


func test_none_color_is_never_consistent() -> void:
	assert_false(AuraEnums.is_consistent(
		AuraEnums.AuraColor.NONE,
		AuraEnums.AuraForm.TIGHT_CONTAINED
	))


func test_none_form_is_never_consistent() -> void:
	assert_false(AuraEnums.is_consistent(
		AuraEnums.AuraColor.COLD_BLUE,
		AuraEnums.AuraForm.NONE
	))


# --- Test: Display Names ---


func test_get_color_name_cold_blue() -> void:
	assert_eq(AuraEnums.get_color_name(AuraEnums.AuraColor.COLD_BLUE), "Cold Blue")


func test_get_color_name_hot_red() -> void:
	assert_eq(AuraEnums.get_color_name(AuraEnums.AuraColor.HOT_RED), "Hot Red")


func test_get_color_name_pale_green() -> void:
	assert_eq(AuraEnums.get_color_name(AuraEnums.AuraColor.PALE_GREEN), "Pale Green")


func test_get_color_name_deep_purple() -> void:
	assert_eq(AuraEnums.get_color_name(AuraEnums.AuraColor.DEEP_PURPLE), "Deep Purple")


func test_get_color_name_none() -> void:
	assert_eq(AuraEnums.get_color_name(AuraEnums.AuraColor.NONE), "None")


func test_get_form_name_tight_contained() -> void:
	assert_eq(AuraEnums.get_form_name(AuraEnums.AuraForm.TIGHT_CONTAINED), "Tight/Contained")


func test_get_form_name_spiking_erratic() -> void:
	assert_eq(AuraEnums.get_form_name(AuraEnums.AuraForm.SPIKING_ERRATIC), "Spiking/Erratic")


func test_get_form_name_diffuse_spreading() -> void:
	assert_eq(AuraEnums.get_form_name(AuraEnums.AuraForm.DIFFUSE_SPREADING), "Diffuse/Spreading")


func test_get_form_name_swirling_mobile() -> void:
	assert_eq(AuraEnums.get_form_name(AuraEnums.AuraForm.SWIRLING_MOBILE), "Swirling/Mobile")


func test_get_form_name_none() -> void:
	assert_eq(AuraEnums.get_form_name(AuraEnums.AuraForm.NONE), "None")


func test_get_temperament_name_passive() -> void:
	assert_eq(AuraEnums.get_temperament_name(AuraEnums.EntityTemperament.PASSIVE), "Passive")


func test_get_temperament_name_aggressive() -> void:
	assert_eq(AuraEnums.get_temperament_name(AuraEnums.EntityTemperament.AGGRESSIVE), "Aggressive")


func test_get_temperament_name_territorial() -> void:
	assert_eq(AuraEnums.get_temperament_name(AuraEnums.EntityTemperament.TERRITORIAL), "Territorial")


func test_get_temperament_name_roaming() -> void:
	assert_eq(AuraEnums.get_temperament_name(AuraEnums.EntityTemperament.ROAMING), "Roaming")


func test_get_temperament_name_unknown() -> void:
	assert_eq(AuraEnums.get_temperament_name(AuraEnums.EntityTemperament.UNKNOWN), "Unknown")


# --- Test: Temperament Descriptions ---


func test_get_temperament_description_passive() -> void:
	var desc := AuraEnums.get_temperament_description(AuraEnums.EntityTemperament.PASSIVE)
	assert_true(desc.length() > 0)
	assert_true("avoid" in desc.to_lower() or "shy" in desc.to_lower())


func test_get_temperament_description_aggressive() -> void:
	var desc := AuraEnums.get_temperament_description(AuraEnums.EntityTemperament.AGGRESSIVE)
	assert_true(desc.length() > 0)
	assert_true("hostile" in desc.to_lower() or "attack" in desc.to_lower())


func test_get_temperament_description_territorial() -> void:
	var desc := AuraEnums.get_temperament_description(AuraEnums.EntityTemperament.TERRITORIAL)
	assert_true(desc.length() > 0)
	assert_true("area" in desc.to_lower() or "guard" in desc.to_lower())


func test_get_temperament_description_roaming() -> void:
	var desc := AuraEnums.get_temperament_description(AuraEnums.EntityTemperament.ROAMING)
	assert_true(desc.length() > 0)
	assert_true("move" in desc.to_lower() or "free" in desc.to_lower())


# --- Test: Enum Collections ---


func test_get_all_colors_returns_four() -> void:
	var colors := AuraEnums.get_all_colors()
	assert_eq(colors.size(), 4)


func test_get_all_colors_excludes_none() -> void:
	var colors := AuraEnums.get_all_colors()
	assert_false(colors.has(AuraEnums.AuraColor.NONE))


func test_get_all_forms_returns_four() -> void:
	var forms := AuraEnums.get_all_forms()
	assert_eq(forms.size(), 4)


func test_get_all_forms_excludes_none() -> void:
	var forms := AuraEnums.get_all_forms()
	assert_false(forms.has(AuraEnums.AuraForm.NONE))


# --- Test: Enum Counts ---


func test_aura_color_has_five_values() -> void:
	assert_eq(AuraEnums.AuraColor.size(), 5, "Expected 5 AuraColor values (including NONE)")


func test_aura_form_has_five_values() -> void:
	assert_eq(AuraEnums.AuraForm.size(), 5, "Expected 5 AuraForm values (including NONE)")


func test_entity_temperament_has_five_values() -> void:
	assert_eq(AuraEnums.EntityTemperament.size(), 5, "Expected 5 EntityTemperament values")


# --- Test: Bidirectional Mapping Consistency ---


func test_all_color_form_mappings_are_bidirectional() -> void:
	for color: AuraEnums.AuraColor in AuraEnums.get_all_colors():
		var expected_form := AuraEnums.get_expected_form(color)
		var reverse_color := AuraEnums.get_expected_color(expected_form)
		assert_eq(
			reverse_color, color,
			"Color %s -> Form -> Color should round-trip" % color
		)


func test_all_form_color_mappings_are_bidirectional() -> void:
	for form: AuraEnums.AuraForm in AuraEnums.get_all_forms():
		var expected_color := AuraEnums.get_expected_color(form)
		var reverse_form := AuraEnums.get_expected_form(expected_color)
		assert_eq(
			reverse_form, form,
			"Form %s -> Color -> Form should round-trip" % form
		)


# --- Test: Combined Signature ---


func test_get_combined_signature_both_none() -> void:
	var sig := AuraEnums.get_combined_signature(AuraEnums.AuraColor.NONE, AuraEnums.AuraForm.NONE)
	assert_eq(sig, "No reading")


func test_get_combined_signature_color_only() -> void:
	var sig := AuraEnums.get_combined_signature(AuraEnums.AuraColor.COLD_BLUE, AuraEnums.AuraForm.NONE)
	assert_true("Cold Blue" in sig)
	assert_true("unresolved" in sig.to_lower())


func test_get_combined_signature_form_only() -> void:
	var sig := AuraEnums.get_combined_signature(
		AuraEnums.AuraColor.NONE, AuraEnums.AuraForm.TIGHT_CONTAINED
	)
	assert_true("Tight/Contained" in sig)
	assert_true("unresolved" in sig.to_lower())


func test_get_combined_signature_both_present() -> void:
	var sig := AuraEnums.get_combined_signature(
		AuraEnums.AuraColor.HOT_RED, AuraEnums.AuraForm.SPIKING_ERRATIC
	)
	assert_true("Hot Red" in sig)
	assert_true("Spiking/Erratic" in sig)


# --- Test: All Consistency Combinations ---


func test_all_matching_pairs_are_consistent() -> void:
	var colors := AuraEnums.get_all_colors()
	var forms := AuraEnums.get_all_forms()

	for i in range(colors.size()):
		var color: AuraEnums.AuraColor = colors[i]
		var form: AuraEnums.AuraForm = forms[i]
		assert_true(
			AuraEnums.is_consistent(color, form),
			"Color %s and Form %s should be consistent" % [color, form]
		)


func test_all_mismatching_pairs_are_inconsistent() -> void:
	var colors := AuraEnums.get_all_colors()
	var forms := AuraEnums.get_all_forms()

	for i in range(colors.size()):
		for j in range(forms.size()):
			if i != j:
				var color: AuraEnums.AuraColor = colors[i]
				var form: AuraEnums.AuraForm = forms[j]
				assert_false(
					AuraEnums.is_consistent(color, form),
					"Color %s and Form %s should be inconsistent" % [color, form]
				)
