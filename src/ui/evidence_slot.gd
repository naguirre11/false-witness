class_name EvidenceSlot
extends Control
## Displays a single evidence type on the evidence board.
##
## Shows the evidence name, icon (placeholder), collection status,
## verification state, and collector attribution.

signal slot_pressed(evidence_type: EvidenceEnums.EvidenceType)

# --- Constants ---

const SLOT_SIZE := Vector2(120, 100)

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

## Verification state icons (Unicode symbols)
const VERIFICATION_ICONS: Dictionary = {
	EvidenceEnums.VerificationState.UNVERIFIED: "\u2713",  # Single checkmark
	EvidenceEnums.VerificationState.VERIFIED: "\u2713\u2713",  # Double checkmark
	EvidenceEnums.VerificationState.CONTESTED: "\u26A0",  # Warning/exclamation
}

## Verification state colors
const VERIFICATION_COLORS: Dictionary = {
	EvidenceEnums.VerificationState.UNVERIFIED: Color(0.7, 0.7, 0.7),  # Gray
	EvidenceEnums.VerificationState.VERIFIED: Color.GREEN,
	EvidenceEnums.VerificationState.CONTESTED: Color.ORANGE,
}

## Player colors for collector attribution (indexed by peer_id % 8)
const PLAYER_COLORS: Array[Color] = [
	Color.CYAN,
	Color.MAGENTA,
	Color.LIME,
	Color.YELLOW,
	Color.CORAL,
	Color.DEEP_SKY_BLUE,
	Color.HOT_PINK,
	Color.SPRING_GREEN,
]

# --- Exported Properties ---

@export var evidence_type: EvidenceEnums.EvidenceType

# --- State ---

var _collected: bool = false
var _quality: EvidenceEnums.ReadingQuality = EvidenceEnums.ReadingQuality.STRONG
var _evidence: Evidence = null  ## Full evidence data for attribution

# --- Nodes ---

@onready var _background: Panel = %Background
@onready var _border: Panel = %Border
@onready var _icon: TextureRect = %Icon
@onready var _label: Label = %EvidenceName
@onready var _status_label: Label = %StatusLabel
@onready var _button: Button = %SlotButton
@onready var _verification_icon: Label = %VerificationIcon
@onready var _collector_row: HBoxContainer = %CollectorRow


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


func set_collected(
	is_collected: bool, quality := EvidenceEnums.ReadingQuality.STRONG, evidence: Evidence = null
) -> void:
	_collected = is_collected
	_quality = quality
	_evidence = evidence
	_update_status_display()
	_update_icon()
	_update_verification_display()
	_update_collector_display()
	_update_tooltip()


func is_collected() -> bool:
	return _collected


func get_evidence_type() -> EvidenceEnums.EvidenceType:
	return evidence_type


func get_evidence() -> Evidence:
	return _evidence


func get_verification_state() -> EvidenceEnums.VerificationState:
	if _evidence:
		return _evidence.verification_state
	return EvidenceEnums.VerificationState.UNVERIFIED


func _update_display() -> void:
	if not is_node_ready():
		return

	if _label:
		_label.text = EvidenceEnums.get_evidence_name(evidence_type)

	_update_status_display()
	_update_icon()
	_update_verification_display()
	_update_collector_display()


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


func _update_verification_display() -> void:
	if not _verification_icon:
		return

	if not _collected or not _evidence:
		_verification_icon.text = ""
		_verification_icon.modulate = Color.TRANSPARENT
		return

	var state := _evidence.verification_state
	_verification_icon.text = VERIFICATION_ICONS.get(state, "")
	_verification_icon.modulate = VERIFICATION_COLORS.get(state, Color.WHITE)


func _update_collector_display() -> void:
	if not _collector_row:
		return

	# Clear existing collector indicators
	for child in _collector_row.get_children():
		child.queue_free()

	if not _collected or not _evidence:
		return

	# Add primary collector
	var primary_indicator := _create_collector_indicator(_evidence.collector_id)
	_collector_row.add_child(primary_indicator)

	# Add secondary collector for cooperative evidence
	if _evidence.secondary_collector_id > 0:
		var secondary_indicator := _create_collector_indicator(_evidence.secondary_collector_id)
		_collector_row.add_child(secondary_indicator)


