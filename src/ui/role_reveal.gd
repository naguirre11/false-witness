extends Control
## Role reveal popup shown at match start.
##
## Displays the player's assigned role (Investigator or Cultist).
## For Cultists, shows secret intel about the true entity type.
## Auto-dismisses after timeout or on click.

# --- Signals ---

## Emitted when the reveal is dismissed (timeout or click).
signal dismissed

# --- Constants ---

## Time before auto-dismiss (seconds)
const AUTO_DISMISS_TIME := 10.0

## Colors for role display
const INVESTIGATOR_COLOR := Color(0.3, 0.6, 1.0)  # Blue
const CULTIST_COLOR := Color(0.8, 0.2, 0.2)  # Red

# --- State ---

var _is_cultist: bool = false
var _entity_type: String = ""
var _entity_evidence: Array[String] = []
var _allied_cultist_names: Array[String] = []
var _timer: float = AUTO_DISMISS_TIME

# --- Node References ---

@onready var _dimmer: ColorRect = %Dimmer
@onready var _panel: PanelContainer = %Panel
@onready var _role_label: Label = %RoleLabel
@onready var _role_description: Label = %RoleDescription
@onready var _timer_label: Label = %TimerLabel
@onready var _entity_info_container: VBoxContainer = %EntityInfoContainer
@onready var _entity_type_label: Label = %EntityTypeLabel
@onready var _entity_evidence_label: Label = %EntityEvidenceLabel
@onready var _allies_container: VBoxContainer = %AlliesContainer
@onready var _allies_label: Label = %AlliesLabel
@onready var _ability_overview: Label = %AbilityOverview
@onready var _dismiss_button: Button = %DismissButton


func _ready() -> void:
	_dismiss_button.pressed.connect(_on_dismiss_pressed)
	_dimmer.gui_input.connect(_on_dimmer_input)


func _process(delta: float) -> void:
	_timer -= delta
	_update_timer_display()

	if _timer <= 0:
		_dismiss()


## Show the role reveal for an Investigator.
func show_investigator_role() -> void:
	_is_cultist = false
	_configure_investigator_display()
	_start_reveal()


## Show the role reveal for a Cultist with secret intel.
func show_cultist_role(
	entity_type: String, entity_evidence: Array[String], allied_names: Array[String] = []
) -> void:
	_is_cultist = true
	_entity_type = entity_type
	_entity_evidence = entity_evidence
	_allied_cultist_names = allied_names
	_configure_cultist_display()
	_start_reveal()


func _configure_investigator_display() -> void:
	_role_label.text = "INVESTIGATOR"
	_role_label.add_theme_color_override("font_color", INVESTIGATOR_COLOR)

	_role_description.text = (
		"Your mission: Investigate the paranormal entity and identify its type.\n"
		+ "Use your equipment to gather evidence and work with your team.\n"
		+ "Be vigilant - there may be a Cultist among you."
	)

	# Hide Cultist-specific sections
	_entity_info_container.visible = false
	_allies_container.visible = false
	_ability_overview.visible = false


func _configure_cultist_display() -> void:
	_role_label.text = "CULTIST"
	_role_label.add_theme_color_override("font_color", CULTIST_COLOR)

	_role_description.text = (
		"You serve the entity. Misdirect the investigators.\n"
		+ "Plant false evidence and lead them to the wrong conclusion.\n"
		+ "Don't get discovered - or lose your power."
	)

	# Show Cultist-specific sections
	_entity_info_container.visible = true
	_entity_type_label.text = "True Entity: %s" % _entity_type
	_entity_evidence_label.text = "Evidence Types: %s" % ", ".join(_entity_evidence)

	# Show allies if 2-Cultist variant
	if _allied_cultist_names.size() > 0:
		_allies_container.visible = true
		_allies_label.text = "Allied Cultist: %s" % ", ".join(_allied_cultist_names)
	else:
		_allies_container.visible = false

	# Show ability overview
	_ability_overview.visible = true
	_ability_overview.text = (
		"ABILITIES:\n"
		+ "• EMF Spoof (2x) - Plant false EMF readings\n"
		+ "• Temperature Manipulation (2x) - Create cold zones\n"
		+ "• Prism Interference (1x) - Corrupt prism data\n"
		+ "• Aura Disruption (2x) - Plant false aura trails\n"
		+ "• Provocation (1x) - Force a hunt\n"
		+ "• False Alarm (1x) - Fake hunt warning\n"
		+ "• Equipment Sabotage (1x) - Disable teammate equipment"
	)


func _start_reveal() -> void:
	_timer = AUTO_DISMISS_TIME
	visible = true

	# Animate panel entry
	var tween := create_tween()
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.8, 0.8)
	tween.set_parallel(true)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.3)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)


func _update_timer_display() -> void:
	var seconds := int(ceil(_timer))
	_timer_label.text = "Auto-dismiss in %d..." % seconds

	# Flash when low
	if _timer <= 3.0:
		_timer_label.modulate = Color(1.0, 0.5, 0.5) if int(_timer * 2) % 2 == 0 else Color.WHITE


func _dismiss() -> void:
	# Animate out
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_panel, "modulate:a", 0.0, 0.2)
	tween.tween_property(_dimmer, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(_on_dismiss_complete)


func _on_dismiss_complete() -> void:
	visible = false
	dismissed.emit()


func _on_dismiss_pressed() -> void:
	_dismiss()


func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_dismiss()
