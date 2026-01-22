extends Node
## Manages voice chat for False Witness.
## Autoload: VoiceManager
##
## Handles:
## - Voice mode (push-to-talk, open mic, disabled)
## - Steam voice capture and transmission
## - Spatial audio playback for remote players
## - Per-player mute controls
## - Voice activity detection for entity AI


# --- Signals ---

signal voice_state_changed(state: int)
signal voice_data_captured(data: PackedByteArray)
signal voice_activity(player_id: int, amplitude: float)
signal player_muted(steam_id: int)
signal player_unmuted(steam_id: int)

# --- Constants ---

const VOICE_SAMPLE_RATE: int = 48000  # Steam Voice optimal rate
const VAD_THRESHOLD_DEFAULT: float = 0.01  # Voice activity detection threshold
const VAD_SILENCE_TIMEOUT: float = 0.3  # Seconds of silence before stopping transmission
const VOICE_MAX_DISTANCE: float = 15.0  # Default proximity voice range in meters

# --- State ---

var is_voice_enabled: bool = true
var local_muted: bool = false
var voice_mode: VoiceEnums.VoiceMode = VoiceEnums.VoiceMode.PUSH_TO_TALK
var voice_state: VoiceEnums.VoiceState = VoiceEnums.VoiceState.IDLE

# Voice activity detection
var vad_threshold: float = VAD_THRESHOLD_DEFAULT
var _vad_silence_timer: float = 0.0
var _is_ptt_pressed: bool = false

# Per-player mute
var _muted_players: Dictionary = {}  # steam_id -> true

# Voice players for spatial audio
var _voice_players: Dictionary = {}  # steam_id -> VoicePlayer

# Network channel for voice data
const VOICE_CHANNEL: int = 1  # Separate channel from game packets


func _ready() -> void:
	# Set up push-to-talk input action if it doesn't exist
	_setup_ptt_input_action()
	print("[VoiceManager] Initialized - Mode: %s" % VoiceEnums.get_mode_name(voice_mode))


func _process(delta: float) -> void:
	# Read incoming voice packets
	_read_voice_packets()

	if not is_voice_enabled or local_muted:
		if voice_state != VoiceEnums.VoiceState.IDLE:
			_set_voice_state(VoiceEnums.VoiceState.IDLE)
		return

	match voice_mode:
		VoiceEnums.VoiceMode.PUSH_TO_TALK:
			_process_push_to_talk()
		VoiceEnums.VoiceMode.OPEN_MIC:
			_process_open_mic(delta)
		VoiceEnums.VoiceMode.DISABLED:
			if voice_state != VoiceEnums.VoiceState.IDLE:
				_set_voice_state(VoiceEnums.VoiceState.IDLE)


func _input(event: InputEvent) -> void:
	if voice_mode != VoiceEnums.VoiceMode.PUSH_TO_TALK:
		return

	if event.is_action_pressed(VoiceEnums.DEFAULT_PTT_ACTION):
		_is_ptt_pressed = true
	elif event.is_action_released(VoiceEnums.DEFAULT_PTT_ACTION):
		_is_ptt_pressed = false


# =============================================================================
# PUBLIC API - Voice Control
# =============================================================================


## Enable or disable voice chat entirely.
func set_voice_enabled(enabled: bool) -> void:
	is_voice_enabled = enabled
	if not enabled:
		_stop_voice_recording()
		_set_voice_state(VoiceEnums.VoiceState.IDLE)
	print("[VoiceManager] Voice %s" % ("enabled" if enabled else "disabled"))


## Mute local microphone (still receive others).
func set_local_muted(muted: bool) -> void:
	local_muted = muted
	if muted:
		_stop_voice_recording()
		_set_voice_state(VoiceEnums.VoiceState.IDLE)
	print("[VoiceManager] Local mute: %s" % str(muted))


## Set voice transmission mode.
func set_voice_mode(mode: VoiceEnums.VoiceMode) -> void:
	voice_mode = mode
	_stop_voice_recording()
	_set_voice_state(VoiceEnums.VoiceState.IDLE)
	print("[VoiceManager] Voice mode: %s" % VoiceEnums.get_mode_name(mode))


## Set voice activity detection sensitivity (0.0 - 1.0).
func set_vad_threshold(threshold: float) -> void:
	vad_threshold = clampf(threshold, 0.0, 1.0)


