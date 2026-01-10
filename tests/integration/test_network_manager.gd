extends GutTest
## Unit tests for NetworkManager and PlayerData.
##
## Note: Full networking tests require multiple processes.
## These tests focus on state management and serialization.

const PlayerData = preload("res://src/core/networking/player_data.gd")


# =============================================================================
# PlayerData Tests
# =============================================================================


func test_player_data_initialization() -> void:
	var player: PlayerData = PlayerData.new(12345, "TestPlayer", true)

	assert_eq(player.peer_id, 12345, "Peer ID should match")
	assert_eq(player.username, "TestPlayer", "Username should match")
	assert_true(player.is_host, "Should be host")
	assert_true(player.is_alive, "Should start alive")
	assert_false(player.is_echo, "Should not be echo")
	assert_false(player.is_cultist, "Should not be cultist")


func test_player_data_default_initialization() -> void:
	var player: PlayerData = PlayerData.new()

	assert_eq(player.peer_id, 0, "Default peer ID should be 0")
	assert_eq(player.username, "", "Default username should be empty")
	assert_false(player.is_host, "Default should not be host")


func test_player_data_transform_serialization() -> void:
	var player: PlayerData = PlayerData.new(100, "Player1", false)
	player.position = Vector3(10.5, 2.0, -5.0)
	player.rotation = Vector3(0.0, 1.57, 0.0)
	player.velocity = Vector3(1.0, 0.0, 1.0)

	var transform_data: Dictionary = player.get_transform_data()

	assert_eq(transform_data.peer_id, 100, "Transform data should contain peer ID")
	assert_true(transform_data.has("position"), "Should have position")
	assert_true(transform_data.has("rotation"), "Should have rotation")
	assert_true(transform_data.has("velocity"), "Should have velocity")


func test_player_data_transform_round_trip() -> void:
	var original: PlayerData = PlayerData.new(200, "Original", false)
	original.position = Vector3(15.0, 3.5, -10.0)
	original.rotation = Vector3(0.1, 0.2, 0.3)
	original.velocity = Vector3(2.0, -1.0, 0.5)

	var transform_data: Dictionary = original.get_transform_data()

	var restored: PlayerData = PlayerData.new(200, "Restored", false)
	restored.apply_transform_data(transform_data)

	assert_eq(restored.position, original.position, "Position should survive round trip")
	assert_eq(restored.rotation, original.rotation, "Rotation should survive round trip")
	assert_eq(restored.velocity, original.velocity, "Velocity should survive round trip")


func test_player_data_full_serialization() -> void:
	var player: PlayerData = PlayerData.new(300, "FullTest", true)
	player.position = Vector3(1.0, 2.0, 3.0)
	player.rotation = Vector3(0.5, 1.0, 0.0)
	player.velocity = Vector3(0.0, 0.0, 5.0)
	player.is_alive = false
	player.is_echo = true
	player.current_equipment = "emf_reader"

	var data: Dictionary = player.to_dict()

	assert_eq(data.peer_id, 300, "Should serialize peer_id")
	assert_eq(data.username, "FullTest", "Should serialize username")
	assert_true(data.is_host, "Should serialize is_host")
	assert_false(data.is_alive, "Should serialize is_alive")
	assert_true(data.is_echo, "Should serialize is_echo")
	assert_eq(data.current_equipment, "emf_reader", "Should serialize equipment")


func test_player_data_full_round_trip() -> void:
	var original: PlayerData = PlayerData.new(400, "RoundTrip", true)
	original.position = Vector3(5.0, 10.0, 15.0)
	original.rotation = Vector3(1.0, 2.0, 3.0)
	original.velocity = Vector3(0.5, 0.5, 0.5)
	original.is_alive = false
	original.is_echo = true
	original.current_equipment = "thermometer"

	var data: Dictionary = original.to_dict()

	var restored: PlayerData = PlayerData.new()
	restored.from_dict(data)

	assert_eq(restored.peer_id, original.peer_id, "peer_id should survive")
	assert_eq(restored.username, original.username, "username should survive")
	assert_eq(restored.is_host, original.is_host, "is_host should survive")
	assert_eq(restored.position, original.position, "position should survive")
	assert_eq(restored.rotation, original.rotation, "rotation should survive")
	assert_eq(restored.velocity, original.velocity, "velocity should survive")
	assert_eq(restored.is_alive, original.is_alive, "is_alive should survive")
	assert_eq(restored.is_echo, original.is_echo, "is_echo should survive")
	assert_eq(restored.current_equipment, original.current_equipment, "equipment should survive")


