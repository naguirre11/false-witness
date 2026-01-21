class_name SurfaceManifestation
extends Node3D
## A visible mark left on a surface by entity activity.
##
## Surface manifestations are persistent evidence that can be shown to
## other players. They include:
## - Writing on walls/mirrors (warnings, names, messages)
## - Handprints (bloody, ashy, frosty variants)
## - Scratch marks (claw marks, gouges)
## - Symbols (occult, geometric patterns)
##
## Unlike transient phenomena (flickers, throws), manifestations persist
## and serve as verifiable evidence locations.

# --- Signals ---

## Emitted when manifestation is created.
signal manifestation_created(type: ManifestationType, entity_type: String)

## Emitted when manifestation fades/decays.
signal manifestation_faded

## Emitted when a player examines this manifestation.
signal manifestation_examined(player_id: int)

# --- Enums ---

## Types of surface manifestation.
enum ManifestationType {
	WRITING,  ## Text on surface (warnings, names)
	HANDPRINT,  ## Hand or finger prints
	SCRATCH,  ## Claw marks, gouges
	SYMBOL,  ## Occult or geometric pattern
}

## Visual variants for handprints.
enum HandprintVariant {
	BLOODY,  ## Red/dark blood appearance
	ASHY,  ## Gray/black ashy appearance
	FROSTY,  ## Blue/white frost appearance
	DUSTY,  ## Brown/tan dusty appearance
}

## Appearance state of the manifestation.
enum AppearanceState {
	FORMING,  ## Manifestation appearing
	VISIBLE,  ## Fully visible
	FADING,  ## Gradually disappearing
	FADED,  ## No longer visible
}

# --- Constants ---

## Time for manifestation to fully appear (seconds).
const FORM_DURATION := 2.0

## Default time before manifestation starts fading (seconds).
const DEFAULT_PERSIST_TIME := 300.0  # 5 minutes

## Time for manifestation to fade away (seconds).
const FADE_DURATION := 10.0

## Examination range for players.
const EXAMINE_RANGE := 3.0

## Visible range for manifestation.
const VISIBLE_RANGE := 20.0

# --- Export: Manifestation Settings ---

@export_group("Manifestation")
## Type of this manifestation.
@export var manifestation_type: ManifestationType = ManifestationType.HANDPRINT

## Variant for handprints (ignored for other types).
@export var handprint_variant: HandprintVariant = HandprintVariant.BLOODY

## Text content for writing type.
@export var writing_text: String = ""

## Whether this manifestation persists indefinitely.
@export var permanent: bool = false

## How long before fading starts (seconds). Ignored if permanent.
@export var persist_time: float = DEFAULT_PERSIST_TIME

@export_group("Visual")
## Texture or decal to display.
@export var manifestation_texture: Texture2D

## Size of the manifestation (meters).
@export var manifestation_size: Vector2 = Vector2(0.5, 0.5)

## Color tint for the manifestation.
@export var tint_color: Color = Color.WHITE

@export_group("Audio")
## Sound when manifestation appears.
@export var appear_sound: AudioStream

# --- State ---

var _appearance_state: AppearanceState = AppearanceState.FORMING
var _form_timer: float = 0.0
var _persist_timer: float = 0.0
var _fade_timer: float = 0.0
var _opacity: float = 0.0
var _entity_type: String = ""
var _creation_time: float = 0.0
var _examining_players: Array[int] = []
var _decal: Decal = null


func _ready() -> void:
	add_to_group("surface_manifestations")
	_creation_time = Time.get_ticks_msec() / 1000.0
	_setup_visual()


func _process(delta: float) -> void:
	match _appearance_state:
		AppearanceState.FORMING:
			_process_forming(delta)
		AppearanceState.VISIBLE:
			_process_visible(delta)
		AppearanceState.FADING:
			_process_fading(delta)


# --- Entity Interface ---


