extends GutTest
## Unit tests for TemperatureZone.

const TempZoneScript = preload("res://src/equipment/temperature_zone.gd")

var temp_zone: TemperatureZone


func before_each() -> void:
	temp_zone = TempZoneScript.new()
	add_child(temp_zone)


func after_each() -> void:
	temp_zone.queue_free()
	temp_zone = null


# --- Basic Properties ---


func test_added_to_temperature_zone_group() -> void:
	assert_true(temp_zone.is_in_group("temperature_zone"))


func test_default_base_temperature() -> void:
	assert_eq(temp_zone.base_temperature, 18.0)


func test_get_temperature_returns_base() -> void:
	temp_zone.enable_natural_variance = false
	temp_zone._ready()

	assert_almost_eq(temp_zone.get_temperature(), 18.0, 0.1)


func test_get_base_temperature() -> void:
	temp_zone.base_temperature = 20.0
	temp_zone._ready()

	assert_eq(temp_zone.get_base_temperature(), 20.0)


func test_default_zone_radius() -> void:
	assert_eq(temp_zone.zone_radius, 5.0)


func test_default_zone_name() -> void:
	assert_eq(temp_zone.zone_name, "Room")


# --- Entity Influence ---


func test_default_entity_influence_is_zero() -> void:
	assert_eq(temp_zone.get_entity_influence(), 0.0)


func test_set_entity_influence_changes_value() -> void:
	temp_zone.set_entity_influence(-15.0)

	assert_eq(temp_zone.get_entity_influence(), -15.0)


func test_entity_influence_affects_temperature() -> void:
	temp_zone.base_temperature = 18.0
	temp_zone.enable_natural_variance = false
	temp_zone.set_entity_influence(-20.0)
	temp_zone._process(0.1)

	assert_almost_eq(temp_zone.get_temperature(), -2.0, 0.1)


func test_entity_influence_emits_signal() -> void:
	var received := {"influence": 0.0}
	temp_zone.entity_influence_changed.connect(func(i): received["influence"] = i)

	temp_zone.set_entity_influence(-10.0)

	assert_eq(received["influence"], -10.0)


func test_set_target_influence_gradual_change() -> void:
	temp_zone.base_temperature = 18.0
	temp_zone.enable_natural_variance = false
	temp_zone.influence_change_rate = 1.0  # 1 degree per second

	temp_zone.set_target_influence(-10.0)

	# Should not be at target immediately
	assert_eq(temp_zone.get_entity_influence(), 0.0)

	# Simulate time passing
	for i in range(20):
		temp_zone._process(0.1)

	# Should be closer to target (2 seconds = -2 degrees of change)
	assert_lt(temp_zone.get_entity_influence(), 0.0)


func test_entity_enter_sets_target() -> void:
	temp_zone.entity_enter(-20.0)

	assert_eq(temp_zone.target_influence, -20.0)


func test_entity_leave_resets_target() -> void:
	temp_zone.set_entity_influence(-20.0)
	temp_zone.entity_leave()

	assert_eq(temp_zone.target_influence, 0.0)


# --- Freezing Detection ---


func test_is_freezing_false_at_normal_temp() -> void:
	temp_zone.base_temperature = 18.0
	temp_zone.enable_natural_variance = false
	temp_zone._ready()

	assert_false(temp_zone.is_freezing())


func test_is_freezing_true_below_threshold() -> void:
	temp_zone.base_temperature = 18.0
	temp_zone.enable_natural_variance = false
	temp_zone.set_entity_influence(-20.0)
	temp_zone._process(0.1)

	# 18 - 20 = -2, which is below FREEZING_THRESHOLD (3)
	assert_true(temp_zone.is_freezing())


func test_freezing_threshold_boundary() -> void:
	temp_zone.base_temperature = 3.0
	temp_zone.enable_natural_variance = false
	temp_zone._process(0.1)

	# Exactly at 3.0 is NOT freezing (< 3 is freezing)
	assert_false(temp_zone.is_freezing())

	temp_zone.set_entity_influence(-0.1)
	temp_zone._process(0.1)

	# 2.9 is freezing
	assert_true(temp_zone.is_freezing())


# --- Extreme Cold Detection ---


