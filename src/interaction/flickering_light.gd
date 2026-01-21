class_name FlickeringLight
extends Node3D
## A light fixture that can flicker and break due to entity activity.
##
## Supports multiple flicker patterns based on entity type:
## - SUBTLE: Slight dimming (ambient entity presence)
## - RHYTHMIC: Regular on/off pattern (communicating entity)
## - CHAOTIC: Rapid random flickering (aggressive entity)
## - STROBE: Fast strobe effect (very aggressive)
##
## Aggressive entities can also break/explode lights permanently.
## Light state syncs across the network.

# --- Signals ---

## Emitted when flicker starts.
signal flicker_started(pattern: FlickerPattern, entity_type: String)

## Emitted when flicker ends.
signal flicker_ended

## Emitted when light is broken/exploded.
signal light_broken(entity_type: String)

## Emitted when light state changes.
signal light_state_changed(new_state: LightState)

# --- Enums ---

## Current state of the light.
enum LightState {
	ON,  ## Light fully on
	OFF,  ## Light turned off (by player or entity)
	FLICKERING,  ## Currently flickering
	BROKEN,  ## Permanently broken (cannot be turned on)
}

## Flicker patterns for different entity behaviors.
enum FlickerPattern {
	SUBTLE,  ## Slight dimming (30% reduction, slow)
	RHYTHMIC,  ## Regular on/off (1Hz pattern)
	CHAOTIC,  ## Rapid random flickering
	STROBE,  ## Fast strobe (10Hz)
	DYING,  ## Progressively dimmer before breaking
}

# --- Constants ---

## Visible range for flicker effect.
const VISIBLE_RANGE := 20.0

## Default flicker duration (seconds).
const DEFAULT_FLICKER_DURATION := 5.0

## Sound range for electrical buzz.
const BUZZ_AUDIBLE_RANGE := 10.0

## Sound range for break/explosion.
const BREAK_AUDIBLE_RANGE := 25.0

# --- Export: Light Settings ---

@export_group("Light")
## The actual Light3D node to control (OmniLight3D or SpotLight3D).
@export var light_node: Light3D

## Base energy level when fully on.
@export var base_energy: float = 1.0

## Whether this light can be broken by entities.
@export var can_break: bool = true

## Whether the light starts on.
@export var starts_on: bool = true

@export_group("Audio")
## Sound for electrical buzz during flicker.
@export var buzz_sound: AudioStream

## Sound when light breaks/explodes.
@export var break_sound: AudioStream

## Sound when light turns on/off.
@export var switch_sound: AudioStream

# --- State ---

var _light_state: LightState = LightState.ON
var _current_pattern: FlickerPattern = FlickerPattern.SUBTLE
var _flicker_timer: float = 0.0
var _flicker_duration: float = 0.0
var _pattern_phase: float = 0.0
var _last_entity_type: String = ""
var _audio_player: AudioStreamPlayer3D = null


func _ready() -> void:
	add_to_group("lights")

	if not starts_on:
		_set_light_state(LightState.OFF)
		_set_light_energy(0.0)

	# Auto-find Light3D child if not assigned
	if light_node == null:
		for child in get_children():
			if child is Light3D:
				light_node = child
				break


func _process(delta: float) -> void:
	if _light_state != LightState.FLICKERING:
		return

	_flicker_timer -= delta
	_pattern_phase += delta

	if _flicker_timer <= 0.0:
		_end_flicker()
		return

	# Update light based on pattern
	_apply_flicker_pattern(delta)


# --- Entity Interface ---


## Called by entities to cause light flickering.
## Returns true if flicker was started.
func entity_flicker(
	pattern: FlickerPattern,
	duration: float,
	entity_type: String
) -> bool:
	if _light_state == LightState.BROKEN:
		return false

	if _light_state == LightState.FLICKERING:
		# Already flickering - extend duration
		_flicker_duration = maxf(_flicker_timer, duration)
		_flicker_timer = _flicker_duration
		return true

	_start_flicker(pattern, duration, entity_type)
	return true


