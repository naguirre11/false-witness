extends GutTest
## Tests for AudioManager autoload.

var audio_manager: Node


func before_each() -> void:
	# Create a fresh AudioManager for each test
	var script: GDScript = load("res://src/core/audio_manager.gd")
	audio_manager = script.new()
	audio_manager.name = "TestAudioManager"
	add_child(audio_manager)


func after_each() -> void:
	if audio_manager:
		audio_manager.queue_free()
		audio_manager = null


# --- Bus Constants Tests ---


func test_bus_constants_defined() -> void:
	assert_eq(audio_manager.BUS_MASTER, "Master")
	assert_eq(audio_manager.BUS_SFX, "SFX")
	assert_eq(audio_manager.BUS_MUSIC, "Music")
	assert_eq(audio_manager.BUS_VOICE, "Voice")
	assert_eq(audio_manager.BUS_AMBIENT, "Ambient")


func test_valid_buses_array() -> void:
	var buses: Array[String] = audio_manager.VALID_BUSES
	assert_eq(buses.size(), 5)
	assert_true(buses.has("Master"))
	assert_true(buses.has("SFX"))
	assert_true(buses.has("Music"))
	assert_true(buses.has("Voice"))
	assert_true(buses.has("Ambient"))


# --- Bus Volume Tests ---


func test_has_bus_returns_true_for_master() -> void:
	# Master bus always exists
	assert_true(audio_manager.has_bus("Master"))


func test_has_bus_returns_false_for_invalid() -> void:
	assert_false(audio_manager.has_bus("NonExistentBus"))


func test_get_bus_names_returns_valid_buses() -> void:
	var names: Array[String] = audio_manager.get_bus_names()
	assert_eq(names.size(), 5)


func test_get_bus_volume_db_master() -> void:
	# Master should start at 0 dB
	var volume: float = audio_manager.get_bus_volume_db("Master")
	assert_almost_eq(volume, 0.0, 0.01)


func test_set_bus_volume_db_clamps_high() -> void:
	audio_manager.set_bus_volume_db("Master", 100.0)
	var volume: float = audio_manager.get_bus_volume_db("Master")
	# Should be clamped to 6 dB
	assert_almost_eq(volume, 6.0, 0.01)
	# Reset
	audio_manager.set_bus_volume_db("Master", 0.0)


func test_set_bus_volume_db_clamps_low() -> void:
	audio_manager.set_bus_volume_db("Master", -200.0)
	var volume: float = audio_manager.get_bus_volume_db("Master")
	# Should be clamped to -80 dB
	assert_almost_eq(volume, -80.0, 0.01)
	# Reset
	audio_manager.set_bus_volume_db("Master", 0.0)


func test_set_bus_volume_linear() -> void:
	audio_manager.set_bus_volume_linear("Master", 0.5)
	var linear: float = audio_manager.get_bus_volume_linear("Master")
	assert_almost_eq(linear, 0.5, 0.01)
	# Reset
	audio_manager.set_bus_volume_linear("Master", 1.0)


func test_set_bus_volume_linear_clamps() -> void:
	audio_manager.set_bus_volume_linear("Master", 2.0)
	var linear: float = audio_manager.get_bus_volume_linear("Master")
	assert_almost_eq(linear, 1.0, 0.01)
	# Reset
	audio_manager.set_bus_volume_linear("Master", 1.0)


func test_volume_changed_signal_emitted() -> void:
	var signal_data := {"received": false, "bus": "", "volume": 0.0}
	audio_manager.volume_changed.connect(
		func(bus: String, vol: float):
			signal_data["received"] = true
			signal_data["bus"] = bus
			signal_data["volume"] = vol
	)

	audio_manager.set_bus_volume_db("Master", -10.0)

	assert_true(signal_data["received"])
	assert_eq(signal_data["bus"], "Master")
	assert_almost_eq(signal_data["volume"] as float, -10.0, 0.01)

	# Reset
	audio_manager.set_bus_volume_db("Master", 0.0)


# --- Bus Mute Tests ---


func test_bus_mute_toggle() -> void:
	assert_false(audio_manager.is_bus_muted("Master"))
	audio_manager.set_bus_mute("Master", true)
	assert_true(audio_manager.is_bus_muted("Master"))
	audio_manager.set_bus_mute("Master", false)
	assert_false(audio_manager.is_bus_muted("Master"))


# --- Sound Pool Tests ---


func test_configure_sound_pool_creates_players() -> void:
	var stream := AudioStreamGenerator.new()
	audio_manager.configure_sound_pool("test_sound", stream, 4, "Master")

	# Should have 4 available players
	assert_eq(audio_manager.get_pool_available_count("test_sound"), 4)


func test_configure_sound_pool_rejects_empty_id() -> void:
	var stream := AudioStreamGenerator.new()
	audio_manager.configure_sound_pool("", stream, 4, "Master")
	# No pool should be created
	assert_eq(audio_manager.get_pool_available_count(""), 0)


func test_configure_sound_pool_rejects_null_stream() -> void:
	audio_manager.configure_sound_pool("test_null", null, 4, "Master")
	assert_eq(audio_manager.get_pool_available_count("test_null"), 0)


func test_play_pooled_sound_returns_false_for_unconfigured() -> void:
	var result: bool = audio_manager.play_pooled_sound("nonexistent")
	assert_false(result)


func test_remove_sound_pool() -> void:
	var stream := AudioStreamGenerator.new()
	audio_manager.configure_sound_pool("to_remove", stream, 2, "Master")
	assert_eq(audio_manager.get_pool_available_count("to_remove"), 2)

	audio_manager.remove_sound_pool("to_remove")
	assert_eq(audio_manager.get_pool_available_count("to_remove"), 0)


