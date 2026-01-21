# gdlint: ignore=max-public-methods
extends GutTest
## Integration tests for ReadilyApparentManager.
## Tests manifestation and interaction evidence tracking.

const ManifestationEnumsScript := preload("res://src/evidence/manifestation_enums.gd")

# --- Test Fixtures ---

var _manager: Node
var _player_a: Node3D
var _player_b: Node3D
var _player_c: Node3D


func before_each() -> void:
	# Create manager from script (it's an autoload pattern, no class_name)
	var manager_script := preload("res://src/evidence/readily_apparent_manager.gd")
	_manager = manager_script.new()

	_player_a = Node3D.new()
	_player_b = Node3D.new()
	_player_c = Node3D.new()

	# Add players to scene tree
	add_child(_manager)
	add_child(_player_a)
	add_child(_player_b)
	add_child(_player_c)

	# Set up player positions
	_player_a.position = Vector3(0, 0, 0)
	_player_b.position = Vector3(5, 0, 0)  # 5m away
	_player_c.position = Vector3(25, 0, 0)  # 25m away (out of most ranges)

	# Add players to "players" group for detection
	_player_a.add_to_group("players")
	_player_b.add_to_group("players")
	_player_c.add_to_group("players")


func after_each() -> void:
	_player_a.remove_from_group("players")
	_player_b.remove_from_group("players")
	_player_c.remove_from_group("players")
	_manager.queue_free()
	_player_a.queue_free()
	_player_b.queue_free()
	_player_c.queue_free()


# --- Test: ManifestationEnums ---


func test_manifestation_type_has_five_values() -> void:
	assert_eq(
		ManifestationEnumsScript.ManifestationType.size(), 5, "Should have 5 manifestation types"
	)


func test_interaction_type_has_nine_values() -> void:
	assert_eq(
		ManifestationEnumsScript.InteractionType.size(), 9, "Should have 9 interaction types"
	)


func test_get_manifestation_name_full_body() -> void:
	var name: String = ManifestationEnumsScript.get_manifestation_name(
		ManifestationEnumsScript.ManifestationType.FULL_BODY
	)
	assert_eq(name, "Full Body Apparition")


func test_get_manifestation_name_partial() -> void:
	var name: String = ManifestationEnumsScript.get_manifestation_name(
		ManifestationEnumsScript.ManifestationType.PARTIAL
	)
	assert_eq(name, "Partial Manifestation")


func test_get_interaction_name_door_slam() -> void:
	var name: String = ManifestationEnumsScript.get_interaction_name(
		ManifestationEnumsScript.InteractionType.DOOR_SLAM
	)
	assert_eq(name, "Door Slam")


func test_get_interaction_name_object_throw() -> void:
	var name: String = ManifestationEnumsScript.get_interaction_name(
		ManifestationEnumsScript.InteractionType.OBJECT_THROW
	)
	assert_eq(name, "Object Thrown")


func test_visibility_range_full_body() -> void:
	var range_val: float = ManifestationEnumsScript.get_visibility_range(
		ManifestationEnumsScript.ManifestationType.FULL_BODY
	)
	assert_eq(range_val, 20.0)


func test_visibility_range_partial() -> void:
	var range_val: float = ManifestationEnumsScript.get_visibility_range(
		ManifestationEnumsScript.ManifestationType.PARTIAL
	)
	assert_eq(range_val, 15.0)


func test_audibility_range_door_slam() -> void:
	var range_val: float = ManifestationEnumsScript.get_audibility_range(
		ManifestationEnumsScript.InteractionType.DOOR_SLAM
	)
	assert_eq(range_val, 30.0)


func test_audibility_range_light_flicker() -> void:
	var range_val: float = ManifestationEnumsScript.get_audibility_range(
		ManifestationEnumsScript.InteractionType.LIGHT_FLICKER
	)
	assert_eq(range_val, 5.0)


func test_is_clear_manifestation_full_body() -> void:
	assert_true(ManifestationEnumsScript.is_clear_manifestation(
		ManifestationEnumsScript.ManifestationType.FULL_BODY
	))


func test_is_clear_manifestation_partial() -> void:
	assert_true(ManifestationEnumsScript.is_clear_manifestation(
		ManifestationEnumsScript.ManifestationType.PARTIAL
	))


func test_is_not_clear_manifestation_silhouette() -> void:
	assert_false(ManifestationEnumsScript.is_clear_manifestation(
		ManifestationEnumsScript.ManifestationType.SILHOUETTE
	))


