extends GutTest
## Tests for HidingSpotDoor class.

# --- Test Helpers ---


# Mock player for testing
class MockPlayer:
	extends Node3D

	var peer_id: int = 1

	func get_peer_id() -> int:
		return peer_id


var _door: HidingSpotDoor = null


func before_each() -> void:
	_door = HidingSpotDoor.new()
	_door.name = "TestDoor"
	add_child(_door)


func after_each() -> void:
	if _door:
		_door.queue_free()
		_door = null


# --- Initialization Tests ---


func test_door_starts_open_by_default() -> void:
	assert_false(_door.is_closed())


func test_door_can_start_closed() -> void:
	var door := HidingSpotDoor.new()
	door.starts_closed = true
	add_child(door)

	# Note: _ready sets state based on starts_closed
	assert_true(door.is_closed())

	door.queue_free()


func test_door_is_toggle_type_interactable() -> void:
	assert_eq(_door.interaction_type, Interactable.InteractionType.TOGGLE)


func test_door_added_to_group() -> void:
	assert_true(_door.is_in_group("hiding_spot_doors"))


# --- Door State Tests ---


func test_is_closed_returns_current_state() -> void:
	assert_false(_door.is_closed())

	_door.set_closed(true)
	assert_true(_door.is_closed())

	_door.set_closed(false)
	assert_false(_door.is_closed())


func test_set_closed_emits_signal() -> void:
	var signal_received := {"called": false, "closed": false}
	_door.door_state_changed.connect(
		func(is_closed: bool):
			signal_received["called"] = true
			signal_received["closed"] = is_closed
	)

	_door.set_closed(true)

	assert_true(signal_received["called"])
	assert_true(signal_received["closed"])


func test_set_closed_to_same_state_does_not_emit() -> void:
	_door.set_closed(false)  # Already false

	var signal_received := {"count": 0}
	_door.door_state_changed.connect(func(_c): signal_received["count"] += 1)

	_door.set_closed(false)

	assert_eq(signal_received["count"], 0)


func test_open_sets_door_open() -> void:
	_door.set_closed(true)
	_door.open()
	assert_false(_door.is_closed())


func test_close_sets_door_closed() -> void:
	_door.close()
	assert_true(_door.is_closed())


# --- Interaction Tests ---


func test_interact_toggles_door_state() -> void:
	var player := MockPlayer.new()
	add_child(player)

	assert_false(_door.is_closed())

	_door.interact(player)
	assert_true(_door.is_closed())

	# Clear cooldown for second interaction
	_door.clear_cooldown()
	_door.interact(player)
	assert_false(_door.is_closed())

	player.queue_free()


func test_interact_returns_true() -> void:
	var player := MockPlayer.new()
	add_child(player)

	var result := _door.interact(player)
	assert_true(result)

	player.queue_free()


func test_interact_emits_interacted_signal() -> void:
	var signal_received := {"called": false}
	_door.interacted.connect(func(_p): signal_received["called"] = true)

	var player := MockPlayer.new()
	add_child(player)

	_door.interact(player)

	assert_true(signal_received["called"])

	player.queue_free()


# --- Interaction Prompt Tests ---


func test_get_interaction_prompt_shows_open_when_closed() -> void:
	_door.set_closed(true)
	assert_eq(_door.get_interaction_prompt(), "Open")


func test_get_interaction_prompt_shows_close_when_open() -> void:
	_door.set_closed(false)
	assert_eq(_door.get_interaction_prompt(), "Close")


# --- Collision Body Tests ---


func test_collision_body_enabled_when_closed() -> void:
	var collision_body := StaticBody3D.new()
	collision_body.name = "DoorCollision"
	_door.add_child(collision_body)

	# Re-run _ready logic to find the body
	_door._collision_body = collision_body

	_door.set_closed(true)

	assert_eq(collision_body.collision_layer, 1, "Should be on World layer when closed")


func test_collision_body_disabled_when_open() -> void:
	var collision_body := StaticBody3D.new()
	collision_body.name = "DoorCollision"
	collision_body.collision_layer = 1  # Start with collision enabled
	_door.add_child(collision_body)

	_door._collision_body = collision_body

	# First close, then open to ensure state change triggers update
	_door.set_closed(true)
	_door.set_closed(false)

	assert_eq(collision_body.collision_layer, 0, "Should have no collision when open")


# --- Network State Tests ---


func test_get_network_state_includes_door_state() -> void:
	_door.set_closed(true)

	var state := _door.get_network_state()

	assert_has(state, "door_closed")
	assert_true(state.door_closed)


func test_apply_network_state_updates_door() -> void:
	var state := {
		"enabled": true,
		"used": false,
		"door_closed": true,
	}

	_door.apply_network_state(state)

	assert_true(_door.is_closed())


func test_network_state_includes_base_fields() -> void:
	var state := _door.get_network_state()

	assert_has(state, "enabled")
	assert_has(state, "used")
	assert_has(state, "door_closed")


# --- Animation Player Tests ---


func test_animation_player_found_in_children() -> void:
	var anim_player := AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	_door.add_child(anim_player)

	# Reset and re-add door to trigger _ready
	var door := HidingSpotDoor.new()
	anim_player = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	door.add_child(anim_player)
	add_child(door)

	# Animation player should be found
	assert_not_null(door._anim_player)

	door.queue_free()


# --- Can Interact Tests ---


func test_can_interact_with_fresh_door() -> void:
	var player := MockPlayer.new()
	add_child(player)

	assert_true(_door.can_interact(player))

	player.queue_free()


func test_cannot_interact_when_disabled() -> void:
	var player := MockPlayer.new()
	add_child(player)

	_door.set_interaction_enabled(false)

	assert_false(_door.can_interact(player))

	player.queue_free()
