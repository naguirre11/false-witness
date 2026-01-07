extends Node
## Manages networking with Steam P2P (primary) and ENet fallback (LAN without Steam).
## Autoload: NetworkManager
##
## Based on GodotSteam Template (https://github.com/wahan-h/GodotSteam-Template)
## Adapted for False Witness multiplayer architecture.
##
## Supports two network backends:
## - Steam P2P: Used when Steam is available (default)
## - ENet: Fallback for LAN play without Steam

# --- Signals ---

signal connection_state_changed(state: int)
signal lobby_created(lobby_id: int)
signal lobby_joined(lobby_id: int)
signal lobby_join_failed(reason: String)
signal lobby_members_updated(members: Array)
signal player_joined_network(peer_id: int, username: String)
signal player_left_network(peer_id: int)
signal player_data_updated(peer_id: int, data: Resource)
signal packet_received(sender_id: int, data: Dictionary)

# --- Network Backend ---

enum NetworkBackend {
	NONE,
	STEAM,
	ENET,
}

# --- Connection States ---

enum ConnectionState {
	DISCONNECTED,
	CONNECTING,
	CONNECTED,
	HOST,
}

# --- Constants ---

const PlayerData = preload("res://src/core/networking/player_data.gd")
const PACKET_READ_LIMIT: int = 32
const MAX_LOBBY_MEMBERS: int = 6  # False Witness supports 4-6 players
const DEFAULT_PORT: int = 7777
const SYNC_INTERVAL: float = 0.05  # 20 Hz position updates

# --- State Variables ---

var backend: NetworkBackend = NetworkBackend.NONE
var connection_state: ConnectionState = ConnectionState.DISCONNECTED
var is_host: bool = false
var lobby_id: int = 0
var local_peer_id: int = 0
var lobby_members: Array[Dictionary] = []

# --- Player Data ---

var players: Dictionary = {}  # peer_id -> PlayerData
var local_player: PlayerData = null

# --- ENet State ---

var _enet_peer: ENetMultiplayerPeer = null
var _sync_timer: float = 0.0


func _ready() -> void:
	# Try to use Steam if available
	if SteamManager.is_steam_running:
		_setup_steam_backend()
	else:
		print("[NetworkManager] Steam not available - ENet fallback ready")


func _process(delta: float) -> void:
	match backend:
		NetworkBackend.STEAM:
			if lobby_id > 0:
				_read_all_p2p_packets()
				_process_position_sync(delta)
		NetworkBackend.ENET:
			if connection_state in [ConnectionState.CONNECTED, ConnectionState.HOST]:
				_process_position_sync(delta)


# =============================================================================
# PUBLIC API
# =============================================================================


## Creates a new lobby/server. The creator becomes the host.
func host_game(max_members: int = MAX_LOBBY_MEMBERS, use_enet: bool = false) -> void:
	if connection_state != ConnectionState.DISCONNECTED:
		push_warning("[NetworkManager] Already connected")
		return

	if use_enet or not SteamManager.is_steam_running:
		_create_enet_server(max_members)
	else:
		_create_steam_lobby(max_members)


## Joins an existing game.
## For Steam: pass lobby_id as target
## For ENet: pass IP address as target (port optional, defaults to DEFAULT_PORT)
func join_game(target: Variant, port: int = DEFAULT_PORT) -> void:
	if connection_state != ConnectionState.DISCONNECTED:
		push_warning("[NetworkManager] Already connected")
		return

	if target is int and SteamManager.is_steam_running:
		_join_steam_lobby(target)
	elif target is String:
		_join_enet_server(target, port)
	else:
		push_error("[NetworkManager] Invalid join target")
		lobby_join_failed.emit("Invalid target")


## Leaves the current game/lobby.
func leave_game() -> void:
	match backend:
		NetworkBackend.STEAM:
			_leave_steam_lobby()
		NetworkBackend.ENET:
			_leave_enet_server()

	_cleanup_state()


## Sends game data to a specific player or all players (target = 0).
func send_game_packet(target: int, data: Dictionary, reliable: bool = true) -> void:
	data["_type"] = "game"
	_send_packet(target, data, reliable)


## Sends a position update for the local player.
func send_position_update(pos: Vector3, rot: Vector3, vel: Vector3) -> void:
	if local_player:
		local_player.position = pos
		local_player.rotation = rot
		local_player.velocity = vel


## Returns all connected players.
func get_players() -> Dictionary:
	return players


## Returns player data for a specific peer.
func get_player(peer_id: int) -> PlayerData:
	return players.get(peer_id, null)


## Returns the local player data.
func get_local_player() -> PlayerData:
	return local_player


## Returns true if we are the host.
func is_game_host() -> bool:
	return is_host


## Returns the current connection state.
func get_connection_state() -> ConnectionState:
	return connection_state


