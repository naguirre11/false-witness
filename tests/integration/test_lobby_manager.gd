extends GutTest
## Tests for LobbyManager - lobby system with player slots, ready states, and host controls.

const LobbySlot = preload("res://src/core/networking/lobby_slot.gd")


# =============================================================================
# TEST FIXTURES
# =============================================================================


var _lobby_manager: Node


func before_each() -> void:
	_lobby_manager = preload("res://src/core/lobby_manager.gd").new()
	add_child(_lobby_manager)
	# Don't call _ready since it would try to connect to autoloads


func after_each() -> void:
	if _lobby_manager and is_instance_valid(_lobby_manager):
		_lobby_manager.queue_free()
		_lobby_manager = null


# =============================================================================
# LOBBY SLOT TESTS
# =============================================================================


func test_lobby_slot_initialization() -> void:
	var slot: LobbySlot = LobbySlot.new(2, 12345, "TestPlayer", true)

	assert_eq(slot.slot_index, 2, "Slot index should be 2")
	assert_eq(slot.peer_id, 12345, "Peer ID should match")
	assert_eq(slot.username, "TestPlayer", "Username should match")
	assert_true(slot.is_host, "Should be host")
	assert_false(slot.is_ready, "Should not be ready by default")
	assert_eq(slot.join_order, 0, "Join order should default to 0")


func test_lobby_slot_default_initialization() -> void:
	var slot: LobbySlot = LobbySlot.new()

	assert_eq(slot.slot_index, 0, "Slot index should default to 0")
	assert_eq(slot.peer_id, LobbySlot.EMPTY_PEER_ID, "Peer ID should be empty")
	assert_eq(slot.username, "", "Username should be empty")
	assert_false(slot.is_host, "Should not be host")
	assert_false(slot.is_ready, "Should not be ready")


func test_lobby_slot_is_occupied() -> void:
	var slot: LobbySlot = LobbySlot.new(0, 0)
	assert_false(slot.is_occupied(), "Empty slot should not be occupied")
	assert_true(slot.is_empty(), "Empty slot should be empty")

	slot.peer_id = 12345
	assert_true(slot.is_occupied(), "Slot with peer should be occupied")
	assert_false(slot.is_empty(), "Slot with peer should not be empty")


func test_lobby_slot_clear() -> void:
	var slot: LobbySlot = LobbySlot.new(3, 12345, "TestPlayer", true)
	slot.is_ready = true
	slot.join_order = 5
	slot.connection_quality = LobbySlot.ConnectionQuality.GOOD

	slot.clear()

	assert_eq(slot.peer_id, LobbySlot.EMPTY_PEER_ID, "Peer ID should be cleared")
	assert_eq(slot.username, "", "Username should be cleared")
	assert_false(slot.is_ready, "Ready should be cleared")
	assert_false(slot.is_host, "Host should be cleared")
	assert_eq(slot.join_order, 0, "Join order should be cleared")
	assert_eq(
		slot.connection_quality, LobbySlot.ConnectionQuality.UNKNOWN, "Quality should be cleared"
	)
	# slot_index should remain unchanged
	assert_eq(slot.slot_index, 3, "Slot index should remain unchanged")


func test_lobby_slot_serialization() -> void:
	var slot: LobbySlot = LobbySlot.new(2, 12345, "TestPlayer", true)
	slot.is_ready = true
	slot.join_order = 3
	slot.connection_quality = LobbySlot.ConnectionQuality.EXCELLENT

	var data: Dictionary = slot.to_dict()

	assert_eq(data.slot_index, 2, "Serialized slot_index should match")
	assert_eq(data.peer_id, 12345, "Serialized peer_id should match")
	assert_eq(data.username, "TestPlayer", "Serialized username should match")
	assert_true(data.is_host, "Serialized is_host should match")
	assert_true(data.is_ready, "Serialized is_ready should match")
	assert_eq(data.join_order, 3, "Serialized join_order should match")
	assert_eq(
		data.connection_quality, LobbySlot.ConnectionQuality.EXCELLENT, "Serialized quality"
	)


