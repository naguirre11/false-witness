class_name PlayerData
extends Resource
## Synchronized player data for networked games.
##
## Contains all player state that needs to be synchronized across the network.
## Used by NetworkManager to track connected players and their current state.

# --- Identity ---

var peer_id: int = 0  # Network peer ID (Steam ID or ENet peer ID)
var username: String = ""
var is_host: bool = false

# --- Transform Data (synced frequently) ---

var position: Vector3 = Vector3.ZERO
var rotation: Vector3 = Vector3.ZERO  # Euler angles for simplicity
var velocity: Vector3 = Vector3.ZERO

# --- Gameplay State ---

var is_alive: bool = true
var is_echo: bool = false  # Dead player in Echo mode
var is_cultist: bool = false  # Only known to server and the cultist
var current_equipment: String = ""  # Equipment type currently held

# --- Connection State ---

var last_update_time: float = 0.0
var ping_ms: int = 0


func _init(
	p_peer_id: int = 0,
	p_username: String = "",
	p_is_host: bool = false
) -> void:
	peer_id = p_peer_id
	username = p_username
	is_host = p_is_host
	last_update_time = Time.get_unix_time_from_system()


## Creates a dictionary of frequently-synced transform data.
func get_transform_data() -> Dictionary:
	return {
		"peer_id": peer_id,
		"position": var_to_bytes(position),
		"rotation": var_to_bytes(rotation),
		"velocity": var_to_bytes(velocity),
	}


## Applies transform data from network packet.
func apply_transform_data(data: Dictionary) -> void:
	if data.has("position"):
		position = bytes_to_var(data.position)
	if data.has("rotation"):
		rotation = bytes_to_var(data.rotation)
	if data.has("velocity"):
		velocity = bytes_to_var(data.velocity)
	last_update_time = Time.get_unix_time_from_system()


## Creates a full state dictionary for initial sync or reconnection.
func to_dict() -> Dictionary:
	return {
		"peer_id": peer_id,
		"username": username,
		"is_host": is_host,
		"position": var_to_bytes(position),
		"rotation": var_to_bytes(rotation),
		"velocity": var_to_bytes(velocity),
		"is_alive": is_alive,
		"is_echo": is_echo,
		"current_equipment": current_equipment,
	}


## Applies full state from dictionary.
func from_dict(data: Dictionary) -> void:
	if data.has("peer_id"):
		peer_id = data.peer_id
	if data.has("username"):
		username = data.username
	if data.has("is_host"):
		is_host = data.is_host
	if data.has("position"):
		position = bytes_to_var(data.position)
	if data.has("rotation"):
		rotation = bytes_to_var(data.rotation)
	if data.has("velocity"):
		velocity = bytes_to_var(data.velocity)
	if data.has("is_alive"):
		is_alive = data.is_alive
	if data.has("is_echo"):
		is_echo = data.is_echo
	if data.has("current_equipment"):
		current_equipment = data.current_equipment
	last_update_time = Time.get_unix_time_from_system()


## Resets player to alive state (for new round).
func reset_for_new_round() -> void:
	is_alive = true
	is_echo = false
	is_cultist = false
	current_equipment = ""
	position = Vector3.ZERO
	rotation = Vector3.ZERO
	velocity = Vector3.ZERO
