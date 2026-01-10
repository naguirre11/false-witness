extends GutTest
## Tests for VerificationManager trust-level verification rules.


# --- Test Helpers ---

var verification_manager: Node


func before_each() -> void:
	verification_manager = load("res://src/evidence/verification_manager.gd").new()
	add_child_autofree(verification_manager)


func _create_evidence(
	evidence_type: EvidenceEnums.EvidenceType,
	collector_id: int,
	pos: Vector3 = Vector3.ZERO
) -> Evidence:
	return Evidence.create(evidence_type, collector_id, pos)


func _create_cooperative_evidence(
	evidence_type: EvidenceEnums.EvidenceType,
	primary_id: int,
	secondary_id: int,
	pos: Vector3 = Vector3.ZERO
) -> Evidence:
	return Evidence.create_cooperative(evidence_type, primary_id, secondary_id, pos)


# --- Basic Verification Tests ---


func test_try_verify_returns_fail_for_null_evidence() -> void:
	var result: Dictionary = verification_manager.try_verify(null, 1)
	assert_false(result.get("success", true))
	assert_eq(result.get("reason"), "null_evidence")


func test_try_verify_prevents_self_verification() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.EMF_SIGNATURE, 1)
	var result: Dictionary = verification_manager.try_verify(evidence, 1)
	assert_false(result.get("success", true))
	assert_eq(result.get("reason"), "self_verification")


func test_try_verify_prevents_secondary_collector_verification() -> void:
	var evidence := _create_cooperative_evidence(
		EvidenceEnums.EvidenceType.PRISM_READING, 1, 2
	)
	var result: Dictionary = verification_manager.try_verify(evidence, 2)
	assert_false(result.get("success", true))
	assert_eq(result.get("reason"), "secondary_collector_verification")


func test_try_verify_prevents_already_verified() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.EMF_SIGNATURE, 1)
	evidence.verify()
	var result: Dictionary = verification_manager.try_verify(evidence, 2)
	assert_false(result.get("success", true))
	assert_eq(result.get("reason"), "already_verified")


func test_try_verify_allows_third_party() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.EMF_SIGNATURE, 1)
	var result: Dictionary = verification_manager.try_verify(evidence, 3)
	assert_true(result.get("success", false))


# --- Contest Tests ---


func test_try_contest_returns_fail_for_null_evidence() -> void:
	var result: Dictionary = verification_manager.try_contest(null, 1)
	assert_false(result.get("success", true))
	assert_eq(result.get("reason"), "null_evidence")


func test_try_contest_prevents_self_contest() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.EMF_SIGNATURE, 1)
	var result: Dictionary = verification_manager.try_contest(evidence, 1)
	assert_false(result.get("success", true))
	assert_eq(result.get("reason"), "self_contest")


func test_try_contest_prevents_unfalsifiable_contest() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.HUNT_BEHAVIOR, 1)
	var result: Dictionary = verification_manager.try_contest(evidence, 2)
	assert_false(result.get("success", true))
	assert_eq(result.get("reason"), "unfalsifiable_cannot_contest")


func test_try_contest_prevents_already_contested() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.EMF_SIGNATURE, 1)
	evidence.contest()
	var result: Dictionary = verification_manager.try_contest(evidence, 2)
	assert_false(result.get("success", true))
	assert_eq(result.get("reason"), "already_contested")


func test_try_contest_allows_high_trust() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.EMF_SIGNATURE, 1)
	var result: Dictionary = verification_manager.try_contest(evidence, 2)
	assert_true(result.get("success", false))


func test_try_contest_allows_low_trust() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.PRISM_READING, 1)
	var result: Dictionary = verification_manager.try_contest(evidence, 2)
	assert_true(result.get("success", false))


# --- UNFALSIFIABLE Trust Level Tests ---


func test_unfalsifiable_always_verifiable() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.HUNT_BEHAVIOR, 1)
	var result: Dictionary = verification_manager.try_verify(evidence, 2)
	assert_true(result.get("success", false))


func test_unfalsifiable_single_witness_sets_metadata() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.HUNT_BEHAVIOR, 1)
	verification_manager.try_verify(evidence, 2)
	assert_true(evidence.get_verification_meta("single_witness", false))


func test_unfalsifiable_adds_verifier_as_witness() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.HUNT_BEHAVIOR, 1)
	verification_manager.try_verify(evidence, 2)
	assert_true(evidence.was_witnessed_by(2))


