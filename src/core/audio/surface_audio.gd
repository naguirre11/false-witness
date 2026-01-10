class_name SurfaceAudio
extends Resource
## Defines audio properties for a surface type.
##
## Used by FootstepManager to play appropriate sounds based on
## the surface the player is walking on.

# --- Surface Types ---

enum SurfaceType {
	DEFAULT,  ## Fallback for untagged surfaces
	WOOD,  ## Wooden floors, boards
	CONCRETE,  ## Concrete, stone floors
	CARPET,  ## Carpeted floors (quieter)
	TILE,  ## Ceramic/bathroom tiles
	METAL,  ## Metal grating, plates
	GRASS,  ## Outdoor grass
	GRAVEL,  ## Gravel paths
	WATER,  ## Shallow water puddles
}

# --- Export ---

@export var surface_type: SurfaceType = SurfaceType.DEFAULT

## Footstep sounds for this surface. Randomly selected per step.
@export var footstep_sounds: Array[AudioStream] = []

## Volume offset in dB relative to base footstep volume.
## Negative = quieter (carpet), Positive = louder (metal)
@export var volume_offset_db: float = 0.0

## Pitch variation range (random pitch between 1.0 - variation and 1.0 + variation)
@export_range(0.0, 0.3) var pitch_variation: float = 0.1

## Whether crouch reduces volume further on this surface
@export var crouch_reduces_volume: bool = true

## Additional volume reduction when crouching (in dB)
@export var crouch_volume_reduction_db: float = -6.0


## Gets a random footstep sound from the list.
## Returns null if no sounds are configured.
func get_random_footstep() -> AudioStream:
	if footstep_sounds.is_empty():
		return null
	return footstep_sounds[randi() % footstep_sounds.size()]


## Gets the final volume for a footstep on this surface.
## base_volume_db: The base volume for footsteps.
## is_crouching: Whether the player is crouching.
func get_footstep_volume(base_volume_db: float, is_crouching: bool) -> float:
	var volume: float = base_volume_db + volume_offset_db
	if is_crouching and crouch_reduces_volume:
		volume += crouch_volume_reduction_db
	return volume


## Gets a random pitch value for variation.
func get_random_pitch() -> float:
	return randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)


## Gets the surface type name as a string.
func get_surface_name() -> String:
	return SurfaceType.keys()[surface_type]


# --- Static Helpers ---


## Gets the default surface type name.
static func get_default_surface_name() -> String:
	return "DEFAULT"


## Converts a SurfaceType to its string name.
static func surface_type_to_name(type: SurfaceType) -> String:
	return SurfaceType.keys()[type]


## Converts a string name to SurfaceType. Returns DEFAULT if not found.
static func name_to_surface_type(name_str: String) -> SurfaceType:
	var upper: String = name_str.to_upper()
	for i: int in range(SurfaceType.size()):
		if SurfaceType.keys()[i] == upper:
			return i as SurfaceType
	return SurfaceType.DEFAULT
