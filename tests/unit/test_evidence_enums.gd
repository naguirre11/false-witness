extends GutTest
## Unit tests for EvidenceEnums helper methods.


# --- Test: Category Mapping ---


func test_get_category_emf_is_equipment_derived() -> void:
	var category := EvidenceEnums.get_category(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	assert_eq(category, EvidenceEnums.EvidenceCategory.EQUIPMENT_DERIVED)


func test_get_category_freezing_is_equipment_derived() -> void:
	var category := EvidenceEnums.get_category(EvidenceEnums.EvidenceType.FREEZING_TEMPERATURE)
	assert_eq(category, EvidenceEnums.EvidenceCategory.EQUIPMENT_DERIVED)


func test_get_category_prism_is_equipment_derived() -> void:
	var category := EvidenceEnums.get_category(EvidenceEnums.EvidenceType.PRISM_READING)
	assert_eq(category, EvidenceEnums.EvidenceCategory.EQUIPMENT_DERIVED)


func test_get_category_aura_is_equipment_derived() -> void:
	var category := EvidenceEnums.get_category(EvidenceEnums.EvidenceType.AURA_PATTERN)
	assert_eq(category, EvidenceEnums.EvidenceCategory.EQUIPMENT_DERIVED)


func test_get_category_ghost_writing_is_triggered_test() -> void:
	var category := EvidenceEnums.get_category(EvidenceEnums.EvidenceType.GHOST_WRITING)
	assert_eq(category, EvidenceEnums.EvidenceCategory.TRIGGERED_TEST)


func test_get_category_visual_is_readily_apparent() -> void:
	var category := EvidenceEnums.get_category(EvidenceEnums.EvidenceType.VISUAL_MANIFESTATION)
	assert_eq(category, EvidenceEnums.EvidenceCategory.READILY_APPARENT)


func test_get_category_physical_is_readily_apparent() -> void:
	var category := EvidenceEnums.get_category(EvidenceEnums.EvidenceType.PHYSICAL_INTERACTION)
	assert_eq(category, EvidenceEnums.EvidenceCategory.READILY_APPARENT)


func test_get_category_hunt_behavior_is_behavior_based() -> void:
	var category := EvidenceEnums.get_category(EvidenceEnums.EvidenceType.HUNT_BEHAVIOR)
	assert_eq(category, EvidenceEnums.EvidenceCategory.BEHAVIOR_BASED)


# --- Test: Trust Level Mapping ---


func test_get_trust_level_hunt_behavior_is_unfalsifiable() -> void:
	var trust := EvidenceEnums.get_trust_level(EvidenceEnums.EvidenceType.HUNT_BEHAVIOR)
	assert_eq(trust, EvidenceEnums.TrustLevel.UNFALSIFIABLE)


func test_get_trust_level_emf_is_high() -> void:
	var trust := EvidenceEnums.get_trust_level(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	assert_eq(trust, EvidenceEnums.TrustLevel.HIGH)


func test_get_trust_level_freezing_is_high() -> void:
	var trust := EvidenceEnums.get_trust_level(EvidenceEnums.EvidenceType.FREEZING_TEMPERATURE)
	assert_eq(trust, EvidenceEnums.TrustLevel.HIGH)


func test_get_trust_level_visual_is_high() -> void:
	var trust := EvidenceEnums.get_trust_level(EvidenceEnums.EvidenceType.VISUAL_MANIFESTATION)
	assert_eq(trust, EvidenceEnums.TrustLevel.HIGH)


func test_get_trust_level_physical_is_high() -> void:
	var trust := EvidenceEnums.get_trust_level(EvidenceEnums.EvidenceType.PHYSICAL_INTERACTION)
	assert_eq(trust, EvidenceEnums.TrustLevel.HIGH)


func test_get_trust_level_aura_is_variable() -> void:
	var trust := EvidenceEnums.get_trust_level(EvidenceEnums.EvidenceType.AURA_PATTERN)
	assert_eq(trust, EvidenceEnums.TrustLevel.VARIABLE)


func test_get_trust_level_prism_is_low() -> void:
	var trust := EvidenceEnums.get_trust_level(EvidenceEnums.EvidenceType.PRISM_READING)
	assert_eq(trust, EvidenceEnums.TrustLevel.LOW)


func test_get_trust_level_ghost_writing_is_sabotage_risk() -> void:
	var trust := EvidenceEnums.get_trust_level(EvidenceEnums.EvidenceType.GHOST_WRITING)
	assert_eq(trust, EvidenceEnums.TrustLevel.SABOTAGE_RISK)


# --- Test: Cooperative Check ---


func test_is_cooperative_prism_true() -> void:
	assert_true(EvidenceEnums.is_cooperative(EvidenceEnums.EvidenceType.PRISM_READING))


func test_is_cooperative_aura_true() -> void:
	assert_true(EvidenceEnums.is_cooperative(EvidenceEnums.EvidenceType.AURA_PATTERN))


func test_is_cooperative_emf_false() -> void:
	assert_false(EvidenceEnums.is_cooperative(EvidenceEnums.EvidenceType.EMF_SIGNATURE))


func test_is_cooperative_freezing_false() -> void:
	assert_false(EvidenceEnums.is_cooperative(EvidenceEnums.EvidenceType.FREEZING_TEMPERATURE))


func test_is_cooperative_ghost_writing_false() -> void:
	assert_false(EvidenceEnums.is_cooperative(EvidenceEnums.EvidenceType.GHOST_WRITING))


func test_is_cooperative_visual_false() -> void:
	assert_false(EvidenceEnums.is_cooperative(EvidenceEnums.EvidenceType.VISUAL_MANIFESTATION))


func test_is_cooperative_physical_false() -> void:
	assert_false(EvidenceEnums.is_cooperative(EvidenceEnums.EvidenceType.PHYSICAL_INTERACTION))


func test_is_cooperative_hunt_behavior_false() -> void:
	assert_false(EvidenceEnums.is_cooperative(EvidenceEnums.EvidenceType.HUNT_BEHAVIOR))


# --- Test: Display Names ---


func test_get_evidence_name_emf() -> void:
	var name := EvidenceEnums.get_evidence_name(EvidenceEnums.EvidenceType.EMF_SIGNATURE)
	assert_eq(name, "EMF Level 5")


func test_get_evidence_name_freezing() -> void:
	var name := EvidenceEnums.get_evidence_name(EvidenceEnums.EvidenceType.FREEZING_TEMPERATURE)
	assert_eq(name, "Freezing Temperature")


func test_get_evidence_name_prism() -> void:
	var name := EvidenceEnums.get_evidence_name(EvidenceEnums.EvidenceType.PRISM_READING)
	assert_eq(name, "Spectral Prism Reading")


func test_get_evidence_name_aura() -> void:
	var name := EvidenceEnums.get_evidence_name(EvidenceEnums.EvidenceType.AURA_PATTERN)
	assert_eq(name, "Aura Pattern")


func test_get_evidence_name_ghost_writing() -> void:
	var name := EvidenceEnums.get_evidence_name(EvidenceEnums.EvidenceType.GHOST_WRITING)
	assert_eq(name, "Ghost Writing")


func test_get_evidence_name_visual() -> void:
	var name := EvidenceEnums.get_evidence_name(EvidenceEnums.EvidenceType.VISUAL_MANIFESTATION)
	assert_eq(name, "Visual Manifestation")


func test_get_evidence_name_physical() -> void:
	var name := EvidenceEnums.get_evidence_name(EvidenceEnums.EvidenceType.PHYSICAL_INTERACTION)
	assert_eq(name, "Physical Interaction")


func test_get_evidence_name_hunt() -> void:
	var name := EvidenceEnums.get_evidence_name(EvidenceEnums.EvidenceType.HUNT_BEHAVIOR)
	assert_eq(name, "Hunt Behavior")


func test_get_category_name_readily_apparent() -> void:
	var name := EvidenceEnums.get_category_name(EvidenceEnums.EvidenceCategory.READILY_APPARENT)
	assert_eq(name, "Readily Apparent")


func test_get_category_name_equipment_derived() -> void:
	var name := EvidenceEnums.get_category_name(EvidenceEnums.EvidenceCategory.EQUIPMENT_DERIVED)
	assert_eq(name, "Equipment-Derived")


func test_get_category_name_triggered_test() -> void:
	var name := EvidenceEnums.get_category_name(EvidenceEnums.EvidenceCategory.TRIGGERED_TEST)
	assert_eq(name, "Triggered Test")


func test_get_category_name_behavior_based() -> void:
	var name := EvidenceEnums.get_category_name(EvidenceEnums.EvidenceCategory.BEHAVIOR_BASED)
	assert_eq(name, "Behavior-Based")


func test_get_trust_name_unfalsifiable() -> void:
	var name := EvidenceEnums.get_trust_name(EvidenceEnums.TrustLevel.UNFALSIFIABLE)
	assert_eq(name, "Unfalsifiable")


func test_get_trust_name_high() -> void:
	var name := EvidenceEnums.get_trust_name(EvidenceEnums.TrustLevel.HIGH)
	assert_eq(name, "High Trust")


func test_get_trust_name_variable() -> void:
	var name := EvidenceEnums.get_trust_name(EvidenceEnums.TrustLevel.VARIABLE)
	assert_eq(name, "Variable Trust")


func test_get_trust_name_low() -> void:
	var name := EvidenceEnums.get_trust_name(EvidenceEnums.TrustLevel.LOW)
	assert_eq(name, "Low Trust")


func test_get_trust_name_sabotage_risk() -> void:
	var name := EvidenceEnums.get_trust_name(EvidenceEnums.TrustLevel.SABOTAGE_RISK)
	assert_eq(name, "Sabotage Risk")


func test_get_verification_name_unverified() -> void:
	var name := EvidenceEnums.get_verification_name(EvidenceEnums.VerificationState.UNVERIFIED)
	assert_eq(name, "Unverified")


func test_get_verification_name_verified() -> void:
	var name := EvidenceEnums.get_verification_name(EvidenceEnums.VerificationState.VERIFIED)
	assert_eq(name, "Verified")


func test_get_verification_name_contested() -> void:
	var name := EvidenceEnums.get_verification_name(EvidenceEnums.VerificationState.CONTESTED)
	assert_eq(name, "Contested")


func test_get_quality_name_strong() -> void:
	var name := EvidenceEnums.get_quality_name(EvidenceEnums.ReadingQuality.STRONG)
	assert_eq(name, "Strong")


func test_get_quality_name_weak() -> void:
	var name := EvidenceEnums.get_quality_name(EvidenceEnums.ReadingQuality.WEAK)
	assert_eq(name, "Weak")


# --- Test: Category Distribution ---


func test_equipment_derived_count_is_four() -> void:
	var count := 0
	for evidence_type: int in EvidenceEnums.EvidenceType.values():
		var category := EvidenceEnums.get_category(evidence_type as EvidenceEnums.EvidenceType)
		if category == EvidenceEnums.EvidenceCategory.EQUIPMENT_DERIVED:
			count += 1
	assert_eq(count, 4, "Expected 4 Equipment-Derived evidence types")


func test_readily_apparent_count_is_two() -> void:
	var count := 0
	for evidence_type: int in EvidenceEnums.EvidenceType.values():
		var category := EvidenceEnums.get_category(evidence_type as EvidenceEnums.EvidenceType)
		if category == EvidenceEnums.EvidenceCategory.READILY_APPARENT:
			count += 1
	assert_eq(count, 2, "Expected 2 Readily-Apparent evidence types")


func test_triggered_test_count_is_one() -> void:
	var count := 0
	for evidence_type: int in EvidenceEnums.EvidenceType.values():
		var category := EvidenceEnums.get_category(evidence_type as EvidenceEnums.EvidenceType)
		if category == EvidenceEnums.EvidenceCategory.TRIGGERED_TEST:
			count += 1
	assert_eq(count, 1, "Expected 1 Triggered Test evidence type")


func test_behavior_based_count_is_one() -> void:
	var count := 0
	for evidence_type: int in EvidenceEnums.EvidenceType.values():
		var category := EvidenceEnums.get_category(evidence_type as EvidenceEnums.EvidenceType)
		if category == EvidenceEnums.EvidenceCategory.BEHAVIOR_BASED:
			count += 1
	assert_eq(count, 1, "Expected 1 Behavior-Based evidence type")


func test_total_evidence_types_is_eight() -> void:
	var count: int = EvidenceEnums.EvidenceType.size()
	assert_eq(count, 8, "Expected exactly 8 evidence types")
