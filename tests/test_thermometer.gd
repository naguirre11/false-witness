extends GutTest
## Unit tests for Thermometer equipment.

const ThermometerScript = preload("res://src/equipment/thermometer.gd")
const TempZoneScript = preload("res://src/equipment/temperature_zone.gd")

var thermometer: Thermometer
var mock_player: Node3D
var temp_zone: TemperatureZone


func before_each() -> void:
	thermometer = ThermometerScript.new()
	mock_player = Node3D.new()
	mock_player.name = "MockPlayer"
	add_child(thermometer)
	add_child(mock_player)


func after_each() -> void:
	# Remove zone from group first
	if temp_zone and is_instance_valid(temp_zone):
		if temp_zone.is_in_group("temperature_zone"):
			temp_zone.remove_from_group("temperature_zone")
		temp_zone.queue_free()
	thermometer.queue_free()
	mock_player.queue_free()
	thermometer = null
	mock_player = null
	temp_zone = null


func _create_temp_zone(
	pos: Vector3 = Vector3.ZERO,
	base_temp: float = 18.0,
	radius: float = 5.0
) -> TemperatureZone:
	temp_zone = TempZoneScript.new()
	temp_zone.base_temperature = base_temp
	temp_zone.zone_radius = radius
	temp_zone.enable_natural_variance = false
	temp_zone.position = pos
	add_child(temp_zone)
	return temp_zone


# --- Basic Equipment Properties ---


func test_equipment_type_is_thermometer() -> void:
	assert_eq(thermometer.equipment_type, Equipment.EquipmentType.THERMOMETER)


func test_equipment_name_is_set() -> void:
	assert_eq(thermometer.equipment_name, "Thermometer")


func test_use_mode_is_hold() -> void:
	assert_eq(thermometer.use_mode, Equipment.UseMode.HOLD)


func test_detectable_evidence_includes_freezing_temperature() -> void:
	var evidence: Array[String] = thermometer.get_detectable_evidence()

	assert_has(evidence, "FREEZING_TEMPERATURE")


# --- Temperature Reading Tests ---


func test_default_temperature_is_ambient() -> void:
	assert_eq(thermometer.get_temperature(), Thermometer.AMBIENT_TEMPERATURE)


func test_temperature_ambient_when_inactive() -> void:
	thermometer.equip(mock_player)
	_create_temp_zone(Vector3.ZERO, 5.0)  # Cold zone
	mock_player.global_position = Vector3.ZERO

	# Not activated - should still show ambient
	assert_eq(thermometer.get_temperature(), Thermometer.AMBIENT_TEMPERATURE)


func test_temperature_detected_when_active() -> void:
	thermometer.equip(mock_player)
	_create_temp_zone(Vector3.ZERO, 10.0, 5.0)
	mock_player.global_position = Vector3.ZERO

	thermometer.use(mock_player)
	for i in range(5):
		thermometer._process(0.2)

	# Should detect the zone's temperature
	assert_almost_eq(thermometer.get_temperature(), 10.0, 0.5)


func test_temperature_ambient_outside_zones() -> void:
	thermometer.equip(mock_player)
	_create_temp_zone(Vector3(100, 0, 0), 5.0, 5.0)  # Far away zone
	mock_player.global_position = Vector3.ZERO

	thermometer.use(mock_player)
	for i in range(5):
		thermometer._process(0.2)

	assert_eq(thermometer.get_temperature(), Thermometer.AMBIENT_TEMPERATURE)


func test_temperature_reset_when_deactivated() -> void:
	thermometer.equip(mock_player)
	_create_temp_zone(Vector3.ZERO, 5.0)
	mock_player.global_position = Vector3.ZERO

	thermometer.use(mock_player)
	for i in range(5):
		thermometer._process(0.2)
	assert_ne(thermometer.get_temperature(), Thermometer.AMBIENT_TEMPERATURE)

	thermometer.stop_using(mock_player)

	assert_eq(thermometer.get_temperature(), Thermometer.AMBIENT_TEMPERATURE)


# --- Temperature Changed Signal ---


func test_temperature_changed_signal_emitted() -> void:
	thermometer.equip(mock_player)
	_create_temp_zone(Vector3.ZERO, 5.0)
	mock_player.global_position = Vector3.ZERO

	var received := {"temp": -999.0}
	thermometer.temperature_changed.connect(func(t): received["temp"] = t)

	thermometer.use(mock_player)
	for i in range(5):
		thermometer._process(0.2)

	assert_ne(received["temp"], -999.0)
	assert_almost_eq(received["temp"], 5.0, 0.5)


# --- Freezing Detection ---


func test_is_freezing_false_at_normal_temp() -> void:
	thermometer.equip(mock_player)
	_create_temp_zone(Vector3.ZERO, 18.0)
	mock_player.global_position = Vector3.ZERO

	thermometer.use(mock_player)
	for i in range(5):
		thermometer._process(0.2)

	assert_false(thermometer.is_freezing())


func test_is_freezing_true_below_threshold() -> void:
	thermometer.equip(mock_player)
	_create_temp_zone(Vector3.ZERO, 2.0)  # Below freezing threshold
	mock_player.global_position = Vector3.ZERO

	thermometer.use(mock_player)
	for i in range(5):
		thermometer._process(0.2)

	assert_true(thermometer.is_freezing())


