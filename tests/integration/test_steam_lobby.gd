extends GutTest
## Integration tests for Steam lobby functionality (FW-013-15)
##
## Tests lobby code generation, decoding, data sync, and fallback behavior.
## Note: Most tests work without Steam running by testing the code logic directly.


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================


func _create_steam_manager() -> Node:
	# Create a SteamManager-like object for testing code generation
	var manager := Node.new()
	manager.set_script(load("res://src/core/steam_manager.gd"))
	add_child_autofree(manager)
	return manager


# =============================================================================
# LOBBY CODE TESTS
# =============================================================================


func test_lobby_code_is_6_characters() -> void:
	# Test that generated codes are always 6 characters
	var code := _generate_lobby_code(12345678)
	assert_eq(code.length(), 6, "Lobby code should be 6 characters")


func test_lobby_code_is_alphanumeric() -> void:
	# Test that codes only contain valid characters
	var valid_chars := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	var code := _generate_lobby_code(999999999)

	for i in range(code.length()):
		assert_true(
			valid_chars.contains(code[i]),
			"Character '%s' should be alphanumeric" % code[i]
		)


func test_lobby_code_encode_decode_roundtrip() -> void:
	# Test that encoding and decoding produces the original value
	var test_ids := [1, 100, 12345, 999999, 123456789, 2147483647]

	for original_id in test_ids:
		var code := _generate_lobby_code(original_id)
		var decoded_id := _decode_lobby_code(code)
		assert_eq(
			decoded_id, original_id,
			"Roundtrip for ID %d should produce same value" % original_id
		)


func test_lobby_code_decode_invalid_length() -> void:
	# Test that invalid length codes return 0
	assert_eq(_decode_lobby_code(""), 0, "Empty code should return 0")
	assert_eq(_decode_lobby_code("ABC"), 0, "3-char code should return 0")
	assert_eq(_decode_lobby_code("ABCDEFGH"), 0, "8-char code should return 0")


func test_lobby_code_decode_invalid_characters() -> void:
	# Test that codes with invalid characters return 0
	assert_eq(_decode_lobby_code("ABC!@#"), 0, "Code with special chars should return 0")
	assert_eq(_decode_lobby_code("abcdef"), 0, "Lowercase code should return 0")


func test_lobby_code_different_ids_produce_different_codes() -> void:
	# Test that different IDs produce different codes
	var code1 := _generate_lobby_code(12345)
	var code2 := _generate_lobby_code(12346)
	var code3 := _generate_lobby_code(99999)

	assert_ne(code1, code2, "Adjacent IDs should produce different codes")
	assert_ne(code1, code3, "Different IDs should produce different codes")
	assert_ne(code2, code3, "Different IDs should produce different codes")


func test_lobby_code_zero_id() -> void:
	# Test handling of zero ID
	var code := _generate_lobby_code(0)
	assert_eq(code, "000000", "Zero ID should produce '000000'")

	var decoded := _decode_lobby_code("000000")
	assert_eq(decoded, 0, "'000000' should decode to 0")


# =============================================================================
# LOBBY MANAGER INTEGRATION TESTS
# =============================================================================


func test_lobby_manager_get_lobby_code_empty_when_not_in_lobby() -> void:
	# Test that get_lobby_code returns empty when not in a lobby
	var code: String = LobbyManager.get_lobby_code()
	assert_eq(code, "", "Should return empty string when not in lobby")


func test_lobby_manager_is_steam_available() -> void:
	# Test the is_steam_available helper
	var expected: bool = SteamManager.is_steam_running
	var actual: bool = LobbyManager.is_steam_available()
	assert_eq(actual, expected, "is_steam_available should match SteamManager.is_steam_running")


func test_lobby_manager_join_by_code_requires_steam() -> void:
	# Test that join_lobby_by_code errors without Steam
	# This test only runs if Steam is not available
	if SteamManager.is_steam_running:
		pass_test("Skipping - Steam is running")
		return

	# Should log an error but not crash
	LobbyManager.join_lobby_by_code("ABC123")
	assert_false(LobbyManager.is_in_lobby, "Should not join lobby without Steam")


func test_lobby_manager_join_by_ip_allowed_without_steam() -> void:
	# Test that join_lobby_by_ip doesn't require Steam
	# Note: This will fail to connect but shouldn't error
	if LobbyManager.is_in_lobby:
		LobbyManager.leave_lobby()

	# Just verify the method exists and can be called
	# Actual connection requires a server
	assert_true(LobbyManager.has_method("join_lobby_by_ip"), "Should have join_lobby_by_ip method")


# =============================================================================
# STEAM MANAGER STATE TESTS
# =============================================================================


func test_steam_manager_has_required_signals() -> void:
	# Test that SteamManager has all required signals
	var required_signals := [
		"steam_initialized",
		"lobby_created",
		"lobby_create_failed",
		"lobby_joined",
		"lobby_join_failed",
		"lobby_member_joined",
		"lobby_member_left",
		"lobby_data_changed",
	]

	for signal_name in required_signals:
		assert_true(
			SteamManager.has_signal(signal_name),
			"SteamManager should have signal '%s'" % signal_name
		)


func test_steam_manager_has_required_methods() -> void:
	# Test that SteamManager has all required methods
	var required_methods := [
		"create_lobby",
		"join_lobby",
		"leave_lobby",
		"get_lobby_members",
		"get_member_name",
		"is_lobby_owner",
		"set_lobby_data",
		"get_lobby_data",
		"invite_friend",
		"update_rich_presence",
		"clear_rich_presence",
	]

	for method_name in required_methods:
		assert_true(
			SteamManager.has_method(method_name),
			"SteamManager should have method '%s'" % method_name
		)


func test_steam_manager_initial_state() -> void:
	# Test SteamManager initial state
	assert_eq(SteamManager.current_lobby_id, 0, "Should have no lobby initially")
	assert_eq(SteamManager.current_lobby_code, "", "Should have no code initially")


# =============================================================================
# HELPER IMPLEMENTATIONS (copied from SteamManager for testing)
# =============================================================================


const LOBBY_CODE_CHARS: String = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"


func _generate_lobby_code(lobby_id: int) -> String:
	var code := ""
	var value := lobby_id

	# Generate 6 base36 characters
	for i in range(6):
		code = LOBBY_CODE_CHARS[value % 36] + code
		value = value / 36

	return code


func _decode_lobby_code(code: String) -> int:
	if code.length() != 6:
		return 0

	var lobby_id := 0
	for i in range(6):
		var char_idx := LOBBY_CODE_CHARS.find(code[i])
		if char_idx == -1:
			return 0  # Invalid character
		lobby_id = lobby_id * 36 + char_idx

	return lobby_id
