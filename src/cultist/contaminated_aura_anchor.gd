class_name ContaminatedAuraAnchor
extends Node3D
## A false aura anchor planted by a Cultist that decays over time.
##
## When in PLANTED state, appears identical to a real entity's aura signature.
## As it decays, the color and form become increasingly unstable and eventually
## the anchor provides no readable aura data.
##
## Decay behavior:
## - PLANTED (0-60s): Clear aura trail, consistent color/form
## - UNSTABLE (60-120s): Trail fades slightly, occasional flicker
## - DEGRADED (120-180s): Trail direction inconsistent, form unstable
## - EXPIRED (180+s): Aura trail disappears (NONE values)

const AuraEnumsScript := preload("res://src/equipment/aura/aura_enums.gd")

# --- Signals ---

## Emitted when the decay state changes.
signal decay_state_changed(old_state: int, new_state: int)

## Emitted when this anchor expires and should be removed.
signal expired()

# --- Constants ---

## Flicker rate during UNSTABLE state (flickers per second).
const UNSTABLE_FLICKER_RATE: float = 1.5

## Duration of flicker during UNSTABLE state.
const UNSTABLE_FLICKER_DURATION: float = 0.2

## Shift rate during DEGRADED state (shifts per second).
const DEGRADED_SHIFT_RATE: float = 5.0

## Opacity multiplier during UNSTABLE state (slightly faded).
const UNSTABLE_OPACITY: float = 0.8

## Opacity multiplier during DEGRADED state (significantly faded).
const DEGRADED_OPACITY: float = 0.5

# --- Export ---

@export_group("Debug")
@export var debug_visible: bool = false  ## Show debug visual in editor

# --- State ---

## Reference to the contaminated evidence this anchor represents.
var _evidence: Resource = null  # ContaminatedEvidence

## Current decay state (cached, updated via _evidence).
var _current_decay_state: int = CultistEnums.DecayState.PLANTED

## The "true" (false) color set by Cultist.
var _base_color: int = AuraEnumsScript.AuraColor.COLD_BLUE

## The "true" (false) form matching the color.
var _base_form: int = AuraEnumsScript.AuraForm.TIGHT_CONTAINED

## Currently displayed color (may differ due to decay effects).
var _current_color: int = AuraEnumsScript.AuraColor.COLD_BLUE

## Currently displayed form (may differ due to decay effects).
var _current_form: int = AuraEnumsScript.AuraForm.TIGHT_CONTAINED

## Current opacity/intensity (1.0 = full, 0.0 = invisible).
var _current_opacity: float = 1.0

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
	add_to_group("aura_anchors")
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

	# Update color/form based on decay state
	_update_display()


## Initializes this anchor with the contaminated evidence it represents.
## Sets a random false color/form combination.
func initialize(evidence: Resource) -> void:
	_evidence = evidence
	_current_decay_state = CultistEnums.DecayState.PLANTED

	# Pick a random color/form for the false reading
	var colors := AuraEnumsScript.get_all_colors()
	var forms := AuraEnumsScript.get_all_forms()
	_base_color = colors[_rng.randi() % colors.size()]
	_base_form = forms[_rng.randi() % forms.size()]

	_current_color = _base_color
	_current_form = _base_form
	_current_opacity = 1.0


## Initializes this anchor with a specific false color/form.
func initialize_with_aura(
	evidence: Resource,
	false_color: int,
	false_form: int = -1
) -> void:
	_evidence = evidence
	_current_decay_state = CultistEnums.DecayState.PLANTED

	_base_color = false_color
	if false_form >= 0:
		_base_form = false_form
	else:
		_base_form = AuraEnumsScript.get_expected_form(false_color)

	_current_color = _base_color
	_current_form = _base_form
	_current_opacity = 1.0


## Returns the current aura color for this anchor.
## This is called by the Aura Imager to get the displayed color.
func get_true_color() -> int:
	return _current_color


## Returns the current aura form for this anchor.
## This is called by the Aura Imager to get the displayed form.
func get_true_form() -> int:
	return _current_form


## Returns the current opacity/intensity (for rendering).
func get_opacity() -> float:
	return _current_opacity


## Returns the current decay state.
func get_decay_state() -> int:
	return _current_decay_state


## Returns true if this anchor has expired.
func has_expired() -> bool:
	return _current_decay_state == CultistEnums.DecayState.EXPIRED


## Returns true if the color and form are consistent (for verification).
func is_consistent() -> bool:
	return AuraEnumsScript.is_consistent(_current_color, _current_form)


## Returns the combined signature string.
func get_signature() -> String:
	return AuraEnumsScript.get_combined_signature(_current_color, _current_form)


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


## PLANTED: Clear aura trail, consistent color/form.
## Indistinguishable from real entity aura signature.
func _apply_planted_display() -> void:
	_current_color = _base_color
	_current_form = _base_form
	_current_opacity = 1.0


## UNSTABLE: Trail fades slightly, occasional flicker.
## Imager sees brief flickers in the display.
func _apply_unstable_display() -> void:
	_current_opacity = UNSTABLE_OPACITY

	# Check if we should start a new flicker
	var flicker_interval: float = 1.0 / UNSTABLE_FLICKER_RATE
	if not _in_flicker and fmod(_effect_timer, flicker_interval) < 0.05:
		if _rng.randf() < 0.6:  # 60% chance to flicker
			_in_flicker = true
			_flicker_timer = 0.0

	if _in_flicker:
		# During flicker, briefly show different color OR form (not both)
		if _rng.randf() < 0.5:
			# Flicker color
			var colors := AuraEnumsScript.get_all_colors()
			_current_color = colors[_rng.randi() % colors.size()]
			_current_form = _base_form
		else:
			# Flicker form
			var forms := AuraEnumsScript.get_all_forms()
			_current_color = _base_color
			_current_form = forms[_rng.randi() % forms.size()]
	else:
		# Normal display
		_current_color = _base_color
		_current_form = _base_form


## DEGRADED: Trail direction inconsistent, form unstable.
## Both color and form shift erratically - clearly contaminated.
func _apply_degraded_display() -> void:
	_current_opacity = DEGRADED_OPACITY

	var shift_interval: float = 1.0 / DEGRADED_SHIFT_RATE

	# Frequent random shifts
	if fmod(_effect_timer, shift_interval) < 0.02:
		var colors := AuraEnumsScript.get_all_colors()
		var forms := AuraEnumsScript.get_all_forms()

		# 50% chance to shift color
		if _rng.randf() < 0.5:
			_current_color = colors[_rng.randi() % colors.size()]

		# 50% chance to shift form
		if _rng.randf() < 0.5:
			_current_form = forms[_rng.randi() % forms.size()]

		# This creates mismatches - a clear sign of contamination


## EXPIRED: Aura trail disappears.
## Returns NONE for both color and form, making it unreadable.
func _apply_expired_display() -> void:
	_current_color = AuraEnumsScript.AuraColor.NONE
	_current_form = AuraEnumsScript.AuraForm.NONE
	_current_opacity = 0.0


# --- Debug Visual ---


func _create_debug_visual() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.3
	mesh.height = 0.6

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.8, 0.4, 0.5)  # Green tint for aura
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(0.2, 0.6, 0.3)
	material.emission_energy_multiplier = 0.5
	mesh.material = material

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.name = "DebugVisual"
	add_child(mesh_instance)
