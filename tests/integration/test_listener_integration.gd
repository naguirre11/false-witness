extends GutTest
## Integration tests for Listener entity in game context.
##
## Tests voice activity triggering hunts, dormant audio cue setup,
## behavioral tell observability, and evidence generation.


# --- Test Fixtures ---


var listener: Listener = null


func before_each() -> void:
	listener = Listener.new()
	add_child_autofree(listener)
	await get_tree().process_frame


func after_each() -> void:
	listener = null


# --- Voice Hunt Trigger Tests ---


func test_voice_hunt_triggers_set_cooldown() -> void:
	# Verify initial state
	assert_true(listener.is_in_dormant_phase())
	assert_eq(listener.get_voice_cooldown_remaining(), 0.0)

	# Directly call the trigger method
	var player_id := 1001
	var player_pos := listener.global_position + Vector3(5, 0, 5)
	listener._trigger_voice_hunt(player_id, player_pos)

	# Cooldown should be set
	assert_eq(listener.get_voice_cooldown_remaining(), Listener.VOICE_HUNT_COOLDOWN)


func test_voice_hunt_exits_dormant_phase() -> void:
	assert_true(listener.is_in_dormant_phase())

	var player_id := 1001
	var player_pos := listener.global_position + Vector3(5, 0, 5)
	listener._trigger_voice_hunt(player_id, player_pos)

	# Should exit dormant phase
	assert_false(listener.is_dormant)


func test_voice_hunt_records_target_position() -> void:
	var player_pos := Vector3(10, 0, 15)
	listener._trigger_voice_hunt(1001, player_pos)

	# Target position should be recorded
	assert_eq(listener._target_last_position, player_pos)


func test_voice_hunt_emits_signal() -> void:
	var signal_data := {"received": false, "speaker_id": -1}

	listener.voice_hunt_triggered.connect(
		func(speaker_id: int):
			signal_data.received = true
			signal_data.speaker_id = speaker_id
	)

	listener._trigger_voice_hunt(1001, Vector3.ZERO)

	assert_true(signal_data.received)
	assert_eq(signal_data.speaker_id, 1001)


# --- Behavioral Tell Tests ---


func test_voice_reaction_starts_correctly() -> void:
	listener.change_state(Entity.EntityState.ACTIVE)
	assert_false(listener.is_reacting_to_voice())

	var player_pos := Vector3(5, 0, 5)
	listener._start_voice_reaction(1001, player_pos)

	assert_true(listener.is_reacting_to_voice())
	assert_eq(listener._voice_source_position, player_pos)


func test_voice_reaction_triggers_behavioral_tell() -> void:
	var tell_data := {"triggered": false, "type": ""}

	listener.behavioral_tell_triggered.connect(
		func(tell_type: String):
			tell_data.triggered = true
			tell_data.type = tell_type
	)

	listener.change_state(Entity.EntityState.ACTIVE)
	listener._start_voice_reaction(1001, Vector3(5, 0, 5))

	assert_true(tell_data.triggered)
	assert_eq(tell_data.type, "voice_reactive")


func test_voice_reaction_timer_decrements() -> void:
	listener._is_voice_reacting = true
	listener._voice_reaction_timer = 2.0

	listener._process_voice_reaction(0.5)

	assert_almost_eq(listener._voice_reaction_timer, 1.5, 0.01)


func test_voice_reaction_ends_when_timer_expires() -> void:
	listener._is_voice_reacting = true
	listener._voice_reaction_timer = 0.1

	listener._process_voice_reaction(0.2)

	assert_false(listener.is_reacting_to_voice())


# --- Evidence Generation Tests ---


func test_listener_has_three_evidence_types() -> void:
	var evidence := listener.get_evidence_types()
	assert_eq(evidence.size(), 3)


func test_listener_produces_freezing_temperature() -> void:
	var evidence := listener.get_evidence_types()
	assert_has(evidence, EvidenceEnums.EvidenceType.FREEZING_TEMPERATURE)


func test_listener_produces_ghost_writing() -> void:
	var evidence := listener.get_evidence_types()
	assert_has(evidence, EvidenceEnums.EvidenceType.GHOST_WRITING)


func test_listener_produces_aura_pattern() -> void:
	var evidence := listener.get_evidence_types()
	assert_has(evidence, EvidenceEnums.EvidenceType.AURA_PATTERN)


