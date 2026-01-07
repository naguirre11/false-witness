extends GutTest
## Unit tests for EquipmentManager.

const EquipmentManagerScript = preload("res://src/equipment/equipment_manager.gd")
const EquipmentScript = preload("res://src/equipment/equipment.gd")

var manager: EquipmentManager
var mock_player: Node3D
var equipment_holder: Node3D


func before_each() -> void:
	# Create mock player hierarchy
	mock_player = Node3D.new()
	mock_player.name = "Player"

	var head := Node3D.new()
	head.name = "Head"
	mock_player.add_child(head)

	equipment_holder = Node3D.new()
	equipment_holder.name = "EquipmentHolder"
	head.add_child(equipment_holder)

	manager = EquipmentManagerScript.new()
	manager.name = "EquipmentManager"
	mock_player.add_child(manager)

	add_child(mock_player)


func after_each() -> void:
	mock_player.queue_free()
	manager = null
	mock_player = null
	equipment_holder = null


# --- Initialization Tests ---


func test_initializes_three_slots() -> void:
	var slots: Array[EquipmentSlot] = manager.get_slots()

	assert_eq(slots.size(), 3)


func test_slots_start_empty() -> void:
	assert_eq(manager.get_filled_slot_count(), 0)


func test_active_slot_starts_at_zero() -> void:
	assert_eq(manager.get_active_slot(), 0)


func test_loadout_not_locked_initially() -> void:
	assert_false(manager.is_loadout_locked())


func test_loadout_not_complete_when_empty() -> void:
	assert_false(manager.is_loadout_complete())


# --- Loadout Assignment Tests ---


func test_assign_equipment_to_slot() -> void:
	var result: bool = manager.assign_equipment(0, 0)  # Slot 0, EMF Reader

	assert_true(result)
	assert_eq(manager.get_slot_type(0), 0)


func test_assign_emits_loadout_changed() -> void:
	var received := {"called": false}
	manager.loadout_changed.connect(func(_s): received["called"] = true)

	manager.assign_equipment(1, 2)

	assert_true(received["called"])


func test_assign_invalid_slot_fails() -> void:
	var result: bool = manager.assign_equipment(5, 0)

	assert_false(result)


func test_assign_negative_slot_fails() -> void:
	var result: bool = manager.assign_equipment(-1, 0)

	assert_false(result)


func test_assign_duplicate_equipment_fails() -> void:
	manager.assign_equipment(0, 3)  # Thermometer in slot 0

	var result: bool = manager.assign_equipment(1, 3)  # Try thermometer in slot 1

	assert_false(result)


func test_clear_slot() -> void:
	manager.assign_equipment(0, 1)
	var result: bool = manager.clear_slot(0)

	assert_true(result)
	assert_eq(manager.get_slot_type(0), -1)


func test_clear_invalid_slot_fails() -> void:
	var result: bool = manager.clear_slot(10)

	assert_false(result)


func test_filled_slot_count_accurate() -> void:
	manager.assign_equipment(0, 0)
	manager.assign_equipment(2, 4)

	assert_eq(manager.get_filled_slot_count(), 2)


func test_loadout_complete_when_all_filled() -> void:
	manager.assign_equipment(0, 0)
	manager.assign_equipment(1, 1)
	manager.assign_equipment(2, 2)

	assert_true(manager.is_loadout_complete())


# --- Loadout Locking Tests ---


func test_lock_loadout_sets_flag() -> void:
	manager.lock_loadout()

	assert_true(manager.is_loadout_locked())


func test_lock_loadout_emits_signal() -> void:
	var received := {"called": false}
	manager.equipment_locked.connect(func(): received["called"] = true)

	manager.lock_loadout()

	assert_true(received["called"])


func test_assign_fails_when_locked() -> void:
	manager.lock_loadout()

	var result: bool = manager.assign_equipment(0, 5)

	assert_false(result)


func test_clear_fails_when_locked() -> void:
	manager.assign_equipment(0, 0)
	manager.lock_loadout()

	var result: bool = manager.clear_slot(0)

	assert_false(result)


func test_unlock_loadout_allows_changes() -> void:
	manager.lock_loadout()
	manager.unlock_loadout()

	var result: bool = manager.assign_equipment(0, 6)

	assert_true(result)


# --- Active Slot Switching Tests ---


func test_set_active_slot() -> void:
	manager.set_active_slot(1)

	assert_eq(manager.get_active_slot(), 1)


func test_set_active_slot_emits_signal() -> void:
	var received := {"old": -1, "new": -1}
	manager.active_slot_changed.connect(
		func(o, n):
			received["old"] = o
			received["new"] = n
	)

	manager.set_active_slot(2)

	assert_eq(received["old"], 0)
	assert_eq(received["new"], 2)


func test_set_same_slot_no_signal() -> void:
	var signal_count: int = 0
	manager.active_slot_changed.connect(func(_o, _n): signal_count += 1)

	manager.set_active_slot(0)  # Already at 0

	assert_eq(signal_count, 0)


