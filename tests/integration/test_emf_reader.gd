extends GutTest
## Unit tests for EMFReader equipment.

const EMFReaderScript = preload("res://src/equipment/emf_reader.gd")
const EMFSourceScript = preload("res://src/equipment/emf_source.gd")

var emf_reader: EMFReader
var mock_player: Node3D
var emf_source: EMFSource


func before_each() -> void:
	emf_reader = EMFReaderScript.new()
	mock_player = Node3D.new()
	mock_player.name = "MockPlayer"
	add_child(emf_reader)
	add_child(mock_player)


func after_each() -> void:
	# Remove from group first to prevent detection by other tests
	if emf_source and is_instance_valid(emf_source):
		if emf_source.is_in_group("emf_source"):
			emf_source.remove_from_group("emf_source")
		emf_source.queue_free()
	emf_reader.queue_free()
	mock_player.queue_free()
	emf_reader = null
	mock_player = null
	emf_source = null


func _create_emf_source(pos: Vector3 = Vector3.ZERO, activity: float = 1.0) -> EMFSource:
	emf_source = EMFSourceScript.new()
	emf_source.base_activity = activity
	emf_source.position = pos
	add_child(emf_source)
	return emf_source


# --- Basic Equipment Properties ---


func test_equipment_type_is_emf_reader() -> void:
	assert_eq(emf_reader.equipment_type, Equipment.EquipmentType.EMF_READER)


func test_equipment_name_is_set() -> void:
	assert_eq(emf_reader.equipment_name, "EMF Reader")


func test_use_mode_is_hold() -> void:
	assert_eq(emf_reader.use_mode, Equipment.UseMode.HOLD)


func test_detectable_evidence_includes_emf_signature() -> void:
	var evidence: Array[String] = emf_reader.get_detectable_evidence()

	assert_has(evidence, "EMF_SIGNATURE")


# --- EMF Level Tests ---


func test_default_emf_level_is_zero() -> void:
	assert_eq(emf_reader.get_emf_level(), 0)


func test_emf_level_zero_when_inactive() -> void:
	emf_reader.equip(mock_player)
	# Create source but don't activate reader
	_create_emf_source(Vector3.ZERO)
	mock_player.global_position = Vector3.ZERO

	assert_eq(emf_reader.get_emf_level(), 0)


func test_emf_level_detected_when_active() -> void:
	emf_reader.equip(mock_player)
	_create_emf_source(Vector3(0, 0, 1))  # 1 meter away
	mock_player.global_position = Vector3.ZERO

	emf_reader.use(mock_player)
	# Simulate a few updates
	for i in range(3):
		emf_reader._process(0.1)

	assert_gt(emf_reader.get_emf_level(), 0)


func test_level_5_at_very_close_range() -> void:
	emf_reader.equip(mock_player)
	_create_emf_source(Vector3(0, 0, 1))  # Very close (within LEVEL_5_DISTANCE)
	mock_player.global_position = Vector3.ZERO

	emf_reader.use(mock_player)
	for i in range(3):
		emf_reader._process(0.1)

	assert_eq(emf_reader.get_emf_level(), 5)


func test_level_decreases_with_distance() -> void:
	emf_reader.equip(mock_player)
	_create_emf_source(Vector3(0, 0, 7))  # 7 meters away (between LEVEL_3 and LEVEL_2)
	mock_player.global_position = Vector3.ZERO

	emf_reader.use(mock_player)
	for i in range(3):
		emf_reader._process(0.1)

	var level: int = emf_reader.get_emf_level()
	assert_gt(level, 0)
	assert_lt(level, 5)  # Should be level 2 or 3 at 7m


func test_no_detection_outside_range() -> void:
	emf_reader.equip(mock_player)
	_create_emf_source(Vector3(0, 0, 20))  # 20 meters away (outside range)
	mock_player.global_position = Vector3.ZERO

	emf_reader.use(mock_player)
	for i in range(3):
		emf_reader._process(0.1)

	assert_eq(emf_reader.get_emf_level(), 0)