func test_player_data_reset_for_new_round() -> void:
	var player: PlayerData = PlayerData.new(500, "ResetTest", false)
	player.position = Vector3(100.0, 50.0, 25.0)
	player.rotation = Vector3(1.0, 1.0, 1.0)
	player.velocity = Vector3(10.0, 5.0, 2.0)
	player.is_alive = false
	player.is_echo = true
	player.is_cultist = true
	player.current_equipment = "spirit_box"

	player.reset_for_new_round()

	assert_true(player.is_alive, "Should be alive after reset")
	assert_false(player.is_echo, "Should not be echo after reset")
	assert_false(player.is_cultist, "Should not be cultist after reset")
	assert_eq(player.current_equipment, "", "Equipment should be cleared")
	assert_eq(player.position, Vector3.ZERO, "Position should be zero")
	assert_eq(player.rotation, Vector3.ZERO, "Rotation should be zero")
	assert_eq(player.velocity, Vector3.ZERO, "Velocity should be zero")
	# Identity fields should persist
	assert_eq(player.peer_id, 500, "peer_id should persist")
	assert_eq(player.username, "ResetTest", "username should persist")


func test_player_data_partial_dict_application() -> void:
	var player: PlayerData = PlayerData.new(600, "Partial", false)
	player.position = Vector3(1.0, 1.0, 1.0)
	player.is_alive = true

	# Apply partial data (only some fields)
	player.from_dict({
		"is_alive": false,
		"is_echo": true
	})

	assert_false(player.is_alive, "is_alive should update")
	assert_true(player.is_echo, "is_echo should update")
	# Unchanged fields should remain
	assert_eq(player.peer_id, 600, "peer_id should remain")
	assert_eq(player.username, "Partial", "username should remain")


# =============================================================================
# NetworkManager State Tests
# =============================================================================


func test_network_manager_initial_state() -> void:
	# NetworkManager is an autoload, check its initial state
	var state: int = NetworkManager.get_connection_state()
	var backend: int = NetworkManager.get_backend()

	# Should start disconnected with no backend
	# Note: May have STEAM backend if Steam is running
	assert_true(
		state == NetworkManager.ConnectionState.DISCONNECTED or
		backend != NetworkManager.NetworkBackend.NONE,
		"Should be disconnected or have backend initialized"
	)


func test_network_manager_has_expected_signals() -> void:
	# Verify signals exist on NetworkManager
	assert_true(
		NetworkManager.has_signal("connection_state_changed"),
		"Should have connection_state_changed signal"
	)
	assert_true(
		NetworkManager.has_signal("lobby_created"),
		"Should have lobby_created signal"
	)
	assert_true(
		NetworkManager.has_signal("lobby_joined"),
		"Should have lobby_joined signal"
	)
	assert_true(
		NetworkManager.has_signal("lobby_join_failed"),
		"Should have lobby_join_failed signal"
	)
	assert_true(
		NetworkManager.has_signal("player_joined_network"),
		"Should have player_joined_network signal"
	)
	assert_true(
		NetworkManager.has_signal("player_left_network"),
		"Should have player_left_network signal"
	)
	assert_true(
		NetworkManager.has_signal("player_data_updated"),
		"Should have player_data_updated signal"
	)
	assert_true(
		NetworkManager.has_signal("packet_received"),
		"Should have packet_received signal"
	)


func test_network_manager_connection_state_enum() -> void:
	# Verify ConnectionState enum values exist
	assert_eq(
		NetworkManager.ConnectionState.DISCONNECTED, 0,
		"DISCONNECTED should be 0"
	)
	assert_eq(
		NetworkManager.ConnectionState.CONNECTING, 1,
		"CONNECTING should be 1"
	)
	assert_eq(
		NetworkManager.ConnectionState.CONNECTED, 2,
		"CONNECTED should be 2"
	)
	assert_eq(
		NetworkManager.ConnectionState.HOST, 3,
		"HOST should be 3"
	)


func test_network_manager_backend_enum() -> void:
	# Verify NetworkBackend enum values exist
	assert_eq(NetworkManager.NetworkBackend.NONE, 0, "NONE should be 0")
	assert_eq(NetworkManager.NetworkBackend.STEAM, 1, "STEAM should be 1")
	assert_eq(NetworkManager.NetworkBackend.ENET, 2, "ENET should be 2")


func test_network_manager_constants() -> void:
	# Verify important constants
	assert_eq(NetworkManager.MAX_LOBBY_MEMBERS, 6, "Max lobby should be 6")
	assert_eq(NetworkManager.DEFAULT_PORT, 7777, "Default port should be 7777")
	assert_gt(NetworkManager.SYNC_INTERVAL, 0.0, "Sync interval should be positive")


func test_network_manager_get_players_returns_dictionary() -> void:
	var players: Dictionary = NetworkManager.get_players()
	assert_typeof(players, TYPE_DICTIONARY, "get_players should return Dictionary")


func test_network_manager_is_game_host_returns_bool() -> void:
	var result: bool = NetworkManager.is_game_host()
	assert_typeof(result, TYPE_BOOL, "is_game_host should return bool")


func test_network_manager_get_player_with_invalid_id() -> void:
	var player: PlayerData = NetworkManager.get_player(-999)
	assert_null(player, "Invalid peer ID should return null")


func test_network_manager_send_position_update_without_connection() -> void:
	# Should not crash when called without active connection
	NetworkManager.send_position_update(
		Vector3(1.0, 2.0, 3.0),
		Vector3(0.0, 1.0, 0.0),
		Vector3(0.0, 0.0, 0.0)
	)
	# Test passes if no error occurs
	assert_true(true, "send_position_update should not crash without connection")
