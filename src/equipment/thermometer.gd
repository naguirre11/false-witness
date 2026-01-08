class_name Thermometer
extends Equipment
## Thermometer equipment for detecting freezing temperatures.
##
## The Thermometer is a solo-operation tool that displays readings visible to
## all nearby players (shared display). This makes it high-trust evidence.
##
## Features:
## - Temperature display in Celsius
## - Freezing threshold detection (< 3°C = FREEZING_TEMPERATURE evidence)
## - Reading quality based on stability and position
## - Server-authoritative readings with network sync

# --- Signals ---

## Emitted when temperature reading changes significantly.
signal temperature_changed(new_temperature: float)

## Emitted when freezing evidence is detected.
signal evidence_detected(evidence: Evidence)

## Emitted when reading quality changes.
signal quality_changed(new_quality: EvidenceEnums.ReadingQuality)

# --- Constants ---

## Temperature thresholds (Celsius)
const FREEZING_THRESHOLD: float = 3.0  ## Below this = FREEZING_TEMPERATURE evidence
const EXTREME_COLD_THRESHOLD: float = -5.0  ## Below this = extreme cold entity

## Update interval for temperature readings
const UPDATE_INTERVAL: float = 0.2  ## Slightly slower than EMF for stability

## Strong reading requirements
const STRONG_READING_HOLD_TIME: float = 2.0  ## Seconds stationary for strong reading
const STRONG_READING_STABILITY: float = 1.0  ## Max temp variance for strong reading

## No zone temperature (ambient when outside all zones)
const AMBIENT_TEMPERATURE: float = 20.0

## Display update threshold (only emit when change is noticeable)
const DISPLAY_UPDATE_THRESHOLD: float = 0.1

# --- Export: Thermometer Settings ---

@export_group("Detection")
@export var detection_range: float = 8.0  ## Range to detect temperature zones

@export_group("Audio")
@export var beep_on_freezing: bool = true  ## Beep when freezing detected
@export var ambient_cold_audio: bool = true  ## Play cold ambient sound

# --- State ---

var _current_temperature: float = AMBIENT_TEMPERATURE
var _displayed_temperature: float = AMBIENT_TEMPERATURE
var _reading_quality: EvidenceEnums.ReadingQuality = EvidenceEnums.ReadingQuality.WEAK
var _stationary_time: float = 0.0
var _last_position: Vector3 = Vector3.ZERO
var _update_timer: float = 0.0
var _temp_history: Array[float] = []  ## Recent readings for stability check
var _freezing_collected: bool = false  ## Prevent spam evidence collection

## Current zone (if any)
var _current_zone: Node3D = null
var _current_zone_distance: float = INF


func _ready() -> void:
	equipment_type = EquipmentType.THERMOMETER
	equipment_name = "Thermometer"
	use_mode = UseMode.HOLD
	cooldown_time = 0.0


func _process(delta: float) -> void:
	super._process(delta)

	if _current_state != EquipmentState.ACTIVE:
		return

	# Throttled update for temperature detection
	_update_timer += delta
	if _update_timer >= UPDATE_INTERVAL:
		_update_timer = 0.0
		_update_temperature_reading()
		_update_stationary_time(delta * (1.0 / UPDATE_INTERVAL))

	# Check for evidence collection
	if _current_temperature < FREEZING_THRESHOLD and not _freezing_collected:
		_collect_freezing_evidence()


# --- Virtual Method Overrides ---


func _use_impl() -> void:
	_reset_reading_state()
	print("[Thermometer] Activated")


func _stop_using_impl() -> void:
	_current_temperature = AMBIENT_TEMPERATURE
	_displayed_temperature = AMBIENT_TEMPERATURE
	_current_zone = null
	_freezing_collected = false
	_temp_history.clear()
	temperature_changed.emit(AMBIENT_TEMPERATURE)
	print("[Thermometer] Deactivated")


func get_detectable_evidence() -> Array[String]:
	return ["FREEZING_TEMPERATURE"]


# --- Public API ---


## Returns the current temperature reading (Celsius).
func get_temperature() -> float:
	return _current_temperature


## Returns the displayed temperature (smoothed for UI).
func get_displayed_temperature() -> float:
	return _displayed_temperature


