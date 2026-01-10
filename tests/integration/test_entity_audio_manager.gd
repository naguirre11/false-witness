extends GutTest
## Tests for EntityAudioManager autoload and EntityAudioConfig resource.

var entity_audio_manager: Node
var audio_manager: Node
var event_bus_script: GDScript


func before_each() -> void:
	# Create AudioManager first (dependency)
	var audio_script: GDScript = load("res://src/core/audio_manager.gd")
	audio_manager = audio_script.new()
	audio_manager.name = "AudioManager"
	add_child(audio_manager)

	# Create EntityAudioManager
	var entity_audio_script: GDScript = load("res://src/core/audio/entity_audio_manager.gd")
	entity_audio_manager = entity_audio_script.new()
	entity_audio_manager.name = "EntityAudioManager"
	add_child(entity_audio_manager)


func after_each() -> void:
	if entity_audio_manager:
		entity_audio_manager.queue_free()
		entity_audio_manager = null
	if audio_manager:
		audio_manager.queue_free()
		audio_manager = null


# --- EntityAudioConfig Tests ---


func test_entity_audio_config_can_be_created() -> void:
	var config := EntityAudioConfig.new()
	assert_not_null(config)
	assert_true(config is Resource)


func test_entity_audio_config_default_values() -> void:
	var config := EntityAudioConfig.new()

	# Check default footstep settings
	assert_almost_eq(config.footstep_interval_normal, 0.6, 0.01)
	assert_almost_eq(config.footstep_interval_hunt, 0.4, 0.01)
	assert_almost_eq(config.footstep_volume_db, 0.0, 0.01)
	assert_almost_eq(config.footstep_pitch_variation, 0.1, 0.01)

	# Check default vocalization settings
	assert_almost_eq(config.ambient_vocalization_interval, 15.0, 0.01)
	assert_almost_eq(config.vocalization_volume_db, 0.0, 0.01)

	# Check default spatial settings
	assert_almost_eq(config.spatial_unit_size, 2.0, 0.01)
	assert_almost_eq(config.max_audible_distance, 50.0, 0.01)


func test_entity_audio_config_get_random_footstep_returns_null_when_empty() -> void:
	var config := EntityAudioConfig.new()
	assert_null(config.get_random_footstep(false))
	assert_null(config.get_random_footstep(true))


func test_entity_audio_config_get_random_footstep_returns_sound() -> void:
	var config := EntityAudioConfig.new()
	var stream := AudioStreamGenerator.new()
	config.footsteps_normal.append(stream)

	var result := config.get_random_footstep(false)
	assert_not_null(result)
	assert_eq(result, stream)


func test_entity_audio_config_get_random_footstep_hunt() -> void:
	var config := EntityAudioConfig.new()
	var normal_stream := AudioStreamGenerator.new()
	var hunt_stream := AudioStreamGenerator.new()
	config.footsteps_normal.append(normal_stream)
	config.footsteps_hunt.append(hunt_stream)

	# Normal mode should return normal stream
	assert_eq(config.get_random_footstep(false), normal_stream)
	# Hunt mode should return hunt stream
	assert_eq(config.get_random_footstep(true), hunt_stream)


func test_entity_audio_config_get_random_vocalization() -> void:
	var config := EntityAudioConfig.new()
	assert_null(config.get_random_ambient_vocalization())
	assert_null(config.get_random_hunt_vocalization())

	var ambient := AudioStreamGenerator.new()
	var hunt := AudioStreamGenerator.new()
	config.ambient_vocalizations.append(ambient)
	config.hunt_vocalizations.append(hunt)

	assert_eq(config.get_random_ambient_vocalization(), ambient)
	assert_eq(config.get_random_hunt_vocalization(), hunt)


func test_entity_audio_config_get_random_manifestation_sound() -> void:
	var config := EntityAudioConfig.new()
	assert_null(config.get_random_manifestation_sound())

	var stream := AudioStreamGenerator.new()
	config.manifestation_sounds.append(stream)
	assert_eq(config.get_random_manifestation_sound(), stream)