## Called by entities to break/explode the light.
## Returns true if light was broken.
func entity_break(entity_type: String) -> bool:
	if not can_break:
		return false

	if _light_state == LightState.BROKEN:
		return false

	_break_light(entity_type)
	return true


## Starts a dying flicker pattern that ends with the light breaking.
func entity_dying_flicker(entity_type: String) -> bool:
	if not can_break:
		return false

	if _light_state == LightState.BROKEN:
		return false

	_start_flicker(FlickerPattern.DYING, 3.0, entity_type)
	return true


# --- Player Interaction ---


## Toggles the light on/off (if not broken).
func toggle() -> bool:
	if _light_state == LightState.BROKEN:
		return false

	if _light_state == LightState.FLICKERING:
		_end_flicker()

	if _light_state == LightState.ON:
		_set_light_state(LightState.OFF)
		_set_light_energy(0.0)
	else:
		_set_light_state(LightState.ON)
		_set_light_energy(base_energy)

	_play_switch_sound()
	return true


## Turns light on (if not broken).
func turn_on() -> bool:
	if _light_state == LightState.BROKEN:
		return false

	if _light_state == LightState.FLICKERING:
		_end_flicker()

	_set_light_state(LightState.ON)
	_set_light_energy(base_energy)
	_play_switch_sound()
	return true


## Turns light off (if not broken).
func turn_off() -> bool:
	if _light_state == LightState.BROKEN:
		return false

	if _light_state == LightState.FLICKERING:
		_end_flicker()

	_set_light_state(LightState.OFF)
	_set_light_energy(0.0)
	_play_switch_sound()
	return true


# --- Internal: Flicker Logic ---


func _start_flicker(pattern: FlickerPattern, duration: float, entity_type: String) -> void:
	var was_on := _light_state == LightState.ON

	_current_pattern = pattern
	_flicker_duration = duration
	_flicker_timer = duration
	_pattern_phase = 0.0
	_last_entity_type = entity_type
	_set_light_state(LightState.FLICKERING)

	flicker_started.emit(pattern, entity_type)
	_emit_flicker_event("start", pattern, entity_type)

	# Start buzz sound
	_start_buzz_sound()


func _end_flicker() -> void:
	_stop_buzz_sound()

	if _current_pattern == FlickerPattern.DYING and can_break:
		# Dying pattern ends with break
		_break_light(_last_entity_type)
	else:
		# Return to ON state
		_set_light_state(LightState.ON)
		_set_light_energy(base_energy)

	flicker_ended.emit()


func _apply_flicker_pattern(_delta: float) -> void:
	var energy := 0.0

	match _current_pattern:
		FlickerPattern.SUBTLE:
			# Slight dimming with slow oscillation
			energy = base_energy * (0.7 + 0.3 * sin(_pattern_phase * 2.0))

		FlickerPattern.RHYTHMIC:
			# 1Hz on/off pattern
			var phase := fmod(_pattern_phase, 1.0)
			energy = base_energy if phase < 0.5 else 0.0

		FlickerPattern.CHAOTIC:
			# Random flickering
			if randf() < 0.3:
				energy = base_energy * randf_range(0.0, 1.0)
			else:
				energy = base_energy * randf_range(0.6, 1.0)

		FlickerPattern.STROBE:
			# 10Hz strobe
			var phase := fmod(_pattern_phase * 10.0, 1.0)
			energy = base_energy if phase < 0.5 else 0.0

		FlickerPattern.DYING:
			# Progressive dimming with flickering
			var time_ratio := 1.0 - (_flicker_timer / _flicker_duration)
			var dim_factor := 1.0 - (time_ratio * 0.8)  # Dims to 20%
			var flicker := randf_range(0.7, 1.0) if randf() > 0.3 else randf_range(0.0, 0.5)
			energy = base_energy * dim_factor * flicker

	_set_light_energy(energy)