func test_lobby_slot_deserialization() -> void:
	var slot: LobbySlot = LobbySlot.new()
	var data: Dictionary = {
		"slot_index": 4,
		"peer_id": 99999,
		"username": "DeserializedPlayer",
		"is_host": false,
		"is_ready": true,
		"join_order": 7,
		"connection_quality": LobbySlot.ConnectionQuality.FAIR,
	}

	slot.from_dict(data)

	assert_eq(slot.slot_index, 4, "Deserialized slot_index should match")
	assert_eq(slot.peer_id, 99999, "Deserialized peer_id should match")
	assert_eq(slot.username, "DeserializedPlayer", "Deserialized username should match")
	assert_false(slot.is_host, "Deserialized is_host should match")
	assert_true(slot.is_ready, "Deserialized is_ready should match")
	assert_eq(slot.join_order, 7, "Deserialized join_order should match")
	assert_eq(
		slot.connection_quality, LobbySlot.ConnectionQuality.FAIR, "Deserialized quality"
	)


func test_lobby_slot_serialization_roundtrip() -> void:
	var original: LobbySlot = LobbySlot.new(5, 77777, "RoundtripPlayer", false)
	original.is_ready = true
	original.join_order = 10
	original.connection_quality = LobbySlot.ConnectionQuality.GOOD

	var data: Dictionary = original.to_dict()
	var restored: LobbySlot = LobbySlot.new()
	restored.from_dict(data)

	assert_eq(restored.slot_index, original.slot_index, "Roundtrip slot_index should match")
	assert_eq(restored.peer_id, original.peer_id, "Roundtrip peer_id should match")
	assert_eq(restored.username, original.username, "Roundtrip username should match")
	assert_eq(restored.is_host, original.is_host, "Roundtrip is_host should match")
	assert_eq(restored.is_ready, original.is_ready, "Roundtrip is_ready should match")
	assert_eq(restored.join_order, original.join_order, "Roundtrip join_order should match")
	assert_eq(
		restored.connection_quality, original.connection_quality, "Roundtrip quality"
	)


func test_lobby_slot_quality_to_string() -> void:
	assert_eq(
		LobbySlot.quality_to_string(LobbySlot.ConnectionQuality.UNKNOWN),
		"Unknown",
		"UNKNOWN should stringify correctly"
	)
	assert_eq(
		LobbySlot.quality_to_string(LobbySlot.ConnectionQuality.POOR),
		"Poor",
		"POOR should stringify correctly"
	)
	assert_eq(
		LobbySlot.quality_to_string(LobbySlot.ConnectionQuality.FAIR),
		"Fair",
		"FAIR should stringify correctly"
	)
	assert_eq(
		LobbySlot.quality_to_string(LobbySlot.ConnectionQuality.GOOD),
		"Good",
		"GOOD should stringify correctly"
	)
	assert_eq(
		LobbySlot.quality_to_string(LobbySlot.ConnectionQuality.EXCELLENT),
		"Excellent",
		"EXCELLENT should stringify correctly"
	)


func test_lobby_slot_partial_deserialization() -> void:
	var slot: LobbySlot = LobbySlot.new(1, 11111, "OriginalName", true)
	slot.is_ready = true
	slot.join_order = 5

	# Only update some fields
	var partial: Dictionary = {
		"is_ready": false,
		"connection_quality": LobbySlot.ConnectionQuality.GOOD,
	}

	slot.from_dict(partial)

	# Updated fields
	assert_false(slot.is_ready, "is_ready should be updated")
	assert_eq(slot.connection_quality, LobbySlot.ConnectionQuality.GOOD, "Quality should be updated")

	# Unchanged fields
	assert_eq(slot.slot_index, 1, "slot_index should remain unchanged")
	assert_eq(slot.peer_id, 11111, "peer_id should remain unchanged")
	assert_eq(slot.username, "OriginalName", "username should remain unchanged")
	assert_true(slot.is_host, "is_host should remain unchanged")
	assert_eq(slot.join_order, 5, "join_order should remain unchanged")


# =============================================================================
# LOBBY MANAGER CONSTANTS TESTS
# =============================================================================


func test_lobby_manager_constants() -> void:
	assert_eq(_lobby_manager.MIN_PLAYERS, 4, "Minimum players should be 4")
	assert_eq(_lobby_manager.MAX_PLAYERS, 6, "Maximum players should be 6")
	assert_gt(_lobby_manager.LOBBY_SYNC_INTERVAL, 0.0, "Sync interval should be positive")


# =============================================================================
# LOBBY MANAGER STATE TESTS
# =============================================================================


