extends Node
## Trust-level verification rules engine for the evidence system.
## Autoload: VerificationManager
##
## Handles verification logic based on evidence trust levels:
## - UNFALSIFIABLE: Auto-verified with multiple witnesses
## - HIGH: Location/time-based matching
## - VARIABLE: Third-party verification or behavioral cross-reference
## - LOW: Different operator readings
## - SABOTAGE_RISK: Buddy system (setup + result witnesses)
##
## Note: No class_name to avoid conflicts with autoload singleton name.

# --- Signals ---

## Emitted when a verification attempt is made.
signal verification_attempted(evidence: Evidence, verifier_id: int, success: bool)

## Emitted when evidence is auto-verified (multi-witness events).
signal auto_verified(evidence: Evidence, witness_ids: Array)

## Emitted when verification fails due to rule violation.
signal verification_rule_failed(evidence: Evidence, reason: String)

# --- Enums ---

## Staleness levels for evidence.
enum StalenessLevel {
	FRESH,  ## Under 60s - easy to verify
	STALE,  ## 60-120s - verification needs explanation
	VERY_STALE,  ## Over 180s - cannot be newly verified
}

# --- Configuration ---

## Location tolerance for HIGH trust verification (meters).
const LOCATION_TOLERANCE := 5.0

## Time tolerance for HIGH trust verification (seconds).
const TIME_TOLERANCE := 30.0

## Minimum witnesses required for auto-verification.
const MIN_WITNESSES_AUTO_VERIFY := 2

## Evidence staleness thresholds (seconds since collection).
const STALENESS_FRESH := 60.0  ## Under 60s = fresh, easy to verify
const STALENESS_STALE := 120.0  ## 60-120s = stale, verification needs explanation
const STALENESS_VERY_STALE := 180.0  ## Over 180s = very stale, cannot be newly verified

# --- State ---

## Tracks operator IDs for LOW trust evidence (keyed by evidence UID).
var _operator_history: Dictionary = {}


func _ready() -> void:
	_connect_to_evidence_manager()
	print("[VerificationManager] Initialized - Trust-level verification rules active")


func _connect_to_evidence_manager() -> void:
	var evidence_manager := _get_evidence_manager()
	if evidence_manager:
		if evidence_manager.has_signal("evidence_collected"):
			evidence_manager.evidence_collected.connect(_on_evidence_collected)
		if evidence_manager.has_signal("evidence_cleared"):
			evidence_manager.evidence_cleared.connect(_on_evidence_cleared)


func _get_evidence_manager() -> Node:
	if has_node("/root/EvidenceManager"):
		return get_node("/root/EvidenceManager")
	return null


func _get_event_bus() -> Node:
	if has_node("/root/EventBus"):
		return get_node("/root/EventBus")
	return null


# --- Public API: Verification ---


## Attempts to verify evidence according to trust-level rules.
## Returns a VerificationResult dictionary with "success", "reason", and "metadata".
func try_verify(evidence: Evidence, verifier_id: int) -> Dictionary:
	var result: Dictionary

	if evidence == null:
		result = _fail_result("null_evidence")
		# Can't emit with null evidence
		return result

	# Self-verification is never allowed
	if evidence.collector_id == verifier_id:
		result = _fail_result("self_verification")
		_emit_verification_result(evidence, verifier_id, result)
		return result

	# Secondary collector also cannot verify
	if evidence.secondary_collector_id == verifier_id:
		result = _fail_result("secondary_collector_verification")
		_emit_verification_result(evidence, verifier_id, result)
		return result

	# Already verified
	if evidence.is_verified():
		result = _fail_result("already_verified")
		_emit_verification_result(evidence, verifier_id, result)
		return result

	# Check staleness - very stale evidence cannot be newly verified
	var staleness := get_evidence_staleness(evidence)
	if staleness == StalenessLevel.VERY_STALE:
		result = _fail_result("too_stale_to_verify")
		evidence.set_verification_meta("staleness_blocked", true)
		_emit_verification_result(evidence, verifier_id, result)
		return result

	# Track staleness on stale evidence
	if staleness == StalenessLevel.STALE:
		evidence.set_verification_meta("late_verification", true)

	# Dispatch to trust-level-specific rules
	match evidence.trust_level:
		EvidenceEnums.TrustLevel.UNFALSIFIABLE:
			result = _verify_unfalsifiable(evidence, verifier_id)
		EvidenceEnums.TrustLevel.HIGH:
			result = _verify_high_trust(evidence, verifier_id)
		EvidenceEnums.TrustLevel.VARIABLE:
			result = _verify_variable_trust(evidence, verifier_id)
		EvidenceEnums.TrustLevel.LOW:
			result = _verify_low_trust(evidence, verifier_id)
		EvidenceEnums.TrustLevel.SABOTAGE_RISK:
			result = _verify_sabotage_risk(evidence, verifier_id)
		_:
			result = _fail_result("unknown_trust_level")

	_emit_verification_result(evidence, verifier_id, result)
	return result


