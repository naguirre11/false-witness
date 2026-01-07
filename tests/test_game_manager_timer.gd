extends GutTest
## Tests for GameManager timer functionality.

const GameManagerScript = preload("res://src/core/managers/game_manager.gd")

var manager: Node


func before_each() -> void:
	manager = GameManagerScript.new()
	add_child_autofree(manager)


func test_timer_starts_on_investigation() -> void:
	manager.force_state(manager.GameState.INVESTIGATION)
	assert_true(manager.is_timer_active(), "Timer should be active in INVESTIGATION")
	assert_gt(manager.get_time_remaining(), 0.0, "Time remaining should be positive")


func test_timer_starts_on_deliberation() -> void:
	manager.force_state(manager.GameState.DELIBERATION)
	assert_true(manager.is_timer_active(), "Timer should be active in DELIBERATION")
	assert_gt(manager.get_time_remaining(), 0.0, "Time remaining should be positive")


func test_timer_not_active_in_lobby() -> void:
	manager.change_state(manager.GameState.LOBBY)
	assert_false(manager.is_timer_active(), "Timer should not be active in LOBBY")


func test_timer_stops_on_state_change() -> void:
	manager.force_state(manager.GameState.INVESTIGATION)
	assert_true(manager.is_timer_active(), "Timer should be active")
	manager.change_state(manager.GameState.HUNT)
	assert_false(manager.is_timer_active(), "Timer should stop when leaving timed state")


func test_timer_default_investigation_duration() -> void:
	manager.force_state(manager.GameState.INVESTIGATION)
	var expected: float = manager.DEFAULT_INVESTIGATION_TIME
	assert_eq(manager.get_time_remaining(), expected, "Should use default investigation time")


func test_timer_default_deliberation_duration() -> void:
	manager.force_state(manager.GameState.DELIBERATION)
	var expected: float = manager.DEFAULT_DELIBERATION_TIME
	assert_eq(manager.get_time_remaining(), expected, "Should use default deliberation time")


func test_configure_phase_durations() -> void:
	manager.configure_phase_durations(800.0, 240.0)
	assert_eq(manager.investigation_duration, 800.0, "Investigation duration should be 800")
	assert_eq(manager.deliberation_duration, 240.0, "Deliberation duration should be 240")


func test_configure_phase_durations_clamps_to_min() -> void:
	manager.configure_phase_durations(100.0, 60.0)  # Below minimums
	assert_eq(
		manager.investigation_duration,
		manager.MIN_INVESTIGATION_TIME,
		"Should clamp to minimum investigation time"
	)
	assert_eq(
		manager.deliberation_duration,
		manager.MIN_DELIBERATION_TIME,
		"Should clamp to minimum deliberation time"
	)


func test_configure_phase_durations_clamps_to_max() -> void:
	manager.configure_phase_durations(9999.0, 9999.0)  # Above maximums
	assert_eq(
		manager.investigation_duration,
		manager.MAX_INVESTIGATION_TIME,
		"Should clamp to maximum investigation time"
	)
	assert_eq(
		manager.deliberation_duration,
		manager.MAX_DELIBERATION_TIME,
		"Should clamp to maximum deliberation time"
	)


func test_pause_timer() -> void:
	manager.force_state(manager.GameState.INVESTIGATION)
	manager.pause_timer()
	assert_true(manager.is_timer_paused(), "Timer should be paused")


func test_resume_timer() -> void:
	manager.force_state(manager.GameState.INVESTIGATION)
	manager.pause_timer()
	manager.resume_timer()
	assert_false(manager.is_timer_paused(), "Timer should be resumed")


func test_extend_timer() -> void:
	manager.force_state(manager.GameState.INVESTIGATION)
	var initial_time: float = manager.get_time_remaining()
	manager.extend_timer(60.0)
	assert_eq(
		manager.get_time_remaining(), initial_time + 60.0, "Timer should be extended by 60 seconds"
	)


func test_set_timer() -> void:
	manager.force_state(manager.GameState.INVESTIGATION)
	manager.set_timer(300.0)
	assert_eq(manager.get_time_remaining(), 300.0, "Timer should be set to 300 seconds")


func test_reset_stops_timer() -> void:
	manager.force_state(manager.GameState.INVESTIGATION)
	assert_true(manager.is_timer_active(), "Timer should be active")
	manager.reset()
	assert_false(manager.is_timer_active(), "Timer should stop after reset")
