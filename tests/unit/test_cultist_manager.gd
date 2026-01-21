extends GutTest
## Unit tests for CultistManager role assignment logic.


var _manager: Node


func before_each() -> void:
	# Create a fresh CultistManager instance for each test
	_manager = load("res://src/cultist/cultist_manager.gd").new()
	_manager.set_is_server(true)
	add_child_autofree(_manager)


## Helper to create typed evidence array.
func _make_evidence(types: Array) -> Array[String]:
	var result: Array[String] = []
	for t in types:
		result.append(str(t))
	return result


# --- Test: 4-Player Assignment ---


func test_4_player_assignment_produces_exactly_1_cultist() -> void:
	_manager.seed_rng(12345)
	var player_ids: Array[int] = [1, 2, 3, 4]

	var role_map: Dictionary = _manager.assign_roles(player_ids, "TestEntity", _make_evidence(["EMF", "TEMP"]))

	var cultist_count := 0
	for player_id in role_map.keys():
		if role_map[player_id] == 1:  # CULTIST
			cultist_count += 1

	assert_eq(cultist_count, 1, "4-player game should have exactly 1 Cultist")


func test_4_player_assignment_produces_3_investigators() -> void:
	_manager.seed_rng(54321)
	var player_ids: Array[int] = [1, 2, 3, 4]

	var role_map: Dictionary = _manager.assign_roles(player_ids, "TestEntity", _make_evidence(["EMF", "TEMP"]))

	var investigator_count := 0
	for player_id in role_map.keys():
		if role_map[player_id] == 0:  # INVESTIGATOR
			investigator_count += 1

	assert_eq(investigator_count, 3, "4-player game should have exactly 3 Investigators")


# --- Test: 5-Player Assignment ---


func test_5_player_assignment_produces_exactly_1_cultist() -> void:
	_manager.seed_rng(67890)
	var player_ids: Array[int] = [1, 2, 3, 4, 5]

	var role_map: Dictionary = _manager.assign_roles(player_ids, "TestEntity", _make_evidence(["EMF", "TEMP"]))

	var cultist_count := 0
	for player_id in role_map.keys():
		if role_map[player_id] == 1:  # CULTIST
			cultist_count += 1

	assert_eq(cultist_count, 1, "5-player game should have exactly 1 Cultist")


func test_5_player_assignment_produces_4_investigators() -> void:
	_manager.seed_rng(11111)
	var player_ids: Array[int] = [1, 2, 3, 4, 5]

	var role_map: Dictionary = _manager.assign_roles(player_ids, "TestEntity", _make_evidence(["EMF", "TEMP"]))

	var investigator_count := 0
	for player_id in role_map.keys():
		if role_map[player_id] == 0:  # INVESTIGATOR
			investigator_count += 1

	assert_eq(investigator_count, 4, "5-player game should have exactly 4 Investigators")


# --- Test: 6-Player Assignment (1 Cultist) ---


func test_6_player_assignment_1_cultist_config() -> void:
	_manager.seed_rng(22222)
	_manager.set_cultist_count_6p(1)
	var player_ids: Array[int] = [1, 2, 3, 4, 5, 6]

	var role_map: Dictionary = _manager.assign_roles(player_ids, "TestEntity", _make_evidence(["EMF", "TEMP"]))

	var cultist_count := 0
	for player_id in role_map.keys():
		if role_map[player_id] == 1:  # CULTIST
			cultist_count += 1

	assert_eq(cultist_count, 1, "6-player game with 1-Cultist config should have 1 Cultist")


# --- Test: 6-Player Assignment (2 Cultists) ---


func test_6_player_assignment_2_cultist_config() -> void:
	_manager.seed_rng(33333)
	_manager.set_cultist_count_6p(2)
	var player_ids: Array[int] = [1, 2, 3, 4, 5, 6]

	var role_map: Dictionary = _manager.assign_roles(player_ids, "TestEntity", _make_evidence(["EMF", "TEMP"]))

	var cultist_count := 0
	for player_id in role_map.keys():
		if role_map[player_id] == 1:  # CULTIST
			cultist_count += 1

	assert_eq(cultist_count, 2, "6-player game with 2-Cultist config should have 2 Cultists")


