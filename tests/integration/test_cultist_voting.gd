extends GutTest
## Integration tests for Cultist voting system.
##
## Tests emergency vote calling, vote casting, vote tracking,
## majority calculation, and vote outcomes (Cultist discovery, innocent voted).

# --- Test Helpers ---

var _cultist_manager: Node


func before_each() -> void:
	# Create a fresh CultistManager for each test
	var manager_script: GDScript = load("res://src/cultist/cultist_manager.gd")
	_cultist_manager = manager_script.new()
	_cultist_manager.name = "TestCultistManager"
	add_child_autofree(_cultist_manager)

	# Set up as server
	_cultist_manager.set_is_server(true)
	_cultist_manager.reset()


func after_each() -> void:
	_cultist_manager = null


func _setup_match_with_cultist() -> void:
	# Set up a 4-player match with one Cultist
	var player_ids: Array[int] = [1, 2, 3, 4]
	var evidence_types: Array[String] = ["EMF_SIGNATURE"]
	_cultist_manager.seed_rng(12345)  # Deterministic for testing
	_cultist_manager.assign_roles(player_ids, "TestEntity", evidence_types)


# --- Emergency Vote Calling Tests ---


func test_emergency_vote_limit_is_two() -> void:
	assert_eq(
		_cultist_manager.MAX_EMERGENCY_VOTES,
		2,
		"Should allow 2 emergency votes per match"
	)


func test_emergency_votes_remaining_starts_at_two() -> void:
	_setup_match_with_cultist()
	assert_eq(
		_cultist_manager.get_emergency_votes_remaining(),
		2,
		"Should start with 2 emergency votes remaining"
	)


func test_get_emergency_votes_used_starts_at_zero() -> void:
	_setup_match_with_cultist()
	assert_eq(
		_cultist_manager.get_emergency_votes_used(),
		0,
		"Should start with 0 emergency votes used"
	)


func test_can_call_emergency_vote_returns_false_when_not_in_investigation() -> void:
	_setup_match_with_cultist()
	# By default, we're not in INVESTIGATION state
	assert_false(
		_cultist_manager.can_call_emergency_vote(),
		"Should not allow vote when not in INVESTIGATION state"
	)


# --- Vote Tracking Tests ---


func test_voting_in_progress_starts_false() -> void:
	_setup_match_with_cultist()
	assert_false(
		_cultist_manager.is_voting_in_progress(),
		"Voting should not be in progress initially"
	)


func test_start_voting_sets_in_progress() -> void:
	_setup_match_with_cultist()
	var alive_players: Array[int] = [1, 2, 3, 4]
	_cultist_manager.start_voting(alive_players)

	assert_true(
		_cultist_manager.is_voting_in_progress(),
		"Voting should be in progress after start_voting()"
	)


func test_start_voting_clears_previous_votes() -> void:
	_setup_match_with_cultist()
	var alive_players: Array[int] = [1, 2, 3, 4]
	_cultist_manager.start_voting(alive_players)

	var votes: Dictionary = _cultist_manager.get_current_votes()
	assert_eq(votes.size(), 0, "Votes should be cleared when voting starts")


func test_cast_vote_records_vote() -> void:
	_setup_match_with_cultist()
	var alive_players: Array[int] = [1, 2, 3, 4]
	_cultist_manager.start_voting(alive_players)

	# Player 1 votes for player 2
	_cultist_manager.cast_vote(1, 2)

	var votes: Dictionary = _cultist_manager.get_current_votes()
	assert_eq(votes.size(), 1, "Should have one vote recorded")
	assert_eq(votes.get(1), 2, "Player 1 should have voted for player 2")


func test_cast_vote_can_change_vote() -> void:
	_setup_match_with_cultist()
	var alive_players: Array[int] = [1, 2, 3, 4]
	_cultist_manager.start_voting(alive_players)

	# Player 1 votes for player 2, then changes to player 3
	_cultist_manager.cast_vote(1, 2)
	_cultist_manager.cast_vote(1, 3)

	var votes: Dictionary = _cultist_manager.get_current_votes()
	assert_eq(votes.get(1), 3, "Vote should update to new target")


func test_cast_vote_allows_skip() -> void:
	_setup_match_with_cultist()
	var alive_players: Array[int] = [1, 2, 3, 4]
	_cultist_manager.start_voting(alive_players)

	# Player 1 skips (-1)
	_cultist_manager.cast_vote(1, -1)

	var votes: Dictionary = _cultist_manager.get_current_votes()
	assert_eq(votes.get(1), -1, "Skip vote (-1) should be recorded")