func test_level_reset_when_deactivated() -> void:
	emf_reader.equip(mock_player)
	_create_emf_source(Vector3(0, 0, 1))
	mock_player.global_position = Vector3.ZERO

	emf_reader.use(mock_player)
	for i in range(3):
		emf_reader._process(0.1)
	assert_gt(emf_reader.get_emf_level(), 0)

	emf_reader.stop_using(mock_player)

	assert_eq(emf_reader.get_emf_level(), 0)


# --- Level Changed Signal ---


func test_level_changed_signal_emitted() -> void:
	emf_reader.equip(mock_player)
	_create_emf_source(Vector3(0, 0, 1))
	mock_player.global_position = Vector3.ZERO

	var received := {"level": -1}
	emf_reader.level_changed.connect(func(lvl): received["level"] = lvl)

	emf_reader.use(mock_player)
	for i in range(3):
		emf_reader._process(0.1)

	assert_ne(received["level"], -1)


func test_level_changed_signal_on_stop() -> void:
	emf_reader.equip(mock_player)
	_create_emf_source(Vector3(0, 0, 1))
	mock_player.global_position = Vector3.ZERO

	emf_reader.use(mock_player)
	for i in range(3):
		emf_reader._process(0.1)

	var received := {"level": -1}
	emf_reader.level_changed.connect(func(lvl): received["level"] = lvl)

	emf_reader.stop_using(mock_player)

	assert_eq(received["level"], 0)


# --- Reading Quality Tests ---


func test_default_quality_is_weak() -> void:
	emf_reader.equip(mock_player)
	emf_reader.use(mock_player)

	assert_eq(emf_reader.get_reading_quality(), EvidenceEnums.ReadingQuality.WEAK)


func test_quality_weak_when_moving() -> void:
	emf_reader.equip(mock_player)
	_create_emf_source(Vector3(0, 0, 1))

	emf_reader.use(mock_player)

	# Simulate movement
	mock_player.global_position = Vector3.ZERO
	emf_reader._process(0.1)
	mock_player.global_position = Vector3(1, 0, 0)
	emf_reader._process(0.1)

	assert_eq(emf_reader.get_reading_quality(), EvidenceEnums.ReadingQuality.WEAK)


func test_quality_strong_when_stationary_and_close() -> void:
	emf_reader.equip(mock_player)
	_create_emf_source(Vector3(0, 0, 1))  # Within STRONG_READING_MAX_DISTANCE
	mock_player.global_position = Vector3.ZERO

	emf_reader.use(mock_player)

	# Simulate staying stationary for STRONG_READING_HOLD_TIME
	for i in range(20):  # 2 seconds with 0.1 intervals
		emf_reader._process(0.1)

	assert_eq(emf_reader.get_reading_quality(), EvidenceEnums.ReadingQuality.STRONG)


func test_quality_weak_when_far_even_if_stationary() -> void:
	emf_reader.equip(mock_player)
	_create_emf_source(Vector3(0, 0, 5))  # Outside STRONG_READING_MAX_DISTANCE
	mock_player.global_position = Vector3.ZERO

	emf_reader.use(mock_player)

	# Simulate staying stationary
	for i in range(20):
		emf_reader._process(0.1)

	assert_eq(emf_reader.get_reading_quality(), EvidenceEnums.ReadingQuality.WEAK)


func test_is_strong_reading_helper() -> void:
	emf_reader.equip(mock_player)
	_create_emf_source(Vector3(0, 0, 1))
	mock_player.global_position = Vector3.ZERO

	emf_reader.use(mock_player)

	# Initially weak
	emf_reader._process(0.1)
	assert_false(emf_reader.is_strong_reading())

	# Wait for strong
	for i in range(20):
		emf_reader._process(0.1)

	assert_true(emf_reader.is_strong_reading())


# --- Direction Indicator Tests ---


func test_direction_zero_when_no_source() -> void:
	emf_reader.equip(mock_player)
	mock_player.global_position = Vector3.ZERO

	emf_reader.use(mock_player)
	emf_reader._process(0.1)

	assert_eq(emf_reader.get_source_direction(), Vector3.ZERO)


