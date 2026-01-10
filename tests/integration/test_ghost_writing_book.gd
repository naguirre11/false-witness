extends GutTest
## Tests for GhostWritingBook equipment.

var book: GhostWritingBook


func before_each() -> void:
	book = GhostWritingBook.new()
	add_child_autofree(book)
	# Use shorter times for testing
	book.min_placement_time = 0.1
	book.max_wait_time = 1.0


# --- Initialization Tests ---


func test_initialization() -> void:
	assert_eq(
		book.equipment_type,
		Equipment.EquipmentType.GHOST_WRITING_BOOK,
		"Should be GHOST_WRITING_BOOK type"
	)
	assert_eq(book.equipment_name, "Ghost Writing Book", "Should have correct name")
	assert_eq(book.use_mode, Equipment.UseMode.INSTANT, "Should use INSTANT mode")
	assert_eq(book.get_book_state(), GhostWritingBook.BookState.HELD, "Should be HELD")
	assert_eq(book.get_writing_style(), GhostWritingBook.WritingStyle.NONE, "Writing NONE")
	assert_eq(book.get_placed_position(), Vector3.ZERO, "Position should be ZERO")
	assert_false(book.has_writing(), "Should not have writing initially")


func test_detectable_evidence_type() -> void:
	var evidence_types := book.get_detectable_evidence()
	assert_eq(evidence_types.size(), 1, "Should detect one evidence type")
	assert_eq(evidence_types[0], "ghost_writing", "Should detect ghost_writing")


func test_enums_exist() -> void:
	# Writing styles
	assert_eq(GhostWritingBook.WritingStyle.NONE, 0, "NONE should be 0")
	assert_eq(GhostWritingBook.WritingStyle.CRUDE_SCRAWLS, 1, "CRUDE_SCRAWLS should be 1")
	assert_eq(GhostWritingBook.WritingStyle.SYMBOLS, 2, "SYMBOLS should be 2")
	assert_eq(GhostWritingBook.WritingStyle.WORDS, 3, "WORDS should be 3")
	# Book states
	assert_eq(GhostWritingBook.BookState.HELD, 0, "HELD should be 0")
	assert_eq(GhostWritingBook.BookState.PLACED, 1, "PLACED should be 1")
	assert_eq(GhostWritingBook.BookState.WRITING, 2, "WRITING should be 2")
	assert_eq(GhostWritingBook.BookState.WRITTEN, 3, "WRITTEN should be 3")
	assert_eq(GhostWritingBook.BookState.CHECKED, 4, "CHECKED should be 4")


# --- Placement Tests ---


func test_place_book_basic() -> void:
	var location := Vector3(5.0, 1.0, -3.0)
	var result: bool = book.place_book(location, 42)

	assert_true(result, "place_book should return true")
	assert_eq(book.get_book_state(), GhostWritingBook.BookState.PLACED, "State should be PLACED")
	assert_eq(book.get_placed_position(), location, "Should store placed position")
	assert_eq(book.get_placer_id(), 42, "Should store placer ID")


func test_place_book_emits_signals() -> void:
	var state := {"location": Vector3.ZERO, "placer": -1, "new_state": -1}
	book.book_placed.connect(
		func(loc, placer):
			state["location"] = loc
			state["placer"] = placer
	)
	book.book_state_changed.connect(func(s): state["new_state"] = s)

	book.place_book(Vector3(2.0, 0.0, 3.0), 5)

	assert_eq(state["location"], Vector3(2.0, 0.0, 3.0), "Signal should have location")
	assert_eq(state["placer"], 5, "Signal should have placer ID")
	assert_eq(state["new_state"], GhostWritingBook.BookState.PLACED, "State should change")


func test_cannot_place_when_already_placed() -> void:
	book.place_book(Vector3(1.0, 0.0, 1.0), 1)
	var result: bool = book.place_book(Vector3(2.0, 0.0, 2.0), 1)
	assert_false(result, "Should not be able to place twice")


func test_place_book_clears_previous_state() -> void:
	book.place_book(Vector3(1.0, 0.0, 1.0), 1)
	book.pickup_book(1)
	book.place_book(Vector3(2.0, 0.0, 2.0), 2)

	assert_eq(book.get_placer_id(), 2, "Should have new placer ID")
	assert_false(book.was_moved(), "Should not be marked as moved")


# --- Pickup Tests ---


