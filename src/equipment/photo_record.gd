class_name PhotoRecord
extends Resource
## Represents metadata for a captured photograph.
##
## Photos can capture entity manifestations or readily-apparent evidence.
## Photos are shared with other players for verification and comparison.
##
## Photos are serializable for network sync.

# --- Exported Properties ---

@export_group("Identification")
## Unique identifier for network sync
@export var uid: String = ""
## Entity type captured (entity name or "None")
@export var entity_type: String = ""

@export_group("Capture Info")
## Game time when photo was taken (seconds)
@export var capture_timestamp: float = 0.0
## World position where photo was taken
@export var capture_location: Vector3 = Vector3.ZERO
## Player peer ID who took the photo
@export var photographer_id: int = 0

@export_group("Evidence Linking")
## UID of linked evidence (empty if no evidence in photo)
@export var evidence_uid: String = ""

@export_group("Sharing Tracking")
## Array of peer IDs this photo has been shared with
@export var shared_with: Array[int] = []


## Creates a new PhotoRecord with the given parameters.
## Automatically generates UID and sets timestamp.
static func create(
	entity: String,
	location: Vector3,
	photographer: int
) -> PhotoRecord:
	var record := PhotoRecord.new()
	record.uid = _generate_uid()
	record.entity_type = entity
	record.capture_location = location
	record.photographer_id = photographer
	record.capture_timestamp = Time.get_ticks_msec() / 1000.0
	return record


## Serializes this photo record for network transmission.
func to_network_dict() -> Dictionary:
	return {
		"uid": uid,
		"entity_type": entity_type,
		"capture_timestamp": capture_timestamp,
		"capture_location_x": capture_location.x,
		"capture_location_y": capture_location.y,
		"capture_location_z": capture_location.z,
		"photographer_id": photographer_id,
		"evidence_uid": evidence_uid,
		"shared_with": shared_with,
	}


## Creates a PhotoRecord instance from network data.
static func from_network_dict(data: Dictionary) -> PhotoRecord:
	var record := PhotoRecord.new()
	record.uid = data.get("uid", "")
	record.entity_type = data.get("entity_type", "")
	record.capture_timestamp = data.get("capture_timestamp", 0.0)
	record.capture_location = Vector3(
		data.get("capture_location_x", 0.0),
		data.get("capture_location_y", 0.0),
		data.get("capture_location_z", 0.0)
	)
	record.photographer_id = data.get("photographer_id", 0)
	record.evidence_uid = data.get("evidence_uid", "")
	# Rebuild shared_with array with proper typing
	var raw_shared: Array = data.get("shared_with", [])
	record.shared_with = []
	for peer_id in raw_shared:
		record.shared_with.append(peer_id as int)
	return record


## Marks this photo as shared with the given peer.
func mark_shared(peer_id: int) -> void:
	if peer_id not in shared_with:
		shared_with.append(peer_id)


## Returns true if this photo was shared with the given peer.
func was_shared_with(peer_id: int) -> bool:
	return peer_id in shared_with


## Generates a unique identifier for this photo.
static func _generate_uid() -> String:
	return "%d_%d" % [Time.get_ticks_msec(), randi()]


## Returns a debug string representation.
func _to_string() -> String:
	return "[PhotoRecord: %s by %d at %s]" % [entity_type, photographer_id, uid]
