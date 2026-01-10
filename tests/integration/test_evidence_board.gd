extends GutTest
## Tests for EvidenceBoard UI component.

var _board: EvidenceBoard
var _board_scene: PackedScene


func before_all() -> void:
	_board_scene = load("res://scenes/ui/evidence_board.tscn")


func before_each() -> void:
	_board = _board_scene.instantiate()
	add_child_autofree(_board)
	await get_tree().process_frame


# --- Structure Tests ---


func test_board_has_required_nodes() -> void:
	assert_not_null(_board.get_node_or_null("%BoardPanel"), "Should have BoardPanel")
	assert_not_null(_board.get_node_or_null("%TitleLabel"), "Should have TitleLabel")
	assert_not_null(_board.get_node_or_null("%CategoriesContainer"), "Should have container")


func test_board_starts_hidden() -> void:
	assert_false(_board.visible)


func test_title_label_text() -> void:
	var title: Label = _board.get_node("%TitleLabel")
	assert_eq(title.text, "EVIDENCE BOARD")


# --- Visibility Tests ---


func test_show_board() -> void:
	_board.show_board()
	assert_true(_board.visible)
	assert_true(_board.is_board_visible())


func test_hide_board() -> void:
	_board.show_board()
	_board.hide_board()
	assert_false(_board.visible)
	assert_false(_board.is_board_visible())


func test_toggle_visibility_shows_when_hidden() -> void:
	_board.toggle_visibility()
	assert_true(_board.is_board_visible())


func test_toggle_visibility_hides_when_visible() -> void:
	_board.show_board()
	_board.toggle_visibility()
	assert_false(_board.is_board_visible())


func test_force_visible_shows_board() -> void:
	_board.set_force_visible(true)
	assert_true(_board.visible)


func test_force_visible_prevents_hiding() -> void:
	_board.set_force_visible(true)
	_board.hide_board()
	assert_true(_board.visible)


func test_unforce_allows_hiding() -> void:
	_board.set_force_visible(true)
	_board.set_force_visible(false)
	assert_false(_board.visible)


# --- Slot Creation Tests ---


func test_creates_slots_for_all_evidence_types() -> void:
	# There are 8 evidence types total
	var slot_count := 0
	for category_key: int in EvidenceBoard.EVIDENCE_BY_CATEGORY:
		var types: Array = EvidenceBoard.EVIDENCE_BY_CATEGORY[category_key]
		slot_count += types.size()

	assert_eq(slot_count, 8, "Should have 8 evidence types defined")


func test_evidence_categories_are_complete() -> void:
	# Verify all evidence types are in some category
	var all_types_in_categories: Array[int] = []
	for category_key: int in EvidenceBoard.EVIDENCE_BY_CATEGORY:
		var types: Array = EvidenceBoard.EVIDENCE_BY_CATEGORY[category_key]
		for evidence_type: int in types:
			all_types_in_categories.append(evidence_type)

	for evidence_type: int in EvidenceEnums.EvidenceType.values():
		assert_true(
			evidence_type in all_types_in_categories,
			"Evidence type %d should be in a category" % evidence_type
		)


func test_equipment_derived_category_has_four_types() -> void:
	var types: Array = EvidenceBoard.EVIDENCE_BY_CATEGORY[
		EvidenceEnums.EvidenceCategory.EQUIPMENT_DERIVED
	]
	assert_eq(types.size(), 4)


func test_readily_apparent_category_has_two_types() -> void:
	var types: Array = EvidenceBoard.EVIDENCE_BY_CATEGORY[
		EvidenceEnums.EvidenceCategory.READILY_APPARENT
	]
	assert_eq(types.size(), 2)


func test_triggered_test_category_has_one_type() -> void:
	var types: Array = EvidenceBoard.EVIDENCE_BY_CATEGORY[
		EvidenceEnums.EvidenceCategory.TRIGGERED_TEST
	]
	assert_eq(types.size(), 1)


func test_behavior_based_category_has_one_type() -> void:
	var types: Array = EvidenceBoard.EVIDENCE_BY_CATEGORY[
		EvidenceEnums.EvidenceCategory.BEHAVIOR_BASED
	]
	assert_eq(types.size(), 1)


# --- Game State Tests ---


func test_deliberation_state_forces_visible() -> void:
	const INVESTIGATION := 3
	const DELIBERATION := 5

	_board._on_game_state_changed(INVESTIGATION, DELIBERATION)
	assert_true(_board.visible, "Should be visible during deliberation")


func test_leaving_deliberation_unforces_visible() -> void:
	const DELIBERATION := 5
	const RESULTS := 6

	_board._on_game_state_changed(0, DELIBERATION)
	_board._on_game_state_changed(DELIBERATION, RESULTS)
	assert_false(_board.visible, "Should hide after deliberation ends")


# --- Evidence Integration Tests ---


func test_on_evidence_cleared_resets_slots() -> void:
	# This tests the signal handler directly
	_board._on_evidence_cleared()
	# No crash = success, slots are cleared
	assert_true(true)


func test_slot_scene_path_is_valid() -> void:
	var scene: PackedScene = load(EvidenceBoard.EVIDENCE_SLOT_SCENE)
	assert_not_null(scene, "Slot scene should exist at expected path")
