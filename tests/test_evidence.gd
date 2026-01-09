extends GutTest
## Unit tests for Evidence resource class.


# --- Test: Creation ---


func test_create_sets_type() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	assert_eq(evidence.type, EvidenceEnums.EvidenceType.EMF_SIGNATURE)


func test_create_sets_collector_id() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		42,
		Vector3.ZERO
	)
	assert_eq(evidence.collector_id, 42)


func test_create_sets_location() -> void:
	var pos := Vector3(10.5, 2.0, -5.0)
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		pos
	)
	assert_eq(evidence.location, pos)


func test_create_sets_default_quality_to_strong() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	assert_eq(evidence.quality, EvidenceEnums.ReadingQuality.STRONG)


func test_create_with_weak_quality() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO,
		EvidenceEnums.ReadingQuality.WEAK
	)
	assert_eq(evidence.quality, EvidenceEnums.ReadingQuality.WEAK)


func test_create_auto_sets_category() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.GHOST_WRITING,
		1,
		Vector3.ZERO
	)
	assert_eq(evidence.category, EvidenceEnums.EvidenceCategory.TRIGGERED_TEST)


func test_create_auto_sets_trust_level() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.PRISM_READING,
		1,
		Vector3.ZERO
	)
	assert_eq(evidence.trust_level, EvidenceEnums.TrustLevel.LOW)


func test_create_sets_timestamp() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	assert_gt(evidence.timestamp, 0.0)


func test_create_generates_uid() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	assert_ne(evidence.uid, "")


func test_create_default_verification_unverified() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	assert_eq(evidence.verification_state, EvidenceEnums.VerificationState.UNVERIFIED)


# --- Test: Cooperative Evidence ---


func test_create_cooperative_sets_secondary_collector() -> void:
	var evidence := Evidence.create_cooperative(
		EvidenceEnums.EvidenceType.PRISM_READING,
		1,
		2,
		Vector3.ZERO
	)
	assert_eq(evidence.secondary_collector_id, 2)


func test_create_cooperative_sets_primary_collector() -> void:
	var evidence := Evidence.create_cooperative(
		EvidenceEnums.EvidenceType.AURA_PATTERN,
		10,
		20,
		Vector3.ZERO
	)
	assert_eq(evidence.collector_id, 10)


func test_is_cooperative_true_for_prism() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.PRISM_READING,
		1,
		Vector3.ZERO
	)
	assert_true(evidence.is_cooperative())


func test_is_cooperative_true_for_aura() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.AURA_PATTERN,
		1,
		Vector3.ZERO
	)
	assert_true(evidence.is_cooperative())


func test_is_cooperative_false_for_emf() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	assert_false(evidence.is_cooperative())


func test_is_cooperative_false_for_ghost_writing() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.GHOST_WRITING,
		1,
		Vector3.ZERO
	)
	assert_false(evidence.is_cooperative())


# --- Test: Quality Checks ---


func test_is_definitive_true_for_strong() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO,
		EvidenceEnums.ReadingQuality.STRONG
	)
	assert_true(evidence.is_definitive())


func test_is_definitive_false_for_weak() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO,
		EvidenceEnums.ReadingQuality.WEAK
	)
	assert_false(evidence.is_definitive())


# --- Test: Verification ---


func test_verify_changes_state() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	evidence.verify()
	assert_eq(evidence.verification_state, EvidenceEnums.VerificationState.VERIFIED)


func test_is_verified_true_after_verify() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	evidence.verify()
	assert_true(evidence.is_verified())


func test_contest_changes_state() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	evidence.contest()
	assert_eq(evidence.verification_state, EvidenceEnums.VerificationState.CONTESTED)


func test_is_contested_true_after_contest() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	evidence.contest()
	assert_true(evidence.is_contested())


func test_reset_verification_returns_to_unverified() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	evidence.verify()
	evidence.reset_verification()
	assert_eq(evidence.verification_state, EvidenceEnums.VerificationState.UNVERIFIED)


# --- Test: Display Names ---


func test_get_display_name_emf() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	assert_eq(evidence.get_display_name(), "EMF Level 5")