func test_is_audible_interaction_door_slam() -> void:
	assert_true(ManifestationEnumsScript.is_audible_interaction(
		ManifestationEnumsScript.InteractionType.DOOR_SLAM
	))


func test_is_not_audible_interaction_door_open() -> void:
	assert_false(ManifestationEnumsScript.is_audible_interaction(
		ManifestationEnumsScript.InteractionType.DOOR_OPEN
	))


func test_is_persistent_interaction_surface_writing() -> void:
	assert_true(ManifestationEnumsScript.is_persistent_interaction(
		ManifestationEnumsScript.InteractionType.SURFACE_WRITING
	))


func test_is_not_persistent_interaction_door_slam() -> void:
	assert_false(ManifestationEnumsScript.is_persistent_interaction(
		ManifestationEnumsScript.InteractionType.DOOR_SLAM
	))


func test_get_all_manifestations_excludes_none() -> void:
	var manifestations: Array = ManifestationEnumsScript.get_all_manifestations()
	assert_eq(manifestations.size(), 4)
	assert_false(manifestations.has(ManifestationEnumsScript.ManifestationType.NONE))


func test_get_all_interactions_excludes_none() -> void:
	var interactions: Array = ManifestationEnumsScript.get_all_interactions()
	assert_eq(interactions.size(), 8)
	assert_false(interactions.has(ManifestationEnumsScript.InteractionType.NONE))


# --- Test: ReadilyApparentManager - Manifestation Registration ---


func test_register_manifestation_returns_uid() -> void:
	var uid: String = _manager.register_manifestation(
		ManifestationEnumsScript.ManifestationType.PARTIAL,
		Vector3(0, 0, 0)
	)
	assert_true(uid.begins_with("phenomenon_"))


func test_register_manifestation_stores_record() -> void:
	var uid: String = _manager.register_manifestation(
		ManifestationEnumsScript.ManifestationType.PARTIAL,
		Vector3(0, 0, 0)
	)
	var record: Dictionary = _manager.get_phenomenon(uid)
	assert_eq(record["type"], "manifestation")
	assert_eq(record["subtype"], ManifestationEnumsScript.ManifestationType.PARTIAL)


func test_register_manifestation_stores_location() -> void:
	var location := Vector3(10, 5, 20)
	var uid: String = _manager.register_manifestation(
		ManifestationEnumsScript.ManifestationType.FULL_BODY,
		location
	)
	var record: Dictionary = _manager.get_phenomenon(uid)
	assert_eq(record["location"], location)


func test_register_manifestation_stores_timestamp() -> void:
	var before_time := Time.get_ticks_msec() / 1000.0
	var uid: String = _manager.register_manifestation(
		ManifestationEnumsScript.ManifestationType.PARTIAL,
		Vector3.ZERO
	)
	var after_time := Time.get_ticks_msec() / 1000.0
	var record: Dictionary = _manager.get_phenomenon(uid)
	assert_true(record["timestamp"] >= before_time)
	assert_true(record["timestamp"] <= after_time)


func test_register_manifestation_emits_signal() -> void:
	watch_signals(_manager)
	_manager.register_manifestation(
		ManifestationEnumsScript.ManifestationType.PARTIAL,
		Vector3.ZERO
	)
	assert_signal_emitted(_manager, "phenomenon_occurred")


# --- Test: Witness Detection ---


func test_witnesses_detected_in_range() -> void:
	# Partial manifestation range is 15m
	# Player A is at origin, Player B is 5m away - both in range
	var uid: String = _manager.register_manifestation(
		ManifestationEnumsScript.ManifestationType.PARTIAL,
		Vector3(0, 0, 0)
	)
	var record: Dictionary = _manager.get_phenomenon(uid)
	# At least player_a should be in range (at origin)
	assert_true(record["witnesses"].size() >= 1)


func test_distant_player_not_witness() -> void:
	# Player C is 25m away, partial range is 15m
	var uid: String = _manager.register_manifestation(
		ManifestationEnumsScript.ManifestationType.PARTIAL,
		Vector3(0, 0, 0)  # At player_a position
	)
	var record: Dictionary = _manager.get_phenomenon(uid)
	# Player C instance ID should not be in witnesses
	var player_c_id := _player_c.get_instance_id()
	assert_false(record["witnesses"].has(player_c_id))


func test_get_witnesses_in_area() -> void:
	var witnesses: Array = _manager.get_witnesses_in_area(Vector3(0, 0, 0), 10.0)
	# Should find at least player_a (at origin) and player_b (5m away)
	assert_true(witnesses.size() >= 1)


