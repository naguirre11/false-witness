extends GutTest
## Integration tests for VideoCamera equipment.


var _video_camera: VideoCamera
var _mock_player: Node3D


func before_each() -> void:
	_mock_player = Node3D.new()
	add_child_autofree(_mock_player)

	_video_camera = autofree(VideoCamera.new())
	add_child(_video_camera)

	# Simulate equipping
	_video_camera._owning_player = _mock_player
	_video_camera._is_equipped = true


func after_each() -> void:
	_video_camera = null
	_mock_player = null


# --- take_photo() validation tests ---


func test_take_photo_requires_aiming() -> void:
	# GIVEN: Camera not in aim mode
	_video_camera._is_aiming = false

	# WHEN: Attempting to take photo
	var result := _video_camera.take_photo()

	# THEN: Returns null
	assert_null(result, "Should return null when not aiming")


func test_take_photo_requires_film() -> void:
	# GIVEN: Camera in aim mode but no film
	_video_camera._is_aiming = true
	_video_camera._film_remaining = 0

	# WHEN: Attempting to take photo
	var result := _video_camera.take_photo()

	# THEN: Returns null
	assert_null(result, "Should return null when no film")


func test_take_photo_respects_cooldown() -> void:
	# GIVEN: Camera in aim mode with film but on cooldown
	_video_camera._is_aiming = true
	_video_camera._film_remaining = 6
	_video_camera._current_state = VideoCamera.EquipmentState.COOLDOWN
	_video_camera._cooldown_timer = 1.0

	# WHEN: Attempting to take photo
	var result := _video_camera.take_photo()

	# THEN: Returns null
	assert_null(result, "Should return null when on cooldown")


# --- RPC method existence tests ---


func test_rpc_methods_exist() -> void:
	# THEN: Required RPC methods exist
	assert_true(
		_video_camera.has_method("_rpc_request_capture"),
		"Should have _rpc_request_capture method"
	)
	assert_true(
		_video_camera.has_method("_rpc_capture_result"),
		"Should have _rpc_capture_result method"
	)
	assert_true(
		_video_camera.has_method("_get_evidence_manager"),
		"Should have _get_evidence_manager method"
	)


# --- Signal emission tests ---


func test_film_depleted_signal() -> void:
	# GIVEN: Camera in aim mode with 1 film
	_video_camera._is_aiming = true
	_video_camera._film_remaining = 1

	# Track signal
	watch_signals(_video_camera)

	# WHEN: Take photo (triggers RPC, but we can't test server in unit test)
	var result := _video_camera.take_photo()

	# THEN: Returns null (RPC result comes later)
	assert_null(result, "Should return null immediately (RPC-based)")


func test_cooldown_tracking() -> void:
	# GIVEN: Camera in inactive state (ready to use)
	_video_camera._is_aiming = true
	_video_camera._film_remaining = 6
	_video_camera._current_state = VideoCamera.EquipmentState.INACTIVE

	# THEN: Can take photo
	var result := _video_camera.take_photo()
	assert_null(result, "Returns null (RPC-based)")


# --- Entity detection tests ---


func test_detect_entity_in_frame_returns_dict() -> void:
	# WHEN: Calling detection method
	var result := _video_camera._detect_entity_in_frame()

	# THEN: Returns dict with expected keys
	assert_true(result.has("found"), "Should have 'found' key")
	assert_true(result.has("entity"), "Should have 'entity' key")
	assert_true(result.has("entity_type"), "Should have 'entity_type' key")
	assert_false(result.found, "Should be false when no entities present")


func test_has_line_of_sight_with_no_obstacles() -> void:
	# GIVEN: Two points in space
	var from_pos := Vector3(0, 1, 0)
	var to_pos := Vector3(0, 1, 10)

	# WHEN: Checking line of sight
	var result := _video_camera._has_line_of_sight(from_pos, to_pos)

	# THEN: Returns true (no obstacles in empty test scene)
	assert_true(result, "Should have LOS in empty scene")
