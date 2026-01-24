extends Control
## Entity selection popup for proposing identification during deliberation.
##
## Displays all possible entities in a grid, with visual indicators for:
## - Eliminated entities (gray, based on evidence)
## - Possible entities (highlighted, match collected evidence)

# --- Signals ---

signal entity_selected(entity_type: String)
signal cancelled

# --- Constants ---

## All entity types available in the game
const ALL_ENTITIES: Array[String] = [
	"Phantom",
	"Banshee",
	"Revenant",
	"Shade",
	"Poltergeist",
	"Wraith",
	"Mare",
	"Demon",
]

## Entity icons for display
const ENTITY_ICONS: Dictionary = {
	"Phantom": "👻",
	"Banshee": "💀",
	"Revenant": "🧟",
	"Shade": "🌑",
	"Poltergeist": "🪑",
	"Wraith": "👤",
	"Mare": "🌙",
	"Demon": "😈",
}

## Entity evidence mapping for elimination logic
const ENTITY_EVIDENCE: Dictionary = {
	"Phantom": ["EMF_SIGNATURE", "SPIRIT_BOX", "DOTS"],
	"Banshee": ["GHOST_ORBS", "FINGERPRINTS", "DOTS"],
	"Revenant": ["FREEZING_TEMPERATURE", "GHOST_ORBS", "GHOST_WRITING"],
	"Shade": ["EMF_SIGNATURE", "GHOST_WRITING", "FREEZING_TEMPERATURE"],
	"Poltergeist": ["SPIRIT_BOX", "FINGERPRINTS", "GHOST_WRITING"],
	"Wraith": ["EMF_SIGNATURE", "SPIRIT_BOX", "DOTS"],
	"Mare": ["SPIRIT_BOX", "GHOST_ORBS", "GHOST_WRITING"],
	"Demon": ["FINGERPRINTS", "GHOST_WRITING", "FREEZING_TEMPERATURE"],
}

# --- State ---

var _eliminated_entities: Array[String] = []
var _possible_entities: Array[String] = []
var _selected_entity: String = ""

# --- Node References ---

@onready var _title_label: Label = %TitleLabel
@onready var _grid: GridContainer = %EntityGrid
@onready var _confirm_button: Button = %ConfirmButton
@onready var _cancel_button: Button = %CancelButton
@onready var _selected_label: Label = %SelectedLabel


func _ready() -> void:
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_cancel_button.pressed.connect(_on_cancel_pressed)
	_confirm_button.disabled = true
	_populate_grid()
	hide()


## Shows the selection popup, optionally with pre-calculated entity possibilities.
func show_selection(eliminated: Array[String] = [], possible: Array[String] = []) -> void:
	_eliminated_entities = eliminated
	_possible_entities = possible if possible.size() > 0 else _calculate_possible_entities()
	_selected_entity = ""
	_confirm_button.disabled = true
	_selected_label.text = "Select an entity to identify..."
	_update_entity_buttons()
	show()
	grab_focus()


## Hides the selection popup.
func hide_selection() -> void:
	hide()


## Returns the currently selected entity.
func get_selected_entity() -> String:
	return _selected_entity


# --- Private Methods ---


func _populate_grid() -> void:
	# Clear existing buttons
	for child in _grid.get_children():
		child.queue_free()

	# Create a button for each entity
	for entity_type in ALL_ENTITIES:
		var button := Button.new()
		button.custom_minimum_size = Vector2(150, 100)
		button.name = entity_type

		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER

		var icon_label := Label.new()
		icon_label.text = ENTITY_ICONS.get(entity_type, "❓")
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.add_theme_font_size_override("font_size", 32)

		var name_label := Label.new()
		name_label.text = entity_type
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 14)

		vbox.add_child(icon_label)
		vbox.add_child(name_label)
		button.add_child(vbox)

		button.pressed.connect(_on_entity_button_pressed.bind(entity_type))
		_grid.add_child(button)


func _update_entity_buttons() -> void:
	for child in _grid.get_children():
		if child is Button:
			var entity_type: String = child.name
			var is_eliminated := entity_type in _eliminated_entities
			var is_possible := entity_type in _possible_entities
			var is_selected := entity_type == _selected_entity

			# Update visual state
			if is_selected:
				child.modulate = Color(0.5, 1.0, 0.5)  # Green highlight
			elif is_eliminated:
				child.modulate = Color(0.4, 0.4, 0.4)  # Gray (eliminated)
				child.disabled = true
			elif is_possible:
				child.modulate = Color(1.0, 1.0, 0.8)  # Yellow-white (possible)
				child.disabled = false
			else:
				child.modulate = Color(0.7, 0.7, 0.7)  # Dim (no evidence either way)
				child.disabled = false


func _calculate_possible_entities() -> Array[String]:
	# If no evidence manager, all entities are possible
	if not has_node("/root/EvidenceManager"):
		return ALL_ENTITIES.duplicate()

	# Get collected evidence types
	var collected_evidence: Array = EvidenceManager.get_all_evidence()
	var evidence_types: Array[String] = []

	for evidence in collected_evidence:
		if evidence is Dictionary and evidence.has("type"):
			var type_str: String = evidence.type
			if type_str not in evidence_types:
				evidence_types.append(type_str)

	# If no evidence collected, all entities possible
	if evidence_types.is_empty():
		return ALL_ENTITIES.duplicate()

	# Filter to entities that match all collected evidence
	var possible: Array[String] = []
	for entity_type in ALL_ENTITIES:
		var entity_evidence: Array = ENTITY_EVIDENCE.get(entity_type, [])
		var matches_all := true

		for collected_type in evidence_types:
			if collected_type not in entity_evidence:
				matches_all = false
				break

		if matches_all:
			possible.append(entity_type)

	return possible


func _on_entity_button_pressed(entity_type: String) -> void:
	_selected_entity = entity_type
	_selected_label.text = "Selected: %s" % entity_type
	_confirm_button.disabled = false
	_update_entity_buttons()
	print("[EntitySelection] Selected: %s" % entity_type)


func _on_confirm_pressed() -> void:
	if _selected_entity.is_empty():
		return

	entity_selected.emit(_selected_entity)
	hide_selection()
	print("[EntitySelection] Confirmed: %s" % _selected_entity)


func _on_cancel_pressed() -> void:
	cancelled.emit()
	hide_selection()
	print("[EntitySelection] Cancelled")