func test_lobby_manager_initial_state() -> void:
	assert_false(_lobby_manager.is_in_lobby, "Should not be in lobby initially")
	assert_false(_lobby_manager.is_lobby_host, "Should not be host initially")
	assert_eq(_lobby_manager.local_slot_index, -1, "Local slot should be -1 initially")
	assert_eq(_lobby_manager.host_peer_id, 0, "Host peer ID should be 0 initially")
	assert_false(_lobby_manager.game_started, "Game should not be started initially")


func test_lobby_manager_signals_exist() -> void:
	assert_true(_lobby_manager.has_signal("lobby_created"), "Should have lobby_created")
	assert_true(_lobby_manager.has_signal("lobby_joined"), "Should have lobby_joined")
	assert_true(_lobby_manager.has_signal("lobby_left"), "Should have lobby_left")
	assert_true(_lobby_manager.has_signal("lobby_closed"), "Should have lobby_closed")
	assert_true(_lobby_manager.has_signal("player_slot_updated"), "Should have player_slot_updated")
	assert_true(_lobby_manager.has_signal("player_ready_changed"), "Should have ready_changed")
	assert_true(_lobby_manager.has_signal("all_players_ready"), "Should have all_players_ready")
	assert_true(_lobby_manager.has_signal("host_changed"), "Should have host_changed")
	assert_true(_lobby_manager.has_signal("game_starting"), "Should have game_starting")
	assert_true(_lobby_manager.has_signal("lobby_state_updated"), "Should have state_updated")
	assert_true(_lobby_manager.has_signal("player_kicked"), "Should have player_kicked")


func test_get_slots_returns_correct_count() -> void:
	# Need to initialize slots first - call _initialize_slots directly
	_lobby_manager._initialize_slots()

	var slots: Array = _lobby_manager.get_slots()
	assert_eq(slots.size(), _lobby_manager.MAX_PLAYERS, "Should have MAX_PLAYERS slots")


func test_get_player_count_empty_lobby() -> void:
	_lobby_manager._initialize_slots()

	var count: int = _lobby_manager.get_player_count()
	assert_eq(count, 0, "Empty lobby should have 0 players")


func test_are_all_players_ready_empty_lobby() -> void:
	_lobby_manager._initialize_slots()

	var all_ready: bool = _lobby_manager.are_all_players_ready()
	assert_false(all_ready, "Empty lobby should not report all ready")


func test_can_start_game_returns_false_when_not_host() -> void:
	_lobby_manager._initialize_slots()
	_lobby_manager.is_lobby_host = false

	assert_false(_lobby_manager.can_start_game(), "Non-host cannot start game")


func test_can_start_game_returns_false_with_insufficient_players() -> void:
	_lobby_manager._initialize_slots()
	_lobby_manager.is_lobby_host = true

	# Add fewer than MIN_PLAYERS
	var slots = _lobby_manager._slots
	slots[0].peer_id = 1
	slots[0].is_ready = true
	slots[1].peer_id = 2
	slots[1].is_ready = true

	assert_false(_lobby_manager.can_start_game(), "Cannot start with fewer than MIN_PLAYERS")


func test_can_start_game_returns_false_when_not_all_ready() -> void:
	_lobby_manager._initialize_slots()
	_lobby_manager.is_lobby_host = true

	# Add MIN_PLAYERS but not all ready
	var slots = _lobby_manager._slots
	for i in range(_lobby_manager.MIN_PLAYERS):
		slots[i].peer_id = i + 1
		slots[i].is_ready = (i < 3)  # Only first 3 are ready

	assert_false(_lobby_manager.can_start_game(), "Cannot start when not all ready")


func test_can_start_game_returns_true_when_conditions_met() -> void:
	_lobby_manager._initialize_slots()
	_lobby_manager.is_lobby_host = true

	# Add MIN_PLAYERS, all ready
	var slots = _lobby_manager._slots
	for i in range(_lobby_manager.MIN_PLAYERS):
		slots[i].peer_id = i + 1
		slots[i].is_ready = true

	assert_true(_lobby_manager.can_start_game(), "Should be able to start when all conditions met")


func test_is_late_join_prevented() -> void:
	_lobby_manager.game_started = false
	assert_false(_lobby_manager.is_late_join_prevented(), "Late join not prevented before start")

	_lobby_manager.game_started = true
	assert_true(_lobby_manager.is_late_join_prevented(), "Late join prevented after start")


