extends GutTest
## Unit tests for ContaminatedEvidence decay system.
##
## Tests decay state transitions based on time elapsed since creation.
## Decay timing: 0-60s (PLANTED), 60-120s (UNSTABLE), 120-180s (DEGRADED), 180+ (EXPIRED)

const ContaminatedEvidenceScript := preload("res://src/cultist/contaminated_evidence.gd")
const CultistEnumsScript := preload("res://src/cultist/cultist_enums.gd")


func _create_evidence(offset_seconds: float = 0.0) -> Resource:
	var evidence: Resource = ContaminatedEvidenceScript.create_contaminated(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,  # cultist_id
		Vector3.ZERO,
		CultistEnumsScript.AbilityType.EMF_SPOOF
	)
	# Adjust timestamp to simulate time passing
	if offset_seconds != 0.0 and evidence:
		var current_time: float = evidence.creation_timestamp
		evidence.creation_timestamp = current_time - offset_seconds
	return evidence


# --- Test: PLANTED State (0-60 seconds) ---


func test_planted_state_at_creation() -> void:
	var evidence := _create_evidence(0.0)
	assert_not_null(evidence, "Evidence should be created")

	var state: int = evidence.get_decay_state()
	assert_eq(state, CultistEnumsScript.DecayState.PLANTED, "New evidence should be PLANTED")


func test_planted_state_at_30_seconds() -> void:
	var evidence := _create_evidence(30.0)
	assert_not_null(evidence, "Evidence should be created")

	var state: int = evidence.get_decay_state()
	assert_eq(state, CultistEnumsScript.DecayState.PLANTED, "30s evidence should be PLANTED")


func test_planted_state_at_59_seconds() -> void:
	var evidence := _create_evidence(59.0)
	assert_not_null(evidence, "Evidence should be created")

	var state: int = evidence.get_decay_state()
	assert_eq(state, CultistEnumsScript.DecayState.PLANTED, "59s evidence should be PLANTED")


# --- Test: UNSTABLE State (60-120 seconds) ---


func test_unstable_state_at_60_seconds() -> void:
	var evidence := _create_evidence(60.0)
	assert_not_null(evidence, "Evidence should be created")

	var state: int = evidence.get_decay_state()
	assert_eq(state, CultistEnumsScript.DecayState.UNSTABLE, "60s evidence should be UNSTABLE")


func test_unstable_state_at_90_seconds() -> void:
	var evidence := _create_evidence(90.0)
	assert_not_null(evidence, "Evidence should be created")

	var state: int = evidence.get_decay_state()
	assert_eq(state, CultistEnumsScript.DecayState.UNSTABLE, "90s evidence should be UNSTABLE")


func test_unstable_state_at_119_seconds() -> void:
	var evidence := _create_evidence(119.0)
	assert_not_null(evidence, "Evidence should be created")

	var state: int = evidence.get_decay_state()
	assert_eq(state, CultistEnumsScript.DecayState.UNSTABLE, "119s evidence should be UNSTABLE")


# --- Test: DEGRADED State (120-180 seconds) ---


func test_degraded_state_at_120_seconds() -> void:
	var evidence := _create_evidence(120.0)
	assert_not_null(evidence, "Evidence should be created")

	var state: int = evidence.get_decay_state()
	assert_eq(state, CultistEnumsScript.DecayState.DEGRADED, "120s evidence should be DEGRADED")


func test_degraded_state_at_150_seconds() -> void:
	var evidence := _create_evidence(150.0)
	assert_not_null(evidence, "Evidence should be created")

	var state: int = evidence.get_decay_state()
	assert_eq(state, CultistEnumsScript.DecayState.DEGRADED, "150s evidence should be DEGRADED")


func test_degraded_state_at_179_seconds() -> void:
	var evidence := _create_evidence(179.0)
	assert_not_null(evidence, "Evidence should be created")

	var state: int = evidence.get_decay_state()
	assert_eq(state, CultistEnumsScript.DecayState.DEGRADED, "179s evidence should be DEGRADED")


# --- Test: EXPIRED State (180+ seconds) ---


func test_expired_state_at_180_seconds() -> void:
	var evidence := _create_evidence(180.0)
	assert_not_null(evidence, "Evidence should be created")

	var state: int = evidence.get_decay_state()
	assert_eq(state, CultistEnumsScript.DecayState.EXPIRED, "180s evidence should be EXPIRED")


