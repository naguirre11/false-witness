extends Node
## Detects behavioral conflicts between equipment readings and observed entity behavior.
## Autoload: ConflictDetector
##
## The key "gotcha" mechanism for catching Cultist lies: if a player reports
## equipment readings that don't match the observed entity behavior during hunts,
## the evidence is flagged as conflicting.
##
## Conflict detection works by comparing:
## - Prism readings (shape implies behavior type) vs observed behavior
## - Aura readings (color implies aggression level) vs observed behavior
##
## Note: No class_name to avoid conflicts with autoload singleton name.

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


# --- Hunt Behavior Observation Data ---

## Observation data structure for tracking behavior during hunts.
## Keys: observer_id, timestamp, speed, aggression, targeting, category
const OBSERVATION_KEYS: Array[String] = [
	"observer_id", "timestamp", "speed", "aggression", "targeting", "category",
]


## Speed thresholds for behavior categorization.
const SPEED_SLOW := 2.0  ## Below this = PASSIVE/TERRITORIAL
const SPEED_MEDIUM := 4.0  ## Below this = MOBILE, above = AGGRESSIVE


## Aggression thresholds (0.0 to 1.0 scale).
const AGGRESSION_LOW := 0.3  ## Below this = PASSIVE
const AGGRESSION_MEDIUM := 0.6  ## Below this = TERRITORIAL/MOBILE
const AGGRESSION_HIGH := 0.8  ## Above this = AGGRESSIVE


# --- State ---

## Tracks observed hunt behavior by entity. Key = "entity_name", Value = BehaviorCategory
var _observed_behaviors: Dictionary = {}

## Tracks equipment evidence UIDs that have been flagged as conflicting.
var _conflicting_evidence: Dictionary = {}  # UID -> conflict_description

## Accumulated hunt observations from multiple observers.
## Key = hunt_id (generated per hunt), Value = Array of observation dicts.
var _hunt_observations: Dictionary = {}

## Current active hunt ID (set when hunt starts, cleared when hunt ends).
var _current_hunt_id: String = ""

## Counter for generating hunt IDs.
var _hunt_counter: int = 0


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

	# Connect to EventBus for hunt state tracking
	var event_bus := _get_event_bus()
	if event_bus:
		if event_bus.has_signal("hunt_started"):
			event_bus.hunt_started.connect(_on_hunt_started)
		if event_bus.has_signal("hunt_ended"):
			event_bus.hunt_ended.connect(_on_hunt_ended)


# --- Public API ---


## Records observed behavior during a hunt.
## Called by hunt tracking systems when entity behavior is observed.
func record_hunt_behavior(behavior: BehaviorCategory) -> void:
	_observed_behaviors["last_observed"] = behavior
	# Check for conflicts with existing equipment evidence
	_check_all_equipment_conflicts()


# --- Public API: Hunt Observation Tracking ---


## Starts tracking a new hunt. Call when a hunt begins.
## Returns the hunt ID for this hunt.
func start_hunt_tracking() -> String:
	_hunt_counter += 1
	_current_hunt_id = "hunt_%d_%d" % [Time.get_ticks_msec(), _hunt_counter]
	_hunt_observations[_current_hunt_id] = []
	print("[ConflictDetector] Started tracking hunt: %s" % _current_hunt_id)
	return _current_hunt_id


## Records a player's observation of entity behavior during a hunt.
## This is the primary method for tracking hunt behavior.
## @param observer_id: Player peer ID who observed the behavior.
## @param speed: Observed entity movement speed (units per second).
## @param aggression: Observed aggression level (0.0 to 1.0).
## @param targeting: Was the entity targeting players? (true/false).
## @param location: Where the observation was made.
func record_observation(
	observer_id: int,
	speed: float,
	aggression: float,
	targeting: bool,
	location: Vector3 = Vector3.ZERO
) -> void:
	if _current_hunt_id.is_empty():
		# Auto-start tracking if not already started
		start_hunt_tracking()

	var category := _categorize_behavior(speed, aggression, targeting)
	var observation := {
		"observer_id": observer_id,
		"timestamp": Time.get_ticks_msec() / 1000.0,
		"speed": speed,
		"aggression": aggression,
		"targeting": targeting,
		"category": category,
		"location": location,
	}

	_hunt_observations[_current_hunt_id].append(observation)
	print(
		"[ConflictDetector] Observation from player %d: speed=%.1f, aggression=%.1f, cat=%s"
		% [observer_id, speed, aggression, _behavior_to_name(category)]
	)


