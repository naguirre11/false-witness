class_name EvidenceDetailPopup
extends Control
## Popup showing detailed information about a collected evidence item.
##
## Displayed when clicking an evidence slot on the evidence board.
## Shows: type, collector(s), timestamp, location, reading quality,
## trust level, verification state, and any conflicts.

signal closed
signal verify_requested(evidence: Evidence)

# --- Constants ---

## Verification requirement messages by trust level.
const VERIFICATION_REQUIREMENTS: Dictionary = {
	EvidenceEnums.TrustLevel.UNFALSIFIABLE: "Auto-verified with multiple witnesses",
	EvidenceEnums.TrustLevel.HIGH: "Need another player to corroborate",
	EvidenceEnums.TrustLevel.VARIABLE: "Need third player to watch the reading",
	EvidenceEnums.TrustLevel.LOW: "Need different operator for second reading",
	EvidenceEnums.TrustLevel.SABOTAGE_RISK: "Need witnesses to setup AND result",
}

# --- State ---

var _evidence: Evidence = null
var _evidence_type: EvidenceEnums.EvidenceType
# Verification UI elements (created dynamically)
var _verify_container: VBoxContainer = null
var _verify_button: Button = null
var _verify_requirement_label: Label = null

# --- Nodes ---

@onready var _dimmer: ColorRect = %Dimmer
@onready var _panel: PanelContainer = %Panel
@onready var _title_label: Label = %TitleLabel
@onready var _type_label: Label = %TypeLabel
@onready var _collector_label: Label = %CollectorLabel
@onready var _timestamp_label: Label = %TimestampLabel
@onready var _location_label: Label = %LocationLabel
@onready var _quality_label: Label = %QualityLabel
@onready var _trust_label: Label = %TrustLabel
@onready var _verification_label: Label = %VerificationLabel
@onready var _conflict_container: VBoxContainer = %ConflictContainer
@onready var _conflict_label: Label = %ConflictLabel
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	hide()
	if _close_button:
		_close_button.pressed.connect(_on_close_pressed)
	if _dimmer:
		_dimmer.gui_input.connect(_on_dimmer_input)
	_create_verification_ui()


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_close_popup()
		get_viewport().set_input_as_handled()


## Show the popup with evidence details.
func show_evidence(evidence_type: EvidenceEnums.EvidenceType, evidence: Evidence = null) -> void:
	_evidence_type = evidence_type
	_evidence = evidence
	_update_display()
	show()


func _close_popup() -> void:
	hide()
	closed.emit()


func _update_display() -> void:
	if not is_node_ready():
		return

	# Evidence type name
	var type_name := EvidenceEnums.get_evidence_name(_evidence_type)
	if _title_label:
		_title_label.text = type_name

	# Category
	var category := EvidenceEnums.get_category(_evidence_type)
	var category_name := EvidenceEnums.get_category_name(category)
	if _type_label:
		_type_label.text = "Category: %s" % category_name

	# Trust level
	var trust := EvidenceEnums.get_trust_level(_evidence_type)
	var trust_name := EvidenceEnums.get_trust_name(trust)
	var trust_desc := _get_trust_description(trust)
	if _trust_label:
		_trust_label.text = "Trust: %s\n%s" % [trust_name, trust_desc]
		_trust_label.modulate = _get_trust_color(trust)

	if _evidence:
		_update_collected_display()
	else:
		_update_uncollected_display()