# --- Phase Cycling Integration ---


func test_dormant_to_active_transition() -> void:
	assert_true(listener.is_in_dormant_phase())

	# Fast-forward phase timer
	listener._phase_timer = 0.1
	listener._process_dormant_behavior(0.2)

	# Should transition to active
	assert_false(listener.is_in_dormant_phase())


func test_active_to_dormant_transition() -> void:
	listener.change_state(Entity.EntityState.ACTIVE)
	assert_false(listener.is_in_dormant_phase())

	# Fast-forward phase timer
	listener._phase_timer = 0.1
	listener._process_active_behavior(0.2)

	# Should transition back to dormant
	assert_true(listener.is_in_dormant_phase())


func test_hunt_state_clears_dormant() -> void:
	assert_true(listener.is_in_dormant_phase())

	listener.change_state(Entity.EntityState.HUNTING)

	# Hunting should have exited dormant
	assert_false(listener.is_in_dormant_phase())


# --- Entity Manager Integration ---


func test_listener_entity_type_constant() -> void:
	assert_eq(listener.get_entity_type(), "Listener")


func test_state_change_signal_emits() -> void:
	var changes := {"count": 0}

	listener.state_changed.connect(
		func(_old: Entity.EntityState, _new: Entity.EntityState):
			changes.count += 1
	)

	listener.change_state(Entity.EntityState.ACTIVE)
	assert_eq(changes.count, 1)


# --- Hunt Target Selection ---


func test_select_hunt_target_returns_null_for_empty_array() -> void:
	var target: Node = listener._select_hunt_target([])
	assert_null(target)


func test_select_hunt_target_prioritizes_speaker() -> void:
	var player1 := Node3D.new()
	player1.global_position = Vector3(10, 0, 0)
	add_child_autofree(player1)

	var player2 := Node3D.new()
	player2.global_position = Vector3(5, 0, 0)
	add_child_autofree(player2)

	# Set player1 as speaker even though player2 is closer
	listener._last_speaker_id = player1.get_instance_id()

	var players := [player1, player2]
	var target: Node = listener._select_hunt_target(players)

	# Should pick speaker (player1) not nearest
	assert_eq(target, player1)


func test_select_hunt_target_picks_nearest_when_no_speaker() -> void:
	listener.global_position = Vector3.ZERO

	var player1 := Node3D.new()
	player1.global_position = Vector3(10, 0, 0)  # Far
	add_child_autofree(player1)

	var player2 := Node3D.new()
	player2.global_position = Vector3(3, 0, 0)  # Close
	add_child_autofree(player2)

	listener._last_speaker_id = -1  # No speaker

	var players := [player1, player2]
	var target: Node = listener._select_hunt_target(players)

	assert_eq(target, player2)


# --- Network State ---


func test_network_state_includes_all_fields() -> void:
	var state := listener.get_network_state()

	assert_has(state, "is_dormant")
	assert_has(state, "phase_timer")
	assert_has(state, "voice_cooldown")


func test_apply_network_state_sets_dormant() -> void:
	var state := {"is_dormant": false}
	listener.apply_network_state(state)

	assert_false(listener.is_dormant)


func test_apply_network_state_sets_phase_timer() -> void:
	var state := {"phase_timer": 42.5}
	listener.apply_network_state(state)

	assert_eq(listener._phase_timer, 42.5)


func test_apply_network_state_sets_voice_cooldown() -> void:
	var state := {"voice_cooldown": 30.0}
	listener.apply_network_state(state)

	assert_eq(listener._voice_hunt_cooldown, 30.0)


# --- Voice Hunt During Hunt ---


func test_voice_target_update_during_hunt_sets_position() -> void:
	listener.change_state(Entity.EntityState.HUNTING)
	listener._hunt_target = null

	var speaker_pos := Vector3(15, 0, 20)
	listener._update_voice_target_during_hunt(2002, speaker_pos)

	assert_eq(listener._target_last_position, speaker_pos)
	assert_eq(listener._last_speaker_id, 2002)


func test_voice_target_update_during_hunt_sets_awareness() -> void:
	listener.change_state(Entity.EntityState.HUNTING)
	listener._hunt_target = null
	listener._is_aware_of_target = false

	listener._update_voice_target_during_hunt(2002, Vector3(15, 0, 20))

	assert_true(listener._is_aware_of_target)
