class_name EvidenceSpawnPoint
extends Marker3D
## Marker for valid evidence spawn locations.
##
## Place these in rooms to indicate where evidence can manifest.
## Each point can be configured for compatible evidence types.

# --- Enums ---

## Evidence types that can spawn at this point.
## Maps to EvidenceEnums.EvidenceType.
enum CompatibleEvidence {
	ALL = 0,  ## Any evidence type can spawn here
	EMF_ONLY = 1,  ## Only EMF readings
	TEMPERATURE_ONLY = 2,  ## Only temperature changes
	WRITING_ONLY = 3,  ## Only ghost writing
	AURA_ONLY = 4,  ## Only aura patterns
	NO_WRITING = 5,  ## Any except writing (needs flat surface)
}

# --- Export Settings ---

@export_group("Evidence Configuration")
## What evidence types can spawn at this point.
@export var compatible_evidence: CompatibleEvidence = CompatibleEvidence.ALL

## Priority weight for spawn selection (higher = more likely).
@export_range(0.1, 5.0, 0.1) var spawn_weight: float = 1.0

## Room this spawn point belongs to.
@export var room_name: String = ""

@export_group("Visual")
## Whether to show a debug visual in editor.
@export var show_debug_visual: bool = false


func _ready() -> void:
	add_to_group("evidence_spawn_points")

	# Infer room name from parent if not set
	if room_name.is_empty():
		room_name = _infer_room_name()


## Checks if a specific evidence type can spawn at this point.
func can_spawn_evidence_type(evidence_type: int) -> bool:
	match compatible_evidence:
		CompatibleEvidence.ALL:
			return true
		CompatibleEvidence.EMF_ONLY:
			return evidence_type == 0  # EvidenceEnums.EvidenceType.EMF
		CompatibleEvidence.TEMPERATURE_ONLY:
			return evidence_type == 1  # EvidenceEnums.EvidenceType.FREEZING_TEMPERATURE
		CompatibleEvidence.WRITING_ONLY:
			return evidence_type == 2  # EvidenceEnums.EvidenceType.GHOST_WRITING
		CompatibleEvidence.AURA_ONLY:
			return evidence_type == 3  # EvidenceEnums.EvidenceType.AURA_PATTERN
		CompatibleEvidence.NO_WRITING:
			return evidence_type != 2  # Not ghost writing
		_:
			return true


## Returns the spawn position (global).
func get_spawn_position() -> Vector3:
	return global_position


## Returns the room this point belongs to.
func get_room_name() -> String:
	return room_name


## Returns the spawn weight for random selection.
func get_spawn_weight() -> float:
	return spawn_weight


## Infers room name from node hierarchy or name.
func _infer_room_name() -> String:
	# Try to get from name (e.g., "LivingRoom_E1" -> "LivingRoom")
	var name_parts := name.split("_")
	if name_parts.size() > 1:
		return name_parts[0]

	# Try parent node
	var parent := get_parent()
	if parent and parent.name != "EvidencePoints":
		return parent.name

	return "Unknown"
