class_name ContaminatedEMFSource
extends Node3D
## A false EMF source planted by a Cultist that decays over time.
##
## When in PLANTED state, appears identical to a real Level 5 EMF source.
## As it decays, the readings become increasingly erratic and eventually
## the source disappears.
##
## Decay behavior:
## - PLANTED (0-60s): Steady Level 5, indistinguishable from real
## - UNSTABLE (60-120s): Flickers between levels randomly
## - DEGRADED (120-180s): Resets to 0 periodically, erratic behavior
## - EXPIRED (180+s): Source disappears, no longer detected

# --- Signals ---

## Emitted when the decay state changes.
signal decay_state_changed(old_state: int, new_state: int)

## Emitted when this source expires and should be removed.
signal expired()

# --- Constants ---

## Activity level that produces Level 5 EMF readings.
const LEVEL_5_ACTIVITY: float = 2.0

## Activity level that produces Level 0 EMF readings.
const LEVEL_0_ACTIVITY: float = 0.0

## Flicker rate during UNSTABLE state (changes per second).
const UNSTABLE_FLICKER_RATE: float = 3.0

## Reset frequency during DEGRADED state (resets per second).
const DEGRADED_RESET_RATE: float = 0.5

## Duration of Level 0 reset during DEGRADED state.
const DEGRADED_RESET_DURATION: float = 0.3

# --- Export ---

@export_group("Debug")
@export var debug_visible: bool = false  ## Show debug visual in editor

# --- State ---

## Reference to the contaminated evidence this source represents.
var _evidence: Resource = null  # ContaminatedEvidence

## Current decay state (cached, updated via _evidence).
var _current_decay_state: int = CultistEnums.DecayState.PLANTED

## Current activity level (modified by decay effects).
var _current_activity: float = LEVEL_5_ACTIVITY

## Timer for state updates.
var _update_timer: float = 0.0

## Timer for flicker/reset effects.
var _effect_timer: float = 0.0

## Whether currently in a degraded reset (showing 0).
var _in_degraded_reset: bool = false

## Time accumulator for degraded reset.
var _degraded_reset_timer: float = 0.0

## Random number generator for deterministic but varied behavior.
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("emf_source")
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

	# Apply decay effects
	_effect_timer += delta
	_apply_decay_effects(delta)


## Initializes this source with the contaminated evidence it represents.
func initialize(evidence: Resource) -> void:
	_evidence = evidence
	_current_decay_state = CultistEnums.DecayState.PLANTED
	_current_activity = LEVEL_5_ACTIVITY


## Returns the current EMF activity level.
## Called by EMFReader to determine signal strength.
## Returns decay-state-dependent values to create visual tells.
func get_emf_activity() -> float:
	return _current_activity


## Returns the current decay state.
func get_decay_state() -> int:
	return _current_decay_state


## Returns true if this source has expired.
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
		_current_activity = LEVEL_0_ACTIVITY
		expired.emit()


# --- Internal: Decay Effects ---


func _apply_decay_effects(_delta: float) -> void:
	match _current_decay_state:
		CultistEnums.DecayState.PLANTED:
			_apply_planted_effect()
		CultistEnums.DecayState.UNSTABLE:
			_apply_unstable_effect()
		CultistEnums.DecayState.DEGRADED:
			_apply_degraded_effect(_delta)
		CultistEnums.DecayState.EXPIRED:
			_apply_expired_effect()


## PLANTED: Steady Level 5 reading (indistinguishable from real).
func _apply_planted_effect() -> void:
	_current_activity = LEVEL_5_ACTIVITY


## UNSTABLE: EMF flickers between levels randomly.
## Creates subtle but noticeable inconsistency.
func _apply_unstable_effect() -> void:
	# Flicker at defined rate
	var flicker_interval: float = 1.0 / UNSTABLE_FLICKER_RATE
	if _effect_timer >= flicker_interval:
		_effect_timer = 0.0

		# Randomly choose between Level 5 (normal) and lower levels
		var roll := _rng.randf()
		if roll < 0.6:
			# 60% chance: normal Level 5
			_current_activity = LEVEL_5_ACTIVITY
		elif roll < 0.8:
			# 20% chance: Level 4
			_current_activity = 1.5
		elif roll < 0.95:
			# 15% chance: Level 3
			_current_activity = 1.0
		else:
			# 5% chance: Level 2
			_current_activity = 0.6


## DEGRADED: EMF resets to 0 periodically, erratic behavior.
## Very noticeable to observant players.
func _apply_degraded_effect(delta: float) -> void:
	if _in_degraded_reset:
		# Currently showing Level 0
		_degraded_reset_timer += delta
		if _degraded_reset_timer >= DEGRADED_RESET_DURATION:
			_in_degraded_reset = false
			_degraded_reset_timer = 0.0
		_current_activity = LEVEL_0_ACTIVITY
		return

	# Check for reset trigger
	var reset_interval: float = 1.0 / DEGRADED_RESET_RATE
	if _effect_timer >= reset_interval:
		_effect_timer = 0.0

		# Higher chance of erratic behavior
		var roll := _rng.randf()
		if roll < 0.3:
			# 30% chance: trigger reset to 0
			_in_degraded_reset = true
			_degraded_reset_timer = 0.0
			_current_activity = LEVEL_0_ACTIVITY
		elif roll < 0.5:
			# 20% chance: jump to random level
			var random_level := _rng.randi_range(1, 5)
			_current_activity = random_level * 0.4
		else:
			# 50% chance: normal Level 5 (but unstable)
			var noise := _rng.randf_range(-0.3, 0.3)
			_current_activity = LEVEL_5_ACTIVITY + noise


## EXPIRED: EMF reading disappears entirely.
func _apply_expired_effect() -> void:
	_current_activity = LEVEL_0_ACTIVITY


# --- Debug Visual ---


func _create_debug_visual() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.25
	mesh.height = 0.5

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.2, 0.2, 0.5)  # Red tint for contaminated
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(1.0, 0.2, 0.2)
	material.emission_energy_multiplier = 0.5
	mesh.material = material

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.name = "DebugVisual"
	add_child(mesh_instance)
