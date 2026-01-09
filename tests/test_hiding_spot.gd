extends GutTest
## Tests for HidingSpot class.

# --- Test Helpers ---


# Mock player for testing
class MockPlayer:
	extends CharacterBody3D

	var peer_id: int = 1

	func _init(id: int = 1) -> void:
		peer_id = id
		add_to_group("players")

	func get_peer_id() -> int:
		return peer_id


# Mock door for testing
class MockDoor:
	extends Node

	signal door_state_changed(is_closed: bool)

	var _closed: bool = false

	func is_closed() -> bool:
		return _closed

	func set_closed(closed: bool) -> void:
		_closed = closed
		door_state_changed.emit(closed)


# Mock entity for testing
class MockEntity:
	extends Node3D

	var _can_ignore_hiding: bool = false

	func can_ignore_hiding_spots() -> bool:
		return _can_ignore_hiding


var _hiding_spot: HidingSpot = null


func before_each() -> void:
	_hiding_spot = HidingSpot.new()
	_hiding_spot.name = "TestHidingSpot"

	# Add collision shape
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2, 2, 2)
	shape.shape = box
	_hiding_spot.add_child(shape)

	add_child(_hiding_spot)


func after_each() -> void:
	if _hiding_spot:
		_hiding_spot.queue_free()
		_hiding_spot = null


# --- Initialization Tests ---


func test_hiding_spot_starts_with_no_occupants() -> void:
	assert_false(_hiding_spot.has_occupants())
	assert_eq(_hiding_spot.get_occupant_count(), 0)
	assert_eq(_hiding_spot.get_occupants().size(), 0)


func test_hiding_spot_default_settings() -> void:
	assert_true(_hiding_spot.blocks_entity_entry)
	assert_eq(_hiding_spot.search_duration, 5.0)
	assert_true(_hiding_spot.blocks_detection_when_closed)


func test_hiding_spot_added_to_group() -> void:
	assert_true(_hiding_spot.is_in_group("hiding_spots"))


func test_hiding_spot_collision_settings() -> void:
	# Should detect players only (layer 2)
	assert_eq(_hiding_spot.collision_layer, 0, "Should not be solid")
	assert_eq(_hiding_spot.collision_mask, 2, "Should detect players (layer 2)")


# --- Door State Tests ---


func test_is_door_closed_returns_initial_value() -> void:
	_hiding_spot.initial_door_closed = false
	# Re-trigger ready logic by setting value directly
	_hiding_spot.set_door_closed(false)

	assert_false(_hiding_spot.is_door_closed())


func test_set_door_closed_updates_state() -> void:
	_hiding_spot.set_door_closed(true)
	assert_true(_hiding_spot.is_door_closed())

	_hiding_spot.set_door_closed(false)
	assert_false(_hiding_spot.is_door_closed())


func test_set_door_closed_emits_signal() -> void:
	var signal_received := {"called": false, "closed": false}
	_hiding_spot.door_state_changed.connect(
		func(is_closed: bool):
			signal_received["called"] = true
			signal_received["closed"] = is_closed
	)

	_hiding_spot.set_door_closed(true)

	assert_true(signal_received["called"])
	assert_true(signal_received["closed"])


func test_door_node_state_is_read() -> void:
	var mock_door := MockDoor.new()
	mock_door.name = "Door"
	mock_door._closed = true
	_hiding_spot.add_child(mock_door)

	# Force finding door node
	_hiding_spot._find_door_node()

	assert_true(_hiding_spot.is_door_closed())


func test_door_signal_updates_hiding_spot() -> void:
	var mock_door := MockDoor.new()
	mock_door.name = "Door"
	_hiding_spot.add_child(mock_door)
	_hiding_spot._find_door_node()

	mock_door.set_closed(true)

	assert_true(_hiding_spot.is_door_closed())


# --- Occupancy Tests ---


func test_has_player_returns_false_when_not_present() -> void:
	assert_false(_hiding_spot.has_player(1))
	assert_false(_hiding_spot.has_player(999))


