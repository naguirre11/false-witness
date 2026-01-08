class_name EvidenceBoard
extends Control
## Evidence Board UI panel displaying all collected evidence.
##
## Shows evidence organized by category (Equipment-Derived, Readily-Apparent,
## Triggered Test, Behavior-Based). Accessible via hotkey during investigation
## and always visible during deliberation.
##
## Future tickets add:
## - Trust level visualization (FW-035b)
## - Collector attribution (FW-035c)
## - Entity possibility matrix (FW-035d)

# --- Constants ---

const EVIDENCE_SLOT_SCENE := "res://scenes/ui/evidence_slot.tscn"

# Evidence types organized by category for display order
const EVIDENCE_BY_CATEGORY: Dictionary = {
	EvidenceEnums.EvidenceCategory.EQUIPMENT_DERIVED:
	[
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		EvidenceEnums.EvidenceType.FREEZING_TEMPERATURE,
		EvidenceEnums.EvidenceType.PRISM_READING,
		EvidenceEnums.EvidenceType.AURA_PATTERN,
	],
	EvidenceEnums.EvidenceCategory.READILY_APPARENT:
	[
		EvidenceEnums.EvidenceType.VISUAL_MANIFESTATION,
		EvidenceEnums.EvidenceType.PHYSICAL_INTERACTION,
	],
	EvidenceEnums.EvidenceCategory.TRIGGERED_TEST:
	[
		EvidenceEnums.EvidenceType.GHOST_WRITING,
	],
	EvidenceEnums.EvidenceCategory.BEHAVIOR_BASED:
	[
		EvidenceEnums.EvidenceType.HUNT_BEHAVIOR,
	],
}

# --- State ---

var _evidence_slots: Dictionary = {}  # EvidenceType -> EvidenceSlot
var _is_visible: bool = false
var _force_visible: bool = false  # True during deliberation

# --- Nodes ---

@onready var _panel: PanelContainer = %BoardPanel
@onready var _title: Label = %TitleLabel
@onready var _categories_container: VBoxContainer = %CategoriesContainer


func _ready() -> void:
	_build_evidence_grid()
	_connect_signals()
	_sync_with_manager()
	hide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_evidence_board") and not _force_visible:
		toggle_visibility()


func _connect_signals() -> void:
	var evidence_manager := _get_evidence_manager()
	if evidence_manager:
		evidence_manager.evidence_collected.connect(_on_evidence_collected)
		evidence_manager.evidence_cleared.connect(_on_evidence_cleared)
		evidence_manager.evidence_verification_changed.connect(_on_verification_changed)

	var event_bus := _get_event_bus()
	if event_bus and event_bus.has_signal("game_state_changed"):
		event_bus.game_state_changed.connect(_on_game_state_changed)


func _build_evidence_grid() -> void:
	if not _categories_container:
		push_error("[EvidenceBoard] CategoriesContainer not found")
		return

	# Clear existing children
	for child in _categories_container.get_children():
		child.queue_free()

	var slot_scene: PackedScene = load(EVIDENCE_SLOT_SCENE)
	if not slot_scene:
		push_error("[EvidenceBoard] Failed to load evidence slot scene")
		return

	# Build category rows
	for category: int in EVIDENCE_BY_CATEGORY:
		var evidence_types: Array = EVIDENCE_BY_CATEGORY[category]
		var row := _create_category_row(category, evidence_types, slot_scene)
		_categories_container.add_child(row)


func _create_category_row(
	category: EvidenceEnums.EvidenceCategory, evidence_types: Array, slot_scene: PackedScene
) -> Control:
	var row := VBoxContainer.new()

	# Category header
	var header := Label.new()
	header.text = EvidenceEnums.get_category_name(category)
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	row.add_child(header)

	# Slots container
	var slots_container := HBoxContainer.new()
	slots_container.add_theme_constant_override("separation", 8)
	row.add_child(slots_container)

	# Create slots for each evidence type
	for evidence_type: int in evidence_types:
		var slot: EvidenceSlot = slot_scene.instantiate()
		slot.setup(evidence_type as EvidenceEnums.EvidenceType)
		slot.slot_pressed.connect(_on_slot_pressed)
		slots_container.add_child(slot)
		_evidence_slots[evidence_type] = slot

	# Separator
	var separator := HSeparator.new()
	separator.add_theme_constant_override("separation", 8)
	row.add_child(separator)

	return row


func _sync_with_manager() -> void:
	var evidence_manager := _get_evidence_manager()
	if not evidence_manager:
		return

	# Sync all currently collected evidence
	var all_evidence: Array = evidence_manager.get_all_evidence()
	for evidence: Evidence in all_evidence:
		_update_slot_for_evidence(evidence)


func _update_slot_for_evidence(evidence: Evidence) -> void:
	var slot: EvidenceSlot = _evidence_slots.get(evidence.type)
	if slot:
		slot.set_collected(true, evidence.quality, evidence)


func _clear_all_slots() -> void:
	for slot: EvidenceSlot in _evidence_slots.values():
		slot.set_collected(false)


# --- Visibility ---


func toggle_visibility() -> void:
	if _is_visible:
		hide_board()
	else:
		show_board()


func show_board() -> void:
	_is_visible = true
	show()


func hide_board() -> void:
	if _force_visible:
		return

	_is_visible = false
	hide()


func set_force_visible(forced: bool) -> void:
	_force_visible = forced
	if forced:
		show_board()
	else:
		hide_board()


func is_board_visible() -> bool:
	return _is_visible


# --- Signal Handlers ---


func _on_evidence_collected(evidence: Evidence) -> void:
	_update_slot_for_evidence(evidence)


func _on_evidence_cleared() -> void:
	_clear_all_slots()


func _on_game_state_changed(old_state: int, new_state: int) -> void:
	const DELIBERATION := 5  # GameManager.GameState.DELIBERATION

	if new_state == DELIBERATION:
		set_force_visible(true)
	elif old_state == DELIBERATION:
		set_force_visible(false)


func _on_slot_pressed(evidence_type: EvidenceEnums.EvidenceType) -> void:
	# Log slot press for debugging (collector details shown via tooltip)
	print("[EvidenceBoard] Slot pressed: %s" % EvidenceEnums.get_evidence_name(evidence_type))


func _on_verification_changed(evidence: Evidence) -> void:
	# Re-update the slot to reflect new verification state
	_update_slot_for_evidence(evidence)


# --- Helpers ---


func _get_evidence_manager() -> Node:
	if has_node("/root/EvidenceManager"):
		return get_node("/root/EvidenceManager")
	return null


func _get_event_bus() -> Node:
	if has_node("/root/EventBus"):
		return get_node("/root/EventBus")
	return null
