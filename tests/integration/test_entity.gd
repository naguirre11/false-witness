# gdlint: ignore=max-public-methods
# gdlint: ignore=max-file-lines
extends GutTest
## Tests for Entity base class.

const EchoControllerScript = preload("res://src/player/echo_controller.gd")

# --- Test Helpers ---

var _entity: Entity = null


## Mock player class for testing hunt target validation.
class MockPlayer:
	extends CharacterBody3D

	var is_alive: bool = true
	var is_echo: bool = false


func before_each() -> void:
	_entity = Entity.new()
	_entity.entity_type = "TestEntity"
	add_child(_entity)


func after_each() -> void:
	if _entity:
		_entity.queue_free()
		_entity = null


# --- Initialization Tests ---


func test_entity_initializes_with_dormant_state() -> void:
	assert_eq(_entity.get_state(), Entity.EntityState.DORMANT)
	assert_eq(_entity.get_state_name(), "Dormant")


func test_entity_type_returns_configured_value() -> void:
	assert_eq(_entity.get_entity_type(), "TestEntity")


func test_entity_default_export_values() -> void:
	assert_eq(_entity.base_speed, 1.5, "Base speed should be 1.5")
	assert_eq(_entity.hunt_speed, 2.5, "Hunt speed should be 2.5")
	assert_eq(_entity.hunt_sanity_threshold, 50.0, "Default hunt threshold should be 50")
	assert_eq(_entity.hunt_duration, 30.0, "Hunt duration should be 30s")


func test_entity_not_visible_initially() -> void:
	assert_false(_entity.is_visible_to_players(), "Should not be visible initially")


func test_entity_not_hunting_initially() -> void:
	assert_false(_entity.is_hunting())


# --- State Machine Tests ---


func test_change_state_updates_state() -> void:
	_entity.change_state(Entity.EntityState.ACTIVE)
	assert_eq(_entity.get_state(), Entity.EntityState.ACTIVE)
	assert_eq(_entity.get_state_name(), "Active")


func test_change_state_emits_signal() -> void:
	var signal_received := {"called": false, "old": -1, "new": -1}
	_entity.state_changed.connect(
		func(old: Entity.EntityState, new: Entity.EntityState):
			signal_received["called"] = true
			signal_received["old"] = old
			signal_received["new"] = new
	)

	_entity.change_state(Entity.EntityState.ACTIVE)

	assert_true(signal_received["called"], "state_changed should be emitted")
	assert_eq(signal_received["old"], Entity.EntityState.DORMANT)
	assert_eq(signal_received["new"], Entity.EntityState.ACTIVE)


func test_change_state_to_same_state_does_nothing() -> void:
	var signal_received := {"count": 0}
	_entity.state_changed.connect(func(_old, _new): signal_received["count"] += 1)

	_entity.change_state(Entity.EntityState.DORMANT)

	assert_eq(signal_received["count"], 0, "Should not emit when state unchanged")


func test_all_states_have_valid_names() -> void:
	var states := [
		Entity.EntityState.DORMANT,
		Entity.EntityState.ACTIVE,
		Entity.EntityState.HUNTING,
		Entity.EntityState.MANIFESTING,
	]
	var expected_names := ["Dormant", "Active", "Hunting", "Manifesting"]

	for i in states.size():
		_entity.change_state(states[i])
		assert_eq(_entity.get_state_name(), expected_names[i])


# --- Hunt State Tests ---


func test_on_hunt_started_changes_to_hunting_state() -> void:
	_entity.on_hunt_started()

	assert_eq(_entity.get_state(), Entity.EntityState.HUNTING)
	assert_true(_entity.is_hunting())


func test_on_hunt_ended_changes_to_active_state() -> void:
	_entity.on_hunt_started()
	_entity.on_hunt_ended()

	assert_eq(_entity.get_state(), Entity.EntityState.ACTIVE)
	assert_false(_entity.is_hunting())


func test_hunt_clears_target_on_end() -> void:
	var mock_target := Node3D.new()
	add_child(mock_target)

	_entity.on_hunt_started()
	_entity.set_hunt_target(mock_target)
	assert_eq(_entity.get_hunt_target(), mock_target)

	_entity.on_hunt_ended()
	assert_null(_entity.get_hunt_target(), "Target should be cleared on hunt end")

	mock_target.queue_free()


# --- Movement Speed Tests ---


func test_get_current_speed_returns_zero_in_dormant() -> void:
	assert_eq(_entity.get_current_speed(), 0.0, "Dormant entities don't move")


func test_get_current_speed_returns_base_speed_in_active() -> void:
	_entity.change_state(Entity.EntityState.ACTIVE)
	assert_eq(_entity.get_current_speed(), _entity.base_speed)


func test_get_current_speed_returns_hunt_unaware_speed_when_not_aware() -> void:
	_entity.on_hunt_started()
	_entity.set_aware_of_target(false)
	assert_eq(_entity.get_current_speed(), _entity.hunt_unaware_speed)


