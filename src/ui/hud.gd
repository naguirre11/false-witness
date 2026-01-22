extends CanvasLayer
## In-game HUD displaying equipment hotbar, timer, interaction prompts, and status.
##
## Manages visibility based on game state and connects to relevant managers
## for real-time updates.

# --- Constants ---

const SLOT_COUNT := 3

## Base scale for voice icon when transmitting.
const VOICE_ICON_BASE_SCALE := 1.0

## Max scale when voice icon pulses with amplitude.
const VOICE_ICON_PULSE_SCALE := 1.3

## Speed of pulse animation.
const VOICE_PULSE_SPEED := 8.0

# --- State ---

var _is_voice_active: bool = false
var _current_phase: String = "Investigation"
var _active_slot: int = 0
var _voice_pulse_time: float = 0.0

# --- Node References ---

@onready var _voice_icon: Label = %VoiceIcon
@onready var _voice_label: Label = %VoiceLabel
@onready var _phase_label: Label = %PhaseLabel
@onready var _timer_label: Label = %TimerLabel
@onready var _equipment_hotbar: HBoxContainer = %EquipmentHotbar
@onready var _interaction_prompt: Label = %InteractionPrompt
@onready var _evidence_board_hint: Label = %EvidenceBoardHint
@onready var _death_overlay: ColorRect = %DeathOverlay


func _ready() -> void:
	_setup_signals()
	_update_hotbar_display()
	hide_death_overlay()


func _setup_signals() -> void:
	# Connect to EventBus signals
	if has_node("/root/EventBus"):
		var event_bus := get_node("/root/EventBus")

		if event_bus.has_signal("game_state_changed"):
			event_bus.game_state_changed.connect(_on_game_state_changed)

		if event_bus.has_signal("phase_timer_tick"):
			event_bus.phase_timer_tick.connect(_on_timer_tick)

		if event_bus.has_signal("player_became_echo"):
			event_bus.player_became_echo.connect(_on_player_became_echo)

	# Connect to VoiceManager for voice indicator
	if has_node("/root/VoiceManager"):
		var voice_manager := get_node("/root/VoiceManager")

		if voice_manager.has_signal("voice_state_changed"):
			voice_manager.voice_state_changed.connect(_on_voice_state_changed)

	# TODO: Connect to InteractionManager for prompts


func _process(delta: float) -> void:
	# Animate voice icon pulse when transmitting
	if _is_voice_active and _voice_icon.visible:
		_voice_pulse_time += delta * VOICE_PULSE_SPEED
		var pulse: float = (sin(_voice_pulse_time) + 1.0) / 2.0  # 0.0 to 1.0
		var voice_scale: float = lerpf(VOICE_ICON_BASE_SCALE, VOICE_ICON_PULSE_SCALE, pulse)
		_voice_icon.scale = Vector2(voice_scale, voice_scale)

		# Also modulate color intensity
		var color_pulse: float = lerpf(0.8, 1.0, pulse)
		_voice_icon.modulate = Color(color_pulse, color_pulse, color_pulse, 1.0)


func _input(event: InputEvent) -> void:
	# Toggle evidence board with Tab
	if event.is_action_pressed("toggle_evidence_board"):
		_toggle_evidence_board()


# --- Public API ---


## Shows the death/spectator overlay.
func show_death_overlay() -> void:
	_death_overlay.visible = true


## Hides the death/spectator overlay.
func hide_death_overlay() -> void:
	_death_overlay.visible = false


## Shows the interaction prompt with given text.
func show_interaction_prompt(text: String) -> void:
	_interaction_prompt.text = text
	_interaction_prompt.visible = true


## Hides the interaction prompt.
func hide_interaction_prompt() -> void:
	_interaction_prompt.visible = false


## Updates the equipment hotbar with given loadout.
func update_hotbar(loadout: Array) -> void:
	var slots: Array = _equipment_hotbar.get_children()

	for i in range(mini(SLOT_COUNT, slots.size())):
		var slot_panel: PanelContainer = slots[i]
		var content: VBoxContainer = slot_panel.get_child(0)

		var icon_label: Label = content.get_node_or_null("Slot%dIcon" % (i + 1))
		var name_label: Label = content.get_node_or_null("Slot%dName" % (i + 1))

		if i < loadout.size() and loadout[i] >= 0:
			var equip_type: int = loadout[i]
			var equip_name: String = _get_equipment_name(equip_type)
			var equip_icon: String = _get_equipment_icon(equip_type)

			if icon_label:
				icon_label.text = equip_icon
			if name_label:
				name_label.text = equip_name
		else:
			if icon_label:
				icon_label.text = "📦"
			if name_label:
				name_label.text = "Empty"


## Sets the active equipment slot (highlighted).
func set_active_slot(slot_index: int) -> void:
	_active_slot = slot_index
	_update_hotbar_highlight()


