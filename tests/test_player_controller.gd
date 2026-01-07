extends GutTest
## Tests for PlayerController - first-person movement, stamina, crouch, and head bob.

const PlayerControllerScript = preload("res://src/player/player_controller.gd")

var player: CharacterBody3D
var collision_shape: CollisionShape3D
var head: Node3D
var camera: Camera3D


func before_each() -> void:
	# Create player with minimal scene structure for testing
	player = PlayerControllerScript.new()
	player.is_local_player = false  # Disable mouse capture in tests

	# Create collision shape
	collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.8
	capsule.radius = 0.35
	collision_shape.shape = capsule
	collision_shape.position.y = 0.9
	player.add_child(collision_shape)

	# Create head with camera
	head = Node3D.new()
	head.name = "Head"
	head.position.y = 1.6
	player.add_child(head)

	camera = Camera3D.new()
	camera.name = "Camera3D"
	head.add_child(camera)

	add_child_autofree(player)


# === Initialization Tests ===

func test_player_initializes_with_full_stamina() -> void:
	assert_eq(
		player.current_stamina,
		player.max_stamina,
		"Player should start with full stamina"
	)


func test_player_initializes_not_sprinting() -> void:
	assert_false(player.is_sprinting, "Player should not be sprinting initially")


func test_player_initializes_not_crouching() -> void:
	assert_false(player.is_crouching, "Player should not be crouching initially")


func test_player_initializes_with_input_enabled() -> void:
	assert_true(player.input_enabled, "Input should be enabled initially")


# === Speed Calculation Tests ===

func test_get_current_speed_returns_walk_speed_by_default() -> void:
	var speed: float = player._get_current_speed()
	assert_eq(speed, player.walk_speed, "Default speed should be walk speed")


func test_get_current_speed_returns_crouch_speed_when_crouching() -> void:
	player.is_crouching = true
	var speed: float = player._get_current_speed()
	assert_eq(speed, player.crouch_speed, "Speed should be crouch speed when crouching")


func test_get_current_speed_returns_sprint_speed_when_sprinting() -> void:
	player.is_sprinting = true
	player.current_stamina = player.max_stamina
	var speed: float = player._get_current_speed()
	assert_eq(speed, player.sprint_speed, "Speed should be sprint speed when sprinting")


func test_crouch_speed_overrides_sprint() -> void:
	player.is_crouching = true
	player.is_sprinting = true
	var speed: float = player._get_current_speed()
	assert_eq(speed, player.crouch_speed, "Crouch should override sprint for speed calculation")


# === Stamina Tests ===

func test_get_stamina_percent_full() -> void:
	player.current_stamina = player.max_stamina
	assert_eq(
		player.get_stamina_percent(),
		1.0,
		"Full stamina should return 1.0"
	)


func test_get_stamina_percent_half() -> void:
	player.current_stamina = player.max_stamina / 2.0
	assert_almost_eq(
		player.get_stamina_percent(),
		0.5,
		0.01,
		"Half stamina should return 0.5"
	)


func test_get_stamina_percent_empty() -> void:
	player.current_stamina = 0.0
	assert_eq(player.get_stamina_percent(), 0.0, "Empty stamina should return 0.0")


func test_stamina_changed_signal_emitted() -> void:
	var signal_data := {"received": false, "current": 0.0, "max": 0.0}
	player.stamina_changed.connect(func(current: float, maximum: float):
		signal_data["received"] = true
		signal_data["current"] = current
		signal_data["max"] = maximum
	)

	# Trigger stamina change via reset
	player.reset_state()

	assert_true(signal_data["received"], "stamina_changed should be emitted")
	assert_eq(signal_data["current"], player.max_stamina, "Current stamina should be max")


# === Crouch Tests ===

func test_start_crouch_sets_state() -> void:
	player._start_crouch()
	assert_true(player.is_crouching, "is_crouching should be true after _start_crouch")


func test_start_crouch_stops_sprinting() -> void:
	player.is_sprinting = true
	player._start_crouch()
	assert_false(player.is_sprinting, "Sprinting should stop when crouching")


func test_start_crouch_sets_target_height() -> void:
	player._start_crouch()
	assert_eq(
		player._target_height,
		player.crouch_height,
		"Target height should be crouch height"
	)


func test_crouch_signal_emitted_on_start() -> void:
	var signal_data := {"received": false, "is_crouching": false}
	player.crouched.connect(func(is_crouching: bool):
		signal_data["received"] = true
		signal_data["is_crouching"] = is_crouching
	)

	player._start_crouch()

	assert_true(signal_data["received"], "crouched signal should be emitted")
	assert_true(signal_data["is_crouching"], "Signal should indicate crouching")


func test_can_stand_up_returns_true_when_no_obstruction() -> void:
	# In test environment without physics world, should return true
	var can_stand: bool = player._can_stand_up()
	assert_true(can_stand, "Should be able to stand when no obstruction")


# === Movement Detection Tests ===

func test_is_moving_false_when_stationary() -> void:
	player.velocity = Vector3.ZERO
	assert_false(player._is_moving(), "Should not be moving when velocity is zero")


func test_is_moving_true_when_walking() -> void:
	player.velocity = Vector3(2, 0, 2)
	assert_true(player._is_moving(), "Should be moving when velocity is non-zero")


func test_is_moving_ignores_vertical_velocity() -> void:
	player.velocity = Vector3(0, -5, 0)  # Falling
	assert_false(player._is_moving(), "Vertical velocity should not count as moving")


# === Horizontal Speed Tests ===

func test_get_horizontal_speed_zero_when_stationary() -> void:
	player.velocity = Vector3.ZERO
	assert_eq(player.get_horizontal_speed(), 0.0, "Horizontal speed should be zero")


