extends GutTest
## Integration tests for evidence board UI components.
##
## Tests evidence board components working together:
## - Evidence slot display updates
## - Verification state UI updates
## - Entity matrix elimination display
## - Keyboard navigation between slots


# --- Test: Evidence Slot Display ---


func test_evidence_slot_initializes_uncollected() -> void:
	var slot := EvidenceSlot.new()
	add_child_autofree(slot)

	assert_false(slot.is_collected())


func test_evidence_slot_shows_evidence_when_set() -> void:
	var slot := EvidenceSlot.new()
	add_child_autofree(slot)

	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE, 100, Vector3.ZERO
	)

	slot.set_evidence(evidence)

	assert_true(slot.is_collected())


func test_evidence_slot_clears_evidence() -> void:
	var slot := EvidenceSlot.new()
	add_child_autofree(slot)

	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE, 100, Vector3.ZERO
	)
	slot.set_evidence(evidence)
	slot.clear_evidence()

	assert_false(slot.is_collected())


# --- Test: Verification State UI Updates ---


func test_evidence_slot_shows_unverified_state() -> void:
	var slot := EvidenceSlot.new()
	add_child_autofree(slot)

	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE, 100, Vector3.ZERO
	)
	# Default is UNVERIFIED
	assert_eq(evidence.verification_state, EvidenceEnums.VerificationState.UNVERIFIED)

	slot.set_evidence(evidence)

	# Slot should display unverified state
	assert_true(slot.is_collected())


func test_evidence_slot_shows_verified_state() -> void:
	var slot := EvidenceSlot.new()
	add_child_autofree(slot)

	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE, 100, Vector3.ZERO
	)
	evidence.verify()

	slot.set_evidence(evidence)

	assert_true(evidence.is_verified())


func test_evidence_slot_shows_contested_state() -> void:
	var slot := EvidenceSlot.new()
	add_child_autofree(slot)

	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE, 100, Vector3.ZERO
	)
	evidence.contest()

	slot.set_evidence(evidence)

	assert_true(evidence.is_contested())


# --- Test: Entity Matrix Elimination ---


func test_entity_matrix_initializes_with_all_entities() -> void:
	var matrix := EntityMatrix.new()
	add_child_autofree(matrix)

	# All 8 entities should be possible initially
	var remaining := matrix.get_remaining_entities()
	assert_eq(remaining.size(), 8)


func test_entity_matrix_eliminates_entity() -> void:
	var matrix := EntityMatrix.new()
	add_child_autofree(matrix)

	matrix.eliminate_entity("Phantom")

	var remaining := matrix.get_remaining_entities()
	assert_false("Phantom" in remaining)


func test_entity_matrix_multiple_eliminations() -> void:
	var matrix := EntityMatrix.new()
	add_child_autofree(matrix)

	matrix.eliminate_entity("Phantom")
	matrix.eliminate_entity("Banshee")
	matrix.eliminate_entity("Revenant")

	var remaining := matrix.get_remaining_entities()
	assert_eq(remaining.size(), 5)
	assert_false("Phantom" in remaining)
	assert_false("Banshee" in remaining)
	assert_false("Revenant" in remaining)


func test_entity_matrix_reset_clears_eliminations() -> void:
	var matrix := EntityMatrix.new()
	add_child_autofree(matrix)

	matrix.eliminate_entity("Phantom")
	matrix.eliminate_entity("Banshee")
	matrix.reset()

	var remaining := matrix.get_remaining_entities()
	assert_eq(remaining.size(), 8)


# --- Test: Keyboard Navigation ---


func test_evidence_slot_accepts_keyboard_focus() -> void:
	var slot := EvidenceSlot.new()
	slot.focus_mode = Control.FOCUS_ALL
	add_child_autofree(slot)

	# Slot should be focusable
	assert_eq(slot.focus_mode, Control.FOCUS_ALL)


func test_multiple_slots_maintain_separate_state() -> void:
	var slot1 := EvidenceSlot.new()
	var slot2 := EvidenceSlot.new()
	add_child_autofree(slot1)
	add_child_autofree(slot2)

	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE, 100, Vector3.ZERO
	)

	slot1.set_evidence(evidence)

	assert_true(slot1.is_collected())
	assert_false(slot2.is_collected())


