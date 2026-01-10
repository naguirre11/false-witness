# gdlint: ignore=max-public-methods
extends GutTest
## Tests for EchoController - spectral observer movement and visibility.

const EchoControllerScript = preload("res://src/player/echo_controller.gd")

var echo: CharacterBody3D
var head: Node3D
var camera: Camera3D
var mesh: MeshInstance3D


func before_each() -> void:
	# Create echo with minimal scene structure
	echo = EchoControllerScript.new()
	echo.is_local = false  # Disable mouse capture in tests

	# Create head with camera
	head = Node3D.new()
	head.name = "Head"
	echo.add_child(head)

	camera = Camera3D.new()
	camera.name = "Camera3D"
	head.add_child(camera)

	# Create mesh for translucent appearance
	mesh = MeshInstance3D.new()
	mesh.name = "MeshInstance3D"
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.5
	mesh.mesh = capsule
	echo.add_child(mesh)

	# Create collision shape (will be disabled)
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.radius = 0.3
	capsule_shape.height = 1.5
	collision.shape = capsule_shape
	echo.add_child(collision)

	add_child_autofree(echo)


# === Initialization Tests ===


func test_echo_initializes_with_input_enabled() -> void:
	assert_true(echo.input_enabled, "Echo should have input enabled by default")


func test_echo_initializes_not_moving() -> void:
	assert_false(echo.is_moving, "Echo should not be moving initially")


func test_echo_initializes_with_zero_velocity() -> void:
	assert_eq(echo.velocity, Vector3.ZERO, "Echo should start with zero velocity")


# === Collision Tests ===


func test_echo_collision_layer_is_zero() -> void:
	assert_eq(echo.collision_layer, 0, "Echo collision layer should be 0 (no collisions)")


func test_echo_collision_mask_is_zero() -> void:
	assert_eq(echo.collision_mask, 0, "Echo collision mask should be 0 (no collisions)")


func test_echo_collision_shape_is_disabled() -> void:
	var collision := echo.get_node_or_null("CollisionShape3D") as CollisionShape3D
	assert_not_null(collision, "CollisionShape3D should exist")
	assert_true(collision.disabled, "Collision shape should be disabled for wall passing")


# === Entity Visibility Tests ===


func test_echo_can_see_entity() -> void:
	assert_true(echo.can_see_entity(), "Echo should always be able to see entity")


func test_echo_ignores_entity_visibility() -> void:
	assert_true(echo.ignores_entity_visibility(), "Echo should ignore entity visibility state")


# === Movement Constants ===


func test_echo_has_reduced_gravity() -> void:
	assert_lt(
		EchoControllerScript.ECHO_GRAVITY, 9.8, "Echo gravity should be less than normal gravity"
	)


func test_echo_float_speed_comparable_to_player() -> void:
	# Echo speed should be reasonable (comparable to player walk speed ~4.0)
	assert_gt(echo.float_speed, 2.0, "Echo should move reasonably fast")
	assert_lt(echo.float_speed, 10.0, "Echo should not move too fast")


func test_echo_glide_deceleration_allows_momentum() -> void:
	# Deceleration should be less than 1 (0.92 means 8% speed loss per frame)
	assert_lt(echo.glide_deceleration, 1.0, "Glide should reduce speed")
	assert_gt(echo.glide_deceleration, 0.5, "Glide should not stop immediately")


# === Movement Tests ===


func test_echo_glide_deceleration_reduces_velocity() -> void:
	echo.velocity = Vector3(5, 0, 5)
	var initial_speed: float = echo.velocity.length()

	# Simulate deceleration
	echo._apply_glide_deceleration(0.016)

	assert_lt(echo.velocity.length(), initial_speed, "Velocity should decrease after deceleration")