## Creates a manifestation at this location.
## Called by entity or evidence system.
func create_manifestation(
	type: ManifestationType,
	entity_type: String,
	content: String = ""
) -> void:
	manifestation_type = type
	_entity_type = entity_type

	if type == ManifestationType.WRITING:
		writing_text = content

	_appearance_state = AppearanceState.FORMING
	_form_timer = 0.0
	_creation_time = Time.get_ticks_msec() / 1000.0

	_play_appear_sound()
	manifestation_created.emit(type, entity_type)
	_emit_creation_event()


## Sets the handprint variant (for HANDPRINT type).
func set_handprint_variant(variant: HandprintVariant) -> void:
	handprint_variant = variant
	_update_visual_for_variant()


# --- Examination Interface ---


## Called when a player examines this manifestation.
func examine(player_id: int) -> Dictionary:
	if player_id not in _examining_players:
		_examining_players.append(player_id)
		manifestation_examined.emit(player_id)

	return get_evidence_data()


## Returns evidence data for this manifestation.
func get_evidence_data() -> Dictionary:
	return {
		"type": "SURFACE_MANIFESTATION",
		"manifestation_type": manifestation_type,
		"handprint_variant": handprint_variant if manifestation_type == ManifestationType.HANDPRINT else -1,
		"writing_text": writing_text,
		"entity_type": _entity_type,
		"location": global_position,
		"creation_time": _creation_time,
		"examining_players": _examining_players.duplicate(),
	}


## Returns true if this manifestation has been examined.
func has_been_examined() -> bool:
	return _examining_players.size() > 0


## Returns the list of players who have examined this.
func get_examining_players() -> Array[int]:
	return _examining_players


# --- State Processing ---


func _process_forming(delta: float) -> void:
	_form_timer += delta
	_opacity = clampf(_form_timer / FORM_DURATION, 0.0, 1.0)
	_update_visual_opacity()

	if _form_timer >= FORM_DURATION:
		_appearance_state = AppearanceState.VISIBLE
		_persist_timer = 0.0


func _process_visible(delta: float) -> void:
	if permanent:
		return

	_persist_timer += delta
	if _persist_timer >= persist_time:
		_appearance_state = AppearanceState.FADING
		_fade_timer = 0.0


func _process_fading(delta: float) -> void:
	_fade_timer += delta
	_opacity = 1.0 - clampf(_fade_timer / FADE_DURATION, 0.0, 1.0)
	_update_visual_opacity()

	if _fade_timer >= FADE_DURATION:
		_appearance_state = AppearanceState.FADED
		_opacity = 0.0
		manifestation_faded.emit()


# --- Visual Setup ---


func _setup_visual() -> void:
	# Create or find decal for surface projection
	_decal = get_node_or_null("Decal") as Decal
	if _decal == null:
		_decal = Decal.new()
		_decal.name = "Decal"
		add_child(_decal)

	_decal.size = Vector3(manifestation_size.x, 0.2, manifestation_size.y)

	if manifestation_texture:
		_decal.texture_albedo = manifestation_texture

	_update_visual_for_variant()
	_update_visual_opacity()


func _update_visual_for_variant() -> void:
	if _decal == null:
		return

	# Set color based on handprint variant
	if manifestation_type == ManifestationType.HANDPRINT:
		match handprint_variant:
			HandprintVariant.BLOODY:
				_decal.modulate = Color(0.7, 0.1, 0.1, 1.0) * tint_color
			HandprintVariant.ASHY:
				_decal.modulate = Color(0.3, 0.3, 0.3, 1.0) * tint_color
			HandprintVariant.FROSTY:
				_decal.modulate = Color(0.7, 0.9, 1.0, 1.0) * tint_color
			HandprintVariant.DUSTY:
				_decal.modulate = Color(0.6, 0.5, 0.4, 1.0) * tint_color
	else:
		_decal.modulate = tint_color


func _update_visual_opacity() -> void:
	if _decal == null:
		return

	var current_color := _decal.modulate
	current_color.a = _opacity
	_decal.modulate = current_color


# --- Audio ---


func _play_appear_sound() -> void:
	if appear_sound == null:
		return

	var player := AudioStreamPlayer3D.new()
	player.stream = appear_sound
	player.max_distance = VISIBLE_RANGE
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