func test_expired_state_at_300_seconds() -> void:
	var evidence := _create_evidence(300.0)
	assert_not_null(evidence, "Evidence should be created")

	var state: int = evidence.get_decay_state()
	assert_eq(state, CultistEnumsScript.DecayState.EXPIRED, "300s evidence should be EXPIRED")


func test_expired_state_at_1000_seconds() -> void:
	var evidence := _create_evidence(1000.0)
	assert_not_null(evidence, "Evidence should be created")

	var state: int = evidence.get_decay_state()
	assert_eq(state, CultistEnumsScript.DecayState.EXPIRED, "1000s evidence should be EXPIRED")


# --- Test: Decay State Calculation ---


func test_get_elapsed_time() -> void:
	var evidence := _create_evidence(45.0)
	assert_not_null(evidence, "Evidence should be created")

	var elapsed: float = evidence.get_elapsed_time()
	# Allow some tolerance for test execution time
	assert_almost_eq(elapsed, 45.0, 1.0, "Elapsed time should be ~45 seconds")


func test_get_decay_progress_planted() -> void:
	var evidence := _create_evidence(30.0)  # 30s = 30/180 = ~0.166
	assert_not_null(evidence, "Evidence should be created")

	var progress: float = evidence.get_decay_progress()
	# Progress is linear from 0-1 over full 180s decay period
	assert_almost_eq(progress, 0.166, 0.02, "Decay progress at 30s should be ~0.166")


func test_get_decay_progress_unstable() -> void:
	var evidence := _create_evidence(90.0)  # Half through UNSTABLE
	assert_not_null(evidence, "Evidence should be created")

	var progress: float = evidence.get_decay_progress()
	# Unstable is at ~0.5 through total decay (90/180)
	assert_almost_eq(progress, 0.5, 0.1, "Decay progress should be ~0.5 in UNSTABLE")


func test_get_decay_progress_expired() -> void:
	var evidence := _create_evidence(200.0)  # Well past expired
	assert_not_null(evidence, "Evidence should be created")

	var progress: float = evidence.get_decay_progress()
	assert_eq(progress, 1.0, "Decay progress should be 1.0 when EXPIRED")


# --- Test: is_contaminated Flag ---


func test_evidence_is_contaminated() -> void:
	var evidence := _create_evidence(0.0)
	assert_not_null(evidence, "Evidence should be created")

	assert_true(evidence.is_contaminated, "Contaminated evidence should have flag set")


func test_evidence_planted_by_set() -> void:
	var evidence := _create_evidence(0.0)
	assert_not_null(evidence, "Evidence should be created")

	assert_eq(evidence.planted_by, 1, "planted_by should be set to cultist_id")


func test_evidence_source_ability_set() -> void:
	var evidence := _create_evidence(0.0)
	assert_not_null(evidence, "Evidence should be created")

	assert_eq(
		evidence.source_ability,
		CultistEnumsScript.AbilityType.EMF_SPOOF,
		"source_ability should be set"
	)


# --- Test: update_decay Method ---


func test_update_decay_returns_true_on_state_change() -> void:
	# Create evidence that's about to transition
	var evidence := _create_evidence(59.9)
	assert_not_null(evidence, "Evidence should be created")

	# Manually adjust timestamp to force transition
	evidence.creation_timestamp = Time.get_unix_time_from_system() - 60.1

	var changed: bool = evidence.update_decay()
	assert_true(changed, "update_decay should return true when state changes")


func test_update_decay_returns_false_when_stable() -> void:
	var evidence := _create_evidence(30.0)
	assert_not_null(evidence, "Evidence should be created")

	var changed: bool = evidence.update_decay()
	assert_false(changed, "update_decay should return false when state unchanged")


# --- Test: Metadata ---


func test_set_and_get_metadata() -> void:
	var evidence := _create_evidence(0.0)
	assert_not_null(evidence, "Evidence should be created")

	evidence.set_metadata("test_key", "test_value")
	var value: Variant = evidence.get_metadata("test_key")

	assert_eq(value, "test_value", "Should retrieve metadata value")


func test_get_missing_metadata_returns_null() -> void:
	var evidence := _create_evidence(0.0)
	assert_not_null(evidence, "Evidence should be created")

	var value: Variant = evidence.get_metadata("nonexistent_key")

	assert_null(value, "Missing metadata should return null")