## Returns the current reading quality.
func get_reading_quality() -> EvidenceEnums.ReadingQuality:
	return _reading_quality


## Returns true if current reading is strong quality.
func is_strong_reading() -> bool:
	return _reading_quality == EvidenceEnums.ReadingQuality.STRONG


## Returns true if temperature is below freezing threshold.
func is_freezing() -> bool:
	return _current_temperature < FREEZING_THRESHOLD


## Returns true if temperature indicates extreme cold entity.
func is_extreme_cold() -> bool:
	return _current_temperature < EXTREME_COLD_THRESHOLD


## Returns the zone the player is currently in (if any).
func get_current_zone() -> Node3D:
	return _current_zone


## Override network state to include thermometer-specific data.
func get_network_state() -> Dictionary:
	var state := super.get_network_state()
	state["temperature"] = _current_temperature
	state["displayed_temp"] = _displayed_temperature
	state["quality"] = _reading_quality
	state["is_freezing"] = is_freezing()
	return state


## Override to apply thermometer-specific network state.
func apply_network_state(state: Dictionary) -> void:
	super.apply_network_state(state)
	if state.has("temperature"):
		var new_temp: float = state.temperature
		if absf(new_temp - _current_temperature) > DISPLAY_UPDATE_THRESHOLD:
			_current_temperature = new_temp
			temperature_changed.emit(_current_temperature)
	if state.has("displayed_temp"):
		_displayed_temperature = state.displayed_temp
	if state.has("quality"):
		var new_quality: int = state.quality
		if new_quality != _reading_quality:
			_reading_quality = new_quality as EvidenceEnums.ReadingQuality
			quality_changed.emit(_reading_quality)


# --- Internal: Temperature Detection ---


func _reset_reading_state() -> void:
	_current_temperature = AMBIENT_TEMPERATURE
	_displayed_temperature = AMBIENT_TEMPERATURE
	_reading_quality = EvidenceEnums.ReadingQuality.WEAK
	_stationary_time = 0.0
	_update_timer = 0.0
	_freezing_collected = false
	_current_zone = null
	_current_zone_distance = INF
	_temp_history.clear()
	if _owning_player:
		_last_position = _owning_player.global_position


func _update_temperature_reading() -> void:
	var zones := _find_temperature_zones()

	if zones.is_empty():
		# No zone - use ambient temperature
		_set_temperature(AMBIENT_TEMPERATURE)
		_current_zone = null
		_current_zone_distance = INF
		return

	# Find the zone the player is inside (or nearest if overlapping)
	var best_zone: Node3D = null
	var best_distance: float = INF
	var best_temp: float = AMBIENT_TEMPERATURE

	for zone_data: Dictionary in zones:
		var zone: Node3D = zone_data.node
		var dist: float = zone_data.distance
		var temp: float = zone_data.temperature
		var radius: float = zone_data.radius

		# Prioritize zones we're inside
		if dist <= radius:
			if best_zone == null or dist < best_distance:
				best_zone = zone
				best_distance = dist
				best_temp = temp
		elif best_zone == null:
			# Not inside any zone yet, track nearest
			if dist < best_distance:
				best_zone = zone
				best_distance = dist
				best_temp = temp

	_current_zone = best_zone
	_current_zone_distance = best_distance
	_set_temperature(best_temp)

	# Update reading quality
	_update_reading_quality()


func _find_temperature_zones() -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	if not _owning_player:
		return results

	var player_pos: Vector3 = _owning_player.global_position

	# Find all temperature zones in range
	var temp_zones := get_tree().get_nodes_in_group("temperature_zone")
	for node: Node in temp_zones:
		if not node is Node3D:
			continue

		var zone: Node3D = node as Node3D
		var distance: float = player_pos.distance_to(zone.global_position)

		# Get zone radius (default to detection_range if not available)
		var radius: float = detection_range
		if zone.has_method("get") and zone.get("zone_radius") != null:
			radius = zone.zone_radius
		elif zone.get("zone_radius") != null:
			radius = zone.zone_radius

		# Skip if too far from zone center
		if distance > detection_range + radius:
			continue

		# Get temperature from zone
		var temp: float = AMBIENT_TEMPERATURE
		if zone.has_method("get_temperature"):
			temp = zone.get_temperature()

		var entry := {
			"node": zone,
			"distance": distance,
			"temperature": temp,
			"radius": radius
		}
		results.append(entry)

	return results


