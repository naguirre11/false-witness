class_name ManifestationEnums
extends RefCounted
## Readily-apparent evidence enumerations.
##
## Defines types of visual manifestations and physical interactions that
## can occur as evidence. These events are observable by all nearby players,
## making them high-trust evidence sources.


## Types of visual entity manifestations.
## Each type has different visibility characteristics.
enum ManifestationType {
	NONE,  ## No manifestation
	FULL_BODY,  ## Complete entity appearance (rare, unmistakable)
	PARTIAL,  ## Upper body or limbs visible (common)
	SILHOUETTE,  ## Shadow outline only (ambiguous)
	FLASH,  ## Brief bright apparition (blink and miss)
}


## Types of physical interactions entities can cause.
## These affect the environment and are observable by all.
enum InteractionType {
	NONE,  ## No interaction
	OBJECT_THROW,  ## Object thrown across room
	DOOR_SLAM,  ## Door slams shut forcefully
	DOOR_OPEN,  ## Door opens slowly/creepily
	LIGHT_FLICKER,  ## Lights flicker briefly
	LIGHT_EXPLODE,  ## Light fixture explodes/breaks
	SURFACE_WRITING,  ## Text appears on surface
	HANDPRINT,  ## Handprint appears (bloody/ashy)
	SCRATCH_MARKS,  ## Scratches form on surface
}


## Visibility ranges for manifestations (meters).
## Players within this range can potentially see the event.
const VISIBILITY_RANGE := {
	ManifestationType.FULL_BODY: 20.0,  ## Visible from far away
	ManifestationType.PARTIAL: 15.0,
	ManifestationType.SILHOUETTE: 10.0,
	ManifestationType.FLASH: 12.0,
}


## Audibility ranges for interactions (meters).
## Players within this range can hear the event.
const AUDIBILITY_RANGE := {
	InteractionType.OBJECT_THROW: 15.0,  ## Impact sound
	InteractionType.DOOR_SLAM: 30.0,  ## Audible throughout building
	InteractionType.DOOR_OPEN: 8.0,  ## Creaky hinges
	InteractionType.LIGHT_FLICKER: 5.0,  ## Buzzing
	InteractionType.LIGHT_EXPLODE: 20.0,  ## Breaking glass
	InteractionType.SURFACE_WRITING: 3.0,  ## Scratching sound
	InteractionType.HANDPRINT: 2.0,  ## Wet slap
	InteractionType.SCRATCH_MARKS: 10.0,  ## Loud scratching
}


## Default duration for manifestations (seconds).
const MANIFESTATION_DURATION := {
	ManifestationType.FULL_BODY: 4.0,  ## Longest
	ManifestationType.PARTIAL: 3.0,
	ManifestationType.SILHOUETTE: 2.5,
	ManifestationType.FLASH: 0.5,  ## Very brief
}


## Returns the visibility range for a manifestation type.
static func get_visibility_range(manifestation: ManifestationType) -> float:
	if manifestation in VISIBILITY_RANGE:
		return VISIBILITY_RANGE[manifestation]
	return 10.0  # Default


## Returns the audibility range for an interaction type.
static func get_audibility_range(interaction: InteractionType) -> float:
	if interaction in AUDIBILITY_RANGE:
		return AUDIBILITY_RANGE[interaction]
	return 10.0  # Default


## Returns the default duration for a manifestation type.
static func get_manifestation_duration(manifestation: ManifestationType) -> float:
	if manifestation in MANIFESTATION_DURATION:
		return MANIFESTATION_DURATION[manifestation]
	return 2.0  # Default


## Returns the display name for a manifestation type.
static func get_manifestation_name(manifestation: ManifestationType) -> String:
	match manifestation:
		ManifestationType.NONE:
			return "None"
		ManifestationType.FULL_BODY:
			return "Full Body Apparition"
		ManifestationType.PARTIAL:
			return "Partial Manifestation"
		ManifestationType.SILHOUETTE:
			return "Shadow Silhouette"
		ManifestationType.FLASH:
			return "Spectral Flash"
		_:
			return "Unknown"


