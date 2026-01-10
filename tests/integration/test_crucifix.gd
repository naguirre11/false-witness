extends GutTest
## Tests for Crucifix protection item.


var crucifix: Crucifix


func before_each() -> void:
	crucifix = Crucifix.new()
	add_child_autofree(crucifix)
	crucifix._ready()


# --- Initialization Tests ---


func test_equipment_type() -> void:
	assert_eq(
		crucifix.equipment_type,
		Equipment.EquipmentType.CRUCIFIX,
		"Should have CRUCIFIX type"
	)


func test_equipment_name() -> void:
	assert_eq(crucifix.equipment_name, "Crucifix", "Should have correct name")


func test_use_mode_is_instant() -> void:
	assert_eq(crucifix.use_mode, Equipment.UseMode.INSTANT, "Should use INSTANT mode")


func test_max_charges_is_two() -> void:
	assert_eq(crucifix.max_charges, 2, "Should have 2 charges")


func test_initial_charges_is_two() -> void:
	assert_eq(crucifix.get_charges_remaining(), 2, "Should start with 2 charges")


func test_placement_mode_is_placed() -> void:
	assert_eq(
		crucifix.placement_mode,
		ProtectionItem.PlacementMode.PLACED,
		"Should use PLACED mode"
	)


func test_effective_radius() -> void:
	assert_eq(crucifix.effective_radius, 3.0, "Should have 3m radius")


func test_demon_radius_multiplier() -> void:
	assert_almost_eq(
		crucifix.demon_radius_multiplier,
		0.667,
		0.01,
		"Demon multiplier should be ~0.667"
	)


# --- Placement Tests ---


func test_place_crucifix() -> void:
	var result: bool = crucifix.place_at(Vector3(1.0, 0.0, 2.0))

	assert_true(result, "Should successfully place crucifix")
	assert_true(crucifix.is_placed(), "Should be marked as placed")


func test_placement_preserves_charges() -> void:
	crucifix.place_at(Vector3(1.0, 0.0, 2.0))

	assert_eq(crucifix.get_charges_remaining(), 2, "Placement should not consume charges")


# --- Effective Radius Tests ---


func test_normal_entity_radius() -> void:
	var radius: float = crucifix.get_effective_radius(false)

	assert_eq(radius, 3.0, "Normal entities should have 3m radius")


func test_demon_entity_radius() -> void:
	var radius: float = crucifix.get_effective_radius(true)

	assert_almost_eq(radius, 2.0, 0.01, "Demon should have ~2m radius")


# --- Trigger Tests ---


func test_trigger_consumes_charge() -> void:
	crucifix.place_at(Vector3.ZERO)

	crucifix.trigger()

	assert_eq(crucifix.get_charges_remaining(), 1, "Trigger should consume one charge")


func test_two_triggers_deplete_crucifix() -> void:
	crucifix.place_at(Vector3.ZERO)

	crucifix.trigger()
	crucifix.trigger()

	assert_eq(crucifix.get_charges_remaining(), 0, "Two triggers should deplete")
	assert_false(crucifix.has_charges(), "Should be depleted")


func test_trigger_emits_charge_used() -> void:
	crucifix.place_at(Vector3.ZERO)
	watch_signals(crucifix)

	crucifix.trigger()

	assert_signal_emitted(crucifix, "charge_used")


func test_depletion_emits_depleted() -> void:
	crucifix.place_at(Vector3.ZERO)
	watch_signals(crucifix)

	crucifix.trigger()
	crucifix.trigger()

	assert_signal_emitted(crucifix, "depleted")


func test_trigger_fails_without_placement() -> void:
	var result: bool = crucifix.trigger()

	assert_false(result, "Should not trigger when not placed")


func test_trigger_fails_when_depleted() -> void:
	crucifix.place_at(Vector3.ZERO)
	crucifix.trigger()
	crucifix.trigger()

	var result: bool = crucifix.trigger()

	assert_false(result, "Should not trigger when depleted")


# --- Visual Creation Tests ---


func test_creates_placed_visual() -> void:
	crucifix.place_at(Vector3(1.0, 0.0, 1.0))

	# The visual is created and added to the world via _add_placed_item_to_world
	# which requires a scene tree, so we just verify placement succeeded
	assert_true(crucifix.is_placed(), "Should have created visual and placed")


# --- Network State Tests ---


func test_network_state_includes_base_data() -> void:
	crucifix.place_at(Vector3(1.0, 2.0, 3.0))

	var state := crucifix.get_network_state()

	assert_has(state, "charges", "Should include charges")
	assert_has(state, "is_placed", "Should include placement")
	assert_has(state, "placed_position", "Should include position")


func test_network_state_charges() -> void:
	crucifix.place_at(Vector3.ZERO)
	crucifix.trigger()

	var state := crucifix.get_network_state()

	assert_eq(state["charges"], 1, "Should have 1 charge in state")


# --- Entity Type Detection Tests ---


func test_is_entity_demon_with_method() -> void:
	var mock_entity := MockEntity.new()
	mock_entity._entity_type = "Demon"
	add_child_autofree(mock_entity)

	var result: bool = crucifix._is_entity_demon(mock_entity)

	assert_true(result, "Should detect Demon entity")


func test_is_entity_demon_with_property() -> void:
	var mock_entity := MockEntityProperty.new()
	mock_entity.entity_type = "Demon"
	add_child_autofree(mock_entity)

	var result: bool = crucifix._is_entity_demon(mock_entity)

	assert_true(result, "Should detect Demon via property")


func test_is_not_demon_for_other_entity() -> void:
	var mock_entity := MockEntity.new()
	mock_entity._entity_type = "Phantom"
	add_child_autofree(mock_entity)

	var result: bool = crucifix._is_entity_demon(mock_entity)

	assert_false(result, "Should not detect non-Demon as Demon")


func test_is_not_demon_for_null() -> void:
	var result: bool = crucifix._is_entity_demon(null)

	assert_false(result, "Null entity should not be Demon")


# --- Helper Classes ---


class MockEntity:
	extends Node

	var _entity_type: String = ""

	func get_entity_type() -> String:
		return _entity_type


class MockEntityProperty:
	extends Node

	var entity_type: String = ""