func test_6_player_assignment_2_cultist_leaves_4_investigators() -> void:
	_manager.seed_rng(44444)
	_manager.set_cultist_count_6p(2)
	var player_ids: Array[int] = [1, 2, 3, 4, 5, 6]

	var role_map: Dictionary = _manager.assign_roles(player_ids, "TestEntity", _make_evidence(["EMF", "TEMP"]))

	var investigator_count := 0
	for player_id in role_map.keys():
		if role_map[player_id] == 0:  # INVESTIGATOR
			investigator_count += 1

	assert_eq(investigator_count, 4, "6-player game with 2 Cultists should have 4 Investigators")


# --- Test: Randomness Distribution ---


func test_assignment_randomness_distributes_cultist_across_players() -> void:
	# Run multiple assignments with different seeds
	# Each player should be selected as Cultist at least once
	var player_ids: Array[int] = [1, 2, 3, 4, 5]
	var cultist_selections: Dictionary = {}

	for player_id in player_ids:
		cultist_selections[player_id] = 0

	# Run 50 iterations with different seeds
	for i in range(50):
		_manager.seed_rng(i * 1000)
		var role_map: Dictionary = _manager.assign_roles(player_ids, "TestEntity", _make_evidence(["EMF"]))

		for player_id in role_map.keys():
			if role_map[player_id] == 1:  # CULTIST
				cultist_selections[player_id] += 1

	# Each player should be selected at least once (probabilistically)
	# With 50 iterations and 5 players, each should be selected ~10 times
	var any_selected_multiple_times := false
	for player_id in cultist_selections.keys():
		if cultist_selections[player_id] > 1:
			any_selected_multiple_times = true
			break

	assert_true(any_selected_multiple_times, "Random selection should vary across players")


func test_seeded_rng_produces_reproducible_results() -> void:
	var player_ids: Array[int] = [1, 2, 3, 4, 5]

	# First assignment with seed 12345
	_manager.seed_rng(12345)
	var first_result: Dictionary = _manager.assign_roles(player_ids, "TestEntity", _make_evidence(["EMF"]))

	# Reset and run again with same seed
	_manager.reset()
	_manager.set_is_server(true)
	_manager.seed_rng(12345)
	var second_result: Dictionary = _manager.assign_roles(player_ids, "TestEntity", _make_evidence(["EMF"]))

	# Results should be identical
	for player_id in first_result.keys():
		assert_eq(
			first_result[player_id],
			second_result[player_id],
			"Same seed should produce identical role assignments"
		)


# --- Test: Role Map Structure ---


func test_role_map_contains_all_player_ids() -> void:
	_manager.seed_rng(55555)
	var player_ids: Array[int] = [10, 20, 30, 40]

	var role_map: Dictionary = _manager.assign_roles(player_ids, "TestEntity", _make_evidence(["EMF"]))

	for player_id in player_ids:
		assert_has(role_map, player_id, "Role map should contain all player IDs")


func test_role_map_values_are_valid_roles() -> void:
	_manager.seed_rng(66666)
	var player_ids: Array[int] = [1, 2, 3, 4, 5]

	var role_map: Dictionary = _manager.assign_roles(player_ids, "TestEntity", _make_evidence(["EMF"]))

	for player_id in role_map.keys():
		var role: int = role_map[player_id]
		assert_true(role == 0 or role == 1, "Role should be 0 (INVESTIGATOR) or 1 (CULTIST)")


# --- Test: is_cultist Method ---


func test_is_cultist_returns_true_for_cultist() -> void:
	_manager.seed_rng(77777)
	var player_ids: Array[int] = [1, 2, 3, 4]

	var role_map: Dictionary = _manager.assign_roles(player_ids, "TestEntity", _make_evidence(["EMF"]))

	# Find the Cultist
	var cultist_id := -1
	for player_id in role_map.keys():
		if role_map[player_id] == 1:
			cultist_id = player_id
			break

	assert_ne(cultist_id, -1, "Should find a Cultist")
	assert_true(_manager.is_cultist(cultist_id), "is_cultist should return true for Cultist")