func test_get_current_speed_returns_hunt_aware_speed_when_aware() -> void:
	_entity.on_hunt_started()
	_entity.set_aware_of_target(true)
	assert_eq(_entity.get_current_speed(), _entity.hunt_aware_speed)


# --- Manifestation Tests ---


func test_start_manifestation_changes_state() -> void:
	_entity.change_state(Entity.EntityState.ACTIVE)
	var result := _entity.start_manifestation()

	assert_true(result, "Manifestation should start")
	assert_eq(_entity.get_state(), Entity.EntityState.MANIFESTING)
	assert_true(_entity.is_visible_to_players())


func test_start_manifestation_blocked_during_hunt() -> void:
	_entity.on_hunt_started()
	var result := _entity.start_manifestation()

	assert_false(result, "Cannot manifest during hunt")
	assert_eq(_entity.get_state(), Entity.EntityState.HUNTING)


func test_end_manifestation_returns_to_active() -> void:
	_entity.change_state(Entity.EntityState.ACTIVE)
	_entity.start_manifestation()
	_entity.end_manifestation()

	assert_eq(_entity.get_state(), Entity.EntityState.ACTIVE)
	assert_false(_entity.is_visible_to_players())


func test_manifestation_cooldown_prevents_immediate_remanifest() -> void:
	_entity.change_state(Entity.EntityState.ACTIVE)
	_entity.start_manifestation()
	_entity.end_manifestation()

	# Immediate attempt should fail due to cooldown
	var result := _entity.start_manifestation()
	assert_false(result, "Should be on cooldown")


func test_visibility_changed_signal_emitted() -> void:
	var signal_received := {"called": false, "visible": false}
	_entity.entity_visibility_changed.connect(
		func(is_visible: bool):
			signal_received["called"] = true
			signal_received["visible"] = is_visible
	)

	_entity.change_state(Entity.EntityState.ACTIVE)
	_entity.start_manifestation()

	assert_true(signal_received["called"])
	assert_true(signal_received["visible"])


# --- Behavioral Tell Tests ---


func test_get_behavioral_tell_type_returns_unknown_by_default() -> void:
	assert_eq(_entity.get_behavioral_tell_type(), "unknown")


func test_trigger_behavioral_tell_emits_signal() -> void:
	var signal_received := {"called": false, "type": ""}
	_entity.behavioral_tell_triggered.connect(
		func(tell_type: String):
			signal_received["called"] = true
			signal_received["type"] = tell_type
	)

	_entity.trigger_behavioral_tell()

	assert_true(signal_received["called"])
	assert_eq(signal_received["type"], "unknown")


# --- Favorite Room Tests ---


func test_favorite_room_empty_initially() -> void:
	assert_eq(_entity.get_favorite_room(), "")


func test_set_favorite_room_updates_value() -> void:
	_entity.set_favorite_room("Kitchen")
	assert_eq(_entity.get_favorite_room(), "Kitchen")


# --- Manager Integration Tests ---


func test_set_manager_stores_reference() -> void:
	var mock_manager := Node.new()
	add_child(mock_manager)

	_entity.set_manager(mock_manager)
	assert_eq(_entity.get_manager(), mock_manager)

	mock_manager.queue_free()


# --- Hunt Target Tests ---


func test_set_hunt_target_stores_target() -> void:
	var target := Node3D.new()
	target.global_position = Vector3(5, 0, 5)
	add_child(target)

	_entity.set_hunt_target(target)

	assert_eq(_entity.get_hunt_target(), target)

	target.queue_free()


func test_set_hunt_target_sets_awareness() -> void:
	var target := Node3D.new()
	add_child(target)

	_entity.set_hunt_target(target)

	# Setting a target should make entity aware
	_entity.on_hunt_started()
	assert_eq(_entity.get_current_speed(), _entity.hunt_aware_speed)

	target.queue_free()


# --- Network State Tests ---


func test_get_network_state_includes_all_fields() -> void:
	_entity.change_state(Entity.EntityState.ACTIVE)
	_entity.global_position = Vector3(10, 0, 20)
	_entity.rotation.y = 1.5

	var state := _entity.get_network_state()

	assert_has(state, "state", "Should include state")
	assert_has(state, "position", "Should include position")
	assert_has(state, "rotation_y", "Should include rotation")
	assert_has(state, "is_visible", "Should include visibility")
	assert_has(state, "hunt_timer", "Should include hunt timer")
	assert_has(state, "manifestation_timer", "Should include manifestation timer")


