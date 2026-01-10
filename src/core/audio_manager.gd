extends Node
## AudioManager autoload for centralized audio playback and configuration.
##
## Manages audio buses, volume controls, spatial audio settings,
## and provides sound pooling for frequently played sounds.
##
## Audio buses:
## - Master: Overall volume control
## - SFX: Sound effects (footsteps, equipment, interactions)
## - Music: Background music
## - Voice: Voice chat and entity vocalizations
## - Ambient: Environmental sounds

# --- Signals ---

signal volume_changed(bus_name: String, volume_db: float)
signal sound_played(sound_id: String, position: Vector3)

# --- Constants ---

## Bus name constants for type safety
const BUS_MASTER := "Master"
const BUS_SFX := "SFX"
const BUS_MUSIC := "Music"
const BUS_VOICE := "Voice"
const BUS_AMBIENT := "Ambient"

## Valid bus names for validation
const VALID_BUSES: Array[String] = [BUS_MASTER, BUS_SFX, BUS_MUSIC, BUS_VOICE, BUS_AMBIENT]

## Default spatial audio settings for horror atmosphere
const DEFAULT_UNIT_SIZE := 1.0
const DEFAULT_MAX_DISTANCE := 30.0
const DEFAULT_ATTENUATION_MODEL := AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE

## Sound pool settings
const DEFAULT_POOL_SIZE := 8
const MAX_POOL_SIZE := 32

# --- State ---

## Sound pools by sound ID (Dictionary[String, Array[AudioStreamPlayer3D]])
var _sound_pools: Dictionary = {}

## Pool configurations by sound ID (Dictionary[String, Dictionary])
var _pool_configs: Dictionary = {}

## Active 3D sound players for cleanup (Array[AudioStreamPlayer3D])
var _active_3d_players: Array[AudioStreamPlayer3D] = []

## Active 2D sound players for cleanup (Array[AudioStreamPlayer])
var _active_2d_players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	_verify_audio_buses()


## Verifies that all expected audio buses exist.
func _verify_audio_buses() -> void:
	for bus_name: String in VALID_BUSES:
		var idx: int = AudioServer.get_bus_index(bus_name)
		if idx == -1:
			push_warning("[AudioManager] Expected bus '%s' not found" % bus_name)


# --- Volume Control ---


## Gets the volume of a bus in decibels.
func get_bus_volume_db(bus_name: String) -> float:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		push_error("[AudioManager] Bus '%s' not found" % bus_name)
		return 0.0
	return AudioServer.get_bus_volume_db(idx)