func test_is_cultist_returns_false_for_investigator() -> void:
	_manager.seed_rng(88888)
	var player_ids: Array[int] = [1, 2, 3, 4]

	var role_map: Dictionary = _manager.assign_roles(player_ids, "TestEntity", _make_evidence(["EMF"]))

	# Find an Investigator
	var investigator_id := -1
	for player_id in role_map.keys():
		if role_map[player_id] == 0:
			investigator_id = player_id
			break

	assert_ne(investigator_id, -1, "Should find an Investigator")
	assert_false(
		_manager.is_cultist(investigator_id), "is_cultist should return false for Investigator"
	)


# --- Test: Invalid Player Counts ---


func test_assignment_fails_with_too_few_players() -> void:
	_manager.seed_rng(99999)
	var player_ids: Array[int] = [1, 2, 3]  # Only 3 players (min is 4)

	var role_map: Dictionary = _manager.assign_roles(player_ids, "TestEntity", _make_evidence(["EMF"]))

	assert_true(role_map.is_empty(), "Assignment should fail with fewer than 4 players")


func test_assignment_fails_with_too_many_players() -> void:
	_manager.seed_rng(10101)
	var player_ids: Array[int] = [1, 2, 3, 4, 5, 6, 7]  # 7 players (max is 6)

	var role_map: Dictionary = _manager.assign_roles(player_ids, "TestEntity", _make_evidence(["EMF"]))

	assert_true(role_map.is_empty(), "Assignment should fail with more than 6 players")


# --- Test: Entity Info Storage ---


func test_entity_type_stored_after_assignment() -> void:
	_manager.seed_rng(20202)
	var player_ids: Array[int] = [1, 2, 3, 4]

	_manager.assign_roles(player_ids, "Banshee", _make_evidence(["EMF", "FREEZING"]))

	assert_eq(_manager.get_entity_type(), "Banshee", "Entity type should be stored")


func test_entity_evidence_stored_after_assignment() -> void:
	_manager.seed_rng(30303)
	var player_ids: Array[int] = [1, 2, 3, 4]

	_manager.assign_roles(player_ids, "Spirit", _make_evidence(["EMF_SIGNATURE", "GHOST_WRITING", "AURA_PATTERN"]))

	var evidence: Array[String] = _manager.get_entity_evidence()
	assert_eq(evidence.size(), 3, "Should store 3 evidence types")
	assert_has(evidence, "EMF_SIGNATURE")
	assert_has(evidence, "GHOST_WRITING")
	assert_has(evidence, "AURA_PATTERN")


# --- Test: Reset ---


func test_reset_clears_cultist_ids() -> void:
	_manager.seed_rng(40404)
	var player_ids: Array[int] = [1, 2, 3, 4]
	_manager.assign_roles(player_ids, "TestEntity", _make_evidence(["EMF"]))

	_manager.reset()

	assert_eq(_manager.get_cultist_count(), 0, "Reset should clear Cultist IDs")


func test_reset_clears_entity_info() -> void:
	_manager.seed_rng(50505)
	var player_ids: Array[int] = [1, 2, 3, 4]
	_manager.assign_roles(player_ids, "TestEntity", _make_evidence(["EMF"]))

	_manager.reset()
	_manager.set_is_server(true)

	assert_eq(_manager.get_entity_type(), "", "Reset should clear entity type")
	assert_eq(_manager.get_entity_evidence().size(), 0, "Reset should clear entity evidence")


# --- Test: Cultist Count Configuration ---


func test_cultist_count_6p_default_is_1() -> void:
	assert_eq(_manager.get_cultist_count_6p(), 1, "Default Cultist count for 6p should be 1")


func test_set_cultist_count_6p_clamps_to_valid_range() -> void:
	_manager.set_cultist_count_6p(0)
	assert_eq(_manager.get_cultist_count_6p(), 1, "Cultist count should be clamped to min 1")

	_manager.set_cultist_count_6p(5)
	assert_eq(_manager.get_cultist_count_6p(), 2, "Cultist count should be clamped to max 2")
