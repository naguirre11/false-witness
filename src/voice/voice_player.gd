class_name VoicePlayer
extends AudioStreamPlayer3D
## 3D spatial audio player for voice chat playback with jitter buffering.
## Attached to remote player nodes to enable proximity-based voice.
##
## Handles:
## - Decoding compressed Steam voice data
## - Jitter buffer for smooth playback despite network variance
## - Adaptive buffer sizing based on network conditions
## - Latency measurement and logging
## - Streaming to AudioStreamGenerator
## - Position updates following player movement
## - Distance-based volume attenuation


# --- Signals ---

signal latency_measured(latency_ms: float)


# --- Constants ---

const DEFAULT_MAX_DISTANCE: float = 15.0  # Meters - proximity voice range
const DEFAULT_ATTENUATION: float = 1.0
const SAMPLE_RATE: int = 48000  # Steam voice optimal sample rate
const BUFFER_SIZE: int = 4096  # Audio buffer frames

## Jitter buffer settings
const MIN_JITTER_BUFFER_MS: float = 40.0  # Minimum buffer delay (ms)
const MAX_JITTER_BUFFER_MS: float = 200.0  # Maximum buffer delay (ms)
const INITIAL_JITTER_BUFFER_MS: float = 60.0  # Starting buffer delay (ms)
const JITTER_ADAPTATION_RATE: float = 0.1  # How fast buffer adapts (0-1)
const LATENCY_LOG_INTERVAL: float = 5.0  # Log latency stats every 5 seconds

## Jitter measurement
const JITTER_WINDOW_SIZE: int = 20  # Number of packets to measure jitter over


# --- State ---

var steam_id: int = 0
var _stream_generator: AudioStreamGenerator = null
var _stream_playback: AudioStreamGeneratorPlayback = null
var _is_playing_voice: bool = false

## Jitter buffer state
var _jitter_buffer: Array[Dictionary] = []  # [{timestamp, samples}]
var _target_buffer_ms: float = INITIAL_JITTER_BUFFER_MS
var _buffer_playback_started: bool = false

## Latency tracking
var _arrival_times: Array[int] = []  # Timestamps of packet arrivals
var _packet_timestamps: Array[int] = []  # Original send timestamps
var _last_latency_log_time: float = 0.0
var _total_latency_ms: float = 0.0
var _latency_sample_count: int = 0
var _min_latency_ms: float = 999999.0
var _max_latency_ms: float = 0.0

## Jitter calculation
var _inter_arrival_deltas: Array[int] = []
var _current_jitter_ms: float = 0.0


func _ready() -> void:
	_setup_audio_stream()
	_configure_spatial_audio()


func _process(delta: float) -> void:
	# Process jitter buffer - play audio when buffer is ready
	_process_jitter_buffer()

	# Keep pushing silence if we're not receiving voice data
	# This prevents audio pops from buffer underruns
	if _stream_playback and not _is_playing_voice:
		_push_silence()

	# Periodic latency logging
	_last_latency_log_time += delta
	if _last_latency_log_time >= LATENCY_LOG_INTERVAL:
		_log_latency_stats()
		_last_latency_log_time = 0.0


# =============================================================================
# PUBLIC API
# =============================================================================


## Initialize the voice player for a specific Steam user.
func setup(player_steam_id: int) -> void:
	steam_id = player_steam_id
	name = "VoicePlayer_%d" % steam_id


## Play voice data received from the network.
## voice_data should be compressed Steam voice from getVoice().
## send_timestamp is the original send time in milliseconds (from sender).
func play_voice_data(compressed_data: PackedByteArray, send_timestamp: int = 0) -> void:
	if not SteamManager.is_steam_running:
		return

	# Decompress voice data using Steam API
	var pcm_data := _decompress_voice(compressed_data)
	if pcm_data.size() == 0:
		return

	var arrival_time := Time.get_ticks_msec()

	# Measure latency if timestamp provided
	if send_timestamp > 0:
		_measure_latency(send_timestamp, arrival_time)

	# Add to jitter buffer instead of immediate playback
	_add_to_jitter_buffer(pcm_data, send_timestamp, arrival_time)
	_is_playing_voice = true


## Stop voice playback.
func stop_voice() -> void:
	_is_playing_voice = false
	_jitter_buffer.clear()
	_buffer_playback_started = false


## Update position to follow the player.
func update_position(new_position: Vector3) -> void:
	global_position = new_position


## Configure the proximity range.
func configure_max_distance(distance: float) -> void:
	max_distance = distance


## Check if currently playing voice.
func is_voice_active() -> bool:
	return _is_playing_voice


## Get current average latency in milliseconds.
func get_average_latency_ms() -> float:
	if _latency_sample_count == 0:
		return 0.0
	return _total_latency_ms / float(_latency_sample_count)


## Get current jitter buffer target in milliseconds.
func get_buffer_target_ms() -> float:
	return _target_buffer_ms


## Get current measured jitter in milliseconds.
func get_current_jitter_ms() -> float:
	return _current_jitter_ms


## Get latency statistics as a Dictionary.
func get_latency_stats() -> Dictionary:
	return {
		"average_ms": get_average_latency_ms(),
		"min_ms": _min_latency_ms if _min_latency_ms < 999999.0 else 0.0,
		"max_ms": _max_latency_ms,
		"jitter_ms": _current_jitter_ms,
		"buffer_target_ms": _target_buffer_ms,
		"sample_count": _latency_sample_count,
	}