func test_voting_timer_starts_at_30_seconds() -> void:
	_setup_match_with_cultist()
	var alive_players: Array[int] = [1, 2, 3, 4]
	_cultist_manager.start_voting(alive_players)

	assert_eq(
		_cultist_manager.get_voting_time_remaining(),
		30.0,
		"Voting timer should start at 30 seconds"
	)


# --- Majority Calculation Tests ---


func test_vote_complete_emits_with_majority() -> void:
	_setup_match_with_cultist()
	var alive_players: Array[int] = [1, 2, 3, 4]
	_cultist_manager.start_voting(alive_players)

	# Track signal
	var signal_state := {"received": false, "target": -1, "is_majority": false}
	_cultist_manager.vote_complete.connect(func(target, is_majority):
		signal_state["received"] = true
		signal_state["target"] = target
		signal_state["is_majority"] = is_majority
	)

	# 3 out of 4 vote for player 2 (>50% majority)
	_cultist_manager.cast_vote(1, 2)
	_cultist_manager.cast_vote(3, 2)
	_cultist_manager.cast_vote(4, 2)
	# When all vote, voting should end automatically
	# But player 2 hasn't voted yet, so we need all 4
	_cultist_manager.cast_vote(2, 1)

	# Need to let the vote_complete processing happen
	await get_tree().process_frame

	assert_true(signal_state["received"], "vote_complete signal should be emitted")
	assert_eq(signal_state["target"], 2, "Majority voted for player 2")
	assert_true(signal_state["is_majority"], "Should be a majority vote")


func test_vote_complete_no_majority_when_tie() -> void:
	_setup_match_with_cultist()
	var alive_players: Array[int] = [1, 2, 3, 4]
	_cultist_manager.start_voting(alive_players)

	# Track signal
	var signal_state := {"received": false, "target": -1, "is_majority": false}
	_cultist_manager.vote_complete.connect(func(target, is_majority):
		signal_state["received"] = true
		signal_state["target"] = target
		signal_state["is_majority"] = is_majority
	)

	# 2 vote for player 2, 2 vote for player 3 (tie)
	_cultist_manager.cast_vote(1, 2)
	_cultist_manager.cast_vote(2, 3)
	_cultist_manager.cast_vote(3, 2)
	_cultist_manager.cast_vote(4, 3)

	await get_tree().process_frame

	assert_true(signal_state["received"], "vote_complete signal should be emitted")
	assert_eq(signal_state["target"], -1, "No target when tie")
	assert_false(signal_state["is_majority"], "Should not be a majority on tie")


func test_vote_complete_no_majority_when_all_skip() -> void:
	_setup_match_with_cultist()
	var alive_players: Array[int] = [1, 2, 3, 4]
	_cultist_manager.start_voting(alive_players)

	# Track signal
	var signal_state := {"received": false, "target": -1, "is_majority": false}
	_cultist_manager.vote_complete.connect(func(target, is_majority):
		signal_state["received"] = true
		signal_state["target"] = target
		signal_state["is_majority"] = is_majority
	)

	# All players skip
	_cultist_manager.cast_vote(1, -1)
	_cultist_manager.cast_vote(2, -1)
	_cultist_manager.cast_vote(3, -1)
	_cultist_manager.cast_vote(4, -1)

	await get_tree().process_frame

	assert_true(signal_state["received"], "vote_complete signal should be emitted")
	assert_eq(signal_state["target"], -1, "No target when all skip")
	assert_false(signal_state["is_majority"], "Should not be a majority when all skip")


# --- Cultist Discovery Tests ---


func test_is_cultist_discovered_starts_false() -> void:
	_setup_match_with_cultist()

	# Get the cultist ID
	var cultist_ids: Array[int] = _cultist_manager.get_cultist_ids()
	assert_gt(cultist_ids.size(), 0, "Should have at least one Cultist")

	var cultist_id: int = cultist_ids[0]
	assert_false(
		_cultist_manager.is_cultist_discovered(cultist_id),
		"Cultist should not be discovered initially"
	)


func test_cultist_discovered_signal_emits_on_correct_vote() -> void:
	_setup_match_with_cultist()
	var cultist_ids: Array[int] = _cultist_manager.get_cultist_ids()
	var cultist_id: int = cultist_ids[0]
	var alive_players: Array[int] = [1, 2, 3, 4]

	# Track signal
	var signal_state := {"received": false, "player_id": -1}
	_cultist_manager.cultist_discovered.connect(func(player_id):
		signal_state["received"] = true
		signal_state["player_id"] = player_id
	)

	_cultist_manager.start_voting(alive_players)

	# Majority votes for the Cultist
	for pid in alive_players:
		if pid != cultist_id:
			_cultist_manager.cast_vote(pid, cultist_id)
		else:
			_cultist_manager.cast_vote(pid, -1)  # Cultist skips

	await get_tree().process_frame

	assert_true(signal_state["received"], "cultist_discovered should be emitted")
	assert_eq(signal_state["player_id"], cultist_id, "Should discover the correct player")