func test_apply_network_state_updates_entity() -> void:
	var state := {
		"state": Entity.EntityState.ACTIVE,
		"position": {"x": 5.0, "y": 0.0, "z": 10.0},
		"rotation_y": 2.0,
		"is_visible": true,
		"hunt_timer": 15.0,
		"manifestation_timer": 3.0,
	}

	_entity.apply_network_state(state)

	assert_eq(_entity.get_state(), Entity.EntityState.ACTIVE)
	assert_almost_eq(_entity.global_position.x, 5.0, 0.01)
	assert_almost_eq(_entity.global_position.z, 10.0, 0.01)
	assert_almost_eq(_entity.rotation.y, 2.0, 0.01)
	assert_true(_entity.is_visible_to_players())


# --- Navigation Tests ---


func test_navigation_agent_created_on_ready() -> void:
	# NavigationAgent3D should be created in _ready
	var nav_agent: NavigationAgent3D = null
	for child in _entity.get_children():
		if child is NavigationAgent3D:
			nav_agent = child
			break

	assert_not_null(nav_agent, "NavigationAgent3D should be created")


func test_is_navigation_finished_returns_true_initially() -> void:
	# With no target set, navigation should be "finished"
	assert_true(_entity.is_navigation_finished())


# --- Collision Layer Tests ---


func test_entity_on_correct_collision_layer() -> void:
	# Layer 3 = bit 2 (0-indexed) = value 4
	assert_eq(_entity.collision_layer, 4, "Should be on Entity layer (3)")


func test_entity_collision_mask_includes_world_and_player() -> void:
	# World (1) + Player (2) = 3
	assert_eq(_entity.collision_mask, 3, "Should collide with World and Player")


# --- Hunt Detection Integration Tests ---


func test_is_aware_of_target_false_initially() -> void:
	assert_false(_entity.is_aware_of_target())


func test_is_aware_of_target_true_after_set_hunt_target() -> void:
	var target := Node3D.new()
	add_child(target)

	_entity.set_hunt_target(target)

	# set_hunt_target sets _is_aware_of_target = true
	assert_true(_entity.is_aware_of_target())

	target.queue_free()


func test_set_aware_of_target_updates_awareness() -> void:
	_entity.set_aware_of_target(true)
	assert_true(_entity.is_aware_of_target())

	_entity.set_aware_of_target(false)
	assert_false(_entity.is_aware_of_target())


func test_get_last_known_target_position_empty_initially() -> void:
	var pos := _entity.get_last_known_target_position()
	assert_eq(pos, Vector3.ZERO)


func test_set_hunt_target_records_last_known_position() -> void:
	var target := Node3D.new()
	target.global_position = Vector3(10, 0, 15)
	add_child(target)

	_entity.set_hunt_target(target)

	# Last known position should be set
	var pos := _entity.get_last_known_target_position()
	assert_almost_eq(pos.x, 10.0, 0.01)
	assert_almost_eq(pos.z, 15.0, 0.01)

	target.queue_free()


func test_on_hunt_ended_clears_awareness() -> void:
	var target := Node3D.new()
	add_child(target)

	_entity.on_hunt_started()
	_entity.set_hunt_target(target)
	assert_true(_entity.is_aware_of_target())

	_entity.on_hunt_ended()
	assert_false(_entity.is_aware_of_target())

	target.queue_free()


func test_get_target_detection_radius_returns_base_without_target() -> void:
	var radius := _entity.get_target_detection_radius()
	assert_eq(radius, HuntDetection.BASE_DETECTION_RADIUS)


func test_speed_depends_on_awareness_during_hunt() -> void:
	_entity.on_hunt_started()

	# Unaware = slow speed
	_entity.set_aware_of_target(false)
	assert_eq(_entity.get_current_speed(), _entity.hunt_unaware_speed)

	# Aware = fast speed
	_entity.set_aware_of_target(true)
	assert_eq(_entity.get_current_speed(), _entity.hunt_aware_speed)


# --- Hiding Spot Tests ---


func test_can_ignore_hiding_spots_returns_false_by_default() -> void:
	assert_false(_entity.can_ignore_hiding_spots())


func test_is_searching_hiding_spot_false_initially() -> void:
	assert_false(_entity.is_searching_hiding_spot())
	assert_null(_entity.get_searching_hiding_spot())


class MockHidingSpotForEntity:
	extends Node3D

	var _search_started: bool = false
	var _search_cancelled: bool = false

	func _init() -> void:
		add_to_group("hiding_spots")

	func start_entity_search(_entity: Node) -> void:
		_search_started = true

	func cancel_search() -> void:
		_search_cancelled = true

	func is_being_searched() -> bool:
		return _search_started and not _search_cancelled


func test_find_nearby_hiding_spot_finds_spot_in_range() -> void:
	# Clear any existing hiding spots from previous tests
	for spot in get_tree().get_nodes_in_group("hiding_spots"):
		spot.remove_from_group("hiding_spots")

	var hiding_spot := MockHidingSpotForEntity.new()
	add_child(hiding_spot)
	hiding_spot.global_position = Vector3(3, 0, 0)

	var found := _entity._find_nearby_hiding_spot(Vector3(0, 0, 0), 5.0)

	assert_not_null(found, "Should find hiding spot within range")
	assert_eq(found, hiding_spot)

	hiding_spot.queue_free()


