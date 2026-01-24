extends GutTest
## Unit tests for EquipmentSlot resource.

const EquipmentSlotScript = preload("res://src/equipment/equipment_slot.gd")

var slot: EquipmentSlot


func before_each() -> void:
	slot = EquipmentSlotScript.new()


func after_each() -> void:
	slot = null


# --- Basic State Tests ---


func test_default_equipment_type_is_empty() -> void:
	assert_eq(slot.equipment_type, -1)


func test_default_slot_index_is_zero() -> void:
	assert_eq(slot.slot_index, 0)


func test_default_has_no_equipment() -> void:
	assert_false(slot.has_equipment())


func test_default_has_no_instance() -> void:
	assert_false(slot.has_instance())


# --- Assignment Tests ---


func test_assign_sets_equipment_type() -> void:
	slot.assign(0)  # EMF_READER

	assert_eq(slot.equipment_type, 0)


func test_assign_marks_has_equipment() -> void:
	slot.assign(1)  # SPIRIT_BOX

	assert_true(slot.has_equipment())


func test_assign_emits_signal() -> void:
	var received := {"old": -999, "new": -999}
	slot.equipment_changed.connect(
		func(o, n):
			received["old"] = o
			received["new"] = n
	)

	slot.assign(2)  # JOURNAL

	assert_eq(received["old"], -1)
	assert_eq(received["new"], 2)


func test_assign_same_type_no_signal() -> void:
	slot.assign(3)
	var signal_count: int = 0
	slot.equipment_changed.connect(func(_o, _n): signal_count += 1)

	slot.assign(3)  # Same type

	assert_eq(signal_count, 0)


# --- Clear Tests ---


func test_clear_resets_equipment_type() -> void:
	slot.assign(4)
	slot.clear()

	assert_eq(slot.equipment_type, -1)


func test_clear_marks_no_equipment() -> void:
	slot.assign(5)
	slot.clear()

	assert_false(slot.has_equipment())


func test_clear_emits_signal() -> void:
	slot.assign(6)
	var received := {"old": -999, "new": -999}
	slot.equipment_changed.connect(
		func(o, n):
			received["old"] = o
			received["new"] = n
	)

	slot.clear()

	assert_eq(received["old"], 6)
	assert_eq(received["new"], -1)


func test_clear_empty_slot_no_signal() -> void:
	var signal_count: int = 0
	slot.equipment_changed.connect(func(_o, _n): signal_count += 1)

	slot.clear()

	assert_eq(signal_count, 0)


# --- Instance Tests ---


func test_has_instance_with_valid_node() -> void:
	var instance := Node.new()
	add_child(instance)
	slot.equipment_instance = instance

	assert_true(slot.has_instance())

	instance.queue_free()


func test_has_instance_with_null() -> void:
	slot.equipment_instance = null

	assert_false(slot.has_instance())


func test_clear_clears_instance() -> void:
	var instance := Node.new()
	add_child(instance)
	slot.equipment_instance = instance
	slot.assign(0)

	slot.clear()

	assert_null(slot.equipment_instance)
	instance.queue_free()


# --- Type Name Tests ---


func test_get_type_name_when_empty() -> void:
	assert_eq(slot.get_type_name(), "Empty")


func test_get_type_name_emf_reader() -> void:
	slot.assign(0)
	assert_eq(slot.get_type_name(), "EMF Reader")


func test_get_type_name_spirit_box() -> void:
	slot.assign(1)
	assert_eq(slot.get_type_name(), "Spirit Box")


func test_get_type_name_journal() -> void:
	slot.assign(2)
	assert_eq(slot.get_type_name(), "Journal")


func test_get_type_name_thermometer() -> void:
	slot.assign(3)
	assert_eq(slot.get_type_name(), "Thermometer")


func test_get_type_name_uv_flashlight() -> void:
	slot.assign(4)
	assert_eq(slot.get_type_name(), "UV Flashlight")


func test_get_type_name_dots_projector() -> void:
	slot.assign(5)
	assert_eq(slot.get_type_name(), "DOTS Projector")


func test_get_type_name_video_camera() -> void:
	slot.assign(6)
	assert_eq(slot.get_type_name(), "Video Camera")


func test_get_type_name_parabolic_mic() -> void:
	slot.assign(7)
	assert_eq(slot.get_type_name(), "Parabolic Mic")