# --- HIGH Trust Level Tests ---


func test_high_trust_verifiable_by_third_party() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.EMF_SIGNATURE, 1)
	var result: Dictionary = verification_manager.try_verify(evidence, 2)
	assert_true(result.get("success", false))


func test_high_trust_includes_thermometer() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.FREEZING_TEMPERATURE, 1)
	assert_eq(evidence.trust_level, EvidenceEnums.TrustLevel.HIGH)
	var result: Dictionary = verification_manager.try_verify(evidence, 2)
	assert_true(result.get("success", false))


func test_high_trust_includes_visual_manifestation() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.VISUAL_MANIFESTATION, 1)
	assert_eq(evidence.trust_level, EvidenceEnums.TrustLevel.HIGH)
	var result: Dictionary = verification_manager.try_verify(evidence, 2)
	assert_true(result.get("success", false))


func test_high_trust_includes_physical_interaction() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.PHYSICAL_INTERACTION, 1)
	assert_eq(evidence.trust_level, EvidenceEnums.TrustLevel.HIGH)
	var result: Dictionary = verification_manager.try_verify(evidence, 2)
	assert_true(result.get("success", false))


# --- VARIABLE Trust Level Tests ---


func test_variable_trust_verifiable_by_third_party() -> void:
	var evidence := _create_cooperative_evidence(
		EvidenceEnums.EvidenceType.AURA_PATTERN, 1, 2
	)
	var result: Dictionary = verification_manager.try_verify(evidence, 3)
	assert_true(result.get("success", false))


func test_variable_trust_records_verifier_id() -> void:
	var evidence := _create_cooperative_evidence(
		EvidenceEnums.EvidenceType.AURA_PATTERN, 1, 2
	)
	verification_manager.try_verify(evidence, 3)
	assert_eq(evidence.verifier_id, 3)


func test_variable_trust_metadata_contains_third_party_witness() -> void:
	var evidence := _create_cooperative_evidence(
		EvidenceEnums.EvidenceType.AURA_PATTERN, 1, 2
	)
	var result: Dictionary = verification_manager.try_verify(evidence, 3)
	var metadata: Dictionary = result.get("metadata", {})
	assert_eq(metadata.get("third_party_witness"), 3)


# --- LOW Trust Level Tests ---


func test_low_trust_verifiable() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.PRISM_READING, 1)
	var result: Dictionary = verification_manager.try_verify(evidence, 2)
	assert_true(result.get("success", false))


func test_low_trust_operator_registration() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.PRISM_READING, 1)
	verification_manager.register_operator(evidence, 1)
	verification_manager.register_operator(evidence, 2)
	var operators: Array = verification_manager.get_operators(evidence)
	assert_eq(operators.size(), 2)
	assert_has(operators, 1)
	assert_has(operators, 2)


func test_low_trust_different_operators_metadata() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.PRISM_READING, 1)
	verification_manager.register_operator(evidence, 1)
	verification_manager.register_operator(evidence, 2)
	var result: Dictionary = verification_manager.try_verify(evidence, 3)
	var metadata: Dictionary = result.get("metadata", {})
	assert_true(metadata.get("different_operators", false))


func test_low_trust_single_operator_no_different_operators_flag() -> void:
	# With only one operator registered beforehand, different_operators should be false
	# Note: The verifier is also added as an operator during verification,
	# but the check happens BEFORE registration, so with 1 pre-registered operator,
	# different_operators is false.
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.PRISM_READING, 1)
	# Don't register any operators - the verifier will be the first
	var result: Dictionary = verification_manager.try_verify(evidence, 2)
	var metadata: Dictionary = result.get("metadata", {})
	# With 0 operators before the verifier, different_operators should be false
	assert_false(metadata.get("different_operators", true))


# --- SABOTAGE_RISK Trust Level Tests ---


func test_sabotage_risk_verifiable_without_buddy_system() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.GHOST_WRITING, 1)
	var result: Dictionary = verification_manager.try_verify(evidence, 2)
	assert_true(result.get("success", false))


func test_sabotage_risk_sets_no_buddy_system_metadata() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.GHOST_WRITING, 1)
	verification_manager.try_verify(evidence, 2)
	assert_true(evidence.get_verification_meta("no_buddy_system", false))