func test_player_entered_signal_emitted() -> void:
	var signal_received := {"called": false, "player_id": -1}
	_hiding_spot.player_entered.connect(
		func(player_id: int):
			signal_received["called"] = true
			signal_received["player_id"] = player_id
	)

	var player := MockPlayer.new(42)
	add_child(player)

	# Simulate body entering
	_hiding_spot._on_body_entered(player)

	assert_true(signal_received["called"])
	assert_eq(signal_received["player_id"], 42)

	player.queue_free()


func test_player_exit_signal_emitted() -> void:
	var signal_received := {"called": false, "player_id": -1}
	_hiding_spot.player_exited.connect(
		func(player_id: int):
			signal_received["called"] = true
			signal_received["player_id"] = player_id
	)

	var player := MockPlayer.new(42)
	add_child(player)

	# Enter then exit
	_hiding_spot._on_body_entered(player)
	_hiding_spot._on_body_exited(player)

	assert_true(signal_received["called"])
	assert_eq(signal_received["player_id"], 42)

	player.queue_free()


func test_occupant_tracking_updates_on_enter() -> void:
	var player := MockPlayer.new(1)
	add_child(player)

	_hiding_spot._on_body_entered(player)

	assert_true(_hiding_spot.has_occupants())
	assert_eq(_hiding_spot.get_occupant_count(), 1)
	assert_true(_hiding_spot.has_player(1))

	player.queue_free()


func test_occupant_tracking_updates_on_exit() -> void:
	var player := MockPlayer.new(1)
	add_child(player)

	_hiding_spot._on_body_entered(player)
	_hiding_spot._on_body_exited(player)

	assert_false(_hiding_spot.has_occupants())
	assert_eq(_hiding_spot.get_occupant_count(), 0)
	assert_false(_hiding_spot.has_player(1))

	player.queue_free()


func test_multiple_players_can_occupy() -> void:
	var player1 := MockPlayer.new(1)
	var player2 := MockPlayer.new(2)
	add_child(player1)
	add_child(player2)

	_hiding_spot._on_body_entered(player1)
	_hiding_spot._on_body_entered(player2)

	assert_eq(_hiding_spot.get_occupant_count(), 2)
	assert_true(_hiding_spot.has_player(1))
	assert_true(_hiding_spot.has_player(2))

	player1.queue_free()
	player2.queue_free()


func test_non_player_bodies_ignored() -> void:
	var non_player := CharacterBody3D.new()
	non_player.name = "NotAPlayer"
	add_child(non_player)

	_hiding_spot._on_body_entered(non_player)

	assert_false(_hiding_spot.has_occupants())

	non_player.queue_free()


func test_get_occupants_returns_copy() -> void:
	var player := MockPlayer.new(1)
	add_child(player)

	_hiding_spot._on_body_entered(player)

	var occupants := _hiding_spot.get_occupants()
	occupants.clear()  # Modify the returned array

	# Original should be unchanged
	assert_eq(_hiding_spot.get_occupant_count(), 1)

	player.queue_free()


# --- Protection Tests ---


func test_is_protecting_occupants_false_when_empty() -> void:
	_hiding_spot.set_door_closed(true)
	assert_false(_hiding_spot.is_protecting_occupants())


func test_is_protecting_occupants_false_when_door_open() -> void:
	var player := MockPlayer.new(1)
	add_child(player)
	_hiding_spot._on_body_entered(player)

	_hiding_spot.set_door_closed(false)

	assert_false(_hiding_spot.is_protecting_occupants())

	player.queue_free()


func test_is_protecting_occupants_true_when_door_closed_and_occupied() -> void:
	var player := MockPlayer.new(1)
	add_child(player)
	_hiding_spot._on_body_entered(player)

	_hiding_spot.set_door_closed(true)

	assert_true(_hiding_spot.is_protecting_occupants())

	player.queue_free()


func test_is_protecting_occupants_false_when_blocking_disabled() -> void:
	var player := MockPlayer.new(1)
	add_child(player)
	_hiding_spot._on_body_entered(player)
	_hiding_spot.set_door_closed(true)

	_hiding_spot.blocks_detection_when_closed = false

	assert_false(_hiding_spot.is_protecting_occupants())

	player.queue_free()


