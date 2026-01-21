class_name ConflictDetector
extends Node
## Detects behavioral conflicts between equipment readings and observed entity behavior.
##
## The key "gotcha" mechanism for catching Cultist lies: if a player reports
## equipment readings that don't match the observed entity behavior during hunts,
## the evidence is flagged as conflicting.
##
## Conflict detection works by comparing:
## - Prism readings (shape implies behavior type) vs observed behavior
## - Aura readings (color implies aggression level) vs observed behavior
##
## Note: No class_name to avoid conflicts with autoload singleton name if used as autoload.

# --- Signals ---

## Emitted when a behavioral conflict is detected.
signal behavioral_conflict(equipment_uid: String, conflict_description: String)

## Emitted when conflicts are resolved (evidence re-verified or removed).
signal conflict_resolved(equipment_uid: String)

# --- Constants ---

## Behavior categories observable during entity hunts.
## These correspond to different movement patterns, aggression levels, and targeting behaviors.
enum BehaviorCategory {
	PASSIVE,      ## Slow movement, avoids players, rare hunts
	AGGRESSIVE,   ## Fast movement, targets players, frequent hunts
	TERRITORIAL,  ## Defends specific area, moderate aggression in zone
	MOBILE,       ## Unpredictable movement, roams widely
}


## Maps entity types to their expected behavior categories.
## Multiple behaviors possible per entity.
const ENTITY_BEHAVIOR_MAP: Dictionary = {
	"Phantom": [BehaviorCategory.MOBILE, BehaviorCategory.PASSIVE],
	"Banshee": [BehaviorCategory.AGGRESSIVE, BehaviorCategory.TERRITORIAL],
	"Revenant": [BehaviorCategory.AGGRESSIVE, BehaviorCategory.MOBILE],
	"Shade": [BehaviorCategory.PASSIVE, BehaviorCategory.TERRITORIAL],
	"Poltergeist": [BehaviorCategory.AGGRESSIVE, BehaviorCategory.MOBILE],
	"Wraith": [BehaviorCategory.MOBILE, BehaviorCategory.PASSIVE],
	"Mare": [BehaviorCategory.TERRITORIAL, BehaviorCategory.PASSIVE],
	"Demon": [BehaviorCategory.AGGRESSIVE, BehaviorCategory.MOBILE],
}


## Maps Prism shape readings to expected behavior categories.
## Prism shapes are geometric indicators of entity aggression pattern.
const PRISM_SHAPE_BEHAVIOR_MAP: Dictionary = {
	# Circle = aggressive, targets players
	"CIRCLE": [BehaviorCategory.AGGRESSIVE],
	# Triangle = passive, avoids confrontation
	"TRIANGLE": [BehaviorCategory.PASSIVE],
	# Square = territorial, defends area
	"SQUARE": [BehaviorCategory.TERRITORIAL],
	# Star = mobile, unpredictable movement
	"STAR": [BehaviorCategory.MOBILE],
}


## Maps Aura color readings to expected behavior categories.
## Aura colors indicate entity energy/aggression levels.
const AURA_COLOR_BEHAVIOR_MAP: Dictionary = {
	# Hot colors = high aggression
	"HOT_RED": [BehaviorCategory.AGGRESSIVE],
	"ORANGE": [BehaviorCategory.AGGRESSIVE, BehaviorCategory.TERRITORIAL],
	# Neutral colors = mobile/unpredictable
	"YELLOW": [BehaviorCategory.MOBILE, BehaviorCategory.TERRITORIAL],
	"GREEN": [BehaviorCategory.MOBILE, BehaviorCategory.PASSIVE],
	# Cold colors = low aggression
	"COLD_BLUE": [BehaviorCategory.PASSIVE],
	"VIOLET": [BehaviorCategory.PASSIVE, BehaviorCategory.TERRITORIAL],
}


# --- State ---

## Tracks observed hunt behavior by entity. Key = "entity_name", Value = BehaviorCategory
var _observed_behaviors: Dictionary = {}

## Tracks equipment evidence UIDs that have been flagged as conflicting.
var _conflicting_evidence: Dictionary = {}  # UID -> conflict_description


func _ready() -> void:
	_connect_signals()
	print("[ConflictDetector] Initialized - Behavioral conflict detection active")


func _connect_signals() -> void:
	var evidence_manager := _get_evidence_manager()
	if evidence_manager:
		if evidence_manager.has_signal("evidence_collected"):
			evidence_manager.evidence_collected.connect(_on_evidence_collected)
		if evidence_manager.has_signal("evidence_cleared"):
			evidence_manager.evidence_cleared.connect(_on_evidence_cleared)


# --- Public API ---


## Records observed behavior during a hunt.
## Called by hunt tracking systems when entity behavior is observed.
func record_hunt_behavior(behavior: BehaviorCategory) -> void:
	_observed_behaviors["last_observed"] = behavior
	# Check for conflicts with existing equipment evidence
	_check_all_equipment_conflicts()


## Gets the last observed behavior category.
func get_last_observed_behavior() -> int:
	return _observed_behaviors.get("last_observed", BehaviorCategory.PASSIVE)


## Checks if specific equipment evidence conflicts with observed behavior.
func check_conflict(equipment_evidence: Evidence) -> Dictionary:
	var observed_behavior: int = _observed_behaviors.get("last_observed", -1)
	if observed_behavior < 0:
		return {"has_conflict": false, "reason": "no_behavior_observed"}

	var evidence_type := equipment_evidence.type

	# Check Prism readings
	if evidence_type == EvidenceEnums.EvidenceType.PRISM_READING:
		return _check_prism_conflict(equipment_evidence, observed_behavior)

	# Check Aura readings
	if evidence_type == EvidenceEnums.EvidenceType.AURA_PATTERN:
		return _check_aura_conflict(equipment_evidence, observed_behavior)

	return {"has_conflict": false, "reason": "not_conflict_checkable"}