func test_stop_pooled_sounds() -> void:
	var stream := AudioStreamGenerator.new()
	audio_manager.configure_sound_pool("stoppable", stream, 2, "Master")
	# This shouldn't crash even if no sounds are playing
	audio_manager.stop_pooled_sounds("stoppable")
	pass_test("stop_pooled_sounds did not crash")


# --- One-Shot Sound Tests ---


func test_play_sound_returns_null_for_null_stream() -> void:
	var player: AudioStreamPlayer = audio_manager.play_sound(null)
	assert_null(player)


func test_play_sound_3d_returns_null_for_null_stream() -> void:
	var player: AudioStreamPlayer3D = audio_manager.play_sound_3d(null, Vector3.ZERO)
	assert_null(player)


func test_play_sound_attached_returns_null_for_null_stream() -> void:
	var target := Node3D.new()
	add_child(target)
	var player: AudioStreamPlayer3D = audio_manager.play_sound_attached(null, target)
	assert_null(player)
	target.queue_free()


func test_play_sound_attached_returns_null_for_null_node() -> void:
	var stream := AudioStreamGenerator.new()
	var player: AudioStreamPlayer3D = audio_manager.play_sound_attached(stream, null)
	assert_null(player)


func test_play_sound_creates_player() -> void:
	var stream := AudioStreamGenerator.new()
	var player: AudioStreamPlayer = audio_manager.play_sound(stream, "Master", -5.0)
	assert_not_null(player)
	assert_true(player is AudioStreamPlayer)
	assert_eq(player.bus, "Master")
	assert_almost_eq(player.volume_db, -5.0, 0.01)


func test_play_sound_3d_creates_player_at_position() -> void:
	var stream := AudioStreamGenerator.new()
	var pos := Vector3(10.0, 5.0, -3.0)
	var player: AudioStreamPlayer3D = audio_manager.play_sound_3d(stream, pos, "Master", -10.0)
	assert_not_null(player)
	assert_true(player is AudioStreamPlayer3D)
	assert_almost_eq(player.global_position.x, pos.x, 0.01)
	assert_almost_eq(player.global_position.y, pos.y, 0.01)
	assert_almost_eq(player.global_position.z, pos.z, 0.01)


func test_play_sound_attached_parents_to_node() -> void:
	var stream := AudioStreamGenerator.new()
	var target := Node3D.new()
	target.name = "AttachTarget"
	add_child(target)

	var player: AudioStreamPlayer3D = audio_manager.play_sound_attached(stream, target)
	assert_not_null(player)
	assert_eq(player.get_parent(), target)

	target.queue_free()


func test_sound_played_signal_emitted_for_3d_sound() -> void:
	var signal_data := {"received": false, "position": Vector3.ZERO}
	audio_manager.sound_played.connect(
		func(sid: String, pos: Vector3):
			signal_data["received"] = true
			signal_data["position"] = pos
	)

	var stream := AudioStreamGenerator.new()
	stream.resource_path = "test://stream"
	var pos := Vector3(1.0, 2.0, 3.0)
	audio_manager.play_sound_3d(stream, pos)

	assert_true(signal_data["received"])
	assert_almost_eq((signal_data["position"] as Vector3).x, 1.0, 0.01)


func test_get_active_sound_count() -> void:
	# Initially should be 0
	assert_eq(audio_manager.get_active_sound_count(), 0)


func test_stop_all_sounds() -> void:
	# Should not crash even with no active sounds
	audio_manager.stop_all_sounds()
	assert_eq(audio_manager.get_active_sound_count(), 0)


# --- Spatial Audio Settings Tests ---


func test_configure_spatial_player() -> void:
	var player := AudioStreamPlayer3D.new()
	add_child(player)

	audio_manager.configure_spatial_player(player, 2.0, 50.0)

	assert_almost_eq(player.unit_size, 2.0, 0.01)
	assert_almost_eq(player.max_distance, 50.0, 0.01)

	player.queue_free()


func test_configure_spatial_player_handles_null() -> void:
	# Should not crash
	audio_manager.configure_spatial_player(null)
	pass_test("configure_spatial_player handled null without crash")


func test_get_close_range_settings() -> void:
	var settings: Dictionary = audio_manager.get_close_range_settings()
	assert_true(settings.has("unit_size"))
	assert_true(settings.has("max_distance"))
	assert_true(settings.has("attenuation_model"))
	assert_almost_eq(settings["unit_size"] as float, 0.5, 0.01)
	assert_almost_eq(settings["max_distance"] as float, 15.0, 0.01)


func test_get_medium_range_settings() -> void:
	var settings: Dictionary = audio_manager.get_medium_range_settings()
	assert_almost_eq(settings["unit_size"] as float, 1.0, 0.01)
	assert_almost_eq(settings["max_distance"] as float, 25.0, 0.01)


func test_get_long_range_settings() -> void:
	var settings: Dictionary = audio_manager.get_long_range_settings()
	assert_almost_eq(settings["unit_size"] as float, 2.0, 0.01)
	assert_almost_eq(settings["max_distance"] as float, 50.0, 0.01)


# --- Default Constants Tests ---


func test_default_spatial_constants() -> void:
	assert_almost_eq(audio_manager.DEFAULT_UNIT_SIZE, 1.0, 0.01)
	assert_almost_eq(audio_manager.DEFAULT_MAX_DISTANCE, 30.0, 0.01)


func test_pool_size_constants() -> void:
	assert_eq(audio_manager.DEFAULT_POOL_SIZE, 8)
	assert_eq(audio_manager.MAX_POOL_SIZE, 32)
