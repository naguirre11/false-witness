extends GutTest
## Unit tests for ConflictDetector behavioral conflict detection.
##
## Tests conflict detection between equipment readings and observed behavior:
## - Prism shape vs behavioral category mismatch
## - Aura color vs behavioral temperament mismatch
## - Conflict metadata and descriptions
## - Multiple conflicts on same evidence


# --- Test Evidence Helper ---


func _create_evidence_with_metadata(
	evidence_type: EvidenceEnums.EvidenceType,
	collector_id: int,
	metadata_key: String,
	metadata_value: Variant
) -> Evidence:
	var evidence := Evidence.create(evidence_type, collector_id, Vector3.ZERO)
	evidence.set_metadata(metadata_key, metadata_value)
	return evidence


# --- Test: Prism vs Behavior Conflict Detection ---


func test_prism_circle_conflicts_with_passive_behavior() -> void:
	# CIRCLE shape implies AGGRESSIVE behavior
	# If we observe PASSIVE behavior, there's a conflict
	var detector := ConflictDetectorDouble.new()
	add_child_autofree(detector)

	# Record observed passive behavior
	detector.record_observed_behavior(ConflictDetectorDouble.BehaviorCategory.PASSIVE)

	# Create Prism evidence with CIRCLE shape
	var evidence := _create_evidence_with_metadata(
		EvidenceEnums.EvidenceType.PRISM_READING, 100,
		"prism_shape", PrismEnums.PrismPattern.CIRCLE
	)

	var result := detector.check_conflict(evidence)

	assert_true(result.get("has_conflict", false))
	assert_true(result.get("conflict_description", "").length() > 0)


func test_prism_triangle_conflicts_with_aggressive_behavior() -> void:
	# TRIANGLE shape implies PASSIVE behavior
	# If we observe AGGRESSIVE behavior, there's a conflict
	var detector := ConflictDetectorDouble.new()
	add_child_autofree(detector)

	detector.record_observed_behavior(ConflictDetectorDouble.BehaviorCategory.AGGRESSIVE)

	var evidence := _create_evidence_with_metadata(
		EvidenceEnums.EvidenceType.PRISM_READING, 100,
		"prism_shape", PrismEnums.PrismPattern.TRIANGLE
	)

	var result := detector.check_conflict(evidence)

	assert_true(result.get("has_conflict", false))


func test_prism_circle_no_conflict_with_aggressive_behavior() -> void:
	# CIRCLE shape implies AGGRESSIVE behavior
	# If we observe AGGRESSIVE behavior, there's no conflict
	var detector := ConflictDetectorDouble.new()
	add_child_autofree(detector)

	detector.record_observed_behavior(ConflictDetectorDouble.BehaviorCategory.AGGRESSIVE)

	var evidence := _create_evidence_with_metadata(
		EvidenceEnums.EvidenceType.PRISM_READING, 100,
		"prism_shape", PrismEnums.PrismPattern.CIRCLE
	)

	var result := detector.check_conflict(evidence)

	assert_false(result.get("has_conflict", true))


func test_prism_triangle_no_conflict_with_passive_behavior() -> void:
	# TRIANGLE shape implies PASSIVE behavior
	# If we observe PASSIVE behavior, there's no conflict
	var detector := ConflictDetectorDouble.new()
	add_child_autofree(detector)

	detector.record_observed_behavior(ConflictDetectorDouble.BehaviorCategory.PASSIVE)

	var evidence := _create_evidence_with_metadata(
		EvidenceEnums.EvidenceType.PRISM_READING, 100,
		"prism_shape", PrismEnums.PrismPattern.TRIANGLE
	)

	var result := detector.check_conflict(evidence)

	assert_false(result.get("has_conflict", true))


# --- Test: Aura vs Behavior Conflict Detection ---