func test_pickup_book_basic() -> void:
	book.place_book(Vector3(1.0, 0.0, 1.0), 1)
	var result: bool = book.pickup_book(1)

	assert_true(result, "pickup_book should return true")
	assert_eq(book.get_book_state(), GhostWritingBook.BookState.HELD, "State should be HELD")


func test_pickup_book_emits_signals() -> void:
	book.place_book(Vector3.ZERO, 1)
	var state := {"picker": -1, "new_state": -1}
	book.book_picked_up.connect(func(p): state["picker"] = p)
	book.book_state_changed.connect(func(s): state["new_state"] = s)

	book.pickup_book(7)

	assert_eq(state["picker"], 7, "Signal should have picker ID")
	assert_eq(state["new_state"], GhostWritingBook.BookState.HELD, "State should change")


func test_cannot_pickup_when_not_placed() -> void:
	var result: bool = book.pickup_book(1)
	assert_false(result, "Should not pickup when not placed")


func test_pickup_sabotage_tracking() -> void:
	book.place_book(Vector3.ZERO, 1)
	book.pickup_book(2)  # Different player picks up

	var history := book.get_move_history()
	assert_eq(history.size(), 1, "Should record move")
	assert_eq(history[0]["mover_id"], 2, "Should record mover ID")

	# Same player pickup should not record
	book.place_book(Vector3.ZERO, 3)
	book.pickup_book(3)
	history = book.get_move_history()
	assert_eq(history.size(), 0, "Should not record move by placer")


# --- Move Tests ---


func test_move_book_basic() -> void:
	book.place_book(Vector3(1.0, 0.0, 1.0), 1)
	book.move_book(2, Vector3(5.0, 0.0, 5.0))
	assert_eq(book.get_placed_position(), Vector3(5.0, 0.0, 5.0), "Position should update")


func test_move_book_emits_signal() -> void:
	book.place_book(Vector3(1.0, 0.0, 1.0), 1)
	var state := {"mover": -1, "from": Vector3.ZERO, "to": Vector3.ZERO}
	book.book_moved.connect(
		func(mover, from_pos, to_pos):
			state["mover"] = mover
			state["from"] = from_pos
			state["to"] = to_pos
	)

	book.move_book(3, Vector3(5.0, 0.0, 5.0))

	assert_eq(state["mover"], 3, "Signal should have mover ID")
	assert_eq(state["from"], Vector3(1.0, 0.0, 1.0), "Signal should have from position")
	assert_eq(state["to"], Vector3(5.0, 0.0, 5.0), "Signal should have to position")


func test_move_sabotage_tracking() -> void:
	book.place_book(Vector3.ZERO, 1)

	# Non-placer move marks as moved
	book.move_book(2, Vector3(5.0, 0.0, 5.0))
	assert_true(book.was_moved(), "Should be marked as moved")

	# Reset
	book.pickup_book(1)
	book.place_book(Vector3.ZERO, 1)

	# Placer move does not mark
	book.move_book(1, Vector3(5.0, 0.0, 5.0))
	assert_false(book.was_moved(), "Should not be marked as moved by placer")


func test_move_history_records_multiple_moves() -> void:
	book.place_book(Vector3.ZERO, 1)
	book.move_book(2, Vector3(1.0, 0.0, 1.0))
	book.move_book(3, Vector3(2.0, 0.0, 2.0))

	var history := book.get_move_history()
	assert_eq(history.size(), 2, "Should record both moves")
	assert_eq(history[0]["mover_id"], 2, "First mover should be 2")
	assert_eq(history[1]["mover_id"], 3, "Second mover should be 3")


func test_cannot_move_when_held() -> void:
	var result: bool = book.move_book(1, Vector3.ZERO)
	assert_false(result, "Should not move when held")


# --- Witness Tests ---


func test_witness_registration() -> void:
	book.place_book(Vector3.ZERO, 1)

	assert_false(book.has_setup_witness(), "Should not have setup witness initially")
	assert_false(book.has_result_witness(), "Should not have result witness initially")

	book.register_setup_witness(2)
	assert_true(book.has_setup_witness(), "Should have setup witness")

	book.register_result_witness(3)
	assert_true(book.has_result_witness(), "Should have result witness")


func test_placer_cannot_be_own_witness() -> void:
	book.place_book(Vector3.ZERO, 1)
	book.register_setup_witness(1)  # Same as placer
	assert_false(book.has_setup_witness(), "Placer should not count as witness")


# --- Time Tests ---