## Returns the active network backend.
func get_backend() -> NetworkBackend:
	return backend


# =============================================================================
# STEAM BACKEND
# =============================================================================


func _setup_steam_backend() -> void:
	Steam.lobby_created.connect(_on_steam_lobby_created)
	Steam.lobby_joined.connect(_on_steam_lobby_joined)
	Steam.lobby_chat_update.connect(_on_steam_lobby_chat_update)
	Steam.p2p_session_request.connect(_on_steam_p2p_session_request)
	print("[NetworkManager] Steam backend initialized")


func _create_steam_lobby(max_members: int) -> void:
	backend = NetworkBackend.STEAM
	is_host = true
	connection_state = ConnectionState.CONNECTING
	connection_state_changed.emit(connection_state)
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, max_members)


func _join_steam_lobby(target_lobby_id: int) -> void:
	backend = NetworkBackend.STEAM
	is_host = false
	connection_state = ConnectionState.CONNECTING
	connection_state_changed.emit(connection_state)
	Steam.joinLobby(target_lobby_id)


func _leave_steam_lobby() -> void:
	if lobby_id == 0:
		return

	Steam.leaveLobby(lobby_id)

	for member in lobby_members:
		Steam.closeP2PSessionWithUser(member.steam_id)


func _on_steam_lobby_created(result: int, new_lobby_id: int) -> void:
	if result != Steam.RESULT_OK:
		push_error("[NetworkManager] Failed to create lobby: %d" % result)
		_cleanup_state()
		lobby_join_failed.emit("Failed to create lobby")
		return

	lobby_id = new_lobby_id
	local_peer_id = SteamManager.steam_id

	Steam.setLobbyJoinable(lobby_id, true)
	Steam.setLobbyData(lobby_id, "game", "false_witness")
	Steam.setLobbyData(lobby_id, "version", "0.1.0")
	Steam.allowP2PPacketRelay(true)

	connection_state = ConnectionState.HOST
	connection_state_changed.emit(connection_state)

	_create_local_player()
	_refresh_steam_lobby_members()

	print("[NetworkManager] Lobby created: %d" % lobby_id)
	lobby_created.emit(lobby_id)
	EventBus.player_joined.emit(local_peer_id)


func _on_steam_lobby_joined(
	joined_lobby_id: int, _permissions: int, _locked: bool, response: int
) -> void:
	if response != Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		var reason: String = _get_steam_join_failure_reason(response)
		push_error("[NetworkManager] Failed to join lobby: %s" % reason)
		_cleanup_state()
		lobby_join_failed.emit(reason)
		return

	lobby_id = joined_lobby_id
	local_peer_id = SteamManager.steam_id
	connection_state = ConnectionState.CONNECTED
	connection_state_changed.emit(connection_state)

	_create_local_player()
	_refresh_steam_lobby_members()
	_send_handshake()

	print("[NetworkManager] Joined lobby: %d" % lobby_id)
	lobby_joined.emit(lobby_id)
	EventBus.player_joined.emit(local_peer_id)