func test_entity_audio_config_get_random_tell_sound() -> void:
	var config := EntityAudioConfig.new()
	assert_null(config.get_random_tell_sound())

	var stream := AudioStreamGenerator.new()
	config.behavioral_tell_sounds.append(stream)
	assert_eq(config.get_random_tell_sound(), stream)


func test_entity_audio_config_get_random_pitch_in_range() -> void:
	var config := EntityAudioConfig.new()
	config.footstep_pitch_variation = 0.2

	# Run multiple times to check range
	for i in range(20):
		var pitch: float = config.get_random_pitch()
		assert_true(pitch >= 0.8 and pitch <= 1.2)


func test_entity_audio_config_get_footstep_interval() -> void:
	var config := EntityAudioConfig.new()
	config.footstep_interval_normal = 0.5
	config.footstep_interval_hunt = 0.3

	assert_almost_eq(config.get_footstep_interval(false), 0.5, 0.01)
	assert_almost_eq(config.get_footstep_interval(true), 0.3, 0.01)


# --- EntityAudioManager Basic Tests ---


func test_entity_audio_manager_initializes() -> void:
	assert_not_null(entity_audio_manager)


func test_entity_audio_manager_has_signals() -> void:
	assert_true(entity_audio_manager.has_signal("hunt_audio_started"))
	assert_true(entity_audio_manager.has_signal("hunt_audio_ended"))
	assert_true(entity_audio_manager.has_signal("ambient_suppressed"))


func test_set_entity_accepts_entity_and_config() -> void:
	var mock_entity := Node3D.new()
	mock_entity.name = "MockEntity"
	add_child(mock_entity)

	var config := EntityAudioConfig.new()
	entity_audio_manager.set_entity(mock_entity, config)

	# Should not crash
	pass_test("set_entity accepted entity and config")

	mock_entity.queue_free()


func test_clear_entity_clears_state() -> void:
	var mock_entity := Node3D.new()
	add_child(mock_entity)
	var config := EntityAudioConfig.new()

	entity_audio_manager.set_entity(mock_entity, config)
	entity_audio_manager.clear_entity()

	# Should not crash
	pass_test("clear_entity completed without error")

	mock_entity.queue_free()


func test_set_player_camera() -> void:
	var camera := Node3D.new()
	camera.name = "TestCamera"
	add_child(camera)

	entity_audio_manager.set_player_camera(camera)

	# Should not crash
	pass_test("set_player_camera completed without error")

	camera.queue_free()


func test_is_ambient_suppressed_default_false() -> void:
	assert_false(entity_audio_manager.is_ambient_suppressed())


func test_trigger_silence_cue() -> void:
	entity_audio_manager.trigger_silence_cue()
	assert_true(entity_audio_manager.is_ambient_suppressed())


func test_stop_silence_cue() -> void:
	entity_audio_manager.trigger_silence_cue()
	entity_audio_manager.stop_silence_cue()
	assert_false(entity_audio_manager.is_ambient_suppressed())


func test_ambient_suppressed_signal_emitted() -> void:
	var signal_data := {"received": false, "suppressed": false}
	entity_audio_manager.ambient_suppressed.connect(
		func(is_suppressed: bool):
			signal_data["received"] = true
			signal_data["suppressed"] = is_suppressed
	)

	entity_audio_manager.trigger_silence_cue()

	assert_true(signal_data["received"])
	assert_true(signal_data["suppressed"])


# --- Hunt Audio Event Tests ---


func test_hunt_audio_started_signal_on_hunt_start() -> void:
	# This test verifies that EntityAudioManager emits hunt_audio_started
	# when EventBus.hunt_started is emitted. Since the autoload connects
	# in _ready, the test manager instance needs entity/config set first.

	var mock_entity := Node3D.new()
	add_child(mock_entity)
	var config := EntityAudioConfig.new()
	entity_audio_manager.set_entity(mock_entity, config)

	var signal_data := {"received": false}
	entity_audio_manager.hunt_audio_started.connect(
		func(): signal_data["received"] = true
	)

	# Simulate hunt started via EventBus
	if EventBus:
		EventBus.hunt_started.emit()
		assert_true(signal_data["received"])
	else:
		pending("EventBus not available")

	mock_entity.queue_free()


