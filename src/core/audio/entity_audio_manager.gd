extends Node
## EntityAudioManager autoload for entity-specific audio.
##
## Manages all entity-related audio including:
## - Hunt audio (warning, start, chase, end)
## - Entity footsteps during movement
## - Ambient vocalizations based on proximity
## - Manifestation audio
## - Audio occlusion through walls
## - Dynamic mixing based on aggression level
## - Silence as horror cue
##
## Connects to EventBus signals for decoupled audio triggers.
## No class_name to avoid conflicts with autoload singleton name.

# --- Signals ---

signal hunt_audio_started
signal hunt_audio_ended
signal ambient_suppressed(is_suppressed: bool)

# --- Constants ---

## Bus names (from AudioManager)
const BUS_SFX := "SFX"
const BUS_AMBIENT := "Ambient"

## Occlusion settings
const OCCLUSION_RAY_OFFSET := Vector3(0, 1.5, 0)  # Roughly head height
const OCCLUSION_VOLUME_REDUCTION_DB := -12.0  # Volume drop when occluded
const OCCLUSION_UPDATE_INTERVAL := 0.2  # Seconds between occlusion checks

## Ambient proximity settings
const PROXIMITY_CHECK_INTERVAL := 1.0  # Seconds between proximity checks
const PROXIMITY_FAR_THRESHOLD := 30.0  # Distance for faint ambient
const PROXIMITY_NEAR_THRESHOLD := 10.0  # Distance for loud ambient
const PROXIMITY_VOLUME_FAR_DB := -18.0  # Volume at far threshold
const PROXIMITY_VOLUME_NEAR_DB := -3.0  # Volume at near threshold

## Silence horror cue settings
const SILENCE_FADE_DURATION := 2.0  # Seconds to fade ambient to silence
const SILENCE_HOLD_DURATION := 3.0  # Seconds of near-silence before danger

## Footstep timing
const FOOTSTEP_TIMER_UPDATE := 0.05  # Update granularity

# --- State ---

## Currently tracked entity (for audio attachment)
var _entity: Node = null

## Entity audio configuration
var _entity_config: EntityAudioConfig = null

## References to AudioManager
var _audio_manager: Node = null

## Occlusion state
var _player_camera: Node3D = null
var _occlusion_timer: float = 0.0
var _is_occluded: bool = false

## Proximity ambient state
var _proximity_timer: float = 0.0
var _ambient_player: AudioStreamPlayer3D = null

## Hunt audio state
var _is_hunt_active: bool = false
var _hunt_ambient_player: AudioStreamPlayer3D = null
var _hunt_vocalization_timer: float = 0.0
var _hunt_vocalization_interval: float = 5.0

## Footstep state
var _footstep_timer: float = 0.0
var _entity_was_moving: bool = false

## Silence horror cue state
var _ambient_target_volume_db: float = 0.0
var _is_silence_cue_active: bool = false
var _silence_timer: float = 0.0

## Aggression-based mixing
var _current_aggression_phase: int = 0  # 0=dormant, 1=active, 2=aggressive, 3=furious
var _aggression_ambient_modifier_db: float = 0.0

## Listener dormant audio state
var _listener_dormant_player: AudioStreamPlayer3D = null
var _listener_dormant_entity: Node = null


func _ready() -> void:
	_find_audio_manager()
	_connect_event_bus_signals()


func _process(delta: float) -> void:
	_update_occlusion(delta)
	_update_proximity_ambient(delta)
	_update_footsteps(delta)
	_update_hunt_vocalizations(delta)
	_update_silence_cue(delta)


# --- Initialization ---


func _find_audio_manager() -> void:
	_audio_manager = get_node_or_null("/root/AudioManager")
	if not _audio_manager:
		push_warning("[EntityAudioManager] AudioManager not found")


func _connect_event_bus_signals() -> void:
	if not EventBus:
		push_warning("[EntityAudioManager] EventBus not found")
		return

	# Hunt lifecycle signals
	EventBus.hunt_warning_started.connect(_on_hunt_warning_started)
	EventBus.hunt_warning_ended.connect(_on_hunt_warning_ended)
	EventBus.hunt_started.connect(_on_hunt_started)
	EventBus.hunt_ended.connect(_on_hunt_ended)

	# Entity signals
	EventBus.entity_spawned.connect(_on_entity_spawned)
	EventBus.entity_removed.connect(_on_entity_removed)
	EventBus.entity_tell_triggered.connect(_on_entity_tell_triggered)
	EventBus.entity_manifesting.connect(_on_entity_manifesting)
	EventBus.entity_manifestation_ended.connect(_on_entity_manifestation_ended)
	EventBus.entity_aggression_changed.connect(_on_entity_aggression_changed)
	EventBus.entity_state_changed.connect(_on_entity_state_changed)

	# Player death
	EventBus.player_died.connect(_on_player_died)


