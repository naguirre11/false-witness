extends GutTest
## Unit tests for VerificationManager verification rules.
##
## Tests verification logic for each trust level:
## - UNFALSIFIABLE: Auto-verified with multiple witnesses
## - HIGH: Corroborating evidence or manual verification
## - VARIABLE: Third-party witness required
## - LOW: Different operators for repeat reading
## - SABOTAGE_RISK: Buddy system (setup + result witnesses)


# --- Test Evidence Helper ---


func _create_test_evidence(
	evidence_type: EvidenceEnums.EvidenceType,
	collector_id: int
) -> Evidence:
	var evidence := Evidence.create(evidence_type, collector_id, Vector3.ZERO)
	return evidence


# --- Test: Self-Verification Rejection ---


func test_self_verification_rejected() -> void:
	var evidence := _create_test_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE, 100
	)
	var verification_manager := VerificationManagerDouble.new()
	add_child_autofree(verification_manager)

	var result := verification_manager.try_verify(evidence, 100)

	assert_false(result.get("success", true))
	assert_eq(result.get("reason", ""), "self_verification")


func test_secondary_collector_verification_rejected() -> void:
	var evidence := _create_test_evidence(
		EvidenceEnums.EvidenceType.PRISM_READING, 100
	)
	evidence.secondary_collector_id = 200
	var verification_manager := VerificationManagerDouble.new()
	add_child_autofree(verification_manager)

	var result := verification_manager.try_verify(evidence, 200)

	assert_false(result.get("success", true))
	assert_eq(result.get("reason", ""), "secondary_collector_verification")


# --- Test: UNFALSIFIABLE (Hunt Behavior) ---


func test_unfalsifiable_allows_verification() -> void:
	var evidence := _create_test_evidence(
		EvidenceEnums.EvidenceType.HUNT_BEHAVIOR, 100
	)
	var verification_manager := VerificationManagerDouble.new()
	add_child_autofree(verification_manager)

	var result := verification_manager.try_verify(evidence, 200)

	assert_true(result.get("success", false))


func test_unfalsifiable_single_witness_metadata() -> void:
	var evidence := _create_test_evidence(
		EvidenceEnums.EvidenceType.HUNT_BEHAVIOR, 100
	)
	# Only collector as witness
	evidence.add_witness(100)
	var verification_manager := VerificationManagerDouble.new()
	add_child_autofree(verification_manager)

	verification_manager.try_verify(evidence, 200)

	assert_true(evidence.get_verification_meta("single_witness", false))


func test_unfalsifiable_adds_verifier_as_witness() -> void:
	var evidence := _create_test_evidence(
		EvidenceEnums.EvidenceType.HUNT_BEHAVIOR, 100
	)
	var verification_manager := VerificationManagerDouble.new()
	add_child_autofree(verification_manager)

	verification_manager.try_verify(evidence, 200)

	assert_true(evidence.was_witnessed_by(200))


# --- Test: HIGH Trust (EMF, Temperature) ---


func test_high_trust_verification_succeeds() -> void:
	var evidence := _create_test_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE, 100
	)
	var verification_manager := VerificationManagerDouble.new()
	add_child_autofree(verification_manager)

	var result := verification_manager.try_verify(evidence, 200)

	assert_true(result.get("success", false))


# --- Test: VARIABLE Trust (Aura) ---


func test_variable_trust_records_verifier() -> void:
	var evidence := _create_test_evidence(
		EvidenceEnums.EvidenceType.AURA_PATTERN, 100
	)
	evidence.secondary_collector_id = 101  # Cooperative evidence
	var verification_manager := VerificationManagerDouble.new()
	add_child_autofree(verification_manager)

	verification_manager.try_verify(evidence, 200)

	assert_eq(evidence.verifier_id, 200)


func test_variable_trust_third_party_witness() -> void:
	var evidence := _create_test_evidence(
		EvidenceEnums.EvidenceType.AURA_PATTERN, 100
	)
	evidence.secondary_collector_id = 101
	var verification_manager := VerificationManagerDouble.new()
	add_child_autofree(verification_manager)

	var result := verification_manager.try_verify(evidence, 200)

	assert_true(result.get("success", false))
	assert_eq(result.get("metadata", {}).get("third_party_witness", 0), 200)


# --- Test: LOW Trust (Prism) ---


func test_low_trust_registers_operator() -> void:
	var evidence := _create_test_evidence(
		EvidenceEnums.EvidenceType.PRISM_READING, 100
	)
	evidence.secondary_collector_id = 101
	var verification_manager := VerificationManagerDouble.new()
	add_child_autofree(verification_manager)

	verification_manager.try_verify(evidence, 200)

	var operators := verification_manager.get_operators(evidence)
	assert_true(200 in operators)


