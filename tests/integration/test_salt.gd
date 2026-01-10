extends GutTest
## Tests for Salt protection item.


var salt: Salt


func before_each() -> void:
	salt = Salt.new()
	add_child_autofree(salt)
	salt._ready()


# --- Initialization Tests ---


func test_equipment_type() -> void:
	assert_eq(
		salt.equipment_type,
		Equipment.EquipmentType.SALT,
		"Should have SALT type"
	)


func test_equipment_name() -> void:
	assert_eq(salt.equipment_name, "Salt", "Should have correct name")


func test_use_mode_is_instant() -> void:
	assert_eq(salt.use_mode, Equipment.UseMode.INSTANT, "Should use INSTANT mode")


func test_max_charges_is_three() -> void:
	assert_eq(salt.max_charges, 3, "Should have 3 charges")


func test_initial_charges_is_three() -> void:
	assert_eq(salt.get_charges_remaining(), 3, "Should start with 3 charges")


func test_placement_mode_is_placed() -> void:
	assert_eq(
		salt.placement_mode,
		ProtectionItem.PlacementMode.PLACED,
		"Should use PLACED mode"
	)


func test_cannot_use_during_hunt() -> void:
	assert_false(salt.can_use_during_hunt, "Should not work during hunts")


func test_effective_radius() -> void:
	assert_eq(salt.effective_radius, 0.5, "Should have 0.5m radius")


# --- Constants Tests ---


func test_slowdown_duration() -> void:
	assert_eq(Salt.SLOWDOWN_DURATION, 3.0, "Slowdown should last 3 seconds")


func test_slowdown_factor() -> void:
	assert_eq(Salt.SLOWDOWN_FACTOR, 0.5, "Slowdown should be 50%")


func test_footprint_duration() -> void:
	assert_eq(Salt.FOOTPRINT_DURATION, 120.0, "Footprints should last 2 minutes")


# --- Placement Tests ---


func test_place_salt() -> void:
	var result: bool = salt.place_at(Vector3(1.0, 0.0, 2.0))

	assert_true(result, "Should successfully place salt")
	assert_true(salt.is_placed(), "Should be marked as placed")


func test_placement_preserves_charges() -> void:
	salt.place_at(Vector3(1.0, 0.0, 2.0))

	assert_eq(salt.get_charges_remaining(), 3, "Placement should not consume charges")


# --- Trigger Tests ---


func test_trigger_with_normal_entity() -> void:
	salt.place_at(Vector3.ZERO)
	var entity := MockEntityNormal.new()
	add_child_autofree(entity)

	var result: bool = salt.trigger(entity)

	assert_true(result, "Should trigger for normal entity")


func test_trigger_consumes_charge() -> void:
	salt.place_at(Vector3.ZERO)
	var entity := MockEntityNormal.new()
	add_child_autofree(entity)

	salt.trigger(entity)

	assert_eq(salt.get_charges_remaining(), 2, "Trigger should consume charge")


func test_three_triggers_deplete_salt() -> void:
	salt.place_at(Vector3.ZERO)
	var entity := MockEntityNormal.new()
	add_child_autofree(entity)

	salt.trigger(entity)
	salt.trigger(entity)
	salt.trigger(entity)

	assert_eq(salt.get_charges_remaining(), 0, "Three triggers should deplete")


func test_trigger_fails_without_placement() -> void:
	var entity := MockEntityNormal.new()
	add_child_autofree(entity)

	var result: bool = salt.trigger(entity)

	assert_false(result, "Should not trigger when not placed")


# --- Wraith Behavior Tests ---


func test_wraith_does_not_consume_charge() -> void:
	salt.place_at(Vector3.ZERO)
	var wraith := MockEntityWraith.new()
	add_child_autofree(wraith)

	salt.trigger(wraith)

	assert_eq(salt.get_charges_remaining(), 3, "Wraith should not consume charge")


func test_wraith_trigger_returns_false() -> void:
	salt.place_at(Vector3.ZERO)
	var wraith := MockEntityWraith.new()
	add_child_autofree(wraith)

	var result: bool = salt.trigger(wraith)

	assert_false(result, "Wraith trigger should return false")