func test_can_entity_detect_inside_when_door_open() -> void:
	assert_true(_hiding_spot.can_entity_detect_inside())


func test_can_entity_detect_inside_false_when_door_closed() -> void:
	_hiding_spot.set_door_closed(true)
	assert_false(_hiding_spot.can_entity_detect_inside())


func test_can_entity_detect_inside_true_when_blocking_disabled() -> void:
	_hiding_spot.blocks_detection_when_closed = false
	_hiding_spot.set_door_closed(true)

	assert_true(_hiding_spot.can_entity_detect_inside())


# --- Entity Search Tests ---


func test_is_being_searched_false_initially() -> void:
	assert_false(_hiding_spot.is_being_searched())
	assert_null(_hiding_spot.get_searching_entity())


func test_start_entity_search_begins_search() -> void:
	var entity := MockEntity.new()
	add_child(entity)

	_hiding_spot.start_entity_search(entity)

	assert_true(_hiding_spot.is_being_searched())
	assert_eq(_hiding_spot.get_searching_entity(), entity)

	entity.queue_free()


func test_start_entity_search_emits_signal() -> void:
	var signal_received := {"called": false, "entity": null}
	_hiding_spot.search_started.connect(
		func(entity: Node):
			signal_received["called"] = true
			signal_received["entity"] = entity
	)

	var entity := MockEntity.new()
	add_child(entity)
	_hiding_spot.start_entity_search(entity)

	assert_true(signal_received["called"])
	assert_eq(signal_received["entity"], entity)

	entity.queue_free()


func test_search_timer_set_on_start() -> void:
	var entity := MockEntity.new()
	add_child(entity)

	_hiding_spot.search_duration = 8.0
	_hiding_spot.start_entity_search(entity)

	assert_almost_eq(_hiding_spot.get_search_time_remaining(), 8.0, 0.01)

	entity.queue_free()


func test_cancel_search_ends_search() -> void:
	var entity := MockEntity.new()
	add_child(entity)

	_hiding_spot.start_entity_search(entity)
	_hiding_spot.cancel_search()

	assert_false(_hiding_spot.is_being_searched())
	assert_null(_hiding_spot.get_searching_entity())

	entity.queue_free()


func test_cancel_search_emits_signal() -> void:
	var signal_received := {"called": false}
	_hiding_spot.search_ended.connect(func(_e): signal_received["called"] = true)

	var entity := MockEntity.new()
	add_child(entity)

	_hiding_spot.start_entity_search(entity)
	_hiding_spot.cancel_search()

	assert_true(signal_received["called"])

	entity.queue_free()


func test_double_search_start_ignored() -> void:
	var entity1 := MockEntity.new()
	var entity2 := MockEntity.new()
	add_child(entity1)
	add_child(entity2)

	_hiding_spot.start_entity_search(entity1)
	_hiding_spot.start_entity_search(entity2)

	# First entity should still be searching
	assert_eq(_hiding_spot.get_searching_entity(), entity1)

	entity1.queue_free()
	entity2.queue_free()


# --- Network State Tests ---


func test_get_network_state_includes_all_fields() -> void:
	var player := MockPlayer.new(42)
	add_child(player)
	_hiding_spot._on_body_entered(player)
	_hiding_spot.set_door_closed(true)

	var state := _hiding_spot.get_network_state()

	assert_has(state, "occupants")
	assert_has(state, "door_closed")
	assert_has(state, "being_searched")
	assert_has(state, "search_timer")

	assert_eq(state.occupants.size(), 1)
	assert_true(state.door_closed)
	assert_false(state.being_searched)

	player.queue_free()


func test_apply_network_state_updates_hiding_spot() -> void:
	var state := {
		"occupants": [1, 2],
		"door_closed": true,
		"search_timer": 3.0,
	}

	_hiding_spot.apply_network_state(state)

	assert_true(_hiding_spot.is_door_closed())
	assert_almost_eq(_hiding_spot.get_search_time_remaining(), 3.0, 0.01)
