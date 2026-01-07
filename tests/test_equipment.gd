extends GutTest
## Unit tests for Equipment base class.

const EquipmentScript = preload("res://src/equipment/equipment.gd")

var equipment: Equipment
var mock_player: Node3D


func before_each() -> void:
	equipment = EquipmentScript.new()
	mock_player = Node3D.new()
	add_child(equipment)
	add_child(mock_player)


func after_each() -> void:
	equipment.queue_free()
	mock_player.queue_free()
	equipment = null
	mock_player = null


# --- Basic State Tests ---


func test_default_state_is_inactive() -> void:
	assert_eq(equipment.get_state(), Equipment.EquipmentState.INACTIVE)


func test_default_not_equipped() -> void:
	assert_false(equipment.is_equipped())


func test_default_not_active() -> void:
	assert_false(equipment.is_active())


func test_equip_sets_owner() -> void:
	equipment.equip(mock_player)

	assert_true(equipment.is_equipped())
	assert_eq(equipment.get_owner_player(), mock_player)


func test_unequip_clears_owner() -> void:
	equipment.equip(mock_player)
	equipment.unequip()

	assert_false(equipment.is_equipped())
	assert_null(equipment.get_owner_player())


# --- Use Tests ---


func test_cannot_use_when_not_equipped() -> void:
	var result: bool = equipment.use(mock_player)

	assert_false(result)
	assert_eq(equipment.get_state(), Equipment.EquipmentState.INACTIVE)


func test_use_when_equipped_activates() -> void:
	equipment.equip(mock_player)
	var result: bool = equipment.use(mock_player)

	assert_true(result)
	assert_eq(equipment.get_state(), Equipment.EquipmentState.ACTIVE)


func test_use_emits_used_signal() -> void:
	equipment.equip(mock_player)
	var received := {"called": false, "player": null}
	equipment.used.connect(
		func(p):
			received["called"] = true
			received["player"] = p
	)

	equipment.use(mock_player)

	assert_true(received["called"])
	assert_eq(received["player"], mock_player)


func test_stop_using_emits_signal() -> void:
	equipment.equip(mock_player)
	equipment.use(mock_player)
	var received := {"called": false}
	equipment.stopped_using.connect(func(_p): received["called"] = true)

	equipment.stop_using(mock_player)

	assert_true(received["called"])


func test_stop_using_returns_to_inactive() -> void:
	equipment.equip(mock_player)
	equipment.use(mock_player)

	equipment.stop_using(mock_player)

	assert_eq(equipment.get_state(), Equipment.EquipmentState.INACTIVE)


# --- Use Mode Tests ---


func test_hold_mode_stops_when_released() -> void:
	equipment.use_mode = Equipment.UseMode.HOLD
	equipment.equip(mock_player)
	equipment.use(mock_player)
	assert_eq(equipment.get_state(), Equipment.EquipmentState.ACTIVE)

	equipment.stop_using(mock_player)

	assert_eq(equipment.get_state(), Equipment.EquipmentState.INACTIVE)


func test_toggle_mode_toggles_state() -> void:
	equipment.use_mode = Equipment.UseMode.TOGGLE
	equipment.equip(mock_player)

	# First use - activate
	equipment.use(mock_player)
	assert_eq(equipment.get_state(), Equipment.EquipmentState.ACTIVE)

	# Second use - deactivate
	equipment.use(mock_player)
	assert_eq(equipment.get_state(), Equipment.EquipmentState.INACTIVE)


func test_toggle_mode_ignores_stop_using() -> void:
	equipment.use_mode = Equipment.UseMode.TOGGLE
	equipment.equip(mock_player)
	equipment.use(mock_player)

	# stop_using should not affect toggle mode
	equipment.stop_using(mock_player)
	assert_eq(equipment.get_state(), Equipment.EquipmentState.ACTIVE)


# --- Cooldown Tests ---


func test_cooldown_sets_state() -> void:
	equipment.cooldown_time = 1.0
	equipment.equip(mock_player)
	equipment.use(mock_player)

	equipment.stop_using(mock_player)

	assert_eq(equipment.get_state(), Equipment.EquipmentState.COOLDOWN)


func test_cooldown_prevents_use() -> void:
	equipment.cooldown_time = 1.0
	equipment.equip(mock_player)
	equipment.use(mock_player)
	equipment.stop_using(mock_player)

	var result: bool = equipment.use(mock_player)

	assert_false(result)


