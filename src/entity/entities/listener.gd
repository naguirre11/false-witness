class_name Listener
extends Entity
## The Listener is a voice-reactive entity.
##
## Unique characteristics:
## - Alternates between dormant (listening) and active phases
## - Triggers instant hunts when players speak loudly during dormant phase
## - Voice-triggered hunts have no warning phase
## - Pauses and turns toward voice sources during active phase
##
## Evidence types: FREEZING_TEMPERATURE, GHOST_WRITING, AURA_PATTERN
##
## Behavioral tell: Voice-reactive - responds to player speech

# --- Signals ---

## Emitted when Listener enters dormant (listening) phase.
signal dormant_started

## Emitted when Listener exits dormant phase.
signal dormant_ended

## Emitted when voice triggers a hunt.
signal voice_hunt_triggered(speaker_id: int)

# --- Constants ---

## Minimum duration of dormant phase (seconds).
const MIN_DORMANT_DURATION: float = 30.0

## Maximum duration of dormant phase (seconds).
const MAX_DORMANT_DURATION: float = 60.0

## Minimum duration of active phase (seconds).
const MIN_ACTIVE_DURATION: float = 60.0

## Maximum duration of active phase (seconds).
const MAX_ACTIVE_DURATION: float = 120.0

## Cooldown after voice-triggered hunt before voice can trigger again (seconds).
const VOICE_HUNT_COOLDOWN: float = 60.0

## Amplitude threshold for voice to trigger hunt (above whisper).
const VOICE_TRIGGER_THRESHOLD: float = 0.3

## Range to detect voice (meters).
const VOICE_DETECTION_RANGE: float = 20.0

## Duration the Listener pauses when reacting to voice (seconds).
const VOICE_REACTION_PAUSE: float = 2.0

## Speed of head turn when reacting to voice (radians per second).
const VOICE_TURN_SPEED: float = 3.0

# --- Export Properties ---

@export_group("Listener Settings")
## Sensitivity to voice - lower = more sensitive.
@export_range(0.1, 1.0, 0.05) var voice_sensitivity: float = 0.3

## Volume of dormant ambient sound (0-1).
@export_range(0.0, 1.0, 0.1) var dormant_sound_volume: float = 0.3

# --- State Variables ---

## Whether Listener is currently in dormant (listening) phase.
var is_dormant: bool = false

## Time remaining in current phase (dormant or active).
var _phase_timer: float = 0.0

## Cooldown until voice can trigger hunt again.
var _voice_hunt_cooldown: float = 0.0

## Whether currently reacting to a voice (pause and turn).
var _is_voice_reacting: bool = false

## Time remaining in voice reaction.
var _voice_reaction_timer: float = 0.0

## Target position to turn toward during voice reaction.
var _voice_source_position: Vector3 = Vector3.ZERO

## ID of last speaker that triggered interest.
var _last_speaker_id: int = -1


func _ready() -> void:
	super._ready()

	# Set entity type
	entity_type = "Listener"

	# Configure movement speeds
	base_speed = 1.2  # Slow roamer
	hunt_speed = 2.2  # Moderate hunter
	hunt_aware_speed = 2.4
	hunt_unaware_speed = 1.5

	# Configure hunt behavior
	hunt_sanity_threshold = 50.0

	# Configure manifestation
	manifestation_duration = 6.0
	manifestation_cooldown = 25.0

	# Connect to VoiceManager signals
	_connect_voice_signals()

	# Start in dormant phase
	_enter_dormant_phase()


## Returns the entity type identifier.
func get_entity_type() -> String:
	return "Listener"


## Returns the behavioral tell type.
func get_behavioral_tell_type() -> String:
	return "voice_reactive"


## Returns true if voice can trigger hunt regardless of sanity.
func can_voice_trigger_hunt() -> bool:
	return true


# --- Evidence Configuration ---


## Returns the evidence types this entity can produce.
func get_evidence_types() -> Array[int]:
	return [
		EvidenceEnums.EvidenceType.FREEZING_TEMPERATURE,
		EvidenceEnums.EvidenceType.GHOST_WRITING,
		EvidenceEnums.EvidenceType.AURA_PATTERN,
	]