func _on_steam_lobby_chat_update(
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
			_refresh_steam_lobby_members()
			var username: String = Steam.getFriendPersonaName(changed_id)
			_add_player(changed_id, username, false)
			player_joined_network.emit(changed_id, username)
			EventBus.player_joined.emit(changed_id)
		Steam.CHAT_MEMBER_STATE_CHANGE_LEFT, Steam.CHAT_MEMBER_STATE_CHANGE_DISCONNECTED:
			print("[NetworkManager] Player left: %d" % changed_id)
			_remove_player(changed_id)
			player_left_network.emit(changed_id)
			EventBus.player_left.emit(changed_id)
			_refresh_steam_lobby_members()


func _on_steam_p2p_session_request(remote_id: int) -> void:
	var is_member: bool = false
	for member in lobby_members:
		if member.steam_id == remote_id:
			is_member = true
			break

	if is_member or lobby_id > 0:
		Steam.acceptP2PSessionWithUser(remote_id)
		_send_handshake()


func _refresh_steam_lobby_members() -> void:
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


func _get_steam_join_failure_reason(response: int) -> String:
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


# =============================================================================
# ENET BACKEND
# =============================================================================


func _create_enet_server(max_members: int) -> void:
	backend = NetworkBackend.ENET
	is_host = true
	connection_state = ConnectionState.CONNECTING
	connection_state_changed.emit(connection_state)

	_enet_peer = ENetMultiplayerPeer.new()
	var error: int = _enet_peer.create_server(DEFAULT_PORT, max_members)

	if error != OK:
		push_error("[NetworkManager] Failed to create ENet server: %d" % error)
		_cleanup_state()
		lobby_join_failed.emit("Failed to create server")
		return

	multiplayer.multiplayer_peer = _enet_peer
	local_peer_id = 1  # Server is always peer 1 in ENet

	_connect_enet_signals()

	connection_state = ConnectionState.HOST
	connection_state_changed.emit(connection_state)

	_create_local_player()

	print("[NetworkManager] ENet server created on port %d" % DEFAULT_PORT)
	lobby_created.emit(local_peer_id)
	EventBus.player_joined.emit(local_peer_id)


func _join_enet_server(address: String, port: int) -> void:
	backend = NetworkBackend.ENET
	is_host = false
	connection_state = ConnectionState.CONNECTING
	connection_state_changed.emit(connection_state)

	_enet_peer = ENetMultiplayerPeer.new()
	var error: int = _enet_peer.create_client(address, port)

	if error != OK:
		push_error("[NetworkManager] Failed to connect to ENet server: %d" % error)
		_cleanup_state()
		lobby_join_failed.emit("Failed to connect")
		return

	multiplayer.multiplayer_peer = _enet_peer

	_connect_enet_signals()

	print("[NetworkManager] Connecting to %s:%d..." % [address, port])


func _leave_enet_server() -> void:
	if _enet_peer:
		_enet_peer.close()
		multiplayer.multiplayer_peer = null
		_enet_peer = null


func _connect_enet_signals() -> void:
	multiplayer.peer_connected.connect(_on_enet_peer_connected)
	multiplayer.peer_disconnected.connect(_on_enet_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_enet_connected_to_server)
	multiplayer.connection_failed.connect(_on_enet_connection_failed)
	multiplayer.server_disconnected.connect(_on_enet_server_disconnected)


func _disconnect_enet_signals() -> void:
	if multiplayer.peer_connected.is_connected(_on_enet_peer_connected):
		multiplayer.peer_connected.disconnect(_on_enet_peer_connected)
	if multiplayer.peer_disconnected.is_connected(_on_enet_peer_disconnected):
		multiplayer.peer_disconnected.disconnect(_on_enet_peer_disconnected)
	if multiplayer.connected_to_server.is_connected(_on_enet_connected_to_server):
		multiplayer.connected_to_server.disconnect(_on_enet_connected_to_server)
	if multiplayer.connection_failed.is_connected(_on_enet_connection_failed):
		multiplayer.connection_failed.disconnect(_on_enet_connection_failed)
	if multiplayer.server_disconnected.is_connected(_on_enet_server_disconnected):
		multiplayer.server_disconnected.disconnect(_on_enet_server_disconnected)


func _on_enet_peer_connected(peer_id: int) -> void:
	print("[NetworkManager] ENet peer connected: %d" % peer_id)
	var username: String = "Player_%d" % peer_id
	_add_player(peer_id, username, false)
	player_joined_network.emit(peer_id, username)
	EventBus.player_joined.emit(peer_id)

	# Host sends current state to new peer
	if is_host:
		_send_full_state_to_peer(peer_id)


func _on_enet_peer_disconnected(peer_id: int) -> void:
	print("[NetworkManager] ENet peer disconnected: %d" % peer_id)
	_remove_player(peer_id)
	player_left_network.emit(peer_id)
	EventBus.player_left.emit(peer_id)


func _on_enet_connected_to_server() -> void:
	local_peer_id = multiplayer.get_unique_id()
	connection_state = ConnectionState.CONNECTED
	connection_state_changed.emit(connection_state)

	_create_local_player()
	_send_handshake()

	print("[NetworkManager] Connected to ENet server as peer %d" % local_peer_id)
	lobby_joined.emit(local_peer_id)
	EventBus.player_joined.emit(local_peer_id)


func _on_enet_connection_failed() -> void:
	push_error("[NetworkManager] ENet connection failed")
	_cleanup_state()
	lobby_join_failed.emit("Connection failed")


func _on_enet_server_disconnected() -> void:
	print("[NetworkManager] Disconnected from ENet server")
	_cleanup_state()
	connection_state_changed.emit(connection_state)


# =============================================================================
# PACKET HANDLING
# =============================================================================


func _send_packet(target: int, data: Dictionary, reliable: bool = true) -> void:
	match backend:
		NetworkBackend.STEAM:
			_send_steam_packet(target, data, reliable)
		NetworkBackend.ENET:
			_send_enet_packet(target, data, reliable)


func _send_steam_packet(target: int, data: Dictionary, reliable: bool) -> void:
	var send_type: int = Steam.P2P_SEND_RELIABLE if reliable else Steam.P2P_SEND_UNRELIABLE
	var channel: int = 0
	var packet_data: PackedByteArray = var_to_bytes(data)

	if target == 0:
		for member in lobby_members:
			if member.steam_id != SteamManager.steam_id:
				Steam.sendP2PPacket(member.steam_id, packet_data, send_type, channel)
	else:
		Steam.sendP2PPacket(target, packet_data, send_type, channel)


func _send_enet_packet(target: int, data: Dictionary, _reliable: bool) -> void:
	if target == 0:
		_broadcast_enet_packet.rpc(data)
	else:
		_receive_enet_packet.rpc_id(target, data)


@rpc("any_peer", "reliable")
func _receive_enet_packet(data: Dictionary) -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	_handle_packet(sender_id, data)


@rpc("any_peer", "reliable", "call_local")
func _broadcast_enet_packet(data: Dictionary) -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id != local_peer_id:
		_handle_packet(sender_id, data)


func _read_all_p2p_packets(read_count: int = 0) -> void:
	if read_count >= PACKET_READ_LIMIT:
		return

	if Steam.getAvailableP2PPacketSize(0) > 0:
		_read_steam_p2p_packet()
		_read_all_p2p_packets(read_count + 1)


func _read_steam_p2p_packet() -> void:
	var packet_size: int = Steam.getAvailableP2PPacketSize(0)
	if packet_size <= 0:
		return

	var packet: Dictionary = Steam.readP2PPacket(packet_size, 0)
	var sender_id: int = packet.steam_id_remote
	var data: Dictionary = bytes_to_var(packet.data)

	_handle_packet(sender_id, data)


func _handle_packet(sender_id: int, data: Dictionary) -> void:
	if not data.has("_type"):
		packet_received.emit(sender_id, data)
		return

	match data._type:
		"handshake":
			_handle_handshake(sender_id, data)
		"position":
			_handle_position_update(sender_id, data)
		"full_state":
			_handle_full_state(sender_id, data)
		"game":
			data.erase("_type")
			packet_received.emit(sender_id, data)


func _send_handshake() -> void:
	var username: String = ""
	if backend == NetworkBackend.STEAM:
		username = SteamManager.steam_username
	else:
		username = "Player_%d" % local_peer_id

	_send_packet(0, {
		"_type": "handshake",
		"peer_id": local_peer_id,
		"username": username
	}, true)


func _handle_handshake(sender_id: int, data: Dictionary) -> void:
	var username: String = data.get("username", "Unknown")
	if not players.has(sender_id):
		_add_player(sender_id, username, false)
		player_joined_network.emit(sender_id, username)


func _send_full_state_to_peer(peer_id: int) -> void:
	var player_states: Array = []
	for pid in players:
		var player: PlayerData = players[pid]
		player_states.append(player.to_dict())

	_send_packet(peer_id, {
		"_type": "full_state",
		"players": player_states
	}, true)


func _handle_full_state(_sender_id: int, data: Dictionary) -> void:
	if not data.has("players"):
		return

	for player_dict in data.players:
		var pid: int = player_dict.get("peer_id", 0)
		if pid == 0 or pid == local_peer_id:
			continue

		if not players.has(pid):
			var player: PlayerData = PlayerData.new(pid)
			player.from_dict(player_dict)
			players[pid] = player


# =============================================================================
# POSITION SYNCHRONIZATION
# =============================================================================


func _process_position_sync(delta: float) -> void:
	_sync_timer += delta
	if _sync_timer >= SYNC_INTERVAL:
		_sync_timer = 0.0
		_send_local_position()


func _send_local_position() -> void:
	if not local_player:
		return

	_send_packet(0, {
		"_type": "position",
		"data": local_player.get_transform_data()
	}, false)  # Unreliable for frequent updates


func _handle_position_update(sender_id: int, data: Dictionary) -> void:
	if not data.has("data"):
		return

	var player: PlayerData = players.get(sender_id, null)
	if player:
		player.apply_transform_data(data.data)
		player_data_updated.emit(sender_id, player)


# =============================================================================
# PLAYER MANAGEMENT
# =============================================================================


func _create_local_player() -> void:
	var username: String = ""
	if backend == NetworkBackend.STEAM:
		username = SteamManager.steam_username
	else:
		username = "Player_%d" % local_peer_id

	local_player = PlayerData.new(local_peer_id, username, is_host)
	players[local_peer_id] = local_player


func _add_player(peer_id: int, username: String, player_is_host: bool) -> void:
	if players.has(peer_id):
		return

	var player: PlayerData = PlayerData.new(peer_id, username, player_is_host)
	players[peer_id] = player


func _remove_player(peer_id: int) -> void:
	players.erase(peer_id)


func _cleanup_state() -> void:
	match backend:
		NetworkBackend.ENET:
			_disconnect_enet_signals()

	backend = NetworkBackend.NONE
	connection_state = ConnectionState.DISCONNECTED
	is_host = false
	lobby_id = 0
	local_peer_id = 0
	lobby_members.clear()
	players.clear()
	local_player = null
	_enet_peer = null
	_sync_timer = 0.0

	connection_state_changed.emit(connection_state)