func test_is_extreme_cold_false_normally() -> void:
	temp_zone.base_temperature = 18.0
	temp_zone.enable_natural_variance = false
	temp_zone._ready()

	assert_false(temp_zone.is_extreme_cold())


func test_is_extreme_cold_true_below_threshold() -> void:
	temp_zone.base_temperature = 0.0
	temp_zone.enable_natural_variance = false
	temp_zone.set_entity_influence(-10.0)
	temp_zone._process(0.1)

	# 0 - 10 = -10, which is below EXTREME_COLD_THRESHOLD (-5)
	assert_true(temp_zone.is_extreme_cold())


func test_extreme_cold_threshold_boundary() -> void:
	temp_zone.base_temperature = -5.0
	temp_zone.enable_natural_variance = false
	temp_zone._process(0.1)

	# Exactly at -5.0 is NOT extreme cold (< -5 is extreme)
	assert_false(temp_zone.is_extreme_cold())

	temp_zone.set_entity_influence(-0.1)
	temp_zone._process(0.1)

	# -5.1 is extreme cold
	assert_true(temp_zone.is_extreme_cold())


# --- Position Detection ---


func test_distance_to_returns_correct_value() -> void:
	temp_zone.global_position = Vector3(0, 0, 0)

	var dist: float = temp_zone.distance_to(Vector3(3, 4, 0))

	assert_almost_eq(dist, 5.0, 0.01)


func test_contains_position_inside_radius() -> void:
	temp_zone.global_position = Vector3.ZERO
	temp_zone.zone_radius = 5.0

	assert_true(temp_zone.contains_position(Vector3(3, 0, 0)))


func test_contains_position_outside_radius() -> void:
	temp_zone.global_position = Vector3.ZERO
	temp_zone.zone_radius = 5.0

	assert_false(temp_zone.contains_position(Vector3(10, 0, 0)))


func test_contains_position_on_boundary() -> void:
	temp_zone.global_position = Vector3.ZERO
	temp_zone.zone_radius = 5.0

	assert_true(temp_zone.contains_position(Vector3(5, 0, 0)))


# --- Natural Variance ---


func test_natural_variance_enabled_by_default() -> void:
	assert_true(temp_zone.enable_natural_variance)


func test_natural_variance_affects_temperature() -> void:
	temp_zone.base_temperature = 18.0
	temp_zone.enable_natural_variance = true
	temp_zone.variance_speed = 10.0  # Fast for testing

	# Record temperatures over time
	var temps: Array[float] = []
	for i in range(10):
		temp_zone._process(0.1)
		temps.append(temp_zone.get_temperature())

	# Temperature should vary (not all the same)
	var min_temp: float = INF
	var max_temp: float = -INF
	for t: float in temps:
		min_temp = minf(min_temp, t)
		max_temp = maxf(max_temp, t)

	assert_gt(max_temp - min_temp, 0.0)


func test_variance_disabled_stable_temperature() -> void:
	temp_zone.base_temperature = 18.0
	temp_zone.enable_natural_variance = false

	var first_temp: float = temp_zone.get_temperature()

	for i in range(10):
		temp_zone._process(0.1)

	assert_eq(temp_zone.get_temperature(), first_temp)


# --- Temperature Changed Signal ---


func test_temperature_changed_signal_emitted() -> void:
	temp_zone.base_temperature = 18.0
	temp_zone.enable_natural_variance = false

	var received := {"temp": -999.0}
	temp_zone.temperature_changed.connect(func(t): received["temp"] = t)

	temp_zone.set_entity_influence(-10.0)
	temp_zone._process(0.1)

	assert_almost_eq(received["temp"], 8.0, 0.1)


# --- Edge Cases ---


func test_very_cold_entity_influence() -> void:
	temp_zone.base_temperature = 18.0
	temp_zone.enable_natural_variance = false
	temp_zone.set_entity_influence(-30.0)
	temp_zone._process(0.1)

	assert_almost_eq(temp_zone.get_temperature(), -12.0, 0.1)


func test_warm_entity_influence() -> void:
	temp_zone.base_temperature = 18.0
	temp_zone.enable_natural_variance = false
	temp_zone.set_entity_influence(5.0)  # Warming effect
	temp_zone._process(0.1)

	assert_almost_eq(temp_zone.get_temperature(), 23.0, 0.1)