func test_get_type_name_spectral_calibrator() -> void:
	slot.assign(8)
	assert_eq(slot.get_type_name(), "Spectral Calibrator")


func test_get_type_name_spectral_lens_reader() -> void:
	slot.assign(9)
	assert_eq(slot.get_type_name(), "Spectral Lens Reader")


func test_get_type_name_dowsing_rods() -> void:
	slot.assign(10)
	assert_eq(slot.get_type_name(), "Dowsing Rods")


func test_get_type_name_aura_imager() -> void:
	slot.assign(11)
	assert_eq(slot.get_type_name(), "Aura Imager")


func test_get_type_name_ghost_writing_book() -> void:
	slot.assign(12)
	assert_eq(slot.get_type_name(), "Ghost Writing Book")


func test_get_type_name_crucifix() -> void:
	slot.assign(13)
	assert_eq(slot.get_type_name(), "Crucifix")


func test_get_type_name_sage_bundle() -> void:
	slot.assign(14)
	assert_eq(slot.get_type_name(), "Sage Bundle")


func test_get_type_name_salt() -> void:
	slot.assign(15)
	assert_eq(slot.get_type_name(), "Salt")


# --- Static Helper Tests ---


func test_type_to_name_returns_correct_names() -> void:
	assert_eq(EquipmentSlot.type_to_name(0), "EMF Reader")
	assert_eq(EquipmentSlot.type_to_name(3), "Thermometer")
	assert_eq(EquipmentSlot.type_to_name(8), "Spectral Calibrator")
	assert_eq(EquipmentSlot.type_to_name(12), "Ghost Writing Book")
	assert_eq(EquipmentSlot.type_to_name(15), "Salt")


func test_type_to_name_unknown_type() -> void:
	assert_eq(EquipmentSlot.type_to_name(99), "Unknown")


func test_name_to_type_returns_correct_types() -> void:
	assert_eq(EquipmentSlot.name_to_type("EMF Reader"), 0)
	assert_eq(EquipmentSlot.name_to_type("Thermometer"), 3)
	assert_eq(EquipmentSlot.name_to_type("Spectral Calibrator"), 8)
	assert_eq(EquipmentSlot.name_to_type("Ghost Writing Book"), 12)
	assert_eq(EquipmentSlot.name_to_type("Salt"), 15)


func test_name_to_type_unknown_name() -> void:
	assert_eq(EquipmentSlot.name_to_type("Invalid Equipment"), -1)


func test_get_scene_path_returns_path() -> void:
	var path: String = EquipmentSlot.get_scene_path(0)
	assert_eq(path, "res://scenes/equipment/emf_reader.tscn")


func test_get_scene_path_unknown_type() -> void:
	var path: String = EquipmentSlot.get_scene_path(99)
	assert_eq(path, "")


# --- Serialization Tests ---


func test_to_dict_includes_slot_index() -> void:
	slot.slot_index = 2

	var data: Dictionary = slot.to_dict()

	assert_has(data, "slot_index")
	assert_eq(data.slot_index, 2)


func test_to_dict_includes_equipment_type() -> void:
	slot.assign(3)

	var data: Dictionary = slot.to_dict()

	assert_has(data, "equipment_type")
	assert_eq(data.equipment_type, 3)


func test_from_dict_sets_slot_index() -> void:
	var data := {"slot_index": 1, "equipment_type": 5}

	slot.from_dict(data)

	assert_eq(slot.slot_index, 1)


func test_from_dict_sets_equipment_type() -> void:
	var data := {"slot_index": 0, "equipment_type": 4}

	slot.from_dict(data)

	assert_eq(slot.equipment_type, 4)


func test_from_dict_emits_signal_on_type_change() -> void:
	var received := {"called": false}
	slot.equipment_changed.connect(func(_o, _n): received["called"] = true)
	var data := {"slot_index": 0, "equipment_type": 6}

	slot.from_dict(data)

	assert_true(received["called"])


func test_serialization_round_trip() -> void:
	slot.slot_index = 2
	slot.assign(5)

	var data: Dictionary = slot.to_dict()
	var new_slot := EquipmentSlotScript.new()
	new_slot.from_dict(data)

	assert_eq(new_slot.slot_index, 2)
	assert_eq(new_slot.equipment_type, 5)