## Attempts to contest evidence. UNFALSIFIABLE evidence cannot be contested.
func try_contest(evidence: Evidence, contester_id: int) -> Dictionary:
	if evidence == null:
		return _fail_result("null_evidence")

	# Self-contesting is never allowed
	if evidence.collector_id == contester_id:
		return _fail_result("self_contest")

	# UNFALSIFIABLE evidence cannot be contested (behavioral ground truth)
	if evidence.trust_level == EvidenceEnums.TrustLevel.UNFALSIFIABLE:
		return _fail_result("unfalsifiable_cannot_contest")

	# Already contested
	if evidence.is_contested():
		return _fail_result("already_contested")

	return _success_result()


## Registers a witness for UNFALSIFIABLE evidence (hunt behavior).
## Auto-verifies if witness count reaches threshold.
func register_witness(evidence: Evidence, witness_id: int) -> void:
	if evidence == null:
		return

	evidence.add_witness(witness_id)

	# Check for auto-verification
	if evidence.trust_level == EvidenceEnums.TrustLevel.UNFALSIFIABLE:
		_check_auto_verification(evidence)


## Registers an operator for LOW trust evidence.
## Tracks different operators for multi-reading verification.
func register_operator(evidence: Evidence, operator_id: int) -> void:
	if evidence == null:
		return

	if not _operator_history.has(evidence.uid):
		_operator_history[evidence.uid] = []

	var operators: Array = _operator_history[evidence.uid]
	if operator_id not in operators:
		operators.append(operator_id)


## Returns the operator history for LOW trust evidence.
func get_operators(evidence: Evidence) -> Array:
	if evidence == null:
		return []
	return _operator_history.get(evidence.uid, [])


## Sets up Ghost Writing buddy system witnesses.
func set_ghost_writing_witnesses(
	evidence: Evidence,
	setup_witness: int,
	result_witness: int
) -> void:
	if evidence == null:
		return

	evidence.setup_witness_id = setup_witness
	evidence.result_witness_id = result_witness


## Reports a sabotage flag for evidence.
func report_sabotage(evidence: Evidence, flag: String) -> void:
	if evidence == null:
		return

	evidence.set_sabotage_flag(flag)


# --- Public API: Staleness ---


## Returns the staleness level for evidence based on age.
func get_evidence_staleness(evidence: Evidence) -> StalenessLevel:
	if evidence == null:
		return StalenessLevel.VERY_STALE

	var age := get_evidence_age(evidence)

	if age < STALENESS_FRESH:
		return StalenessLevel.FRESH
	if age < STALENESS_VERY_STALE:
		return StalenessLevel.STALE
	return StalenessLevel.VERY_STALE


## Returns the age of evidence in seconds since collection.
func get_evidence_age(evidence: Evidence) -> float:
	if evidence == null:
		return 999999.0

	var current_time := Time.get_ticks_msec() / 1000.0
	return current_time - evidence.timestamp


## Returns a human-readable staleness description for UI display.
func get_staleness_description(staleness: StalenessLevel) -> String:
	match staleness:
		StalenessLevel.FRESH:
			return "Fresh - easy to verify"
		StalenessLevel.STALE:
			return "Stale - verification requires explanation"
		StalenessLevel.VERY_STALE:
			return "Very stale - cannot be newly verified"
		_:
			return "Unknown"


## Returns the staleness color for UI display.
func get_staleness_color(staleness: StalenessLevel) -> Color:
	match staleness:
		StalenessLevel.FRESH:
			return Color.GREEN
		StalenessLevel.STALE:
			return Color.YELLOW
		StalenessLevel.VERY_STALE:
			return Color.RED
		_:
			return Color.WHITE


# --- Internal: Trust-Level Verification Rules ---


## UNFALSIFIABLE: Hunt behavior is auto-verified with multiple witnesses.
## Manual verification is allowed but typically unnecessary.
func _verify_unfalsifiable(evidence: Evidence, verifier_id: int) -> Dictionary:
	# If single witness, mark it in metadata but allow verification
	if evidence.get_witness_count() < MIN_WITNESSES_AUTO_VERIFY:
		evidence.set_verification_meta("single_witness", true)

	# UNFALSIFIABLE can always be manually verified (it's ground truth)
	evidence.add_witness(verifier_id)
	return _success_result()


