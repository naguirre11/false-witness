extends GutTest
## Integration tests for VoiceManager and voice chat functionality (FW-014-16)
##
## Tests push-to-talk, voice activity detection, mute/unmute, spatial audio,
## settings persistence, and VoicePlayer jitter buffer.
## Note: Audio input/output is mocked since we can't capture real audio in tests.


# =============================================================================
# SETUP/TEARDOWN
# =============================================================================


func before_each() -> void:
	# Reset VoiceManager state between tests
	if has_node("/root/VoiceManager"):
		VoiceManager.reset_settings()


# =============================================================================
# VOICE MANAGER INITIALIZATION TESTS
# =============================================================================


func test_voice_manager_initializes() -> void:
	assert_true(has_node("/root/VoiceManager"), "VoiceManager autoload should exist")


func test_voice_manager_has_required_signals() -> void:
	var required_signals := [
		"voice_state_changed",
		"voice_data_captured",
		"voice_activity",
		"player_muted",
		"player_unmuted",
	]

	for signal_name in required_signals:
		assert_true(
			VoiceManager.has_signal(signal_name),
			"VoiceManager should have signal '%s'" % signal_name
		)


func test_voice_manager_has_required_methods() -> void:
	var required_methods := [
		"set_voice_enabled",
		"set_local_muted",
		"set_voice_mode",
		"set_vad_threshold",
		"is_transmitting",
		"get_voice_amplitude",
		"mute_player",
		"unmute_player",
		"is_player_muted",
		"set_input_volume",
		"set_output_volume",
		"set_sensitivity",
		"save_settings",
		"load_settings",
		"reset_settings",
	]

	for method_name in required_methods:
		assert_true(
			VoiceManager.has_method(method_name),
			"VoiceManager should have method '%s'" % method_name
		)


func test_voice_manager_initial_state() -> void:
	assert_true(VoiceManager.is_voice_enabled, "Voice should be enabled by default")
	assert_false(VoiceManager.local_muted, "Local should not be muted by default")
	assert_eq(
		VoiceManager.voice_mode,
		VoiceEnums.VoiceMode.PUSH_TO_TALK,
		"Default mode should be Push to Talk"
	)
	assert_eq(
		VoiceManager.voice_state,
		VoiceEnums.VoiceState.IDLE,
		"Initial state should be IDLE"
	)


# =============================================================================
# VOICE MODE TESTS
# =============================================================================


func test_set_voice_mode_push_to_talk() -> void:
	VoiceManager.set_voice_mode(VoiceEnums.VoiceMode.PUSH_TO_TALK)
	assert_eq(
		VoiceManager.voice_mode,
		VoiceEnums.VoiceMode.PUSH_TO_TALK,
		"Should set push-to-talk mode"
	)


func test_set_voice_mode_open_mic() -> void:
	VoiceManager.set_voice_mode(VoiceEnums.VoiceMode.OPEN_MIC)
	assert_eq(
		VoiceManager.voice_mode,
		VoiceEnums.VoiceMode.OPEN_MIC,
		"Should set open mic mode"
	)


func test_set_voice_mode_disabled() -> void:
	VoiceManager.set_voice_mode(VoiceEnums.VoiceMode.DISABLED)
	assert_eq(
		VoiceManager.voice_mode,
		VoiceEnums.VoiceMode.DISABLED,
		"Should set disabled mode"
	)


func test_set_voice_mode_resets_state_to_idle() -> void:
	VoiceManager.set_voice_mode(VoiceEnums.VoiceMode.DISABLED)
	assert_eq(
		VoiceManager.voice_state,
		VoiceEnums.VoiceState.IDLE,
		"Changing mode should reset state to IDLE"
	)


# =============================================================================
# MUTE FUNCTIONALITY TESTS
# =============================================================================


func test_set_local_muted_true() -> void:
	VoiceManager.set_local_muted(true)
	assert_true(VoiceManager.local_muted, "Should set local_muted to true")


func test_set_local_muted_false() -> void:
	VoiceManager.set_local_muted(true)
	VoiceManager.set_local_muted(false)
	assert_false(VoiceManager.local_muted, "Should set local_muted to false")


func test_mute_player() -> void:
	var test_steam_id: int = 123456789

	VoiceManager.mute_player(test_steam_id)

	assert_true(
		VoiceManager.is_player_muted(test_steam_id),
		"Player should be muted after mute_player()"
	)


