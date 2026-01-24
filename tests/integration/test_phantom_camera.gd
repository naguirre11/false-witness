extends GutTest
## Integration tests for Phantom-VideoCamera interaction.
## Verifies VideoCamera fulfills Phantom's expected camera interface.

const VideoCamera := preload("res://src/equipment/video_camera.gd")


func test_video_camera_has_take_photo_method() -> void:
	var camera := VideoCamera.new()
	add_child(camera)

	assert_true(camera.has_method("take_photo"), "VideoCamera must have take_photo method")

	camera.queue_free()


func test_video_camera_has_is_aiming_method() -> void:
	var camera := VideoCamera.new()
	add_child(camera)

	assert_true(camera.has_method("is_aiming"), "VideoCamera must have is_aiming method")

	camera.queue_free()


func test_video_camera_is_aiming_returns_bool() -> void:
	var camera := VideoCamera.new()
	add_child(camera)

	var result = camera.is_aiming()
	assert_typeof(result, TYPE_BOOL, "is_aiming must return bool")

	camera.queue_free()


func test_video_camera_has_is_using_camera_method() -> void:
	var camera := VideoCamera.new()
	add_child(camera)

	assert_true(camera.has_method("is_using_camera"), "VideoCamera must have is_using_camera method")

	camera.queue_free()


func test_video_camera_name_contains_camera() -> void:
	var camera := VideoCamera.new()
	camera.name = "VideoCamera"  # Set node name
	add_child(camera)

	var name_check := "camera" in camera.name.to_lower()
	assert_true(name_check, "VideoCamera name must contain 'camera'")

	camera.queue_free()


func test_phantom_camera_detection_interface() -> void:
	# Simulate what Phantom._check_player_using_camera does
	var camera := VideoCamera.new()
	camera.name = "VideoCamera"
	add_child(camera)

	# Check 1: has_method("take_photo")
	var is_camera := camera.has_method("take_photo")
	assert_true(is_camera, "Camera must be detected via take_photo method")

	# Check 2: has_method("is_aiming") and call it
	if camera.has_method("is_aiming"):
		var aiming: bool = camera.is_aiming()
		assert_false(aiming, "Camera should not be aiming by default")

	camera.queue_free()


func test_camera_aiming_state_changes() -> void:
	var camera := VideoCamera.new()
	add_child(camera)

	# Initially not aiming
	assert_false(camera.is_aiming(), "Should not be aiming initially")

	# Toggle aim mode (simulate use)
	camera._is_aiming = true  # Direct state change for test
	assert_true(camera.is_aiming(), "Should be aiming after toggle")

	camera.queue_free()