func test_aura_hot_red_conflicts_with_passive_behavior() -> void:
	# HOT_RED color implies AGGRESSIVE behavior
	# If we observe PASSIVE behavior, there's a conflict
	var detector := ConflictDetectorDouble.new()
	add_child_autofree(detector)

	detector.record_observed_behavior(ConflictDetectorDouble.BehaviorCategory.PASSIVE)

	var evidence := _create_evidence_with_metadata(
		EvidenceEnums.EvidenceType.AURA_PATTERN, 100,
		"aura_color", AuraEnums.AuraColor.HOT_RED
	)

	var result := detector.check_conflict(evidence)

	assert_true(result.get("has_conflict", false))


func test_aura_cold_blue_conflicts_with_aggressive_behavior() -> void:
	# COLD_BLUE color implies PASSIVE behavior
	# If we observe AGGRESSIVE behavior, there's a conflict
	var detector := ConflictDetectorDouble.new()
	add_child_autofree(detector)

	detector.record_observed_behavior(ConflictDetectorDouble.BehaviorCategory.AGGRESSIVE)

	var evidence := _create_evidence_with_metadata(
		EvidenceEnums.EvidenceType.AURA_PATTERN, 100,
		"aura_color", AuraEnums.AuraColor.COLD_BLUE
	)

	var result := detector.check_conflict(evidence)

	assert_true(result.get("has_conflict", false))


func test_aura_hot_red_no_conflict_with_aggressive_behavior() -> void:
	# HOT_RED color implies AGGRESSIVE behavior
	# If we observe AGGRESSIVE behavior, there's no conflict
	var detector := ConflictDetectorDouble.new()
	add_child_autofree(detector)

	detector.record_observed_behavior(ConflictDetectorDouble.BehaviorCategory.AGGRESSIVE)

	var evidence := _create_evidence_with_metadata(
		EvidenceEnums.EvidenceType.AURA_PATTERN, 100,
		"aura_color", AuraEnums.AuraColor.HOT_RED
	)

	var result := detector.check_conflict(evidence)

	assert_false(result.get("has_conflict", true))


func test_aura_cold_blue_no_conflict_with_passive_behavior() -> void:
	# COLD_BLUE color implies PASSIVE behavior
	# If we observe PASSIVE behavior, there's no conflict
	var detector := ConflictDetectorDouble.new()
	add_child_autofree(detector)

	detector.record_observed_behavior(ConflictDetectorDouble.BehaviorCategory.PASSIVE)

	var evidence := _create_evidence_with_metadata(
		EvidenceEnums.EvidenceType.AURA_PATTERN, 100,
		"aura_color", AuraEnums.AuraColor.COLD_BLUE
	)

	var result := detector.check_conflict(evidence)

	assert_false(result.get("has_conflict", true))


# --- Test: Conflict Metadata ---


func test_conflict_description_contains_prism_info() -> void:
	var detector := ConflictDetectorDouble.new()
	add_child_autofree(detector)

	detector.record_observed_behavior(ConflictDetectorDouble.BehaviorCategory.PASSIVE)

	var evidence := _create_evidence_with_metadata(
		EvidenceEnums.EvidenceType.PRISM_READING, 100,
		"prism_shape", PrismEnums.PrismPattern.CIRCLE
	)

	var result := detector.check_conflict(evidence)
	var desc: String = result.get("conflict_description", "")

	# Description should mention Prism and the shape
	assert_true(desc.to_lower().contains("prism") or desc.to_lower().contains("circle"))


func test_conflict_description_contains_aura_info() -> void:
	var detector := ConflictDetectorDouble.new()
	add_child_autofree(detector)

	detector.record_observed_behavior(ConflictDetectorDouble.BehaviorCategory.PASSIVE)

	var evidence := _create_evidence_with_metadata(
		EvidenceEnums.EvidenceType.AURA_PATTERN, 100,
		"aura_color", AuraEnums.AuraColor.HOT_RED
	)

	var result := detector.check_conflict(evidence)
	var desc: String = result.get("conflict_description", "")

	# Description should mention Aura and the color
	assert_true(desc.to_lower().contains("aura") or desc.to_lower().contains("red"))


