class_name ContaminatedTemperatureZone
extends Node3D
## A false freezing temperature zone planted by a Cultist that decays over time.
##
## When in PLANTED state, appears identical to a real entity's cold zone.
## As it decays, the temperature readings become increasingly erratic and
## eventually the zone returns to ambient temperature.
##
## Decay behavior:
## - PLANTED (0-60s): Consistent freezing temperature (< 0°C)
## - UNSTABLE (60-120s): Temperature swings ±5° every few seconds
## - DEGRADED (120-180s): Temperature rapidly fluctuates, clearly unnatural
## - EXPIRED (180+s): Temperature returns to ambient, zone no longer detected

# --- Signals ---

## Emitted when the decay state changes.
signal decay_state_changed(old_state: int, new_state: int)

## Emitted when this zone expires and should be removed.
signal expired()

## Emitted when temperature changes.
signal temperature_changed(new_temperature: float)

# --- Constants ---

## Base freezing temperature for planted state.
const FREEZING_TEMP: float = -3.0

## Ambient temperature (normal room temp).
const AMBIENT_TEMP: float = 20.0

## Temperature swing range during UNSTABLE state.
const UNSTABLE_SWING_RANGE: float = 5.0

## Temperature swing interval during UNSTABLE state.
const UNSTABLE_SWING_INTERVAL: float = 2.0

## Rapid fluctuation rate during DEGRADED state.
const DEGRADED_FLUCTUATION_RATE: float = 8.0

## Maximum temperature variance during DEGRADED state.
const DEGRADED_TEMP_VARIANCE: float = 15.0

# --- Export ---

@export_group("Zone Settings")
@export var zone_radius: float = 4.0  ## Detection radius from zone center

@export_group("Debug")
@export var debug_visible: bool = false  ## Show debug visual in editor

# --- State ---

## Reference to the contaminated evidence this zone represents.
var _evidence: Resource = null  # ContaminatedEvidence

## Current decay state (cached, updated via _evidence).
var _current_decay_state: int = CultistEnums.DecayState.PLANTED

## Current temperature returned by get_temperature().
var _current_temperature: float = FREEZING_TEMP

## Timer for state updates.
var _update_timer: float = 0.0

## Phase accumulator for decay effects.
var _effect_phase: float = 0.0

## Timer for unstable swing effects.
var _swing_timer: float = 0.0

## Current swing direction (+1 or -1).
var _swing_direction: int = 1

## Random number generator for varied behavior.
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("temperature_zone")
	_rng.randomize()

	if debug_visible:
		_create_debug_visual()


func _process(delta: float) -> void:
	if _evidence == null:
		return

	# Update decay state periodically
	_update_timer += delta
	if _update_timer >= 0.1:
		_update_timer = 0.0
		_update_decay_state()

	# Update effect phase
	_effect_phase += delta
	_swing_timer += delta

	# Update temperature based on decay state
	_update_temperature(delta)


## Initializes this zone with the contaminated evidence it represents.
func initialize(evidence: Resource) -> void:
	_evidence = evidence
	_current_decay_state = CultistEnums.DecayState.PLANTED
	_current_temperature = FREEZING_TEMP


## Returns the current temperature at this zone (Celsius).
## This is called by Thermometer to get the temperature reading.
func get_temperature() -> float:
	return _current_temperature


## Returns the zone radius for detection.
func get_zone_radius() -> float:
	return zone_radius


## Returns the current decay state.
func get_decay_state() -> int:
	return _current_decay_state


## Returns true if this zone has expired.
func has_expired() -> bool:
	return _current_decay_state == CultistEnums.DecayState.EXPIRED


## Returns true if the zone is at freezing temperature (< 3°C).
func is_freezing() -> bool:
	return _current_temperature < 3.0


## Returns the distance from a position to this zone's center.
func distance_to(pos: Vector3) -> float:
	return global_position.distance_to(pos)