func test_cooldown_remaining_returns_time() -> void:
	equipment.cooldown_time = 2.0
	equipment.equip(mock_player)
	equipment.use(mock_player)
	equipment.stop_using(mock_player)

	var remaining: float = equipment.get_cooldown_remaining()

	assert_almost_eq(remaining, 2.0, 0.01)


func test_cooldown_decreases_over_time() -> void:
	equipment.cooldown_time = 2.0
	equipment.equip(mock_player)
	equipment.use(mock_player)
	equipment.stop_using(mock_player)

	# Simulate time passing
	equipment._process(0.5)

	assert_almost_eq(equipment.get_cooldown_remaining(), 1.5, 0.01)


func test_cooldown_ends_and_returns_to_inactive() -> void:
	equipment.cooldown_time = 0.5
	equipment.equip(mock_player)
	equipment.use(mock_player)
	equipment.stop_using(mock_player)

	# Simulate time passing beyond cooldown
	equipment._process(0.6)

	assert_eq(equipment.get_state(), Equipment.EquipmentState.INACTIVE)
	assert_almost_eq(equipment.get_cooldown_remaining(), 0.0, 0.01)


# --- State Change Signal Tests ---


func test_state_changed_signal_on_use() -> void:
	equipment.equip(mock_player)
	var received := {"state": -1}
	equipment.state_changed.connect(func(s): received["state"] = s)

	equipment.use(mock_player)

	assert_eq(received["state"], Equipment.EquipmentState.ACTIVE)


func test_state_changed_signal_on_stop() -> void:
	equipment.equip(mock_player)
	equipment.use(mock_player)
	var received := {"state": -1}
	equipment.state_changed.connect(func(s): received["state"] = s)

	equipment.stop_using(mock_player)

	assert_eq(received["state"], Equipment.EquipmentState.INACTIVE)


# --- Network State Tests ---


func test_get_network_state_includes_state() -> void:
	equipment.equip(mock_player)
	equipment.use(mock_player)

	var state: Dictionary = equipment.get_network_state()

	assert_has(state, "state")
	assert_eq(state.state, Equipment.EquipmentState.ACTIVE)


func test_get_network_state_includes_cooldown() -> void:
	equipment.cooldown_time = 2.0
	equipment.equip(mock_player)
	equipment.use(mock_player)
	equipment.stop_using(mock_player)

	var state: Dictionary = equipment.get_network_state()

	assert_has(state, "cooldown")
	assert_almost_eq(state.cooldown, 2.0, 0.01)


func test_apply_network_state_sets_state() -> void:
	var state := {"state": Equipment.EquipmentState.ACTIVE, "cooldown": 0.0}

	equipment.apply_network_state(state)

	assert_eq(equipment.get_state(), Equipment.EquipmentState.ACTIVE)


func test_apply_network_state_sets_cooldown() -> void:
	var state := {"state": Equipment.EquipmentState.COOLDOWN, "cooldown": 1.5}

	equipment.apply_network_state(state)

	assert_almost_eq(equipment.get_cooldown_remaining(), 1.5, 0.01)


# --- Equipment Type Tests ---


func test_equipment_type_default() -> void:
	assert_eq(equipment.equipment_type, Equipment.EquipmentType.EMF_READER)


func test_can_set_equipment_type() -> void:
	equipment.equipment_type = Equipment.EquipmentType.THERMOMETER

	assert_eq(equipment.equipment_type, Equipment.EquipmentType.THERMOMETER)


func test_get_display_name_returns_equipment_name() -> void:
	equipment.equipment_name = "Test Equipment"

	assert_eq(equipment.get_display_name(), "Test Equipment")


# --- Hunt Behavior Tests ---


func test_can_use_during_hunt_default_true() -> void:
	assert_true(equipment.can_use_during_hunt)


func test_detectable_evidence_returns_empty_by_default() -> void:
	var evidence: Array[String] = equipment.get_detectable_evidence()

	assert_eq(evidence.size(), 0)


# --- Unequip Stops Active Equipment ---


func test_unequip_stops_active_equipment() -> void:
	equipment.equip(mock_player)
	equipment.use(mock_player)
	var stopped := {"called": false}
	equipment.stopped_using.connect(func(_p): stopped["called"] = true)

	equipment.unequip()

	assert_true(stopped["called"])
	assert_eq(equipment.get_state(), Equipment.EquipmentState.INACTIVE)
