class_name LightSwitch
extends Interactable
## A wall switch that toggles linked room lights.
##
## The switch controls one or more OmniLight3D/SpotLight3D nodes.
## State is synced across the network.

# --- Signals ---

## Emitted when light state changes.
signal light_toggled(is_on: bool)

# --- Export: Switch Settings ---

@export_group("Light Control")
## The light nodes this switch controls.
@export var controlled_lights: Array[NodePath] = []

## Whether the lights start on.
@export var starts_on: bool = true

@export_group("Audio")
## Sound for switch toggle.
@export var toggle_sound: AudioStream

# --- State ---

var _is_on: bool = true
var _light_nodes: Array[Node3D] = []


func _ready() -> void:
	super._ready()
	add_to_group("light_switches")
	interaction_type = InteractionType.TOGGLE
	_is_on = starts_on
	_update_prompt()

	# Cache light references
	_cache_light_nodes()

	# Apply initial state
	_apply_light_state()


## Caches references to controlled light nodes.
func _cache_light_nodes() -> void:
	_light_nodes.clear()
	for path in controlled_lights:
		var light := get_node_or_null(path) as Node3D
		if light:
			_light_nodes.append(light)
		else:
			push_warning("LightSwitch: Could not find light at path: %s" % path)


# --- Player Interaction ---


func _interact_impl(_player: Node) -> bool:
	_toggle()
	return true


func get_interaction_prompt() -> String:
	return "Turn Off" if _is_on else "Turn On"


# --- Light Control ---


## Toggles the light state.
func _toggle() -> void:
	_is_on = not _is_on
	_apply_light_state()
	_update_prompt()
	_play_toggle_sound()
	light_toggled.emit(_is_on)


## Applies the current light state to all controlled lights.
func _apply_light_state() -> void:
	for light in _light_nodes:
		if light.has_method("set_visible"):
			light.visible = _is_on
		# Also try enabling/disabling if it's a Light3D
		if light is Light3D:
			(light as Light3D).light_energy = 1.0 if _is_on else 0.0


func _update_prompt() -> void:
	interaction_prompt = get_interaction_prompt()


# --- Public API ---


## Returns whether the lights are currently on.
func is_on() -> bool:
	return _is_on


## Sets the light state directly.
func set_on(on: bool) -> void:
	if _is_on != on:
		_is_on = on
		_apply_light_state()
		_update_prompt()
		light_toggled.emit(_is_on)


## Adds a light to control at runtime.
func add_controlled_light(light: Node3D) -> void:
	if light and light not in _light_nodes:
		_light_nodes.append(light)
		# Apply current state to new light
		if light is Light3D:
			(light as Light3D).light_energy = 1.0 if _is_on else 0.0
		else:
			light.visible = _is_on


## Removes a light from control.
func remove_controlled_light(light: Node3D) -> void:
	_light_nodes.erase(light)


## Returns all controlled light nodes.
func get_controlled_lights() -> Array[Node3D]:
	return _light_nodes


# --- Audio ---


func _play_toggle_sound() -> void:
	if toggle_sound == null:
		return
	var player := AudioStreamPlayer3D.new()
	player.stream = toggle_sound
	player.max_distance = 10.0
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


# --- Network State ---


func get_network_state() -> Dictionary:
	var state := super.get_network_state()
	state["is_on"] = _is_on
	return state


func apply_network_state(state: Dictionary) -> void:
	super.apply_network_state(state)
	if state.has("is_on"):
		_is_on = state.is_on
		_apply_light_state()
		_update_prompt()