## HIGH: Verified when 2+ players report same evidence in same location/time.
func _verify_high_trust(evidence: Evidence, verifier_id: int) -> Dictionary:
	# Check if verifier has corroborating evidence
	var evidence_manager := _get_evidence_manager()
	if evidence_manager == null:
		return _fail_result("no_evidence_manager")

	# Look for matching evidence from verifier in same location/time
	var verifier_evidence: Array = evidence_manager.get_evidence_by_collector(verifier_id)
	for other: Evidence in verifier_evidence:
		if _is_corroborating_evidence(evidence, other):
			return _success_result({"corroborating_uid": other.uid})

	# Even without corroborating evidence, verifier can manually verify
	# (they saw the same thing but didn't collect)
	return _success_result()


## VARIABLE: Requires third-party verification (watched the screen).
func _verify_variable_trust(evidence: Evidence, verifier_id: int) -> Dictionary:
	# Verifier must not be one of the collectors
	# (already checked in try_verify for collector_id and secondary_collector_id)

	# Record the verifier
	evidence.verifier_id = verifier_id

	# Third party watching the screen counts as verification
	return _success_result({"third_party_witness": verifier_id})


## LOW: Requires repeat reading with different operators.
func _verify_low_trust(evidence: Evidence, verifier_id: int) -> Dictionary:
	var operators := get_operators(evidence)

	# Register this verifier as a potential operator
	register_operator(evidence, verifier_id)

	# Check if we have different operators
	var has_different_operators := operators.size() >= 2
	if has_different_operators:
		evidence.set_verification_meta("different_operators", true)

	# LOW trust can be verified manually but ideally with different operators
	return _success_result({"different_operators": has_different_operators})


## SABOTAGE_RISK: Requires buddy system (witnesses to setup AND result).
func _verify_sabotage_risk(evidence: Evidence, verifier_id: int) -> Dictionary:
	# Check for sabotage flags
	if evidence.has_sabotage_flags():
		var flags: Dictionary = evidence.sabotage_flags
		return _fail_result("sabotage_detected", {"sabotage_flags": flags})

	# Ideal verification: has both setup and result witnesses
	var has_buddy_system := evidence.has_ghost_writing_witnesses()

	# Record the verifier
	evidence.verifier_id = verifier_id

	if has_buddy_system:
		return _success_result({"buddy_system": true, "verifier": verifier_id})

	# Allow verification without buddy system, but note it
	evidence.set_verification_meta("no_buddy_system", true)
	return _success_result({"buddy_system": false, "verifier": verifier_id})


# --- Internal: Auto-Verification ---


func _check_auto_verification(evidence: Evidence) -> void:
	if evidence.is_verified():
		return

	if evidence.get_witness_count() >= MIN_WITNESSES_AUTO_VERIFY:
		var evidence_manager := _get_evidence_manager()
		if evidence_manager:
			# Directly verify through EvidenceManager
			# Use the first non-collector witness as verifier
			for witness_id in evidence.witness_ids:
				if witness_id != evidence.collector_id:
					evidence_manager.verify_evidence(evidence.uid, witness_id)
					auto_verified.emit(evidence, evidence.witness_ids.duplicate())
					break


# --- Internal: Evidence Matching ---


func _is_corroborating_evidence(original: Evidence, other: Evidence) -> bool:
	# Must be same type
	if original.type != other.type:
		return false

	# Must be from different collectors
	if original.collector_id == other.collector_id:
		return false

	# Check location tolerance
	var distance: float = original.location.distance_to(other.location)
	if distance > LOCATION_TOLERANCE:
		return false

	# Check time tolerance
	var time_diff: float = absf(original.timestamp - other.timestamp)
	if time_diff > TIME_TOLERANCE:
		return false

	return true


# --- Internal: Result Builders ---


func _success_result(metadata: Dictionary = {}) -> Dictionary:
	var result := {"success": true, "reason": "", "metadata": metadata}
	return result


func _fail_result(reason: String, metadata: Dictionary = {}) -> Dictionary:
	var result := {"success": false, "reason": reason, "metadata": metadata}
	return result


func _emit_verification_result(
	evidence: Evidence,
	verifier_id: int,
	result: Dictionary
) -> void:
	var success: bool = result.get("success", false)
	verification_attempted.emit(evidence, verifier_id, success)

	if not success:
		var reason: String = result.get("reason", "unknown")
		verification_rule_failed.emit(evidence, reason)


# --- Internal: Event Handlers ---


func _on_evidence_collected(evidence: Evidence) -> void:
	# Register collector as first witness for their own evidence
	evidence.add_witness(evidence.collector_id)

	# For cooperative evidence, add secondary collector as witness
	if evidence.secondary_collector_id != 0:
		evidence.add_witness(evidence.secondary_collector_id)


func _on_evidence_cleared() -> void:
	_operator_history.clear()
