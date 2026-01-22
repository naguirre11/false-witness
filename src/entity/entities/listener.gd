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

@export_group("Active Phase Behavior")
## Interval between roaming destination updates (seconds).
@export_range(5.0, 30.0, 1.0) var roam_interval: float = 15.0

## Interval between interaction attempts (seconds).
@export_range(10.0, 60.0, 5.0) var interaction_interval: float = 30.0

## Interval between manifestation attempts (seconds).
@export_range(20.0, 120.0, 10.0) var manifestation_interval: float = 45.0

## Interval between temperature zone updates in favorite room (seconds).
@export_range(5.0, 30.0, 5.0) var temperature_interval: float = 10.0

## Chance (0-1) to interact with a ghost writing book when nearby.
@export_range(0.0, 1.0, 0.1) var ghost_writing_chance: float = 0.7

## Detection range for ghost writing books (meters).
@export_range(1.0, 10.0, 0.5) var ghost_writing_range: float = 5.0

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

# --- Active Phase Behavior Timers ---

## Timer for roaming destination updates.
var _roam_timer: float = 0.0

## Timer for interaction attempts (door slam, light flicker, etc).
var _interaction_timer: float = 0.0

## Timer for manifestation attempts.
var _manifestation_timer_listener: float = 0.0

## Timer for temperature zone updates.
var _temperature_timer: float = 0.0

## Current roam target position (for navigation).
var _roam_target: Vector3 = Vector3.ZERO

## Whether currently roaming to a target.
var _is_roaming: bool = false


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

	# --- Roaming behavior ---
	_roam_timer -= delta
	if _roam_timer <= 0:
		_roam_timer = roam_interval + randf_range(-5.0, 5.0)  # Add randomness
		_select_new_roam_target()

	# Navigate toward roam target
	if _is_roaming and _roam_target != Vector3.ZERO:
		navigate_to(_roam_target)
		if is_navigation_finished():
			_is_roaming = false

	# --- Interactions (door slam, light flicker, object throw) ---
	_interaction_timer -= delta
	if _interaction_timer <= 0:
		_interaction_timer = interaction_interval + randf_range(-10.0, 10.0)
		_attempt_interaction()

	# --- Manifestation attempts ---
	_manifestation_timer_listener -= delta
	if _manifestation_timer_listener <= 0:
		_manifestation_timer_listener = manifestation_interval + randf_range(-15.0, 15.0)
		_attempt_manifestation()

	# --- Temperature zone in favorite room ---
	if _is_in_favorite_room():
		_temperature_timer -= delta
		if _temperature_timer <= 0:
			_temperature_timer = temperature_interval
			_create_freezing_zone()

	# --- Ghost writing book detection ---
	_check_ghost_writing_books()


func _process_hunting_behavior(delta: float) -> void:
	# Voice cooldown still ticks during hunts
	if _voice_hunt_cooldown > 0:
		_voice_hunt_cooldown -= delta

	# Continue listening for voices during hunt (for target switching)
	# But don't trigger new hunts - just update last known position


## Selects hunt target from available players.
## Listener prioritizes the voice-triggering speaker, then any visible player.
func _select_hunt_target(players: Array) -> Node:
	if players.is_empty():
		return null

	# If we have a last speaker, prioritize them
	if _last_speaker_id != -1:
		for player in players:
			var pid := _get_player_id(player)
			if pid == _last_speaker_id:
				return player

	# Otherwise, pick the nearest player
	var nearest: Node = null
	var nearest_distance := 999999.0

	for player in players:
		if player is Node3D:
			var dist: float = global_position.distance_to((player as Node3D).global_position)
			if dist < nearest_distance:
				nearest_distance = dist
				nearest = player

	return nearest


## Updates target position when voice is heard during hunt.
## Allows Listener to track speaking players mid-hunt.
func _update_voice_target_during_hunt(speaker_id: int, speaker_pos: Vector3) -> void:
	# Only update if no current target or speaker is closer
	if _hunt_target == null or not is_instance_valid(_hunt_target):
		_target_last_position = speaker_pos
		_last_speaker_id = speaker_id
		_is_aware_of_target = true
		return

	# If current target, check if speaker is closer
	if _hunt_target is Node3D:
		var current_dist: float = global_position.distance_to(
			(_hunt_target as Node3D).global_position
		)
		var speaker_dist := global_position.distance_to(speaker_pos)

		# Switch to speaker if they're closer and speaking loudly
		if speaker_dist < current_dist:
			_target_last_position = speaker_pos
			_last_speaker_id = speaker_id
			# Note: actual target switch happens in next detection cycle


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

	# Hunting phase: update target based on voice
	if _state == EntityState.HUNTING:
		if amplitude > threshold:
			_update_voice_target_during_hunt(player_id, player_pos)
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


# --- Active Phase Behaviors ---


## Selects a new roaming target position.
## Prefers favorite room but occasionally roams elsewhere.
func _select_new_roam_target() -> void:
	# 60% chance to roam toward favorite room, 40% random
	var go_to_favorite := randf() < 0.6 and _favorite_room != ""

	if go_to_favorite:
		_roam_target = _get_favorite_room_position()
	else:
		_roam_target = _get_random_roam_position()

	if _roam_target != Vector3.ZERO:
		_is_roaming = true