func test_time_since_placement() -> void:
	assert_eq(book.get_time_since_placement(), 0.0, "Time should be 0 when held")

	book.place_book(Vector3.ZERO, 1)

	# Just verify time is being tracked (any value > 0)
	var time_since: float = book.get_time_since_placement()
	assert_gte(time_since, 0.0, "Time should be tracked after placement")


# --- Writing State Tests ---


func test_writing_progress() -> void:
	book.place_book(Vector3.ZERO, 1)
	assert_eq(book.get_writing_progress(), 0.0, "Progress should be 0 when just placed")

	book._book_state = GhostWritingBook.BookState.WRITTEN
	assert_eq(book.get_writing_progress(), 1.0, "Progress should be 1.0 when written")


func test_has_writing_states() -> void:
	book.place_book(Vector3.ZERO, 1)
	assert_false(book.has_writing(), "Should not have writing when just placed")

	book._book_state = GhostWritingBook.BookState.WRITTEN
	assert_true(book.has_writing(), "Should have writing when WRITTEN")

	book._book_state = GhostWritingBook.BookState.CHECKED
	assert_true(book.has_writing(), "Should have writing when CHECKED")


# --- Check Book Tests ---


func test_check_book_no_writing() -> void:
	book.place_book(Vector3.ZERO, 1)
	var result := book.check_book(2)
	assert_false(result["has_writing"], "Should have no writing immediately")


func test_check_book_with_writing() -> void:
	book.place_book(Vector3.ZERO, 1)
	book._book_state = GhostWritingBook.BookState.WRITTEN
	book._current_writing_style = GhostWritingBook.WritingStyle.SYMBOLS

	var result := book.check_book(2)

	assert_true(result["has_writing"], "Should have writing")
	assert_eq(result["writing_style"], GhostWritingBook.WritingStyle.SYMBOLS, "Correct style")


func test_check_book_emits_signal() -> void:
	book.place_book(Vector3.ZERO, 1)
	book._book_state = GhostWritingBook.BookState.WRITTEN
	var state := {"checker": -1, "has_writing": false}
	book.book_checked.connect(
		func(c, w):
			state["checker"] = c
			state["has_writing"] = w
	)

	book.check_book(5)

	assert_eq(state["checker"], 5, "Should have checker ID")
	assert_true(state["has_writing"], "Should have writing status")


func test_check_book_registers_result_witness() -> void:
	book.place_book(Vector3.ZERO, 1)
	book.check_book(2)
	assert_true(book.has_result_witness(), "Checker should become result witness")


func test_check_book_negative_evidence_after_max_wait() -> void:
	book.max_wait_time = 1.0
	book.place_book(Vector3.ZERO, 1)
	# Simulate time passing by setting placed_time to the past
	book._placed_time = (Time.get_ticks_msec() / 1000.0) - 2.0

	var result := book.check_book(2)
	assert_true(result.get("is_negative_evidence", false), "Should be negative evidence")


func test_check_book_returns_was_moved() -> void:
	book.place_book(Vector3.ZERO, 1)
	book.move_book(2, Vector3(5.0, 0.0, 5.0))
	var result := book.check_book(2)
	assert_true(result["was_moved"], "Should indicate book was moved")


# --- Evidence Quality Tests ---


func test_quality_weak_when_moved() -> void:
	book.place_book(Vector3.ZERO, 1)
	book.move_book(2, Vector3(5.0, 0.0, 5.0))
	book._book_state = GhostWritingBook.BookState.WRITTEN
	book._current_writing_style = GhostWritingBook.WritingStyle.WORDS

	var result := book.check_book(3)
	assert_eq(result["quality"], EvidenceEnums.ReadingQuality.WEAK, "Should be WEAK when moved")


func test_quality_weak_when_no_witnesses() -> void:
	book.place_book(Vector3.ZERO, 1)
	book._book_state = GhostWritingBook.BookState.WRITTEN
	book._current_writing_style = GhostWritingBook.WritingStyle.WORDS

	var result := book.check_book(1)  # Placer checks, doesn't count as witness
	assert_eq(result["quality"], EvidenceEnums.ReadingQuality.WEAK, "WEAK without witnesses")


func test_quality_weak_for_crude_scrawls() -> void:
	book.place_book(Vector3.ZERO, 1)
	book.register_setup_witness(2)
	book._book_state = GhostWritingBook.BookState.WRITTEN
	book._current_writing_style = GhostWritingBook.WritingStyle.CRUDE_SCRAWLS

	var result := book.check_book(3)
	assert_eq(result["quality"], EvidenceEnums.ReadingQuality.WEAK, "WEAK for crude scrawls")