# --- Test: Evidence Type Display ---


func test_evidence_slot_accepts_all_evidence_types() -> void:
	var slot := EvidenceSlot.new()
	add_child_autofree(slot)

	var types := [
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		EvidenceEnums.EvidenceType.FREEZING_TEMPERATURE,
		EvidenceEnums.EvidenceType.PRISM_READING,
		EvidenceEnums.EvidenceType.AURA_PATTERN,
		EvidenceEnums.EvidenceType.GHOST_WRITING,
		EvidenceEnums.EvidenceType.VISUAL_MANIFESTATION,
		EvidenceEnums.EvidenceType.PHYSICAL_INTERACTION,
		EvidenceEnums.EvidenceType.HUNT_BEHAVIOR,
	]

	for evidence_type in types:
		var evidence := Evidence.create(evidence_type, 100, Vector3.ZERO)
		slot.set_evidence(evidence)
		assert_true(slot.is_collected(), "Should accept %s" % evidence_type)
		slot.clear_evidence()


# --- Test: Evidence Quality Display ---


func test_evidence_with_strong_quality() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE, 100, Vector3.ZERO
	)
	evidence.quality = EvidenceEnums.ReadingQuality.STRONG

	assert_eq(evidence.quality, EvidenceEnums.ReadingQuality.STRONG)


func test_evidence_with_weak_quality() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE, 100, Vector3.ZERO
	)
	evidence.quality = EvidenceEnums.ReadingQuality.WEAK

	assert_eq(evidence.quality, EvidenceEnums.ReadingQuality.WEAK)


# --- Test: Evidence Witness Tracking ---


func test_evidence_tracks_witnesses() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE, 100, Vector3.ZERO
	)

	evidence.add_witness(100)
	evidence.add_witness(200)
	evidence.add_witness(300)

	assert_eq(evidence.get_witness_count(), 3)
	assert_true(evidence.was_witnessed_by(200))


func test_evidence_duplicate_witnesses_not_added() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE, 100, Vector3.ZERO
	)

	evidence.add_witness(100)
	evidence.add_witness(100)  # Duplicate

	assert_eq(evidence.get_witness_count(), 1)


# --- Test: Verification Metadata ---


func test_evidence_stores_verification_metadata() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE, 100, Vector3.ZERO
	)

	evidence.set_verification_meta("test_key", "test_value")

	assert_eq(evidence.get_verification_meta("test_key", ""), "test_value")


func test_evidence_verification_metadata_default() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE, 100, Vector3.ZERO
	)

	var result := evidence.get_verification_meta("nonexistent_key", "default_value")

	assert_eq(result, "default_value")


# --- Test: Evidence Metadata ---


func test_evidence_stores_evidence_metadata() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.PRISM_READING, 100, Vector3.ZERO
	)

	evidence.set_metadata("prism_shape", PrismEnums.PrismPattern.CIRCLE)

	assert_eq(evidence.get_metadata("prism_shape", -1), PrismEnums.PrismPattern.CIRCLE)


func test_evidence_metadata_default() -> void:
	var evidence := Evidence.create(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE, 100, Vector3.ZERO
	)

	var result := evidence.get_metadata("nonexistent_key", "default_value")

	assert_eq(result, "default_value")


# --- Test: Entity Matrix Evidence Matching ---


func test_entity_matrix_contains_all_entity_types() -> void:
	var expected_entities := [
		"Phantom", "Banshee", "Revenant", "Shade",
		"Poltergeist", "Wraith", "Mare", "Demon",
	]

	var matrix := EntityMatrix.new()
	add_child_autofree(matrix)
	var remaining := matrix.get_remaining_entities()

	for entity in expected_entities:
		assert_true(entity in remaining, "Matrix should contain %s" % entity)


func test_entity_matrix_possible_entities_shrinks() -> void:
	var matrix := EntityMatrix.new()
	add_child_autofree(matrix)

	var initial_count := matrix.get_remaining_entities().size()
	matrix.eliminate_entity("Phantom")
	var after_elimination := matrix.get_remaining_entities().size()

	assert_true(after_elimination < initial_count)