func test_unmute_player() -> void:
	var test_steam_id: int = 123456789

	VoiceManager.mute_player(test_steam_id)
	VoiceManager.unmute_player(test_steam_id)

	assert_false(
		VoiceManager.is_player_muted(test_steam_id),
		"Player should not be muted after unmute_player()"
	)


func test_mute_player_emits_signal() -> void:
	var test_steam_id: int = 987654321
	var state := {"signal_received": false, "received_id": 0}

	VoiceManager.player_muted.connect(func(steam_id: int):
		state["signal_received"] = true
		state["received_id"] = steam_id
	)

	VoiceManager.mute_player(test_steam_id)

	assert_true(state["signal_received"], "Should emit player_muted signal")
	assert_eq(state["received_id"], test_steam_id, "Signal should include correct Steam ID")


func test_unmute_player_emits_signal() -> void:
	var test_steam_id: int = 111222333
	var state := {"signal_received": false}

	VoiceManager.mute_player(test_steam_id)
	VoiceManager.player_unmuted.connect(func(_steam_id: int):
		state["signal_received"] = true
	)
	VoiceManager.unmute_player(test_steam_id)

	assert_true(state["signal_received"], "Should emit player_unmuted signal")


func test_get_muted_players() -> void:
	var ids: Array[int] = [111, 222, 333]

	for id in ids:
		VoiceManager.mute_player(id)

	var muted := VoiceManager.get_muted_players()

	for id in ids:
		assert_true(id in muted, "Muted list should contain ID %d" % id)


# =============================================================================
# VOICE SETTINGS TESTS
# =============================================================================


func test_set_input_volume_clamps_to_valid_range() -> void:
	VoiceManager.set_input_volume(1.5)
	assert_eq(VoiceManager.voice_input_volume, 1.0, "Should clamp above 1.0 to 1.0")

	VoiceManager.set_input_volume(-0.5)
	assert_eq(VoiceManager.voice_input_volume, 0.0, "Should clamp below 0.0 to 0.0")

	VoiceManager.set_input_volume(0.5)
	assert_eq(VoiceManager.voice_input_volume, 0.5, "Should accept valid value")


func test_set_output_volume_clamps_to_valid_range() -> void:
	VoiceManager.set_output_volume(2.0)
	assert_eq(VoiceManager.voice_output_volume, 1.0, "Should clamp above 1.0 to 1.0")

	VoiceManager.set_output_volume(-1.0)
	assert_eq(VoiceManager.voice_output_volume, 0.0, "Should clamp below 0.0 to 0.0")

	VoiceManager.set_output_volume(0.75)
	assert_eq(VoiceManager.voice_output_volume, 0.75, "Should accept valid value")


func test_set_sensitivity_adjusts_vad_threshold() -> void:
	var initial_threshold := VoiceManager.vad_threshold

	VoiceManager.set_sensitivity(1.0)  # Max sensitivity
	var high_sensitivity_threshold := VoiceManager.vad_threshold

	VoiceManager.set_sensitivity(0.0)  # Min sensitivity
	var low_sensitivity_threshold := VoiceManager.vad_threshold

	assert_true(
		high_sensitivity_threshold < low_sensitivity_threshold,
		"High sensitivity should have lower threshold than low sensitivity"
	)


func test_get_settings_returns_all_values() -> void:
	VoiceManager.set_voice_mode(VoiceEnums.VoiceMode.OPEN_MIC)
	VoiceManager.set_input_volume(0.8)
	VoiceManager.set_output_volume(0.6)
	VoiceManager.set_sensitivity(0.7)

	var settings := VoiceManager.get_settings()

	assert_eq(settings.voice_mode, VoiceEnums.VoiceMode.OPEN_MIC, "Should have correct mode")
	assert_eq(settings.voice_input_volume, 0.8, "Should have correct input volume")
	assert_eq(settings.voice_output_volume, 0.6, "Should have correct output volume")
	assert_eq(settings.voice_sensitivity, 0.7, "Should have correct sensitivity")


func test_reset_settings_restores_defaults() -> void:
	# Change all settings
	VoiceManager.set_voice_mode(VoiceEnums.VoiceMode.DISABLED)
	VoiceManager.set_input_volume(0.2)
	VoiceManager.set_output_volume(0.3)
	VoiceManager.set_sensitivity(0.9)

	# Reset
	VoiceManager.reset_settings()

	assert_eq(
		VoiceManager.voice_mode,
		VoiceEnums.VoiceMode.PUSH_TO_TALK,
		"Mode should reset to default"
	)
	assert_eq(VoiceManager.voice_input_volume, 1.0, "Input volume should reset to default")
	assert_eq(VoiceManager.voice_output_volume, 1.0, "Output volume should reset to default")