func test_hunt_audio_ended_signal_on_hunt_end() -> void:
	# Setup entity for proper signal emission
	var mock_entity := Node3D.new()
	add_child(mock_entity)
	var config := EntityAudioConfig.new()
	entity_audio_manager.set_entity(mock_entity, config)

	# First start a hunt
	if EventBus:
		EventBus.hunt_started.emit()

	var signal_data := {"received": false}
	entity_audio_manager.hunt_audio_ended.connect(
		func(): signal_data["received"] = true
	)

	# End the hunt
	if EventBus:
		EventBus.hunt_ended.emit()
		assert_true(signal_data["received"])
	else:
		pending("EventBus not available")

	mock_entity.queue_free()


# --- Aggression Phase Tests ---


func test_aggression_phase_updates() -> void:
	if EventBus:
		# Test dormant phase
		EventBus.entity_aggression_changed.emit(0, "DORMANT")
		await get_tree().process_frame

		# Test active phase
		EventBus.entity_aggression_changed.emit(1, "ACTIVE")
		await get_tree().process_frame

		# Test aggressive phase
		EventBus.entity_aggression_changed.emit(2, "AGGRESSIVE")
		await get_tree().process_frame

		# Test furious phase
		EventBus.entity_aggression_changed.emit(3, "FURIOUS")
		await get_tree().process_frame

		pass_test("Aggression phase changes processed without error")
	else:
		pending("EventBus not available")


# --- Occlusion Tests ---


func test_occlusion_without_entity_does_not_crash() -> void:
	# Without entity set, occlusion check should do nothing
	entity_audio_manager._update_occlusion(0.1)
	pass_test("Occlusion update without entity completed")


func test_occlusion_without_camera_does_not_crash() -> void:
	var mock_entity := Node3D.new()
	add_child(mock_entity)
	var config := EntityAudioConfig.new()
	entity_audio_manager.set_entity(mock_entity, config)

	# Without camera, occlusion check should do nothing
	entity_audio_manager._update_occlusion(0.1)
	pass_test("Occlusion update without camera completed")

	mock_entity.queue_free()


# --- Proximity Tests ---


func test_proximity_without_entity_does_not_crash() -> void:
	entity_audio_manager._update_proximity_ambient(0.1)
	pass_test("Proximity update without entity completed")


func test_proximity_without_camera_does_not_crash() -> void:
	var mock_entity := Node3D.new()
	add_child(mock_entity)
	var config := EntityAudioConfig.new()
	entity_audio_manager.set_entity(mock_entity, config)

	entity_audio_manager._update_proximity_ambient(0.1)
	pass_test("Proximity update without camera completed")

	mock_entity.queue_free()


# --- Footstep Tests ---


func test_footsteps_without_entity_does_not_crash() -> void:
	entity_audio_manager._update_footsteps(0.1)
	pass_test("Footstep update without entity completed")


func test_footsteps_with_non_character_body_does_nothing() -> void:
	var mock_entity := Node3D.new()
	add_child(mock_entity)
	var config := EntityAudioConfig.new()
	entity_audio_manager.set_entity(mock_entity, config)

	entity_audio_manager._update_footsteps(0.1)
	pass_test("Footstep update with non-CharacterBody3D completed")

	mock_entity.queue_free()


# --- Process Tests ---


func test_process_does_not_crash_without_entity() -> void:
	# Simulate several frames of processing
	for i in range(10):
		entity_audio_manager._process(0.016)

	pass_test("Process without entity completed 10 frames")


func test_process_with_entity_and_camera() -> void:
	var mock_entity := Node3D.new()
	mock_entity.name = "TestEntity"
	add_child(mock_entity)

	var camera := Node3D.new()
	camera.name = "TestCamera"
	add_child(camera)

	var config := EntityAudioConfig.new()
	entity_audio_manager.set_entity(mock_entity, config)
	entity_audio_manager.set_player_camera(camera)

	# Simulate several frames
	for i in range(10):
		entity_audio_manager._process(0.016)

	pass_test("Process with entity and camera completed 10 frames")

	mock_entity.queue_free()
	camera.queue_free()