## Ends the current hunt tracking and creates HUNT_BEHAVIOR evidence.
## Returns the Evidence resource if created, null if no observations.
func end_hunt_tracking() -> Evidence:
	if _current_hunt_id.is_empty():
		return null

	var observations: Array = _hunt_observations.get(_current_hunt_id, [])
	if observations.is_empty():
		_current_hunt_id = ""
		return null

	# Aggregate observations to determine final behavior category
	var final_category := _aggregate_observations(observations)

	# Store as the last observed behavior for conflict checking
	_observed_behaviors["last_observed"] = final_category

	# Create HUNT_BEHAVIOR evidence
	var evidence := _create_hunt_behavior_evidence(observations, final_category)

	# Clear hunt state
	var ended_hunt_id := _current_hunt_id
	_current_hunt_id = ""
	print("[ConflictDetector] Ended hunt tracking: %s with %d observers" % [
		ended_hunt_id, _get_unique_observers(observations).size()
	])

	# Check for conflicts with existing equipment evidence
	_check_all_equipment_conflicts()

	return evidence


## Returns the current hunt ID, or empty string if no hunt active.
func get_current_hunt_id() -> String:
	return _current_hunt_id


## Returns true if a hunt is currently being tracked.
func is_hunt_active() -> bool:
	return not _current_hunt_id.is_empty()


## Returns observations for a specific hunt.
func get_hunt_observations(hunt_id: String) -> Array:
	return _hunt_observations.get(hunt_id, []).duplicate()


## Returns the number of unique observers for the current hunt.
func get_current_observer_count() -> int:
	if _current_hunt_id.is_empty():
		return 0
	var observations: Array = _hunt_observations.get(_current_hunt_id, [])
	return _get_unique_observers(observations).size()


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
	_hunt_observations.clear()
	_current_hunt_id = ""


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

			# Set conflict metadata on the evidence
			evidence.set_verification_meta("conflict_description", desc)

			# Emit to EventBus for global notification
			_emit_behavioral_conflict_to_event_bus(uid, desc)

			# Mark evidence as CONTESTED in EvidenceManager
			var evidence_manager := _get_evidence_manager()
			if evidence_manager:
				# Use contest_evidence to trigger CONTESTED state and proper signal emission
				evidence_manager.contest_evidence(uid, 0)  # 0 = system-triggered conflict
				print(
					"[ConflictDetector] Marked evidence %s as CONTESTED: %s" % [uid, desc]
				)


# --- Internal: Hunt Behavior Tracking ---


## Categorizes observed behavior based on measured values.
func _categorize_behavior(speed: float, aggression: float, targeting: bool) -> int:
	# High aggression + targeting = AGGRESSIVE
	if aggression >= AGGRESSION_HIGH and targeting:
		return BehaviorCategory.AGGRESSIVE

	# High aggression without targeting = TERRITORIAL (defends area)
	if aggression >= AGGRESSION_MEDIUM and not targeting:
		return BehaviorCategory.TERRITORIAL

	# Fast speed + low aggression = MOBILE (roaming)
	if speed >= SPEED_MEDIUM and aggression < AGGRESSION_MEDIUM:
		return BehaviorCategory.MOBILE

	# Slow speed + low aggression = PASSIVE
	if speed < SPEED_SLOW and aggression < AGGRESSION_LOW:
		return BehaviorCategory.PASSIVE

	# Medium speed with medium aggression = TERRITORIAL
	if speed < SPEED_MEDIUM and aggression >= AGGRESSION_LOW:
		return BehaviorCategory.TERRITORIAL

	# Default to MOBILE for unpredictable movement patterns
	return BehaviorCategory.MOBILE


## Aggregates multiple observations to determine the consensus behavior.
## Multiple observers strengthen the evidence quality.
func _aggregate_observations(observations: Array) -> int:
	if observations.is_empty():
		return BehaviorCategory.PASSIVE

	# Count votes for each category
	var category_votes: Dictionary = {
		BehaviorCategory.PASSIVE: 0,
		BehaviorCategory.AGGRESSIVE: 0,
		BehaviorCategory.TERRITORIAL: 0,
		BehaviorCategory.MOBILE: 0,
	}

	for obs: Dictionary in observations:
		var cat: int = obs.get("category", BehaviorCategory.PASSIVE)
		category_votes[cat] = category_votes.get(cat, 0) + 1

	# Find the category with most votes
	var max_votes: int = 0
	var winning_category: int = BehaviorCategory.PASSIVE
	for cat: int in category_votes:
		if category_votes[cat] > max_votes:
			max_votes = category_votes[cat]
			winning_category = cat

	return winning_category


