extends Node
## Manages Steam lobbies and P2P networking.
## Autoload: NetworkManager
##
## Based on GodotSteam Template (https://github.com/wahan-h/GodotSteam-Template)
## Adapted for False Witness multiplayer architecture.

signal lobby_created(lobby_id: int)
signal lobby_joined(lobby_id: int)
signal lobby_join_failed(reason: String)
signal lobby_members_updated(members: Array)
signal player_joined(steam_id: int, username: String)
signal player_left(steam_id: int)
signal packet_received(sender_id: int, data: Dictionary)

const PACKET_READ_LIMIT: int = 32
const MAX_LOBBY_MEMBERS: int = 6  # False Witness supports 4-6 players

var is_host: bool = false
var lobby_id: int = 0
var lobby_members: Array[Dictionary] = []


func _ready() -> void:
	# Connect Steam signals
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.p2p_session_request.connect(_on_p2p_session_request)


func _process(_delta: float) -> void:
	if lobby_id > 0:
		_read_all_p2p_packets()


## Creates a new public lobby. The creator becomes the host.
func create_lobby(max_members: int = MAX_LOBBY_MEMBERS) -> void:
	if lobby_id != 0:
		push_warning("[NetworkManager] Already in a lobby")
		return

	is_host = true
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, max_members)


## Joins an existing lobby by ID.
func join_lobby(target_lobby_id: int) -> void:
	if lobby_id != 0:
		push_warning("[NetworkManager] Already in a lobby")
		return

	is_host = false
	Steam.joinLobby(target_lobby_id)


## Leaves the current lobby.
func leave_lobby() -> void:
	if lobby_id == 0:
		return

	Steam.leaveLobby(lobby_id)

	# Close P2P sessions with all members
	for member in lobby_members:
		Steam.closeP2PSessionWithUser(member.steam_id)

	lobby_id = 0
	lobby_members.clear()
	is_host = false


## Sends a packet to a specific player or all players (target = 0).
func send_packet(target: int, data: Dictionary, reliable: bool = true) -> void:
	var send_type: int = Steam.P2P_SEND_RELIABLE if reliable else Steam.P2P_SEND_UNRELIABLE
	var channel: int = 0
	var packet_data: PackedByteArray = var_to_bytes(data)

	if target == 0:
		# Broadcast to all lobby members except self
		for member in lobby_members:
			if member.steam_id != SteamManager.steam_id:
				Steam.sendP2PPacket(member.steam_id, packet_data, send_type, channel)
	else:
		Steam.sendP2PPacket(target, packet_data, send_type, channel)


## Returns the current lobby members.
func get_members() -> Array[Dictionary]:
	return lobby_members


## Returns true if we are the host of the current lobby.
func is_lobby_host() -> bool:
	return is_host


# --- Steam Signal Handlers ---

func _on_lobby_created(result: int, new_lobby_id: int) -> void:
	if result != Steam.RESULT_OK:
		push_error("[NetworkManager] Failed to create lobby: %d" % result)
		lobby_join_failed.emit("Failed to create lobby")
		is_host = false
		return

	lobby_id = new_lobby_id

	# Configure lobby
	Steam.setLobbyJoinable(lobby_id, true)
	Steam.setLobbyData(lobby_id, "game", "false_witness")
	Steam.setLobbyData(lobby_id, "version", "0.1.0")

	# Allow P2P relay through Steam servers if direct connection fails
	Steam.allowP2PPacketRelay(true)

	print("[NetworkManager] Lobby created: %d" % lobby_id)
	_refresh_lobby_members()
	lobby_created.emit(lobby_id)


func _on_lobby_joined(
	joined_lobby_id: int, _permissions: int, _locked: bool, response: int
) -> void:
	if response != Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		var reason: String = _get_join_failure_reason(response)
		push_error("[NetworkManager] Failed to join lobby: %s" % reason)
		lobby_join_failed.emit(reason)
		return

	lobby_id = joined_lobby_id
	print("[NetworkManager] Joined lobby: %d" % lobby_id)

	_refresh_lobby_members()
	_send_handshake()
	lobby_joined.emit(lobby_id)


func _on_lobby_chat_update(
	updated_lobby_id: int,
	changed_id: int,
	_making_change_id: int,
	chat_state: int
) -> void:
	if updated_lobby_id != lobby_id:
		return

	match chat_state:
		Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
			print("[NetworkManager] Player joined: %d" % changed_id)
			_refresh_lobby_members()
			var username: String = Steam.getFriendPersonaName(changed_id)
			player_joined.emit(changed_id, username)
		Steam.CHAT_MEMBER_STATE_CHANGE_LEFT, Steam.CHAT_MEMBER_STATE_CHANGE_DISCONNECTED:
			print("[NetworkManager] Player left: %d" % changed_id)
			player_left.emit(changed_id)
			_refresh_lobby_members()


func _on_p2p_session_request(remote_id: int) -> void:
	# Accept P2P session from lobby members
	var is_member: bool = false
	for member in lobby_members:
		if member.steam_id == remote_id:
			is_member = true
			break

	if is_member or lobby_id > 0:
		Steam.acceptP2PSessionWithUser(remote_id)
		_send_handshake()


# --- Internal Helpers ---

func _refresh_lobby_members() -> void:
	lobby_members.clear()

	var member_count: int = Steam.getNumLobbyMembers(lobby_id)
	for i in range(member_count):
		var member_id: int = Steam.getLobbyMemberByIndex(lobby_id, i)
		var member_name: String = Steam.getFriendPersonaName(member_id)
		lobby_members.append({
			"steam_id": member_id,
			"steam_name": member_name
		})

	lobby_members_updated.emit(lobby_members)


func _send_handshake() -> void:
	send_packet(0, {
		"type": "handshake",
		"steam_id": SteamManager.steam_id,
		"username": SteamManager.steam_username
	})


func _read_all_p2p_packets(read_count: int = 0) -> void:
	if read_count >= PACKET_READ_LIMIT:
		return

	if Steam.getAvailableP2PPacketSize(0) > 0:
		_read_p2p_packet()
		_read_all_p2p_packets(read_count + 1)


func _read_p2p_packet() -> void:
	var packet_size: int = Steam.getAvailableP2PPacketSize(0)
	if packet_size <= 0:
		return

	var packet: Dictionary = Steam.readP2PPacket(packet_size, 0)
	var sender_id: int = packet.steam_id_remote
	var data: Dictionary = bytes_to_var(packet.data)

	# Handle internal messages
	if data.has("type"):
		match data.type:
			"handshake":
				_refresh_lobby_members()
				return

	# Emit for game systems to handle
	packet_received.emit(sender_id, data)


func _get_join_failure_reason(response: int) -> String:
	match response:
		Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST:
			return "Lobby does not exist"
		Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED:
			return "Not allowed to join"
		Steam.CHAT_ROOM_ENTER_RESPONSE_FULL:
			return "Lobby is full"
		Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED:
			return "Banned from lobby"
		_:
			return "Unknown error: %d" % response
