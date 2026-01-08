class_name EMFSource
extends Node3D
## EMF source for testing and entity integration.
##
## Place this in the scene and add to "emf_source" group to be detected by
## EMF Readers. Activity level controls detection strength.
##
## For entity integration: Entity AI will control activity level based on
## manifestation state. High activity during manifestation = Level 5 readings.

# --- Signals ---

signal activity_changed(new_activity: float)

# --- Export ---

@export_group("EMF Settings")
@export_range(0.0, 2.0) var base_activity: float = 1.0  ## Base EMF activity level
@export var auto_pulse: bool = false  ## Enable periodic activity spikes
@export var pulse_interval: float = 5.0  ## Seconds between pulses
@export var pulse_duration: float = 2.0  ## Duration of activity spike
@export var pulse_multiplier: float = 2.0  ## Activity multiplier during pulse

@export_group("Debug")
@export var debug_visible: bool = false  ## Show debug sphere in editor

# --- State ---

var _current_activity: float = 1.0
var _pulse_timer: float = 0.0
var _is_pulsing: bool = false


func _ready() -> void:
	add_to_group("emf_source")
	_current_activity = base_activity

	if debug_visible:
		_create_debug_visual()


func _process(delta: float) -> void:
	# Always process pulse decay (manual or auto-triggered)
	if _is_pulsing:
		_update_pulse_decay(delta)
	elif auto_pulse:
		_update_auto_pulse(delta)


## Returns the current EMF activity level.
## Called by EMFReader to determine signal strength.
func get_emf_activity() -> float:
	return _current_activity


## Sets the activity level directly.
## Use this for entity AI to control EMF readings.
func set_activity(activity: float) -> void:
	var old_activity := _current_activity
	_current_activity = maxf(0.0, activity)
	if _current_activity != old_activity:
		activity_changed.emit(_current_activity)


## Triggers a temporary activity spike.
## Useful for entity manifestation events.
func trigger_spike(duration: float = 2.0, multiplier: float = 2.0) -> void:
	_is_pulsing = true
	_pulse_timer = duration
	_current_activity = base_activity * multiplier
	activity_changed.emit(_current_activity)


## Returns true if currently in an activity spike.
func is_active() -> bool:
	return _current_activity > base_activity or _is_pulsing


# --- Internal ---


func _update_pulse_decay(delta: float) -> void:
	_pulse_timer -= delta
	if _pulse_timer <= 0.0:
		_is_pulsing = false
		_current_activity = base_activity
		_pulse_timer = pulse_interval  # Reset timer for next auto-pulse cycle
		activity_changed.emit(_current_activity)


func _update_auto_pulse(delta: float) -> void:
	_pulse_timer -= delta
	if _pulse_timer <= 0.0:
		trigger_spike(pulse_duration, pulse_multiplier)


func _create_debug_visual() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.3
	mesh.height = 0.6

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.8, 1.0, 0.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(0.2, 0.8, 1.0)
	material.emission_energy_multiplier = 0.5
	mesh.material = material

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.name = "DebugVisual"
	add_child(mesh_instance)