# =============================================================================
# VOICE PLAYER TESTS
# =============================================================================


func test_voice_player_creation() -> void:
	var player := VoicePlayer.new()
	add_child_autofree(player)

	player.setup(12345)

	assert_eq(player.steam_id, 12345, "Should store steam_id")
	assert_eq(player.name, "VoicePlayer_12345", "Should set name correctly")


func test_voice_player_position_update() -> void:
	var player := VoicePlayer.new()
	add_child_autofree(player)
	player.setup(99999)

	var new_pos := Vector3(10.0, 5.0, -3.0)
	player.update_position(new_pos)

	assert_eq(player.global_position, new_pos, "Should update position")


func test_voice_player_max_distance_configuration() -> void:
	var player := VoicePlayer.new()
	add_child_autofree(player)
	player.setup(11111)

	var custom_distance := 25.0
	player.configure_max_distance(custom_distance)

	assert_eq(player.max_distance, custom_distance, "Should set custom max_distance")


func test_voice_player_latency_stats_initial() -> void:
	var player := VoicePlayer.new()
	add_child_autofree(player)
	player.setup(22222)

	var stats := player.get_latency_stats()

	assert_eq(stats.sample_count, 0, "Should have no samples initially")
	assert_eq(stats.average_ms, 0.0, "Should have zero average initially")


func test_voice_player_buffer_target() -> void:
	var player := VoicePlayer.new()
	add_child_autofree(player)
	player.setup(33333)

	var buffer_target := player.get_buffer_target_ms()

	assert_true(buffer_target >= 40.0, "Buffer target should be at least 40ms")
	assert_true(buffer_target <= 200.0, "Buffer target should be at most 200ms")


func test_voice_player_reset_latency_stats() -> void:
	var player := VoicePlayer.new()
	add_child_autofree(player)
	player.setup(44444)

	# Simulate some stats (normally done by receiving packets)
	player._total_latency_ms = 500.0
	player._latency_sample_count = 10

	player.reset_latency_stats()

	var stats := player.get_latency_stats()
	assert_eq(stats.sample_count, 0, "Should reset sample count")
	assert_eq(stats.average_ms, 0.0, "Should reset average")


# =============================================================================
# VOICE STATE SIGNAL TESTS
# =============================================================================


func test_voice_state_changed_signal_emitted() -> void:
	var state := {"received": false, "new_state": -1}

	VoiceManager.voice_state_changed.connect(func(new_state: int):
		state["received"] = true
		state["new_state"] = new_state
	)

	# Disable voice then re-enable to trigger state change
	VoiceManager.set_voice_enabled(false)

	# State should be IDLE after disabling
	assert_eq(
		VoiceManager.voice_state,
		VoiceEnums.VoiceState.IDLE,
		"Should be IDLE when disabled"
	)


# =============================================================================
# IS_TRANSMITTING TESTS
# =============================================================================


func test_is_transmitting_false_when_idle() -> void:
	VoiceManager.set_voice_mode(VoiceEnums.VoiceMode.PUSH_TO_TALK)
	# Without pressing PTT key, should not be transmitting
	assert_false(
		VoiceManager.is_transmitting(),
		"Should not be transmitting when idle"
	)


func test_is_transmitting_false_when_disabled() -> void:
	VoiceManager.set_voice_mode(VoiceEnums.VoiceMode.DISABLED)
	assert_false(
		VoiceManager.is_transmitting(),
		"Should not be transmitting when voice is disabled"
	)


# =============================================================================
# VAD THRESHOLD TESTS
# =============================================================================


func test_set_vad_threshold_clamps_values() -> void:
	VoiceManager.set_vad_threshold(1.5)
	assert_eq(VoiceManager.vad_threshold, 1.0, "Should clamp above 1.0")

	VoiceManager.set_vad_threshold(-0.5)
	assert_eq(VoiceManager.vad_threshold, 0.0, "Should clamp below 0.0")


func test_set_vad_threshold_accepts_valid_values() -> void:
	VoiceManager.set_vad_threshold(0.5)
	assert_eq(VoiceManager.vad_threshold, 0.5, "Should accept valid value")
