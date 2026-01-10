extends GutTest
## Unit tests for EvidenceManager autoload.


const MANAGER_SCRIPT := "res://src/evidence/evidence_manager.gd"

var _manager: Node = null


func before_each() -> void:
	_manager = load(MANAGER_SCRIPT).new()
	add_child_autoqfree(_manager)
	_manager.enable_collection()


# --- Test: Initial State ---


func test_starts_with_no_evidence() -> void:
	assert_eq(_manager.get_evidence_count(), 0)


func test_collection_disabled_by_default() -> void:
	var fresh_manager: Node = load(MANAGER_SCRIPT).new()
	add_child_autoqfree(fresh_manager)
	assert_false(fresh_manager.is_collection_enabled())


func test_enable_collection() -> void:
	var fresh_manager: Node = load(MANAGER_SCRIPT).new()
	add_child_autoqfree(fresh_manager)
	fresh_manager.enable_collection()
	assert_true(fresh_manager.is_collection_enabled())


func test_disable_collection() -> void:
	_manager.disable_collection()
	assert_false(_manager.is_collection_enabled())


# --- Test: Evidence Collection ---


func test_collect_evidence_returns_evidence() -> void:
	var evidence: Evidence = _manager.collect_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	assert_not_null(evidence)


func test_collect_evidence_increments_count() -> void:
	_manager.collect_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	assert_eq(_manager.get_evidence_count(), 1)


func test_collect_evidence_stores_type() -> void:
	var evidence: Evidence = _manager.collect_evidence(
		EvidenceEnums.EvidenceType.GHOST_WRITING,
		1,
		Vector3.ZERO
	)
	assert_eq(evidence.type, EvidenceEnums.EvidenceType.GHOST_WRITING)


func test_collect_evidence_stores_collector() -> void:
	var evidence: Evidence = _manager.collect_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		42,
		Vector3.ZERO
	)
	assert_eq(evidence.collector_id, 42)


func test_collect_evidence_stores_location() -> void:
	var pos := Vector3(5.0, 1.0, -3.0)
	var evidence: Evidence = _manager.collect_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		pos
	)
	assert_eq(evidence.location, pos)


func test_collect_evidence_stores_quality() -> void:
	var evidence: Evidence = _manager.collect_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO,
		EvidenceEnums.ReadingQuality.WEAK
	)
	assert_eq(evidence.quality, EvidenceEnums.ReadingQuality.WEAK)


func test_collect_evidence_stores_equipment() -> void:
	var evidence: Evidence = _manager.collect_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO,
		EvidenceEnums.ReadingQuality.STRONG,
		"EMF Reader"
	)
	assert_eq(evidence.equipment_used, "EMF Reader")


func test_collect_evidence_rejected_when_disabled() -> void:
	_manager.disable_collection()
	var evidence: Evidence = _manager.collect_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	assert_null(evidence)


func test_collect_evidence_emits_signal() -> void:
	var state := {"received": false, "evidence": null}
	_manager.evidence_collected.connect(func(e: Evidence):
		state["received"] = true
		state["evidence"] = e
	)
	_manager.collect_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	assert_true(state["received"])
	assert_not_null(state["evidence"])


# --- Test: Cooperative Evidence Collection ---


func test_collect_cooperative_evidence() -> void:
	var evidence: Evidence = _manager.collect_cooperative_evidence(
		EvidenceEnums.EvidenceType.PRISM_READING,
		1,
		2,
		Vector3.ZERO
	)
	assert_not_null(evidence)
	assert_eq(evidence.secondary_collector_id, 2)


func test_collect_cooperative_evidence_stores_both_collectors() -> void:
	var evidence: Evidence = _manager.collect_cooperative_evidence(
		EvidenceEnums.EvidenceType.AURA_PATTERN,
		10,
		20,
		Vector3.ZERO
	)
	assert_eq(evidence.collector_id, 10)
	assert_eq(evidence.secondary_collector_id, 20)


func test_collect_cooperative_non_cooperative_type_falls_back() -> void:
	var evidence: Evidence = _manager.collect_cooperative_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		2,
		Vector3.ZERO
	)
	assert_not_null(evidence)
	assert_eq(evidence.secondary_collector_id, 0)


# --- Test: Queries by Type ---


func test_get_evidence_by_type_returns_empty_initially() -> void:
	var result: Array[Evidence] = _manager.get_evidence_by_type(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE
	)
	assert_eq(result.size(), 0)


