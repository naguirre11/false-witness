extends GutTest
## Unit tests for MatchManager win condition logic.


# --- Test: MatchResult Creation ---


func test_match_result_creates_with_defaults() -> void:
	var result := MatchResult.new()
	assert_eq(result.winning_team, MatchResult.WinningTeam.INVESTIGATORS)
	assert_eq(result.win_condition, MatchResult.WinCondition.CORRECT_IDENTIFICATION)


func test_match_result_did_investigators_win_true() -> void:
	var result := MatchResult.new()
	result.winning_team = MatchResult.WinningTeam.INVESTIGATORS
	assert_true(result.did_investigators_win())
	assert_false(result.did_cultist_win())


func test_match_result_did_cultist_win_true() -> void:
	var result := MatchResult.new()
	result.winning_team = MatchResult.WinningTeam.CULTIST
	assert_true(result.did_cultist_win())
	assert_false(result.did_investigators_win())


func test_match_result_to_dict_contains_required_fields() -> void:
	var result := MatchResult.new()
	result.winning_team = MatchResult.WinningTeam.INVESTIGATORS
	result.win_condition = MatchResult.WinCondition.CORRECT_IDENTIFICATION
	result.entity_type = "Specter"
	result.cultist_id = 12345
	result.cultist_username = "TestCultist"

	var dict := result.to_dict()

	assert_true(dict.has("winning_team"))
	assert_true(dict.has("win_condition"))
	assert_true(dict.has("entity_type"))
	assert_true(dict.has("cultist_id"))
	assert_true(dict.has("cultist_username"))


func test_match_result_from_dict_restores_values() -> void:
	var data := {
		"winning_team": MatchResult.WinningTeam.CULTIST,
		"win_condition": MatchResult.WinCondition.INCORRECT_IDENTIFICATION,
		"entity_type": "Phantom",
		"cultist_id": 67890,
		"cultist_username": "SneakyCultist",
		"match_duration": 450.0
	}

	var result := MatchResult.from_dict(data)

	assert_eq(result.winning_team, MatchResult.WinningTeam.CULTIST)
	assert_eq(result.win_condition, MatchResult.WinCondition.INCORRECT_IDENTIFICATION)
	assert_eq(result.entity_type, "Phantom")
	assert_eq(result.cultist_id, 67890)
	assert_eq(result.cultist_username, "SneakyCultist")
	assert_eq(result.match_duration, 450.0)


# --- Test: Win Condition Text ---


func test_get_win_condition_text_correct_identification() -> void:
	var result := MatchResult.new()
	result.win_condition = MatchResult.WinCondition.CORRECT_IDENTIFICATION
	var text := result.get_win_condition_text()
	assert_true(text.contains("correctly identified"))


func test_get_win_condition_text_incorrect_identification() -> void:
	var result := MatchResult.new()
	result.win_condition = MatchResult.WinCondition.INCORRECT_IDENTIFICATION
	var text := result.get_win_condition_text()
	assert_true(text.contains("wrong entity"))


func test_get_win_condition_text_cultist_voted_out() -> void:
	var result := MatchResult.new()
	result.win_condition = MatchResult.WinCondition.CULTIST_VOTED_OUT
	var text := result.get_win_condition_text()
	assert_true(text.contains("Cultist") and text.contains("voted out"))


func test_get_win_condition_text_innocent_voted_out() -> void:
	var result := MatchResult.new()
	result.win_condition = MatchResult.WinCondition.INNOCENT_VOTED_OUT
	var text := result.get_win_condition_text()
	assert_true(text.contains("innocent"))


func test_get_win_condition_text_time_expired() -> void:
	var result := MatchResult.new()
	result.win_condition = MatchResult.WinCondition.TIME_EXPIRED
	var text := result.get_win_condition_text()
	assert_true(text.contains("Time") or text.contains("time"))


# --- Test: Voting Threshold Calculations ---


func test_majority_threshold_for_four_players() -> void:
	# 4 players: majority = 4/2 + 1 = 3
	var manager := _create_evidence_manager_double()
	manager.set_alive_player_count(4)
	assert_eq(manager.get_majority_threshold(), 3)


func test_majority_threshold_for_five_players() -> void:
	# 5 players: majority = 5/2 + 1 = 3 (integer division)
	var manager := _create_evidence_manager_double()
	manager.set_alive_player_count(5)
	assert_eq(manager.get_majority_threshold(), 3)


func test_majority_threshold_for_six_players() -> void:
	# 6 players: majority = 6/2 + 1 = 4
	var manager := _create_evidence_manager_double()
	manager.set_alive_player_count(6)
	assert_eq(manager.get_majority_threshold(), 4)


func test_majority_threshold_for_three_players() -> void:
	# 3 players: majority = 3/2 + 1 = 2
	var manager := _create_evidence_manager_double()
	manager.set_alive_player_count(3)
	assert_eq(manager.get_majority_threshold(), 2)


func test_majority_threshold_minimum_is_one() -> void:
	# Even with 1 player, threshold should be at least 1
	var manager := _create_evidence_manager_double()
	manager.set_alive_player_count(1)
	assert_eq(manager.get_majority_threshold(), 1)


func test_vote_counts_empty_by_default() -> void:
	var manager := _create_evidence_manager_double()
	var counts := manager.get_vote_counts()
	assert_eq(counts["approve"], 0)
	assert_eq(counts["reject"], 0)


# --- Test: Win Condition Enum Values ---


func test_win_condition_correct_identification_value() -> void:
	assert_eq(MatchResult.WinCondition.CORRECT_IDENTIFICATION, 0)


func test_win_condition_incorrect_identification_value() -> void:
	assert_eq(MatchResult.WinCondition.INCORRECT_IDENTIFICATION, 1)


func test_win_condition_cultist_voted_out_value() -> void:
	assert_eq(MatchResult.WinCondition.CULTIST_VOTED_OUT, 2)


func test_win_condition_innocent_voted_out_value() -> void:
	assert_eq(MatchResult.WinCondition.INNOCENT_VOTED_OUT, 3)


func test_win_condition_time_expired_value() -> void:
	assert_eq(MatchResult.WinCondition.TIME_EXPIRED, 4)


func test_winning_team_investigators_value() -> void:
	assert_eq(MatchResult.WinningTeam.INVESTIGATORS, 0)


func test_winning_team_cultist_value() -> void:
	assert_eq(MatchResult.WinningTeam.CULTIST, 1)


# --- Helper Functions ---


## Creates an EvidenceManager-like double for testing voting methods.
class EvidenceManagerDouble extends Node:
	var _alive_player_count: int = 4
	var _pending_identification: Dictionary = {}

	func set_alive_player_count(count: int) -> void:
		_alive_player_count = maxi(1, count)

	func get_majority_threshold() -> int:
		return (_alive_player_count / 2) + 1

	func get_vote_counts() -> Dictionary:
		if _pending_identification.is_empty():
			return {"approve": 0, "reject": 0}
		var votes: Dictionary = _pending_identification.get("votes", {})
		var approve_count: int = 0
		var reject_count: int = 0
		for vote_value: bool in votes.values():
			if vote_value:
				approve_count += 1
			else:
				reject_count += 1
		return {"approve": approve_count, "reject": reject_count}


func _create_evidence_manager_double() -> EvidenceManagerDouble:
	var node := EvidenceManagerDouble.new()
	add_child_autofree(node)
	return node
