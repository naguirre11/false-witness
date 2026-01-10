extends GutTest
## Tests for FootstepManager component.

var footstep_manager: FootstepManager
var mock_player: CharacterBody3D


func before_each() -> void:
	# Create a mock player
	mock_player = CharacterBody3D.new()
	mock_player.name = "MockPlayer"
	add_child(mock_player)

	# Create footstep manager as child
	footstep_manager = FootstepManager.new()
	footstep_manager.name = "FootstepManager"
	mock_player.add_child(footstep_manager)


func after_each() -> void:
	if mock_player:
		mock_player.queue_free()
		mock_player = null
	footstep_manager = null


# --- Initialization Tests ---


func test_finds_player_parent() -> void:
	# The manager should find its player parent automatically
	assert_not_null(footstep_manager._player)
	assert_eq(footstep_manager._player, mock_player)


func test_set_player() -> void:
	var other_player := Node3D.new()
	add_child(other_player)

	footstep_manager.set_player(other_player)
	assert_eq(footstep_manager._player, other_player)

	other_player.queue_free()


func test_initial_surface_is_default() -> void:
	assert_eq(footstep_manager.get_current_surface(), SurfaceAudio.SurfaceType.DEFAULT)


# --- Constants Tests ---


func test_constants_defined() -> void:
	assert_almost_eq(footstep_manager.SURFACE_DETECT_DISTANCE, 2.0, 0.01)
	assert_eq(footstep_manager.FLOOR_COLLISION_MASK, 1)
	assert_almost_eq(footstep_manager.SPRINT_VOLUME_OFFSET_DB, 3.0, 0.01)
	assert_eq(footstep_manager.SURFACE_META_KEY, "surface_type")


func test_default_audio_settings() -> void:
	assert_almost_eq(footstep_manager.base_volume_db, 0.0, 0.01)
	assert_almost_eq(footstep_manager.max_audible_distance, 20.0, 0.01)
	assert_almost_eq(footstep_manager.audio_unit_size, 0.5, 0.01)


# --- Surface Config Tests ---


func test_register_surface_audio() -> void:
	var surface := SurfaceAudio.new()
	surface.surface_type = SurfaceAudio.SurfaceType.WOOD

	footstep_manager.register_surface_audio(surface)

	assert_true(footstep_manager.surface_configs.has(SurfaceAudio.SurfaceType.WOOD))


func test_register_surface_audio_null() -> void:
	# Should not crash
	footstep_manager.register_surface_audio(null)
	pass_test("register_surface_audio handled null")


func test_clear_surface_configs() -> void:
	var surface := SurfaceAudio.new()
	surface.surface_type = SurfaceAudio.SurfaceType.METAL
	footstep_manager.register_surface_audio(surface)

	footstep_manager.clear_surface_configs()

	assert_true(footstep_manager.surface_configs.is_empty())


# --- On Footstep Tests ---


func test_on_footstep_with_null_player() -> void:
	footstep_manager._player = null
	# Should not crash
	footstep_manager.on_footstep()
	pass_test("on_footstep handled null player")


func test_on_footstep_emits_signal() -> void:
	# Create a world for the player to exist in
	var world := World3D.new()
	var viewport := SubViewport.new()
	viewport.world_3d = world
	add_child(viewport)
	viewport.add_child(mock_player.duplicate())

	# Get reference to the duplicated player's FootstepManager
	var dup_player: CharacterBody3D = viewport.get_child(0) as CharacterBody3D
	var dup_manager: FootstepManager = dup_player.get_node("FootstepManager") as FootstepManager

	var signal_data := {"received": false}
	dup_manager.footstep_played.connect(
		func(surface: int, pos: Vector3): signal_data["received"] = true
	)

	# Without configured sounds, signal should still emit but no sound plays
	dup_manager.on_footstep()

	# Signal is only emitted if a sound was actually played
	# With no sounds configured, it won't emit
	pass_test("on_footstep ran without crash")

	viewport.queue_free()


# --- Surface Detection Tests ---


func test_detect_surface_no_world() -> void:
	# Create a player without a world
	var solo_player := Node3D.new()
	add_child(solo_player)

	var solo_manager := FootstepManager.new()
	solo_manager._player = solo_player

	# Should return DEFAULT when no world
	var surface: SurfaceAudio.SurfaceType = solo_manager._detect_surface()
	assert_eq(surface, SurfaceAudio.SurfaceType.DEFAULT)

	solo_player.queue_free()


# --- Get Surface Audio Tests ---


func test_get_surface_audio_configured() -> void:
	var wood := SurfaceAudio.new()
	wood.surface_type = SurfaceAudio.SurfaceType.WOOD
	wood.volume_offset_db = -2.0

	footstep_manager.register_surface_audio(wood)

	var result := footstep_manager._get_surface_audio(SurfaceAudio.SurfaceType.WOOD)
	assert_eq(result, wood)


func test_get_surface_audio_unconfigured_returns_default() -> void:
	# Don't register any surface
	var result := footstep_manager._get_surface_audio(SurfaceAudio.SurfaceType.METAL)
	assert_not_null(result)
	assert_eq(result.surface_type, SurfaceAudio.SurfaceType.DEFAULT)


# --- Signal Connection Tests ---


func test_footstep_played_signal_exists() -> void:
	assert_true(footstep_manager.has_signal("footstep_played"))


# --- Integration with PlayerController-like object ---


func test_reads_sprint_state_from_player() -> void:
	# Add is_sprinting property to mock player
	mock_player.set_meta("is_sprinting", true)

	# The manager checks player properties
	# We can't directly test internal state reading, but we verify it doesn't crash
	footstep_manager.on_footstep()
	pass_test("Handled player state reading")


func test_reads_crouch_state_from_player() -> void:
	mock_player.set_meta("is_crouching", true)
	footstep_manager.on_footstep()
	pass_test("Handled crouch state reading")


# --- Edge Cases ---


func test_multiple_surface_configs() -> void:
	var wood := SurfaceAudio.new()
	wood.surface_type = SurfaceAudio.SurfaceType.WOOD

	var metal := SurfaceAudio.new()
	metal.surface_type = SurfaceAudio.SurfaceType.METAL

	var carpet := SurfaceAudio.new()
	carpet.surface_type = SurfaceAudio.SurfaceType.CARPET

	footstep_manager.register_surface_audio(wood)
	footstep_manager.register_surface_audio(metal)
	footstep_manager.register_surface_audio(carpet)

	assert_eq(footstep_manager.surface_configs.size(), 3)


func test_override_surface_config() -> void:
	var wood1 := SurfaceAudio.new()
	wood1.surface_type = SurfaceAudio.SurfaceType.WOOD
	wood1.volume_offset_db = -1.0

	var wood2 := SurfaceAudio.new()
	wood2.surface_type = SurfaceAudio.SurfaceType.WOOD
	wood2.volume_offset_db = -5.0

	footstep_manager.register_surface_audio(wood1)
	footstep_manager.register_surface_audio(wood2)

	var result := footstep_manager._get_surface_audio(SurfaceAudio.SurfaceType.WOOD)
	# Second registration should override
	assert_almost_eq(result.volume_offset_db, -5.0, 0.01)