# --- Test: No Observed Behavior ---


func test_no_conflict_when_no_behavior_observed() -> void:
	var detector := ConflictDetectorDouble.new()
	add_child_autofree(detector)

	# Don't record any behavior

	var evidence := _create_evidence_with_metadata(
		EvidenceEnums.EvidenceType.PRISM_READING, 100,
		"prism_shape", PrismEnums.PrismPattern.CIRCLE
	)

	var result := detector.check_conflict(evidence)

	# Can't detect conflict without observed behavior
	assert_false(result.get("has_conflict", true))


# --- Test: Non-Equipment Evidence ---


func test_emf_evidence_has_no_behavior_conflict() -> void:
	var detector := ConflictDetectorDouble.new()
	add_child_autofree(detector)

	detector.record_observed_behavior(ConflictDetectorDouble.BehaviorCategory.AGGRESSIVE)

	# EMF is not Prism or Aura, shouldn't have behavior conflict
	var evidence := _create_evidence_with_metadata(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE, 100,
		"level", 5
	)

	var result := detector.check_conflict(evidence)

	assert_false(result.get("has_conflict", true))


func test_hunt_behavior_evidence_has_no_conflict() -> void:
	var detector := ConflictDetectorDouble.new()
	add_child_autofree(detector)

	detector.record_observed_behavior(ConflictDetectorDouble.BehaviorCategory.AGGRESSIVE)

	# Hunt behavior is the ground truth, shouldn't conflict with itself
	var evidence := _create_evidence_with_metadata(
		EvidenceEnums.EvidenceType.HUNT_BEHAVIOR, 100,
		"behavior_category", ConflictDetectorDouble.BehaviorCategory.PASSIVE
	)

	var result := detector.check_conflict(evidence)

	assert_false(result.get("has_conflict", true))


# --- Test: Territorial and Mobile Behaviors ---


func test_prism_square_no_conflict_with_territorial() -> void:
	# SQUARE shape implies TERRITORIAL behavior
	var detector := ConflictDetectorDouble.new()
	add_child_autofree(detector)

	detector.record_observed_behavior(ConflictDetectorDouble.BehaviorCategory.TERRITORIAL)

	var evidence := _create_evidence_with_metadata(
		EvidenceEnums.EvidenceType.PRISM_READING, 100,
		"prism_shape", PrismEnums.PrismPattern.SQUARE
	)

	var result := detector.check_conflict(evidence)

	assert_false(result.get("has_conflict", true))


func test_prism_spiral_no_conflict_with_mobile() -> void:
	# SPIRAL shape implies MOBILE behavior
	var detector := ConflictDetectorDouble.new()
	add_child_autofree(detector)

	detector.record_observed_behavior(ConflictDetectorDouble.BehaviorCategory.MOBILE)

	var evidence := _create_evidence_with_metadata(
		EvidenceEnums.EvidenceType.PRISM_READING, 100,
		"prism_shape", PrismEnums.PrismPattern.SPIRAL
	)

	var result := detector.check_conflict(evidence)

	assert_false(result.get("has_conflict", true))


# --- Test Double ---