# --- Public API ---


## Sets the entity to track for audio.
## Call this when an entity spawns or is assigned.
func set_entity(entity: Node, config: EntityAudioConfig) -> void:
	_entity = entity
	_entity_config = config
	_reset_timers()

	if entity and entity.has_signal("state_changed"):
		if not entity.state_changed.is_connected(_on_entity_state_direct):
			entity.state_changed.connect(_on_entity_state_direct)


## Clears the tracked entity.
func clear_entity() -> void:
	if _entity and _entity.has_signal("state_changed"):
		if _entity.state_changed.is_connected(_on_entity_state_direct):
			_entity.state_changed.disconnect(_on_entity_state_direct)

	_entity = null
	_entity_config = null
	_stop_all_entity_audio()


## Sets the player camera for occlusion checks.
func set_player_camera(camera: Node3D) -> void:
	_player_camera = camera


## Gets whether ambient audio is currently suppressed (silence cue).
func is_ambient_suppressed() -> bool:
	return _is_silence_cue_active


## Triggers the silence horror cue manually.
## Used when something dangerous is about to happen.
func trigger_silence_cue() -> void:
	if not _is_silence_cue_active:
		_start_silence_cue()


## Stops the silence horror cue.
func stop_silence_cue() -> void:
	if _is_silence_cue_active:
		_end_silence_cue()


# --- Event Handlers: Hunt Lifecycle ---


func _on_hunt_warning_started(entity_position: Vector3, _duration: float) -> void:
	if not _entity_config:
		return

	# Play hunt warning sound
	if _entity_config.hunt_warning_sound:
		_play_sound_3d(
			_entity_config.hunt_warning_sound,
			entity_position,
			BUS_SFX,
			_entity_config.hunt_audio_volume_db
		)

	# Start silence cue during warning
	_start_silence_cue()


func _on_hunt_warning_ended(hunt_proceeding: bool) -> void:
	if not hunt_proceeding:
		# Hunt was prevented - end silence cue with relief
		_end_silence_cue()


func _on_hunt_started() -> void:
	_is_hunt_active = true
	_hunt_vocalization_timer = 0.0

	if not _entity_config:
		return

	# Play hunt start stinger
	if _entity_config.hunt_start_sound and _entity:
		var pos: Vector3 = _entity.global_position if _entity is Node3D else Vector3.ZERO
		var hunt_volume := _entity_config.hunt_audio_volume_db + 3.0  # Louder
		_play_sound_3d(_entity_config.hunt_start_sound, pos, BUS_SFX, hunt_volume)

	# Start hunt ambient loop
	if _entity_config.hunt_ambient_loop and _entity:
		_start_hunt_ambient()

	hunt_audio_started.emit()


func _on_hunt_ended() -> void:
	_is_hunt_active = false

	# Stop hunt ambient
	_stop_hunt_ambient()

	# End silence cue
	_end_silence_cue()

	if not _entity_config:
		return

	# Play hunt end sound
	if _entity_config.hunt_end_sound and _entity:
		var pos: Vector3 = _entity.global_position if _entity is Node3D else Vector3.ZERO
		_play_sound_3d(
			_entity_config.hunt_end_sound, pos, BUS_SFX, _entity_config.hunt_audio_volume_db
		)

	hunt_audio_ended.emit()


# --- Event Handlers: Entity Events ---


func _on_entity_spawned(_entity_type: String, _room: String) -> void:
	# Entity spawned - actual entity reference will be set via set_entity()
	pass


func _on_entity_removed() -> void:
	clear_entity()


func _on_entity_tell_triggered(tell_type: String) -> void:
	if not _entity_config or not _entity:
		return

	# Play behavioral tell sound
	var tell_sound := _entity_config.get_random_tell_sound()
	if tell_sound:
		var pos: Vector3 = _entity.global_position if _entity is Node3D else Vector3.ZERO
		_play_sound_3d(tell_sound, pos, BUS_SFX, _entity_config.vocalization_volume_db)

	print("[EntityAudioManager] Tell audio: %s" % tell_type)


func _on_entity_manifesting(position: Vector3) -> void:
	if not _entity_config:
		return

	# Play manifestation sound
	var manifest_sound := _entity_config.get_random_manifestation_sound()
	if manifest_sound:
		_play_sound_3d(manifest_sound, position, BUS_SFX, _entity_config.vocalization_volume_db)


