extends GutTest
## Tests for EventBus autoload - global signal hub functionality.

const EventBusScript = preload("res://src/core/managers/event_bus.gd")

var bus: Node


func before_each() -> void:
	bus = EventBusScript.new()
	add_child_autofree(bus)


func test_game_state_changed_signal_exists() -> void:
	assert_true(bus.has_signal("game_state_changed"), "Should have game_state_changed signal")


func test_player_joined_signal_exists() -> void:
	assert_true(bus.has_signal("player_joined"), "Should have player_joined signal")


func test_player_left_signal_exists() -> void:
	assert_true(bus.has_signal("player_left"), "Should have player_left signal")


func test_evidence_detected_signal_exists() -> void:
	assert_true(bus.has_signal("evidence_detected"), "Should have evidence_detected signal")


func test_hunt_started_signal_exists() -> void:
	assert_true(bus.has_signal("hunt_started"), "Should have hunt_started signal")


func test_hunt_ended_signal_exists() -> void:
	assert_true(bus.has_signal("hunt_ended"), "Should have hunt_ended signal")


func test_game_state_changed_emission() -> void:
	var state := {"received": false, "old": -1, "new": -1}

	bus.game_state_changed.connect(
		func(old_state: int, new_state: int):
			state["received"] = true
			state["old"] = old_state
			state["new"] = new_state
	)

	bus.game_state_changed.emit(0, 1)

	assert_true(state["received"], "Signal should be received")
	assert_eq(state["old"], 0, "Old state should be 0")
	assert_eq(state["new"], 1, "New state should be 1")


func test_player_joined_emission() -> void:
	var state := {"received": false, "player_id": -1}

	bus.player_joined.connect(
		func(player_id: int):
			state["received"] = true
			state["player_id"] = player_id
	)

	bus.player_joined.emit(12345)

	assert_true(state["received"], "Signal should be received")
	assert_eq(state["player_id"], 12345, "Player ID should match")


func test_player_left_emission() -> void:
	var state := {"received": false, "player_id": -1}

	bus.player_left.connect(
		func(player_id: int):
			state["received"] = true
			state["player_id"] = player_id
	)

	bus.player_left.emit(67890)

	assert_true(state["received"], "Signal should be received")
	assert_eq(state["player_id"], 67890, "Player ID should match")


func test_evidence_detected_emission() -> void:
	var state := {"received": false, "type": "", "loc": Vector3.ZERO, "strength": 0.0}

	bus.evidence_detected.connect(
		func(ev_type: String, loc: Vector3, strength: float):
			state["received"] = true
			state["type"] = ev_type
			state["loc"] = loc
			state["strength"] = strength
	)

	bus.evidence_detected.emit("EMF", Vector3(1, 2, 3), 0.75)

	assert_true(state["received"], "Signal should be received")
	assert_eq(state["type"], "EMF", "Evidence type should match")
	assert_eq(state["loc"], Vector3(1, 2, 3), "Location should match")
	assert_almost_eq(state["strength"], 0.75, 0.01, "Strength should match")


func test_hunt_started_emission() -> void:
	var state := {"received": false}

	bus.hunt_started.connect(func(): state["received"] = true)

	bus.hunt_started.emit()

	assert_true(state["received"], "Hunt started signal should be received")


func test_match_ended_emission() -> void:
	var state := {"received": false, "result": ""}

	bus.match_ended.connect(
		func(result: String):
			state["received"] = true
			state["result"] = result
	)

	bus.match_ended.emit("investigators_win")

	assert_true(state["received"], "Match ended signal should be received")
	assert_eq(state["result"], "investigators_win", "Result should match")


func test_multiple_listeners() -> void:
	var count := {"value": 0}

	bus.hunt_started.connect(func(): count["value"] += 1)
	bus.hunt_started.connect(func(): count["value"] += 1)
	bus.hunt_started.connect(func(): count["value"] += 1)

	bus.hunt_started.emit()

	assert_eq(count["value"], 3, "All three listeners should receive the signal")