func test_find_nearby_hiding_spot_ignores_out_of_range() -> void:
	# Clear any existing hiding spots from previous tests
	for spot in get_tree().get_nodes_in_group("hiding_spots"):
		spot.remove_from_group("hiding_spots")

	var hiding_spot := MockHidingSpotForEntity.new()
	add_child(hiding_spot)
	# Must set position after adding to tree
	hiding_spot.global_position = Vector3(10, 0, 0)

	# Position entity at origin
	_entity.global_position = Vector3.ZERO

	var found := _entity._find_nearby_hiding_spot(Vector3(0, 0, 0), 5.0)

	assert_null(found, "Should not find hiding spot out of range")

	hiding_spot.queue_free()


func test_start_hiding_spot_search_sets_searching_state() -> void:
	var hiding_spot := MockHidingSpotForEntity.new()
	add_child(hiding_spot)

	_entity._start_hiding_spot_search(hiding_spot)

	assert_true(_entity.is_searching_hiding_spot())
	assert_eq(_entity.get_searching_hiding_spot(), hiding_spot)

	hiding_spot.queue_free()


func test_start_hiding_spot_search_notifies_spot() -> void:
	var hiding_spot := MockHidingSpotForEntity.new()
	add_child(hiding_spot)

	_entity._start_hiding_spot_search(hiding_spot)

	assert_true(hiding_spot._search_started)

	hiding_spot.queue_free()


func test_cancel_hiding_spot_search_clears_state() -> void:
	var hiding_spot := MockHidingSpotForEntity.new()
	add_child(hiding_spot)

	_entity._start_hiding_spot_search(hiding_spot)
	_entity._cancel_hiding_spot_search()

	assert_false(_entity.is_searching_hiding_spot())
	assert_null(_entity.get_searching_hiding_spot())

	hiding_spot.queue_free()


func test_cancel_hiding_spot_search_notifies_spot() -> void:
	var hiding_spot := MockHidingSpotForEntity.new()
	add_child(hiding_spot)

	_entity._start_hiding_spot_search(hiding_spot)
	_entity._cancel_hiding_spot_search()

	assert_true(hiding_spot._search_cancelled)

	hiding_spot.queue_free()


func test_on_hunt_ended_cancels_hiding_spot_search() -> void:
	var hiding_spot := MockHidingSpotForEntity.new()
	add_child(hiding_spot)

	_entity.on_hunt_started()
	_entity._start_hiding_spot_search(hiding_spot)
	_entity.on_hunt_ended()

	assert_false(_entity.is_searching_hiding_spot())

	hiding_spot.queue_free()


# --- Hunt Variation Virtual Methods Tests ---


func test_get_hunt_sanity_threshold_returns_default() -> void:
	assert_eq(_entity.get_hunt_sanity_threshold(), 50.0)


func test_get_hunt_sanity_threshold_reflects_export_value() -> void:
	_entity.hunt_sanity_threshold = 70.0
	assert_eq(_entity.get_hunt_sanity_threshold(), 70.0)


func test_should_ignore_team_sanity_returns_false_by_default() -> void:
	assert_false(_entity.should_ignore_team_sanity())


func test_can_voice_trigger_hunt_returns_false_by_default() -> void:
	assert_false(_entity.can_voice_trigger_hunt())


func test_get_hunt_speed_for_awareness_returns_aware_speed_when_true() -> void:
	_entity.hunt_aware_speed = 3.0
	_entity.hunt_unaware_speed = 1.0
	assert_eq(_entity.get_hunt_speed_for_awareness(true), 3.0)


func test_get_hunt_speed_for_awareness_returns_unaware_speed_when_false() -> void:
	_entity.hunt_aware_speed = 3.0
	_entity.hunt_unaware_speed = 1.0
	assert_eq(_entity.get_hunt_speed_for_awareness(false), 1.0)


func test_can_hunt_in_current_conditions_returns_true_by_default() -> void:
	assert_true(_entity.can_hunt_in_current_conditions())


func test_get_hunt_duration_returns_default() -> void:
	assert_eq(_entity.get_hunt_duration(), 30.0)


func test_get_hunt_duration_reflects_export_value() -> void:
	_entity.hunt_duration = 45.0
	assert_eq(_entity.get_hunt_duration(), 45.0)


# --- Echo Reaction System Tests (FW-043c) ---


func test_entity_not_reacting_to_echo_initially() -> void:
	assert_false(_entity.is_reacting_to_echo())


func test_entity_get_reaction_target_echo_returns_null_initially() -> void:
	assert_null(_entity.get_reaction_target_echo())


func test_entity_trigger_echo_reaction_fails_without_echoes() -> void:
	var result: bool = _entity.trigger_echo_reaction()
	assert_false(result, "Should fail when no Echoes in range")


