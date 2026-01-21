extends GutTest
## Integration tests for Cultist contamination abilities.
##
## Tests that each ability correctly creates contaminated evidence
## and source nodes, consumes charges, and integrates with the game systems.

const EMFSpoofScript := preload("res://src/cultist/abilities/emf_spoof.gd")
const TempManipScript := preload("res://src/cultist/abilities/temperature_manipulation.gd")
const PrismInterferenceScript := preload("res://src/cultist/abilities/prism_interference.gd")
const AuraDisruptionScript := preload("res://src/cultist/abilities/aura_disruption.gd")
const CultistEnumsScript := preload("res://src/cultist/cultist_enums.gd")


# --- EMF Spoof Tests ---


func test_emf_spoof_creates_contaminated_evidence() -> void:
	var ability: Resource = EMFSpoofScript.new()
	var result: Dictionary = ability.execute(1, Vector3(5, 0, 5))

	assert_true(result.has("evidence"), "Result should contain evidence")
	assert_not_null(result.evidence, "Evidence should not be null")
	assert_true(result.evidence.is_contaminated, "Evidence should be contaminated")


func test_emf_spoof_creates_emf_source_node() -> void:
	var ability: Resource = EMFSpoofScript.new()
	var result: Dictionary = ability.execute(1, Vector3(5, 0, 5))

	assert_true(result.has("source"), "Result should contain source node")
	assert_not_null(result.source, "Source node should not be null")
	assert_true(result.source is Node3D, "Source should be Node3D")


func test_emf_spoof_source_in_correct_group() -> void:
	var ability: Resource = EMFSpoofScript.new()
	var result: Dictionary = ability.execute(1, Vector3(5, 0, 5))

	var source: Node3D = result.source
	add_child_autofree(source)
	await get_tree().process_frame

	assert_true(source.is_in_group("emf_source"), "Source should be in emf_source group")


func test_emf_spoof_source_returns_activity() -> void:
	var ability: Resource = EMFSpoofScript.new()
	var result: Dictionary = ability.execute(1, Vector3(5, 0, 5))

	var source: Node3D = result.source
	assert_true(source.has_method("get_emf_activity"), "Source should have get_emf_activity()")

	var activity: float = source.get_emf_activity()
	assert_gt(activity, 0.0, "Activity should be positive for PLANTED state")


func test_emf_spoof_consumes_charge() -> void:
	var ability: Resource = EMFSpoofScript.new()
	var initial_charges: int = ability.current_charges

	ability.execute(1, Vector3.ZERO)

	assert_eq(ability.current_charges, initial_charges - 1, "Should consume one charge")


func test_emf_spoof_max_charges_is_two() -> void:
	var ability: Resource = EMFSpoofScript.new()
	assert_eq(ability.max_charges, 2, "EMF Spoof should have 2 max charges")


func test_emf_spoof_cannot_use_without_charges() -> void:
	var ability: Resource = EMFSpoofScript.new()
	ability.current_charges = 0

	var result: Dictionary = ability.execute(1, Vector3.ZERO)

	assert_true(result.is_empty(), "Execute should return empty dict when no charges")


# --- Temperature Manipulation Tests ---


func test_temp_manipulation_creates_contaminated_evidence() -> void:
	var ability: Resource = TempManipScript.new()
	var result: Dictionary = ability.execute(1, Vector3(10, 0, 10))

	assert_true(result.has("evidence"), "Result should contain evidence")
	assert_not_null(result.evidence, "Evidence should not be null")
	assert_true(result.evidence.is_contaminated, "Evidence should be contaminated")


func test_temp_manipulation_creates_zone_node() -> void:
	var ability: Resource = TempManipScript.new()
	var result: Dictionary = ability.execute(1, Vector3(10, 0, 10))

	assert_true(result.has("zone"), "Result should contain zone node")
	assert_not_null(result.zone, "Zone node should not be null")
	assert_true(result.zone is Node3D, "Zone should be Node3D")


func test_temp_manipulation_zone_in_correct_group() -> void:
	var ability: Resource = TempManipScript.new()
	var result: Dictionary = ability.execute(1, Vector3(10, 0, 10))

	var zone: Node3D = result.zone
	add_child_autofree(zone)
	await get_tree().process_frame

	assert_true(zone.is_in_group("temperature_zone"), "Zone should be in temperature_zone group")


func test_temp_manipulation_zone_returns_freezing_temperature() -> void:
	var ability: Resource = TempManipScript.new()
	var result: Dictionary = ability.execute(1, Vector3(10, 0, 10))

	var zone: Node3D = result.zone
	assert_true(zone.has_method("get_temperature"), "Zone should have get_temperature()")

	var temp: float = zone.get_temperature()
	assert_lt(temp, 0.0, "Temperature should be below 0°C for PLANTED state")


func test_temp_manipulation_consumes_charge() -> void:
	var ability: Resource = TempManipScript.new()
	var initial_charges: int = ability.current_charges

	ability.execute(1, Vector3.ZERO)

	assert_eq(ability.current_charges, initial_charges - 1, "Should consume one charge")


