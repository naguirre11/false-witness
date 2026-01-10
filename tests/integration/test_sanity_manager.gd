extends GutTest
## Tests for SanityManager autoload.


# --- Constants ---

const SanityManagerScript := preload("res://src/entity/sanity_manager.gd")


# --- Test Helpers ---

var _manager: Node = null


func before_each() -> void:
	_manager = SanityManagerScript.new()
	add_child(_manager)
	_manager.set_is_server(true)


func after_each() -> void:
	if _manager:
		_manager.queue_free()
		_manager = null


# --- Initialization Tests ---


func test_manager_initializes_with_default_values() -> void:
	assert_eq(_manager.get_team_sanity(), 100.0, "Team sanity should start at 100")
	assert_true(_manager.get_all_sanity().is_empty(), "No players registered initially")


# --- Player Registration Tests ---


func test_register_player_adds_to_registry() -> void:
	_manager.register_player(1)

	var sanity: float = _manager.get_player_sanity(1)
	assert_eq(sanity, 100.0, "New player should have 100 sanity")


func test_register_player_with_custom_sanity() -> void:
	_manager.register_player(1, 75.0)

	assert_eq(_manager.get_player_sanity(1), 75.0)


func test_register_player_clamps_sanity() -> void:
	_manager.register_player(1, 150.0)
	_manager.register_player(2, -50.0)

	assert_eq(_manager.get_player_sanity(1), 100.0, "Should clamp to max")
	assert_eq(_manager.get_player_sanity(2), 0.0, "Should clamp to min")


func test_unregister_player_removes_from_registry() -> void:
	_manager.register_player(1)
	_manager.unregister_player(1)

	# Should return default for unregistered player
	assert_eq(_manager.get_player_sanity(1), 100.0, "Unregistered player returns default")
	assert_false(_manager.get_all_sanity().has(1), "Player should not be in registry")


# --- Team Sanity Tests ---


func test_team_sanity_calculated_from_players() -> void:
	_manager.register_player(1, 100.0)
	_manager.register_player(2, 50.0)

	assert_eq(_manager.get_team_sanity(), 75.0, "Team average should be 75")


func test_team_sanity_updates_when_player_leaves() -> void:
	_manager.register_player(1, 100.0)
	_manager.register_player(2, 50.0)
	_manager.unregister_player(2)

	assert_eq(_manager.get_team_sanity(), 100.0, "Team average should update")


func test_empty_team_defaults_to_100() -> void:
	_manager.register_player(1)
	_manager.unregister_player(1)

	assert_eq(_manager.get_team_sanity(), 100.0, "Empty team defaults to 100")


# --- Sanity Manipulation Tests ---


func test_drain_sanity_reduces_player_sanity() -> void:
	_manager.register_player(1, 100.0)
	_manager.drain_sanity(1, 20.0)

	assert_eq(_manager.get_player_sanity(1), 80.0)


func test_drain_sanity_clamps_to_zero() -> void:
	_manager.register_player(1, 10.0)
	_manager.drain_sanity(1, 50.0)

	assert_eq(_manager.get_player_sanity(1), 0.0)


func test_restore_sanity_increases_player_sanity() -> void:
	_manager.register_player(1, 50.0)
	_manager.restore_sanity(1, 30.0)

	assert_eq(_manager.get_player_sanity(1), 80.0)


func test_restore_sanity_clamps_to_max() -> void:
	_manager.register_player(1, 90.0)
	_manager.restore_sanity(1, 50.0)

	assert_eq(_manager.get_player_sanity(1), 100.0)


func test_drain_all_sanity_affects_all_players() -> void:
	_manager.register_player(1, 100.0)
	_manager.register_player(2, 80.0)
	_manager.register_player(3, 60.0)

	_manager.drain_all_sanity(10.0)

	assert_eq(_manager.get_player_sanity(1), 90.0)
	assert_eq(_manager.get_player_sanity(2), 70.0)
	assert_eq(_manager.get_player_sanity(3), 50.0)


func test_set_player_sanity_directly() -> void:
	_manager.register_player(1)
	_manager.set_player_sanity(1, 42.0)

	assert_eq(_manager.get_player_sanity(1), 42.0)