func _update_collected_display() -> void:
	# Collector(s)
	if _collector_label:
		var collector_text := "Collected by: %s" % _get_player_name(_evidence.collector_id)
		if _evidence.secondary_collector_id > 0:
			collector_text += " + %s" % _get_player_name(_evidence.secondary_collector_id)
		_collector_label.text = collector_text
		_collector_label.show()

	# Timestamp with staleness
	if _timestamp_label:
		var time_str := _format_timestamp(_evidence.timestamp)
		var staleness_info := _get_staleness_info()
		_timestamp_label.text = "Time: %s (%s)" % [time_str, staleness_info.description]
		_timestamp_label.modulate = staleness_info.color
		_timestamp_label.show()

	# Location
	if _location_label:
		var loc_str := _format_location(_evidence.location)
		_location_label.text = "Location: %s" % loc_str
		_location_label.show()

	# Quality
	if _quality_label:
		var quality_name := EvidenceEnums.get_quality_name(_evidence.quality)
		_quality_label.text = "Quality: %s" % quality_name
		if _evidence.quality == EvidenceEnums.ReadingQuality.WEAK:
			_quality_label.modulate = Color(1.0, 0.8, 0.4)  # Orange for weak
		else:
			_quality_label.modulate = Color.WHITE
		_quality_label.show()

	# Verification state with verifier info
	if _verification_label:
		var verif_name := EvidenceEnums.get_verification_name(_evidence.verification_state)
		var verif_desc := _get_verification_description(_evidence.verification_state)
		var verif_text := "Status: %s\n%s" % [verif_name, verif_desc]

		# Add verifier info if verified
		if _evidence.is_verified() and _evidence.verifier_id != 0:
			var verifier_name := _get_player_name(_evidence.verifier_id)
			var verif_time := _format_timestamp(_evidence.verification_timestamp)
			verif_text += "\nVerified by: %s at %s" % [verifier_name, verif_time]

			# Show additional verifiers if any
			var history := _evidence.get_verification_history()
			if history.size() > 1:
				verif_text += "\n(%d total verifications)" % history.size()

		_verification_label.text = verif_text
		_verification_label.modulate = _get_verification_color(_evidence.verification_state)
		_verification_label.show()

	# Conflicts
	_update_conflict_display()

	# Verification helper UI
	_update_verification_ui()


func _update_uncollected_display() -> void:
	if _collector_label:
		_collector_label.text = "Not collected"
		_collector_label.show()

	if _timestamp_label:
		_timestamp_label.hide()

	if _location_label:
		_location_label.hide()

	if _quality_label:
		_quality_label.hide()

	if _verification_label:
		_verification_label.text = "Status: Not collected"
		_verification_label.modulate = Color(0.5, 0.5, 0.5)
		_verification_label.show()

	if _conflict_container:
		_conflict_container.hide()

	if _verify_container:
		_verify_container.hide()


func _update_conflict_display() -> void:
	if not _conflict_container or not _conflict_label:
		return

	if _evidence and _evidence.is_contested():
		_conflict_container.show()
		# Get conflict description from evidence metadata
		var conflict_desc: String = _evidence.get_verification_meta("conflict_description", "")
		if conflict_desc.is_empty():
			conflict_desc = "This evidence has been contested."
		_conflict_label.text = conflict_desc
	else:
		_conflict_container.hide()


func _get_trust_description(trust: EvidenceEnums.TrustLevel) -> String:
	match trust:
		EvidenceEnums.TrustLevel.UNFALSIFIABLE:
			return "All players can verify - cannot be faked"
		EvidenceEnums.TrustLevel.HIGH:
			return "Shared display - difficult to lie about"
		EvidenceEnums.TrustLevel.VARIABLE:
			return "One party can lie - verify with third player"
		EvidenceEnums.TrustLevel.LOW:
			return "Both operators can lie - cross-reference with behavior"
		EvidenceEnums.TrustLevel.SABOTAGE_RISK:
			return "Can be tampered with - buddy system recommended"
		_:
			return ""


func _get_verification_description(state: EvidenceEnums.VerificationState) -> String:
	match state:
		EvidenceEnums.VerificationState.UNVERIFIED:
			return "No second opinion yet"
		EvidenceEnums.VerificationState.VERIFIED:
			return "Corroborated by another player"
		EvidenceEnums.VerificationState.CONTESTED:
			return "Conflicting reports exist"
		_:
			return ""


func _get_trust_color(trust: EvidenceEnums.TrustLevel) -> Color:
	match trust:
		EvidenceEnums.TrustLevel.UNFALSIFIABLE:
			return Color.GOLD
		EvidenceEnums.TrustLevel.HIGH:
			return Color.GREEN
		EvidenceEnums.TrustLevel.VARIABLE:
			return Color.YELLOW
		EvidenceEnums.TrustLevel.LOW:
			return Color.ORANGE
		EvidenceEnums.TrustLevel.SABOTAGE_RISK:
			return Color.RED
		_:
			return Color.WHITE


