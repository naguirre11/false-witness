class_name FootstepManager
extends Node
## Manages footstep audio for a player.
##
## Detects the surface type beneath the player and plays
## appropriate footstep sounds with variation.
##
## Attach this to a player scene or as a child of PlayerController.
## Connect the PlayerController's footstep signal to on_footstep().

# --- Signals ---

signal footstep_played(surface_type: int, position: Vector3)

# --- Constants ---

## Raycast distance for surface detection
const SURFACE_DETECT_DISTANCE := 2.0

## Collision mask for floor detection (Layer 1 = World)
const FLOOR_COLLISION_MASK := 1

## Default footstep volume in dB
const DEFAULT_VOLUME_DB := 0.0

## Volume reduction when sprinting (actually louder)
const SPRINT_VOLUME_OFFSET_DB := 3.0

## Meta key for surface type on meshes/bodies
const SURFACE_META_KEY := "surface_type"

# --- Export ---

@export_group("Audio Settings")

## Base volume for footsteps in dB
@export var base_volume_db: float = DEFAULT_VOLUME_DB

## Maximum distance at which footsteps can be heard
@export var max_audible_distance: float = 20.0

## Unit size for spatial audio falloff
@export var audio_unit_size: float = 0.5

@export_group("Surface Configuration")

## Surface audio configurations by type
@export var surface_configs: Dictionary = {}

# --- State ---

var _player: Node3D
var _current_surface: SurfaceAudio.SurfaceType = SurfaceAudio.SurfaceType.DEFAULT
var _default_surface_audio: SurfaceAudio


func _ready() -> void:
	_setup_default_surface()
	_find_player()


func _setup_default_surface() -> void:
	# Create a default surface audio for when no specific surface is detected
	_default_surface_audio = SurfaceAudio.new()
	_default_surface_audio.surface_type = SurfaceAudio.SurfaceType.DEFAULT
	_default_surface_audio.volume_offset_db = 0.0
	_default_surface_audio.pitch_variation = 0.1


func _find_player() -> void:
	# Try to find the player parent
	var parent := get_parent()
	if parent is Node3D:
		_player = parent


## Sets the player node for position tracking.
func set_player(player: Node3D) -> void:
	_player = player


## Called when the player takes a footstep.
## Queries the player for sprint/crouch state if available.
func on_footstep() -> void:
	if _player == null:
		return

	# Query player state
	var is_sprinting := false
	var is_crouching := false
	if _player.has_method("get") or "is_sprinting" in _player:
		is_sprinting = _player.get("is_sprinting") as bool
	if _player.has_method("get") or "is_crouching" in _player:
		is_crouching = _player.get("is_crouching") as bool

	var surface_type := _detect_surface()
	var surface_audio := _get_surface_audio(surface_type)
	var sound := surface_audio.get_random_footstep()

	if sound == null:
		# No sound configured for this surface, skip
		return

	# Calculate volume
	var volume: float = surface_audio.get_footstep_volume(base_volume_db, is_crouching)
	if is_sprinting:
		volume += SPRINT_VOLUME_OFFSET_DB

	# Play the sound spatially
	_play_footstep_sound(sound, volume, surface_audio.get_random_pitch())

	_current_surface = surface_type
	footstep_played.emit(surface_type, _player.global_position)


## Detects the surface type beneath the player.
func _detect_surface() -> SurfaceAudio.SurfaceType:
	var detected := SurfaceAudio.SurfaceType.DEFAULT

	if _player == null:
		return detected

	var space_state := _player.get_world_3d().direct_space_state
	if space_state == null:
		return detected

	# Raycast downward from player position
	var origin := _player.global_position
	var end := origin + Vector3.DOWN * SURFACE_DETECT_DISTANCE

	var query := PhysicsRayQueryParameters3D.create(origin, end, FLOOR_COLLISION_MASK)
	var result := space_state.intersect_ray(query)

	if result.is_empty():
		return detected

	# Check for surface type metadata on the collider
	var collider: Object = result.get("collider")
	detected = _extract_surface_from_collider(collider)

	return detected


## Extracts surface type from a collider object or its hierarchy.
func _extract_surface_from_collider(collider: Object) -> SurfaceAudio.SurfaceType:
	if collider == null:
		return SurfaceAudio.SurfaceType.DEFAULT

	# Check direct metadata on collider
	if collider.has_meta(SURFACE_META_KEY):
		var meta_value: Variant = collider.get_meta(SURFACE_META_KEY)
		if meta_value is int:
			return meta_value as SurfaceAudio.SurfaceType
		if meta_value is String:
			return SurfaceAudio.name_to_surface_type(meta_value)

	# Check parent nodes for surface type
	if collider is Node:
		return _find_surface_in_hierarchy(collider as Node)

	return SurfaceAudio.SurfaceType.DEFAULT


## Searches parent nodes for surface type metadata.
func _find_surface_in_hierarchy(node: Node) -> SurfaceAudio.SurfaceType:
	var current: Node = node
	while current != null:
		if current.has_meta(SURFACE_META_KEY):
			var meta_value: Variant = current.get_meta(SURFACE_META_KEY)
			if meta_value is int:
				return meta_value as SurfaceAudio.SurfaceType
			if meta_value is String:
				return SurfaceAudio.name_to_surface_type(meta_value)
		current = current.get_parent()
	return SurfaceAudio.SurfaceType.DEFAULT


## Gets the SurfaceAudio configuration for a surface type.
func _get_surface_audio(surface_type: SurfaceAudio.SurfaceType) -> SurfaceAudio:
	if surface_configs.has(surface_type):
		var config: Variant = surface_configs[surface_type]
		if config is SurfaceAudio:
			return config

	# Fall back to default
	return _default_surface_audio


## Plays a footstep sound at the player's position.
func _play_footstep_sound(sound: AudioStream, volume_db: float, pitch_scale: float) -> void:
	if _player == null:
		return

	# Use AudioManager if available
	if Engine.has_singleton("AudioManager"):
		# Godot autoloads aren't singletons, use get_node
		pass

	# Try to get AudioManager from tree
	var audio_manager: Node = _player.get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("play_sound_3d"):
		var player3d: AudioStreamPlayer3D = audio_manager.play_sound_3d(
			sound,
			_player.global_position,
			audio_manager.BUS_SFX,
			volume_db,
			audio_unit_size,
			max_audible_distance
		)
		if player3d:
			player3d.pitch_scale = pitch_scale
	else:
		# Fallback: create local player
		_play_local_footstep(sound, volume_db, pitch_scale)


## Fallback for playing footstep without AudioManager.
func _play_local_footstep(sound: AudioStream, volume_db: float, pitch_scale: float) -> void:
	var player := AudioStreamPlayer3D.new()
	player.stream = sound
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.unit_size = audio_unit_size
	player.max_distance = max_audible_distance
	player.bus = "SFX"

	add_child(player)
	player.global_position = _player.global_position
	player.finished.connect(player.queue_free)
	player.play()


## Gets the current detected surface type.
func get_current_surface() -> SurfaceAudio.SurfaceType:
	return _current_surface


## Registers a SurfaceAudio configuration for a surface type.
func register_surface_audio(surface_audio: SurfaceAudio) -> void:
	if surface_audio:
		surface_configs[surface_audio.surface_type] = surface_audio


## Clears all surface configurations.
func clear_surface_configs() -> void:
	surface_configs.clear()
