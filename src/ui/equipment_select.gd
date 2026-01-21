extends Control
## Equipment selection screen shown during EQUIPMENT_SELECT game state.
##
## Players choose 3 equipment items from the available pool before
## investigation begins. Shows teammate selections in real-time.

# --- Constants ---

const EquipmentCardScene := preload("res://scenes/ui/equipment_card.tscn")

const MAX_SLOTS := 3

## Equipment data: [name, evidence type, description, icon emoji]
const EQUIPMENT_DATA: Dictionary = {
	Equipment.EquipmentType.EMF_READER: [
		"EMF Reader",
		"EMF Level 5",
		"Detects electromagnetic fluctuations. Level 5 readings indicate strong entity presence.",
		"📡"
	],
	Equipment.EquipmentType.THERMOMETER: [
		"Thermometer",
		"Freezing Temps",
		"Measures ambient temperature. Freezing temps (below 0°C) indicate entity activity.",
		"🌡️"
	],
	Equipment.EquipmentType.GHOST_WRITING_BOOK: [
		"Ghost Writing Book",
		"Ghost Writing",
		"Place near entity. Some entities will write messages in the book.",
		"📖"
	],
	Equipment.EquipmentType.SPECTRAL_PRISM_CALIBRATOR: [
		"Spectral Calibrator",
		"Prism Reading",
		"Cooperative: Works with Lens Reader. Calibrate the prism to detect spectral patterns.",
		"🔷"
	],
	Equipment.EquipmentType.SPECTRAL_PRISM_LENS: [
		"Spectral Lens",
		"Prism Reading",
		"Cooperative: Works with Calibrator. Read spectral patterns through calibrated prism.",
		"🔶"
	],
	Equipment.EquipmentType.DOWSING_RODS: [
		"Dowsing Rods",
		"Aura Pattern",
		"Cooperative: Works with Aura Imager. Points toward entity aura signature.",
		"🔮"
	],
	Equipment.EquipmentType.AURA_IMAGER: [
		"Aura Imager",
		"Aura Pattern",
		"Cooperative: Works with Dowsing Rods. Visualizes entity aura patterns.",
		"👁️"
	],
	Equipment.EquipmentType.CRUCIFIX: [
		"Crucifix",
		"",
		"Protection: Prevents hunts in a small radius when placed. Limited uses.",
		"✝️"
	],
	Equipment.EquipmentType.SAGE_BUNDLE: [
		"Sage Bundle",
		"",
		"Protection: Burning sage blinds the entity and prevents hunts temporarily.",
		"🌿"
	],
	Equipment.EquipmentType.SALT: [
		"Salt",
		"",
		"Protection: Place salt lines to detect entity footsteps. Reveals entity path.",
		"🧂"
	],
}

# --- State ---

var _selected_equipment: Array[int] = []
var _equipment_cards: Dictionary = {}  # equipment_type -> card node
var _is_ready: bool = false

# --- Node References ---

@onready var _equipment_grid: GridContainer = %EquipmentGrid
@onready var _selected_slots: HBoxContainer = %SelectedSlotsContainer
@onready var _timer_label: Label = %TimerLabel
@onready var _ready_button: Button = %ReadyButton
@onready var _selection_status: Label = %SelectionStatus
@onready var _tooltip_name: Label = %TooltipName
@onready var _tooltip_evidence: Label = %TooltipEvidence
@onready var _tooltip_description: Label = %TooltipDescription
@onready var _teammates_list: VBoxContainer = %TeammatesList


func _ready() -> void:
	_populate_equipment_grid()
	_setup_signals()
	_update_selection_display()
	_setup_cultist_visibility()


func _populate_equipment_grid() -> void:
	# Clear any existing children
	for child in _equipment_grid.get_children():
		child.queue_free()

	_equipment_cards.clear()

	# Create cards for each equipment type
	for equipment_type in EQUIPMENT_DATA.keys():
		var data: Array = EQUIPMENT_DATA[equipment_type]
		var card := EquipmentCardScene.instantiate()
		_equipment_grid.add_child(card)

		card.setup(
			equipment_type,
			data[0],  # name
			data[1],  # evidence type
			data[2]   # description
		)

		# Connect signals
		card.card_clicked.connect(_on_card_clicked)
		card.card_hovered.connect(_on_card_hovered)
		card.card_unhovered.connect(_on_card_unhovered)

		_equipment_cards[equipment_type] = card


