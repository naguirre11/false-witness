extends GutTest
## Tests for Phantom entity type.

var _phantom: Phantom = null


## Mock player class for testing Phantom behaviors.
class MockPlayer:
	extends CharacterBody3D

	var is_alive: bool = true
	var is_echo: bool = false
	var peer_id: int = 1
	var _using_camera: bool = false
	var _camera_aiming: bool = false

	func is_using_camera() -> bool:
		return _using_camera

	func set_using_camera(value: bool) -> void:
		_using_camera = value

	func set_camera_aiming(value: bool) -> void:
		_camera_aiming = value


## Mock SanityManager for testing sanity drain.
class MockSanityManager:
	extends Node

	var _drain_calls: Array = []
	var _player_sanity: Dictionary = {}

	func drain_sanity(player_id: int, amount: float) -> void:
		_drain_calls.append({"player_id": player_id, "amount": amount})

	func get_drain_calls() -> Array:
		return _drain_calls

	func clear_drain_calls() -> void:
		_drain_calls.clear()

	func get_total_drain_for_player(player_id: int) -> float:
		var total := 0.0
		for call in _drain_calls:
			if call["player_id"] == player_id:
				total += call["amount"]
		return total


func before_each() -> void:
	_phantom = Phantom.new()
	add_child(_phantom)


func after_each() -> void:
	if _phantom:
		_phantom.queue_free()
		_phantom = null


# --- Identity Tests ---


func test_phantom_entity_type() -> void:
	assert_eq(_phantom.get_entity_type(), "Phantom")


func test_phantom_behavioral_tell_type() -> void:
	assert_eq(_phantom.get_behavioral_tell_type(), "photograph_disappearance")


# --- Evidence Type Tests ---


func test_phantom_has_emf_signature() -> void:
	assert_true(_phantom.has_evidence_type(EvidenceEnums.EvidenceType.EMF_SIGNATURE))


func test_phantom_has_prism_reading() -> void:
	assert_true(_phantom.has_evidence_type(EvidenceEnums.EvidenceType.PRISM_READING))


func test_phantom_has_visual_manifestation() -> void:
	assert_true(_phantom.has_evidence_type(EvidenceEnums.EvidenceType.VISUAL_MANIFESTATION))


func test_phantom_does_not_have_other_evidence_types() -> void:
	assert_false(_phantom.has_evidence_type(EvidenceEnums.EvidenceType.FREEZING_TEMPERATURE))
	assert_false(_phantom.has_evidence_type(EvidenceEnums.EvidenceType.AURA_PATTERN))
	assert_false(_phantom.has_evidence_type(EvidenceEnums.EvidenceType.GHOST_WRITING))
	assert_false(_phantom.has_evidence_type(EvidenceEnums.EvidenceType.PHYSICAL_INTERACTION))
	assert_false(_phantom.has_evidence_type(EvidenceEnums.EvidenceType.HUNT_BEHAVIOR))


func test_phantom_get_evidence_types_returns_correct_array() -> void:
	var types := _phantom.get_evidence_types()

	assert_eq(types.size(), 3, "Should have exactly 3 evidence types")
	assert_true(EvidenceEnums.EvidenceType.EMF_SIGNATURE in types)
	assert_true(EvidenceEnums.EvidenceType.PRISM_READING in types)
	assert_true(EvidenceEnums.EvidenceType.VISUAL_MANIFESTATION in types)


# --- Hunt Settings Tests ---


func test_phantom_uses_default_hunt_threshold() -> void:
	assert_eq(_phantom.get_hunt_sanity_threshold(), 50.0)


func test_phantom_does_not_ignore_team_sanity() -> void:
	assert_false(_phantom.should_ignore_team_sanity())


func test_phantom_cannot_voice_trigger_hunt() -> void:
	assert_false(_phantom.can_voice_trigger_hunt())


func test_phantom_can_hunt_in_any_conditions() -> void:
	assert_true(_phantom.can_hunt_in_current_conditions())


func test_phantom_default_hunt_duration() -> void:
	assert_eq(_phantom.get_hunt_duration(), 30.0)


func test_phantom_default_hunt_cooldown() -> void:
	# Base cooldown is 25s * multiplier (1.0)
	assert_eq(_phantom.get_hunt_cooldown(), 25.0)


# --- Movement Speed Tests ---


func test_phantom_default_base_speed() -> void:
	assert_eq(_phantom.base_speed, 1.5)


func test_phantom_hunt_aware_speed() -> void:
	assert_eq(_phantom.hunt_aware_speed, 2.5)


func test_phantom_hunt_unaware_speed() -> void:
	assert_eq(_phantom.hunt_unaware_speed, 1.0)


# --- Manifestation State Tests ---


func test_phantom_manifestation_starts_correctly() -> void:
	_phantom.change_state(Entity.EntityState.ACTIVE)
	var result := _phantom.start_manifestation()

	assert_true(result, "Should be able to start manifestation")
	assert_eq(_phantom.get_state(), Entity.EntityState.MANIFESTING)


func test_phantom_not_visible_initially() -> void:
	assert_false(_phantom.is_visible_to_players())


func test_phantom_visible_during_manifestation() -> void:
	_phantom.change_state(Entity.EntityState.ACTIVE)
	_phantom.start_manifestation()

	assert_true(_phantom.is_visible_to_players())


# --- Behavioral Tell Tests ---


func test_behavioral_tell_not_triggered_when_not_manifesting() -> void:
	# When dormant, tell should not trigger
	var result := _phantom._check_behavioral_tell()
	assert_false(result)


func test_behavioral_tell_not_triggered_when_hunting() -> void:
	_phantom.on_hunt_started()
	var result := _phantom._check_behavioral_tell()
	assert_false(result)


# --- Sanity Drain Constants Tests ---


func test_phantom_sanity_drain_multiplier() -> void:
	assert_eq(Phantom.SANITY_DRAIN_MULTIPLIER, 2.0, "Should drain 2x faster")


func test_phantom_look_drain_per_second() -> void:
	assert_eq(Phantom.LOOK_DRAIN_PER_SECOND, 2.0)


func test_phantom_visibility_check_interval() -> void:
	assert_eq(Phantom.VISIBILITY_CHECK_INTERVAL, 0.2)


# --- Network State Tests ---


func test_network_state_includes_base_data() -> void:
	var state := _phantom.get_network_state()

	assert_true(state.has("state"))
	assert_true(state.has("position"))
	assert_true(state.has("rotation_y"))
	assert_true(state.has("is_visible"))


func test_network_state_includes_phantom_specific_data() -> void:
	var state := _phantom.get_network_state()

	assert_true(state.has("players_looking_count"))
	assert_eq(state["players_looking_count"], 0, "Initially no one looking")


# --- State Transition Tests ---


func test_phantom_starts_dormant() -> void:
	assert_eq(_phantom.get_state(), Entity.EntityState.DORMANT)


func test_phantom_can_transition_to_active() -> void:
	_phantom.change_state(Entity.EntityState.ACTIVE)
	assert_eq(_phantom.get_state(), Entity.EntityState.ACTIVE)


func test_phantom_can_hunt() -> void:
	_phantom.on_hunt_started()

	assert_eq(_phantom.get_state(), Entity.EntityState.HUNTING)
	assert_true(_phantom.is_hunting())


func test_phantom_hunt_ends_correctly() -> void:
	_phantom.on_hunt_started()
	_phantom.on_hunt_ended()

	assert_eq(_phantom.get_state(), Entity.EntityState.ACTIVE)
	assert_false(_phantom.is_hunting())
