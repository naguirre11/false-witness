extends GutTest
## Tests for HuntDetection class.

# --- Test Helpers ---


# Mock player for testing detection
class MockPlayer:
	extends Node3D

	var equipment_manager: MockEquipmentManager = null
	var voice_active: bool = false

	func _init() -> void:
		equipment_manager = MockEquipmentManager.new()

	func get_equipment_manager() -> MockEquipmentManager:
		return equipment_manager

	func is_voice_active() -> bool:
		return voice_active


class MockEquipmentManager:
	extends RefCounted

	var active_equipment: MockEquipment = null

	func get_active_equipment() -> MockEquipment:
		return active_equipment


class MockEquipment:
	extends RefCounted

	var equipment_type: int = -1


var _entity: Node3D = null
var _player: MockPlayer = null


func before_each() -> void:
	_entity = Node3D.new()
	_entity.name = "TestEntity"
	add_child(_entity)

	_player = MockPlayer.new()
	_player.name = "TestPlayer"
	add_child(_player)


func after_each() -> void:
	if _entity:
		_entity.queue_free()
		_entity = null
	if _player:
		_player.queue_free()
		_player = null


# --- Constants Tests ---


func test_base_detection_radius_is_7_meters() -> void:
	assert_eq(HuntDetection.BASE_DETECTION_RADIUS, 7.0)


func test_electronics_bonus_is_3_meters() -> void:
	assert_eq(HuntDetection.ELECTRONICS_DETECTION_BONUS, 3.0)


func test_voice_bonus_is_5_meters() -> void:
	assert_eq(HuntDetection.VOICE_DETECTION_BONUS, 5.0)


# --- Detection Radius Tests ---


func test_get_detection_radius_returns_base_for_no_modifiers() -> void:
	# Player with no electronics or voice
	var radius := HuntDetection.get_detection_radius(_player)
	assert_eq(radius, 7.0, "Base detection radius should be 7m")


func test_get_detection_radius_adds_electronics_bonus() -> void:
	# Give player an EMF reader (type 0)
	var equipment := MockEquipment.new()
	equipment.equipment_type = 0  # EMF_READER
	_player.equipment_manager.active_equipment = equipment

	var radius := HuntDetection.get_detection_radius(_player)
	assert_eq(radius, 10.0, "Should be base (7) + electronics (3) = 10")


func test_get_detection_radius_adds_voice_bonus() -> void:
	_player.voice_active = true

	var radius := HuntDetection.get_detection_radius(_player)
	assert_eq(radius, 12.0, "Should be base (7) + voice (5) = 12")


func test_get_detection_radius_stacks_bonuses() -> void:
	# Electronics + voice
	var equipment := MockEquipment.new()
	equipment.equipment_type = 0  # EMF_READER
	_player.equipment_manager.active_equipment = equipment
	_player.voice_active = true

	var radius := HuntDetection.get_detection_radius(_player)
	assert_eq(radius, 15.0, "Should be base (7) + electronics (3) + voice (5) = 15")


func test_get_detection_radius_non_electronic_equipment_no_bonus() -> void:
	# Journal (type 2) is not electronic
	var equipment := MockEquipment.new()
	equipment.equipment_type = 2  # JOURNAL
	_player.equipment_manager.active_equipment = equipment

	var radius := HuntDetection.get_detection_radius(_player)
	assert_eq(radius, 7.0, "Non-electronic equipment should not add bonus")


func test_various_electronic_equipment_types_add_bonus() -> void:
	# Test several electronic types
	var electronic_types := [0, 1, 3, 6, 7]  # EMF, Spirit Box, Thermometer, Video, Parabolic

	for eq_type in electronic_types:
		var equipment := MockEquipment.new()
		equipment.equipment_type = eq_type
		_player.equipment_manager.active_equipment = equipment

		var radius := HuntDetection.get_detection_radius(_player)
		assert_eq(radius, 10.0, "Equipment type %d should add electronics bonus" % eq_type)


# --- Range Detection Tests ---


func test_is_player_in_range_returns_true_when_close() -> void:
	_entity.global_position = Vector3(0, 0, 0)
	_player.global_position = Vector3(5, 0, 0)  # 5m away, within 7m base

	var in_range := HuntDetection.is_player_in_range(_entity.global_position, _player)
	assert_true(in_range, "Player 5m away should be in range")


func test_is_player_in_range_returns_false_when_far() -> void:
	_entity.global_position = Vector3(0, 0, 0)
	_player.global_position = Vector3(10, 0, 0)  # 10m away, outside 7m base

	var in_range := HuntDetection.is_player_in_range(_entity.global_position, _player)
	assert_false(in_range, "Player 10m away should be out of range")