func _create_collector_indicator(peer_id: int) -> Control:
	var indicator := Panel.new()
	indicator.custom_minimum_size = Vector2(16, 16)

	# Create a simple colored circle for the player
	var style := StyleBoxFlat.new()
	style.bg_color = _get_player_color(peer_id)
	style.set_corner_radius_all(8)  # Make it circular
	indicator.add_theme_stylebox_override("panel", style)

	# Add player initial as label
	var label := Label.new()
	label.text = _get_player_initial(peer_id)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color.BLACK)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchors_preset = Control.PRESET_FULL_RECT
	indicator.add_child(label)

	return indicator


func _get_player_color(peer_id: int) -> Color:
	# Map peer_id to one of the predefined colors
	var color_index: int = peer_id % PLAYER_COLORS.size()
	return PLAYER_COLORS[color_index]


func _get_player_initial(peer_id: int) -> String:
	# Use "P" + last digit of peer_id as placeholder
	# In a real implementation, this would query PlayerManager for the player name
	return "P%d" % (peer_id % 10)


func _get_player_name(peer_id: int) -> String:
	# Placeholder - would query PlayerManager in full implementation
	return "Player %d" % peer_id


func _update_tooltip() -> void:
	if not _button:
		return

	var trust_level := EvidenceEnums.get_trust_level(evidence_type)
	var trust_name := EvidenceEnums.get_trust_name(trust_level)
	var trust_text: String = TRUST_TOOLTIPS.get(trust_level, "")

	var tooltip_parts: Array[String] = []
	tooltip_parts.append("[%s] %s" % [trust_name, trust_text])

	if _collected and _evidence:
		# Add verification state
		var verif_name := EvidenceEnums.get_verification_name(_evidence.verification_state)
		tooltip_parts.append("Status: %s" % verif_name)

		# Add collector info
		var collector_name := _get_player_name(_evidence.collector_id)
		tooltip_parts.append("Collected by: %s" % collector_name)

		# Add secondary collector for cooperative evidence
		if _evidence.secondary_collector_id > 0:
			var secondary_name := _get_player_name(_evidence.secondary_collector_id)
			tooltip_parts.append("Assisted by: %s" % secondary_name)

		# Add timestamp (format as MM:SS since game start)
		var time_str := _format_timestamp(_evidence.timestamp)
		tooltip_parts.append("Time: %s" % time_str)

		# Add location (simplified coordinates)
		var loc_str := _format_location(_evidence.location)
		tooltip_parts.append("Location: %s" % loc_str)

	_button.tooltip_text = "\n".join(tooltip_parts)


func _format_timestamp(timestamp: float) -> String:
	# Format as MM:SS
	var minutes: int = int(timestamp) / 60
	var seconds: int = int(timestamp) % 60
	return "%02d:%02d" % [minutes, seconds]


func _format_location(location: Vector3) -> String:
	# Simplified location display
	return "(%.0f, %.0f, %.0f)" % [location.x, location.y, location.z]


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

	# Apply border color via StyleBox
	if _border:
		var style := StyleBoxFlat.new()
		style.bg_color = Color.TRANSPARENT
		style.border_color = trust_color
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		_border.add_theme_stylebox_override("panel", style)

	# Update tooltip with trust info
	_update_tooltip()


func _get_trust_level() -> EvidenceEnums.TrustLevel:
	return EvidenceEnums.get_trust_level(evidence_type)


## Sets the keyboard focus visual indicator.
func set_keyboard_focused(is_focused: bool) -> void:
	if not _background:
		return

	if is_focused:
		# Add a bright focus border
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.3, 0.4, 0.8)
		style.border_color = Color.CYAN
		style.set_border_width_all(3)
		style.set_corner_radius_all(4)
		_background.add_theme_stylebox_override("panel", style)
	else:
		# Restore default background
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.15, 0.15, 0.8)
		style.set_corner_radius_all(4)
		_background.add_theme_stylebox_override("panel", style)