func _on_entity_manifestation_ended() -> void:
	# Could play a fade-out sound here if desired
	pass


func _on_entity_aggression_changed(phase: int, _phase_name: String) -> void:
	_current_aggression_phase = phase
	_update_aggression_mixing()


func _on_entity_state_changed(_old_state: int, _new_state: int) -> void:
	# Reset footstep timer on state change
	_footstep_timer = 0.0


func _on_entity_state_direct(_old_state: int, _new_state: int) -> void:
	# Direct entity state change (when connected to entity signal)
	_footstep_timer = 0.0


func _on_player_died(_player_id: int) -> void:
	if not _entity_config or not _entity:
		return

	# Play kill sound
	if _entity_config.kill_sound:
		var pos: Vector3 = _entity.global_position if _entity is Node3D else Vector3.ZERO
		_play_sound_3d(_entity_config.kill_sound, pos, BUS_SFX, _entity_config.kill_volume_db)


# --- Audio Playback ---


func _play_sound_3d(
	stream: AudioStream, position: Vector3, bus: String, volume_db: float
) -> AudioStreamPlayer3D:
	if not _audio_manager:
		return null

	# Apply occlusion if occluded
	var final_volume: float = volume_db
	if _is_occluded:
		final_volume += OCCLUSION_VOLUME_REDUCTION_DB

	# Apply aggression modifier
	final_volume += _aggression_ambient_modifier_db

	var settings: Dictionary = _audio_manager.get_long_range_settings()
	if _entity_config:
		settings.unit_size = _entity_config.spatial_unit_size
		settings.max_distance = _entity_config.max_audible_distance

	return _audio_manager.play_sound_3d(
		stream, position, bus, final_volume, settings.unit_size, settings.max_distance
	)


func _play_sound_attached(
	stream: AudioStream, attach_to: Node3D, bus: String, volume_db: float
) -> AudioStreamPlayer3D:
	if not _audio_manager:
		return null

	var final_volume: float = volume_db
	if _is_occluded:
		final_volume += OCCLUSION_VOLUME_REDUCTION_DB

	var settings: Dictionary = _audio_manager.get_long_range_settings()
	if _entity_config:
		settings.unit_size = _entity_config.spatial_unit_size
		settings.max_distance = _entity_config.max_audible_distance

	return _audio_manager.play_sound_attached(
		stream, attach_to, bus, final_volume, settings.unit_size, settings.max_distance
	)


# --- Occlusion ---


func _update_occlusion(delta: float) -> void:
	if not _entity or not _player_camera:
		return

	_occlusion_timer -= delta
	if _occlusion_timer > 0:
		return

	_occlusion_timer = OCCLUSION_UPDATE_INTERVAL
	_is_occluded = _check_occlusion()


func _check_occlusion() -> bool:
	if not _entity or not _player_camera:
		return false

	if not _entity is Node3D:
		return false

	var entity_pos: Vector3 = (_entity as Node3D).global_position + OCCLUSION_RAY_OFFSET
	var camera_pos: Vector3 = _player_camera.global_position

	var space_state: PhysicsDirectSpaceState3D = _player_camera.get_world_3d().direct_space_state
	if not space_state:
		return false

	var query := PhysicsRayQueryParameters3D.create(camera_pos, entity_pos)
	query.collision_mask = 1  # World geometry only
	query.exclude = [_entity]

	var result := space_state.intersect_ray(query)

	# If we hit something, entity is occluded
	return not result.is_empty()


# --- Proximity Ambient ---


func _update_proximity_ambient(delta: float) -> void:
	# Early exit conditions
	var can_play := _entity and _player_camera and _entity_config and not _is_hunt_active
	if not can_play or not _entity is Node3D:
		if _is_hunt_active:
			_stop_ambient_player()
		return

	_proximity_timer -= delta
	if _proximity_timer > 0:
		return

	_proximity_timer = PROXIMITY_CHECK_INTERVAL

	var distance: float = _player_camera.global_position.distance_to(
		(_entity as Node3D).global_position
	)

	# Only play ambient when within far threshold
	if distance > PROXIMITY_FAR_THRESHOLD:
		_stop_ambient_player()
		return

	# Check if it's time for a vocalization (30% chance each proximity check)
	var ambient_sound := _entity_config.get_random_ambient_vocalization()
	if not ambient_sound or randf() >= 0.3:
		return

	# Calculate volume based on distance
	var t: float = inverse_lerp(PROXIMITY_FAR_THRESHOLD, PROXIMITY_NEAR_THRESHOLD, distance)
	t = clampf(t, 0.0, 1.0)
	var volume_db: float = lerpf(PROXIMITY_VOLUME_FAR_DB, PROXIMITY_VOLUME_NEAR_DB, t)

	# Apply occlusion
	if _is_occluded:
		volume_db += OCCLUSION_VOLUME_REDUCTION_DB

	_play_sound_3d(ambient_sound, (_entity as Node3D).global_position, BUS_AMBIENT, volume_db)