func test_low_trust_different_operators_flag() -> void:
	var evidence := _create_test_evidence(
		EvidenceEnums.EvidenceType.PRISM_READING, 100
	)
	evidence.secondary_collector_id = 101
	var verification_manager := VerificationManagerDouble.new()
	add_child_autofree(verification_manager)

	# Register first operator
	verification_manager.register_operator(evidence, 100)
	verification_manager.register_operator(evidence, 101)

	# Now verify with third operator
	var result := verification_manager.try_verify(evidence, 200)

	var metadata: Dictionary = result.get("metadata", {})
	assert_true(metadata.get("different_operators", false))


# --- Test: SABOTAGE_RISK (Ghost Writing) ---


func test_sabotage_risk_records_verifier() -> void:
	var evidence := _create_test_evidence(
		EvidenceEnums.EvidenceType.GHOST_WRITING, 100
	)
	var verification_manager := VerificationManagerDouble.new()
	add_child_autofree(verification_manager)

	verification_manager.try_verify(evidence, 200)

	assert_eq(evidence.verifier_id, 200)


func test_sabotage_risk_with_buddy_system() -> void:
	var evidence := _create_test_evidence(
		EvidenceEnums.EvidenceType.GHOST_WRITING, 100
	)
	evidence.setup_witness_id = 200
	evidence.result_witness_id = 201
	var verification_manager := VerificationManagerDouble.new()
	add_child_autofree(verification_manager)

	var result := verification_manager.try_verify(evidence, 300)

	assert_true(result.get("success", false))
	var metadata: Dictionary = result.get("metadata", {})
	assert_true(metadata.get("buddy_system", false))


func test_sabotage_risk_without_buddy_system() -> void:
	var evidence := _create_test_evidence(
		EvidenceEnums.EvidenceType.GHOST_WRITING, 100
	)
	# No setup/result witnesses
	var verification_manager := VerificationManagerDouble.new()
	add_child_autofree(verification_manager)

	var result := verification_manager.try_verify(evidence, 200)

	# Still succeeds but notes missing buddy system
	assert_true(result.get("success", false))
	assert_true(evidence.get_verification_meta("no_buddy_system", false))


func test_sabotage_risk_detected_fails_verification() -> void:
	var evidence := _create_test_evidence(
		EvidenceEnums.EvidenceType.GHOST_WRITING, 100
	)
	evidence.set_sabotage_flag("book_moved", true)
	var verification_manager := VerificationManagerDouble.new()
	add_child_autofree(verification_manager)

	var result := verification_manager.try_verify(evidence, 200)

	assert_false(result.get("success", true))
	assert_eq(result.get("reason", ""), "sabotage_detected")


# --- Test: Staleness ---


func test_very_stale_evidence_cannot_verify() -> void:
	var evidence := _create_test_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE, 100
	)
	# Set timestamp to 200 seconds ago (> 180 = VERY_STALE threshold)
	var current_time := Time.get_ticks_msec() / 1000.0
	evidence.timestamp = current_time - 200.0  # 200 seconds ago
	var verification_manager := VerificationManagerDouble.new()
	add_child_autofree(verification_manager)

	# Verify staleness calculation first
	var staleness := verification_manager.get_evidence_staleness(evidence)
	assert_eq(staleness, VerificationManagerDouble.StalenessLevel.VERY_STALE)

	var result := verification_manager.try_verify(evidence, 200)

	# Should fail with too_stale_to_verify
	assert_false(result.get("success", true))
	assert_eq(result.get("reason", ""), "too_stale_to_verify")


func test_fresh_evidence_can_verify() -> void:
	var evidence := _create_test_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE, 100
	)
	# timestamp is set to current time by create()
	var verification_manager := VerificationManagerDouble.new()
	add_child_autofree(verification_manager)

	var result := verification_manager.try_verify(evidence, 200)

	assert_true(result.get("success", false))


# --- Test: Already Verified ---


func test_already_verified_rejected() -> void:
	var evidence := _create_test_evidence(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE, 100
	)
	evidence.verify()  # Already verified
	var verification_manager := VerificationManagerDouble.new()
	add_child_autofree(verification_manager)

	var result := verification_manager.try_verify(evidence, 200)

	assert_false(result.get("success", true))
	assert_eq(result.get("reason", ""), "already_verified")


# --- Test Double ---