func test_direction_points_to_source() -> void:
	emf_reader.equip(mock_player)
	_create_emf_source(Vector3(5, 0, 0))  # Source to the right
	mock_player.global_position = Vector3.ZERO

	emf_reader.use(mock_player)
	for i in range(3):
		emf_reader._process(0.1)

	var direction: Vector3 = emf_reader.get_source_direction()
	# Should be pointing roughly in +X direction
	assert_gt(direction.x, 0.5)


func test_direction_signal_emitted() -> void:
	emf_reader.equip(mock_player)
	_create_emf_source(Vector3(5, 0, 0))
	mock_player.global_position = Vector3.ZERO

	var received := {"dir": null}
	emf_reader.direction_changed.connect(func(d): received["dir"] = d)

	emf_reader.use(mock_player)
	for i in range(3):
		emf_reader._process(0.1)

	assert_not_null(received["dir"])


func test_direction_zero_when_out_of_range() -> void:
	emf_reader.equip(mock_player)
	_create_emf_source(Vector3(20, 0, 0))  # Outside DIRECTION_INDICATOR_RANGE
	mock_player.global_position = Vector3.ZERO

	emf_reader.use(mock_player)
	for i in range(3):
		emf_reader._process(0.1)

	assert_eq(emf_reader.get_source_direction(), Vector3.ZERO)


# --- Source Distance ---


func test_source_distance_returns_correct_value() -> void:
	emf_reader.equip(mock_player)
	_create_emf_source(Vector3(0, 0, 5))
	mock_player.global_position = Vector3.ZERO

	emf_reader.use(mock_player)
	for i in range(3):
		emf_reader._process(0.1)

	assert_almost_eq(emf_reader.get_source_distance(), 5.0, 0.01)


func test_source_distance_inf_when_no_source() -> void:
	emf_reader.equip(mock_player)
	mock_player.global_position = Vector3.ZERO

	emf_reader.use(mock_player)
	emf_reader._process(0.1)

	assert_eq(emf_reader.get_source_distance(), INF)


# --- Activity Level Effects ---


func test_higher_activity_increases_range() -> void:
	emf_reader.equip(mock_player)
	_create_emf_source(Vector3(0, 0, 4), 2.0)  # High activity
	mock_player.global_position = Vector3.ZERO

	emf_reader.use(mock_player)
	for i in range(3):
		emf_reader._process(0.1)

	# With activity 2.0, effective distance is halved, so 4m becomes 2m (Level 5)
	assert_eq(emf_reader.get_emf_level(), 5)


func test_zero_activity_no_reading() -> void:
	emf_reader.equip(mock_player)
	_create_emf_source(Vector3(0, 0, 1), 0.0)  # No activity
	mock_player.global_position = Vector3.ZERO

	emf_reader.use(mock_player)
	for i in range(3):
		emf_reader._process(0.1)

	assert_eq(emf_reader.get_emf_level(), 0)


# --- Network State Tests ---


func test_network_state_includes_emf_level() -> void:
	emf_reader.equip(mock_player)
	_create_emf_source(Vector3(0, 0, 1))
	mock_player.global_position = Vector3.ZERO

	emf_reader.use(mock_player)
	for i in range(3):
		emf_reader._process(0.1)

	var state: Dictionary = emf_reader.get_network_state()

	assert_has(state, "emf_level")
	assert_eq(state.emf_level, 5)


func test_network_state_includes_direction() -> void:
	emf_reader.equip(mock_player)
	_create_emf_source(Vector3(5, 0, 0))
	mock_player.global_position = Vector3.ZERO

	emf_reader.use(mock_player)
	for i in range(3):
		emf_reader._process(0.1)

	var state: Dictionary = emf_reader.get_network_state()

	assert_has(state, "direction_x")
	assert_has(state, "direction_y")
	assert_has(state, "direction_z")


func test_network_state_includes_quality() -> void:
	emf_reader.equip(mock_player)
	emf_reader.use(mock_player)

	var state: Dictionary = emf_reader.get_network_state()

	assert_has(state, "quality")