# --- Events ---


func _emit_creation_event() -> void:
	var event_bus := _get_event_bus()
	if event_bus and event_bus.has_signal("surface_manifestation_created"):
		event_bus.surface_manifestation_created.emit(
			get_path(),
			manifestation_type,
			_entity_type,
			global_position
		)


func _get_event_bus() -> Node:
	if has_node("/root/EventBus"):
		return get_node("/root/EventBus")
	return null


# --- Public API ---


## Returns the manifestation type.
func get_manifestation_type() -> ManifestationType:
	return manifestation_type


## Returns the appearance state.
func get_appearance_state() -> AppearanceState:
	return _appearance_state


## Returns true if manifestation is currently showing.
func is_manifestation_visible() -> bool:
	return _appearance_state in [AppearanceState.FORMING, AppearanceState.VISIBLE, AppearanceState.FADING]


## Returns true if fully formed and visible.
func is_fully_visible() -> bool:
	return _appearance_state == AppearanceState.VISIBLE


## Returns the entity type that created this.
func get_entity_type() -> String:
	return _entity_type


## Returns the creation timestamp.
func get_creation_time() -> float:
	return _creation_time


## Returns time remaining before fade (or INF if permanent).
func get_time_remaining() -> float:
	if permanent:
		return INF

	if _appearance_state == AppearanceState.VISIBLE:
		return persist_time - _persist_timer
	elif _appearance_state == AppearanceState.FADING:
		return 0.0
	elif _appearance_state == AppearanceState.FORMING:
		return persist_time

	return 0.0


## Forces the manifestation to fade immediately.
func force_fade() -> void:
	if _appearance_state in [AppearanceState.FORMING, AppearanceState.VISIBLE]:
		_appearance_state = AppearanceState.FADING
		_fade_timer = 0.0


## Makes the manifestation permanent (won't fade).
func make_permanent() -> void:
	permanent = true


# --- Type Names ---


## Returns the display name for a manifestation type.
static func get_type_name(type: ManifestationType) -> String:
	match type:
		ManifestationType.WRITING:
			return "Writing"
		ManifestationType.HANDPRINT:
			return "Handprint"
		ManifestationType.SCRATCH:
			return "Scratch Marks"
		ManifestationType.SYMBOL:
			return "Symbol"
		_:
			return "Unknown"


## Returns the display name for a handprint variant.
static func get_variant_name(variant: HandprintVariant) -> String:
	match variant:
		HandprintVariant.BLOODY:
			return "Bloody"
		HandprintVariant.ASHY:
			return "Ashy"
		HandprintVariant.FROSTY:
			return "Frosty"
		HandprintVariant.DUSTY:
			return "Dusty"
		_:
			return "Unknown"


# --- Network State ---


func get_network_state() -> Dictionary:
	return {
		"manifestation_type": manifestation_type,
		"handprint_variant": handprint_variant,
		"writing_text": writing_text,
		"permanent": permanent,
		"appearance_state": _appearance_state,
		"opacity": _opacity,
		"entity_type": _entity_type,
		"creation_time": _creation_time,
		"examining_players": _examining_players,
	}


func apply_network_state(state: Dictionary) -> void:
	if state.has("manifestation_type"):
		manifestation_type = state.manifestation_type as ManifestationType
	if state.has("handprint_variant"):
		handprint_variant = state.handprint_variant as HandprintVariant
	if state.has("writing_text"):
		writing_text = state.writing_text
	if state.has("permanent"):
		permanent = state.permanent
	if state.has("appearance_state"):
		_appearance_state = state.appearance_state as AppearanceState
	if state.has("opacity"):
		_opacity = state.opacity
		_update_visual_opacity()
	if state.has("entity_type"):
		_entity_type = state.entity_type
	if state.has("creation_time"):
		_creation_time = state.creation_time
	if state.has("examining_players"):
		_examining_players.clear()
		for pid in state.examining_players:
			_examining_players.append(pid)

	_update_visual_for_variant()