func test_temp_manipulation_max_charges_is_two() -> void:
	var ability: Resource = TempManipScript.new()
	assert_eq(ability.max_charges, 2, "Temperature Manipulation should have 2 max charges")


# --- Prism Interference Tests ---


func test_prism_interference_creates_contaminated_evidence() -> void:
	var ability: Resource = PrismInterferenceScript.new()
	var result: Dictionary = ability.execute(1, Vector3(15, 0, 15))

	assert_true(result.has("evidence"), "Result should contain evidence")
	assert_not_null(result.evidence, "Evidence should not be null")
	assert_true(result.evidence.is_contaminated, "Evidence should be contaminated")


func test_prism_interference_creates_anchor_node() -> void:
	var ability: Resource = PrismInterferenceScript.new()
	var result: Dictionary = ability.execute(1, Vector3(15, 0, 15))

	assert_true(result.has("anchor"), "Result should contain anchor node")
	assert_not_null(result.anchor, "Anchor node should not be null")
	assert_true(result.anchor is Node3D, "Anchor should be Node3D")


func test_prism_interference_anchor_in_correct_group() -> void:
	var ability: Resource = PrismInterferenceScript.new()
	var result: Dictionary = ability.execute(1, Vector3(15, 0, 15))

	var anchor: Node3D = result.anchor
	add_child_autofree(anchor)
	await get_tree().process_frame

	assert_true(anchor.is_in_group("spectral_anchors"), "Anchor should be in spectral_anchors group")


func test_prism_interference_anchor_returns_pattern() -> void:
	var ability: Resource = PrismInterferenceScript.new()
	var result: Dictionary = ability.execute(1, Vector3(15, 0, 15))

	var anchor: Node3D = result.anchor
	assert_true(anchor.has_method("get_true_pattern"), "Anchor should have get_true_pattern()")
	assert_true(anchor.has_method("get_true_color"), "Anchor should have get_true_color()")

	var pattern: int = anchor.get_true_pattern()
	var color: int = anchor.get_true_color()

	# PLANTED state should have valid pattern/color (not NONE)
	assert_ne(pattern, 0, "Pattern should not be NONE for PLANTED state")
	assert_ne(color, 0, "Color should not be NONE for PLANTED state")


func test_prism_interference_consumes_charge() -> void:
	var ability: Resource = PrismInterferenceScript.new()
	var initial_charges: int = ability.current_charges

	ability.execute(1, Vector3.ZERO)

	assert_eq(ability.current_charges, initial_charges - 1, "Should consume one charge")


func test_prism_interference_max_charges_is_one() -> void:
	var ability: Resource = PrismInterferenceScript.new()
	assert_eq(ability.max_charges, 1, "Prism Interference should have 1 max charge")


func test_prism_interference_single_use() -> void:
	var ability: Resource = PrismInterferenceScript.new()

	# First use should succeed
	var result1: Dictionary = ability.execute(1, Vector3.ZERO)
	assert_false(result1.is_empty(), "First use should succeed")

	# Second use should fail (no charges)
	var result2: Dictionary = ability.execute(1, Vector3.ZERO)
	assert_true(result2.is_empty(), "Second use should fail")


# --- Aura Disruption Tests ---


func test_aura_disruption_creates_contaminated_evidence() -> void:
	var ability: Resource = AuraDisruptionScript.new()
	var result: Dictionary = ability.execute(1, Vector3(20, 0, 20))

	assert_true(result.has("evidence"), "Result should contain evidence")
	assert_not_null(result.evidence, "Evidence should not be null")
	assert_true(result.evidence.is_contaminated, "Evidence should be contaminated")


func test_aura_disruption_creates_anchor_node() -> void:
	var ability: Resource = AuraDisruptionScript.new()
	var result: Dictionary = ability.execute(1, Vector3(20, 0, 20))

	assert_true(result.has("anchor"), "Result should contain anchor node")
	assert_not_null(result.anchor, "Anchor node should not be null")
	assert_true(result.anchor is Node3D, "Anchor should be Node3D")


func test_aura_disruption_anchor_in_correct_group() -> void:
	var ability: Resource = AuraDisruptionScript.new()
	var result: Dictionary = ability.execute(1, Vector3(20, 0, 20))

	var anchor: Node3D = result.anchor
	add_child_autofree(anchor)
	await get_tree().process_frame

	assert_true(anchor.is_in_group("aura_anchors"), "Anchor should be in aura_anchors group")


func test_aura_disruption_anchor_returns_color_and_form() -> void:
	var ability: Resource = AuraDisruptionScript.new()
	var result: Dictionary = ability.execute(1, Vector3(20, 0, 20))

	var anchor: Node3D = result.anchor
	assert_true(anchor.has_method("get_true_color"), "Anchor should have get_true_color()")
	assert_true(anchor.has_method("get_true_form"), "Anchor should have get_true_form()")

	var color: int = anchor.get_true_color()
	var form: int = anchor.get_true_form()

	# PLANTED state should have valid color/form (not NONE)
	assert_ne(color, 0, "Color should not be NONE for PLANTED state")
	assert_ne(form, 0, "Form should not be NONE for PLANTED state")


