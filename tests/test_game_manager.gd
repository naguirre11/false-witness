extends GutTest
## Tests for GameManager autoload - game state machine functionality.

const GameManagerScript = preload("res://src/core/managers/game_manager.gd")

var manager: Node


func before_each() -> void:
	manager = GameManagerScript.new()
	add_child_autofree(manager)


func test_initial_state_is_none() -> void:
	assert_eq(manager.current_state, manager.GameState.NONE, "Initial state should be NONE")


func test_change_state_from_none_to_lobby() -> void:
	var result: bool = manager.change_state(manager.GameState.LOBBY)
	assert_true(result, "Transition NONE -> LOBBY should succeed")
	assert_eq(manager.current_state, manager.GameState.LOBBY, "State should be LOBBY")


func test_change_state_tracks_previous() -> void:
	manager.change_state(manager.GameState.LOBBY)
	manager.change_state(manager.GameState.SETUP)
	assert_eq(
		manager.get_previous_state(), manager.GameState.LOBBY, "Previous state should be LOBBY"
	)


func test_invalid_transition_returns_false() -> void:
	# Cannot go directly from NONE to INVESTIGATION
	var result: bool = manager.change_state(manager.GameState.INVESTIGATION)
	assert_false(result, "Invalid transition should return false")
	assert_eq(manager.current_state, manager.GameState.NONE, "State should remain NONE")


func test_same_state_transition_returns_false() -> void:
	var result: bool = manager.change_state(manager.GameState.NONE)
	assert_false(result, "Transition to same state should return false")


func test_force_state_bypasses_validation() -> void:
	manager.force_state(manager.GameState.HUNT)
	assert_eq(manager.current_state, manager.GameState.HUNT, "Force state should set HUNT directly")


func test_reset_returns_to_none() -> void:
	manager.change_state(manager.GameState.LOBBY)
	manager.reset()
	assert_eq(manager.current_state, manager.GameState.NONE, "Reset should return to NONE")


func test_is_in_match_during_investigation() -> void:
	manager.force_state(manager.GameState.INVESTIGATION)
	assert_true(manager.is_in_match(), "INVESTIGATION should be considered in match")


func test_is_in_match_false_in_lobby() -> void:
	manager.change_state(manager.GameState.LOBBY)
	assert_false(manager.is_in_match(), "LOBBY should not be considered in match")


func test_can_players_move_during_investigation() -> void:
	manager.force_state(manager.GameState.INVESTIGATION)
	assert_true(manager.can_players_move(), "Players should be able to move in INVESTIGATION")


func test_can_players_move_during_hunt() -> void:
	manager.force_state(manager.GameState.HUNT)
	assert_true(manager.can_players_move(), "Players should be able to move in HUNT")


func test_can_players_move_false_in_deliberation() -> void:
	manager.force_state(manager.GameState.DELIBERATION)
	assert_false(manager.can_players_move(), "Players should not move in DELIBERATION")


func test_valid_game_flow_sequence() -> void:
	# Test a valid game flow: NONE -> LOBBY -> SETUP -> INVESTIGATION -> HUNT -> RESULTS
	assert_true(manager.change_state(manager.GameState.LOBBY), "NONE -> LOBBY")
	assert_true(manager.change_state(manager.GameState.SETUP), "LOBBY -> SETUP")
	assert_true(manager.change_state(manager.GameState.INVESTIGATION), "SETUP -> INVESTIGATION")
	assert_true(manager.change_state(manager.GameState.HUNT), "INVESTIGATION -> HUNT")
	assert_true(manager.change_state(manager.GameState.RESULTS), "HUNT -> RESULTS")
	assert_eq(manager.current_state, manager.GameState.RESULTS, "Should be in RESULTS")


func test_hunt_can_return_to_investigation() -> void:
	manager.force_state(manager.GameState.HUNT)
	var result: bool = manager.change_state(manager.GameState.INVESTIGATION)
	assert_true(result, "HUNT -> INVESTIGATION should be valid (hunt ended)")


func test_investigation_can_go_to_deliberation() -> void:
	manager.force_state(manager.GameState.INVESTIGATION)
	var result: bool = manager.change_state(manager.GameState.DELIBERATION)
	assert_true(result, "INVESTIGATION -> DELIBERATION should be valid")