func test_get_witnesses_with_zero_radius() -> void:
	# Query at a location far from all players (no one within 0 radius)
	var witnesses: Array = _manager.get_witnesses_in_area(Vector3(100, 100, 100), 0.0)
	assert_eq(witnesses.size(), 0)


# --- Test: Interaction Registration ---


func test_register_interaction_returns_uid() -> void:
	var uid: String = _manager.register_interaction(
		ManifestationEnumsScript.InteractionType.DOOR_SLAM,
		Vector3(0, 0, 0)
	)
	assert_true(uid.begins_with("phenomenon_"))


func test_register_interaction_stores_type() -> void:
	var uid: String = _manager.register_interaction(
		ManifestationEnumsScript.InteractionType.OBJECT_THROW,
		Vector3.ZERO
	)
	var record: Dictionary = _manager.get_phenomenon(uid)
	assert_eq(record["type"], "interaction")
	assert_eq(record["subtype"], ManifestationEnumsScript.InteractionType.OBJECT_THROW)


func test_register_interaction_stores_affected_object() -> void:
	var uid: String = _manager.register_interaction(
		ManifestationEnumsScript.InteractionType.OBJECT_THROW,
		Vector3.ZERO,
		"vase_001"
	)
	var record: Dictionary = _manager.get_phenomenon(uid)
	assert_eq(record["affected_object"], "vase_001")


func test_register_interaction_emits_signal() -> void:
	watch_signals(_manager)
	_manager.register_interaction(
		ManifestationEnumsScript.InteractionType.DOOR_SLAM,
		Vector3.ZERO
	)
	assert_signal_emitted(_manager, "interaction_occurred")


# --- Test: Phenomenon Reporting ---


func test_report_phenomenon_succeeds() -> void:
	var uid: String = _manager.register_manifestation(
		ManifestationEnumsScript.ManifestationType.PARTIAL,
		Vector3.ZERO
	)
	var result: bool = _manager.report_phenomenon(uid, 12345)
	assert_true(result)


func test_report_updates_record() -> void:
	var uid: String = _manager.register_manifestation(
		ManifestationEnumsScript.ManifestationType.PARTIAL,
		Vector3.ZERO
	)
	_manager.report_phenomenon(uid, 12345)
	var record: Dictionary = _manager.get_phenomenon(uid)
	assert_true(record["reported_by"].has(12345))


func test_report_invalid_uid_fails() -> void:
	var result: bool = _manager.report_phenomenon("invalid_uid", 12345)
	assert_false(result)


func test_report_emits_signal() -> void:
	var uid: String = _manager.register_manifestation(
		ManifestationEnumsScript.ManifestationType.PARTIAL,
		Vector3.ZERO
	)
	watch_signals(_manager)
	_manager.report_phenomenon(uid, 12345)
	assert_signal_emitted(_manager, "phenomenon_reported")


func test_get_report_count() -> void:
	var uid: String = _manager.register_manifestation(
		ManifestationEnumsScript.ManifestationType.PARTIAL,
		Vector3.ZERO
	)
	_manager.report_phenomenon(uid, 12345)
	_manager.report_phenomenon(uid, 67890)
	var count: int = _manager.get_report_count(uid)
	assert_eq(count, 2)


func test_is_multi_witness_report_false() -> void:
	var uid: String = _manager.register_manifestation(
		ManifestationEnumsScript.ManifestationType.PARTIAL,
		Vector3.ZERO
	)
	_manager.report_phenomenon(uid, 12345)
	assert_false(_manager.is_multi_witness_report(uid))


func test_is_multi_witness_report_true() -> void:
	var uid: String = _manager.register_manifestation(
		ManifestationEnumsScript.ManifestationType.PARTIAL,
		Vector3.ZERO
	)
	_manager.report_phenomenon(uid, 12345)
	_manager.report_phenomenon(uid, 67890)
	assert_true(_manager.is_multi_witness_report(uid))


# --- Test: Cultist Omission Tracking ---


func test_was_player_present_true() -> void:
	# Register manifestation at player_a's position
	var uid: String = _manager.register_manifestation(
		ManifestationEnumsScript.ManifestationType.FULL_BODY,  # 20m range
		_player_a.position
	)
	var player_a_id := _player_a.get_instance_id()
	assert_true(_manager.was_player_present(player_a_id, uid))


func test_was_player_present_false_invalid_uid() -> void:
	assert_false(_manager.was_player_present(12345, "invalid_uid"))