func _set_temperature(new_temp: float) -> void:
	# Track temperature history for stability calculation
	_temp_history.append(new_temp)
	if _temp_history.size() > 10:
		_temp_history.remove_at(0)

	# Only emit change if significant
	if absf(new_temp - _current_temperature) > DISPLAY_UPDATE_THRESHOLD:
		_current_temperature = new_temp
		_displayed_temperature = snappedf(new_temp, 0.1)  # Round for display
		temperature_changed.emit(_current_temperature)

		if sync_state:
			_sync_thermometer_state()

		# Audio feedback for freezing
		if beep_on_freezing and new_temp < FREEZING_THRESHOLD:
			_play_freezing_beep()


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


func _update_reading_quality() -> void:
	var old_quality := _reading_quality

	# Calculate temperature stability from history
	var stability := _calculate_stability()

	# Strong reading conditions:
	# 1. Player stationary for STRONG_READING_HOLD_TIME
	# 2. Temperature readings are stable
	# 3. Inside a temperature zone (not ambient)
	var is_stationary: bool = _stationary_time >= STRONG_READING_HOLD_TIME
	var is_stable: bool = stability <= STRONG_READING_STABILITY
	var in_zone: bool = _current_zone != null and _current_zone_distance <= detection_range

	if is_stationary and is_stable and in_zone:
		_reading_quality = EvidenceEnums.ReadingQuality.STRONG
	else:
		_reading_quality = EvidenceEnums.ReadingQuality.WEAK

	if _reading_quality != old_quality:
		quality_changed.emit(_reading_quality)
		if sync_state:
			_sync_thermometer_state()


func _calculate_stability() -> float:
	if _temp_history.size() < 3:
		return INF  # Not enough data

	var min_temp: float = INF
	var max_temp: float = -INF

	for temp: float in _temp_history:
		min_temp = minf(min_temp, temp)
		max_temp = maxf(max_temp, temp)

	return max_temp - min_temp


# --- Internal: Evidence Collection ---


func _collect_freezing_evidence() -> void:
	_freezing_collected = true

	if not _owning_player:
		return

	var player_id: int = _get_player_id(_owning_player)
	var location: Vector3 = _owning_player.global_position

	# Use EvidenceManager to collect
	var evidence_manager := _get_evidence_manager()
	if evidence_manager:
		var evidence: Evidence = evidence_manager.collect_evidence(
			EvidenceEnums.EvidenceType.FREEZING_TEMPERATURE,
			player_id,
			location,
			_reading_quality,
			"Thermometer"
		)

		if evidence:
			evidence_detected.emit(evidence)
			var quality_str := "STRONG" if is_strong_reading() else "WEAK"
			var temp_str := "%.1f°C" % _current_temperature
			print("[Thermometer] Freezing evidence: %s - Quality: %s" % [temp_str, quality_str])


func _get_evidence_manager() -> Node:
	if has_node("/root/EvidenceManager"):
		return get_node("/root/EvidenceManager")
	return null


# --- Internal: Audio ---


func _play_freezing_beep() -> void:
	var event_bus := _get_event_bus()
	if event_bus and event_bus.has_signal("thermometer_freezing"):
		event_bus.thermometer_freezing.emit(_current_temperature)


func _play_extreme_cold_alert() -> void:
	var event_bus := _get_event_bus()
	if event_bus and event_bus.has_signal("thermometer_extreme_cold"):
		event_bus.thermometer_extreme_cold.emit(_current_temperature)


# --- Internal: Network Sync ---


func _sync_thermometer_state() -> void:
	var event_bus := _get_event_bus()
	if not event_bus:
		return

	if event_bus.has_signal("thermometer_state_changed"):
		var player_id: int = 0
		if _owning_player:
			player_id = _get_player_id(_owning_player)
		event_bus.thermometer_state_changed.emit(
			player_id, _current_temperature, _reading_quality
		)