## Gets a position within the favorite room.
func _get_favorite_room_position() -> Vector3:
	# Try to find evidence spawn points in favorite room
	var spawn_points := get_tree().get_nodes_in_group("evidence_spawn_points")
	var room_points: Array[Node3D] = []

	for point in spawn_points:
		if point is Node3D:
			if point.get("room_name") == _favorite_room:
				room_points.append(point as Node3D)

	if not room_points.is_empty():
		var chosen: Node3D = room_points[randi() % room_points.size()]
		return chosen.global_position

	# Fallback: use current position with small offset
	return global_position + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))


## Gets a random roaming position on the navigation mesh.
func _get_random_roam_position() -> Vector3:
	# Try to find any evidence spawn point
	var spawn_points := get_tree().get_nodes_in_group("evidence_spawn_points")
	if not spawn_points.is_empty():
		var point: Node = spawn_points[randi() % spawn_points.size()]
		if point is Node3D:
			return (point as Node3D).global_position

	# Fallback: random offset from current position
	return global_position + Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))


## Attempts to perform a physical interaction.
func _attempt_interaction() -> void:
	# Find interactable objects nearby
	var interaction_range := 5.0

	# Try doors first
	var doors := get_tree().get_nodes_in_group("doors")
	for door in doors:
		if door is Node3D:
			var dist: float = global_position.distance_to((door as Node3D).global_position)
			if dist < interaction_range:
				if door.has_method("entity_interact"):
					door.entity_interact(self)
					_emit_interaction(ManifestationEnums.InteractionType.DOOR_SLAM)
					print("[Listener] Interacted with door")
					return

	# Try light switches
	var switches := get_tree().get_nodes_in_group("light_switches")
	for switch in switches:
		if switch is Node3D:
			var dist: float = global_position.distance_to((switch as Node3D).global_position)
			if dist < interaction_range:
				if switch.has_method("toggle"):
					switch.toggle()
					_emit_interaction(ManifestationEnums.InteractionType.LIGHT_FLICKER)
					print("[Listener] Flickered light")
					return

	# Try throwable objects
	var throwables := get_tree().get_nodes_in_group("throwables")
	for throwable in throwables:
		if throwable is Node3D:
			var dist: float = global_position.distance_to((throwable as Node3D).global_position)
			if dist < interaction_range:
				if throwable.has_method("entity_throw"):
					var direction := Vector3(randf_range(-1, 1), 0.5, randf_range(-1, 1)).normalized()
					throwable.entity_throw(direction * 5.0)
					_emit_interaction(ManifestationEnums.InteractionType.OBJECT_THROW)
					print("[Listener] Threw object")
					return


## Emits an interaction signal via EventBus.
func _emit_interaction(interaction_type: ManifestationEnums.InteractionType) -> void:
	if EventBus and EventBus.has_signal("entity_interaction"):
		EventBus.entity_interaction.emit(interaction_type, global_position)


## Attempts to manifest visually.
func _attempt_manifestation() -> void:
	# Only manifest if cooldown allows
	if _manifestation_cooldown_timer > 0:
		return

	# 30% chance to manifest on each attempt
	if randf() > 0.3:
		return

	# Start manifestation via base class
	var started := start_manifestation()
	if started:
		print("[Listener] Manifestation started")


## Checks if entity is currently in the favorite room.
func _is_in_favorite_room() -> bool:
	if _favorite_room == "":
		return false

	# Check nearby evidence spawn points for room name
	var spawn_points := get_tree().get_nodes_in_group("evidence_spawn_points")
	for point in spawn_points:
		if not point is Node3D:
			continue
		var dist: float = global_position.distance_to((point as Node3D).global_position)
		if dist < 3.0 and point.get("room_name") == _favorite_room:
			return true

	return false


## Creates a freezing temperature zone at current position.
func _create_freezing_zone() -> void:
	# Emit EventBus signal for temperature zone
	if EventBus and EventBus.has_signal("entity_temperature_zone"):
		EventBus.entity_temperature_zone.emit(global_position, -10.0, 5.0)  # -10°C, 5m radius
		print("[Listener] Created freezing zone at %v" % global_position)


## Checks for nearby ghost writing books and potentially writes in them.
func _check_ghost_writing_books() -> void:
	var books := get_tree().get_nodes_in_group("ghost_writing_books")
	for book in books:
		if not book is Node3D:
			continue

		var dist: float = global_position.distance_to((book as Node3D).global_position)
		if dist > ghost_writing_range:
			continue

		# Check if book is placed and ready for writing
		if not book.has_method("is_placed") or not book.is_placed():
			continue

		# Check if already written in
		if book.has_method("has_writing") and book.has_writing():
			continue

		# Chance-based writing
		if randf() < ghost_writing_chance:
			if book.has_method("entity_write"):
				book.entity_write(self)
				print("[Listener] Wrote in ghost writing book")

				# Emit evidence signal
				if EventBus and EventBus.has_signal("ghost_writing_triggered"):
					EventBus.ghost_writing_triggered.emit(
						(book as Node3D).global_position
					)


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
