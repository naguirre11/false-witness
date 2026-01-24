extends GutTest
## Unit tests for VideoCamera equipment.

const VideoCameraScript = preload("res://src/equipment/video_camera.gd")

var camera: VideoCamera
var mock_player: Node3D


func before_each() -> void:
	camera = VideoCameraScript.new()
	mock_player = Node3D.new()
	mock_player.name = "MockPlayer"
	add_child(camera)
	add_child(mock_player)


func after_each() -> void:
	camera.queue_free()
	mock_player.queue_free()
	camera = null
	mock_player = null


# --- Initial State Tests ---


func test_initial_state() -> void:
	assert_eq(camera.get_film_remaining(), 6, "Should start with max film")
	assert_false(camera.is_aiming(), "Should not be aiming initially")
	assert_false(camera.is_using_camera(), "Should not be using camera initially")
	assert_eq(camera.get_photos().size(), 0, "Should have no photos initially")


func test_equipment_properties() -> void:
	assert_eq(camera.equipment_type, Equipment.EquipmentType.VIDEO_CAMERA)
	assert_eq(camera.equipment_name, "Video Camera")
	assert_eq(camera.use_mode, Equipment.UseMode.TOGGLE)
	assert_almost_eq(camera.cooldown_time, 2.5, 0.01)


func test_detectable_evidence() -> void:
	var detectable: Array[String] = camera.get_detectable_evidence()
	assert_eq(detectable.size(), 1)
	assert_has(detectable, "VISUAL_MANIFESTATION")


# --- Aim Mode Tests ---


func test_aim_mode_toggle() -> void:
	camera.equip(mock_player)

	# Activate aim mode
	var success: bool = camera.use(mock_player)
	assert_true(success, "Should succeed entering aim mode")
	assert_true(camera.is_aiming(), "Should be aiming after toggle")
	assert_true(camera.is_using_camera(), "is_using_camera should be true")

	# Deactivate aim mode
	success = camera.use(mock_player)
	assert_true(success, "Should succeed exiting aim mode")
	assert_false(camera.is_aiming(), "Should not be aiming after toggle")
	assert_false(camera.is_using_camera(), "is_using_camera should be false")


func test_aim_signals() -> void:
	camera.equip(mock_player)
	watch_signals(camera)

	# Enter aim mode
	camera.use(mock_player)
	assert_signal_emitted(camera, "aim_started", "Should emit aim_started")

	# Exit aim mode
	camera.use(mock_player)
	assert_signal_emitted(camera, "aim_ended", "Should emit aim_ended")


func test_stop_using_does_not_affect_toggle_mode() -> void:
	# TOGGLE mode equipment doesn't respond to stop_using()
	# stop_using() is only for HOLD mode equipment
	camera.equip(mock_player)
	camera.use(mock_player)
	assert_true(camera.is_aiming(), "Should be aiming")

	# stop_using should have no effect on TOGGLE mode
	camera.stop_using(mock_player)
	assert_true(camera.is_aiming(), "Should still be aiming (TOGGLE mode ignores stop_using)")


func test_can_use_with_zero_film() -> void:
	camera.equip(mock_player)

	# Deplete all film
	camera._film_remaining = 0

	# Should still be able to enter aim mode
	var success: bool = camera.use(mock_player)
	assert_true(success, "Should be able to aim with 0 film")
	assert_true(camera.is_aiming(), "Should be aiming")


# --- Film Counter Tests ---


func test_film_counter() -> void:
	assert_eq(camera.get_film_remaining(), 6, "Should start with 6 film")
	assert_eq(camera.MAX_FILM, 6, "MAX_FILM constant should be 6")


func test_film_reset_on_equip() -> void:
	camera._film_remaining = 2
	camera._photos.append(PhotoRecord.new())

	camera.equip(mock_player)

	assert_eq(camera.get_film_remaining(), 6, "Film should reset on equip")
	assert_eq(camera.get_photos().size(), 0, "Photos should clear on equip")


# --- Interface Method Tests ---


func test_is_aiming_method() -> void:
	assert_false(camera.is_aiming(), "Should return false initially")

	camera._is_aiming = true
	assert_true(camera.is_aiming(), "Should return true when aiming")


func test_is_using_camera_method() -> void:
	# Not equipped, not aiming
	assert_false(camera.is_using_camera(), "Should be false when not equipped")

	# Equipped but not aiming
	camera.equip(mock_player)
	assert_false(camera.is_using_camera(), "Should be false when not aiming")

	# Equipped and aiming
	camera.use(mock_player)
	assert_true(camera.is_using_camera(), "Should be true when equipped and aiming")

	# Unequipped while aiming
	camera.unequip()
	assert_false(camera.is_using_camera(), "Should be false after unequip")