func test_entity_trigger_echo_reaction_succeeds_with_echo_in_range() -> void:
	# Create an Echo and add it to the echoes group
	var echo_script: GDScript = EchoControllerScript
	var echo: Node3D = echo_script.new()
	echo.name = "TestEcho"
	echo.global_position = _entity.global_position + Vector3(5, 0, 0)  # Within range
	add_child_autofree(echo)
	echo.add_to_group("echoes")

	var result: bool = _entity.trigger_echo_reaction()

	assert_true(result, "Should succeed when Echo is in range")
	assert_true(_entity.is_reacting_to_echo())
	assert_eq(_entity.get_reaction_target_echo(), echo)


func test_entity_trigger_echo_reaction_fails_when_already_reacting() -> void:
	# Create an Echo
	var echo_script: GDScript = EchoControllerScript
	var echo: Node3D = echo_script.new()
	echo.name = "TestEcho"
	echo.global_position = _entity.global_position + Vector3(5, 0, 0)
	add_child_autofree(echo)
	echo.add_to_group("echoes")

	# First reaction should succeed
	var first_result: bool = _entity.trigger_echo_reaction()
	assert_true(first_result)

	# Second reaction should fail
	var second_result: bool = _entity.trigger_echo_reaction()
	assert_false(second_result, "Cannot trigger reaction while already reacting")


func test_entity_trigger_echo_reaction_fails_for_echo_out_of_range() -> void:
	# Create an Echo far away
	var echo_script: GDScript = EchoControllerScript
	var echo: Node3D = echo_script.new()
	echo.name = "TestEcho"
	echo.global_position = _entity.global_position + Vector3(100, 0, 0)  # Out of range
	add_child_autofree(echo)
	echo.add_to_group("echoes")

	var result: bool = _entity.trigger_echo_reaction()

	assert_false(result, "Should fail when Echo is out of range")


func test_entity_echo_reaction_emits_signal() -> void:
	# Create an Echo
	var echo_script: GDScript = EchoControllerScript
	var echo: Node3D = echo_script.new()
	echo.name = "TestEcho"
	echo.global_position = _entity.global_position + Vector3(5, 0, 0)
	add_child_autofree(echo)
	echo.add_to_group("echoes")

	var signal_data := {"received": false, "echo": null}
	_entity.echo_reaction_triggered.connect(
		func(e: Node): signal_data["received"] = true; signal_data["echo"] = e
	)

	_entity.trigger_echo_reaction()

	assert_true(signal_data["received"], "echo_reaction_triggered should be emitted")
	assert_eq(signal_data["echo"], echo)


func test_entity_does_not_react_to_echoes_during_hunt() -> void:
	# Start hunting
	_entity.change_state(Entity.EntityState.HUNTING)

	# Create an Echo
	var echo_script: GDScript = EchoControllerScript
	var echo: Node3D = echo_script.new()
	echo.name = "TestEcho"
	echo.global_position = _entity.global_position + Vector3(5, 0, 0)
	add_child_autofree(echo)
	echo.add_to_group("echoes")

	# Simulate _physics_process - should not process echo reactions during hunt
	# We can't call _physics_process directly, but we can verify the state
	# The entity is hunting so echo reactions should be skipped in _physics_process
	assert_true(_entity.is_hunting())


# --- Hunt Target Filtering Tests (FW-043c) ---


func test_is_valid_hunt_target_returns_true_for_alive_player() -> void:
	# Create a mock alive player
	var player := MockPlayer.new()
	player.is_alive = true
	player.is_echo = false
	add_child_autofree(player)

	var result: bool = _entity._is_valid_hunt_target(player)
	assert_true(result, "Alive player should be valid hunt target")


func test_is_valid_hunt_target_returns_false_for_dead_player() -> void:
	# Create a mock dead player
	var player := MockPlayer.new()
	player.is_alive = false
	add_child_autofree(player)

	var result: bool = _entity._is_valid_hunt_target(player)
	assert_false(result, "Dead player should not be valid hunt target")


func test_is_valid_hunt_target_returns_false_for_echo_player() -> void:
	# Create a mock player in Echo state
	var player := MockPlayer.new()
	player.is_alive = false
	player.is_echo = true
	add_child_autofree(player)

	var result: bool = _entity._is_valid_hunt_target(player)
	assert_false(result, "Player in Echo state should not be valid hunt target")


func test_is_valid_hunt_target_returns_false_for_echo_controller() -> void:
	var echo_script: GDScript = EchoControllerScript
	var echo: Node = echo_script.new()
	add_child_autofree(echo)

	var result: bool = _entity._is_valid_hunt_target(echo)
	assert_false(result, "EchoController should not be valid hunt target")