func _break_light(entity_type: String) -> void:
	_stop_buzz_sound()
	_set_light_state(LightState.BROKEN)
	_set_light_energy(0.0)
	_last_entity_type = entity_type

	_play_break_sound()
	light_broken.emit(entity_type)
	_emit_break_event(entity_type)


# --- Internal: Light Control ---


func _set_light_state(new_state: LightState) -> void:
	if _light_state != new_state:
		_light_state = new_state
		light_state_changed.emit(new_state)


func _set_light_energy(energy: float) -> void:
	if light_node:
		light_node.light_energy = energy


# --- Internal: Audio ---


func _start_buzz_sound() -> void:
	if buzz_sound == null:
		return

	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.stream = buzz_sound
	_audio_player.max_distance = BUZZ_AUDIBLE_RANGE
	add_child(_audio_player)
	_audio_player.play()


func _stop_buzz_sound() -> void:
	if _audio_player:
		_audio_player.stop()
		_audio_player.queue_free()
		_audio_player = null


func _play_break_sound() -> void:
	if break_sound == null:
		return
	_play_spatial_audio(break_sound, BREAK_AUDIBLE_RANGE)


func _play_switch_sound() -> void:
	if switch_sound == null:
		return
	_play_spatial_audio(switch_sound, BUZZ_AUDIBLE_RANGE)


func _play_spatial_audio(stream: AudioStream, max_distance: float) -> void:
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.max_distance = max_distance
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


# --- Internal: Events ---


func _emit_flicker_event(action: String, pattern: FlickerPattern, entity_type: String) -> void:
	var event_bus := _get_event_bus()
	if event_bus and event_bus.has_signal("light_flickered"):
		event_bus.light_flickered.emit(
			get_path(),
			action,
			pattern,
			entity_type,
			global_position
		)


func _emit_break_event(entity_type: String) -> void:
	var event_bus := _get_event_bus()
	if event_bus and event_bus.has_signal("light_broken"):
		event_bus.light_broken.emit(get_path(), entity_type, global_position)


func _get_event_bus() -> Node:
	if has_node("/root/EventBus"):
		return get_node("/root/EventBus")
	return null


# --- Public API ---


## Returns the current light state.
func get_light_state() -> LightState:
	return _light_state


## Returns true if light is on.
func is_on() -> bool:
	return _light_state == LightState.ON


## Returns true if light is broken.
func is_broken() -> bool:
	return _light_state == LightState.BROKEN


## Returns true if light is flickering.
func is_flickering() -> bool:
	return _light_state == LightState.FLICKERING


## Returns the current flicker pattern.
func get_current_pattern() -> FlickerPattern:
	return _current_pattern


## Returns the entity type that last affected this light.
func get_last_entity_type() -> String:
	return _last_entity_type


## Repairs a broken light (for testing/reset).
func repair() -> void:
	if _light_state == LightState.BROKEN:
		_set_light_state(LightState.ON)
		_set_light_energy(base_energy)


# --- Network State ---


func get_network_state() -> Dictionary:
	return {
		"light_state": _light_state,
		"current_pattern": _current_pattern,
		"flicker_timer": _flicker_timer,
		"pattern_phase": _pattern_phase,
		"last_entity_type": _last_entity_type,
	}


func apply_network_state(state: Dictionary) -> void:
	if state.has("light_state"):
		_light_state = state.light_state as LightState
	if state.has("current_pattern"):
		_current_pattern = state.current_pattern as FlickerPattern
	if state.has("flicker_timer"):
		_flicker_timer = state.flicker_timer
	if state.has("pattern_phase"):
		_pattern_phase = state.pattern_phase
	if state.has("last_entity_type"):
		_last_entity_type = state.last_entity_type

	# Apply visual state
	match _light_state:
		LightState.ON:
			_set_light_energy(base_energy)
		LightState.OFF, LightState.BROKEN:
			_set_light_energy(0.0)