func test_get_evidence_by_type_returns_matching() -> void:
	_manager.collect_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	var result: Array[Evidence] = _manager.get_evidence_by_type(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE
	)
	assert_eq(result.size(), 1)


func test_get_evidence_by_type_excludes_other_types() -> void:
	_manager.collect_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	_manager.collect_evidence(
		EvidenceEnums.EvidenceType.GHOST_WRITING,
		1,
		Vector3.ZERO
	)
	var result: Array[Evidence] = _manager.get_evidence_by_type(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE
	)
	assert_eq(result.size(), 1)


func test_has_evidence_type_false_initially() -> void:
	assert_false(_manager.has_evidence_type(EvidenceEnums.EvidenceType.EMF_SIGNATURE))


func test_has_evidence_type_true_after_collection() -> void:
	_manager.collect_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	assert_true(_manager.has_evidence_type(EvidenceEnums.EvidenceType.EMF_SIGNATURE))


# --- Test: Queries by Collector ---


func test_get_evidence_by_collector_returns_empty_initially() -> void:
	var result: Array[Evidence] = _manager.get_evidence_by_collector(1)
	assert_eq(result.size(), 0)


func test_get_evidence_by_collector_returns_matching() -> void:
	_manager.collect_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		42,
		Vector3.ZERO
	)
	var result: Array[Evidence] = _manager.get_evidence_by_collector(42)
	assert_eq(result.size(), 1)


func test_get_evidence_by_collector_excludes_others() -> void:
	_manager.collect_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	_manager.collect_evidence(
		EvidenceEnums.EvidenceType.GHOST_WRITING,
		2,
		Vector3.ZERO
	)
	var result: Array[Evidence] = _manager.get_evidence_by_collector(1)
	assert_eq(result.size(), 1)


func test_get_evidence_by_collector_multiple_evidence() -> void:
	_manager.collect_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	_manager.collect_evidence(
		EvidenceEnums.EvidenceType.GHOST_WRITING,
		1,
		Vector3.ZERO
	)
	var result: Array[Evidence] = _manager.get_evidence_by_collector(1)
	assert_eq(result.size(), 2)


# --- Test: Query by UID ---


func test_get_evidence_by_uid_returns_null_for_unknown() -> void:
	var result: Evidence = _manager.get_evidence_by_uid("nonexistent")
	assert_null(result)


func test_get_evidence_by_uid_returns_evidence() -> void:
	var evidence: Evidence = _manager.collect_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	var result: Evidence = _manager.get_evidence_by_uid(evidence.uid)
	assert_eq(result, evidence)


# --- Test: Get All Evidence ---


func test_get_all_evidence_empty_initially() -> void:
	var result: Array[Evidence] = _manager.get_all_evidence()
	assert_eq(result.size(), 0)


func test_get_all_evidence_returns_all() -> void:
	_manager.collect_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	_manager.collect_evidence(
		EvidenceEnums.EvidenceType.GHOST_WRITING,
		2,
		Vector3.ZERO
	)
	var result: Array[Evidence] = _manager.get_all_evidence()
	assert_eq(result.size(), 2)


# --- Test: Verification ---


func test_verify_evidence_changes_state() -> void:
	var evidence: Evidence = _manager.collect_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	var success: bool = _manager.verify_evidence(evidence.uid, 2)
	assert_true(success)
	assert_true(evidence.is_verified())


func test_verify_evidence_rejects_same_collector() -> void:
	var evidence: Evidence = _manager.collect_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	var success: bool = _manager.verify_evidence(evidence.uid, 1)
	assert_false(success)
	assert_false(evidence.is_verified())


func test_verify_evidence_rejects_unknown_uid() -> void:
	var success: bool = _manager.verify_evidence("unknown", 2)
	assert_false(success)


func test_verify_evidence_emits_signal() -> void:
	var evidence: Evidence = _manager.collect_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	var state := {"received": false}
	_manager.evidence_verification_changed.connect(func(_e: Evidence):
		state["received"] = true
	)
	_manager.verify_evidence(evidence.uid, 2)
	assert_true(state["received"])


# --- Test: Contesting ---


func test_contest_evidence_changes_state() -> void:
	var evidence: Evidence = _manager.collect_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	var success: bool = _manager.contest_evidence(evidence.uid, 2)
	assert_true(success)
	assert_true(evidence.is_contested())


func test_contest_evidence_rejects_same_collector() -> void:
	var evidence: Evidence = _manager.collect_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	var success: bool = _manager.contest_evidence(evidence.uid, 1)
	assert_false(success)
	assert_false(evidence.is_contested())