## Returns true if a position is within this zone's radius.
func contains_position(pos: Vector3) -> bool:
	return distance_to(pos) <= zone_radius


# --- Internal: Decay State ---


func _update_decay_state() -> void:
	if _evidence == null:
		return

	# ContaminatedEvidence has update_decay() that returns true if state changed
	if _evidence.has_method("update_decay"):
		var changed: bool = _evidence.update_decay()
		if changed:
			_handle_decay_change()


func _handle_decay_change() -> void:
	if _evidence == null:
		return

	var new_state: int = _evidence.get_decay_state()
	if new_state == _current_decay_state:
		return

	var old_state := _current_decay_state
	_current_decay_state = new_state
	decay_state_changed.emit(old_state, new_state)

	# Handle expiration
	if new_state == CultistEnums.DecayState.EXPIRED:
		_current_temperature = AMBIENT_TEMP
		temperature_changed.emit(_current_temperature)
		expired.emit()


# --- Internal: Temperature Updates ---


func _update_temperature(_delta: float) -> void:
	var old_temp := _current_temperature

	match _current_decay_state:
		CultistEnums.DecayState.PLANTED:
			_apply_planted_temp()
		CultistEnums.DecayState.UNSTABLE:
			_apply_unstable_temp()
		CultistEnums.DecayState.DEGRADED:
			_apply_degraded_temp()
		CultistEnums.DecayState.EXPIRED:
			_apply_expired_temp()

	if absf(_current_temperature - old_temp) > 0.1:
		temperature_changed.emit(_current_temperature)


## PLANTED: Consistent freezing temperature (< 0°C).
## Indistinguishable from real entity cold zone.
func _apply_planted_temp() -> void:
	# Slight natural variance like real zones
	var variance := sin(_effect_phase * 0.2) * 0.3
	_current_temperature = FREEZING_TEMP + variance


## UNSTABLE: Temperature swings ±5° every few seconds.
## Noticeable but could be mistaken for entity movement.
func _apply_unstable_temp() -> void:
	# Check if it's time to swing direction
	if _swing_timer >= UNSTABLE_SWING_INTERVAL:
		_swing_timer = 0.0
		_swing_direction *= -1

	# Base freezing temp with swing
	var swing_offset := _swing_direction * UNSTABLE_SWING_RANGE
	# Smooth the swing using sine
	var swing_progress := _swing_timer / UNSTABLE_SWING_INTERVAL
	var smooth_factor := sin(swing_progress * PI / 2)

	_current_temperature = FREEZING_TEMP + (swing_offset * smooth_factor)


## DEGRADED: Temperature rapidly fluctuates, clearly unnatural.
## Very obvious to observant players.
func _apply_degraded_temp() -> void:
	# Rapid fluctuation using high-frequency sine
	var rapid_wave := sin(_effect_phase * DEGRADED_FLUCTUATION_RATE)

	# Add random jumps
	var random_jump := 0.0
	if _rng.randf() < 0.05:  # 5% chance per frame
		random_jump = _rng.randf_range(-DEGRADED_TEMP_VARIANCE, DEGRADED_TEMP_VARIANCE)

	# Base temp varies wildly between freezing and ambient
	var base_temp := lerpf(FREEZING_TEMP, AMBIENT_TEMP / 2, (rapid_wave + 1) / 2)
	_current_temperature = base_temp + random_jump


## EXPIRED: Temperature returns to ambient, zone no longer effective.
func _apply_expired_temp() -> void:
	_current_temperature = AMBIENT_TEMP


# --- Debug Visual ---


func _create_debug_visual() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = zone_radius
	mesh.height = zone_radius * 2.0

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.5, 1.0, 0.3)  # Blue tint for cold
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(0.1, 0.2, 0.8)
	material.emission_energy_multiplier = 0.3
	mesh.material = material

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.name = "DebugVisual"
	add_child(mesh_instance)