## Updates the phase timer display.
func set_timer(time_remaining: float, phase_name: String) -> void:
	_current_phase = phase_name
	_phase_label.text = phase_name

	var minutes := int(time_remaining) / 60
	var seconds := int(time_remaining) % 60
	_timer_label.text = "%d:%02d" % [minutes, seconds]

	# Visual warning when time low
	if time_remaining <= 60.0:
		_timer_label.modulate = Color(1.0, 0.3, 0.3)
	elif time_remaining <= 120.0:
		_timer_label.modulate = Color(1.0, 0.7, 0.3)
	else:
		_timer_label.modulate = Color.WHITE


# --- Signal Handlers ---


func _on_game_state_changed(_old_state: int, new_state: int) -> void:
	# Show/hide HUD based on game state
	# GameState: NONE=0, LOBBY=1, SETUP=2, INVESTIGATION=3, HUNT=4, DELIBERATION=5, RESULTS=6
	match new_state:
		0, 1, 6:  # NONE, LOBBY, RESULTS
			visible = false
		2:  # SETUP/EQUIPMENT_SELECT
			visible = false  # Equipment select has its own UI
		3:  # INVESTIGATION
			visible = true
			_phase_label.text = "Investigation"
		4:  # HUNT
			visible = true
			_phase_label.text = "HUNT!"
			_timer_label.modulate = Color(1.0, 0.3, 0.3)
		5:  # DELIBERATION
			visible = true
			_phase_label.text = "Deliberation"
		_:
			visible = true


func _on_timer_tick(time_remaining: float) -> void:
	set_timer(time_remaining, _current_phase)


func _on_player_became_echo(player_id: int) -> void:
	# Check if this is the local player
	var local_id: int = _get_local_player_id()
	if player_id == local_id:
		show_death_overlay()


func _on_voice_state_changed(state: int) -> void:
	# VoiceState: IDLE=0, TRANSMITTING=1, RECEIVING=2
	var is_transmitting: bool = (state == 1)
	_set_voice_active(is_transmitting)


# --- Internal Methods ---


func _update_hotbar_display() -> void:
	# Initialize with empty slots
	update_hotbar([-1, -1, -1])
	_update_hotbar_highlight()


func _update_hotbar_highlight() -> void:
	var slots: Array = _equipment_hotbar.get_children()

	for i in range(slots.size()):
		var slot_panel: PanelContainer = slots[i]
		if i == _active_slot:
			slot_panel.modulate = Color(1.2, 1.2, 0.8)  # Highlight
		else:
			slot_panel.modulate = Color.WHITE


func _toggle_evidence_board() -> void:
	# Emit signal or directly toggle evidence board visibility
	if has_node("/root/EventBus"):
		var event_bus := get_node("/root/EventBus")
		# TODO: Add evidence_board_toggled signal if needed
		print("[HUD] Evidence board toggle requested")


func _set_voice_active(active: bool) -> void:
	_is_voice_active = active
	_voice_icon.visible = active
	_voice_label.visible = active

	if active:
		# Reset pulse animation
		_voice_pulse_time = 0.0
		_voice_label.text = "Transmitting..."
	else:
		# Reset icon scale and color when not transmitting
		_voice_icon.scale = Vector2.ONE
		_voice_icon.modulate = Color.WHITE


func _get_local_player_id() -> int:
	if multiplayer.has_multiplayer_peer():
		return multiplayer.get_unique_id()
	return 1


func _get_equipment_name(equip_type: int) -> String:
	# Use EquipmentSlot's static method if available
	if equip_type < 0:
		return "Empty"

	var names: Dictionary = {
		0: "EMF",
		1: "Spirit Box",
		2: "Journal",
		3: "Thermo",
		4: "UV Light",
		5: "DOTS",
		6: "Camera",
		7: "Parabolic",
		8: "Calibrator",
		9: "Lens",
		10: "Rods",
		11: "Imager",
		12: "Book",
		13: "Crucifix",
		14: "Sage",
		15: "Salt",
	}
	return names.get(equip_type, "???")


func _get_equipment_icon(equip_type: int) -> String:
	var icons: Dictionary = {
		0: "📡",   # EMF Reader
		1: "📻",   # Spirit Box
		2: "📓",   # Journal
		3: "🌡️",  # Thermometer
		4: "🔦",   # UV Flashlight
		5: "💠",   # DOTS Projector
		6: "📹",   # Video Camera
		7: "🎙️",  # Parabolic Mic
		8: "🔷",   # Spectral Calibrator
		9: "🔶",   # Spectral Lens
		10: "🔮",  # Dowsing Rods
		11: "👁️", # Aura Imager
		12: "📖",  # Ghost Writing Book
		13: "✝️",  # Crucifix
		14: "🌿",  # Sage Bundle
		15: "🧂",  # Salt
	}
	return icons.get(equip_type, "📦")
