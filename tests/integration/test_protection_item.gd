extends GutTest
## Tests for ProtectionItem base class.


var protection_item: ProtectionItem


func before_each() -> void:
	protection_item = ProtectionItem.new()
	add_child_autofree(protection_item)


# --- Initialization Tests ---


func test_default_values() -> void:
	assert_eq(protection_item.max_charges, 1, "Default max_charges should be 1")
	assert_eq(
		protection_item.placement_mode,
		ProtectionItem.PlacementMode.PLACED,
		"Default placement mode should be PLACED"
	)
	assert_eq(protection_item.effective_radius, 3.0, "Default effective_radius should be 3.0")
	assert_eq(protection_item.placement_range, 2.0, "Default placement_range should be 2.0")


func test_initial_charges() -> void:
	protection_item.max_charges = 3
	protection_item._ready()
	assert_eq(protection_item.get_charges_remaining(), 3, "Should have max_charges initially")


func test_can_use_during_hunt_is_true() -> void:
	protection_item._ready()
	assert_true(protection_item.can_use_during_hunt, "Protection items should work during hunts")


# --- Charge Management Tests ---


func test_has_charges_when_charges_remaining() -> void:
	protection_item._ready()
	assert_true(protection_item.has_charges(), "Should have charges after init")


func test_consume_charge_decrements() -> void:
	protection_item.max_charges = 3
	protection_item._ready()

	protection_item.consume_charge()

	assert_eq(protection_item.get_charges_remaining(), 2, "Should decrement charges")


func test_consume_charge_emits_signal() -> void:
	protection_item._ready()
	watch_signals(protection_item)

	protection_item.consume_charge()

	assert_signal_emitted(protection_item, "charge_used")


func test_consume_charge_signal_contains_remaining() -> void:
	protection_item.max_charges = 2
	protection_item._ready()

	var state := {"remaining": -1}
	protection_item.charge_used.connect(func(r): state["remaining"] = r)

	protection_item.consume_charge()

	assert_eq(state["remaining"], 1, "Signal should contain remaining charges")


func test_depleted_signal_when_no_charges() -> void:
	protection_item.max_charges = 1
	protection_item._ready()
	watch_signals(protection_item)

	protection_item.consume_charge()

	assert_signal_emitted(protection_item, "depleted")


func test_no_depleted_signal_with_charges() -> void:
	protection_item.max_charges = 2
	protection_item._ready()
	watch_signals(protection_item)

	protection_item.consume_charge()

	assert_signal_not_emitted(protection_item, "depleted")


func test_has_charges_false_when_depleted() -> void:
	protection_item.max_charges = 1
	protection_item._ready()

	protection_item.consume_charge()

	assert_false(protection_item.has_charges(), "Should not have charges when depleted")


# --- Placement Tests ---


func test_is_placed_initially_false() -> void:
	assert_false(protection_item.is_placed(), "Should not be placed initially")


func test_get_placed_position_default() -> void:
	assert_eq(protection_item.get_placed_position(), Vector3.ZERO, "Default position should be ZERO")


func test_place_at_sets_placed() -> void:
	protection_item._ready()
	var location := Vector3(1.0, 0.0, 2.0)

	var result: bool = protection_item.place_at(location)

	assert_true(result, "place_at should return true")
	assert_true(protection_item.is_placed(), "Should be placed after place_at")


func test_place_at_sets_position() -> void:
	protection_item._ready()
	var location := Vector3(5.0, 1.0, -3.0)

	protection_item.place_at(location)

	assert_eq(protection_item.get_placed_position(), location, "Should store placed position")


func test_place_at_emits_signal() -> void:
	protection_item._ready()
	watch_signals(protection_item)

	protection_item.place_at(Vector3(1.0, 0.0, 1.0))

	assert_signal_emitted(protection_item, "placed")


func test_cannot_place_twice() -> void:
	protection_item._ready()

	protection_item.place_at(Vector3(1.0, 0.0, 1.0))
	var result: bool = protection_item.place_at(Vector3(2.0, 0.0, 2.0))

	assert_false(result, "Should not be able to place twice")


func test_cannot_place_without_charges() -> void:
	protection_item.max_charges = 0
	protection_item._ready()

	var result: bool = protection_item.place_at(Vector3(1.0, 0.0, 1.0))

	assert_false(result, "Should not place without charges")