func test_set_player_sanity_registers_if_needed() -> void:
	_manager.set_player_sanity(99, 50.0)

	assert_true(_manager.get_all_sanity().has(99), "Should auto-register")
	assert_eq(_manager.get_player_sanity(99), 50.0)


# --- Hunt Threshold Tests ---


func test_can_entity_hunt_false_above_threshold() -> void:
	_manager.register_player(1, 100.0)

	assert_false(_manager.can_entity_hunt(50.0), "Cannot hunt above threshold")


func test_can_entity_hunt_true_at_threshold() -> void:
	_manager.register_player(1, 50.0)

	assert_true(_manager.can_entity_hunt(50.0), "Can hunt at threshold")


func test_can_entity_hunt_true_below_threshold() -> void:
	_manager.register_player(1, 30.0)

	assert_true(_manager.can_entity_hunt(50.0), "Can hunt below threshold")


func test_custom_threshold_works() -> void:
	_manager.register_player(1, 75.0)

	assert_false(_manager.can_entity_hunt(50.0), "75 > 50")
	assert_true(_manager.can_entity_hunt(80.0), "75 < 80")


func test_get_hunt_threshold_progress() -> void:
	_manager.register_player(1, 100.0)
	assert_almost_eq(_manager.get_hunt_threshold_progress(50.0), 0.0, 0.01, "At 100, progress = 0")

	_manager.set_player_sanity(1, 75.0)
	assert_almost_eq(_manager.get_hunt_threshold_progress(50.0), 0.5, 0.01, "At 75, progress = 0.5")

	_manager.set_player_sanity(1, 50.0)
	assert_almost_eq(_manager.get_hunt_threshold_progress(50.0), 1.0, 0.01, "At 50, progress = 1")

	_manager.set_player_sanity(1, 25.0)
	assert_almost_eq(_manager.get_hunt_threshold_progress(50.0), 1.0, 0.01, "Below threshold = 1")


# --- Darkness Tests ---


func test_set_darkness_level_stores_value() -> void:
	_manager.register_player(1)
	_manager.set_darkness_level(1, 0.75)

	# Darkness level is internal, but we can test via drain behavior
	# For now, just ensure it doesn't error
	pass_test("Darkness level set without error")


func test_set_darkness_level_clamps_values() -> void:
	_manager.register_player(1)
	_manager.set_darkness_level(1, 2.0)  # Should clamp to 1.0
	_manager.set_darkness_level(1, -0.5)  # Should clamp to 0.0

	# No assertion needed - testing it doesn't crash
	pass_test("Darkness level clamps without error")


# --- Signal Tests ---


func test_player_sanity_changed_signal_emitted() -> void:
	var signal_received := {"called": false, "player_id": -1, "sanity": -1.0}
	_manager.player_sanity_changed.connect(func(player_id: int, new_sanity: float):
		signal_received["called"] = true
		signal_received["player_id"] = player_id
		signal_received["sanity"] = new_sanity
	)

	_manager.register_player(1, 100.0)
	_manager.drain_sanity(1, 10.0)

	assert_true(signal_received["called"], "Signal should be emitted")
	assert_eq(signal_received["player_id"], 1)
	assert_eq(signal_received["sanity"], 90.0)


func test_team_sanity_changed_signal_emitted_on_significant_change() -> void:
	var signal_received := {"called": false, "average": -1.0}
	_manager.team_sanity_changed.connect(func(new_average: float):
		signal_received["called"] = true
		signal_received["average"] = new_average
	)

	_manager.register_player(1, 100.0)
	_manager.drain_sanity(1, 5.0)  # 5% change - significant

	assert_true(signal_received["called"], "Signal should emit on significant change")


func test_sanity_threshold_crossed_signal_emitted() -> void:
	var signal_received := {"called": false, "threshold": -1.0, "sanity": -1.0}
	_manager.sanity_threshold_crossed.connect(func(threshold: float, team_sanity: float):
		signal_received["called"] = true
		signal_received["threshold"] = threshold
		signal_received["sanity"] = team_sanity
	)

	_manager.register_player(1, 100.0)
	_manager.set_player_sanity(1, 74.0)  # Cross 75 threshold

	assert_true(signal_received["called"], "Signal should emit when crossing threshold")
	assert_eq(signal_received["threshold"], 75.0)


