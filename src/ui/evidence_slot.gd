class_name EvidenceSlot
extends Control
## Displays a single evidence type on the evidence board.
##
## Shows the evidence name, icon (placeholder), and collection status.
## Visual styling based on trust levels communicates evidence reliability.

signal slot_pressed(evidence_type: EvidenceEnums.EvidenceType)

# --- Constants ---

const SLOT_SIZE := Vector2(120, 80)

## Trust level border colors per ticket FW-035b
const TRUST_COLORS: Dictionary = {
	EvidenceEnums.TrustLevel.UNFALSIFIABLE: Color.GOLD,
	EvidenceEnums.TrustLevel.HIGH: Color.GREEN,
	EvidenceEnums.TrustLevel.VARIABLE: Color.YELLOW,
	EvidenceEnums.TrustLevel.LOW: Color.ORANGE,
	EvidenceEnums.TrustLevel.SABOTAGE_RISK: Color.RED,
}

## Tooltip explanations for each trust level
const TRUST_TOOLTIPS: Dictionary = {
	EvidenceEnums.TrustLevel.UNFALSIFIABLE: "Cannot be fabricated - behavioral ground truth",
	EvidenceEnums.TrustLevel.HIGH: "Equipment-verified, difficult to fake",
	EvidenceEnums.TrustLevel.VARIABLE: "Requires cooperation, verify with second reading",
	EvidenceEnums.TrustLevel.LOW: "Easy to misreport, cross-reference recommended",
	EvidenceEnums.TrustLevel.SABOTAGE_RISK: "Cultist can directly contaminate",
}

# --- Exported Properties ---

@export var evidence_type: EvidenceEnums.EvidenceType

# --- State ---

var _collected: bool = false
var _quality: EvidenceEnums.ReadingQuality = EvidenceEnums.ReadingQuality.STRONG

# --- Nodes ---

@onready var _background: Panel = %Background
@onready var _border: Panel = %Border
@onready var _icon: TextureRect = %Icon
@onready var _label: Label = %EvidenceName
@onready var _status_label: Label = %StatusLabel
@onready var _button: Button = %SlotButton


func _ready() -> void:
	custom_minimum_size = SLOT_SIZE
	_update_display()
	_setup_trust_styling()
	if _button:
		_button.pressed.connect(_on_button_pressed)


func setup(type: EvidenceEnums.EvidenceType) -> void:
	evidence_type = type
	_update_display()
	_setup_trust_styling()


func set_collected(is_collected: bool, quality := EvidenceEnums.ReadingQuality.STRONG) -> void:
	_collected = is_collected
	_quality = quality
	_update_status_display()
	_update_icon()


func is_collected() -> bool:
	return _collected


func get_evidence_type() -> EvidenceEnums.EvidenceType:
	return evidence_type


func _update_display() -> void:
	if not is_node_ready():
		return

	if _label:
		_label.text = EvidenceEnums.get_evidence_name(evidence_type)

	_update_status_display()
	_update_icon()


func _update_status_display() -> void:
	if not _status_label:
		return

	if _collected:
		var quality_str := EvidenceEnums.get_quality_name(_quality)
		_status_label.text = quality_str
		_status_label.modulate = Color.WHITE
	else:
		_status_label.text = "---"
		_status_label.modulate = Color(1.0, 1.0, 1.0, 0.5)


func _update_icon() -> void:
	if not _icon:
		return

	# Placeholder: use colored rectangle based on category
	var category := EvidenceEnums.get_category(evidence_type)
	var color := _get_category_color(category)

	if _collected:
		# Strong readings: solid icon, weak readings: semi-transparent
		var alpha := 1.0 if _quality == EvidenceEnums.ReadingQuality.STRONG else 0.6
		_icon.modulate = Color(color.r, color.g, color.b, alpha)
	else:
		_icon.modulate = color * Color(1.0, 1.0, 1.0, 0.3)


func _get_category_color(category: EvidenceEnums.EvidenceCategory) -> Color:
	match category:
		EvidenceEnums.EvidenceCategory.EQUIPMENT_DERIVED:
			return Color.CORNFLOWER_BLUE
		EvidenceEnums.EvidenceCategory.READILY_APPARENT:
			return Color.LIGHT_GREEN
		EvidenceEnums.EvidenceCategory.TRIGGERED_TEST:
			return Color.GOLD
		EvidenceEnums.EvidenceCategory.BEHAVIOR_BASED:
			return Color.INDIAN_RED
		_:
			return Color.WHITE


func _on_button_pressed() -> void:
	slot_pressed.emit(evidence_type)


func _setup_trust_styling() -> void:
	if not is_node_ready():
		return

	var trust_level := EvidenceEnums.get_trust_level(evidence_type)
	var trust_color: Color = TRUST_COLORS.get(trust_level, Color.WHITE)
	var tooltip_text: String = TRUST_TOOLTIPS.get(trust_level, "")

	# Apply border color via StyleBox
	if _border:
		var style := StyleBoxFlat.new()
		style.bg_color = Color.TRANSPARENT
		style.border_color = trust_color
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		_border.add_theme_stylebox_override("panel", style)

	# Set tooltip on the button (captures hover over entire slot)
	if _button:
		var trust_name := EvidenceEnums.get_trust_name(trust_level)
		_button.tooltip_text = "[%s] %s" % [trust_name, tooltip_text]


func _get_trust_level() -> EvidenceEnums.TrustLevel:
	return EvidenceEnums.get_trust_level(evidence_type)