func test_get_unreported_phenomena_empty_initially() -> void:
	var unreported: Array = _manager.get_unreported_phenomena(12345)
	assert_eq(unreported.size(), 0)


func test_get_unreported_phenomena_after_witness() -> void:
	# Register manifestation near player_a
	_manager.register_manifestation(
		ManifestationEnumsScript.ManifestationType.FULL_BODY,  # 20m range
		_player_a.position
	)
	var player_a_id := _player_a.get_instance_id()
	var unreported: Array = _manager.get_unreported_phenomena(player_a_id)
	assert_eq(unreported.size(), 1)


func test_get_unreported_phenomena_clears_after_report() -> void:
	var uid: String = _manager.register_manifestation(
		ManifestationEnumsScript.ManifestationType.FULL_BODY,
		_player_a.position
	)
	var player_a_id := _player_a.get_instance_id()
	_manager.report_phenomenon(uid, player_a_id)
	var unreported: Array = _manager.get_unreported_phenomena(player_a_id)
	assert_eq(unreported.size(), 0)


func test_get_omissions_returns_unreported() -> void:
	_manager.register_manifestation(
		ManifestationEnumsScript.ManifestationType.FULL_BODY,
		_player_a.position
	)
	var player_a_id := _player_a.get_instance_id()
	var omissions: Array = _manager.get_omissions_for_player(player_a_id)
	assert_eq(omissions.size(), 1)


func test_get_omissions_excludes_reported() -> void:
	var uid: String = _manager.register_manifestation(
		ManifestationEnumsScript.ManifestationType.FULL_BODY,
		_player_a.position
	)
	var player_a_id := _player_a.get_instance_id()
	_manager.report_phenomenon(uid, player_a_id)
	var omissions: Array = _manager.get_omissions_for_player(player_a_id)
	assert_eq(omissions.size(), 0)


# --- Test: State Management ---


func test_clear_all_phenomena() -> void:
	_manager.register_manifestation(
		ManifestationEnumsScript.ManifestationType.PARTIAL,
		Vector3.ZERO
	)
	_manager.register_interaction(
		ManifestationEnumsScript.InteractionType.DOOR_SLAM,
		Vector3.ZERO
	)
	_manager.clear_all_phenomena()
	var all_phenomena: Dictionary = _manager.get_all_phenomena()
	assert_eq(all_phenomena.size(), 0)


func test_get_all_phenomena() -> void:
	_manager.register_manifestation(
		ManifestationEnumsScript.ManifestationType.PARTIAL,
		Vector3.ZERO
	)
	_manager.register_interaction(
		ManifestationEnumsScript.InteractionType.DOOR_SLAM,
		Vector3(10, 0, 0)
	)
	var all_phenomena: Dictionary = _manager.get_all_phenomena()
	assert_eq(all_phenomena.size(), 2)


func test_get_recent_phenomena_at_location() -> void:
	_manager.register_manifestation(
		ManifestationEnumsScript.ManifestationType.PARTIAL,
		Vector3(0, 0, 0)
	)
	_manager.register_interaction(
		ManifestationEnumsScript.InteractionType.DOOR_SLAM,
		Vector3(100, 0, 0)  # Far away
	)
	var nearby: Array = _manager.get_recent_phenomena_at_location(Vector3.ZERO, 10.0)
	assert_eq(nearby.size(), 1)


# --- Test: Unique ID Generation ---


func test_uid_is_unique() -> void:
	var uid1: String = _manager.register_manifestation(
		ManifestationEnumsScript.ManifestationType.PARTIAL,
		Vector3.ZERO
	)
	var uid2: String = _manager.register_manifestation(
		ManifestationEnumsScript.ManifestationType.PARTIAL,
		Vector3.ZERO
	)
	assert_ne(uid1, uid2)


func test_uid_increments() -> void:
	var uid1: String = _manager.register_manifestation(
		ManifestationEnumsScript.ManifestationType.PARTIAL,
		Vector3.ZERO
	)
	var uid2: String = _manager.register_manifestation(
		ManifestationEnumsScript.ManifestationType.PARTIAL,
		Vector3.ZERO
	)
	# UIDs should have incrementing counter portion
	# Format: phenomenon_[timestamp]_[counter]
	var parts1 := uid1.split("_")
	var parts2 := uid2.split("_")
	var counter1 := int(parts1[2])
	var counter2 := int(parts2[2])
	assert_eq(counter2, counter1 + 1)