func test_get_slot_by_peer_id_returns_correct_slot() -> void:
	_lobby_manager._initialize_slots()

	var slots = _lobby_manager._slots
	slots[2].peer_id = 12345
	slots[2].username = "TestPlayer"

	var found: LobbySlot = _lobby_manager.get_slot_by_peer_id(12345)
	assert_not_null(found, "Should find slot by peer ID")
	assert_eq(found.slot_index, 2, "Should return correct slot")
	assert_eq(found.username, "TestPlayer", "Should have correct username")


func test_get_slot_by_peer_id_returns_null_for_missing() -> void:
	_lobby_manager._initialize_slots()

	var found: LobbySlot = _lobby_manager.get_slot_by_peer_id(99999)
	assert_null(found, "Should return null for non-existent peer")


func test_get_local_slot_returns_null_when_not_in_lobby() -> void:
	_lobby_manager._initialize_slots()
	_lobby_manager.local_slot_index = -1

	var slot: LobbySlot = _lobby_manager.get_local_slot()
	assert_null(slot, "Should return null when not assigned to slot")


func test_get_local_slot_returns_correct_slot() -> void:
	_lobby_manager._initialize_slots()
	_lobby_manager.local_slot_index = 3

	var slots = _lobby_manager._slots
	slots[3].peer_id = 77777
	slots[3].username = "LocalPlayer"

	var slot: LobbySlot = _lobby_manager.get_local_slot()
	assert_not_null(slot, "Should return local slot")
	assert_eq(slot.username, "LocalPlayer", "Should have correct username")


# =============================================================================
# INTERNAL METHOD TESTS
# =============================================================================


func test_add_player_to_slot() -> void:
	_lobby_manager._initialize_slots()

	var slot_idx: int = _lobby_manager._add_player_to_slot(12345, "NewPlayer", false)

	assert_eq(slot_idx, 0, "Should assign to first empty slot")
	var slot: LobbySlot = _lobby_manager._slots[0]
	assert_eq(slot.peer_id, 12345, "Peer ID should be set")
	assert_eq(slot.username, "NewPlayer", "Username should be set")
	assert_false(slot.is_host, "Should not be host")
	assert_false(slot.is_ready, "Should not be ready initially")


func test_add_multiple_players_to_slots() -> void:
	_lobby_manager._initialize_slots()

	var slot1: int = _lobby_manager._add_player_to_slot(1, "Player1", true)
	var slot2: int = _lobby_manager._add_player_to_slot(2, "Player2", false)
	var slot3: int = _lobby_manager._add_player_to_slot(3, "Player3", false)

	assert_eq(slot1, 0, "First player should be in slot 0")
	assert_eq(slot2, 1, "Second player should be in slot 1")
	assert_eq(slot3, 2, "Third player should be in slot 2")

	assert_eq(_lobby_manager.get_player_count(), 3, "Should have 3 players")


func test_add_player_to_full_lobby_returns_negative() -> void:
	_lobby_manager._initialize_slots()

	# Fill all slots
	for i in range(_lobby_manager.MAX_PLAYERS):
		_lobby_manager._add_player_to_slot(i + 1, "Player%d" % (i + 1), i == 0)

	# Try to add one more
	var result: int = _lobby_manager._add_player_to_slot(999, "Overflow", false)
	assert_eq(result, -1, "Should return -1 when lobby is full")


func test_remove_player_from_slot() -> void:
	_lobby_manager._initialize_slots()

	_lobby_manager._add_player_to_slot(12345, "TestPlayer", false)
	assert_eq(_lobby_manager.get_player_count(), 1, "Should have 1 player")

	_lobby_manager._remove_player_from_slot(12345)
	assert_eq(_lobby_manager.get_player_count(), 0, "Should have 0 players after removal")


func test_join_order_increments() -> void:
	_lobby_manager._initialize_slots()

	_lobby_manager._add_player_to_slot(1, "First", true)
	_lobby_manager._add_player_to_slot(2, "Second", false)
	_lobby_manager._add_player_to_slot(3, "Third", false)

	assert_eq(_lobby_manager._slots[0].join_order, 0, "First player should have join_order 0")
	assert_eq(_lobby_manager._slots[1].join_order, 1, "Second player should have join_order 1")
	assert_eq(_lobby_manager._slots[2].join_order, 2, "Third player should have join_order 2")