## Returns the display name for an interaction type.
static func get_interaction_name(interaction: InteractionType) -> String:
	match interaction:
		InteractionType.NONE:
			return "None"
		InteractionType.OBJECT_THROW:
			return "Object Thrown"
		InteractionType.DOOR_SLAM:
			return "Door Slam"
		InteractionType.DOOR_OPEN:
			return "Door Opened"
		InteractionType.LIGHT_FLICKER:
			return "Light Flicker"
		InteractionType.LIGHT_EXPLODE:
			return "Light Exploded"
		InteractionType.SURFACE_WRITING:
			return "Surface Writing"
		InteractionType.HANDPRINT:
			return "Handprint"
		InteractionType.SCRATCH_MARKS:
			return "Scratch Marks"
		_:
			return "Unknown"


## Returns the description for a manifestation type.
static func get_manifestation_description(manifestation: ManifestationType) -> String:
	match manifestation:
		ManifestationType.FULL_BODY:
			return "Complete entity visible for several seconds"
		ManifestationType.PARTIAL:
			return "Upper body or limbs visible briefly"
		ManifestationType.SILHOUETTE:
			return "Dark shadow outline of entity"
		ManifestationType.FLASH:
			return "Bright flash of apparition, easily missed"
		_:
			return "No manifestation observed"


## Returns the description for an interaction type.
static func get_interaction_description(interaction: InteractionType) -> String:
	match interaction:
		InteractionType.OBJECT_THROW:
			return "Object thrown across room by invisible force"
		InteractionType.DOOR_SLAM:
			return "Door slammed shut violently"
		InteractionType.DOOR_OPEN:
			return "Door opened slowly on its own"
		InteractionType.LIGHT_FLICKER:
			return "Lights flickered briefly"
		InteractionType.LIGHT_EXPLODE:
			return "Light fixture exploded or shattered"
		InteractionType.SURFACE_WRITING:
			return "Text appeared on surface"
		InteractionType.HANDPRINT:
			return "Handprint appeared on surface"
		InteractionType.SCRATCH_MARKS:
			return "Scratch marks formed on surface"
		_:
			return "No interaction observed"


## Returns true if this manifestation type is visually clear (high confidence).
static func is_clear_manifestation(manifestation: ManifestationType) -> bool:
	return manifestation in [
		ManifestationType.FULL_BODY,
		ManifestationType.PARTIAL,
	]


## Returns true if this interaction type is audible (sound component).
static func is_audible_interaction(interaction: InteractionType) -> bool:
	return interaction in [
		InteractionType.OBJECT_THROW,
		InteractionType.DOOR_SLAM,
		InteractionType.LIGHT_EXPLODE,
		InteractionType.SCRATCH_MARKS,
	]


## Returns true if this interaction type leaves persistent evidence.
static func is_persistent_interaction(interaction: InteractionType) -> bool:
	return interaction in [
		InteractionType.LIGHT_EXPLODE,  # Broken light stays broken
		InteractionType.SURFACE_WRITING,
		InteractionType.HANDPRINT,
		InteractionType.SCRATCH_MARKS,
	]


## Returns all valid manifestation types (excluding NONE).
static func get_all_manifestations() -> Array[ManifestationType]:
	return [
		ManifestationType.FULL_BODY,
		ManifestationType.PARTIAL,
		ManifestationType.SILHOUETTE,
		ManifestationType.FLASH,
	]


## Returns all valid interaction types (excluding NONE).
static func get_all_interactions() -> Array[InteractionType]:
	return [
		InteractionType.OBJECT_THROW,
		InteractionType.DOOR_SLAM,
		InteractionType.DOOR_OPEN,
		InteractionType.LIGHT_FLICKER,
		InteractionType.LIGHT_EXPLODE,
		InteractionType.SURFACE_WRITING,
		InteractionType.HANDPRINT,
		InteractionType.SCRATCH_MARKS,
	]