func test_aura_disruption_consumes_charge() -> void:
	var ability: Resource = AuraDisruptionScript.new()
	var initial_charges: int = ability.current_charges

	ability.execute(1, Vector3.ZERO)

	assert_eq(ability.current_charges, initial_charges - 1, "Should consume one charge")


func test_aura_disruption_max_charges_is_two() -> void:
	var ability: Resource = AuraDisruptionScript.new()
	assert_eq(ability.max_charges, 2, "Aura Disruption should have 2 max charges")


# --- Cross-Ability Tests ---


func test_all_abilities_track_planted_by() -> void:
	var emf: Resource = EMFSpoofScript.new()
	var temp: Resource = TempManipScript.new()
	var prism: Resource = PrismInterferenceScript.new()
	var aura: Resource = AuraDisruptionScript.new()

	var cultist_id: int = 42

	var emf_result: Dictionary = emf.execute(cultist_id, Vector3.ZERO)
	var temp_result: Dictionary = temp.execute(cultist_id, Vector3.ZERO)
	var prism_result: Dictionary = prism.execute(cultist_id, Vector3.ZERO)
	var aura_result: Dictionary = aura.execute(cultist_id, Vector3.ZERO)

	assert_eq(emf_result.evidence.planted_by, cultist_id, "EMF should track planted_by")
	assert_eq(temp_result.evidence.planted_by, cultist_id, "Temp should track planted_by")
	assert_eq(prism_result.evidence.planted_by, cultist_id, "Prism should track planted_by")
	assert_eq(aura_result.evidence.planted_by, cultist_id, "Aura should track planted_by")


func test_all_abilities_track_source_ability() -> void:
	var emf: Resource = EMFSpoofScript.new()
	var temp: Resource = TempManipScript.new()
	var prism: Resource = PrismInterferenceScript.new()
	var aura: Resource = AuraDisruptionScript.new()

	var emf_result: Dictionary = emf.execute(1, Vector3.ZERO)
	var temp_result: Dictionary = temp.execute(1, Vector3.ZERO)
	var prism_result: Dictionary = prism.execute(1, Vector3.ZERO)
	var aura_result: Dictionary = aura.execute(1, Vector3.ZERO)

	assert_eq(
		emf_result.evidence.source_ability,
		CultistEnumsScript.AbilityType.EMF_SPOOF,
		"EMF should track source_ability"
	)
	assert_eq(
		temp_result.evidence.source_ability,
		CultistEnumsScript.AbilityType.TEMPERATURE_MANIPULATION,
		"Temp should track source_ability"
	)
	assert_eq(
		prism_result.evidence.source_ability,
		CultistEnumsScript.AbilityType.PRISM_INTERFERENCE,
		"Prism should track source_ability"
	)
	assert_eq(
		aura_result.evidence.source_ability,
		CultistEnumsScript.AbilityType.AURA_DISRUPTION,
		"Aura should track source_ability"
	)


func test_all_abilities_position_source_correctly() -> void:
	var emf: Resource = EMFSpoofScript.new()
	var temp: Resource = TempManipScript.new()
	var prism: Resource = PrismInterferenceScript.new()
	var aura: Resource = AuraDisruptionScript.new()

	var location := Vector3(100, 50, 200)

	var emf_result: Dictionary = emf.execute(1, location)
	var temp_result: Dictionary = temp.execute(1, location)
	var prism_result: Dictionary = prism.execute(1, location)
	var aura_result: Dictionary = aura.execute(1, location)

	assert_eq(emf_result.source.position, location, "EMF source should be at location")
	assert_eq(temp_result.zone.position, location, "Temp zone should be at location")
	assert_eq(prism_result.anchor.position, location, "Prism anchor should be at location")
	assert_eq(aura_result.anchor.position, location, "Aura anchor should be at location")


func test_all_abilities_can_use_initially() -> void:
	var emf: Resource = EMFSpoofScript.new()
	var temp: Resource = TempManipScript.new()
	var prism: Resource = PrismInterferenceScript.new()
	var aura: Resource = AuraDisruptionScript.new()

	assert_true(emf.can_use(), "EMF should be usable initially")
	assert_true(temp.can_use(), "Temp should be usable initially")
	assert_true(prism.can_use(), "Prism should be usable initially")
	assert_true(aura.can_use(), "Aura should be usable initially")


func test_charge_depletion_prevents_use() -> void:
	var ability: Resource = EMFSpoofScript.new()

	# Use all charges
	ability.execute(1, Vector3.ZERO)
	ability.execute(1, Vector3.ZERO)

	assert_false(ability.can_use(), "Should not be usable with 0 charges")
	assert_eq(ability.current_charges, 0, "Charges should be 0")
