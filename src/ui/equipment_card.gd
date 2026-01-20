extends PanelContainer
## UI component displaying a single equipment item for selection.
##
## Used in the equipment selection grid. Emits signals when clicked or hovered
## to allow the parent screen to handle selection logic and tooltips.

# --- Signals ---

signal card_clicked(equipment_type: int)
signal card_hovered(equipment_type: int)
signal card_unhovered(equipment_type: int)

# --- State ---

var _equipment_type: int = -1
var _is_selected: bool = false
var _evidence_type: String = ""
var _description: String = ""

# --- Node References ---

@onready var _equipment_name: Label = %EquipmentName
@onready var _evidence_label: Label = %EvidenceType
@onready var _selection_indicator: Label = %SelectionIndicator
@onready var _equipment_icon: TextureRect = %EquipmentIcon


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)


## Sets up the card with equipment data.
func setup(equipment_type: int, equipment_name: String, evidence: String, desc: String) -> void:
	_equipment_type = equipment_type
	_evidence_type = evidence
	_description = desc

	_equipment_name.text = equipment_name
	_evidence_label.text = evidence if evidence else "Protection"
	_selection_indicator.visible = false


## Returns the equipment type this card represents.
func get_equipment_type() -> int:
	return _equipment_type


## Returns the evidence type this equipment detects.
func get_evidence_type() -> String:
	return _evidence_type


## Returns the equipment description.
func get_description() -> String:
	return _description


## Returns the equipment name.
func get_equipment_name() -> String:
	return _equipment_name.text


## Sets whether this card is selected.
func set_selected(selected: bool) -> void:
	_is_selected = selected
	_selection_indicator.visible = selected

	# Visual feedback for selection
	if selected:
		modulate = Color(0.8, 1.0, 0.8)
	else:
		modulate = Color.WHITE


## Returns whether this card is selected.
func is_selected() -> bool:
	return _is_selected


## Sets the equipment icon texture.
func set_icon(texture: Texture2D) -> void:
	if _equipment_icon and texture:
		_equipment_icon.texture = texture


# --- Input Handling ---


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			card_clicked.emit(_equipment_type)
			accept_event()


func _on_mouse_entered() -> void:
	card_hovered.emit(_equipment_type)
	# Hover visual
	if not _is_selected:
		modulate = Color(1.1, 1.1, 1.1)


func _on_mouse_exited() -> void:
	card_unhovered.emit(_equipment_type)
	# Reset hover visual
	if not _is_selected:
		modulate = Color.WHITE
