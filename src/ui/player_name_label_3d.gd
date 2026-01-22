extends Node3D
## 3D label that shows player name above their head, Cultist indicator when discovered,
## and voice speaker icon when the player is talking.
##
## Billboards to always face the camera.
## Shows player name normally, adds "CULTIST" indicator when discovered.
## Shows speaker icon when player is transmitting voice.

# --- Constants ---

## Color for normal player name.
const NAME_COLOR := Color(1.0, 1.0, 1.0, 1.0)

## Color for discovered Cultist indicator and name.
const CULTIST_COLOR := Color(0.9, 0.15, 0.15, 1.0)

## Color for voice speaker icon.
const SPEAKER_COLOR := Color(0.3, 1.0, 0.3, 1.0)

## Outline color for visibility.
const OUTLINE_COLOR := Color(0.0, 0.0, 0.0, 1.0)

## Font size for player name.
const NAME_FONT_SIZE := 16

## Font size for Cultist indicator.
const CULTIST_FONT_SIZE := 20

## Font size for speaker icon.
const SPEAKER_FONT_SIZE := 18

## Height offset above player head for name.
const NAME_HEIGHT_OFFSET := 0.3

## Height offset for Cultist indicator (above name).
const CULTIST_HEIGHT_OFFSET := 0.5

## Height offset for speaker icon (above Cultist indicator or name if no Cultist).
const SPEAKER_HEIGHT_OFFSET := 0.7

## Speed of speaker icon pulse animation.
const SPEAKER_PULSE_SPEED := 6.0

# --- State ---

var _player_id: int = -1
var _player_name: String = ""
var _is_discovered_cultist: bool = false
var _is_speaking: bool = false
var _speaker_pulse_time: float = 0.0

# --- Node References ---

var _name_label: Label3D
var _cultist_label: Label3D
var _speaker_label: Label3D


func _ready() -> void:
	_setup_labels()
	_connect_signals()


func _setup_labels() -> void:
	# Name label - always visible when player has a name
	_name_label = Label3D.new()
	_name_label.name = "NameLabel3D"
	_name_label.font_size = NAME_FONT_SIZE
	_name_label.modulate = NAME_COLOR
	_name_label.outline_modulate = OUTLINE_COLOR
	_name_label.outline_size = 2
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.no_depth_test = true
	_name_label.position.y = NAME_HEIGHT_OFFSET
	_name_label.visible = false
	add_child(_name_label)

	# Cultist indicator - only visible when discovered
	_cultist_label = Label3D.new()
	_cultist_label.name = "CultistLabel3D"
	_cultist_label.text = "CULTIST"
	_cultist_label.font_size = CULTIST_FONT_SIZE
	_cultist_label.modulate = CULTIST_COLOR
	_cultist_label.outline_modulate = OUTLINE_COLOR
	_cultist_label.outline_size = 4
	_cultist_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_cultist_label.no_depth_test = true
	_cultist_label.position.y = CULTIST_HEIGHT_OFFSET
	_cultist_label.visible = false
	add_child(_cultist_label)

	# Speaker icon - visible when player is transmitting voice
	_speaker_label = Label3D.new()
	_speaker_label.name = "SpeakerLabel3D"
	_speaker_label.text = "🔊"  # Speaker with sound waves emoji
	_speaker_label.font_size = SPEAKER_FONT_SIZE
	_speaker_label.modulate = SPEAKER_COLOR
	_speaker_label.outline_modulate = OUTLINE_COLOR
	_speaker_label.outline_size = 2
	_speaker_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_speaker_label.no_depth_test = true
	_speaker_label.position.y = SPEAKER_HEIGHT_OFFSET
	_speaker_label.visible = false
	add_child(_speaker_label)


func _connect_signals() -> void:
	# Connect to CultistManager signals
	if has_node("/root/CultistManager"):
		var cultist_manager := get_node("/root/CultistManager")
		if cultist_manager.has_signal("cultist_discovered"):
			cultist_manager.cultist_discovered.connect(_on_cultist_discovered)

	# Connect to VoiceManager for voice activity
	if has_node("/root/VoiceManager"):
		var voice_manager := get_node("/root/VoiceManager")
		if voice_manager.has_signal("voice_activity"):
			voice_manager.voice_activity.connect(_on_voice_activity)