func test_filter_valid_hunt_targets_removes_echoes() -> void:
	# Create a mix of alive players and Echoes
	var alive_player := MockPlayer.new()
	alive_player.is_alive = true
	alive_player.is_echo = false
	add_child_autofree(alive_player)

	var echo_script: GDScript = EchoControllerScript
	var echo: Node = echo_script.new()
	add_child_autofree(echo)

	var dead_player := MockPlayer.new()
	dead_player.is_alive = false
	dead_player.is_echo = true
	add_child_autofree(dead_player)

	var all_players: Array = [alive_player, echo, dead_player]
	var valid_targets: Array = _entity._filter_valid_hunt_targets(all_players)

	assert_eq(valid_targets.size(), 1, "Only alive player should be valid target")
	assert_has(valid_targets, alive_player)


func test_get_hunt_cooldown_returns_base_value() -> void:
	# Default multiplier is 1.0, so cooldown should be 25.0
	assert_eq(_entity.get_hunt_cooldown(), 25.0)


func test_get_hunt_cooldown_applies_multiplier() -> void:
	_entity.hunt_cooldown_multiplier = 0.8
	assert_almost_eq(_entity.get_hunt_cooldown(), 20.0, 0.01)


func test_on_hunt_started_uses_get_hunt_duration() -> void:
	_entity.hunt_duration = 45.0
	_entity.on_hunt_started()
	# The internal _hunt_timer should be set to get_hunt_duration()
	# We can verify this through the network state
	var state := _entity.get_network_state()
	assert_eq(state.hunt_timer, 45.0)


func test_get_current_speed_uses_get_hunt_speed_for_awareness() -> void:
	# This verifies the wiring between get_current_speed and get_hunt_speed_for_awareness
	_entity.hunt_aware_speed = 4.0
	_entity.hunt_unaware_speed = 1.5
	_entity.on_hunt_started()

	_entity.set_aware_of_target(true)
	assert_eq(_entity.get_current_speed(), 4.0)

	_entity.set_aware_of_target(false)
	assert_eq(_entity.get_current_speed(), 1.5)


# --- Hunt Variation Subclass Override Tests ---


class CustomEntity:
	extends Entity

	var custom_threshold: float = 70.0
	var custom_ignores_team: bool = true
	var custom_voice_trigger: bool = true
	var custom_aware_speed: float = 4.0
	var custom_unaware_speed: float = 2.0
	var custom_can_hunt: bool = false
	var custom_duration: float = 45.0
	var custom_cooldown: float = 20.0
	var speed_update_called: bool = false

	func get_hunt_sanity_threshold() -> float:
		return custom_threshold

	func should_ignore_team_sanity() -> bool:
		return custom_ignores_team

	func can_voice_trigger_hunt() -> bool:
		return custom_voice_trigger

	func get_hunt_speed_for_awareness(aware: bool) -> float:
		return custom_aware_speed if aware else custom_unaware_speed

	func _update_hunt_speed(_delta: float) -> void:
		speed_update_called = true

	func can_hunt_in_current_conditions() -> bool:
		return custom_can_hunt

	func get_hunt_duration() -> float:
		return custom_duration

	func get_hunt_cooldown() -> float:
		return custom_cooldown


func test_subclass_can_override_sanity_threshold() -> void:
	var custom := CustomEntity.new()
	add_child(custom)

	assert_eq(custom.get_hunt_sanity_threshold(), 70.0)

	custom.queue_free()


func test_subclass_can_override_ignore_team_sanity() -> void:
	var custom := CustomEntity.new()
	add_child(custom)

	assert_true(custom.should_ignore_team_sanity())

	custom.queue_free()


func test_subclass_can_override_voice_trigger() -> void:
	var custom := CustomEntity.new()
	add_child(custom)

	assert_true(custom.can_voice_trigger_hunt())

	custom.queue_free()


func test_subclass_can_override_hunt_speed_for_awareness() -> void:
	var custom := CustomEntity.new()
	add_child(custom)

	assert_eq(custom.get_hunt_speed_for_awareness(true), 4.0)
	assert_eq(custom.get_hunt_speed_for_awareness(false), 2.0)

	custom.queue_free()


func test_subclass_can_override_can_hunt_conditions() -> void:
	var custom := CustomEntity.new()
	add_child(custom)

	assert_false(custom.can_hunt_in_current_conditions())

	custom.queue_free()


func test_subclass_can_override_hunt_duration() -> void:
	var custom := CustomEntity.new()
	add_child(custom)

	assert_eq(custom.get_hunt_duration(), 45.0)

	custom.queue_free()


func test_subclass_can_override_hunt_cooldown() -> void:
	var custom := CustomEntity.new()
	add_child(custom)

	assert_eq(custom.get_hunt_cooldown(), 20.0)

	custom.queue_free()


func test_subclass_speed_override_used_by_get_current_speed() -> void:
	var custom := CustomEntity.new()
	add_child(custom)

	custom.on_hunt_started()
	custom.set_aware_of_target(true)

	assert_eq(custom.get_current_speed(), 4.0)

	custom.queue_free()