## Check if local player is currently transmitting.
func is_transmitting() -> bool:
	return voice_state == VoiceEnums.VoiceState.TRANSMITTING


## Get current voice amplitude (for UI visualization).
func get_voice_amplitude() -> float:
	if not SteamManager.is_steam_running:
		return 0.0

	# Steam doesn't expose amplitude directly, but we can estimate from voice data
	# For now return a simple indicator based on transmission state
	return 1.0 if voice_state == VoiceEnums.VoiceState.TRANSMITTING else 0.0


# =============================================================================
# PUBLIC API - Network Voice Transmission (FW-014-07)
# =============================================================================


## Send voice data to all nearby players.
## Call this from _capture_and_send_voice when data is captured.
func broadcast_voice_data(voice_data: PackedByteArray) -> void:
	if not SteamManager.is_steam_running:
		return

	if SteamManager.current_lobby_id == 0:
		return  # Not in a lobby

	# Package voice data with sender info and timestamp
	var packet := {
		"type": "voice",
		"sender": SteamManager.steam_id,
		"timestamp": Time.get_ticks_msec(),
		"data": voice_data,
	}

	# Send to all lobby members using unreliable channel for low latency
	_send_voice_packet_to_lobby(packet)


## Process received voice packet from another player.
func receive_voice_data(sender_id: int, voice_data: PackedByteArray, timestamp: int) -> void:
	# Check if player is muted
	if is_player_muted(sender_id):
		return

	# Get or create voice player for this sender
	var voice_player := _get_or_create_voice_player(sender_id)
	if voice_player:
		voice_player.play_voice_data(voice_data)

	# Emit signal for entity detection and UI
	voice_activity.emit(sender_id, 1.0)

	# Timestamp used for future jitter buffer implementation
	var _unused := timestamp


# =============================================================================
# INTERNAL - Voice Network
# =============================================================================


func _send_voice_packet_to_lobby(packet: Dictionary) -> void:
	if not SteamManager.is_steam_running:
		return

	var packet_data: PackedByteArray = var_to_bytes(packet)

	# Get lobby members and send to each (except self)
	var members := SteamManager.get_lobby_members()
	for member_id in members:
		if member_id != SteamManager.steam_id:
			# Use unreliable channel for voice (low latency, packet loss OK)
			Steam.sendP2PPacket(
				member_id,
				packet_data,
				Steam.P2P_SEND_UNRELIABLE,
				VOICE_CHANNEL
			)


func _read_voice_packets() -> void:
	if not SteamManager.is_steam_running:
		return

	# Read voice packets from channel 1 (separate from game data on channel 0)
	var packet_size: int = Steam.getAvailableP2PPacketSize(VOICE_CHANNEL)
	while packet_size > 0:
		var packet: Dictionary = Steam.readP2PPacket(packet_size, VOICE_CHANNEL)

		if packet.has("data") and packet.has("steam_id_remote"):
			var data: Dictionary = bytes_to_var(packet.data)
			if data.has("type") and data.type == "voice":
				var sender_id: int = data.get("sender", packet.steam_id_remote)
				var voice_data: PackedByteArray = data.get("data", PackedByteArray())
				var timestamp: int = data.get("timestamp", 0)
				receive_voice_data(sender_id, voice_data, timestamp)

		# Check for more packets
		packet_size = Steam.getAvailableP2PPacketSize(VOICE_CHANNEL)


# =============================================================================
# INTERNAL - Voice Player Management (FW-014-09)
# =============================================================================

const VoicePlayer = preload("res://src/voice/voice_player.gd")


func _get_or_create_voice_player(steam_id: int) -> VoicePlayer:
	# Return existing player if we have one
	if _voice_players.has(steam_id):
		return _voice_players[steam_id]

	# Create new voice player
	var voice_player := VoicePlayer.new()
	voice_player.setup(steam_id)
	add_child(voice_player)
	_voice_players[steam_id] = voice_player

	return voice_player


## Remove voice player when a player disconnects.
func remove_voice_player(steam_id: int) -> void:
	if _voice_players.has(steam_id):
		var player: VoicePlayer = _voice_players[steam_id]
		player.queue_free()
		_voice_players.erase(steam_id)


## Update voice player position (call from player controller).
func update_player_position(steam_id: int, position: Vector3) -> void:
	if _voice_players.has(steam_id):
		var player: VoicePlayer = _voice_players[steam_id]
		player.update_position(position)