## Creates HUNT_BEHAVIOR evidence from aggregated observations.
func _create_hunt_behavior_evidence(observations: Array, category: int) -> Evidence:
	var evidence_manager := _get_evidence_manager()
	if not evidence_manager:
		return null

	# Get unique observers
	var observer_ids := _get_unique_observers(observations)
	if observer_ids.is_empty():
		return null

	# Use first observer's location, or average of all locations
	var avg_location := _get_average_location(observations)

	# Determine quality based on observer count
	# Multiple observers = STRONG, single observer = WEAK
	var quality: EvidenceEnums.ReadingQuality
	if observer_ids.size() >= 2:
		quality = EvidenceEnums.ReadingQuality.STRONG
	else:
		quality = EvidenceEnums.ReadingQuality.WEAK

	# Collect evidence through EvidenceManager
	var evidence: Evidence = evidence_manager.collect_evidence(
		EvidenceEnums.EvidenceType.HUNT_BEHAVIOR,
		observer_ids[0],  # Primary collector is first observer
		avg_location,
		quality,
		"HuntObservation"
	)

	if evidence:
		# Add all observers as witnesses
		for observer_id: int in observer_ids:
			evidence.add_witness(observer_id)

		# Store behavior metadata
		evidence.set_metadata("behavior_category", category)
		evidence.set_metadata("behavior_name", _behavior_to_name(category))
		evidence.set_metadata("observer_count", observer_ids.size())
		evidence.set_metadata("observation_count", observations.size())

		# Store averaged measurement data
		var avg_speed := _get_average_speed(observations)
		var avg_aggression := _get_average_aggression(observations)
		evidence.set_metadata("avg_speed", avg_speed)
		evidence.set_metadata("avg_aggression", avg_aggression)

		# Multiple observers = auto-verified (UNFALSIFIABLE trust level)
		if observer_ids.size() >= 2:
			evidence.verify()
			print(
				"[ConflictDetector] Created VERIFIED hunt behavior evidence: %s (%d observers)"
				% [_behavior_to_name(category), observer_ids.size()]
			)
		else:
			print(
				"[ConflictDetector] Created hunt behavior evidence: %s (single observer)"
				% _behavior_to_name(category)
			)

	return evidence


## Returns unique observer IDs from observations.
func _get_unique_observers(observations: Array) -> Array[int]:
	var observers: Array[int] = []
	for obs: Dictionary in observations:
		var observer_id: int = obs.get("observer_id", 0)
		if observer_id != 0 and observer_id not in observers:
			observers.append(observer_id)
	return observers


## Returns the average location from observations.
func _get_average_location(observations: Array) -> Vector3:
	if observations.is_empty():
		return Vector3.ZERO

	var total := Vector3.ZERO
	var count: int = 0
	for obs: Dictionary in observations:
		var loc: Vector3 = obs.get("location", Vector3.ZERO)
		if loc != Vector3.ZERO:
			total += loc
			count += 1

	if count == 0:
		return Vector3.ZERO
	return total / float(count)


## Returns the average speed from observations.
func _get_average_speed(observations: Array) -> float:
	if observations.is_empty():
		return 0.0

	var total: float = 0.0
	for obs: Dictionary in observations:
		total += obs.get("speed", 0.0)
	return total / float(observations.size())


## Returns the average aggression from observations.
func _get_average_aggression(observations: Array) -> float:
	if observations.is_empty():
		return 0.0

	var total: float = 0.0
	for obs: Dictionary in observations:
		total += obs.get("aggression", 0.0)
	return total / float(observations.size())


# --- Signal Handlers ---


func _on_evidence_collected(evidence: Evidence) -> void:
	# Check if newly collected evidence conflicts with observed behavior
	if evidence.type == EvidenceEnums.EvidenceType.PRISM_READING:
		_check_and_flag_conflict(evidence)
	elif evidence.type == EvidenceEnums.EvidenceType.AURA_PATTERN:
		_check_and_flag_conflict(evidence)


func _on_evidence_cleared() -> void:
	clear_all()


func _on_hunt_started() -> void:
	# Auto-start hunt tracking when a hunt begins
	start_hunt_tracking()


func _on_hunt_ended() -> void:
	# Auto-end hunt tracking and create evidence when hunt ends
	end_hunt_tracking()


# --- Helpers ---


func _get_evidence_manager() -> Node:
	if has_node("/root/EvidenceManager"):
		return get_node("/root/EvidenceManager")
	return null


func _get_event_bus() -> Node:
	if has_node("/root/EventBus"):
		return get_node("/root/EventBus")
	return null


func _emit_behavioral_conflict_to_event_bus(equipment_uid: String, desc: String) -> void:
	var event_bus := _get_event_bus()
	if event_bus and event_bus.has_signal("behavioral_conflict_detected"):
		event_bus.behavioral_conflict_detected.emit(equipment_uid, desc)
