class_name ContaminatedSpectralAnchor
extends Node3D
## A false spectral anchor planted by a Cultist that decays over time.
##
## When in PLANTED state, appears identical to a real entity's spectral signature.
## As it decays, the pattern and color become increasingly unstable and eventually
## the anchor provides garbled/unreadable data.
##
## Decay behavior:
## - PLANTED (0-60s): Consistent shape and color, indistinguishable from real
## - UNSTABLE (60-120s): Shape flickers occasionally
## - DEGRADED (120-180s): Shape unstable, color shifts erratically
## - EXPIRED (180+s): Reading becomes completely garbled/unusable

const PrismEnumsScript := preload("res://src/equipment/spectral_prism/prism_enums.gd")

# --- Signals ---

## Emitted when the decay state changes.
signal decay_state_changed(old_state: int, new_state: int)

## Emitted when this anchor expires and should be removed.
signal expired()

# --- Constants ---

## Flicker rate during UNSTABLE state (flickers per second).
const UNSTABLE_FLICKER_RATE: float = 2.0

## Duration of pattern flicker during UNSTABLE state.
const UNSTABLE_FLICKER_DURATION: float = 0.15

## Shift rate during DEGRADED state (shifts per second).
const DEGRADED_SHIFT_RATE: float = 4.0

# --- Export ---

@export_group("Debug")
@export var debug_visible: bool = false  ## Show debug visual in editor

# --- State ---

## Reference to the contaminated evidence this anchor represents.
var _evidence: Resource = null  # ContaminatedEvidence

## Current decay state (cached, updated via _evidence).
var _current_decay_state: int = CultistEnums.DecayState.PLANTED

## The "true" (false) pattern set by Cultist.
var _base_pattern: int = PrismEnumsScript.PrismPattern.TRIANGLE

## The "true" (false) color matching the pattern.
var _base_color: int = PrismEnumsScript.PrismColor.BLUE_VIOLET

## Currently displayed pattern (may differ due to decay effects).
var _current_pattern: int = PrismEnumsScript.PrismPattern.TRIANGLE

## Currently displayed color (may differ due to decay effects).
var _current_color: int = PrismEnumsScript.PrismColor.BLUE_VIOLET

## Timer for state updates.
var _update_timer: float = 0.0

## Timer for decay effects.
var _effect_timer: float = 0.0

## Whether currently in a flicker state.
var _in_flicker: bool = false

## Timer for current flicker.
var _flicker_timer: float = 0.0

## Random number generator for varied behavior.
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("spectral_anchors")
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

	# Update effect timer
	_effect_timer += delta

	# Update flicker timer
	if _in_flicker:
		_flicker_timer += delta
		if _flicker_timer >= UNSTABLE_FLICKER_DURATION:
			_in_flicker = false
			_flicker_timer = 0.0

	# Update pattern/color based on decay state
	_update_display()


## Initializes this anchor with the contaminated evidence it represents.
## Sets a random false pattern that mismatches the true entity.
func initialize(evidence: Resource) -> void:
	_evidence = evidence
	_current_decay_state = CultistEnums.DecayState.PLANTED

	# Pick a random pattern for the false reading
	var patterns := PrismEnumsScript.get_all_patterns()
	_base_pattern = patterns[_rng.randi() % patterns.size()]
	_base_color = PrismEnumsScript.get_expected_color(_base_pattern)

	_current_pattern = _base_pattern
	_current_color = _base_color


## Initializes this anchor with a specific false pattern.
func initialize_with_pattern(
	evidence: Resource,
	false_pattern: int,
	false_color: int = -1
) -> void:
	_evidence = evidence
	_current_decay_state = CultistEnums.DecayState.PLANTED

	_base_pattern = false_pattern
	if false_color >= 0:
		_base_color = false_color
	else:
		_base_color = PrismEnumsScript.get_expected_color(false_pattern)

	_current_pattern = _base_pattern
	_current_color = _base_color


## Returns the current pattern for this anchor.
## This is called by the Calibrator to get the displayed pattern.
func get_true_pattern() -> int:
	return _current_pattern


## Returns the current color for this anchor.
## This is called by the Lens Reader to get the displayed color.
func get_true_color() -> int:
	return _current_color


## Returns the current decay state.
func get_decay_state() -> int:
	return _current_decay_state


## Returns true if this anchor has expired.
func has_expired() -> bool:
	return _current_decay_state == CultistEnums.DecayState.EXPIRED


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
		expired.emit()


# --- Internal: Display Updates ---


func _update_display() -> void:
	match _current_decay_state:
		CultistEnums.DecayState.PLANTED:
			_apply_planted_display()
		CultistEnums.DecayState.UNSTABLE:
			_apply_unstable_display()
		CultistEnums.DecayState.DEGRADED:
			_apply_degraded_display()
		CultistEnums.DecayState.EXPIRED:
			_apply_expired_display()


## PLANTED: Consistent shape and color.
## Indistinguishable from real entity spectral signature.
func _apply_planted_display() -> void:
	_current_pattern = _base_pattern
	_current_color = _base_color


## UNSTABLE: Shape flickers occasionally.
## Calibrator sees brief shape changes (pattern flickers to wrong shape).
func _apply_unstable_display() -> void:
	# Check if we should start a new flicker
	var flicker_interval: float = 1.0 / UNSTABLE_FLICKER_RATE
	if not _in_flicker and fmod(_effect_timer, flicker_interval) < 0.05:
		if _rng.randf() < 0.7:  # 70% chance to flicker
			_in_flicker = true
			_flicker_timer = 0.0

	if _in_flicker:
		# During flicker, show a random different pattern
		var patterns := PrismEnumsScript.get_all_patterns()
		var random_pattern: int = patterns[_rng.randi() % patterns.size()]
		# Make sure it's different from base
		while random_pattern == _base_pattern and patterns.size() > 1:
			random_pattern = patterns[_rng.randi() % patterns.size()]
		_current_pattern = random_pattern
		# Color stays consistent during unstable (only pattern flickers)
		_current_color = _base_color
	else:
		# Normal display
		_current_pattern = _base_pattern
		_current_color = _base_color


## DEGRADED: Shape unstable, color shifts erratically.
## Both Calibrator and Lens Reader see obvious issues.
func _apply_degraded_display() -> void:
	var shift_interval: float = 1.0 / DEGRADED_SHIFT_RATE

	# Frequent random shifts
	if fmod(_effect_timer, shift_interval) < 0.02:
		var patterns := PrismEnumsScript.get_all_patterns()
		var colors := PrismEnumsScript.get_all_colors()

		# 50% chance to shift pattern
		if _rng.randf() < 0.5:
			_current_pattern = patterns[_rng.randi() % patterns.size()]

		# 50% chance to shift color (independently!)
		if _rng.randf() < 0.5:
			_current_color = colors[_rng.randi() % colors.size()]

		# This creates mismatches - a clear sign of contamination


## EXPIRED: Reading becomes completely garbled.
## Returns NONE for both pattern and color, making it unusable.
func _apply_expired_display() -> void:
	_current_pattern = PrismEnumsScript.PrismPattern.NONE
	_current_color = PrismEnumsScript.PrismColor.NONE


# --- Debug Visual ---


func _create_debug_visual() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.4
	mesh.height = 0.8

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.2, 0.8, 0.5)  # Purple tint for prism
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(0.6, 0.2, 0.6)
	material.emission_energy_multiplier = 0.5
	mesh.material = material

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.name = "DebugVisual"
	add_child(mesh_instance)