## Reset latency statistics.
func reset_latency_stats() -> void:
	_total_latency_ms = 0.0
	_latency_sample_count = 0
	_min_latency_ms = 999999.0
	_max_latency_ms = 0.0
	_arrival_times.clear()
	_packet_timestamps.clear()
	_inter_arrival_deltas.clear()


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


# =============================================================================
# INTERNAL - Jitter Buffer
# =============================================================================


## Add decoded audio to the jitter buffer.
func _add_to_jitter_buffer(
	samples: PackedVector2Array, send_timestamp: int, arrival_time: int
) -> void:
	var entry := {
		"samples": samples,
		"send_timestamp": send_timestamp,
		"arrival_time": arrival_time,
	}

	# Insert sorted by send timestamp (for packet reordering)
	var inserted := false
	for i in range(_jitter_buffer.size()):
		if send_timestamp < _jitter_buffer[i].send_timestamp:
			_jitter_buffer.insert(i, entry)
			inserted = true
			break

	if not inserted:
		_jitter_buffer.append(entry)

	# Limit buffer size to prevent memory issues
	while _jitter_buffer.size() > 50:
		_jitter_buffer.pop_front()


## Process the jitter buffer - play audio when buffer has enough delay.
func _process_jitter_buffer() -> void:
	if _jitter_buffer.is_empty():
		return

	var current_time := Time.get_ticks_msec()

	# Check if we should start playback (buffer has filled enough)
	if not _buffer_playback_started:
		var oldest_entry: Dictionary = _jitter_buffer[0]
		var buffered_time_ms: float = float(current_time - oldest_entry.arrival_time)

		# Wait until we have target buffer amount before starting playback
		if buffered_time_ms >= _target_buffer_ms:
			_buffer_playback_started = true
		else:
			return

	# Play audio from buffer
	while not _jitter_buffer.is_empty():
		var entry: Dictionary = _jitter_buffer[0]
		var age_ms: float = float(current_time - entry.arrival_time)

		# Only play if the packet has been buffered long enough
		if age_ms >= _target_buffer_ms:
			_jitter_buffer.pop_front()
			_push_audio_data(entry.samples)
		else:
			break

	# Reset playback state if buffer empties
	if _jitter_buffer.is_empty():
		_buffer_playback_started = false


# =============================================================================
# INTERNAL - Latency Measurement
# =============================================================================


## Measure and record latency for a packet.
func _measure_latency(send_timestamp: int, arrival_time: int) -> void:
	# Calculate one-way latency estimate
	# Note: This requires clock sync between sender and receiver
	# For now we use it as a relative measure
	var latency_ms: float = float(arrival_time - send_timestamp)

	# Handle clock wrap-around or negative values
	if latency_ms < 0:
		latency_ms = 0.0

	# Update statistics
	_total_latency_ms += latency_ms
	_latency_sample_count += 1
	_min_latency_ms = minf(_min_latency_ms, latency_ms)
	_max_latency_ms = maxf(_max_latency_ms, latency_ms)

	# Track arrivals for jitter calculation
	_arrival_times.append(arrival_time)
	_packet_timestamps.append(send_timestamp)

	# Keep window size limited
	while _arrival_times.size() > JITTER_WINDOW_SIZE:
		_arrival_times.pop_front()
		_packet_timestamps.pop_front()

	# Calculate jitter and adapt buffer
	_calculate_jitter()
	_adapt_buffer_size()

	# Emit signal for UI/debugging
	latency_measured.emit(latency_ms)


## Calculate network jitter using inter-arrival variance.
func _calculate_jitter() -> void:
	if _arrival_times.size() < 2:
		return

	# Calculate inter-arrival deltas
	_inter_arrival_deltas.clear()
	for i in range(1, _arrival_times.size()):
		var arrival_delta := _arrival_times[i] - _arrival_times[i - 1]
		var send_delta := _packet_timestamps[i] - _packet_timestamps[i - 1]
		var delta_diff := absi(arrival_delta - send_delta)
		_inter_arrival_deltas.append(delta_diff)

	# Calculate average jitter (RFC 3550 style)
	if _inter_arrival_deltas.is_empty():
		return

	var total_jitter := 0
	for delta in _inter_arrival_deltas:
		total_jitter += delta

	_current_jitter_ms = float(total_jitter) / float(_inter_arrival_deltas.size())


## Adapt jitter buffer size based on measured network conditions.
func _adapt_buffer_size() -> void:
	# Target buffer should be about 2x the measured jitter
	# This provides headroom for variance
	var target := _current_jitter_ms * 2.0 + MIN_JITTER_BUFFER_MS

	# Clamp to bounds
	target = clampf(target, MIN_JITTER_BUFFER_MS, MAX_JITTER_BUFFER_MS)

	# Smooth adaptation to avoid sudden changes
	_target_buffer_ms = lerpf(_target_buffer_ms, target, JITTER_ADAPTATION_RATE)


## Log latency statistics for debugging.
func _log_latency_stats() -> void:
	if _latency_sample_count == 0:
		return

	var stats := get_latency_stats()
	print(
		"[VoicePlayer %d] Latency - avg: %.1fms, min: %.1fms, max: %.1fms, "
		% [steam_id, stats.average_ms, stats.min_ms, stats.max_ms]
		+ "jitter: %.1fms, buffer: %.1fms"
		% [stats.jitter_ms, stats.buffer_target_ms]
	)