func _stop_ambient_player() -> void:
	if _ambient_player and is_instance_valid(_ambient_player):
		_ambient_player.stop()
		_ambient_player.queue_free()
		_ambient_player = null


# --- Footsteps ---


func _update_footsteps(delta: float) -> void:
	if not _entity or not _entity_config:
		return

	if not _entity is CharacterBody3D:
		return

	var entity_body := _entity as CharacterBody3D

	# Check if entity is moving
	var is_moving: bool = entity_body.velocity.length_squared() > 0.1

	if not is_moving:
		_entity_was_moving = false
		return

	# Check if entity is in a state that produces footsteps
	var entity_state: int = -1
	if _entity.has_method("get_state"):
		entity_state = _entity.get_state()

	# Only footsteps in ACTIVE (1) or HUNTING (2) states
	var should_footstep: bool = entity_state in [1, 2]  # Entity.EntityState.ACTIVE, HUNTING
	if not should_footstep:
		return

	var is_hunting: bool = entity_state == 2

	_footstep_timer -= delta
	if _footstep_timer > 0:
		return

	# Reset timer
	_footstep_timer = _entity_config.get_footstep_interval(is_hunting)

	# Play footstep
	var footstep_sound := _entity_config.get_random_footstep(is_hunting)
	if not footstep_sound:
		return

	var volume_db: float = _entity_config.footstep_volume_db

	# Use close range settings for footsteps if configured
	var unit_size: float = _entity_config.spatial_unit_size
	var max_distance: float = _entity_config.max_audible_distance

	if _entity_config.use_close_range_footsteps and _audio_manager:
		var close_settings: Dictionary = _audio_manager.get_close_range_settings()
		unit_size = close_settings.unit_size
		max_distance = close_settings.max_distance

	var pos: Vector3 = entity_body.global_position
	var player: AudioStreamPlayer3D = _audio_manager.play_sound_3d(
		footstep_sound, pos, BUS_SFX, volume_db, unit_size, max_distance
	)

	if player:
		player.pitch_scale = _entity_config.get_random_pitch()

	_entity_was_moving = true


# --- Hunt Vocalizations ---


func _update_hunt_vocalizations(delta: float) -> void:
	if not _is_hunt_active or not _entity or not _entity_config:
		return

	_hunt_vocalization_timer -= delta
	if _hunt_vocalization_timer > 0:
		return

	# Random interval with some variation
	_hunt_vocalization_timer = _hunt_vocalization_interval * randf_range(0.7, 1.3)

	var hunt_sound := _entity_config.get_random_hunt_vocalization()
	if not hunt_sound:
		return

	if _entity is Node3D:
		_play_sound_3d(
			hunt_sound,
			(_entity as Node3D).global_position,
			BUS_SFX,
			_entity_config.vocalization_volume_db
		)


func _start_hunt_ambient() -> void:
	if not _entity_config or not _entity_config.hunt_ambient_loop:
		return

	if not _entity or not _entity is Node3D:
		return

	_stop_hunt_ambient()

	_hunt_ambient_player = _play_sound_attached(
		_entity_config.hunt_ambient_loop,
		_entity as Node3D,
		BUS_AMBIENT,
		_entity_config.hunt_audio_volume_db
	)


func _stop_hunt_ambient() -> void:
	if _hunt_ambient_player and is_instance_valid(_hunt_ambient_player):
		_hunt_ambient_player.stop()
		_hunt_ambient_player.queue_free()
		_hunt_ambient_player = null


# --- Silence Horror Cue ---


func _start_silence_cue() -> void:
	if _is_silence_cue_active:
		return

	_is_silence_cue_active = true
	_silence_timer = 0.0
	ambient_suppressed.emit(true)

	# Fade down ambient bus
	if _audio_manager:
		_ambient_target_volume_db = _audio_manager.get_bus_volume_db(BUS_AMBIENT)
		# Start fading ambient
		var tween := create_tween()
		tween.tween_method(
			_set_ambient_volume, _ambient_target_volume_db, -40.0, SILENCE_FADE_DURATION  # Near-silence
		)