# --- Phase Management ---


## Enters the dormant (listening) phase.
func _enter_dormant_phase() -> void:
	is_dormant = true
	_phase_timer = randf_range(MIN_DORMANT_DURATION, MAX_DORMANT_DURATION)

	# Start dormant ambient sound
	_play_dormant_sound()

	dormant_started.emit()
	print("[Listener] Entered dormant phase (%.1fs)" % _phase_timer)


## Exits dormant phase and enters active phase.
func _exit_dormant_phase() -> void:
	is_dormant = false
	_phase_timer = randf_range(MIN_ACTIVE_DURATION, MAX_ACTIVE_DURATION)

	# Stop dormant ambient sound
	_stop_dormant_sound()

	dormant_ended.emit()
	print("[Listener] Entered active phase (%.1fs)" % _phase_timer)


# --- State Processing Overrides ---


func _on_enter_dormant() -> void:
	# When entering Entity DORMANT state, start listener's dormant phase
	if not is_dormant:
		_enter_dormant_phase()


func _on_enter_active() -> void:
	# When entering Entity ACTIVE state, may need to exit listener dormant
	if is_dormant:
		_exit_dormant_phase()


func _on_enter_hunting() -> void:
	# Hunting always exits dormant
	if is_dormant:
		is_dormant = false
		_stop_dormant_sound()


func _process_dormant_behavior(delta: float) -> void:
	# Update phase timer
	_phase_timer -= delta
	if _phase_timer <= 0:
		# Transition to Entity ACTIVE state
		change_state(EntityState.ACTIVE)
		return

	# Update voice cooldown
	if _voice_hunt_cooldown > 0:
		_voice_hunt_cooldown -= delta


func _process_active_behavior(delta: float) -> void:
	# Process voice reaction if active
	if _is_voice_reacting:
		_process_voice_reaction(delta)
		return

	# Update phase timer
	_phase_timer -= delta
	if _phase_timer <= 0:
		# Transition back to Entity DORMANT state
		change_state(EntityState.DORMANT)
		return

	# Update voice cooldown
	if _voice_hunt_cooldown > 0:
		_voice_hunt_cooldown -= delta

	# Standard roaming behavior during active phase
	# (Movement handled by Entity base class)


func _process_hunting_behavior(delta: float) -> void:
	# Voice cooldown still ticks during hunts
	if _voice_hunt_cooldown > 0:
		_voice_hunt_cooldown -= delta


# --- Voice Detection ---


## Connects to VoiceManager signals for voice detection.
func _connect_voice_signals() -> void:
	if has_node("/root/VoiceManager"):
		var voice_manager := get_node("/root/VoiceManager")
		if voice_manager.has_signal("voice_activity"):
			if not voice_manager.voice_activity.is_connected(_on_voice_activity):
				voice_manager.voice_activity.connect(_on_voice_activity)


## Called when a player's voice activity is detected.
func _on_voice_activity(player_id: int, amplitude: float) -> void:
	# Get player position
	var player_pos := _get_player_position(player_id)
	if player_pos == Vector3.ZERO:
		return

	# Check if in detection range
	var distance := global_position.distance_to(player_pos)
	if distance > VOICE_DETECTION_RANGE:
		return

	# Use configured sensitivity
	var threshold := voice_sensitivity

	# Dormant phase: voice can trigger instant hunt
	if is_dormant and _state != EntityState.HUNTING:
		if amplitude > threshold and _voice_hunt_cooldown <= 0:
			_trigger_voice_hunt(player_id, player_pos)
			return

	# Active phase: react to voice (behavioral tell)
	if _state == EntityState.ACTIVE and not _is_voice_reacting:
		if amplitude > threshold * 0.5:  # Lower threshold for reactions
			_start_voice_reaction(player_id, player_pos)