func test_contest_evidence_rejects_unknown_uid() -> void:
	var success: bool = _manager.contest_evidence("unknown", 2)
	assert_false(success)


func test_contest_evidence_emits_contested_signal() -> void:
	var evidence: Evidence = _manager.collect_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	var state := {"received": false, "contester": 0}
	_manager.evidence_contested.connect(func(e: Evidence, contester_id: int):
		state["received"] = true
		state["contester"] = contester_id
	)
	_manager.contest_evidence(evidence.uid, 99)
	assert_true(state["received"])
	assert_eq(state["contester"], 99)


# --- Test: Filtered Queries ---


func test_get_verified_evidence_empty_initially() -> void:
	var result: Array[Evidence] = _manager.get_verified_evidence()
	assert_eq(result.size(), 0)


func test_get_verified_evidence_returns_only_verified() -> void:
	var evidence1: Evidence = _manager.collect_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	_manager.collect_evidence(
		EvidenceEnums.EvidenceType.GHOST_WRITING,
		2,
		Vector3.ZERO
	)
	_manager.verify_evidence(evidence1.uid, 3)
	var result: Array[Evidence] = _manager.get_verified_evidence()
	assert_eq(result.size(), 1)
	assert_eq(result[0].uid, evidence1.uid)


func test_get_contested_evidence_empty_initially() -> void:
	var result: Array[Evidence] = _manager.get_contested_evidence()
	assert_eq(result.size(), 0)


func test_get_contested_evidence_returns_only_contested() -> void:
	var evidence1: Evidence = _manager.collect_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	_manager.collect_evidence(
		EvidenceEnums.EvidenceType.GHOST_WRITING,
		2,
		Vector3.ZERO
	)
	_manager.contest_evidence(evidence1.uid, 3)
	var result: Array[Evidence] = _manager.get_contested_evidence()
	assert_eq(result.size(), 1)


func test_get_definitive_evidence() -> void:
	_manager.collect_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO,
		EvidenceEnums.ReadingQuality.STRONG
	)
	_manager.collect_evidence(
		EvidenceEnums.EvidenceType.GHOST_WRITING,
		2,
		Vector3.ZERO,
		EvidenceEnums.ReadingQuality.WEAK
	)
	var result: Array[Evidence] = _manager.get_definitive_evidence()
	assert_eq(result.size(), 1)


# --- Test: Clear Evidence ---


func test_clear_evidence_removes_all() -> void:
	_manager.collect_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	_manager.collect_evidence(
		EvidenceEnums.EvidenceType.GHOST_WRITING,
		2,
		Vector3.ZERO
	)
	_manager.clear_evidence()
	assert_eq(_manager.get_evidence_count(), 0)


func test_clear_evidence_emits_signal() -> void:
	var state := {"cleared": false}
	_manager.evidence_cleared.connect(func():
		state["cleared"] = true
	)
	_manager.clear_evidence()
	assert_true(state["cleared"])


func test_clear_evidence_resets_type_index() -> void:
	_manager.collect_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	_manager.clear_evidence()
	assert_false(_manager.has_evidence_type(EvidenceEnums.EvidenceType.EMF_SIGNATURE))


func test_clear_evidence_resets_collector_index() -> void:
	_manager.collect_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		42,
		Vector3.ZERO
	)
	_manager.clear_evidence()
	var result: Array[Evidence] = _manager.get_evidence_by_collector(42)
	assert_eq(result.size(), 0)


# --- Test: Multiple Evidence Types Collected ---


func test_collect_all_evidence_types() -> void:
	var types := [
		EvidenceEnums.EvidenceType.FREEZING_TEMPERATURE,
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		EvidenceEnums.EvidenceType.PRISM_READING,
		EvidenceEnums.EvidenceType.AURA_PATTERN,
		EvidenceEnums.EvidenceType.GHOST_WRITING,
		EvidenceEnums.EvidenceType.VISUAL_MANIFESTATION,
		EvidenceEnums.EvidenceType.PHYSICAL_INTERACTION,
		EvidenceEnums.EvidenceType.HUNT_BEHAVIOR,
	]

	for i: int in range(types.size()):
		_manager.collect_evidence(types[i], i + 1, Vector3.ZERO)

	assert_eq(_manager.get_evidence_count(), 8)

	for evidence_type: int in types:
		assert_true(
			_manager.has_evidence_type(evidence_type as EvidenceEnums.EvidenceType),
			"Missing type: %d" % evidence_type
		)