func test_is_cultist_discovered_returns_true_after_discovery() -> void:
	_setup_match_with_cultist()
	var cultist_ids: Array[int] = _cultist_manager.get_cultist_ids()
	var cultist_id: int = cultist_ids[0]
	var alive_players: Array[int] = [1, 2, 3, 4]

	_cultist_manager.start_voting(alive_players)

	# Majority votes for the Cultist
	for pid in alive_players:
		if pid != cultist_id:
			_cultist_manager.cast_vote(pid, cultist_id)
		else:
			_cultist_manager.cast_vote(pid, -1)

	await get_tree().process_frame

	assert_true(
		_cultist_manager.is_cultist_discovered(cultist_id),
		"Cultist should be discovered after correct vote"
	)


# --- Innocent Voted Tests ---


func test_innocent_voted_out_signal_emits_on_wrong_vote() -> void:
	_setup_match_with_cultist()
	var cultist_ids: Array[int] = _cultist_manager.get_cultist_ids()
	var cultist_id: int = cultist_ids[0]

	# Find an innocent player
	var innocent_id := 1
	for pid in [1, 2, 3, 4]:
		if pid != cultist_id:
			innocent_id = pid
			break

	var alive_players: Array[int] = [1, 2, 3, 4]

	# Track signal
	var signal_state := {"received": false, "player_id": -1}
	_cultist_manager.innocent_voted_out.connect(func(player_id):
		signal_state["received"] = true
		signal_state["player_id"] = player_id
	)

	_cultist_manager.start_voting(alive_players)

	# Majority votes for the innocent
	for pid in alive_players:
		if pid != innocent_id:
			_cultist_manager.cast_vote(pid, innocent_id)
		else:
			_cultist_manager.cast_vote(pid, -1)  # Innocent skips

	await get_tree().process_frame

	assert_true(signal_state["received"], "innocent_voted_out should be emitted")
	assert_eq(signal_state["player_id"], innocent_id, "Should identify the innocent player")


func test_cultist_not_discovered_when_innocent_voted() -> void:
	_setup_match_with_cultist()
	var cultist_ids: Array[int] = _cultist_manager.get_cultist_ids()
	var cultist_id: int = cultist_ids[0]

	# Find an innocent player
	var innocent_id := 1
	for pid in [1, 2, 3, 4]:
		if pid != cultist_id:
			innocent_id = pid
			break

	var alive_players: Array[int] = [1, 2, 3, 4]
	_cultist_manager.start_voting(alive_players)

	# Majority votes for the innocent
	for pid in alive_players:
		if pid != innocent_id:
			_cultist_manager.cast_vote(pid, innocent_id)
		else:
			_cultist_manager.cast_vote(pid, -1)

	await get_tree().process_frame

	# Cultist should still be hidden
	assert_false(
		_cultist_manager.is_cultist_discovered(cultist_id),
		"Cultist should remain hidden when innocent is voted"
	)


# --- Discovered Cultist Restrictions Tests ---


func test_discovered_cultist_cannot_use_abilities() -> void:
	_setup_match_with_cultist()
	var cultist_ids: Array[int] = _cultist_manager.get_cultist_ids()
	var cultist_id: int = cultist_ids[0]
	var alive_players: Array[int] = [1, 2, 3, 4]

	# Discover the Cultist via vote
	_cultist_manager.start_voting(alive_players)
	for pid in alive_players:
		if pid != cultist_id:
			_cultist_manager.cast_vote(pid, cultist_id)
		else:
			_cultist_manager.cast_vote(pid, -1)

	await get_tree().process_frame

	# Check can_cultist_use_abilities
	assert_false(
		_cultist_manager.can_cultist_use_abilities(cultist_id),
		"Discovered Cultist should not be able to use abilities"
	)


func test_undiscovered_cultist_can_use_abilities() -> void:
	_setup_match_with_cultist()
	var cultist_ids: Array[int] = _cultist_manager.get_cultist_ids()
	var cultist_id: int = cultist_ids[0]

	assert_true(
		_cultist_manager.can_cultist_use_abilities(cultist_id),
		"Undiscovered Cultist should be able to use abilities"
	)


# --- Discovery Restrictions Tests (FW-053-12) ---