func _setup_signals() -> void:
	_ready_button.pressed.connect(_on_ready_pressed)

	# Connect to EventBus for timer and teammate updates
	if has_node("/root/EventBus"):
		var event_bus := get_node("/root/EventBus")
		if event_bus.has_signal("phase_timer_tick"):
			event_bus.phase_timer_tick.connect(_on_timer_tick)
		if event_bus.has_signal("equipment_loadout_changed"):
			event_bus.equipment_loadout_changed.connect(_on_teammate_loadout_changed)


func _on_card_clicked(equipment_type: int) -> void:
	if _is_ready:
		return  # Can't change selection after ready

	# Check if already selected
	var index := _selected_equipment.find(equipment_type)

	if index >= 0:
		# Deselect
		_selected_equipment.remove_at(index)
		var card = _equipment_cards.get(equipment_type)
		if card:
			card.set_selected(false)
	else:
		# Select if we have room
		if _selected_equipment.size() < MAX_SLOTS:
			_selected_equipment.append(equipment_type)
			var card = _equipment_cards.get(equipment_type)
			if card:
				card.set_selected(true)

	_update_selection_display()
	_broadcast_selection()


func _on_card_hovered(equipment_type: int) -> void:
	var data: Array = EQUIPMENT_DATA.get(equipment_type, ["Unknown", "", "No description", "❓"])
	_tooltip_name.text = data[0]
	_tooltip_evidence.text = "Detects: " + data[1] if data[1] else "Protection Item"
	_tooltip_description.text = data[2]


func _on_card_unhovered(_equipment_type: int) -> void:
	_tooltip_name.text = "Hover over equipment"
	_tooltip_evidence.text = ""
	_tooltip_description.text = ""


func _update_selection_display() -> void:
	# Update slot labels
	var slot_labels: Array = _selected_slots.get_children()
	for i in range(MAX_SLOTS):
		if i >= slot_labels.size():
			continue

		var slot_panel: PanelContainer = slot_labels[i]
		var label: Label = slot_panel.get_child(0)

		if i < _selected_equipment.size():
			var equip_type: int = _selected_equipment[i]
			var data: Array = EQUIPMENT_DATA.get(equip_type, ["?", "", "", "❓"])
			label.text = "%d\n%s" % [i + 1, data[0]]
		else:
			label.text = "%d\nEmpty" % [i + 1]

	# Update status and ready button
	var count := _selected_equipment.size()
	_selection_status.text = "Select 3 equipment (%d/%d selected)" % [count, MAX_SLOTS]

	var can_ready := count == MAX_SLOTS
	_ready_button.disabled = not can_ready or _is_ready
	_ready_button.text = "Ready (%d/%d)" % [count, MAX_SLOTS] if not _is_ready else "Waiting..."


func _on_ready_pressed() -> void:
	if _selected_equipment.size() != MAX_SLOTS:
		return

	_is_ready = true
	_ready_button.disabled = true
	_ready_button.text = "Waiting..."

	# Lock selection visually
	for card in _equipment_cards.values():
		card.modulate = Color(0.7, 0.7, 0.7) if not card.is_selected() else card.modulate

	# Notify server
	_submit_selection()


func _on_timer_tick(time_remaining: float) -> void:
	var minutes := int(time_remaining) / 60
	var seconds := int(time_remaining) % 60
	_timer_label.text = "%d:%02d" % [minutes, seconds]

	# Visual warning when time low
	if time_remaining <= 10.0:
		_timer_label.modulate = Color(1.0, 0.3, 0.3)
	elif time_remaining <= 30.0:
		_timer_label.modulate = Color(1.0, 0.7, 0.3)
	else:
		_timer_label.modulate = Color.WHITE