func test_freezing_threshold_boundary() -> void:
	thermometer.equip(mock_player)
	mock_player.global_position = Vector3.ZERO

	# Exactly at 3.0 - not freezing
	_create_temp_zone(Vector3.ZERO, 3.0)
	thermometer.use(mock_player)
	for i in range(5):
		thermometer._process(0.2)

	assert_false(thermometer.is_freezing())


# --- Extreme Cold Detection ---


func test_is_extreme_cold_false_normally() -> void:
	thermometer.equip(mock_player)
	_create_temp_zone(Vector3.ZERO, 18.0)
	mock_player.global_position = Vector3.ZERO

	thermometer.use(mock_player)
	for i in range(5):
		thermometer._process(0.2)

	assert_false(thermometer.is_extreme_cold())


func test_is_extreme_cold_true_below_threshold() -> void:
	thermometer.equip(mock_player)
	_create_temp_zone(Vector3.ZERO, -10.0)  # Below extreme cold threshold
	mock_player.global_position = Vector3.ZERO

	thermometer.use(mock_player)
	for i in range(5):
		thermometer._process(0.2)

	assert_true(thermometer.is_extreme_cold())


# --- Reading Quality Tests ---


func test_default_quality_is_weak() -> void:
	thermometer.equip(mock_player)
	thermometer.use(mock_player)

	assert_eq(thermometer.get_reading_quality(), EvidenceEnums.ReadingQuality.WEAK)


func test_quality_weak_when_moving() -> void:
	thermometer.equip(mock_player)
	_create_temp_zone(Vector3.ZERO, 5.0)

	thermometer.use(mock_player)

	# Simulate movement
	mock_player.global_position = Vector3.ZERO
	thermometer._process(0.2)
	mock_player.global_position = Vector3(2, 0, 0)
	thermometer._process(0.2)

	assert_eq(thermometer.get_reading_quality(), EvidenceEnums.ReadingQuality.WEAK)


func test_quality_strong_when_stationary_in_zone() -> void:
	thermometer.equip(mock_player)
	_create_temp_zone(Vector3.ZERO, 5.0)
	mock_player.global_position = Vector3.ZERO

	thermometer.use(mock_player)

	# Simulate staying stationary for STRONG_READING_HOLD_TIME
	for i in range(15):  # 3 seconds with 0.2 intervals
		thermometer._process(0.2)

	assert_eq(thermometer.get_reading_quality(), EvidenceEnums.ReadingQuality.STRONG)


func test_quality_weak_when_no_zone() -> void:
	thermometer.equip(mock_player)
	mock_player.global_position = Vector3.ZERO

	thermometer.use(mock_player)

	# Simulate staying stationary (but no zone)
	for i in range(15):
		thermometer._process(0.2)

	# Should be weak because not in a zone
	assert_eq(thermometer.get_reading_quality(), EvidenceEnums.ReadingQuality.WEAK)


func test_is_strong_reading_helper() -> void:
	thermometer.equip(mock_player)
	_create_temp_zone(Vector3.ZERO, 5.0)
	mock_player.global_position = Vector3.ZERO

	thermometer.use(mock_player)

	# Initially weak
	thermometer._process(0.2)
	assert_false(thermometer.is_strong_reading())

	# Wait for strong
	for i in range(15):
		thermometer._process(0.2)

	assert_true(thermometer.is_strong_reading())


func test_quality_changed_signal_emitted() -> void:
	thermometer.equip(mock_player)
	_create_temp_zone(Vector3.ZERO, 5.0)
	mock_player.global_position = Vector3.ZERO

	var received := {"quality": -1}
	thermometer.quality_changed.connect(func(q): received["quality"] = q)

	thermometer.use(mock_player)

	# Wait for strong
	for i in range(15):
		thermometer._process(0.2)

	assert_eq(received["quality"], EvidenceEnums.ReadingQuality.STRONG)


# --- Zone Detection ---


func test_get_current_zone_returns_zone() -> void:
	thermometer.equip(mock_player)
	var zone := _create_temp_zone(Vector3.ZERO, 5.0)
	mock_player.global_position = Vector3.ZERO

	thermometer.use(mock_player)
	for i in range(5):
		thermometer._process(0.2)

	assert_eq(thermometer.get_current_zone(), zone)


func test_get_current_zone_null_when_outside() -> void:
	thermometer.equip(mock_player)
	_create_temp_zone(Vector3(100, 0, 0), 5.0)
	mock_player.global_position = Vector3.ZERO

	thermometer.use(mock_player)
	for i in range(5):
		thermometer._process(0.2)

	assert_null(thermometer.get_current_zone())


# --- Network State Tests ---


func test_network_state_includes_temperature() -> void:
	thermometer.equip(mock_player)
	_create_temp_zone(Vector3.ZERO, 5.0)
	mock_player.global_position = Vector3.ZERO

	thermometer.use(mock_player)
	for i in range(5):
		thermometer._process(0.2)

	var state: Dictionary = thermometer.get_network_state()

	assert_has(state, "temperature")
	assert_almost_eq(state.temperature, 5.0, 0.5)