func _end_silence_cue() -> void:
	if not _is_silence_cue_active:
		return

	_is_silence_cue_active = false
	ambient_suppressed.emit(false)

	# Restore ambient bus
	if _audio_manager:
		var tween := create_tween()
		tween.tween_method(
			_set_ambient_volume,
			_audio_manager.get_bus_volume_db(BUS_AMBIENT),
			_ambient_target_volume_db,
			SILENCE_FADE_DURATION * 0.5  # Faster recovery
		)


func _update_silence_cue(_delta: float) -> void:
	# Silence cue is managed by tweens, no per-frame update needed
	pass


func _set_ambient_volume(volume_db: float) -> void:
	if _audio_manager:
		_audio_manager.set_bus_volume_db(BUS_AMBIENT, volume_db)


# --- Aggression Mixing ---


func _update_aggression_mixing() -> void:
	# Adjust ambient audio intensity based on aggression phase
	# Higher aggression = more intense ambient, lower base ambient
	match _current_aggression_phase:
		0:  # DORMANT
			_aggression_ambient_modifier_db = 0.0
		1:  # ACTIVE
			_aggression_ambient_modifier_db = 1.0
		2:  # AGGRESSIVE
			_aggression_ambient_modifier_db = 2.0
		3:  # FURIOUS
			_aggression_ambient_modifier_db = 3.0


# --- Utility ---


func _reset_timers() -> void:
	_occlusion_timer = 0.0
	_proximity_timer = 0.0
	_footstep_timer = 0.0
	_hunt_vocalization_timer = 0.0
	_silence_timer = 0.0


func _stop_all_entity_audio() -> void:
	_stop_ambient_player()
	_stop_hunt_ambient()
	_end_silence_cue()
	_stop_listener_dormant_internal()


# --- Listener Dormant Audio (FW-046-05) ---


## Plays the Listener's dormant phase ambient sound.
## Called by Listener entity when entering dormant (listening) phase.
## Audio is spatial - audible within ~10m with position tracking.
func play_listener_dormant(listener_entity: Node, volume_scale: float = 1.0) -> void:
	if not _audio_manager:
		return

	# Stop any existing dormant audio
	_stop_listener_dormant_internal()

	if not listener_entity or not listener_entity is Node3D:
		return

	_listener_dormant_entity = listener_entity

	# Get dormant sound from entity config or use default placeholder
	var dormant_sound: AudioStream = null
	if _entity_config and _entity_config.has_method("get_dormant_ambient_sound"):
		dormant_sound = _entity_config.get_dormant_ambient_sound()

	# Fallback: if no specific sound, try to get generic ambient
	if not dormant_sound and _entity_config:
		dormant_sound = _entity_config.get_random_ambient_vocalization()

	if not dormant_sound:
		# No audio available - just track the entity
		print("[EntityAudioManager] No dormant sound configured for Listener")
		return

	# Calculate volume with scale
	var volume_db: float = -12.0 + (volume_scale - 1.0) * 6.0  # Quiet base, scaled

	# Use close-range spatial settings for subtle detection
	var unit_size: float = 2.0  # 2m unit size for subtle falloff
	var max_distance: float = 10.0  # Audible within 10m as specified

	_listener_dormant_player = AudioStreamPlayer3D.new()
	_listener_dormant_player.stream = dormant_sound
	_listener_dormant_player.volume_db = volume_db
	_listener_dormant_player.unit_size = unit_size
	_listener_dormant_player.max_distance = max_distance
	_listener_dormant_player.bus = BUS_AMBIENT
	_listener_dormant_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE

	# Attach to entity so it follows position
	(listener_entity as Node3D).add_child(_listener_dormant_player)

	# Enable looping if supported
	if dormant_sound.has_method("set_loop"):
		dormant_sound.set_loop(true)

	_listener_dormant_player.play()
	print("[EntityAudioManager] Listener dormant audio started")


## Stops the Listener's dormant phase ambient sound.
## Called by Listener entity when exiting dormant phase.
func stop_listener_dormant(listener_entity: Node) -> void:
	if _listener_dormant_entity != listener_entity:
		return  # Not the entity we're tracking

	_stop_listener_dormant_internal()


## Internal method to stop dormant audio.
func _stop_listener_dormant_internal() -> void:
	if _listener_dormant_player and is_instance_valid(_listener_dormant_player):
		_listener_dormant_player.stop()
		_listener_dormant_player.queue_free()
		_listener_dormant_player = null

	_listener_dormant_entity = null