func _on_teammate_loadout_changed(player_id: int, loadout: Array) -> void:
	# Cultists see all teammate equipment selections in real-time
	# Non-Cultists only see after EQUIPMENT_SELECT phase ends
	if _can_see_teammate_loadout():
		_update_teammate_display(player_id, loadout)


## Returns true if local player can see teammate equipment selections.
## Cultists can see all selections during EQUIPMENT_SELECT for strategic planning.
func _can_see_teammate_loadout() -> bool:
	# Check if CultistManager exists and local player is a Cultist
	if has_node("/root/CultistManager"):
		var cultist_manager := get_node("/root/CultistManager")
		if cultist_manager.has_method("is_local_player_cultist"):
			return cultist_manager.is_local_player_cultist()
	# Default: don't show teammate selections
	return false


## Setup visibility UI based on Cultist status.
func _setup_cultist_visibility() -> void:
	# Hide teammates list for non-Cultists, show for Cultists
	if _teammates_list:
		_teammates_list.visible = _can_see_teammate_loadout()

		# Add header label for Cultist advantage
		if _can_see_teammate_loadout():
			var header := Label.new()
			header.text = "Team Loadouts (Cultist Intel)"
			header.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
			_teammates_list.add_child(header)
			_teammates_list.move_child(header, 0)


func _update_teammate_display(player_id: int, loadout: Array) -> void:
	# Find or create row for this player
	var player_row: HBoxContainer = null
	for child in _teammates_list.get_children():
		if child.has_meta("player_id") and child.get_meta("player_id") == player_id:
			player_row = child
			break

	if not player_row:
		player_row = HBoxContainer.new()
		player_row.set_meta("player_id", player_id)
		_teammates_list.add_child(player_row)

		var name_label := Label.new()
		name_label.text = "Player %d:" % player_id
		name_label.custom_minimum_size.x = 100
		player_row.add_child(name_label)

		for i in range(MAX_SLOTS):
			var slot_label := Label.new()
			slot_label.name = "Slot%d" % i
			slot_label.text = "---"
			slot_label.custom_minimum_size.x = 50
			player_row.add_child(slot_label)

	# Update slot labels
	for i in range(MAX_SLOTS):
		var slot_label: Label = player_row.get_node_or_null("Slot%d" % i)
		if slot_label and i < loadout.size():
			var equip_type: int = loadout[i]
			if equip_type >= 0:
				var data: Array = EQUIPMENT_DATA.get(equip_type, ["?", "", "", "❓"])
				slot_label.text = data[0].substr(0, 8)  # Truncate name
			else:
				slot_label.text = "---"


func _broadcast_selection() -> void:
	# Emit selection change to EventBus for network sync
	if has_node("/root/EventBus"):
		var event_bus := get_node("/root/EventBus")
		if event_bus.has_signal("equipment_loadout_changed"):
			var player_id: int = _get_local_player_id()
			event_bus.equipment_loadout_changed.emit(player_id, _selected_equipment)


func _submit_selection() -> void:
	# Final submission when ready
	# In actual implementation, this would go through EquipmentManager
	print("[EquipmentSelect] Submitted loadout: ", _selected_equipment)


func _get_local_player_id() -> int:
	# Get local player ID (placeholder - actual implementation uses NetworkManager)
	if multiplayer.has_multiplayer_peer():
		return multiplayer.get_unique_id()
	return 1


## Called when timer expires - auto-submit current selection.
func force_submit() -> void:
	if _is_ready:
		return

	# Fill empty slots with first available equipment if needed
	while _selected_equipment.size() < MAX_SLOTS:
		for equip_type in EQUIPMENT_DATA.keys():
			if equip_type not in _selected_equipment:
				_selected_equipment.append(equip_type)
				break

	_is_ready = true
	_submit_selection()


## Returns the current selection.
func get_selection() -> Array[int]:
	return _selected_equipment


## Returns whether selection is complete and confirmed.
func is_selection_ready() -> bool:
	return _is_ready