func test_echo_stops_at_velocity_threshold() -> void:
	echo.velocity = Vector3(0.05, 0, 0.05)  # Below threshold
	echo.is_moving = true

	echo._apply_glide_deceleration(0.016)

	assert_eq(echo.velocity, Vector3.ZERO, "Velocity should snap to zero below threshold")
	assert_false(echo.is_moving, "is_moving should be false when stopped")


func test_echo_get_horizontal_speed() -> void:
	echo.velocity = Vector3(3, 2, 4)  # 3,4 horizontal = 5 speed

	var speed: float = echo.get_horizontal_speed()

	assert_almost_eq(speed, 5.0, 0.01, "Horizontal speed should ignore Y component")


func test_echo_get_horizontal_speed_zero_when_stationary() -> void:
	echo.velocity = Vector3.ZERO
	assert_eq(echo.get_horizontal_speed(), 0.0, "Horizontal speed should be zero when stationary")


# === Visual Appearance Tests ===


func test_echo_is_visible_to_living() -> void:
	assert_true(echo.is_visible_to_living(), "Echo should be visible to living players")


func test_echo_has_outline_color() -> void:
	var color: Color = echo.get_outline_color()
	assert_gt(color.a, 0.0, "Outline color should have some opacity")
	assert_lt(color.a, 1.0, "Outline color should be translucent")


func test_echo_has_opacity() -> void:
	var opacity: float = echo.get_echo_opacity()
	assert_gt(opacity, 0.0, "Echo should have some visibility")
	assert_lt(opacity, 1.0, "Echo should be translucent")


func test_setup_translucent_appearance_applies_material() -> void:
	echo.setup_translucent_appearance()

	var mesh_node := echo.get_node_or_null("MeshInstance3D") as MeshInstance3D
	assert_not_null(mesh_node, "MeshInstance3D should exist")
	assert_not_null(mesh_node.material_override, "Material override should be applied")


func test_translucent_material_has_alpha_transparency() -> void:
	echo.setup_translucent_appearance()

	var mesh_node := echo.get_node_or_null("MeshInstance3D") as MeshInstance3D
	var material := mesh_node.material_override as StandardMaterial3D

	assert_not_null(material, "Material should be StandardMaterial3D")
	assert_eq(
		material.transparency,
		BaseMaterial3D.TRANSPARENCY_ALPHA,
		"Material should use alpha transparency"
	)


# === Voice Chat Stub Tests ===


func test_echo_can_use_voice_chat() -> void:
	assert_true(echo.can_use_voice_chat(), "Echo should be able to use voice chat")


func test_echo_has_ethereal_voice() -> void:
	assert_true(echo.has_ethereal_voice(), "Echo should have ethereal voice effect")


func test_echo_voice_settings_returns_dictionary() -> void:
	var settings: Dictionary = echo.get_voice_settings()

	assert_true(settings.has("enabled"), "Voice settings should have enabled key")
	assert_true(settings.has("ethereal_reverb"), "Voice settings should have reverb key")
	assert_true(settings.enabled, "Voice should be enabled")
	assert_true(settings.ethereal_reverb, "Ethereal reverb should be enabled")


# === Network State Tests ===


func test_echo_get_network_state_includes_position() -> void:
	echo.position = Vector3(10, 5, 20)
	var state: Dictionary = echo.get_network_state()
	assert_eq(state.position, Vector3(10, 5, 20), "Network state should include position")


func test_echo_get_network_state_includes_velocity() -> void:
	echo.velocity = Vector3(1, 2, 3)
	var state: Dictionary = echo.get_network_state()
	assert_eq(state.velocity, Vector3(1, 2, 3), "Network state should include velocity")


func test_echo_get_network_state_includes_player_id() -> void:
	echo.player_id = 12345
	var state: Dictionary = echo.get_network_state()
	assert_eq(state.player_id, 12345, "Network state should include player_id")


func test_echo_apply_network_state_updates_position() -> void:
	var state := {"position": Vector3(100, 50, 200)}
	echo.apply_network_state(state)
	assert_eq(echo.position, Vector3(100, 50, 200), "Position should be updated from network")