func test_get_discovery_state_returns_hidden_for_undiscovered() -> void:
	_setup_match_with_cultist()
	var cultist_ids: Array[int] = _cultist_manager.get_cultist_ids()
	var cultist_id: int = cultist_ids[0]

	# Check discovery state before voting
	var state: int = _cultist_manager.get_discovery_state(cultist_id)
	# DiscoveryState.HIDDEN = 0
	assert_eq(state, 0, "Undiscovered Cultist should have HIDDEN state")


func test_get_discovery_state_returns_discovered_after_vote() -> void:
	_setup_match_with_cultist()
	var cultist_ids: Array[int] = _cultist_manager.get_cultist_ids()
	var cultist_id: int = cultist_ids[0]
	var alive_players: Array[int] = [1, 2, 3, 4]

	# Discover via vote
	_cultist_manager.start_voting(alive_players)
	for pid in alive_players:
		if pid != cultist_id:
			_cultist_manager.cast_vote(pid, cultist_id)
		else:
			_cultist_manager.cast_vote(pid, -1)

	await get_tree().process_frame

	# Check discovery state after voting
	var state: int = _cultist_manager.get_discovery_state(cultist_id)
	# DiscoveryState.DISCOVERED = 1
	assert_eq(state, 1, "Discovered Cultist should have DISCOVERED state")


func test_can_use_ability_returns_false_when_discovered() -> void:
	_setup_match_with_cultist()
	var cultist_ids: Array[int] = _cultist_manager.get_cultist_ids()
	var cultist_id: int = cultist_ids[0]
	var alive_players: Array[int] = [1, 2, 3, 4]

	# Discover via vote
	_cultist_manager.start_voting(alive_players)
	for pid in alive_players:
		if pid != cultist_id:
			_cultist_manager.cast_vote(pid, cultist_id)
		else:
			_cultist_manager.cast_vote(pid, -1)

	await get_tree().process_frame

	# Test can_use_ability for each ability type
	# CultistEnums.AbilityType.EMF_SPOOF = 1
	assert_false(
		_cultist_manager.can_use_ability(cultist_id, 1),
		"Discovered Cultist should not be able to use EMF_SPOOF"
	)


func test_non_cultist_cannot_use_abilities() -> void:
	_setup_match_with_cultist()
	var cultist_ids: Array[int] = _cultist_manager.get_cultist_ids()

	# Find an innocent player
	var innocent_id := 1
	for pid in [1, 2, 3, 4]:
		if pid not in cultist_ids:
			innocent_id = pid
			break

	assert_false(
		_cultist_manager.can_use_ability(innocent_id, 1),
		"Non-Cultist should not be able to use abilities"
	)


func test_discovered_cultists_list_contains_player_after_vote() -> void:
	_setup_match_with_cultist()
	var cultist_ids: Array[int] = _cultist_manager.get_cultist_ids()
	var cultist_id: int = cultist_ids[0]
	var alive_players: Array[int] = [1, 2, 3, 4]

	# Verify not in discovered list initially
	assert_false(
		_cultist_manager.is_cultist_discovered(cultist_id),
		"Cultist should not be in discovered list initially"
	)

	# Discover via vote
	_cultist_manager.start_voting(alive_players)
	for pid in alive_players:
		if pid != cultist_id:
			_cultist_manager.cast_vote(pid, cultist_id)
		else:
			_cultist_manager.cast_vote(pid, -1)

	await get_tree().process_frame

	# Verify in discovered list after vote
	assert_true(
		_cultist_manager.is_cultist_discovered(cultist_id),
		"Cultist should be in discovered list after correct vote"
	)


func test_cultist_voted_discovered_signal_emitted() -> void:
	_setup_match_with_cultist()
	var cultist_ids: Array[int] = _cultist_manager.get_cultist_ids()
	var cultist_id: int = cultist_ids[0]
	var alive_players: Array[int] = [1, 2, 3, 4]

	# Track signal
	var signal_state := {"received": false, "player_id": -1}
	_cultist_manager.cultist_voted_discovered.connect(func(player_id):
		signal_state["received"] = true
		signal_state["player_id"] = player_id
	)

	# Discover via vote
	_cultist_manager.start_voting(alive_players)
	for pid in alive_players:
		if pid != cultist_id:
			_cultist_manager.cast_vote(pid, cultist_id)
		else:
			_cultist_manager.cast_vote(pid, -1)

	await get_tree().process_frame

	assert_true(signal_state["received"], "cultist_voted_discovered should be emitted")
	assert_eq(signal_state["player_id"], cultist_id, "Signal should contain correct player ID")
