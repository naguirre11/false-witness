extends GutTest
## Tests for EvidenceSlot UI component.

var _slot: EvidenceSlot
var _slot_scene: PackedScene


func before_all() -> void:
	_slot_scene = load("res://scenes/ui/evidence_slot.tscn")


func before_each() -> void:
	_slot = _slot_scene.instantiate()
	add_child_autofree(_slot)
	await get_tree().process_frame


func test_slot_has_required_nodes() -> void:
	assert_not_null(_slot.get_node_or_null("%Background"), "Should have Background")
	assert_not_null(_slot.get_node_or_null("%Icon"), "Should have Icon")
	assert_not_null(_slot.get_node_or_null("%EvidenceName"), "Should have EvidenceName")
	assert_not_null(_slot.get_node_or_null("%StatusLabel"), "Should have StatusLabel")
	assert_not_null(_slot.get_node_or_null("%SlotButton"), "Should have SlotButton")


func test_slot_has_minimum_size() -> void:
	assert_eq(_slot.custom_minimum_size, Vector2(120, 100))


func test_setup_sets_evidence_type() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	assert_eq(_slot.evidence_type, EvidenceEnums.EvidenceType.EMF_SIGNATURE)


func test_setup_updates_label() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.FREEZING_TEMPERATURE)
	await get_tree().process_frame
	var label: Label = _slot.get_node("%EvidenceName")
	assert_eq(label.text, "Freezing Temperature")


func test_default_not_collected() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	assert_false(_slot.is_collected())


func test_set_collected_true() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	_slot.set_collected(true)
	assert_true(_slot.is_collected())


func test_set_collected_false() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	_slot.set_collected(true)
	_slot.set_collected(false)
	assert_false(_slot.is_collected())


func test_collected_updates_status_label_strong() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	_slot.set_collected(true, EvidenceEnums.ReadingQuality.STRONG)
	await get_tree().process_frame
	var label: Label = _slot.get_node("%StatusLabel")
	assert_eq(label.text, "Strong")


func test_collected_updates_status_label_weak() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	_slot.set_collected(true, EvidenceEnums.ReadingQuality.WEAK)
	await get_tree().process_frame
	var label: Label = _slot.get_node("%StatusLabel")
	assert_eq(label.text, "Weak")


func test_not_collected_shows_placeholder() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	await get_tree().process_frame
	var label: Label = _slot.get_node("%StatusLabel")
	assert_eq(label.text, "---")


func test_get_evidence_type() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.GHOST_WRITING)
	assert_eq(_slot.get_evidence_type(), EvidenceEnums.EvidenceType.GHOST_WRITING)


func test_slot_pressed_signal_emitted() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.HUNT_BEHAVIOR)
	watch_signals(_slot)

	var button: Button = _slot.get_node("%SlotButton")
	button.pressed.emit()
	await get_tree().process_frame

	assert_signal_emitted(_slot, "slot_pressed")


func test_slot_pressed_signal_has_type() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.VISUAL_MANIFESTATION)
	# Use dict to capture by reference (primitives captured by value in lambdas)
	var state := {"received": -1}

	_slot.slot_pressed.connect(func(t: EvidenceEnums.EvidenceType) -> void: state["received"] = t)

	var button: Button = _slot.get_node("%SlotButton")
	button.pressed.emit()
	await get_tree().process_frame

	assert_eq(state["received"], EvidenceEnums.EvidenceType.VISUAL_MANIFESTATION)


func test_all_evidence_types_have_names() -> void:
	for evidence_type: int in EvidenceEnums.EvidenceType.values():
		_slot.setup(evidence_type as EvidenceEnums.EvidenceType)
		await get_tree().process_frame
		var label: Label = _slot.get_node("%EvidenceName")
		assert_ne(label.text, "Unknown", "Type %d should have a name" % evidence_type)
		assert_ne(label.text, "", "Type %d should have a non-empty name" % evidence_type)


# --- Trust Level Visualization Tests (FW-035b) ---


func test_slot_has_border_node() -> void:
	assert_not_null(_slot.get_node_or_null("%Border"), "Should have Border panel")


func test_border_has_trust_color_unfalsifiable() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.HUNT_BEHAVIOR)
	await get_tree().process_frame
	var border: Panel = _slot.get_node("%Border")
	var style: StyleBox = border.get_theme_stylebox("panel")
	assert_not_null(style, "Border should have style")
	if style is StyleBoxFlat:
		assert_eq(style.border_color, Color.GOLD, "UNFALSIFIABLE should be gold")


func test_border_has_trust_color_high() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	await get_tree().process_frame
	var border: Panel = _slot.get_node("%Border")
	var style: StyleBox = border.get_theme_stylebox("panel")
	assert_not_null(style)
	if style is StyleBoxFlat:
		assert_eq(style.border_color, Color.GREEN, "HIGH trust should be green")


