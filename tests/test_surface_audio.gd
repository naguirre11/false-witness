extends GutTest
## Tests for SurfaceAudio resource.

# --- SurfaceType Enum Tests ---


func test_surface_type_enum_values() -> void:
	assert_eq(SurfaceAudio.SurfaceType.DEFAULT, 0)
	assert_eq(SurfaceAudio.SurfaceType.WOOD, 1)
	assert_eq(SurfaceAudio.SurfaceType.CONCRETE, 2)
	assert_eq(SurfaceAudio.SurfaceType.CARPET, 3)
	assert_eq(SurfaceAudio.SurfaceType.TILE, 4)
	assert_eq(SurfaceAudio.SurfaceType.METAL, 5)
	assert_eq(SurfaceAudio.SurfaceType.GRASS, 6)
	assert_eq(SurfaceAudio.SurfaceType.GRAVEL, 7)
	assert_eq(SurfaceAudio.SurfaceType.WATER, 8)


func test_surface_type_count() -> void:
	assert_eq(SurfaceAudio.SurfaceType.size(), 9)


# --- Static Helper Tests ---


func test_get_default_surface_name() -> void:
	var name: String = SurfaceAudio.get_default_surface_name()
	assert_eq(name, "DEFAULT")


func test_surface_type_to_name() -> void:
	assert_eq(SurfaceAudio.surface_type_to_name(SurfaceAudio.SurfaceType.DEFAULT), "DEFAULT")
	assert_eq(SurfaceAudio.surface_type_to_name(SurfaceAudio.SurfaceType.WOOD), "WOOD")
	assert_eq(SurfaceAudio.surface_type_to_name(SurfaceAudio.SurfaceType.CARPET), "CARPET")
	assert_eq(SurfaceAudio.surface_type_to_name(SurfaceAudio.SurfaceType.METAL), "METAL")


func test_name_to_surface_type() -> void:
	assert_eq(SurfaceAudio.name_to_surface_type("DEFAULT"), SurfaceAudio.SurfaceType.DEFAULT)
	assert_eq(SurfaceAudio.name_to_surface_type("WOOD"), SurfaceAudio.SurfaceType.WOOD)
	assert_eq(SurfaceAudio.name_to_surface_type("carpet"), SurfaceAudio.SurfaceType.CARPET)
	assert_eq(SurfaceAudio.name_to_surface_type("METAL"), SurfaceAudio.SurfaceType.METAL)


func test_name_to_surface_type_invalid_returns_default() -> void:
	assert_eq(SurfaceAudio.name_to_surface_type("INVALID"), SurfaceAudio.SurfaceType.DEFAULT)
	assert_eq(SurfaceAudio.name_to_surface_type(""), SurfaceAudio.SurfaceType.DEFAULT)


# --- SurfaceAudio Instance Tests ---


func test_default_values() -> void:
	var audio := SurfaceAudio.new()
	assert_eq(audio.surface_type, SurfaceAudio.SurfaceType.DEFAULT)
	assert_almost_eq(audio.volume_offset_db, 0.0, 0.01)
	assert_almost_eq(audio.pitch_variation, 0.1, 0.01)
	assert_true(audio.crouch_reduces_volume)
	assert_almost_eq(audio.crouch_volume_reduction_db, -6.0, 0.01)


func test_get_surface_name() -> void:
	var audio := SurfaceAudio.new()
	audio.surface_type = SurfaceAudio.SurfaceType.WOOD
	assert_eq(audio.get_surface_name(), "WOOD")


func test_get_random_footstep_empty_returns_null() -> void:
	var audio := SurfaceAudio.new()
	assert_null(audio.get_random_footstep())


func test_get_random_footstep_single_sound() -> void:
	var audio := SurfaceAudio.new()
	var stream := AudioStreamGenerator.new()
	audio.footstep_sounds = [stream]

	var result := audio.get_random_footstep()
	assert_eq(result, stream)


