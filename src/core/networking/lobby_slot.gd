class_name LobbySlot
extends Resource
## Represents a player slot in the lobby.
##
## Contains the slot position, player information, and ready state.
## Used by LobbyManager to track lobby participants.

# --- Enums ---

enum ConnectionQuality {
	UNKNOWN,
	POOR,
	FAIR,
	GOOD,
	EXCELLENT,
}

# --- Constants ---

const EMPTY_PEER_ID: int = 0

# --- Slot State ---

var slot_index: int = 0  # Position in the lobby (0-5)
var peer_id: int = EMPTY_PEER_ID  # Network peer ID (0 = empty)
var username: String = ""
var is_ready: bool = false
var is_host: bool = false
var join_order: int = 0  # Used for host migration (lower = earlier)

var connection_quality: ConnectionQuality = ConnectionQuality.UNKNOWN


func _init(
	p_slot_index: int = 0,
	p_peer_id: int = EMPTY_PEER_ID,
	p_username: String = "",
	p_is_host: bool = false
) -> void:
	slot_index = p_slot_index
	peer_id = p_peer_id
	username = p_username
	is_host = p_is_host
	is_ready = false
	join_order = 0
	connection_quality = ConnectionQuality.UNKNOWN


## Returns true if this slot is occupied by a player.
func is_occupied() -> bool:
	return peer_id != EMPTY_PEER_ID


## Returns true if this slot is empty.
func is_empty() -> bool:
	return peer_id == EMPTY_PEER_ID


## Clears the slot, making it available.
func clear() -> void:
	peer_id = EMPTY_PEER_ID
	username = ""
	is_ready = false
	is_host = false
	join_order = 0
	connection_quality = ConnectionQuality.UNKNOWN


## Serializes to dictionary for network sync.
func to_dict() -> Dictionary:
	return {
		"slot_index": slot_index,
		"peer_id": peer_id,
		"username": username,
		"is_ready": is_ready,
		"is_host": is_host,
		"join_order": join_order,
		"connection_quality": connection_quality,
	}


## Deserializes from dictionary.
func from_dict(data: Dictionary) -> void:
	if data.has("slot_index"):
		slot_index = data.slot_index
	if data.has("peer_id"):
		peer_id = data.peer_id
	if data.has("username"):
		username = data.username
	if data.has("is_ready"):
		is_ready = data.is_ready
	if data.has("is_host"):
		is_host = data.is_host
	if data.has("join_order"):
		join_order = data.join_order
	if data.has("connection_quality"):
		connection_quality = data.connection_quality


## Returns a readable connection quality string.
static func quality_to_string(quality: ConnectionQuality) -> String:
	match quality:
		ConnectionQuality.UNKNOWN:
			return "Unknown"
		ConnectionQuality.POOR:
			return "Poor"
		ConnectionQuality.FAIR:
			return "Fair"
		ConnectionQuality.GOOD:
			return "Good"
		ConnectionQuality.EXCELLENT:
			return "Excellent"
		_:
			return "Unknown"