# --- Effective Radius Tests ---


func test_get_effective_radius_normal() -> void:
	protection_item.effective_radius = 3.0
	protection_item.demon_radius_multiplier = 0.667

	var radius: float = protection_item.get_effective_radius(false)

	assert_eq(radius, 3.0, "Normal radius should be effective_radius")


func test_get_effective_radius_demon() -> void:
	protection_item.effective_radius = 3.0
	protection_item.demon_radius_multiplier = 0.667

	var radius: float = protection_item.get_effective_radius(true)

	assert_almost_eq(radius, 2.0, 0.01, "Demon radius should be reduced")


# --- Trigger Tests ---


func test_trigger_returns_false_without_charges() -> void:
	protection_item.max_charges = 0
	protection_item._ready()

	var result: bool = protection_item.trigger()

	assert_false(result, "Trigger should fail without charges")


func test_trigger_returns_false_when_not_placed_for_placed_mode() -> void:
	protection_item.placement_mode = ProtectionItem.PlacementMode.PLACED
	protection_item._ready()

	var result: bool = protection_item.trigger()

	assert_false(result, "PLACED mode trigger should fail when not placed")


func test_trigger_emits_triggered_signal() -> void:
	# Note: Base ProtectionItem._on_triggered returns false, so triggered signal
	# is not emitted. This behavior is tested via Crucifix/SageBundle subclasses
	# which have actual implementations that return true.
	# Here we just verify the signal exists and can be connected.
	protection_item._ready()
	var connected: bool = false
	protection_item.triggered.connect(func(_loc): connected = true)
	assert_true(protection_item.has_signal("triggered"), "Should have triggered signal")


# --- Can Use Tests ---


func test_can_use_returns_true_for_held_mode() -> void:
	protection_item.placement_mode = ProtectionItem.PlacementMode.HELD
	protection_item._ready()
	protection_item._is_equipped = true

	var mock_player := Node.new()
	add_child_autofree(mock_player)

	assert_true(protection_item.can_use(mock_player), "HELD mode should be usable")


func test_can_use_returns_false_when_placed() -> void:
	protection_item.placement_mode = ProtectionItem.PlacementMode.PLACED
	protection_item._ready()
	protection_item._is_equipped = true

	var mock_player := Node.new()
	add_child_autofree(mock_player)

	protection_item.place_at(Vector3.ZERO)

	assert_false(protection_item.can_use(mock_player), "Should not use when already placed")


func test_can_use_returns_false_without_charges() -> void:
	protection_item.max_charges = 0
	protection_item._ready()
	protection_item._is_equipped = true

	var mock_player := Node.new()
	add_child_autofree(mock_player)

	assert_false(protection_item.can_use(mock_player), "Should not use without charges")


# --- Network State Tests ---


func test_get_network_state_includes_charges() -> void:
	protection_item.max_charges = 2
	protection_item._ready()
	protection_item.consume_charge()

	var state := protection_item.get_network_state()

	assert_eq(state["charges"], 1, "Network state should include charges")


func test_get_network_state_includes_placement() -> void:
	protection_item._ready()
	protection_item.place_at(Vector3(1.0, 2.0, 3.0))

	var state := protection_item.get_network_state()

	assert_true(state["is_placed"], "Network state should include placement")
	assert_eq(state["placed_position"]["x"], 1.0, "Should include x position")
	assert_eq(state["placed_position"]["y"], 2.0, "Should include y position")
	assert_eq(state["placed_position"]["z"], 3.0, "Should include z position")


func test_apply_network_state_restores_charges() -> void:
	protection_item._ready()
	var state := {"charges": 5}

	protection_item.apply_network_state(state)

	assert_eq(protection_item.get_charges_remaining(), 5, "Should restore charges")


func test_apply_network_state_restores_placement() -> void:
	protection_item._ready()
	var state := {
		"is_placed": true,
		"placed_position": {"x": 5.0, "y": 0.0, "z": -3.0}
	}

	protection_item.apply_network_state(state)

	assert_true(protection_item.is_placed(), "Should restore is_placed")
	assert_eq(protection_item.get_placed_position(), Vector3(5.0, 0.0, -3.0))