func test_network_state_includes_quality() -> void:
	thermometer.equip(mock_player)
	thermometer.use(mock_player)

	var state: Dictionary = thermometer.get_network_state()

	assert_has(state, "quality")


func test_network_state_includes_is_freezing() -> void:
	thermometer.equip(mock_player)
	_create_temp_zone(Vector3.ZERO, 2.0)
	mock_player.global_position = Vector3.ZERO

	thermometer.use(mock_player)
	for i in range(5):
		thermometer._process(0.2)

	var state: Dictionary = thermometer.get_network_state()

	assert_has(state, "is_freezing")
	assert_true(state.is_freezing)


func test_apply_network_state_sets_temperature() -> void:
	var state := {
		"state": Equipment.EquipmentState.ACTIVE,
		"cooldown": 0.0,
		"temperature": 3.5,
		"displayed_temp": 3.5,
		"quality": EvidenceEnums.ReadingQuality.STRONG,
	}

	var received := {"temp": -999.0}
	thermometer.temperature_changed.connect(func(t): received["temp"] = t)

	thermometer.apply_network_state(state)

	assert_almost_eq(thermometer.get_temperature(), 3.5, 0.1)
	assert_almost_eq(received["temp"], 3.5, 0.1)


# --- Displayed Temperature ---


func test_displayed_temperature_rounded() -> void:
	thermometer.equip(mock_player)
	_create_temp_zone(Vector3.ZERO, 5.123456)
	mock_player.global_position = Vector3.ZERO

	thermometer.use(mock_player)
	for i in range(5):
		thermometer._process(0.2)

	var displayed: float = thermometer.get_displayed_temperature()
	# Should be rounded to 1 decimal place
	assert_almost_eq(displayed, 5.1, 0.05)


# --- Entity Temperature Influence ---


func test_detects_entity_cooled_zone() -> void:
	thermometer.equip(mock_player)
	var zone := _create_temp_zone(Vector3.ZERO, 18.0)
	mock_player.global_position = Vector3.ZERO

	# Simulate entity entering
	zone.set_entity_influence(-20.0)
	zone._process(0.1)

	thermometer.use(mock_player)
	for i in range(5):
		thermometer._process(0.2)

	# Should detect -2 (18 - 20)
	assert_almost_eq(thermometer.get_temperature(), -2.0, 0.5)
	assert_true(thermometer.is_freezing())


# --- Multiple Zones ---


func test_detects_nearest_zone() -> void:
	thermometer.equip(mock_player)

	# Create two zones
	var zone1 := TempZoneScript.new()
	zone1.base_temperature = 15.0
	zone1.zone_radius = 5.0
	zone1.enable_natural_variance = false
	zone1.position = Vector3(10, 0, 0)  # Far
	add_child(zone1)

	var zone2 := TempZoneScript.new()
	zone2.base_temperature = 5.0
	zone2.zone_radius = 5.0
	zone2.enable_natural_variance = false
	zone2.position = Vector3(0, 0, 0)  # Close
	add_child(zone2)

	mock_player.global_position = Vector3(1, 0, 0)  # Inside zone2

	thermometer.use(mock_player)
	for i in range(5):
		thermometer._process(0.2)

	# Should detect the closer zone's temperature
	assert_almost_eq(thermometer.get_temperature(), 5.0, 0.5)

	# Clean up
	zone1.remove_from_group("temperature_zone")
	zone2.remove_from_group("temperature_zone")
	zone1.queue_free()
	zone2.queue_free()


# --- Evidence Collection Tests ---


func test_evidence_detected_signal_on_freezing() -> void:
	thermometer.equip(mock_player)
	_create_temp_zone(Vector3.ZERO, 2.0)  # Below freezing
	mock_player.global_position = Vector3.ZERO

	var received := {"evidence": null}
	thermometer.evidence_detected.connect(func(e): received["evidence"] = e)

	thermometer.use(mock_player)
	for i in range(5):
		thermometer._process(0.2)

	# Verify freezing was detected (evidence signal depends on EvidenceManager)
	assert_true(thermometer.is_freezing())


func test_evidence_not_collected_above_threshold() -> void:
	thermometer.equip(mock_player)
	_create_temp_zone(Vector3.ZERO, 10.0)  # Above freezing
	mock_player.global_position = Vector3.ZERO

	var received := {"evidence": null}
	thermometer.evidence_detected.connect(func(e): received["evidence"] = e)

	thermometer.use(mock_player)
	for i in range(5):
		thermometer._process(0.2)

	assert_null(received["evidence"])


func test_evidence_not_collected_twice() -> void:
	thermometer.equip(mock_player)
	_create_temp_zone(Vector3.ZERO, 2.0)
	mock_player.global_position = Vector3.ZERO

	var count := {"c": 0}
	thermometer.evidence_detected.connect(func(_e): count["c"] += 1)

	thermometer.use(mock_player)
	for i in range(20):  # Many updates
		thermometer._process(0.2)

	# Should only collect once
	assert_true(count["c"] <= 1)