## Sets the volume of a bus in decibels.
## volume_db: Volume in dB (0 = normal, -80 = silent, +6 = loud)
func set_bus_volume_db(bus_name: String, volume_db: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		push_error("[AudioManager] Bus '%s' not found" % bus_name)
		return
	AudioServer.set_bus_volume_db(idx, clampf(volume_db, -80.0, 6.0))
	volume_changed.emit(bus_name, volume_db)


## Gets the volume of a bus as a linear value (0.0 to 1.0).
func get_bus_volume_linear(bus_name: String) -> float:
	var db: float = get_bus_volume_db(bus_name)
	return db_to_linear(db)


## Sets the volume of a bus as a linear value (0.0 to 1.0).
func set_bus_volume_linear(bus_name: String, volume: float) -> void:
	var db: float = linear_to_db(clampf(volume, 0.0, 1.0))
	set_bus_volume_db(bus_name, db)


## Mutes or unmutes a bus.
func set_bus_mute(bus_name: String, mute: bool) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		push_error("[AudioManager] Bus '%s' not found" % bus_name)
		return
	AudioServer.set_bus_mute(idx, mute)


## Checks if a bus is muted.
func is_bus_muted(bus_name: String) -> bool:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return false
	return AudioServer.is_bus_mute(idx)


# --- Sound Pooling ---


## Configures a sound pool for frequently played sounds.
## sound_id: Unique identifier for this sound
## stream: The AudioStream to pool
## pool_size: Number of players to pre-create (default 8)
## bus: Audio bus to use (default SFX)
func configure_sound_pool(
	sound_id: String, stream: AudioStream, pool_size: int = DEFAULT_POOL_SIZE, bus: String = BUS_SFX
) -> void:
	if sound_id.is_empty():
		push_error("[AudioManager] Sound ID cannot be empty")
		return
	if stream == null:
		push_error("[AudioManager] Stream cannot be null for sound '%s'" % sound_id)
		return

	pool_size = clampi(pool_size, 1, MAX_POOL_SIZE)

	# Store configuration
	_pool_configs[sound_id] = {
		"stream": stream,
		"bus": bus,
		"pool_size": pool_size,
	}

	# Create the pool
	_sound_pools[sound_id] = []
	for i: int in range(pool_size):
		var player := AudioStreamPlayer.new()
		player.stream = stream
		player.bus = bus
		player.name = "Pool_%s_%d" % [sound_id, i]
		add_child(player)
		_sound_pools[sound_id].append(player)


## Plays a pooled sound (2D, non-spatial).
## Returns true if a player was available, false if all players are busy.
func play_pooled_sound(sound_id: String, volume_db: float = 0.0) -> bool:
	if not _sound_pools.has(sound_id):
		push_warning("[AudioManager] Sound pool '%s' not configured" % sound_id)
		return false

	var pool: Array = _sound_pools[sound_id]
	for player: AudioStreamPlayer in pool:
		if not player.playing:
			player.volume_db = volume_db
			player.play()
			return true

	# All players busy
	return false


## Removes a sound pool and frees its players.
func remove_sound_pool(sound_id: String) -> void:
	if not _sound_pools.has(sound_id):
		return

	var pool: Array = _sound_pools[sound_id]
	for player: AudioStreamPlayer in pool:
		player.queue_free()

	_sound_pools.erase(sound_id)
	_pool_configs.erase(sound_id)


## Gets the number of available (not playing) players in a pool.
func get_pool_available_count(sound_id: String) -> int:
	if not _sound_pools.has(sound_id):
		return 0

	var count := 0
	var pool: Array = _sound_pools[sound_id]
	for player: AudioStreamPlayer in pool:
		if not player.playing:
			count += 1
	return count


# --- One-Shot Sound Playback ---


## Plays a 2D sound (non-spatial) that auto-cleans up.
## Returns the AudioStreamPlayer for further control (or null on failure).
func play_sound(
	stream: AudioStream, bus: String = BUS_SFX, volume_db: float = 0.0
) -> AudioStreamPlayer:
	if stream == null:
		push_error("[AudioManager] Cannot play null stream")
		return null

	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = bus
	player.volume_db = volume_db
	add_child(player)

	player.finished.connect(_on_2d_player_finished.bind(player))
	player.play()

	_active_2d_players.append(player)
	return player


## Plays a 3D spatial sound at a position that auto-cleans up.
## Returns the AudioStreamPlayer3D for further control (or null on failure).
func play_sound_3d(
	stream: AudioStream,
	position: Vector3,
	bus: String = BUS_SFX,
	volume_db: float = 0.0,
	unit_size: float = DEFAULT_UNIT_SIZE,
	max_distance: float = DEFAULT_MAX_DISTANCE
) -> AudioStreamPlayer3D:
	if stream == null:
		push_error("[AudioManager] Cannot play null stream")
		return null

	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.bus = bus
	player.volume_db = volume_db
	player.unit_size = unit_size
	player.max_distance = max_distance
	player.attenuation_model = DEFAULT_ATTENUATION_MODEL
	player.global_position = position
	add_child(player)

	player.finished.connect(_on_3d_player_finished.bind(player))
	player.play()

	_active_3d_players.append(player)
	sound_played.emit(stream.resource_path, position)
	return player


## Plays a 3D spatial sound attached to a node (follows the node).
## Returns the AudioStreamPlayer3D for further control (or null on failure).
func play_sound_attached(
	stream: AudioStream,
	attach_to: Node3D,
	bus: String = BUS_SFX,
	volume_db: float = 0.0,
	unit_size: float = DEFAULT_UNIT_SIZE,
	max_distance: float = DEFAULT_MAX_DISTANCE
) -> AudioStreamPlayer3D:
	if stream == null:
		push_error("[AudioManager] Cannot play null stream")
		return null
	if attach_to == null:
		push_error("[AudioManager] Cannot attach sound to null node")
		return null

	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.bus = bus
	player.volume_db = volume_db
	player.unit_size = unit_size
	player.max_distance = max_distance
	player.attenuation_model = DEFAULT_ATTENUATION_MODEL

	# Add as child of target node so it follows
	attach_to.add_child(player)

	player.finished.connect(_on_attached_player_finished.bind(player))
	player.play()

	sound_played.emit(stream.resource_path, attach_to.global_position)
	return player


func _on_2d_player_finished(player: AudioStreamPlayer) -> void:
	_active_2d_players.erase(player)
	player.queue_free()


func _on_3d_player_finished(player: AudioStreamPlayer3D) -> void:
	_active_3d_players.erase(player)
	player.queue_free()


func _on_attached_player_finished(player: AudioStreamPlayer3D) -> void:
	player.queue_free()


# --- Spatial Audio Configuration ---


## Configures an AudioStreamPlayer3D with horror-appropriate settings.
## Use this to ensure consistent spatial audio across the game.
func configure_spatial_player(
	player: AudioStreamPlayer3D,
	unit_size: float = DEFAULT_UNIT_SIZE,
	max_distance: float = DEFAULT_MAX_DISTANCE,
	attenuation_model: int = DEFAULT_ATTENUATION_MODEL
) -> void:
	if player == null:
		return
	player.unit_size = unit_size
	player.max_distance = max_distance
	player.attenuation_model = attenuation_model


## Creates spatial audio settings for close-range sounds (footsteps, breathing).
## Returns a Dictionary with the settings.
func get_close_range_settings() -> Dictionary:
	return {
		"unit_size": 0.5,
		"max_distance": 15.0,
		"attenuation_model": AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE,
	}


## Creates spatial audio settings for medium-range sounds (equipment, doors).
func get_medium_range_settings() -> Dictionary:
	return {
		"unit_size": 1.0,
		"max_distance": 25.0,
		"attenuation_model": AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE,
	}


## Creates spatial audio settings for long-range sounds (entity sounds, alarms).
func get_long_range_settings() -> Dictionary:
	return {
		"unit_size": 2.0,
		"max_distance": 50.0,
		"attenuation_model": AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC,
	}


# --- Utility ---


## Stops all active one-shot sounds.
func stop_all_sounds() -> void:
	for player: AudioStreamPlayer in _active_2d_players.duplicate():
		player.stop()
		player.queue_free()
	_active_2d_players.clear()

	for player: AudioStreamPlayer3D in _active_3d_players.duplicate():
		player.stop()
		player.queue_free()
	_active_3d_players.clear()


## Stops all sounds in a specific pool.
func stop_pooled_sounds(sound_id: String) -> void:
	if not _sound_pools.has(sound_id):
		return
	var pool: Array = _sound_pools[sound_id]
	for player: AudioStreamPlayer in pool:
		player.stop()


## Gets the count of currently playing one-shot sounds.
func get_active_sound_count() -> int:
	var count := 0
	for player: AudioStreamPlayer in _active_2d_players:
		if player.playing:
			count += 1
	for player: AudioStreamPlayer3D in _active_3d_players:
		if player.playing:
			count += 1
	return count


## Checks if a bus exists.
func has_bus(bus_name: String) -> bool:
	return AudioServer.get_bus_index(bus_name) != -1


## Gets all valid bus names.
func get_bus_names() -> Array[String]:
	return VALID_BUSES.duplicate()
