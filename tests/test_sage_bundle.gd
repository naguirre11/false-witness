extends GutTest
## Tests for SageBundle protection item.


var sage: SageBundle


func before_each() -> void:
	sage = SageBundle.new()
	add_child_autofree(sage)
	sage._ready()


# --- Initialization Tests ---


func test_equipment_type() -> void:
	assert_eq(
		sage.equipment_type,
		Equipment.EquipmentType.SAGE_BUNDLE,
		"Should have SAGE_BUNDLE type"
	)


func test_equipment_name() -> void:
	assert_eq(sage.equipment_name, "Sage Bundle", "Should have correct name")


func test_use_mode_is_instant() -> void:
	assert_eq(sage.use_mode, Equipment.UseMode.INSTANT, "Should use INSTANT mode")


func test_max_charges_is_one() -> void:
	assert_eq(sage.max_charges, 1, "Should have 1 charge")


func test_placement_mode_is_held() -> void:
	assert_eq(
		sage.placement_mode,
		ProtectionItem.PlacementMode.HELD,
		"Should use HELD mode"
	)


func test_can_use_during_hunt() -> void:
	assert_true(sage.can_use_during_hunt, "Should work during hunts")


func test_demon_duration_multiplier() -> void:
	assert_eq(
		sage.demon_duration_multiplier,
		0.5,
		"Demon multiplier should be 0.5"
	)


# --- Constants Tests ---


func test_blind_duration_constant() -> void:
	assert_eq(SageBundle.BLIND_DURATION, 5.0, "Blind duration should be 5 seconds")


func test_hunt_prevention_duration_constant() -> void:
	assert_eq(
		SageBundle.HUNT_PREVENTION_DURATION,
		60.0,
		"Hunt prevention should be 60 seconds"
	)


func test_demon_prevention_duration_constant() -> void:
	assert_eq(
		SageBundle.DEMON_PREVENTION_DURATION,
		30.0,
		"Demon prevention should be 30 seconds"
	)


# --- Trigger Tests ---


func test_trigger_consumes_charge() -> void:
	sage.trigger()

	assert_eq(sage.get_charges_remaining(), 0, "Trigger should consume charge")


func test_trigger_emits_depleted() -> void:
	watch_signals(sage)

	sage.trigger()

	assert_signal_emitted(sage, "depleted")


func test_trigger_fails_when_depleted() -> void:
	sage.trigger()

	var result: bool = sage.trigger()

	assert_false(result, "Second trigger should fail")


# --- Hunt Prevention Tests ---


func test_starts_hunt_prevention() -> void:
	sage.trigger()

	assert_true(sage.is_preventing_hunts(), "Should be preventing hunts after use")


func test_prevention_timer_set() -> void:
	sage.trigger()

	var remaining: float = sage.get_prevention_time_remaining()

	assert_gt(remaining, 0.0, "Should have prevention time remaining")


func test_prevention_ends_after_timer() -> void:
	sage.trigger()

	# Simulate time passing
	sage._prevention_timer = 0.1
	sage._process(0.2)

	assert_false(sage.is_preventing_hunts(), "Prevention should end after timer")


func test_prevention_timer_decrements() -> void:
	sage.trigger()
	var initial: float = sage.get_prevention_time_remaining()

	sage._process(1.0)

	var after: float = sage.get_prevention_time_remaining()
	assert_lt(after, initial, "Timer should decrement")


# --- Network State Tests ---


func test_network_state_includes_prevention() -> void:
	sage.trigger()

	var state := sage.get_network_state()

	assert_has(state, "preventing", "Should include preventing state")
	assert_has(state, "prevention_timer", "Should include prevention timer")


func test_network_state_preventing_true() -> void:
	sage.trigger()

	var state := sage.get_network_state()

	assert_true(state["preventing"], "Preventing should be true")


func test_network_state_preventing_false_initial() -> void:
	var state := sage.get_network_state()

	assert_false(state["preventing"], "Preventing should be false initially")


func test_apply_network_state_restores_prevention() -> void:
	var state := {
		"preventing": true,
		"prevention_timer": 30.0,
	}

	sage.apply_network_state(state)

	assert_true(sage.is_preventing_hunts(), "Should restore prevention state")
	assert_eq(sage.get_prevention_time_remaining(), 30.0, "Should restore timer")


# --- Edge Cases ---


func test_is_preventing_hunts_initially_false() -> void:
	assert_false(sage.is_preventing_hunts(), "Should not prevent hunts initially")


func test_prevention_time_zero_initially() -> void:
	assert_eq(sage.get_prevention_time_remaining(), 0.0, "Timer should be 0 initially")


func test_trigger_does_not_require_placement() -> void:
	# HELD mode should allow trigger without placement
	var result: bool = sage.trigger()

	assert_true(result, "HELD mode should trigger without placement")


func test_multiple_process_cycles() -> void:
	sage.trigger()

	for i in range(10):
		sage._process(0.1)

	var remaining: float = sage.get_prevention_time_remaining()
	assert_almost_eq(remaining, 59.0, 0.1, "Timer should decrement correctly over cycles")
