class_name TemperatureZone
extends Node3D
## Temperature zone for room-based temperature detection.
##
## Place this in a room/area and add to "temperature_zone" group to be detected
## by Thermometers. Represents a region with a base temperature that can be
## modified by entity presence.
##
## For entity integration: Entity AI will set entity_influence based on
## entity type and activity. Cold entities (Mare, Hantu) lower temperature.

# --- Signals ---

signal temperature_changed(new_temperature: float)
signal entity_influence_changed(new_influence: float)

# --- Constants ---

## Default ambient temperature range (Celsius)
const DEFAULT_MIN_TEMP: float = 15.0
const DEFAULT_MAX_TEMP: float = 22.0

## Freezing threshold for evidence
const FREEZING_THRESHOLD: float = 3.0

## Extreme cold threshold for frost effects
const EXTREME_COLD_THRESHOLD: float = -5.0

## Temperature change rate (degrees per second)
const TEMP_CHANGE_RATE: float = 0.5

## Natural temperature variance amplitude
const NATURAL_VARIANCE: float = 0.5

# --- Export ---

@export_group("Zone Settings")
@export var zone_name: String = "Room"  ## Display name for this zone
@export var base_temperature: float = 18.0  ## Baseline temperature (Celsius)
@export var zone_radius: float = 5.0  ## Detection radius from zone center

@export_group("Temperature Behavior")
@export var enable_natural_variance: bool = true  ## Minor temperature fluctuation
@export var variance_speed: float = 0.2  ## Speed of natural variance cycle

@export_group("Entity Settings")
@export var entity_influence: float = 0.0  ## Entity temperature modifier (negative = cold)
@export var target_influence: float = 0.0  ## Target influence (for gradual changes)
@export var influence_change_rate: float = 0.05  ## How fast influence changes per second

@export_group("Debug")
@export var debug_visible: bool = false  ## Show debug sphere in editor

# --- State ---

var _current_temperature: float = 18.0
var _variance_phase: float = 0.0
var _last_computed_temp: float = 18.0


func _ready() -> void:
	add_to_group("temperature_zone")
	_current_temperature = base_temperature
	_last_computed_temp = base_temperature
	_variance_phase = randf() * TAU  # Random start phase for variance

	if debug_visible:
		_create_debug_visual()


func _process(delta: float) -> void:
	# Gradually move entity influence toward target
	if entity_influence != target_influence:
		_update_entity_influence(delta)

	# Update natural variance
	if enable_natural_variance:
		_variance_phase += delta * variance_speed
		if _variance_phase > TAU:
			_variance_phase -= TAU

	# Compute current temperature
	var new_temp := _compute_temperature()
	if absf(new_temp - _last_computed_temp) > 0.01:
		_last_computed_temp = new_temp
		_current_temperature = new_temp
		temperature_changed.emit(_current_temperature)


# --- Public API ---


## Returns the current temperature at this zone (Celsius).
func get_temperature() -> float:
	return _current_temperature


## Returns the base temperature without modifiers.
func get_base_temperature() -> float:
	return base_temperature


## Returns current entity influence value.
func get_entity_influence() -> float:
	return entity_influence


## Sets entity influence directly (immediate).
## Negative values = colder (entity drains heat).
func set_entity_influence(influence: float) -> void:
	var old_influence := entity_influence
	entity_influence = influence
	target_influence = influence
	if entity_influence != old_influence:
		entity_influence_changed.emit(entity_influence)


## Sets target entity influence (gradual transition).
## Use this for smooth temperature changes when entity enters/leaves.
func set_target_influence(influence: float) -> void:
	target_influence = influence


## Returns true if the zone is at freezing temperature (< 3°C).
func is_freezing() -> bool:
	return _current_temperature < FREEZING_THRESHOLD


## Returns true if the zone is at extreme cold (< -5°C).
func is_extreme_cold() -> bool:
	return _current_temperature < EXTREME_COLD_THRESHOLD


## Returns the distance from a position to this zone's center.
func distance_to(pos: Vector3) -> float:
	return global_position.distance_to(pos)


## Returns true if a position is within this zone's radius.
func contains_position(pos: Vector3) -> bool:
	return distance_to(pos) <= zone_radius


## Simulates entity entering the zone with cold effect.
## influence_amount: negative for cold entities (typical: -15 to -25)
func entity_enter(influence_amount: float) -> void:
	set_target_influence(influence_amount)


## Simulates entity leaving the zone.
func entity_leave() -> void:
	set_target_influence(0.0)


# --- Internal ---


func _compute_temperature() -> float:
	var temp := base_temperature

	# Apply entity influence
	temp += entity_influence

	# Apply natural variance
	if enable_natural_variance:
		temp += sin(_variance_phase) * NATURAL_VARIANCE

	return temp


func _update_entity_influence(delta: float) -> void:
	var diff := target_influence - entity_influence
	var change := influence_change_rate * delta

	if absf(diff) <= change:
		entity_influence = target_influence
	elif diff > 0:
		entity_influence += change
	else:
		entity_influence -= change

	entity_influence_changed.emit(entity_influence)


func _create_debug_visual() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = zone_radius
	mesh.height = zone_radius * 2.0

	var material := StandardMaterial3D.new()
	# Color based on temperature: blue = cold, red = warm
	var temp_ratio := clampf((_current_temperature - EXTREME_COLD_THRESHOLD) / 30.0, 0.0, 1.0)
	material.albedo_color = Color(temp_ratio, 0.2, 1.0 - temp_ratio, 0.2)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = material

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.name = "DebugVisual"
	add_child(mesh_instance)
