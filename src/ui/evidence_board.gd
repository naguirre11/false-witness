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

# --- Imports ---

const DesignTokens := preload("res://themes/design_tokens.gd")

# --- Constants ---

const EVIDENCE_SLOT_SCENE := "res://scenes/ui/evidence_slot.tscn"
const EVIDENCE_DETAIL_POPUP_SCENE := "res://scenes/ui/evidence_detail_popup.tscn"

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
var _detail_popup: EvidenceDetailPopup = null
var _focused_slot_index: int = 0  # For keyboard navigation
var _slot_order: Array[int] = []  # Flat list of evidence types in display order

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

	# Keyboard navigation only when board is visible
	if not visible:
		return

	# Check if detail popup is handling input
	if _detail_popup and _detail_popup.visible:
		return

	if event.is_action_pressed("ui_left"):
		_navigate_slots(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_navigate_slots(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_navigate_slots(-4)  # Move up a row (4 slots per row approx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_navigate_slots(4)  # Move down a row
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_select_focused_slot()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		if not _force_visible:
			hide_board()
			get_viewport().set_input_as_handled()


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

	# Clear existing children and state
	for child in _categories_container.get_children():
		child.queue_free()
	_slot_order.clear()

	var slot_scene: PackedScene = load(EVIDENCE_SLOT_SCENE)
	if not slot_scene:
		push_error("[EvidenceBoard] Failed to load evidence slot scene")
		return

	# Build category rows and populate slot order
	for category: int in EVIDENCE_BY_CATEGORY:
		var evidence_types: Array = EVIDENCE_BY_CATEGORY[category]
		var row := _create_category_row(category, evidence_types, slot_scene)
		_categories_container.add_child(row)
		# Add to flat slot order for keyboard navigation
		for evidence_type in evidence_types:
			_slot_order.append(evidence_type)


func _create_category_row(
	category: EvidenceEnums.EvidenceCategory, evidence_types: Array, slot_scene: PackedScene
) -> Control:
	var row := VBoxContainer.new()

	# Category header
	var header := Label.new()
	header.text = EvidenceEnums.get_category_name(category)
	header.add_theme_font_size_override("font_size", DesignTokens.FONT_SIZES.sm)
	header.add_theme_color_override("font_color", DesignTokens.COLORS.text_secondary)
	row.add_child(header)

	# Slots container
	var slots_container := HBoxContainer.new()
	slots_container.add_theme_constant_override("separation", DesignTokens.SPACING.sm)
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
	separator.add_theme_constant_override("separation", DesignTokens.SPACING.sm)
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
	modulate.a = 0.0
	_is_visible = true
	show()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, DesignTokens.ANIMATION.duration_normal)
	_reset_focus()


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
	# Show detail popup for this evidence slot
	_show_detail_popup(evidence_type)


func _on_verification_changed(evidence: Evidence) -> void:
	# Re-update the slot to reflect new verification state
	_update_slot_for_evidence(evidence)


# --- Keyboard Navigation ---


func _navigate_slots(direction: int) -> void:
	if _slot_order.is_empty():
		return

	var old_index := _focused_slot_index
	_focused_slot_index = clampi(
		_focused_slot_index + direction, 0, _slot_order.size() - 1
	)

	if old_index != _focused_slot_index:
		_update_focus_visual(old_index, false)
		_update_focus_visual(_focused_slot_index, true)


func _select_focused_slot() -> void:
	if _focused_slot_index < 0 or _focused_slot_index >= _slot_order.size():
		return

	var evidence_type: int = _slot_order[_focused_slot_index]
	_show_detail_popup(evidence_type as EvidenceEnums.EvidenceType)


func _update_focus_visual(index: int, is_focused: bool) -> void:
	if index < 0 or index >= _slot_order.size():
		return

	var evidence_type: int = _slot_order[index]
	var slot: EvidenceSlot = _evidence_slots.get(evidence_type)
	if slot:
		slot.set_keyboard_focused(is_focused)


func _reset_focus() -> void:
	# Clear focus on all slots
	for evidence_type in _slot_order:
		var slot: EvidenceSlot = _evidence_slots.get(evidence_type)
		if slot:
			slot.set_keyboard_focused(false)
	_focused_slot_index = 0
	if not _slot_order.is_empty():
		_update_focus_visual(0, true)


# --- Detail Popup ---


func _show_detail_popup(evidence_type: EvidenceEnums.EvidenceType) -> void:
	# Create popup if it doesn't exist
	if not _detail_popup:
		var popup_scene: PackedScene = load(EVIDENCE_DETAIL_POPUP_SCENE)
		if not popup_scene:
			push_error("[EvidenceBoard] Failed to load detail popup scene")
			return
		_detail_popup = popup_scene.instantiate()
		add_child(_detail_popup)

	# Get the evidence for this slot (may be null if uncollected)
	var slot: EvidenceSlot = _evidence_slots.get(evidence_type)
	var evidence: Evidence = null
	if slot:
		evidence = slot.get_evidence()

	# Show popup with evidence details
	_detail_popup.show_evidence(evidence_type, evidence)


# --- Helpers ---


func _get_evidence_manager() -> Node:
	if has_node("/root/EvidenceManager"):
		return get_node("/root/EvidenceManager")
	return null


func _get_event_bus() -> Node:
	if has_node("/root/EventBus"):
		return get_node("/root/EventBus")
	return null