func test_get_horizontal_speed_ignores_vertical() -> void:
	player.velocity = Vector3(3, -10, 4)  # 3,4 horizontal = 5 speed
	assert_almost_eq(
		player.get_horizontal_speed(),
		5.0,
		0.01,
		"Horizontal speed should ignore Y component"
	)


# === Input Control Tests ===

func test_set_input_enabled_false_stops_sprinting() -> void:
	player.is_sprinting = true
	player.set_input_enabled(false)
	assert_false(player.is_sprinting, "Sprinting should stop when input disabled")
	assert_false(player.input_enabled, "input_enabled should be false")


func test_set_input_enabled_true() -> void:
	player.input_enabled = false
	player.set_input_enabled(true)
	assert_true(player.input_enabled, "input_enabled should be true")


# === Network State Tests ===

func test_get_network_state_includes_position() -> void:
	player.position = Vector3(10, 5, 20)
	var state: Dictionary = player.get_network_state()
	assert_eq(state.position, Vector3(10, 5, 20), "Network state should include position")


func test_get_network_state_includes_velocity() -> void:
	player.velocity = Vector3(1, 2, 3)
	var state: Dictionary = player.get_network_state()
	assert_eq(state.velocity, Vector3(1, 2, 3), "Network state should include velocity")


func test_get_network_state_includes_crouch_state() -> void:
	player.is_crouching = true
	var state: Dictionary = player.get_network_state()
	assert_true(state.is_crouching, "Network state should include crouch state")


func test_get_network_state_includes_stamina() -> void:
	player.current_stamina = 50.0
	var state: Dictionary = player.get_network_state()
	assert_eq(state.stamina, 50.0, "Network state should include stamina")


func test_apply_network_state_updates_position() -> void:
	var state := {"position": Vector3(100, 50, 200)}
	player.apply_network_state(state)
	assert_eq(player.position, Vector3(100, 50, 200), "Position should be updated from network")


func test_apply_network_state_updates_velocity() -> void:
	var state := {"velocity": Vector3(5, 0, 5)}
	player.apply_network_state(state)
	assert_eq(player.velocity, Vector3(5, 0, 5), "Velocity should be updated from network")


func test_apply_network_state_updates_crouch() -> void:
	var state := {"is_crouching": true}
	player.apply_network_state(state)
	assert_true(player.is_crouching, "Crouch state should be updated from network")
	assert_eq(player._target_height, player.crouch_height, "Target height should update")


# === Teleport Tests ===

func test_teleport_sets_position() -> void:
	player.teleport(Vector3(100, 0, 100))
	assert_eq(player.global_position, Vector3(100, 0, 100), "Teleport should set position")


func test_teleport_sets_rotation() -> void:
	player.teleport(Vector3.ZERO, Vector3(0, PI, 0))
	assert_eq(player.rotation, Vector3(0, PI, 0), "Teleport should set rotation")


func test_teleport_resets_velocity() -> void:
	player.velocity = Vector3(10, 5, 10)
	player.teleport(Vector3.ZERO)
	assert_eq(player.velocity, Vector3.ZERO, "Teleport should reset velocity")


# === Reset State Tests ===

func test_reset_state_restores_full_stamina() -> void:
	player.current_stamina = 0.0
	player.reset_state()
	assert_eq(
		player.current_stamina,
		player.max_stamina,
		"Reset should restore full stamina"
	)


func test_reset_state_clears_sprint() -> void:
	player.is_sprinting = true
	player.reset_state()
	assert_false(player.is_sprinting, "Reset should clear sprinting")


func test_reset_state_clears_crouch() -> void:
	player.is_crouching = true
	player._target_height = player.crouch_height
	player.reset_state()
	assert_false(player.is_crouching, "Reset should clear crouching")
	assert_eq(player._target_height, player.standing_height, "Reset should restore standing height")


func test_reset_state_clears_velocity() -> void:
	player.velocity = Vector3(5, 2, 5)
	player.reset_state()
	assert_eq(player.velocity, Vector3.ZERO, "Reset should clear velocity")


func test_reset_state_clears_timers() -> void:
	player.head_bob_time = 5.0
	player.footstep_timer = 0.3
	player.stamina_regen_timer = 1.0
	player.reset_state()
	assert_eq(player.head_bob_time, 0.0, "Reset should clear head bob time")
	assert_eq(player.footstep_timer, 0.0, "Reset should clear footstep timer")
	assert_eq(player.stamina_regen_timer, 0.0, "Reset should clear stamina regen timer")


# === Footstep Signal Tests ===

func test_footstep_signal_exists() -> void:
	# Verify the signal exists and can be connected
	var signal_received := {"value": false}
	player.footstep.connect(func(): signal_received["value"] = true)

	player._play_footstep()

	assert_true(signal_received["value"], "footstep signal should be emitted")


# === Configuration Tests ===

func test_default_walk_speed_reasonable() -> void:
	assert_gt(player.walk_speed, 0.0, "Walk speed should be positive")
	assert_lt(player.walk_speed, 20.0, "Walk speed should be reasonable")


func test_sprint_speed_faster_than_walk() -> void:
	assert_gt(
		player.sprint_speed,
		player.walk_speed,
		"Sprint speed should be faster than walk speed"
	)


func test_crouch_speed_slower_than_walk() -> void:
	assert_lt(
		player.crouch_speed,
		player.walk_speed,
		"Crouch speed should be slower than walk speed"
	)


func test_crouch_height_less_than_standing() -> void:
	assert_lt(
		player.crouch_height,
		player.standing_height,
		"Crouch height should be less than standing height"
	)


func test_min_sprint_stamina_less_than_max() -> void:
	assert_lt(
		player.min_sprint_stamina,
		player.max_stamina,
		"Min sprint stamina should be less than max"
	)
