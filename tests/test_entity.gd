# gdlint: ignore=max-public-methods
extends GutTest
## Tests for Entity base class.

# --- Test Helpers ---

var _entity: Entity = null


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