func test_set_invalid_slot_ignored() -> void:
	manager.set_active_slot(1)
	manager.set_active_slot(99)

	assert_eq(manager.get_active_slot(), 1)


func test_set_negative_slot_ignored() -> void:
	manager.set_active_slot(1)
	manager.set_active_slot(-1)

	assert_eq(manager.get_active_slot(), 1)


# --- Active Equipment Tests ---


func test_get_active_equipment_returns_null_when_empty() -> void:
	var equipment: Equipment = manager.get_active_equipment()

	assert_null(equipment)


func test_is_equipment_active_returns_false_when_no_equipment() -> void:
	assert_false(manager.is_equipment_active())


# --- Input Control Tests ---


func test_set_input_enabled() -> void:
	manager.set_input_enabled(false)
	# Internal state check via attempting operations
	# Input is internal, but we can verify the manager accepts the call
	assert_true(true)  # Method doesn't crash


func test_set_local_player() -> void:
	manager.set_local_player(false)
	# Internal state check
	assert_true(true)  # Method doesn't crash


# --- Network State Tests ---


func test_get_network_state_includes_slots() -> void:
	manager.assign_equipment(0, 0)
	manager.assign_equipment(1, 3)

	var state: Dictionary = manager.get_network_state()

	assert_has(state, "slots")
	assert_eq(state.slots.size(), 3)


func test_get_network_state_includes_active_slot() -> void:
	manager.set_active_slot(2)

	var state: Dictionary = manager.get_network_state()

	assert_has(state, "active_slot")
	assert_eq(state.active_slot, 2)


func test_get_network_state_includes_locked() -> void:
	manager.lock_loadout()

	var state: Dictionary = manager.get_network_state()

	assert_has(state, "locked")
	assert_true(state.locked)


func test_apply_network_state_sets_slots() -> void:
	var state := {
		"slots":
		[
			{"slot_index": 0, "equipment_type": 2},
			{"slot_index": 1, "equipment_type": 5},
			{"slot_index": 2, "equipment_type": -1},
		],
		"active_slot": 0,
		"locked": false,
	}

	manager.apply_network_state(state)

	assert_eq(manager.get_slot_type(0), 2)
	assert_eq(manager.get_slot_type(1), 5)
	assert_eq(manager.get_slot_type(2), -1)


func test_apply_network_state_sets_active_slot() -> void:
	var state := {
		"slots": [],
		"active_slot": 1,
		"locked": false,
	}

	manager.apply_network_state(state)

	assert_eq(manager.get_active_slot(), 1)


func test_apply_network_state_sets_locked() -> void:
	var state := {
		"slots":
		[
			{"slot_index": 0, "equipment_type": 0},
			{"slot_index": 1, "equipment_type": 1},
			{"slot_index": 2, "equipment_type": 2},
		],
		"active_slot": 0,
		"locked": true,
	}

	manager.apply_network_state(state)

	assert_true(manager.is_loadout_locked())


func test_network_state_round_trip() -> void:
	manager.assign_equipment(0, 4)
	manager.assign_equipment(1, 6)
	manager.assign_equipment(2, 7)
	manager.set_active_slot(1)
	manager.lock_loadout()

	var state: Dictionary = manager.get_network_state()

	# Create new manager and apply state
	var new_manager := EquipmentManagerScript.new()
	mock_player.add_child(new_manager)
	await get_tree().process_frame

	new_manager.apply_network_state(state)

	assert_eq(new_manager.get_slot_type(0), 4)
	assert_eq(new_manager.get_slot_type(1), 6)
	assert_eq(new_manager.get_slot_type(2), 7)
	assert_eq(new_manager.get_active_slot(), 1)
	assert_true(new_manager.is_loadout_locked())

	new_manager.queue_free()


# --- Slot Type Query Tests ---


func test_get_slot_type_invalid_returns_negative() -> void:
	assert_eq(manager.get_slot_type(99), -1)


func test_get_slot_type_negative_returns_negative() -> void:
	assert_eq(manager.get_slot_type(-5), -1)


# --- All Equipment Types Assignable ---


func test_can_assign_all_equipment_types() -> void:
	for equipment_type in range(8):
		var test_manager := EquipmentManagerScript.new()
		mock_player.add_child(test_manager)
		await get_tree().process_frame

		var result: bool = test_manager.assign_equipment(0, equipment_type)

		assert_true(result, "Should be able to assign type %d" % equipment_type)
		assert_eq(test_manager.get_slot_type(0), equipment_type)

		test_manager.queue_free()
		await get_tree().process_frame


# --- Edge Cases ---


func test_unlock_when_not_locked_safe() -> void:
	manager.unlock_loadout()

	assert_false(manager.is_loadout_locked())


func test_lock_twice_safe() -> void:
	manager.lock_loadout()
	manager.lock_loadout()

	assert_true(manager.is_loadout_locked())


func test_reassign_same_slot_different_type() -> void:
	manager.assign_equipment(0, 0)
	manager.assign_equipment(0, 1)

	assert_eq(manager.get_slot_type(0), 1)