## Triggers an instant hunt from voice detection.
func _trigger_voice_hunt(speaker_id: int, speaker_pos: Vector3) -> void:
	print("[Listener] Voice hunt triggered by player %d" % speaker_id)

	# Set cooldown
	_voice_hunt_cooldown = VOICE_HUNT_COOLDOWN

	# Exit dormant phase
	is_dormant = false
	_stop_dormant_sound()

	# Emit signal
	voice_hunt_triggered.emit(speaker_id)

	# Target the speaker
	_target_last_position = speaker_pos

	# Request hunt from EntityManager (skips warning phase)
	if _manager and _manager.has_method("request_voice_triggered_hunt"):
		_manager.request_voice_triggered_hunt(self, speaker_id)
	elif _manager and _manager.has_method("start_hunt"):
		# Fallback: normal hunt start
		_manager.start_hunt()


## Starts a voice reaction (pause and turn toward speaker).
func _start_voice_reaction(speaker_id: int, speaker_pos: Vector3) -> void:
	_is_voice_reacting = true
	_voice_reaction_timer = VOICE_REACTION_PAUSE
	_voice_source_position = speaker_pos
	_last_speaker_id = speaker_id

	# This is the behavioral tell
	trigger_behavioral_tell()


## Processes voice reaction animation.
func _process_voice_reaction(delta: float) -> void:
	_voice_reaction_timer -= delta

	# Turn toward voice source
	var direction := (_voice_source_position - global_position).normalized()
	var target_rotation := atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_rotation, VOICE_TURN_SPEED * delta)

	# End reaction when timer expires
	if _voice_reaction_timer <= 0:
		_is_voice_reacting = false


## Checks behavioral tell condition.
## Returns true if Listener is reacting to voice (turning toward speaker).
func _check_behavioral_tell() -> bool:
	# Tell triggers through _start_voice_reaction, not here
	return false


# --- Helper Methods ---


## Gets a player's position by ID.
func _get_player_position(player_id: int) -> Vector3:
	# Try PlayerManager first
	if has_node("/root/PlayerManager"):
		var player_manager := get_node("/root/PlayerManager")
		if player_manager.has_method("get_player"):
			var player: Node = player_manager.get_player(player_id)
			if player and player is Node3D:
				return (player as Node3D).global_position

	# Fallback: search players group
	for player in get_tree().get_nodes_in_group("players"):
		var pid: int = _get_player_id(player)
		if pid == player_id and player is Node3D:
			return (player as Node3D).global_position

	return Vector3.ZERO


# --- Audio ---


## Plays the ambient dormant sound (faint static/hum).
func _play_dormant_sound() -> void:
	# Audio implementation - placeholder for FW-046-05
	# EntityAudioManager will handle spatial audio
	if has_node("/root/EntityAudioManager"):
		var audio_manager := get_node("/root/EntityAudioManager")
		if audio_manager.has_method("play_listener_dormant"):
			audio_manager.play_listener_dormant(self, dormant_sound_volume)


## Stops the dormant ambient sound.
func _stop_dormant_sound() -> void:
	if has_node("/root/EntityAudioManager"):
		var audio_manager := get_node("/root/EntityAudioManager")
		if audio_manager.has_method("stop_listener_dormant"):
			audio_manager.stop_listener_dormant(self)


# --- Public API ---


## Returns true if Listener is in dormant (listening) phase.
func is_in_dormant_phase() -> bool:
	return is_dormant


## Returns time remaining in current phase.
func get_phase_time_remaining() -> float:
	return _phase_timer


## Returns time until voice can trigger hunt again.
func get_voice_cooldown_remaining() -> float:
	return _voice_hunt_cooldown


## Returns true if currently reacting to a voice.
func is_reacting_to_voice() -> bool:
	return _is_voice_reacting


## Gets the network state for synchronization.
func get_network_state() -> Dictionary:
	var state := super.get_network_state()
	state["is_dormant"] = is_dormant
	state["phase_timer"] = _phase_timer
	state["voice_cooldown"] = _voice_hunt_cooldown
	return state


## Applies network state from server.
func apply_network_state(state: Dictionary) -> void:
	super.apply_network_state(state)

	if state.has("is_dormant"):
		var was_dormant := is_dormant
		is_dormant = state.is_dormant
		if is_dormant and not was_dormant:
			_play_dormant_sound()
		elif not is_dormant and was_dormant:
			_stop_dormant_sound()

	if state.has("phase_timer"):
		_phase_timer = state.phase_timer

	if state.has("voice_cooldown"):
		_voice_hunt_cooldown = state.voice_cooldown