func test_subclass_duration_override_used_by_on_hunt_started() -> void:
	var custom := CustomEntity.new()
	add_child(custom)

	custom.on_hunt_started()

	var state := custom.get_network_state()
	assert_eq(state.hunt_timer, 45.0)

	custom.queue_free()


# --- Death Mechanics Tests ---


## Mock player for death testing
class MockPlayerForDeath:
	extends Node3D
	var peer_id: int = 123
	var is_alive: bool = true
	var death_position: Vector3 = Vector3.ZERO
	var killed_by_entity: Node = null

	func on_killed_by_entity(entity: Node, pos: Vector3) -> void:
		is_alive = false
		death_position = pos
		killed_by_entity = entity


func test_kill_range_constant_exists() -> void:
	assert_eq(Entity.KILL_RANGE, 1.0, "Kill range should be 1.0 meters")


func test_kill_player_emits_player_killed_signal() -> void:
	var signal_received := {"called": false, "player": null}
	_entity.player_killed.connect(
		func(player: Node):
			signal_received["called"] = true
			signal_received["player"] = player
	)

	var mock_player := MockPlayerForDeath.new()
	add_child(mock_player)

	_entity._kill_player(mock_player)

	assert_true(signal_received["called"], "player_killed signal should be emitted")
	assert_eq(signal_received["player"], mock_player)

	mock_player.queue_free()


func test_kill_player_calls_on_killed_by_entity() -> void:
	var mock_player := MockPlayerForDeath.new()
	mock_player.global_position = Vector3(5, 0, 5)
	add_child(mock_player)

	_entity._kill_player(mock_player)

	assert_false(mock_player.is_alive, "Player should be marked as dead")
	assert_eq(mock_player.death_position, Vector3(5, 0, 5))
	assert_eq(mock_player.killed_by_entity, _entity)

	mock_player.queue_free()


func test_kill_player_clears_hunt_target() -> void:
	var mock_player := MockPlayerForDeath.new()
	add_child(mock_player)

	_entity.set_hunt_target(mock_player)
	assert_eq(_entity.get_hunt_target(), mock_player)

	_entity._kill_player(mock_player)

	assert_null(_entity.get_hunt_target(), "Hunt target should be cleared after kill")

	mock_player.queue_free()


func test_kill_player_resets_target_awareness() -> void:
	var mock_player := MockPlayerForDeath.new()
	add_child(mock_player)

	_entity.set_hunt_target(mock_player)
	_entity.set_aware_of_target(true)

	_entity._kill_player(mock_player)

	assert_false(_entity.is_aware_of_target(), "Should no longer be aware of target after kill")

	mock_player.queue_free()


func test_kill_player_skips_already_dead_player() -> void:
	var signal_received := {"count": 0}
	_entity.player_killed.connect(func(_p): signal_received["count"] += 1)

	var mock_player := MockPlayerForDeath.new()
	mock_player.is_alive = false  # Already dead
	add_child(mock_player)

	_entity._kill_player(mock_player)

	assert_eq(signal_received["count"], 0, "Should not emit signal for already dead player")

	mock_player.queue_free()


func test_kill_player_skips_invalid_player() -> void:
	var signal_received := {"count": 0}
	_entity.player_killed.connect(func(_p): signal_received["count"] += 1)

	# Pass null - should not crash or emit signal
	_entity._kill_player(null)

	assert_eq(signal_received["count"], 0, "Should not emit signal for invalid player")


func test_get_player_id_uses_peer_id() -> void:
	var mock_player := MockPlayerForDeath.new()
	mock_player.peer_id = 456
	add_child(mock_player)

	var player_id := _entity._get_player_id(mock_player)
	assert_eq(player_id, 456)

	mock_player.queue_free()


# --- Echo Visibility Tests ---


class MockEchoObserver:
	extends Node

	func ignores_entity_visibility() -> bool:
		return true


class MockLivingObserver:
	extends Node

	var is_echo := false


func test_entity_is_visible_to_echo_when_not_manifesting() -> void:
	var echo_observer := MockEchoObserver.new()
	add_child(echo_observer)

	# Entity is not visible (dormant, not manifesting)
	_entity._is_visible = false

	var result := _entity.is_visible_to(echo_observer)

	assert_true(result, "Entity should be visible to Echo even when not manifesting")

	echo_observer.queue_free()


func test_entity_is_visible_to_echo_observer_always() -> void:
	var echo_observer := MockEchoObserver.new()
	add_child(echo_observer)

	# Test all states
	for visible in [true, false]:
		_entity._is_visible = visible
		var result := _entity.is_visible_to(echo_observer)
		assert_true(result, "Entity should always be visible to Echo observer")

	echo_observer.queue_free()


func test_entity_not_visible_to_living_when_not_manifesting() -> void:
	var living_observer := MockLivingObserver.new()
	living_observer.is_echo = false
	add_child(living_observer)

	_entity._is_visible = false

	var result := _entity.is_visible_to(living_observer)

	assert_false(result, "Entity should not be visible to living player when not manifesting")

	living_observer.queue_free()