func test_sabotage_risk_with_buddy_system() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.GHOST_WRITING, 1)
	verification_manager.set_ghost_writing_witnesses(evidence, 2, 3)
	var result: Dictionary = verification_manager.try_verify(evidence, 4)
	assert_true(result.get("success", false))
	var metadata: Dictionary = result.get("metadata", {})
	assert_true(metadata.get("buddy_system", false))


func test_sabotage_risk_fails_with_sabotage_flag() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.GHOST_WRITING, 1)
	verification_manager.report_sabotage(evidence, "book_moved")
	var result: Dictionary = verification_manager.try_verify(evidence, 2)
	assert_false(result.get("success", true))
	assert_eq(result.get("reason"), "sabotage_detected")


func test_sabotage_risk_multiple_flags() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.GHOST_WRITING, 1)
	verification_manager.report_sabotage(evidence, "book_moved")
	verification_manager.report_sabotage(evidence, "wrong_room")
	var result: Dictionary = verification_manager.try_verify(evidence, 2)
	assert_false(result.get("success", true))
	var metadata: Dictionary = result.get("metadata", {})
	var flags: Dictionary = metadata.get("sabotage_flags", {})
	assert_has(flags, "book_moved")
	assert_has(flags, "wrong_room")


# --- Witness Registration Tests ---


func test_register_witness_adds_to_evidence() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.HUNT_BEHAVIOR, 1)
	verification_manager.register_witness(evidence, 2)
	verification_manager.register_witness(evidence, 3)
	assert_eq(evidence.get_witness_count(), 2)
	assert_true(evidence.was_witnessed_by(2))
	assert_true(evidence.was_witnessed_by(3))


func test_register_witness_no_duplicates() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.HUNT_BEHAVIOR, 1)
	verification_manager.register_witness(evidence, 2)
	verification_manager.register_witness(evidence, 2)
	assert_eq(evidence.get_witness_count(), 1)


# --- Signal Tests ---


func test_verification_attempted_signal_on_success() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.EMF_SIGNATURE, 1)
	var state := {"called": false, "success": false}
	verification_manager.verification_attempted.connect(
		func(e: Evidence, vid: int, s: bool):
			state["called"] = true
			state["success"] = s
	)
	verification_manager.try_verify(evidence, 2)
	assert_true(state["called"])
	assert_true(state["success"])


func test_verification_attempted_signal_on_failure() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.EMF_SIGNATURE, 1)
	var state := {"called": false, "success": true}
	verification_manager.verification_attempted.connect(
		func(e: Evidence, vid: int, s: bool):
			state["called"] = true
			state["success"] = s
	)
	verification_manager.try_verify(evidence, 1)  # Self-verification
	assert_true(state["called"])
	assert_false(state["success"])


func test_verification_rule_failed_signal() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.EMF_SIGNATURE, 1)
	var state := {"called": false, "reason": ""}
	verification_manager.verification_rule_failed.connect(
		func(e: Evidence, r: String):
			state["called"] = true
			state["reason"] = r
	)
	verification_manager.try_verify(evidence, 1)  # Self-verification
	assert_true(state["called"])
	assert_eq(state["reason"], "self_verification")


# --- Evidence Cleared Handler Tests ---


func test_evidence_cleared_clears_operator_history() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.PRISM_READING, 1)
	verification_manager.register_operator(evidence, 1)
	verification_manager.register_operator(evidence, 2)
	assert_eq(verification_manager.get_operators(evidence).size(), 2)

	# Simulate evidence_cleared signal
	verification_manager._on_evidence_cleared()
	assert_eq(verification_manager.get_operators(evidence).size(), 0)


# --- Ghost Writing Witness Tests ---


func test_set_ghost_writing_witnesses() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.GHOST_WRITING, 1)
	verification_manager.set_ghost_writing_witnesses(evidence, 2, 3)
	assert_eq(evidence.setup_witness_id, 2)
	assert_eq(evidence.result_witness_id, 3)
	assert_true(evidence.has_ghost_writing_witnesses())


func test_ghost_writing_incomplete_witnesses() -> void:
	var evidence := _create_evidence(EvidenceEnums.EvidenceType.GHOST_WRITING, 1)
	evidence.setup_witness_id = 2
	# result_witness_id is still 0
	assert_false(evidence.has_ghost_writing_witnesses())