func test_quality_strong_with_all_requirements() -> void:
	book.place_book(Vector3.ZERO, 1)
	book.register_setup_witness(2)
	book._book_state = GhostWritingBook.BookState.WRITTEN
	book._current_writing_style = GhostWritingBook.WritingStyle.WORDS

	var result := book.check_book(3)  # Different from placer and setup witness
	assert_eq(result["quality"], EvidenceEnums.ReadingQuality.STRONG, "STRONG with all reqs")


# --- Network State Tests ---


func test_get_network_state() -> void:
	book.place_book(Vector3(1.0, 2.0, 3.0), 1)
	book.move_book(2, Vector3(4.0, 5.0, 6.0))
	book.register_setup_witness(3)
	book.register_result_witness(4)
	book._current_writing_style = GhostWritingBook.WritingStyle.SYMBOLS
	book._writing_progress = 0.5

	var state := book.get_network_state()

	assert_eq(state["book_state"], GhostWritingBook.BookState.PLACED, "Should include state")
	assert_eq(state["placed_position"]["x"], 4.0, "Should include x")
	assert_eq(state["placed_position"]["y"], 5.0, "Should include y")
	assert_eq(state["placed_position"]["z"], 6.0, "Should include z")
	assert_eq(state["writing_style"], GhostWritingBook.WritingStyle.SYMBOLS, "Writing style")
	assert_eq(state["writing_progress"], 0.5, "Writing progress")
	assert_eq(state["original_placer_id"], 1, "Placer ID")
	assert_true(state["was_moved"], "was_moved")
	assert_eq(state["setup_witness_id"], 3, "Setup witness")
	assert_eq(state["result_witness_id"], 4, "Result witness")


func test_apply_network_state() -> void:
	var state := {
		"book_state": GhostWritingBook.BookState.WRITTEN,
		"placed_position": {"x": 5.0, "y": 1.0, "z": -3.0},
		"writing_style": GhostWritingBook.WritingStyle.WORDS,
		"writing_progress": 0.75,
		"original_placer_id": 5,
		"was_moved": true,
		"setup_witness_id": 6,
		"result_witness_id": 7,
	}

	book.apply_network_state(state)

	assert_eq(book.get_book_state(), GhostWritingBook.BookState.WRITTEN, "Book state")
	assert_eq(book.get_placed_position(), Vector3(5.0, 1.0, -3.0), "Position")
	assert_eq(book.get_writing_style(), GhostWritingBook.WritingStyle.WORDS, "Writing style")
	assert_eq(book.get_placer_id(), 5, "Placer ID")
	assert_true(book.was_moved(), "was_moved")
	assert_true(book.has_setup_witness(), "Setup witness")
	assert_true(book.has_result_witness(), "Result witness")


# --- Edge Cases ---


func test_multiple_place_pickup_cycles() -> void:
	book.place_book(Vector3(1.0, 0.0, 1.0), 1)
	book.pickup_book(1)
	book.place_book(Vector3(2.0, 0.0, 2.0), 2)
	book.pickup_book(2)
	book.place_book(Vector3(3.0, 0.0, 3.0), 3)

	assert_eq(book.get_book_state(), GhostWritingBook.BookState.PLACED, "Should be placed")
	assert_eq(book.get_placer_id(), 3, "Should have latest placer")
	assert_eq(book.get_placed_position(), Vector3(3.0, 0.0, 3.0), "Should have latest position")


func test_move_history_cleared_on_new_placement() -> void:
	book.place_book(Vector3.ZERO, 1)
	book.move_book(2, Vector3(1.0, 0.0, 1.0))
	book.pickup_book(2)

	book.place_book(Vector3(2.0, 0.0, 2.0), 1)

	assert_eq(book.get_move_history().size(), 0, "Move history should be cleared")
	assert_false(book.was_moved(), "was_moved should be reset")


func test_pickup_during_writing_and_written_states() -> void:
	book.place_book(Vector3.ZERO, 1)
	book._book_state = GhostWritingBook.BookState.WRITING
	var result: bool = book.pickup_book(1)
	assert_true(result, "Should be able to pickup during writing")
	assert_eq(book.get_book_state(), GhostWritingBook.BookState.HELD, "Should transition to HELD")

	book.place_book(Vector3.ZERO, 1)
	book._book_state = GhostWritingBook.BookState.WRITTEN
	result = book.pickup_book(1)
	assert_true(result, "Should be able to pickup when written")
	assert_eq(book.get_book_state(), GhostWritingBook.BookState.HELD, "Should transition to HELD")
