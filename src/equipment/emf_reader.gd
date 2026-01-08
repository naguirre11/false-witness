class_name EMFReader
extends Equipment
## EMF Reader equipment for detecting electromagnetic signatures.
##
## The EMF Reader is a solo-operation tool that displays readings visible to
## all nearby players (shared display). This makes it high-trust evidence.
##
## Features:
## - EMF levels 1-5 (only level 5 = evidence)
## - Direction indicator for triangulation
## - Escalating audio feedback
## - Server-authoritative readings with network sync

# --- Signals ---

## Emitted when EMF level changes.
signal level_changed(new_level: int)

## Emitted when direction to strongest source changes.
signal direction_changed(direction: Vector3)

## Emitted when Level 5 evidence is collected.
signal evidence_detected(evidence: Evidence)

# --- Constants ---

const MIN_LEVEL: int = 0
const MAX_LEVEL: int = 5
const EVIDENCE_LEVEL: int = 5

## Distance thresholds for EMF level calculation.
const LEVEL_5_DISTANCE: float = 2.0  # Very close for Level 5
const LEVEL_4_DISTANCE: float = 4.0
const LEVEL_3_DISTANCE: float = 6.0
const LEVEL_2_DISTANCE: float = 8.0
const LEVEL_1_DISTANCE: float = 10.0

## Strong reading requires being stationary and close.
const STRONG_READING_MAX_DISTANCE: float = 2.0
const STRONG_READING_HOLD_TIME: float = 1.5  # Seconds stationary

## Minimum detection range for direction indicator.
const DIRECTION_INDICATOR_RANGE: float = 15.0

## Update rate for EMF detection (not every frame for performance).
const UPDATE_INTERVAL: float = 0.1

# --- Export: EMF Settings ---

@export_group("EMF Detection")
@export var detection_range: float = 12.0  ## Maximum detection distance
@export var direction_accuracy_falloff: float = 0.1  ## Accuracy loss per meter

@export_group("Audio")
@export var beep_enabled: bool = true
@export var base_beep_interval: float = 1.0  ## Interval at Level 1

# --- State ---

var _current_level: int = 0
var _current_direction: Vector3 = Vector3.ZERO
var _reading_quality: EvidenceEnums.ReadingQuality = EvidenceEnums.ReadingQuality.WEAK
var _stationary_time: float = 0.0
var _last_position: Vector3 = Vector3.ZERO
var _update_timer: float = 0.0
var _beep_timer: float = 0.0
var _level_5_collected: bool = false  ## Prevent spam evidence collection

## Nearest EMF source (for direction indicator).
var _nearest_source: Node3D = null
var _nearest_source_distance: float = INF


func _ready() -> void:
	equipment_type = EquipmentType.EMF_READER
	equipment_name = "EMF Reader"
	use_mode = UseMode.HOLD
	cooldown_time = 0.0


func _process(delta: float) -> void:
	super._process(delta)

	if _current_state != EquipmentState.ACTIVE:
		return

	# Throttled update for EMF detection
	_update_timer += delta
	if _update_timer >= UPDATE_INTERVAL:
		_update_timer = 0.0
		_update_emf_reading()
		_update_stationary_time(delta * (1.0 / UPDATE_INTERVAL))
		_update_direction_indicator()

	# Audio feedback
	if beep_enabled and _current_level > 0:
		_update_beep(delta)


# --- Virtual Method Overrides ---


func _use_impl() -> void:
	_reset_reading_state()
	print("[EMFReader] Activated")


func _stop_using_impl() -> void:
	_current_level = 0
	_current_direction = Vector3.ZERO
	_nearest_source = null
	_level_5_collected = false
	level_changed.emit(0)
	print("[EMFReader] Deactivated")


func get_detectable_evidence() -> Array[String]:
	return ["EMF_SIGNATURE"]


# --- Public API ---


## Returns the current EMF level (0-5).
func get_emf_level() -> int:
	return _current_level


## Returns the direction to the nearest EMF source.
## Returns Vector3.ZERO if no source detected.
func get_source_direction() -> Vector3:
	return _current_direction


## Returns the current reading quality.
func get_reading_quality() -> EvidenceEnums.ReadingQuality:
	return _reading_quality


## Returns true if current reading is strong quality.
func is_strong_reading() -> bool:
	return _reading_quality == EvidenceEnums.ReadingQuality.STRONG