func test_is_entity_wraith_detection_method() -> void:
	var wraith := MockEntityWraith.new()
	add_child_autofree(wraith)

	var result: bool = salt._is_entity_wraith(wraith)

	assert_true(result, "Should detect Wraith")


func test_is_entity_wraith_detection_property() -> void:
	var wraith := MockEntityProperty.new()
	wraith.entity_type = "Wraith"
	add_child_autofree(wraith)

	var result: bool = salt._is_entity_wraith(wraith)

	assert_true(result, "Should detect Wraith via property")


func test_non_wraith_not_detected_as_wraith() -> void:
	var phantom := MockEntityNormal.new()
	add_child_autofree(phantom)

	var result: bool = salt._is_entity_wraith(phantom)

	assert_false(result, "Non-Wraith should not be detected as Wraith")


# --- Footprint Tests ---


func test_footprint_locations_empty_initially() -> void:
	assert_eq(salt.get_footprint_locations().size(), 0, "Should have no footprints initially")


func test_trigger_creates_footprint() -> void:
	salt.place_at(Vector3.ZERO)
	var entity := MockEntityNormal.new()
	entity.global_position = Vector3(1.0, 0.0, 1.0)
	add_child_autofree(entity)

	salt.trigger(entity)

	assert_eq(salt.get_footprint_locations().size(), 1, "Should create footprint")


func test_multiple_triggers_create_multiple_footprints() -> void:
	salt.place_at(Vector3.ZERO)
	var entity := MockEntityNormal.new()
	add_child_autofree(entity)

	salt.trigger(entity)
	salt.trigger(entity)

	assert_eq(salt.get_footprint_locations().size(), 2, "Should create multiple footprints")


func test_wraith_does_not_create_footprint() -> void:
	salt.place_at(Vector3.ZERO)
	var wraith := MockEntityWraith.new()
	add_child_autofree(wraith)

	salt.trigger(wraith)

	assert_eq(salt.get_footprint_locations().size(), 0, "Wraith should not create footprints")


# --- Entity Detection Tests ---


func test_is_entity_with_group() -> void:
	var entity := Node3D.new()
	entity.add_to_group("entity")
	add_child_autofree(entity)

	var result: bool = salt._is_entity(entity)

	assert_true(result, "Should detect entity by group")


func test_is_entity_with_method() -> void:
	var entity := MockEntityNormal.new()
	add_child_autofree(entity)

	var result: bool = salt._is_entity(entity)

	assert_true(result, "Should detect entity by method")


func test_non_entity_not_detected() -> void:
	var non_entity := Node3D.new()
	add_child_autofree(non_entity)

	var result: bool = salt._is_entity(non_entity)

	assert_false(result, "Non-entity should not be detected")


# --- Network State Tests ---


func test_network_state_includes_footprints() -> void:
	salt.place_at(Vector3.ZERO)
	var entity := MockEntityNormal.new()
	add_child_autofree(entity)
	salt.trigger(entity)

	var state := salt.get_network_state()

	assert_has(state, "footprints", "Should include footprints")


func test_network_state_footprint_data() -> void:
	salt.place_at(Vector3.ZERO)
	var entity := MockEntityNormal.new()
	entity.global_position = Vector3(5.0, 0.0, -3.0)
	add_child_autofree(entity)
	salt.trigger(entity)

	var state := salt.get_network_state()
	var footprints: Array = state["footprints"]

	assert_eq(footprints.size(), 1, "Should have 1 footprint")


func test_apply_network_state_restores_footprints() -> void:
	var state := {
		"footprints": [
			{"x": 1.0, "y": 0.0, "z": 2.0},
			{"x": 3.0, "y": 0.0, "z": 4.0},
		]
	}

	salt.apply_network_state(state)

	var locations := salt.get_footprint_locations()
	assert_eq(locations.size(), 2, "Should restore footprints")


# --- Helper Classes ---


class MockEntityNormal:
	extends Node3D

	func get_entity_type() -> String:
		return "Phantom"


class MockEntityWraith:
	extends Node3D

	func get_entity_type() -> String:
		return "Wraith"


class MockEntityProperty:
	extends Node3D

	var entity_type: String = ""
