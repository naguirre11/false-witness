extends GutTest
## Unit tests for Listener entity mechanics.
##
## Tests dormant/active phase cycling, voice detection threshold,
## voice-triggered hunt initiation, and hunt cooldown behavior.


# --- Test Fixtures ---


var listener: Listener = null


func before_each() -> void:
	listener = Listener.new()
	add_child_autofree(listener)
	# Allow _ready to complete
	await get_tree().process_frame


func after_each() -> void:
	listener = null


# --- Phase Cycling Tests ---


func test_listener_starts_dormant() -> void:
	assert_true(listener.is_in_dormant_phase(), "Listener should start in dormant phase")


func test_listener_has_correct_entity_type() -> void:
	assert_eq(listener.get_entity_type(), "Listener")


func test_listener_has_correct_behavioral_tell_type() -> void:
	assert_eq(listener.get_behavioral_tell_type(), "voice_reactive")


func test_listener_can_voice_trigger_hunt() -> void:
	assert_true(listener.can_voice_trigger_hunt())


func test_dormant_duration_is_in_range() -> void:
	# Phase timer set in _enter_dormant_phase()
	var time_remaining := listener.get_phase_time_remaining()
	assert_gte(time_remaining, Listener.MIN_DORMANT_DURATION)
	assert_lte(time_remaining, Listener.MAX_DORMANT_DURATION)


func test_dormant_state_is_correct_entity_state() -> void:
	# Listener should be in DORMANT EntityState
	var state := listener.get_state()
	assert_eq(state, Entity.EntityState.DORMANT)


# --- Voice Detection Threshold Tests ---


func test_voice_sensitivity_default() -> void:
	assert_eq(listener.voice_sensitivity, 0.3)


func test_voice_sensitivity_configurable() -> void:
	listener.voice_sensitivity = 0.5
	assert_eq(listener.voice_sensitivity, 0.5)


func test_voice_detection_range_constant() -> void:
	assert_eq(Listener.VOICE_DETECTION_RANGE, 20.0)


func test_voice_trigger_threshold_constant() -> void:
	assert_eq(Listener.VOICE_TRIGGER_THRESHOLD, 0.3)


# --- Voice-Triggered Hunt Tests ---


func test_voice_hunt_cooldown_starts_at_zero() -> void:
	assert_eq(listener.get_voice_cooldown_remaining(), 0.0)


func test_voice_hunt_cooldown_constant() -> void:
	assert_eq(Listener.VOICE_HUNT_COOLDOWN, 60.0)


func test_voice_reaction_pause_constant() -> void:
	assert_eq(Listener.VOICE_REACTION_PAUSE, 2.0)


func test_voice_turn_speed_constant() -> void:
	assert_eq(Listener.VOICE_TURN_SPEED, 3.0)


func test_is_not_reacting_to_voice_initially() -> void:
	assert_false(listener.is_reacting_to_voice())


# --- Hunt Cooldown Tests ---


func test_hunt_cooldown_decrements_in_dormant() -> void:
	# Manually set cooldown
	listener._voice_hunt_cooldown = 10.0

	# Simulate time passing
	listener._process_dormant_behavior(5.0)

	assert_eq(listener.get_voice_cooldown_remaining(), 5.0)


func test_hunt_cooldown_decrements_in_active() -> void:
	# Switch to active state
	listener.change_state(Entity.EntityState.ACTIVE)
	listener._voice_hunt_cooldown = 10.0

	# Simulate time passing
	listener._process_active_behavior(3.0)

	assert_eq(listener.get_voice_cooldown_remaining(), 7.0)


func test_hunt_cooldown_decrements_in_hunting() -> void:
	listener.change_state(Entity.EntityState.HUNTING)
	listener._voice_hunt_cooldown = 10.0

	listener._process_hunting_behavior(4.0)

	assert_eq(listener.get_voice_cooldown_remaining(), 6.0)


func test_hunt_cooldown_reaches_zero_or_below() -> void:
	listener._voice_hunt_cooldown = 2.0
	listener._process_dormant_behavior(5.0)

	# Cooldown can go negative internally (no clamping in process)
	# What matters is get_voice_cooldown_remaining() which just returns the value
	assert_lte(listener.get_voice_cooldown_remaining(), 0.0)


# --- Evidence Type Tests ---