func test_echo_apply_network_state_updates_velocity() -> void:
	var state := {"velocity": Vector3(5, 0, 5)}
	echo.apply_network_state(state)
	assert_eq(echo.velocity, Vector3(5, 0, 5), "Velocity should be updated from network")


# === Input Control Tests ===


func test_set_input_enabled_false() -> void:
	echo.set_input_enabled(false)
	assert_false(echo.input_enabled, "input_enabled should be false")


func test_set_input_enabled_true() -> void:
	echo.input_enabled = false
	echo.set_input_enabled(true)
	assert_true(echo.input_enabled, "input_enabled should be true")


# === Death Position Tests ===


func test_echo_stores_death_position() -> void:
	echo.death_position = Vector3(15, 0, 25)
	assert_eq(echo.death_position, Vector3(15, 0, 25), "Death position should be stored")


func test_echo_stores_player_id() -> void:
	echo.player_id = 98765
	assert_eq(echo.player_id, 98765, "Player ID should be stored")


# === Movement Signal Tests ===


func test_movement_stopped_signal_on_stop() -> void:
	var signal_data := {"received": false}
	echo.movement_stopped.connect(func(): signal_data["received"] = true)

	echo.velocity = Vector3(0.01, 0, 0.01)  # Near threshold
	echo.is_moving = true

	echo._apply_glide_deceleration(0.016)

	assert_true(signal_data["received"], "movement_stopped should be emitted when stopping")


# === Echo Restriction Tests (FW-043c) ===


func test_echo_cannot_use_equipment() -> void:
	assert_false(echo.can_use_equipment(), "Echo should not be able to use equipment")


func test_echo_cannot_interact() -> void:
	assert_false(echo.can_interact(), "Echo should not be able to interact with objects")


func test_echo_cannot_collect_evidence() -> void:
	assert_false(echo.can_collect_evidence(), "Echo should not be able to collect evidence")


func test_echo_cannot_use_cultist_abilities() -> void:
	assert_false(echo.can_use_cultist_abilities(), "Echo cannot use Cultist abilities")


func test_echo_is_not_valid_hunt_target() -> void:
	assert_false(echo.is_valid_hunt_target(), "Echo should not be valid hunt target")


# === Revival System Tests (FW-043d) ===


func test_echo_can_be_revived_initially() -> void:
	assert_true(echo.can_be_revived(), "Echo should be revivable initially")


func test_echo_cannot_be_revived_after_already_revived() -> void:
	echo.times_revived = 1
	assert_false(echo.can_be_revived(), "Echo should not be revivable after already revived")


func test_echo_not_being_revived_initially() -> void:
	assert_false(echo.is_being_revived(), "Echo should not be in revival state initially")


func test_start_revival_returns_true_when_valid() -> void:
	var result: bool = echo.start_revival(100)
	assert_true(result, "start_revival should return true for valid revival")


func test_start_revival_sets_channeling_state() -> void:
	echo.start_revival(100)
	assert_eq(echo.revival_state, echo.RevivalState.CHANNELING, "Should be in CHANNELING state")


func test_start_revival_sets_reviver_id() -> void:
	echo.start_revival(12345)
	assert_eq(echo.reviver_id, 12345, "reviver_id should be set")


func test_start_revival_emits_signal() -> void:
	var signal_data := {"received": false, "reviver": -1}
	echo.revival_started.connect(
		func(r):
			signal_data["received"] = true
			signal_data["reviver"] = r
	)

	echo.start_revival(999)

	assert_true(signal_data["received"], "revival_started signal should be emitted")
	assert_eq(signal_data["reviver"], 999, "Signal should pass reviver_id")


func test_start_revival_fails_when_already_revived() -> void:
	echo.times_revived = 1
	var result: bool = echo.start_revival(100)
	assert_false(result, "start_revival should fail when already revived")


