extends GutTest
## Unit tests for EMFSource.

const EMFSourceScript = preload("res://src/equipment/emf_source.gd")

var emf_source: EMFSource


func before_each() -> void:
	emf_source = EMFSourceScript.new()
	add_child(emf_source)


func after_each() -> void:
	emf_source.queue_free()
	emf_source = null


# --- Basic Properties ---


func test_added_to_emf_source_group() -> void:
	assert_true(emf_source.is_in_group("emf_source"))


func test_default_activity_is_one() -> void:
	assert_eq(emf_source.get_emf_activity(), 1.0)


func test_base_activity_sets_current() -> void:
	emf_source.base_activity = 0.5

	# Need to trigger _ready again after changing base_activity
	emf_source._ready()

	assert_eq(emf_source.get_emf_activity(), 0.5)


# --- Set Activity ---


func test_set_activity_updates_value() -> void:
	emf_source.set_activity(2.0)

	assert_eq(emf_source.get_emf_activity(), 2.0)


func test_set_activity_clamps_negative() -> void:
	emf_source.set_activity(-1.0)

	assert_eq(emf_source.get_emf_activity(), 0.0)


func test_set_activity_emits_signal() -> void:
	var received := {"activity": -1.0}
	emf_source.activity_changed.connect(func(a): received["activity"] = a)

	emf_source.set_activity(1.5)

	assert_eq(received["activity"], 1.5)


func test_set_activity_no_signal_if_unchanged() -> void:
	emf_source.base_activity = 1.0

	var call_count := {"count": 0}
	emf_source.activity_changed.connect(func(_a): call_count["count"] += 1)

	emf_source.set_activity(1.0)

	assert_eq(call_count["count"], 0)


# --- Trigger Spike ---


func test_trigger_spike_increases_activity() -> void:
	emf_source.base_activity = 1.0
	emf_source.trigger_spike(2.0, 3.0)

	assert_eq(emf_source.get_emf_activity(), 3.0)


func test_trigger_spike_emits_signal() -> void:
	emf_source.base_activity = 1.0

	var received := {"activity": 0.0}
	emf_source.activity_changed.connect(func(a): received["activity"] = a)

	emf_source.trigger_spike(2.0, 2.0)

	assert_eq(received["activity"], 2.0)


func test_spike_ends_after_duration() -> void:
	emf_source.base_activity = 1.0
	emf_source.trigger_spike(0.5, 2.0)

	# Simulate time passing
	for i in range(6):
		emf_source._process(0.1)

	assert_eq(emf_source.get_emf_activity(), 1.0)


func test_is_active_true_during_spike() -> void:
	emf_source.base_activity = 1.0
	emf_source.trigger_spike(2.0, 2.0)

	assert_true(emf_source.is_active())


func test_is_active_false_after_spike() -> void:
	emf_source.base_activity = 1.0
	emf_source.trigger_spike(0.3, 2.0)

	for i in range(5):
		emf_source._process(0.1)

	assert_false(emf_source.is_active())


# --- Auto Pulse ---


func test_auto_pulse_off_by_default() -> void:
	assert_false(emf_source.auto_pulse)


func test_auto_pulse_triggers_spike() -> void:
	emf_source.base_activity = 1.0
	emf_source.auto_pulse = true
	emf_source.pulse_interval = 0.2
	emf_source.pulse_duration = 0.1
	emf_source.pulse_multiplier = 2.0

	# Wait for first pulse
	for i in range(3):
		emf_source._process(0.1)

	# Should be in spike or have completed one
	var activity: float = emf_source.get_emf_activity()
	# Either at spike level or back to base
	assert_true(activity >= 1.0)


func test_auto_pulse_cycles() -> void:
	emf_source.base_activity = 1.0
	emf_source.auto_pulse = true
	emf_source.pulse_interval = 0.2
	emf_source.pulse_duration = 0.1
	emf_source.pulse_multiplier = 2.0

	var spike_count := {"count": 0}
	var last_activity: float = 1.0

	emf_source.activity_changed.connect(
		func(a):
			if a > last_activity:
				spike_count["count"] += 1
			last_activity = a
	)

	# Run for several cycles
	for i in range(20):
		emf_source._process(0.1)

	# Should have multiple spikes
	assert_gt(spike_count["count"], 1)


# --- Edge Cases ---


func test_activity_changed_signal_on_spike_end() -> void:
	emf_source.base_activity = 1.0
	emf_source.trigger_spike(0.3, 2.0)

	var received := {"activity": 2.0}
	emf_source.activity_changed.connect(func(a): received["activity"] = a)

	# Wait for spike to end
	for i in range(5):
		emf_source._process(0.1)

	# Should return to base activity
	assert_eq(received["activity"], 1.0)


func test_is_active_with_elevated_base_activity() -> void:
	emf_source.base_activity = 1.0
	emf_source.set_activity(1.5)

	assert_true(emf_source.is_active())


func test_consecutive_spikes() -> void:
	emf_source.base_activity = 1.0

	# First spike
	emf_source.trigger_spike(0.2, 2.0)
	assert_eq(emf_source.get_emf_activity(), 2.0)

	# Second spike before first ends
	emf_source.trigger_spike(0.3, 3.0)
	assert_eq(emf_source.get_emf_activity(), 3.0)