## Simplified ConflictDetector double for testing without autoloads.
class ConflictDetectorDouble:
	extends Node

	enum BehaviorCategory { PASSIVE, AGGRESSIVE, TERRITORIAL, MOBILE }

	const PRISM_SHAPE_BEHAVIOR_MAP: Dictionary = {
		PrismEnums.PrismPattern.TRIANGLE: BehaviorCategory.PASSIVE,
		PrismEnums.PrismPattern.CIRCLE: BehaviorCategory.AGGRESSIVE,
		PrismEnums.PrismPattern.SQUARE: BehaviorCategory.TERRITORIAL,
		PrismEnums.PrismPattern.SPIRAL: BehaviorCategory.MOBILE,
	}

	const AURA_COLOR_BEHAVIOR_MAP: Dictionary = {
		AuraEnums.AuraColor.COLD_BLUE: BehaviorCategory.PASSIVE,
		AuraEnums.AuraColor.HOT_RED: BehaviorCategory.AGGRESSIVE,
		AuraEnums.AuraColor.PALE_GREEN: BehaviorCategory.TERRITORIAL,
		AuraEnums.AuraColor.DEEP_PURPLE: BehaviorCategory.MOBILE,
	}

	var _observed_behaviors: Dictionary = {}

	func record_observed_behavior(behavior: int) -> void:
		_observed_behaviors["last_observed"] = behavior

	func check_conflict(evidence: Evidence) -> Dictionary:
		if evidence.type == EvidenceEnums.EvidenceType.PRISM_READING:
			return _check_prism_conflict(evidence)
		if evidence.type == EvidenceEnums.EvidenceType.AURA_PATTERN:
			return _check_aura_conflict(evidence)
		return {"has_conflict": false, "conflict_description": ""}

	func _check_prism_conflict(evidence: Evidence) -> Dictionary:
		var shape: int = evidence.get_metadata("prism_shape", PrismEnums.PrismPattern.NONE)
		if shape == PrismEnums.PrismPattern.NONE:
			return {"has_conflict": false, "conflict_description": ""}

		var expected_behavior: int = PRISM_SHAPE_BEHAVIOR_MAP.get(shape, -1)
		if expected_behavior == -1:
			return {"has_conflict": false, "conflict_description": ""}

		if not _observed_behaviors.has("last_observed"):
			return {"has_conflict": false, "conflict_description": ""}

		var observed: int = _observed_behaviors["last_observed"]
		if observed != expected_behavior:
			var desc := _build_prism_conflict_description(shape, expected_behavior, observed)
			return {"has_conflict": true, "conflict_description": desc}

		return {"has_conflict": false, "conflict_description": ""}

	func _check_aura_conflict(evidence: Evidence) -> Dictionary:
		var color: int = evidence.get_metadata("aura_color", AuraEnums.AuraColor.NONE)
		if color == AuraEnums.AuraColor.NONE:
			return {"has_conflict": false, "conflict_description": ""}

		var expected_behavior: int = AURA_COLOR_BEHAVIOR_MAP.get(color, -1)
		if expected_behavior == -1:
			return {"has_conflict": false, "conflict_description": ""}

		if not _observed_behaviors.has("last_observed"):
			return {"has_conflict": false, "conflict_description": ""}

		var observed: int = _observed_behaviors["last_observed"]
		if observed != expected_behavior:
			var desc := _build_aura_conflict_description(color, expected_behavior, observed)
			return {"has_conflict": true, "conflict_description": desc}

		return {"has_conflict": false, "conflict_description": ""}

	func _build_prism_conflict_description(
		shape: int,
		expected: int,
		observed: int
	) -> String:
		var shape_name := PrismEnums.get_pattern_name(shape)
		var expected_name := _behavior_to_name(expected)
		var observed_name := _behavior_to_name(observed)
		return "Prism showed %s shape (implies %s), but observed %s behavior" % [
			shape_name, expected_name, observed_name
		]

	func _build_aura_conflict_description(
		color: int,
		expected: int,
		observed: int
	) -> String:
		var color_name := AuraEnums.get_color_name(color)
		var expected_name := _behavior_to_name(expected)
		var observed_name := _behavior_to_name(observed)
		return "Aura showed %s color (implies %s), but observed %s behavior" % [
			color_name, expected_name, observed_name
		]

	func _behavior_to_name(behavior: int) -> String:
		match behavior:
			BehaviorCategory.PASSIVE:
				return "passive"
			BehaviorCategory.AGGRESSIVE:
				return "aggressive"
			BehaviorCategory.TERRITORIAL:
				return "territorial"
			BehaviorCategory.MOBILE:
				return "mobile"
			_:
				return "unknown"