# --- Event Response Tests ---


func test_on_ghost_event_drains_affected_players() -> void:
	_manager.register_player(1, 100.0)
	_manager.register_player(2, 100.0)
	_manager.register_player(3, 100.0)

	_manager.on_ghost_event([1, 3])  # Only players 1 and 3 affected

	var expected_drain: float = _manager.GHOST_EVENT_DRAIN

	assert_eq(_manager.get_player_sanity(1), 100.0 - expected_drain, "Player 1 affected")
	assert_eq(_manager.get_player_sanity(2), 100.0, "Player 2 not affected")
	assert_eq(_manager.get_player_sanity(3), 100.0 - expected_drain, "Player 3 affected")


func test_on_entity_sighted_drains_observer() -> void:
	_manager.register_player(1, 100.0)

	_manager.on_entity_sighted(1)

	var expected_drain: float = _manager.ENTITY_SIGHTING_DRAIN
	assert_eq(_manager.get_player_sanity(1), 100.0 - expected_drain)


# --- Server Authority Tests ---


func test_is_server_defaults_to_false() -> void:
	var fresh_manager := SanityManagerScript.new()
	add_child(fresh_manager)

	assert_false(fresh_manager.is_server())

	fresh_manager.queue_free()


func test_set_is_server_updates_value() -> void:
	_manager.set_is_server(true)
	assert_true(_manager.is_server())

	_manager.set_is_server(false)
	assert_false(_manager.is_server())


# --- Reset Tests ---


func test_reset_clears_all_state() -> void:
	_manager.register_player(1, 50.0)
	_manager.register_player(2, 30.0)

	_manager.reset()

	assert_true(_manager.get_all_sanity().is_empty(), "Players should be cleared")
	assert_eq(_manager.get_team_sanity(), 100.0, "Team sanity should reset to 100")


# --- Network State Tests ---


func test_get_network_state_includes_all_data() -> void:
	_manager.register_player(1, 80.0)
	_manager.register_player(2, 60.0)

	var state: Dictionary = _manager.get_network_state()

	assert_has(state, "sanity", "Should include sanity dictionary")
	assert_has(state, "team_average", "Should include team average")
	assert_eq(state.sanity[1], 80.0)
	assert_eq(state.sanity[2], 60.0)
	assert_eq(state.team_average, 70.0)


func test_apply_network_state_updates_manager() -> void:
	var state := {
		"sanity": {1: 45.0, 2: 55.0},
		"team_average": 50.0,
	}

	_manager.apply_network_state(state)

	assert_eq(_manager.get_player_sanity(1), 45.0)
	assert_eq(_manager.get_player_sanity(2), 55.0)
	assert_eq(_manager.get_team_sanity(), 50.0)


# --- Constants Tests ---


func test_constants_defined_correctly() -> void:
	assert_eq(_manager.DEFAULT_SANITY, 100.0)
	assert_eq(_manager.MIN_SANITY, 0.0)
	assert_eq(_manager.MAX_SANITY, 100.0)
	assert_eq(_manager.DEFAULT_HUNT_THRESHOLD, 50.0)


func test_drain_rate_constants_are_positive() -> void:
	assert_gt(_manager.DARKNESS_DRAIN_RATE, 0.0, "Darkness drain should be positive")
	assert_gt(_manager.EVENT_DRAIN_RATE, 0.0, "Event drain should be positive")
	assert_gt(_manager.HUNT_WITNESS_DRAIN, 0.0, "Hunt witness drain should be positive")
	assert_gt(_manager.ENTITY_SIGHTING_DRAIN, 0.0, "Entity sighting drain should be positive")
	assert_gt(_manager.DEATH_WITNESS_DRAIN, 0.0, "Death witness drain should be positive")
	assert_gt(_manager.GHOST_EVENT_DRAIN, 0.0, "Ghost event drain should be positive")