func test_start_revival_fails_when_already_channeling() -> void:
	echo.start_revival(100)
	var result: bool = echo.start_revival(200)
	assert_false(result, "start_revival should fail when already channeling")


func test_is_being_revived_true_during_channeling() -> void:
	echo.start_revival(100)
	assert_true(echo.is_being_revived(), "is_being_revived should be true during channeling")


func test_update_revival_increases_progress() -> void:
	echo.start_revival(100)
	echo.update_revival(1.0)

	assert_almost_eq(echo.revival_progress, 1.0, 0.01, "Progress should increase by delta")


func test_update_revival_emits_progress_signal() -> void:
	var signal_data := {"progress": 0.0, "duration": 0.0}
	echo.revival_progress_changed.connect(
		func(p, d):
			signal_data["progress"] = p
			signal_data["duration"] = d
	)

	echo.start_revival(100)
	echo.update_revival(5.0)

	assert_almost_eq(signal_data["progress"], 5.0, 0.01, "Progress value should be emitted")
	assert_eq(signal_data["duration"], echo.REVIVAL_DURATION, "Duration should be emitted")


func test_update_revival_completes_when_duration_reached() -> void:
	var completed := {"value": false}
	echo.revival_completed.connect(func(): completed["value"] = true)

	echo.start_revival(100)
	echo.update_revival(30.0)  # Full duration

	assert_true(completed["value"], "revival_completed should be emitted")
	assert_eq(echo.revival_state, echo.RevivalState.COMPLETE, "State should be COMPLETE")


func test_revival_increments_times_revived() -> void:
	echo.start_revival(100)
	echo.update_revival(30.0)

	assert_eq(echo.times_revived, 1, "times_revived should be incremented")


func test_cancel_revival_resets_state() -> void:
	echo.start_revival(100)
	echo.update_revival(10.0)

	echo.cancel_revival()

	assert_eq(echo.revival_state, echo.RevivalState.IDLE, "State should be IDLE after cancel")
	assert_eq(echo.revival_progress, 0.0, "Progress should be reset")
	assert_eq(echo.reviver_id, -1, "reviver_id should be reset")


func test_cancel_revival_emits_signal() -> void:
	var cancelled := {"value": false}
	echo.revival_cancelled.connect(func(): cancelled["value"] = true)

	echo.start_revival(100)
	echo.cancel_revival()

	assert_true(cancelled["value"], "revival_cancelled should be emitted")


func test_on_hunt_started_cancels_revival() -> void:
	echo.start_revival(100)
	echo.update_revival(15.0)

	echo.on_hunt_started()

	assert_eq(echo.revival_state, echo.RevivalState.IDLE, "Hunt should cancel revival")
	assert_eq(echo.revival_progress, 0.0, "Progress should be reset by hunt")


func test_get_revival_progress_percent() -> void:
	echo.start_revival(100)
	echo.update_revival(15.0)  # Half of 30s

	var percent: float = echo.get_revival_progress_percent()

	assert_almost_eq(percent, 0.5, 0.01, "Progress should be 50%")


func test_get_revival_progress_percent_returns_zero_when_not_channeling() -> void:
	var percent: float = echo.get_revival_progress_percent()
	assert_eq(percent, 0.0, "Progress should be 0 when not channeling")


func test_get_reviver_id_returns_negative_when_not_reviving() -> void:
	assert_eq(echo.get_reviver_id(), -1, "Should return -1 when no one is reviving")


func test_update_revival_does_nothing_when_not_channeling() -> void:
	echo.update_revival(5.0)
	assert_eq(echo.revival_progress, 0.0, "Progress should not change when not channeling")


func test_cancel_revival_does_nothing_when_not_channeling() -> void:
	var cancelled := {"value": false}
	echo.revival_cancelled.connect(func(): cancelled["value"] = true)

	echo.cancel_revival()

	assert_false(cancelled["value"], "Signal should not emit when not channeling")