func test_get_display_name_freezing() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.FREEZING_TEMPERATURE,
		1,
		Vector3.ZERO
	)
	assert_eq(evidence.get_display_name(), "Freezing Temperature")


func test_get_display_name_ghost_writing() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.GHOST_WRITING,
		1,
		Vector3.ZERO
	)
	assert_eq(evidence.get_display_name(), "Ghost Writing")


func test_get_category_name() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	assert_eq(evidence.get_category_name(), "Equipment-Derived")


func test_get_trust_name() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.GHOST_WRITING,
		1,
		Vector3.ZERO
	)
	assert_eq(evidence.get_trust_name(), "Sabotage Risk")


# --- Test: Network Serialization ---


func test_to_network_dict_includes_uid() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	var data := evidence.to_network_dict()
	assert_eq(data.uid, evidence.uid)


func test_to_network_dict_includes_type() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.GHOST_WRITING,
		1,
		Vector3.ZERO
	)
	var data := evidence.to_network_dict()
	assert_eq(data.type, EvidenceEnums.EvidenceType.GHOST_WRITING)


func test_to_network_dict_includes_location() -> void:
	var pos := Vector3(1.0, 2.0, 3.0)
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		pos
	)
	var data := evidence.to_network_dict()
	assert_eq(data.location_x, 1.0)
	assert_eq(data.location_y, 2.0)
	assert_eq(data.location_z, 3.0)


func test_from_network_dict_restores_type() -> void:
	var original := Evidence.create(
		EvidenceEnums.EvidenceType.HUNT_BEHAVIOR,
		5,
		Vector3.ZERO
	)
	var data := original.to_network_dict()
	var restored := Evidence.from_network_dict(data)
	assert_eq(restored.type, EvidenceEnums.EvidenceType.HUNT_BEHAVIOR)


func test_from_network_dict_restores_collector() -> void:
	var original := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		99,
		Vector3.ZERO
	)
	var data := original.to_network_dict()
	var restored := Evidence.from_network_dict(data)
	assert_eq(restored.collector_id, 99)


func test_from_network_dict_restores_location() -> void:
	var pos := Vector3(-5.5, 10.0, 3.14)
	var original := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		pos
	)
	var data := original.to_network_dict()
	var restored := Evidence.from_network_dict(data)
	assert_almost_eq(restored.location.x, -5.5, 0.01)
	assert_almost_eq(restored.location.y, 10.0, 0.01)
	assert_almost_eq(restored.location.z, 3.14, 0.01)


func test_from_network_dict_restores_quality() -> void:
	var original := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO,
		EvidenceEnums.ReadingQuality.WEAK
	)
	var data := original.to_network_dict()
	var restored := Evidence.from_network_dict(data)
	assert_eq(restored.quality, EvidenceEnums.ReadingQuality.WEAK)


func test_from_network_dict_restores_verification_state() -> void:
	var original := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	original.verify()
	var data := original.to_network_dict()
	var restored := Evidence.from_network_dict(data)
	assert_eq(restored.verification_state, EvidenceEnums.VerificationState.VERIFIED)


func test_roundtrip_cooperative_evidence() -> void:
	var original := Evidence.create_cooperative(
		EvidenceEnums.EvidenceType.PRISM_READING,
		10,
		20,
		Vector3(1, 2, 3)
	)
	var data := original.to_network_dict()
	var restored := Evidence.from_network_dict(data)
	assert_eq(restored.collector_id, 10)
	assert_eq(restored.secondary_collector_id, 20)


# --- Test: Equality ---


func test_equals_same_uid() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	var copy := Evidence.from_network_dict(evidence.to_network_dict())
	assert_true(evidence.equals(copy))


func test_equals_different_uid() -> void:
	var evidence1 := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	var evidence2 := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	assert_false(evidence1.equals(evidence2))


func test_equals_null_returns_false() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	assert_false(evidence.equals(null))


# --- Test: To String ---


func test_to_string_contains_type() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO
	)
	var str_rep := str(evidence)
	assert_true(str_rep.contains("EMF Level 5"))


func test_to_string_contains_quality() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		1,
		Vector3.ZERO,
		EvidenceEnums.ReadingQuality.WEAK
	)
	var str_rep := str(evidence)
	assert_true(str_rep.contains("WEAK"))