func test_border_has_trust_color_variable() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.AURA_PATTERN)
	await get_tree().process_frame
	var border: Panel = _slot.get_node("%Border")
	var style: StyleBox = border.get_theme_stylebox("panel")
	assert_not_null(style)
	if style is StyleBoxFlat:
		assert_eq(style.border_color, Color.YELLOW, "VARIABLE trust should be yellow")


func test_border_has_trust_color_low() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.PRISM_READING)
	await get_tree().process_frame
	var border: Panel = _slot.get_node("%Border")
	var style: StyleBox = border.get_theme_stylebox("panel")
	assert_not_null(style)
	if style is StyleBoxFlat:
		assert_eq(style.border_color, Color.ORANGE, "LOW trust should be orange")


func test_border_has_trust_color_sabotage_risk() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.GHOST_WRITING)
	await get_tree().process_frame
	var border: Panel = _slot.get_node("%Border")
	var style: StyleBox = border.get_theme_stylebox("panel")
	assert_not_null(style)
	if style is StyleBoxFlat:
		assert_eq(style.border_color, Color.RED, "SABOTAGE_RISK should be red")


func test_tooltip_set_on_button() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	await get_tree().process_frame
	var button: Button = _slot.get_node("%SlotButton")
	assert_ne(button.tooltip_text, "", "Button should have tooltip")


func test_tooltip_contains_trust_name() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	await get_tree().process_frame
	var button: Button = _slot.get_node("%SlotButton")
	assert_true(button.tooltip_text.contains("High Trust"), "Tooltip should contain trust name")


func test_tooltip_contains_explanation() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	await get_tree().process_frame
	var button: Button = _slot.get_node("%SlotButton")
	assert_true(
		button.tooltip_text.contains("Equipment-verified"), "Tooltip should contain explanation"
	)


func test_strong_reading_full_alpha() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	_slot.set_collected(true, EvidenceEnums.ReadingQuality.STRONG)
	await get_tree().process_frame
	var icon: TextureRect = _slot.get_node("%Icon")
	assert_eq(icon.modulate.a, 1.0, "Strong reading should have full alpha")


func test_weak_reading_reduced_alpha() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	_slot.set_collected(true, EvidenceEnums.ReadingQuality.WEAK)
	await get_tree().process_frame
	var icon: TextureRect = _slot.get_node("%Icon")
	assert_almost_eq(icon.modulate.a, 0.6, 0.01, "Weak reading should have 0.6 alpha")


# --- Collector Attribution & Verification Tests (FW-035c) ---


func test_slot_has_verification_icon_node() -> void:
	assert_not_null(_slot.get_node_or_null("%VerificationIcon"), "Should have VerificationIcon")


func test_slot_has_collector_row_node() -> void:
	assert_not_null(_slot.get_node_or_null("%CollectorRow"), "Should have CollectorRow")


func test_verification_icon_empty_when_not_collected() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	await get_tree().process_frame
	var icon: Label = _slot.get_node("%VerificationIcon")
	assert_eq(icon.text, "", "Verification icon should be empty when not collected")


func test_verification_icon_shows_checkmark_for_unverified() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,  # collector_id
		Vector3.ZERO,
		EvidenceEnums.ReadingQuality.STRONG
	)
	_slot.set_collected(true, EvidenceEnums.ReadingQuality.STRONG, evidence)
	await get_tree().process_frame
	var icon: Label = _slot.get_node("%VerificationIcon")
	assert_eq(icon.text, "\u2713", "Should show single checkmark for unverified")


func test_verification_icon_shows_double_checkmark_for_verified() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO,
		EvidenceEnums.ReadingQuality.STRONG
	)
	evidence.verify()
	_slot.set_collected(true, EvidenceEnums.ReadingQuality.STRONG, evidence)
	await get_tree().process_frame
	var icon: Label = _slot.get_node("%VerificationIcon")
	assert_eq(icon.text, "\u2713\u2713", "Should show double checkmark for verified")


func test_verification_icon_shows_warning_for_contested() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO,
		EvidenceEnums.ReadingQuality.STRONG
	)
	evidence.contest()
	_slot.set_collected(true, EvidenceEnums.ReadingQuality.STRONG, evidence)
	await get_tree().process_frame
	var icon: Label = _slot.get_node("%VerificationIcon")
	assert_eq(icon.text, "\u26A0", "Should show warning for contested")


func test_verification_icon_green_for_verified() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO,
		EvidenceEnums.ReadingQuality.STRONG
	)
	evidence.verify()
	_slot.set_collected(true, EvidenceEnums.ReadingQuality.STRONG, evidence)
	await get_tree().process_frame
	var icon: Label = _slot.get_node("%VerificationIcon")
	assert_eq(icon.modulate, Color.GREEN, "Verified should be green")


func test_verification_icon_orange_for_contested() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO,
		EvidenceEnums.ReadingQuality.STRONG
	)
	evidence.contest()
	_slot.set_collected(true, EvidenceEnums.ReadingQuality.STRONG, evidence)
	await get_tree().process_frame
	var icon: Label = _slot.get_node("%VerificationIcon")
	assert_eq(icon.modulate, Color.ORANGE, "Contested should be orange")