func test_entity_visible_to_living_when_manifesting() -> void:
	var living_observer := MockLivingObserver.new()
	living_observer.is_echo = false
	add_child(living_observer)

	_entity._is_visible = true

	var result := _entity.is_visible_to(living_observer)

	assert_true(result, "Entity should be visible to living player when manifesting")

	living_observer.queue_free()


func test_entity_visible_to_observer_with_is_echo_property() -> void:
	var echo_player := MockLivingObserver.new()
	echo_player.is_echo = true
	add_child(echo_player)

	_entity._is_visible = false

	var result := _entity.is_visible_to(echo_player)

	assert_true(result, "Entity should be visible to player with is_echo=true")

	echo_player.queue_free()


# --- Manifestation Witness Tracking Tests (FW-040a) ---


func test_manifestation_witnesses_empty_initially() -> void:
	var witnesses := _entity.get_manifestation_witnesses()
	assert_eq(witnesses.size(), 0, "Witnesses should be empty initially")


func test_start_manifestation_clears_witnesses() -> void:
	# Manually set some witnesses
	_entity._manifestation_witnesses = [1, 2, 3]
	_entity.change_state(Entity.EntityState.ACTIVE)

	_entity.start_manifestation()

	var witnesses := _entity.get_manifestation_witnesses()
	assert_eq(witnesses.size(), 0, "start_manifestation should clear previous witnesses")


func test_start_manifestation_records_start_position() -> void:
	_entity.global_position = Vector3(10, 0, 20)
	_entity.change_state(Entity.EntityState.ACTIVE)

	_entity.start_manifestation()

	assert_almost_eq(_entity._manifestation_start_position.x, 10.0, 0.01)
	assert_almost_eq(_entity._manifestation_start_position.z, 20.0, 0.01)


func test_end_manifestation_emits_witnessed_signal_with_witnesses() -> void:
	var signal_data := {"received": false, "witness_ids": [], "location": Vector3.ZERO}
	_entity.manifestation_witnessed.connect(
		func(ids: Array, loc: Vector3):
			signal_data["received"] = true
			signal_data["witness_ids"] = ids
			signal_data["location"] = loc
	)

	# Set up manifestation with witnesses
	_entity.global_position = Vector3(5, 0, 10)
	_entity.change_state(Entity.EntityState.ACTIVE)
	_entity.start_manifestation()
	_entity._manifestation_witnesses = [101, 102, 103]  # Simulate witnessed

	_entity.end_manifestation()

	assert_true(signal_data["received"], "manifestation_witnessed should be emitted")
	assert_eq(signal_data["witness_ids"].size(), 3, "Should include all witnesses")
	assert_has(signal_data["witness_ids"], 101)
	assert_has(signal_data["witness_ids"], 102)
	assert_has(signal_data["witness_ids"], 103)


func test_end_manifestation_does_not_emit_without_witnesses() -> void:
	var signal_data := {"received": false}
	_entity.manifestation_witnessed.connect(
		func(_ids: Array, _loc: Vector3):
			signal_data["received"] = true
	)

	_entity.change_state(Entity.EntityState.ACTIVE)
	_entity.start_manifestation()
	# No witnesses added

	_entity.end_manifestation()

	assert_false(signal_data["received"], "Should not emit when no witnesses")


func test_end_manifestation_uses_start_position_in_signal() -> void:
	var signal_data := {"location": Vector3.ZERO}
	_entity.manifestation_witnessed.connect(
		func(_ids: Array, loc: Vector3):
			signal_data["location"] = loc
	)

	_entity.global_position = Vector3(15, 0, 25)
	_entity.change_state(Entity.EntityState.ACTIVE)
	_entity.start_manifestation()

	# Move entity during manifestation
	_entity.global_position = Vector3(100, 0, 100)

	# Add a witness so signal is emitted
	_entity._manifestation_witnesses = [999]
	_entity.end_manifestation()

	# Signal should use the START position, not current position
	assert_almost_eq(signal_data["location"].x, 15.0, 0.01)
	assert_almost_eq(signal_data["location"].z, 25.0, 0.01)


func test_get_manifestation_witnesses_returns_copy() -> void:
	_entity._manifestation_witnesses = [1, 2, 3]

	var witnesses := _entity.get_manifestation_witnesses()
	witnesses.append(4)  # Modify the returned array

	# Original should be unchanged
	assert_eq(_entity._manifestation_witnesses.size(), 3, "Original should be unmodified")


func test_witness_range_constant_exists() -> void:
	assert_eq(Entity.WITNESS_RANGE, 15.0, "Witness range should be 15 meters")


func test_witness_check_interval_constant_exists() -> void:
	assert_eq(Entity.WITNESS_CHECK_INTERVAL, 0.5, "Witness check interval should be 0.5 seconds")