## Returns distance to nearest EMF source.
func get_source_distance() -> float:
	return _nearest_source_distance


## Override network state to include EMF-specific data.
func get_network_state() -> Dictionary:
	var state := super.get_network_state()
	state["emf_level"] = _current_level
	state["direction_x"] = _current_direction.x
	state["direction_y"] = _current_direction.y
	state["direction_z"] = _current_direction.z
	state["quality"] = _reading_quality
	return state


## Override to apply EMF-specific network state.
func apply_network_state(state: Dictionary) -> void:
	super.apply_network_state(state)
	if state.has("emf_level"):
		var new_level: int = state.emf_level
		if new_level != _current_level:
			_current_level = new_level
			level_changed.emit(_current_level)
	if state.has("direction_x"):
		_current_direction = Vector3(
			state.get("direction_x", 0.0),
			state.get("direction_y", 0.0),
			state.get("direction_z", 0.0)
		)
		direction_changed.emit(_current_direction)
	if state.has("quality"):
		_reading_quality = state.quality as EvidenceEnums.ReadingQuality


# --- Internal: EMF Detection ---


func _reset_reading_state() -> void:
	_current_level = 0
	_current_direction = Vector3.ZERO
	_reading_quality = EvidenceEnums.ReadingQuality.WEAK
	_stationary_time = 0.0
	_update_timer = 0.0
	_beep_timer = 0.0
	_level_5_collected = false
	_nearest_source = null
	_nearest_source_distance = INF
	if _owning_player:
		_last_position = _owning_player.global_position


func _update_emf_reading() -> void:
	var sources := _find_emf_sources()
	if sources.is_empty():
		_set_level(0)
		_nearest_source = null
		_nearest_source_distance = INF
		return

	# Find nearest/strongest source
	var best_source: Node3D = null
	var best_distance: float = INF
	var best_level: int = 0

	for source: Dictionary in sources:
		var node: Node3D = source.node
		var dist: float = source.distance
		var activity: float = source.activity

		var level := _calculate_level(dist, activity)
		if level > best_level or (level == best_level and dist < best_distance):
			best_level = level
			best_distance = dist
			best_source = node

	_nearest_source = best_source
	_nearest_source_distance = best_distance
	_set_level(best_level)

	# Update reading quality based on conditions
	_update_reading_quality(best_distance)

	# Check for evidence collection
	if best_level == EVIDENCE_LEVEL and not _level_5_collected:
		_collect_emf_evidence()


func _find_emf_sources() -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	if not _owning_player:
		return results

	var player_pos: Vector3 = _owning_player.global_position

	# Find all EMF sources in range
	var emf_sources := get_tree().get_nodes_in_group("emf_source")
	for node: Node in emf_sources:
		if not node is Node3D:
			continue

		var source: Node3D = node as Node3D
		var distance: float = player_pos.distance_to(source.global_position)

		if distance > detection_range:
			continue

		# Get activity level from source (default to 1.0 for mock sources)
		var activity: float = 1.0
		if source.has_method("get_emf_activity"):
			activity = source.get_emf_activity()

		var entry := {"node": source, "distance": distance, "activity": activity}
		results.append(entry)

	return results


func _calculate_level(distance: float, activity: float) -> int:
	# No activity = no EMF
	if activity <= 0.0:
		return 0

	# Scale distance by inverse activity (higher activity = stronger at distance)
	var effective_distance: float = distance / maxf(activity, 0.1)

	# Map distance to level using thresholds
	var level: int = 0
	if effective_distance <= LEVEL_5_DISTANCE:
		level = 5
	elif effective_distance <= LEVEL_4_DISTANCE:
		level = 4
	elif effective_distance <= LEVEL_3_DISTANCE:
		level = 3
	elif effective_distance <= LEVEL_2_DISTANCE:
		level = 2
	elif effective_distance <= LEVEL_1_DISTANCE:
		level = 1
	return level


func _set_level(new_level: int) -> void:
	new_level = clampi(new_level, MIN_LEVEL, MAX_LEVEL)
	if new_level != _current_level:
		_current_level = new_level
		level_changed.emit(_current_level)

		if sync_state:
			_sync_emf_state()


# --- Internal: Direction Indicator ---