func test_collector_row_empty_when_not_collected() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	await get_tree().process_frame
	var row: HBoxContainer = _slot.get_node("%CollectorRow")
	assert_eq(row.get_child_count(), 0, "Collector row should be empty when not collected")


func test_collector_row_shows_one_collector() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		123,  # collector_id
		Vector3.ZERO,
		EvidenceEnums.ReadingQuality.STRONG
	)
	_slot.set_collected(true, EvidenceEnums.ReadingQuality.STRONG, evidence)
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame for queue_free to process
	var row: HBoxContainer = _slot.get_node("%CollectorRow")
	assert_eq(row.get_child_count(), 1, "Should show one collector")


func test_collector_row_shows_two_collectors_for_cooperative() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.PRISM_READING)
	var evidence := Evidence.create_cooperative(
		EvidenceEnums.EvidenceType.PRISM_READING,
		1,  # primary
		2,  # secondary
		Vector3.ZERO,
		EvidenceEnums.ReadingQuality.STRONG
	)
	_slot.set_collected(true, EvidenceEnums.ReadingQuality.STRONG, evidence)
	await get_tree().process_frame
	await get_tree().process_frame
	var row: HBoxContainer = _slot.get_node("%CollectorRow")
	assert_eq(row.get_child_count(), 2, "Should show two collectors for cooperative")


func test_get_evidence_returns_evidence_object() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO,
		EvidenceEnums.ReadingQuality.STRONG
	)
	_slot.set_collected(true, EvidenceEnums.ReadingQuality.STRONG, evidence)
	assert_eq(_slot.get_evidence(), evidence, "Should return the evidence object")


func test_get_evidence_returns_null_when_not_collected() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	assert_null(_slot.get_evidence(), "Should return null when not collected")


func test_get_verification_state_returns_unverified_default() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	assert_eq(
		_slot.get_verification_state(),
		EvidenceEnums.VerificationState.UNVERIFIED,
		"Default should be UNVERIFIED"
	)


func test_get_verification_state_returns_evidence_state() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO,
		EvidenceEnums.ReadingQuality.STRONG
	)
	evidence.verify()
	_slot.set_collected(true, EvidenceEnums.ReadingQuality.STRONG, evidence)
	assert_eq(
		_slot.get_verification_state(),
		EvidenceEnums.VerificationState.VERIFIED,
		"Should return VERIFIED"
	)


func test_tooltip_contains_collector_when_collected() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		42,
		Vector3.ZERO,
		EvidenceEnums.ReadingQuality.STRONG
	)
	_slot.set_collected(true, EvidenceEnums.ReadingQuality.STRONG, evidence)
	await get_tree().process_frame
	var button: Button = _slot.get_node("%SlotButton")
	assert_true(button.tooltip_text.contains("Collected by"), "Tooltip should show collector info")


func test_tooltip_contains_timestamp_when_collected() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO,
		EvidenceEnums.ReadingQuality.STRONG
	)
	_slot.set_collected(true, EvidenceEnums.ReadingQuality.STRONG, evidence)
	await get_tree().process_frame
	var button: Button = _slot.get_node("%SlotButton")
	assert_true(button.tooltip_text.contains("Time:"), "Tooltip should show timestamp")


func test_tooltip_contains_location_when_collected() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3(10, 5, 20),
		EvidenceEnums.ReadingQuality.STRONG
	)
	_slot.set_collected(true, EvidenceEnums.ReadingQuality.STRONG, evidence)
	await get_tree().process_frame
	var button: Button = _slot.get_node("%SlotButton")
	assert_true(button.tooltip_text.contains("Location:"), "Tooltip should show location")


func test_tooltip_contains_verification_status_when_collected() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO,
		EvidenceEnums.ReadingQuality.STRONG
	)
	_slot.set_collected(true, EvidenceEnums.ReadingQuality.STRONG, evidence)
	await get_tree().process_frame
	var button: Button = _slot.get_node("%SlotButton")
	assert_true(button.tooltip_text.contains("Status:"), "Tooltip should show verification status")


func test_tooltip_shows_secondary_collector_for_cooperative() -> void:
	_slot.setup(EvidenceEnums.EvidenceType.AURA_PATTERN)
	var evidence := Evidence.create_cooperative(
		EvidenceEnums.EvidenceType.AURA_PATTERN,
		1,
		2,
		Vector3.ZERO,
		EvidenceEnums.ReadingQuality.STRONG
	)
	_slot.set_collected(true, EvidenceEnums.ReadingQuality.STRONG, evidence)
	await get_tree().process_frame
	var button: Button = _slot.get_node("%SlotButton")
	assert_true(
		button.tooltip_text.contains("Assisted by"), "Tooltip should show secondary collector"
	)
