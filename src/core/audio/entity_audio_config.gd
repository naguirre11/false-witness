class_name EntityAudioConfig
extends Resource
## Configuration for entity-specific audio.
##
## Defines all sounds for an entity type including footsteps, vocalizations,
## hunt audio, and manifestation sounds. Each entity type should have its
## own EntityAudioConfig resource.

# --- Footstep Configuration ---

@export_group("Footsteps")

## Footstep sounds during normal movement (ACTIVE state)
@export var footsteps_normal: Array[AudioStream] = []

## Footstep sounds during hunt (faster, more menacing)
@export var footsteps_hunt: Array[AudioStream] = []

## Interval between footsteps in seconds (normal movement)
@export var footstep_interval_normal: float = 0.6

## Interval between footsteps in seconds (during hunt)
@export var footstep_interval_hunt: float = 0.4

## Volume offset for footsteps in dB
@export var footstep_volume_db: float = 0.0

## Pitch variation for footsteps (random range around 1.0)
@export_range(0.0, 0.3) var footstep_pitch_variation: float = 0.1

# --- Vocalization Configuration ---

@export_group("Vocalizations")

## Ambient vocalizations when entity is nearby (groans, whispers)
@export var ambient_vocalizations: Array[AudioStream] = []

## Hunt vocalizations (growls, screams during chase)
@export var hunt_vocalizations: Array[AudioStream] = []

## Manifestation appearance sounds
@export var manifestation_sounds: Array[AudioStream] = []

## Behavioral tell sounds (entity-specific)
@export var behavioral_tell_sounds: Array[AudioStream] = []

## Interval between ambient vocalizations (seconds)
@export var ambient_vocalization_interval: float = 15.0

## Volume for vocalizations in dB
@export var vocalization_volume_db: float = 0.0

# --- Hunt Audio Configuration ---

@export_group("Hunt Audio")

## Sound played at hunt warning start (ominous buildup)
@export var hunt_warning_sound: AudioStream

## Sound played when hunt actually begins (after warning)
@export var hunt_start_sound: AudioStream

## Sound played when hunt ends (relief or creature retreating)
@export var hunt_end_sound: AudioStream

## Looping ambient sound during hunt
@export var hunt_ambient_loop: AudioStream

## Volume for hunt audio in dB
@export var hunt_audio_volume_db: float = 0.0

# --- Kill Audio ---

@export_group("Kill Audio")

## Sound played when entity kills a player
@export var kill_sound: AudioStream

## Volume for kill sound in dB
@export var kill_volume_db: float = 3.0

# --- Spatial Audio Settings ---

@export_group("Spatial Settings")

## Unit size for spatial audio falloff (smaller = more localized)
@export var spatial_unit_size: float = 2.0

## Maximum audible distance for entity sounds
@export var max_audible_distance: float = 50.0

## Whether footsteps use closer spatial settings
@export var use_close_range_footsteps: bool = true

# --- Helper Methods ---


## Gets a random footstep sound for the current state.
## Returns null if no sounds are configured.
func get_random_footstep(is_hunting: bool) -> AudioStream:
	var sounds: Array[AudioStream] = footsteps_hunt if is_hunting else footsteps_normal
	if sounds.is_empty():
		return null
	return sounds[randi() % sounds.size()]


## Gets a random ambient vocalization.
func get_random_ambient_vocalization() -> AudioStream:
	if ambient_vocalizations.is_empty():
		return null
	return ambient_vocalizations[randi() % ambient_vocalizations.size()]


## Gets a random hunt vocalization.
func get_random_hunt_vocalization() -> AudioStream:
	if hunt_vocalizations.is_empty():
		return null
	return hunt_vocalizations[randi() % hunt_vocalizations.size()]


## Gets a random manifestation sound.
func get_random_manifestation_sound() -> AudioStream:
	if manifestation_sounds.is_empty():
		return null
	return manifestation_sounds[randi() % manifestation_sounds.size()]


## Gets a random behavioral tell sound.
func get_random_tell_sound() -> AudioStream:
	if behavioral_tell_sounds.is_empty():
		return null
	return behavioral_tell_sounds[randi() % behavioral_tell_sounds.size()]


## Gets a random pitch value for variation.
func get_random_pitch() -> float:
	return randf_range(1.0 - footstep_pitch_variation, 1.0 + footstep_pitch_variation)


## Gets the footstep interval based on hunting state.
func get_footstep_interval(is_hunting: bool) -> float:
	return footstep_interval_hunt if is_hunting else footstep_interval_normal