func test_get_slots_as_array() -> void:
	_lobby_manager._initialize_slots()

	_lobby_manager._add_player_to_slot(111, "Player1", true)
	_lobby_manager._add_player_to_slot(222, "Player2", false)

	var arr: Array = _lobby_manager._get_slots_as_array()

	assert_eq(arr.size(), _lobby_manager.MAX_PLAYERS, "Should return all slots")
	assert_eq(arr[0].peer_id, 111, "First slot should have correct peer_id")
	assert_eq(arr[1].peer_id, 222, "Second slot should have correct peer_id")
	assert_eq(arr[2].peer_id, 0, "Third slot should be empty")


func test_host_migration_selects_lowest_join_order() -> void:
	_lobby_manager._initialize_slots()
	_lobby_manager.is_in_lobby = true

	# Add players with different join orders
	_lobby_manager._add_player_to_slot(1, "Host", true)  # join_order 0
	_lobby_manager._add_player_to_slot(2, "Second", false)  # join_order 1
	_lobby_manager._add_player_to_slot(3, "Third", false)  # join_order 2

	# Host leaves
	_lobby_manager._remove_player_from_slot(1)

	# Check that the player with lowest remaining join_order became host
	var new_host: LobbySlot = _lobby_manager.get_slot_by_peer_id(2)
	assert_true(new_host.is_host, "Player with lowest join_order should become host")
	assert_eq(_lobby_manager.host_peer_id, 2, "host_peer_id should be updated")


func test_reset_lobby_state() -> void:
	_lobby_manager._initialize_slots()
	_lobby_manager.is_in_lobby = true
	_lobby_manager.is_lobby_host = true
	_lobby_manager.local_slot_index = 2
	_lobby_manager.host_peer_id = 12345
	_lobby_manager.game_started = true
	_lobby_manager._next_join_order = 5

	_lobby_manager._reset_lobby_state()

	assert_false(_lobby_manager.is_in_lobby, "is_in_lobby should be reset")
	assert_false(_lobby_manager.is_lobby_host, "is_lobby_host should be reset")
	assert_eq(_lobby_manager.local_slot_index, -1, "local_slot_index should be reset")
	assert_eq(_lobby_manager.host_peer_id, 0, "host_peer_id should be reset")
	assert_false(_lobby_manager.game_started, "game_started should be reset")
	assert_eq(_lobby_manager._next_join_order, 0, "_next_join_order should be reset")


# =============================================================================
# PACKET HANDLING TESTS
# =============================================================================


func test_handle_full_state_updates_slots() -> void:
	_lobby_manager._initialize_slots()
	_lobby_manager.is_in_lobby = true

	# Simulate receiving full state from host
	var slots_data: Array = []
	for i in range(_lobby_manager.MAX_PLAYERS):
		var slot_dict: Dictionary = {
			"slot_index": i,
			"peer_id": (i + 1) if i < 3 else 0,
			"username": "Player%d" % (i + 1) if i < 3 else "",
			"is_ready": i == 0 or i == 1,
			"is_host": i == 0,
			"join_order": i if i < 3 else 0,
			"connection_quality": LobbySlot.ConnectionQuality.GOOD,
		}
		slots_data.append(slot_dict)

	var packet: Dictionary = {
		"action": "full_state",
		"slots": slots_data,
		"host_peer_id": 1,
		"game_started": false,
	}

	_lobby_manager._handle_full_state(packet)

	assert_eq(_lobby_manager.get_player_count(), 3, "Should have 3 players")
	assert_eq(_lobby_manager.host_peer_id, 1, "Host peer ID should be set")
	assert_false(_lobby_manager.game_started, "game_started should be set")


func test_handle_ready_changed_updates_slot() -> void:
	_lobby_manager._initialize_slots()
	_lobby_manager.is_in_lobby = true
	_lobby_manager._add_player_to_slot(12345, "TestPlayer", false)

	var packet: Dictionary = {
		"action": "ready_changed",
		"peer_id": 12345,
		"is_ready": true,
	}

	_lobby_manager._handle_ready_changed(12345, packet)

	var slot: LobbySlot = _lobby_manager.get_slot_by_peer_id(12345)
	assert_true(slot.is_ready, "Player should be ready after handling ready_changed")


func test_handle_game_starting_sets_game_started() -> void:
	_lobby_manager._initialize_slots()
	_lobby_manager.is_in_lobby = true
	_lobby_manager.game_started = false

	_lobby_manager._handle_game_starting()

	assert_true(_lobby_manager.game_started, "game_started should be true after handling")