func test_get_random_footstep_multiple_sounds() -> void:
	var audio := SurfaceAudio.new()
	var stream1 := AudioStreamGenerator.new()
	var stream2 := AudioStreamGenerator.new()
	audio.footstep_sounds = [stream1, stream2]

	# Should return one of the streams (random)
	var result := audio.get_random_footstep()
	assert_true(result == stream1 or result == stream2)


# --- Volume Calculation Tests ---


func test_get_footstep_volume_base() -> void:
	var audio := SurfaceAudio.new()
	audio.volume_offset_db = 0.0

	var volume: float = audio.get_footstep_volume(0.0, false)
	assert_almost_eq(volume, 0.0, 0.01)


func test_get_footstep_volume_with_offset() -> void:
	var audio := SurfaceAudio.new()
	audio.volume_offset_db = -3.0

	var volume: float = audio.get_footstep_volume(0.0, false)
	assert_almost_eq(volume, -3.0, 0.01)


func test_get_footstep_volume_crouching() -> void:
	var audio := SurfaceAudio.new()
	audio.volume_offset_db = 0.0
	audio.crouch_reduces_volume = true
	audio.crouch_volume_reduction_db = -6.0

	var volume: float = audio.get_footstep_volume(0.0, true)
	assert_almost_eq(volume, -6.0, 0.01)


func test_get_footstep_volume_crouching_disabled() -> void:
	var audio := SurfaceAudio.new()
	audio.volume_offset_db = 0.0
	audio.crouch_reduces_volume = false
	audio.crouch_volume_reduction_db = -6.0

	var volume: float = audio.get_footstep_volume(0.0, true)
	assert_almost_eq(volume, 0.0, 0.01)


func test_get_footstep_volume_combined() -> void:
	var audio := SurfaceAudio.new()
	audio.volume_offset_db = 3.0  # Loud surface (metal)
	audio.crouch_reduces_volume = true
	audio.crouch_volume_reduction_db = -6.0

	# Base -5 dB + offset 3 dB + crouch -6 dB = -8 dB
	var volume: float = audio.get_footstep_volume(-5.0, true)
	assert_almost_eq(volume, -8.0, 0.01)


# --- Pitch Variation Tests ---


func test_get_random_pitch_range() -> void:
	var audio := SurfaceAudio.new()
	audio.pitch_variation = 0.1

	# Test multiple times to verify range
	for i in range(10):
		var pitch: float = audio.get_random_pitch()
		assert_true(pitch >= 0.9, "Pitch should be >= 0.9, got %f" % pitch)
		assert_true(pitch <= 1.1, "Pitch should be <= 1.1, got %f" % pitch)


func test_get_random_pitch_zero_variation() -> void:
	var audio := SurfaceAudio.new()
	audio.pitch_variation = 0.0

	var pitch: float = audio.get_random_pitch()
	assert_almost_eq(pitch, 1.0, 0.01)


# --- Surface Type Specific Tests ---


func test_carpet_surface_quieter() -> void:
	var carpet := SurfaceAudio.new()
	carpet.surface_type = SurfaceAudio.SurfaceType.CARPET
	carpet.volume_offset_db = -3.0

	var standard := SurfaceAudio.new()
	standard.volume_offset_db = 0.0

	var carpet_vol: float = carpet.get_footstep_volume(0.0, false)
	var std_vol: float = standard.get_footstep_volume(0.0, false)

	assert_true(carpet_vol < std_vol)


func test_metal_surface_louder() -> void:
	var metal := SurfaceAudio.new()
	metal.surface_type = SurfaceAudio.SurfaceType.METAL
	metal.volume_offset_db = 3.0

	var standard := SurfaceAudio.new()
	standard.volume_offset_db = 0.0

	var metal_vol: float = metal.get_footstep_volume(0.0, false)
	var std_vol: float = standard.get_footstep_volume(0.0, false)

	assert_true(metal_vol > std_vol)