func _update_direction_indicator() -> void:
	if _nearest_source == null or not _owning_player:
		if _current_direction != Vector3.ZERO:
			_current_direction = Vector3.ZERO
			direction_changed.emit(_current_direction)
		return

	if _nearest_source_distance > DIRECTION_INDICATOR_RANGE:
		if _current_direction != Vector3.ZERO:
			_current_direction = Vector3.ZERO
			direction_changed.emit(_current_direction)
		return

	# Calculate direction to source
	var player_pos: Vector3 = _owning_player.global_position
	var source_pos: Vector3 = _nearest_source.global_position
	var raw_direction: Vector3 = (source_pos - player_pos).normalized()

	# Apply accuracy falloff with distance
	var accuracy: float = 1.0 - (_nearest_source_distance * direction_accuracy_falloff)
	accuracy = clampf(accuracy, 0.1, 1.0)

	# Add noise based on distance (reduces accuracy at range)
	if accuracy < 1.0:
		var noise_amount: float = (1.0 - accuracy) * 0.5
		raw_direction.x += randf_range(-noise_amount, noise_amount)
		raw_direction.z += randf_range(-noise_amount, noise_amount)
		raw_direction = raw_direction.normalized()

	if raw_direction != _current_direction:
		_current_direction = raw_direction
		direction_changed.emit(_current_direction)


# --- Internal: Reading Quality ---


func _update_stationary_time(delta: float) -> void:
	if not _owning_player:
		return

	var current_pos: Vector3 = _owning_player.global_position
	var movement: float = current_pos.distance_to(_last_position)

	# Consider stationary if movement is very small
	if movement < 0.1:
		_stationary_time += delta
	else:
		_stationary_time = 0.0

	_last_position = current_pos


func _update_reading_quality(distance: float) -> void:
	var old_quality := _reading_quality

	# Strong reading conditions:
	# 1. Close proximity (within STRONG_READING_MAX_DISTANCE)
	# 2. Player stationary for STRONG_READING_HOLD_TIME
	var is_close: bool = distance <= STRONG_READING_MAX_DISTANCE
	var is_stationary: bool = _stationary_time >= STRONG_READING_HOLD_TIME

	if is_close and is_stationary:
		_reading_quality = EvidenceEnums.ReadingQuality.STRONG
	else:
		_reading_quality = EvidenceEnums.ReadingQuality.WEAK

	if _reading_quality != old_quality and sync_state:
		_sync_emf_state()


# --- Internal: Evidence Collection ---


func _collect_emf_evidence() -> void:
	_level_5_collected = true

	if not _owning_player:
		return

	var player_id: int = _get_player_id(_owning_player)
	var location: Vector3 = _owning_player.global_position

	# Use EvidenceManager to collect
	var evidence_manager := _get_evidence_manager()
	if evidence_manager:
		var evidence: Evidence = evidence_manager.collect_evidence(
			EvidenceEnums.EvidenceType.EMF_SIGNATURE,
			player_id,
			location,
			_reading_quality,
			"EMF Reader"
		)

		if evidence:
			evidence_detected.emit(evidence)
			var quality_str := "STRONG" if is_strong_reading() else "WEAK"
			print("[EMFReader] Level 5 evidence collected - Quality: %s" % quality_str)


func _get_evidence_manager() -> Node:
	if has_node("/root/EvidenceManager"):
		return get_node("/root/EvidenceManager")
	return null


# --- Internal: Audio ---


func _update_beep(delta: float) -> void:
	if _current_level <= 0:
		return

	# Beep interval decreases with higher level
	var interval: float = base_beep_interval / float(_current_level)

	_beep_timer += delta
	if _beep_timer >= interval:
		_beep_timer = 0.0
		_play_beep()


func _play_beep() -> void:
	# Emit event for audio system to handle
	var event_bus := _get_event_bus()
	if event_bus and event_bus.has_signal("emf_beep"):
		event_bus.emf_beep.emit(_current_level)

	# Level 5 gets special audio
	if _current_level == EVIDENCE_LEVEL:
		if event_bus and event_bus.has_signal("emf_level_5_spike"):
			event_bus.emf_level_5_spike.emit()


# --- Internal: Network Sync ---


func _sync_emf_state() -> void:
	var event_bus := _get_event_bus()
	if not event_bus:
		return

	if event_bus.has_signal("emf_state_changed"):
		var player_id: int = 0
		if _owning_player:
			player_id = _get_player_id(_owning_player)
		event_bus.emf_state_changed.emit(
			player_id, _current_level, _current_direction, _reading_quality
		)