## Returns true if evidence UID is currently flagged as conflicting.
func is_conflicting(evidence_uid: String) -> bool:
	return _conflicting_evidence.has(evidence_uid)


## Gets the conflict description for a specific evidence UID.
func get_conflict_description(evidence_uid: String) -> String:
	return _conflicting_evidence.get(evidence_uid, "")


## Clears conflict status for specific evidence (e.g., when re-verified).
func clear_conflict(evidence_uid: String) -> void:
	if _conflicting_evidence.has(evidence_uid):
		_conflicting_evidence.erase(evidence_uid)
		conflict_resolved.emit(evidence_uid)


## Clears all tracked conflicts and observed behaviors.
func clear_all() -> void:
	_observed_behaviors.clear()
	_conflicting_evidence.clear()


# --- Internal: Conflict Detection ---


func _check_prism_conflict(evidence: Evidence, observed_behavior: int) -> Dictionary:
	# Get the Prism shape from evidence metadata
	var prism_shape: String = evidence.get_metadata("prism_shape", "")
	if prism_shape.is_empty():
		return {"has_conflict": false, "reason": "no_prism_shape"}

	# Get expected behaviors for this Prism shape
	var expected_behaviors: Array = PRISM_SHAPE_BEHAVIOR_MAP.get(prism_shape, [])
	if expected_behaviors.is_empty():
		return {"has_conflict": false, "reason": "unknown_prism_shape"}

	# Check if observed behavior matches expected
	if observed_behavior not in expected_behaviors:
		var conflict_desc := _build_prism_conflict_description(
			prism_shape, expected_behaviors, observed_behavior
		)
		return {
			"has_conflict": true,
			"conflict_description": conflict_desc,
			"prism_shape": prism_shape,
			"expected_behaviors": expected_behaviors,
			"observed_behavior": observed_behavior,
		}

	return {"has_conflict": false, "reason": "behavior_matches"}


func _check_aura_conflict(evidence: Evidence, observed_behavior: int) -> Dictionary:
	# Get the Aura color from evidence metadata
	var aura_color: String = evidence.get_metadata("aura_color", "")
	if aura_color.is_empty():
		return {"has_conflict": false, "reason": "no_aura_color"}

	# Get expected behaviors for this Aura color
	var expected_behaviors: Array = AURA_COLOR_BEHAVIOR_MAP.get(aura_color, [])
	if expected_behaviors.is_empty():
		return {"has_conflict": false, "reason": "unknown_aura_color"}

	# Check if observed behavior matches expected
	if observed_behavior not in expected_behaviors:
		var conflict_desc := _build_aura_conflict_description(
			aura_color, expected_behaviors, observed_behavior
		)
		return {
			"has_conflict": true,
			"conflict_description": conflict_desc,
			"aura_color": aura_color,
			"expected_behaviors": expected_behaviors,
			"observed_behavior": observed_behavior,
		}

	return {"has_conflict": false, "reason": "behavior_matches"}


func _build_prism_conflict_description(
	shape: String, expected: Array, observed: int
) -> String:
	var expected_names := _behavior_array_to_names(expected)
	var observed_name := _behavior_to_name(observed)
	return "Prism showed %s shape (implies %s), but entity exhibited %s behavior" % [
		shape, expected_names, observed_name
	]


func _build_aura_conflict_description(
	color: String, expected: Array, observed: int
) -> String:
	var expected_names := _behavior_array_to_names(expected)
	var observed_name := _behavior_to_name(observed)
	return "Aura reading was %s (implies %s), but entity exhibited %s behavior" % [
		color, expected_names, observed_name
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


func _behavior_array_to_names(behaviors: Array) -> String:
	var names: Array[String] = []
	for b in behaviors:
		names.append(_behavior_to_name(b))
	return "/".join(names)


func _check_all_equipment_conflicts() -> void:
	var evidence_manager := _get_evidence_manager()
	if not evidence_manager:
		return

	# Check Prism and Aura evidence for conflicts
	var all_evidence: Array = evidence_manager.get_all_evidence()
	for evidence: Evidence in all_evidence:
		if evidence.type == EvidenceEnums.EvidenceType.PRISM_READING:
			_check_and_flag_conflict(evidence)
		elif evidence.type == EvidenceEnums.EvidenceType.AURA_PATTERN:
			_check_and_flag_conflict(evidence)


func _check_and_flag_conflict(evidence: Evidence) -> void:
	var result := check_conflict(evidence)
	if result.get("has_conflict", false):
		var uid := evidence.uid
		var desc: String = result.get("conflict_description", "Unknown conflict")

		if not _conflicting_evidence.has(uid):
			_conflicting_evidence[uid] = desc
			behavioral_conflict.emit(uid, desc)

			# Also mark evidence as contested in EvidenceManager
			var evidence_manager := _get_evidence_manager()
			if evidence_manager and evidence_manager.has_method("contest_evidence"):
				# Set conflict metadata before contesting
				evidence.set_verification_meta("conflict_description", desc)


# --- Signal Handlers ---


func _on_evidence_collected(evidence: Evidence) -> void:
	# Check if newly collected evidence conflicts with observed behavior
	if evidence.type == EvidenceEnums.EvidenceType.PRISM_READING:
		_check_and_flag_conflict(evidence)
	elif evidence.type == EvidenceEnums.EvidenceType.AURA_PATTERN:
		_check_and_flag_conflict(evidence)


func _on_evidence_cleared() -> void:
	clear_all()


# --- Helpers ---


func _get_evidence_manager() -> Node:
	if has_node("/root/EvidenceManager"):
		return get_node("/root/EvidenceManager")
	return null