func _process(delta: float) -> void:
	# Animate speaker icon pulse when speaking
	if _is_speaking and _speaker_label and _speaker_label.visible:
		_speaker_pulse_time += delta * SPEAKER_PULSE_SPEED
		var pulse: float = (sin(_speaker_pulse_time) + 1.0) / 2.0  # 0.0 to 1.0
		var speaker_scale: float = lerpf(0.9, 1.2, pulse)
		_speaker_label.scale = Vector3(speaker_scale, speaker_scale, speaker_scale)

		# Pulse the alpha for more visual feedback
		var alpha_pulse: float = lerpf(0.7, 1.0, pulse)
		_speaker_label.modulate.a = alpha_pulse


## Sets the player ID this label is tracking.
func set_player_id(player_id: int) -> void:
	_player_id = player_id
	# Check if already discovered
	_check_discovery_state()


## Gets the player ID this label is tracking.
func get_player_id() -> int:
	return _player_id


## Sets the player name to display.
func set_player_name(player_name: String) -> void:
	_player_name = player_name
	if _name_label:
		_name_label.text = player_name
		_name_label.visible = player_name.length() > 0
		_update_label_positions()


## Gets the player name being displayed.
func get_player_name() -> String:
	return _player_name


func _on_cultist_discovered(discovered_player_id: int) -> void:
	if discovered_player_id == _player_id:
		_show_cultist_indicator()


func _on_voice_activity(speaking_player_id: int, amplitude: float) -> void:
	if speaking_player_id == _player_id:
		# Player is speaking
		_show_speaker_icon(amplitude)


## Shows the speaker icon when player is transmitting voice.
func _show_speaker_icon(amplitude: float) -> void:
	if not _speaker_label:
		return

	if not _is_speaking:
		_is_speaking = true
		_speaker_pulse_time = 0.0
		_speaker_label.visible = true
		_speaker_label.modulate = SPEAKER_COLOR

	# Reset hide timer (speaker hides after brief silence)
	_reset_speaker_timer()


## Hides the speaker icon after silence.
func _hide_speaker_icon() -> void:
	_is_speaking = false
	if _speaker_label:
		_speaker_label.visible = false
		_speaker_label.scale = Vector3.ONE


## Resets the timer that hides the speaker icon.
## Called each time voice activity is received.
func _reset_speaker_timer() -> void:
	# Cancel existing timer
	if has_node("SpeakerHideTimer"):
		var old_timer := get_node("SpeakerHideTimer")
		old_timer.queue_free()

	# Create new timer to hide speaker after brief silence
	var timer := Timer.new()
	timer.name = "SpeakerHideTimer"
	timer.one_shot = true
	timer.wait_time = 0.5  # Hide after 500ms of no voice activity
	timer.timeout.connect(_hide_speaker_icon)
	add_child(timer)
	timer.start()


func _show_cultist_indicator() -> void:
	if _is_discovered_cultist:
		return

	_is_discovered_cultist = true

	if _cultist_label:
		_cultist_label.visible = true
		_animate_cultist_appear()

	# Change name label color to red
	if _name_label:
		_name_label.modulate = CULTIST_COLOR

	_update_label_positions()


func _check_discovery_state() -> void:
	if _player_id < 0:
		return

	if has_node("/root/CultistManager"):
		var cultist_manager := get_node("/root/CultistManager")
		if cultist_manager.has_method("is_cultist_discovered"):
			var is_discovered: bool = cultist_manager.is_cultist_discovered(_player_id)
			if is_discovered:
				_show_cultist_indicator()


func _update_label_positions() -> void:
	# If Cultist indicator is showing, move name label down slightly
	if _name_label:
		_name_label.position.y = NAME_HEIGHT_OFFSET

	if _cultist_label and _is_discovered_cultist:
		_cultist_label.position.y = CULTIST_HEIGHT_OFFSET


func _animate_cultist_appear() -> void:
	if not _cultist_label:
		return

	# Simple fade in animation with scale pop
	var tween := create_tween()
	_cultist_label.modulate.a = 0.0
	_cultist_label.scale = Vector3(1.5, 1.5, 1.5)
	tween.tween_property(_cultist_label, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(_cultist_label, "scale", Vector3.ONE, 0.3)


## Returns true if this player has been discovered as a Cultist.
func is_discovered() -> bool:
	return _is_discovered_cultist


## Returns true if this player is currently speaking.
func is_speaking() -> bool:
	return _is_speaking