func test_is_player_in_range_considers_electronics_modifier() -> void:
	_entity.global_position = Vector3(0, 0, 0)
	_player.global_position = Vector3(9, 0, 0)  # 9m away

	# Without electronics: out of range (7m)
	assert_false(HuntDetection.is_player_in_range(_entity.global_position, _player))

	# With electronics: in range (10m)
	var equipment := MockEquipment.new()
	equipment.equipment_type = 0
	_player.equipment_manager.active_equipment = equipment

	assert_true(HuntDetection.is_player_in_range(_entity.global_position, _player))


func test_is_player_in_range_at_exact_radius() -> void:
	_entity.global_position = Vector3(0, 0, 0)
	_player.global_position = Vector3(7, 0, 0)  # Exactly at 7m

	var in_range := HuntDetection.is_player_in_range(_entity.global_position, _player)
	assert_true(in_range, "Player at exact radius should be in range")


func test_is_player_in_range_handles_invalid_player() -> void:
	var invalid_player: Node = null
	var in_range := HuntDetection.is_player_in_range(_entity.global_position, invalid_player)
	assert_false(in_range, "Invalid player should return false")


# --- Detection Results Tests ---


func test_detect_players_returns_results_for_each_player() -> void:
	var player2 := MockPlayer.new()
	player2.name = "Player2"
	add_child(player2)

	_entity.global_position = Vector3(0, 0, 0)
	_player.global_position = Vector3(5, 0, 0)
	player2.global_position = Vector3(3, 0, 0)

	var players: Array = [_player, player2]
	var results := HuntDetection.detect_players(_entity, players)

	assert_eq(results.size(), 2, "Should have results for both players")

	player2.queue_free()


func test_detect_players_includes_in_range_flag() -> void:
	_entity.global_position = Vector3(0, 0, 0)
	_player.global_position = Vector3(5, 0, 0)  # In range

	var player_far := MockPlayer.new()
	player_far.name = "FarPlayer"
	player_far.global_position = Vector3(20, 0, 0)  # Out of range
	add_child(player_far)

	var results := HuntDetection.detect_players(_entity, [_player, player_far])

	# Find results by checking distance
	var near_result: Dictionary
	var far_result: Dictionary
	for result in results:
		if result.distance < 10:
			near_result = result
		else:
			far_result = result

	assert_true(near_result.in_range, "Near player should be in range")
	assert_false(far_result.in_range, "Far player should be out of range")

	player_far.queue_free()


func test_detect_players_calculates_distance() -> void:
	_entity.global_position = Vector3(0, 0, 0)
	_player.global_position = Vector3(3, 0, 4)  # Distance = 5 (3-4-5 triangle)

	var results := HuntDetection.detect_players(_entity, [_player])

	assert_eq(results.size(), 1)
	assert_almost_eq(results[0].distance, 5.0, 0.01)


func test_detect_players_includes_detection_radius() -> void:
	_entity.global_position = Vector3(0, 0, 0)
	_player.global_position = Vector3(5, 0, 0)

	var results := HuntDetection.detect_players(_entity, [_player])

	assert_eq(results[0].detection_radius, 7.0, "Should include base detection radius")


# --- Find Nearest Player Tests ---


func test_find_nearest_player_returns_closest() -> void:
	var player2 := MockPlayer.new()
	player2.name = "Player2"
	add_child(player2)

	_entity.global_position = Vector3(0, 0, 0)
	_player.global_position = Vector3(5, 0, 0)
	player2.global_position = Vector3(3, 0, 0)  # Closer

	var result := HuntDetection.find_nearest_player(_entity, [_player, player2])

	assert_eq(result.player, player2, "Should find the closer player")
	assert_almost_eq(result.distance, 3.0, 0.01)

	player2.queue_free()


func test_find_nearest_player_returns_empty_when_none_in_range() -> void:
	_entity.global_position = Vector3(0, 0, 0)
	_player.global_position = Vector3(100, 0, 0)  # Way out of range

	var result := HuntDetection.find_nearest_player(_entity, [_player])

	assert_true(result.is_empty(), "Should return empty when no players in range")


func test_find_nearest_player_returns_empty_for_empty_array() -> void:
	var result := HuntDetection.find_nearest_player(_entity, [])
	assert_true(result.is_empty())


func test_find_nearest_player_includes_has_line_of_sight_field() -> void:
	_entity.global_position = Vector3(0, 0, 0)
	_player.global_position = Vector3(5, 0, 0)

	# Without space_state, has_line_of_sight should be false
	var result := HuntDetection.find_nearest_player(_entity, [_player], null)

	assert_has(result, "has_line_of_sight")
	assert_false(result.has_line_of_sight, "Without space_state, should be false")
