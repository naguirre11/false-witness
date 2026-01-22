class_name VoicePlayer
extends AudioStreamPlayer3D
## 3D spatial audio player for voice chat playback.
## Attached to remote player nodes to enable proximity-based voice.
##
## Handles:
## - Decoding compressed Steam voice data
## - Streaming to AudioStreamGenerator
## - Position updates following player movement
## - Distance-based volume attenuation


# --- Constants ---

const DEFAULT_MAX_DISTANCE: float = 15.0  # Meters - proximity voice range
const DEFAULT_ATTENUATION: float = 1.0
const SAMPLE_RATE: int = 48000  # Steam voice optimal sample rate
const BUFFER_SIZE: int = 4096  # Audio buffer frames


# --- State ---

var steam_id: int = 0
var _stream_generator: AudioStreamGenerator = null
var _stream_playback: AudioStreamGeneratorPlayback = null
var _is_playing_voice: bool = false


func _ready() -> void:
	_setup_audio_stream()
	_configure_spatial_audio()


func _process(_delta: float) -> void:
	# Keep pushing silence if we're not receiving voice data
	# This prevents audio pops from buffer underruns
	if _stream_playback and not _is_playing_voice:
		_push_silence()


# =============================================================================
# PUBLIC API
# =============================================================================


## Initialize the voice player for a specific Steam user.
func setup(player_steam_id: int) -> void:
	steam_id = player_steam_id
	name = "VoicePlayer_%d" % steam_id


## Play voice data received from the network.
## voice_data should be compressed Steam voice from getVoice().
func play_voice_data(compressed_data: PackedByteArray) -> void:
	if not SteamManager.is_steam_running:
		return

	# Decompress voice data using Steam API
	var pcm_data := _decompress_voice(compressed_data)
	if pcm_data.size() == 0:
		return

	# Push to audio stream
	_push_audio_data(pcm_data)
	_is_playing_voice = true


## Stop voice playback.
func stop_voice() -> void:
	_is_playing_voice = false


## Update position to follow the player.
func update_position(new_position: Vector3) -> void:
	global_position = new_position


## Configure the proximity range.
func configure_max_distance(distance: float) -> void:
	max_distance = distance


## Check if currently playing voice.
func is_voice_active() -> bool:
	return _is_playing_voice


# =============================================================================
# INTERNAL - Audio Setup
# =============================================================================


func _setup_audio_stream() -> void:
	_stream_generator = AudioStreamGenerator.new()
	_stream_generator.mix_rate = SAMPLE_RATE
	_stream_generator.buffer_length = float(BUFFER_SIZE) / SAMPLE_RATE

	stream = _stream_generator

	# Start playing immediately (audio will be silence until we push data)
	play()

	# Get playback handle
	_stream_playback = get_stream_playback()


func _configure_spatial_audio() -> void:
	# Configure 3D audio properties
	max_distance = DEFAULT_MAX_DISTANCE
	attenuation_model = ATTENUATION_INVERSE_DISTANCE
	unit_size = 1.0

	# Voice should be audible even at max range
	attenuation_filter_cutoff_hz = 5000.0
	attenuation_filter_db = -24.0

	# Use voice bus if available
	if AudioServer.get_bus_index("Voice") >= 0:
		bus = "Voice"


# =============================================================================
# INTERNAL - Voice Processing
# =============================================================================


func _decompress_voice(compressed_data: PackedByteArray) -> PackedVector2Array:
	if not SteamManager.is_steam_running:
		return PackedVector2Array()

	# Use Steam.decompressVoice() if available
	if not Steam.has_method("decompressVoice"):
		return PackedVector2Array()

	var result: Variant = Steam.call("decompressVoice", compressed_data, SAMPLE_RATE)

	# Convert to stereo samples (Vector2 for left/right)
	if result is Dictionary and result.has("buffer"):
		return _convert_to_stereo(result.buffer)
	elif result is PackedByteArray:
		return _convert_to_stereo(result)

	return PackedVector2Array()


func _convert_to_stereo(mono_samples: PackedByteArray) -> PackedVector2Array:
	# Steam voice is typically mono 16-bit PCM
	# Convert to stereo Vector2 for AudioStreamGenerator
	var stereo_samples := PackedVector2Array()
	var sample_count := mono_samples.size() / 2  # 16-bit = 2 bytes per sample

	stereo_samples.resize(sample_count)

	for i in range(sample_count):
		var byte_index := i * 2
		if byte_index + 1 >= mono_samples.size():
			break

		# Read 16-bit signed sample (little-endian)
		var sample_int: int = mono_samples[byte_index] | (mono_samples[byte_index + 1] << 8)
		if sample_int >= 32768:
			sample_int -= 65536

		# Normalize to -1.0 to 1.0 range
		var sample_float := float(sample_int) / 32768.0

		# Stereo (same value for both channels since voice is mono)
		stereo_samples[i] = Vector2(sample_float, sample_float)

	return stereo_samples


func _push_audio_data(samples: PackedVector2Array) -> void:
	if not _stream_playback:
		return

	var available := _stream_playback.get_frames_available()
	var to_push := mini(samples.size(), available)

	if to_push > 0:
		for i in range(to_push):
			_stream_playback.push_frame(samples[i])


func _push_silence() -> void:
	if not _stream_playback:
		return

	# Fill some buffer with silence to prevent underruns
	var available := _stream_playback.get_frames_available()
	var silence_frames := mini(256, available)

	for i in range(silence_frames):
		_stream_playback.push_frame(Vector2.ZERO)