## Get a voice player by Steam ID (for UI indicators).
func get_voice_player(steam_id: int) -> VoicePlayer:
	return _voice_players.get(steam_id, null)


# =============================================================================
# PUBLIC API - Per-Player Mute
# =============================================================================


## Mute a specific player.
func mute_player(steam_id: int) -> void:
	_muted_players[steam_id] = true
	player_muted.emit(steam_id)
	print("[VoiceManager] Muted player: %d" % steam_id)


## Unmute a specific player.
func unmute_player(steam_id: int) -> void:
	_muted_players.erase(steam_id)
	player_unmuted.emit(steam_id)
	print("[VoiceManager] Unmuted player: %d" % steam_id)


## Check if a player is muted.
func is_player_muted(steam_id: int) -> bool:
	return _muted_players.has(steam_id)


## Get list of all muted players.
func get_muted_players() -> Array[int]:
	var result: Array[int] = []
	for steam_id in _muted_players:
		result.append(steam_id)
	return result


# =============================================================================
# INTERNAL - Voice Recording
# =============================================================================


func _process_push_to_talk() -> void:
	if _is_ptt_pressed:
		if voice_state != VoiceEnums.VoiceState.TRANSMITTING:
			_start_voice_recording()
			_set_voice_state(VoiceEnums.VoiceState.TRANSMITTING)
		_capture_and_send_voice()
	else:
		if voice_state == VoiceEnums.VoiceState.TRANSMITTING:
			_stop_voice_recording()
			_set_voice_state(VoiceEnums.VoiceState.IDLE)


func _process_open_mic(delta: float) -> void:
	# Voice activity detection
	var has_voice: bool = _check_voice_activity()

	if has_voice:
		_vad_silence_timer = 0.0
		if voice_state != VoiceEnums.VoiceState.TRANSMITTING:
			_start_voice_recording()
			_set_voice_state(VoiceEnums.VoiceState.TRANSMITTING)
		_capture_and_send_voice()
	else:
		if voice_state == VoiceEnums.VoiceState.TRANSMITTING:
			_vad_silence_timer += delta
			if _vad_silence_timer >= VAD_SILENCE_TIMEOUT:
				_stop_voice_recording()
				_set_voice_state(VoiceEnums.VoiceState.IDLE)


func _start_voice_recording() -> void:
	if not SteamManager.is_steam_running:
		return

	Steam.startVoiceRecording()


func _stop_voice_recording() -> void:
	if not SteamManager.is_steam_running:
		return

	Steam.stopVoiceRecording()


func _capture_and_send_voice() -> void:
	if not SteamManager.is_steam_running:
		return

	# Note: Steam voice capture requires Steam.getVoice() which returns a Dictionary
	# with "result" (int) and "buffer" (PackedByteArray)
	# Check if Steam class has the required voice methods
	if not Steam.has_method("getVoice"):
		return

	var voice_result: Variant = Steam.call("getVoice")
	if voice_result is Dictionary and voice_result.has("buffer"):
		var voice_data: PackedByteArray = voice_result.buffer
		if voice_data.size() > 0:
			voice_data_captured.emit(voice_data)

			# Send voice data to other players
			broadcast_voice_data(voice_data)

			# Emit activity signal for entity detection
			voice_activity.emit(SteamManager.steam_id, 1.0)


func _check_voice_activity() -> bool:
	if not SteamManager.is_steam_running:
		return false

	# Check if Steam has voice available
	# Different GodotSteam versions have different APIs
	if Steam.has_method("getVoice"):
		var voice_result: Variant = Steam.call("getVoice")
		if voice_result is Dictionary and voice_result.has("buffer"):
			return voice_result.buffer.size() > 0

	return false


func _set_voice_state(new_state: VoiceEnums.VoiceState) -> void:
	if voice_state != new_state:
		voice_state = new_state
		voice_state_changed.emit(new_state)


# =============================================================================
# INTERNAL - Input Setup
# =============================================================================


func _setup_ptt_input_action() -> void:
	# Add push-to-talk action if not already defined
	if not InputMap.has_action(VoiceEnums.DEFAULT_PTT_ACTION):
		InputMap.add_action(VoiceEnums.DEFAULT_PTT_ACTION)

		# Default to V key
		var key_event := InputEventKey.new()
		key_event.keycode = KEY_V
		InputMap.action_add_event(VoiceEnums.DEFAULT_PTT_ACTION, key_event)

		print("[VoiceManager] Added 'voice_transmit' input action (V key)")