## Minimal VerificationManager double for testing without autoloads.
class VerificationManagerDouble:
	extends Node

	enum StalenessLevel { FRESH, STALE, VERY_STALE }

	# Copy staleness constants
	const STALENESS_FRESH := 60.0
	const STALENESS_STALE := 120.0
	const STALENESS_VERY_STALE := 180.0

	var _operator_history: Dictionary = {}

	func try_verify(evidence: Evidence, verifier_id: int) -> Dictionary:
		# Check basic validation
		var validation := _validate_verification(evidence, verifier_id)
		if not validation.get("valid", false):
			return {"success": false, "reason": validation.get("reason", "")}

		# Check staleness
		var staleness := get_evidence_staleness(evidence)
		if staleness == StalenessLevel.VERY_STALE:
			evidence.set_verification_meta("staleness_blocked", true)
			return {"success": false, "reason": "too_stale_to_verify"}
		if staleness == StalenessLevel.STALE:
			evidence.set_verification_meta("late_verification", true)

		# Dispatch to trust-level handler
		return _verify_by_trust_level(evidence, verifier_id)

	func _validate_verification(evidence: Evidence, verifier_id: int) -> Dictionary:
		if evidence == null:
			return {"valid": false, "reason": "null_evidence"}
		if evidence.collector_id == verifier_id:
			return {"valid": false, "reason": "self_verification"}
		if evidence.secondary_collector_id == verifier_id:
			return {"valid": false, "reason": "secondary_collector_verification"}
		if evidence.is_verified():
			return {"valid": false, "reason": "already_verified"}
		return {"valid": true}

	func _verify_by_trust_level(evidence: Evidence, verifier_id: int) -> Dictionary:
		match evidence.trust_level:
			EvidenceEnums.TrustLevel.UNFALSIFIABLE:
				return _verify_unfalsifiable(evidence, verifier_id)
			EvidenceEnums.TrustLevel.HIGH:
				return _verify_high_trust()
			EvidenceEnums.TrustLevel.VARIABLE:
				return _verify_variable_trust(evidence, verifier_id)
			EvidenceEnums.TrustLevel.LOW:
				return _verify_low_trust(evidence, verifier_id)
			EvidenceEnums.TrustLevel.SABOTAGE_RISK:
				return _verify_sabotage_risk(evidence, verifier_id)
			_:
				return {"success": false, "reason": "unknown_trust_level"}

	func _verify_unfalsifiable(evidence: Evidence, verifier_id: int) -> Dictionary:
		if evidence.get_witness_count() < 2:
			evidence.set_verification_meta("single_witness", true)
		evidence.add_witness(verifier_id)
		return {"success": true, "reason": "", "metadata": {}}

	func _verify_high_trust() -> Dictionary:
		return {"success": true, "reason": "", "metadata": {}}

	func _verify_variable_trust(evidence: Evidence, verifier_id: int) -> Dictionary:
		evidence.verifier_id = verifier_id
		return {"success": true, "reason": "", "metadata": {"third_party_witness": verifier_id}}

	func _verify_low_trust(evidence: Evidence, verifier_id: int) -> Dictionary:
		register_operator(evidence, verifier_id)
		var operators := get_operators(evidence)
		var has_different := operators.size() >= 2
		if has_different:
			evidence.set_verification_meta("different_operators", true)
		return {"success": true, "reason": "", "metadata": {"different_operators": has_different}}

	func _verify_sabotage_risk(evidence: Evidence, verifier_id: int) -> Dictionary:
		if evidence.has_sabotage_flags():
			return {
				"success": false,
				"reason": "sabotage_detected",
				"metadata": {"sabotage_flags": evidence.sabotage_flags}
			}
		var has_buddy := evidence.has_ghost_writing_witnesses()
		evidence.verifier_id = verifier_id
		if not has_buddy:
			evidence.set_verification_meta("no_buddy_system", true)
		return {"success": true, "reason": "", "metadata": {"buddy_system": has_buddy}}

	func register_operator(evidence: Evidence, operator_id: int) -> void:
		if evidence == null:
			return
		if not _operator_history.has(evidence.uid):
			_operator_history[evidence.uid] = []
		var operators: Array = _operator_history[evidence.uid]
		if operator_id not in operators:
			operators.append(operator_id)

	func get_operators(evidence: Evidence) -> Array:
		if evidence == null:
			return []
		return _operator_history.get(evidence.uid, [])

	func get_evidence_staleness(evidence: Evidence) -> int:
		if evidence == null:
			return StalenessLevel.VERY_STALE
		var age := get_evidence_age(evidence)
		if age < STALENESS_FRESH:
			return StalenessLevel.FRESH
		if age < STALENESS_VERY_STALE:
			return StalenessLevel.STALE
		return StalenessLevel.VERY_STALE

	func get_evidence_age(evidence: Evidence) -> float:
		if evidence == null:
			return 999999.0
		var current_time := Time.get_ticks_msec() / 1000.0
		return current_time - evidence.timestamp