func test_listener_evidence_types() -> void:
	var evidence_types := listener.get_evidence_types()

	assert_eq(evidence_types.size(), 3)
	assert_has(evidence_types, EvidenceEnums.EvidenceType.FREEZING_TEMPERATURE)
	assert_has(evidence_types, EvidenceEnums.EvidenceType.GHOST_WRITING)
	assert_has(evidence_types, EvidenceEnums.EvidenceType.AURA_PATTERN)


# --- Speed Configuration Tests ---


func test_listener_base_speed() -> void:
	assert_eq(listener.base_speed, 1.2)


func test_listener_hunt_speed() -> void:
	assert_eq(listener.hunt_speed, 2.2)


func test_listener_hunt_aware_speed() -> void:
	assert_eq(listener.hunt_aware_speed, 2.4)


func test_listener_hunt_unaware_speed() -> void:
	assert_eq(listener.hunt_unaware_speed, 1.5)


# --- Phase Transition Tests ---


func test_phase_timer_decrements_in_dormant() -> void:
	var initial_time := listener.get_phase_time_remaining()
	listener._process_dormant_behavior(5.0)
	var new_time := listener.get_phase_time_remaining()

	assert_eq(new_time, initial_time - 5.0)


func test_dormant_to_active_transition_when_timer_expires() -> void:
	# Set a very short phase timer
	listener._phase_timer = 0.1

	# Process enough time to expire
	listener._process_dormant_behavior(0.2)

	# Should now be in active state (is_dormant = false)
	assert_false(listener.is_in_dormant_phase())


func test_active_to_dormant_transition_when_timer_expires() -> void:
	# Enter active state first
	listener.change_state(Entity.EntityState.ACTIVE)
	listener._phase_timer = 0.1

	# Process enough time to expire
	listener._process_active_behavior(0.2)

	# Should now be back in dormant state
	assert_true(listener.is_in_dormant_phase())


# --- Network State Tests ---


func test_network_state_includes_is_dormant() -> void:
	var state := listener.get_network_state()
	assert_has(state, "is_dormant")
	assert_true(state.is_dormant)


func test_network_state_includes_phase_timer() -> void:
	var state := listener.get_network_state()
	assert_has(state, "phase_timer")


func test_network_state_includes_voice_cooldown() -> void:
	listener._voice_hunt_cooldown = 30.0
	var state := listener.get_network_state()

	assert_has(state, "voice_cooldown")
	assert_eq(state.voice_cooldown, 30.0)


func test_apply_network_state_updates_dormant() -> void:
	var state := {"is_dormant": false}
	listener.apply_network_state(state)

	assert_false(listener.is_in_dormant_phase())


func test_apply_network_state_updates_phase_timer() -> void:
	var state := {"phase_timer": 45.0}
	listener.apply_network_state(state)

	assert_eq(listener.get_phase_time_remaining(), 45.0)


func test_apply_network_state_updates_voice_cooldown() -> void:
	var state := {"voice_cooldown": 25.0}
	listener.apply_network_state(state)

	assert_eq(listener.get_voice_cooldown_remaining(), 25.0)


# --- Duration Constants Tests ---


func test_min_dormant_duration() -> void:
	assert_eq(Listener.MIN_DORMANT_DURATION, 30.0)


func test_max_dormant_duration() -> void:
	assert_eq(Listener.MAX_DORMANT_DURATION, 60.0)


func test_min_active_duration() -> void:
	assert_eq(Listener.MIN_ACTIVE_DURATION, 60.0)


func test_max_active_duration() -> void:
	assert_eq(Listener.MAX_ACTIVE_DURATION, 120.0)


# --- Export Properties Tests ---


func test_roam_interval_default() -> void:
	assert_eq(listener.roam_interval, 15.0)


func test_interaction_interval_default() -> void:
	assert_eq(listener.interaction_interval, 30.0)


func test_manifestation_interval_default() -> void:
	assert_eq(listener.manifestation_interval, 45.0)


func test_temperature_interval_default() -> void:
	assert_eq(listener.temperature_interval, 10.0)


func test_ghost_writing_chance_default() -> void:
	assert_eq(listener.ghost_writing_chance, 0.7)


func test_ghost_writing_range_default() -> void:
	assert_eq(listener.ghost_writing_range, 5.0)


func test_dormant_sound_volume_default() -> void:
	assert_eq(listener.dormant_sound_volume, 0.3)