func _get_verification_color(state: EvidenceEnums.VerificationState) -> Color:
	match state:
		EvidenceEnums.VerificationState.UNVERIFIED:
			return Color(0.7, 0.7, 0.7)
		EvidenceEnums.VerificationState.VERIFIED:
			return Color.GREEN
		EvidenceEnums.VerificationState.CONTESTED:
			return Color.ORANGE
		_:
			return Color.WHITE


func _get_player_name(peer_id: int) -> String:
	# Placeholder - would query PlayerManager in full implementation
	return "Player %d" % peer_id


func _format_timestamp(timestamp: float) -> String:
	var minutes: int = int(timestamp) / 60
	var seconds: int = int(timestamp) % 60
	return "%02d:%02d" % [minutes, seconds]


func _format_location(location: Vector3) -> String:
	return "(%.0f, %.0f, %.0f)" % [location.x, location.y, location.z]


func _get_staleness_info() -> Dictionary:
	var verification_manager := _get_verification_manager()
	if not verification_manager or not _evidence:
		return {"description": "Unknown", "color": Color.WHITE}

	var staleness_level: int = verification_manager.get_evidence_staleness(_evidence)
	var description: String = verification_manager.get_staleness_description(staleness_level)
	var color: Color = verification_manager.get_staleness_color(staleness_level)

	return {"description": description, "color": color}


func _get_verification_manager() -> Node:
	if has_node("/root/VerificationManager"):
		return get_node("/root/VerificationManager")
	return null


func _on_close_pressed() -> void:
	_close_popup()


func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_close_popup()


# --- Verification UI ---


func _create_verification_ui() -> void:
	# Find the content container (parent of close button)
	if not _close_button:
		return

	var content_parent := _close_button.get_parent()
	if not content_parent:
		return

	# Create verification container
	_verify_container = VBoxContainer.new()
	_verify_container.name = "VerifyContainer"

	# Add separator
	var separator := HSeparator.new()
	_verify_container.add_child(separator)

	# Add requirement label
	_verify_requirement_label = Label.new()
	_verify_requirement_label.name = "RequirementLabel"
	_verify_requirement_label.add_theme_font_size_override("font_size", 12)
	_verify_requirement_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	_verify_container.add_child(_verify_requirement_label)

	# Add verify button
	_verify_button = Button.new()
	_verify_button.name = "VerifyButton"
	_verify_button.text = "Verify Evidence"
	_verify_button.pressed.connect(_on_verify_pressed)
	_verify_container.add_child(_verify_button)

	# Insert before close button
	var close_idx := content_parent.get_child_count() - 1  # Assume close is last
	content_parent.add_child(_verify_container)
	content_parent.move_child(_verify_container, close_idx)

	_verify_container.hide()


func _update_verification_ui() -> void:
	if not _verify_container:
		return

	# Hide if no evidence or already verified
	if not _evidence:
		_verify_container.hide()
		return

	if _evidence.is_verified():
		_verify_container.hide()
		return

	# Show verification helper
	_verify_container.show()

	# Get trust level and requirement message
	var trust := _evidence.trust_level
	var requirement: String = VERIFICATION_REQUIREMENTS.get(trust, "Verification needed")

	# Check staleness
	var verification_manager := _get_verification_manager()
	if verification_manager:
		var staleness: int = verification_manager.get_evidence_staleness(_evidence)
		# VerificationManager.StalenessLevel.VERY_STALE = 2
		if staleness == 2:
			_verify_requirement_label.text = "Too old to verify (>180s)"
			_verify_requirement_label.modulate = Color.RED
			_verify_button.disabled = true
			_verify_button.text = "Cannot Verify"
			return

	_verify_requirement_label.text = requirement
	_verify_requirement_label.modulate = Color.WHITE
	_verify_button.disabled = false
	_verify_button.text = "Verify Evidence"


func _on_verify_pressed() -> void:
	if _evidence:
		verify_requested.emit(_evidence)
		_close_popup()