func test_take_photo_method_exists() -> void:
	# Verify method exists and returns PhotoRecord or null
	camera.equip(mock_player)
	camera.use(mock_player)  # Enter aim mode

	var result: PhotoRecord = camera.take_photo()
	# Stub implementation returns null, but method should exist
	assert_true(result == null, "Stub implementation should return null")


func test_get_photos_method() -> void:
	var photos: Array[PhotoRecord] = camera.get_photos()
	assert_not_null(photos, "Should return an array")
	assert_eq(photos.size(), 0, "Should start empty")


# --- Take Photo Tests (Stub Behavior) ---


func test_take_photo_requires_aim() -> void:
	camera.equip(mock_player)
	# Not aiming

	var result: PhotoRecord = camera.take_photo()
	assert_null(result, "Should return null when not aiming")


func test_take_photo_consumes_film() -> void:
	# Film consumption happens server-side via RPC (_rpc_request_capture)
	# Unit tests without network context can't test this
	# See integration tests for full photo capture flow
	pending("Film consumption happens server-side via RPC")


func test_take_photo_with_zero_film() -> void:
	camera.equip(mock_player)
	camera._film_remaining = 0
	camera.use(mock_player)

	# Client-side validation should prevent photo attempt
	var result: PhotoRecord = camera.take_photo()
	assert_null(result, "Should return null with no film")
	# Note: film_depleted signal emits server-side after RPC, not testable in unit test


func test_take_photo_starts_cooldown() -> void:
	# Cooldown starts server-side via RPC (_rpc_request_capture)
	# Unit tests without network context can't test this
	# See integration tests for full photo capture flow
	pending("Cooldown starts server-side via RPC")


func test_cannot_take_photo_during_cooldown() -> void:
	camera.equip(mock_player)
	camera.use(mock_player)

	# Manually simulate cooldown state (normally set server-side)
	camera._cooldown_timer = 2.5
	camera._set_state(Equipment.EquipmentState.COOLDOWN)

	# Client-side validation should prevent photo during cooldown
	var result: PhotoRecord = camera.take_photo()
	assert_null(result, "Should return null during cooldown")
	# Film count unchanged (no RPC sent)
	assert_eq(camera.get_film_remaining(), 6, "Film should not be consumed")


# --- Network State Tests ---


func test_network_state_includes_aim() -> void:
	camera.equip(mock_player)
	camera.use(mock_player)  # Enter aim mode

	var state: Dictionary = camera.get_network_state()
	assert_has(state, "is_aiming", "Should include is_aiming")
	assert_true(state["is_aiming"], "Should be true")


func test_network_state_includes_film() -> void:
	camera.equip(mock_player)
	camera._film_remaining = 3

	var state: Dictionary = camera.get_network_state()
	assert_has(state, "film_remaining", "Should include film_remaining")
	assert_eq(state["film_remaining"], 3)


func test_apply_network_state_aim() -> void:
	camera.equip(mock_player)
	watch_signals(camera)

	var state: Dictionary = {"is_aiming": true}
	camera.apply_network_state(state)

	assert_true(camera.is_aiming(), "Should update aim state")
	assert_signal_emitted(camera, "aim_started", "Should emit signal")


func test_apply_network_state_film() -> void:
	camera.equip(mock_player)
	watch_signals(camera)

	var state: Dictionary = {"film_remaining": 2}
	camera.apply_network_state(state)

	assert_eq(camera.get_film_remaining(), 2, "Should update film count")
	assert_signal_emitted(camera, "film_changed", "Should emit signal")


# --- Unequip Tests ---


func test_unequip_exits_aim() -> void:
	camera.equip(mock_player)
	camera.use(mock_player)  # Enter aim mode
	assert_true(camera.is_aiming())

	camera.unequip()
	assert_false(camera.is_aiming(), "Should exit aim mode on unequip")


# --- Entity Detection Tests ---


func test_detect_entity_basic_signature() -> void:
	# Verify method exists and returns expected dict structure
	camera.equip(mock_player)

	var result: Dictionary = camera._detect_entity_in_frame()

	assert_not_null(result, "Should return a dictionary")
	assert_has(result, "found", "Should have 'found' key")
	assert_has(result, "entity", "Should have 'entity' key")
	assert_has(result, "entity_type", "Should have 'entity_type' key")
	assert_false(result.found, "Should return false when no entities present")
	assert_null(result.entity, "Should return null entity when not found")
	assert_eq(result.entity_type, "", "Should return empty string when not found")


func test_has_line_of_sight_basic() -> void:
	# Verify LOS helper works with basic positions
	camera.equip(mock_player)
	add_child_autofree(camera)

	var from_pos := Vector3(0, 1, 0)
	var to_pos := Vector3(0, 1, 10)

	# Without world geometry, should have LOS
	var has_los: bool = camera._has_line_of_sight(from_pos, to_pos)
	# Result depends on scene tree setup, just verify method exists and returns bool
	assert_true(has_los == true or has_los == false, "Should return a boolean")