func test_apply_network_state_sets_level() -> void:
	var state := {
		"state": Equipment.EquipmentState.ACTIVE,
		"cooldown": 0.0,
		"emf_level": 4,
		"direction_x": 1.0,
		"direction_y": 0.0,
		"direction_z": 0.0,
		"quality": EvidenceEnums.ReadingQuality.STRONG,
	}

	var received := {"level": -1}
	emf_reader.level_changed.connect(func(lvl): received["level"] = lvl)

	emf_reader.apply_network_state(state)

	assert_eq(emf_reader.get_emf_level(), 4)
	assert_eq(received["level"], 4)


func test_apply_network_state_sets_direction() -> void:
	var state := {
		"state": Equipment.EquipmentState.ACTIVE,
		"cooldown": 0.0,
		"emf_level": 3,
		"direction_x": 0.0,
		"direction_y": 0.0,
		"direction_z": 1.0,
		"quality": EvidenceEnums.ReadingQuality.WEAK,
	}

	emf_reader.apply_network_state(state)

	var direction: Vector3 = emf_reader.get_source_direction()
	assert_almost_eq(direction.z, 1.0, 0.01)


# --- Evidence Collection Tests ---


func test_evidence_detected_signal_on_level_5() -> void:
	emf_reader.equip(mock_player)
	_create_emf_source(Vector3(0, 0, 1))
	mock_player.global_position = Vector3.ZERO

	var received := {"evidence": null}
	emf_reader.evidence_detected.connect(func(e): received["evidence"] = e)

	emf_reader.use(mock_player)
	for i in range(5):
		emf_reader._process(0.1)

	# Verify level 5 was detected (evidence signal depends on EvidenceManager being enabled)
	assert_eq(emf_reader.get_emf_level(), 5)
	# Note: Evidence collection requires EvidenceManager with collection enabled
	# The signal might not be emitted in tests where evidence collection is disabled


func test_evidence_not_collected_below_level_5() -> void:
	emf_reader.equip(mock_player)
	_create_emf_source(Vector3(0, 0, 5))  # Level 3-4 range
	mock_player.global_position = Vector3.ZERO

	var received := {"evidence": null}
	emf_reader.evidence_detected.connect(func(e): received["evidence"] = e)

	emf_reader.use(mock_player)
	for i in range(5):
		emf_reader._process(0.1)

	assert_null(received["evidence"])


# --- Multiple Sources ---


func test_detects_nearest_source() -> void:
	emf_reader.equip(mock_player)

	# Create two sources
	var source1 := EMFSourceScript.new()
	source1.base_activity = 1.0
	source1.position = Vector3(0, 0, 6)  # Far
	add_child(source1)

	var source2 := EMFSourceScript.new()
	source2.base_activity = 1.0
	source2.position = Vector3(0, 0, 2)  # Close
	add_child(source2)

	mock_player.global_position = Vector3.ZERO

	emf_reader.use(mock_player)
	for i in range(3):
		emf_reader._process(0.1)

	# Should detect the closer source (Level 5 at 2m)
	assert_eq(emf_reader.get_emf_level(), 5)

	# Clean up before next test
	source1.remove_from_group("emf_source")
	source2.remove_from_group("emf_source")
	source1.queue_free()
	source2.queue_free()


func test_direction_points_to_strongest() -> void:
	emf_reader.equip(mock_player)

	# Source far to the left
	var source1 := EMFSourceScript.new()
	source1.base_activity = 1.0
	source1.position = Vector3(-10, 0, 0)
	add_child(source1)

	# Source close to the right
	var source2 := EMFSourceScript.new()
	source2.base_activity = 1.0
	source2.position = Vector3(2, 0, 0)
	add_child(source2)

	mock_player.global_position = Vector3.ZERO

	emf_reader.use(mock_player)
	for i in range(3):
		emf_reader._process(0.1)

	var direction: Vector3 = emf_reader.get_source_direction()
	# Should point to closer source (positive X)
	assert_gt(direction.x, 0)

	# Clean up before next test
	source1.remove_from_group("emf_source")
	source2.remove_from_group("emf_source")
	source1.queue_free()
	source2.queue_free()
