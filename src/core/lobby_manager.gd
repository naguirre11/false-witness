extends Node
## Manages pre-game lobby with player slots, ready states, and host controls.
## Autoload: LobbyManager
##
## Handles:
## - Player slots (4-6 players)
## - Ready/unready toggle
## - Host controls (start game when all ready, minimum 4)
## - Player list synchronization
## - Late join prevention
## - Host migration on disconnect
## - Lobby state broadcasts

# --- Signals ---

signal lobby_created(is_host: bool)
signal lobby_joined(slot_index: int)
signal lobby_left
signal lobby_closed(reason: String)
signal player_slot_updated(slot_index: int, slot: Resource)
signal player_ready_changed(peer_id: int, is_ready: bool)
signal all_players_ready(can_start: bool)
signal host_changed(new_host_peer_id: int, new_host_username: String)
signal game_starting
signal lobby_state_updated(slots: Array)
signal player_kicked(peer_id: int, reason: String)
signal lobby_code_received(code: String)

# --- Constants ---

const LobbySlot = preload("res://src/core/networking/lobby_slot.gd")
const MIN_PLAYERS: int = 4
const MAX_PLAYERS: int = 6
const LOBBY_SYNC_INTERVAL: float = 1.0  # Broadcast full state every second
const PACKET_TYPE_LOBBY: String = "lobby"

# --- State ---

var is_in_lobby: bool = false
var is_lobby_host: bool = false
var local_slot_index: int = -1
var host_peer_id: int = 0
var game_started: bool = false  # Late join prevention flag

var _slots: Array[LobbySlot] = []
var _next_join_order: int = 0
var _sync_timer: float = 0.0
var _steam_lobby_code: String = ""  # 6-character lobby code for Steam


func _ready() -> void:
	_initialize_slots()
	_connect_network_signals()
	_connect_steam_signals()
	print("[LobbyManager] Initialized - %d slots available" % MAX_PLAYERS)


func _process(delta: float) -> void:
	if is_in_lobby and is_lobby_host:
		_sync_timer += delta
		if _sync_timer >= LOBBY_SYNC_INTERVAL:
			_sync_timer = 0.0
			_broadcast_lobby_state()


# =============================================================================
# PUBLIC API - Lobby Management
# =============================================================================


## Creates a new lobby. Caller becomes the host.
## If Steam is running, creates a Steam lobby with a shareable code.
func create_lobby() -> void:
	if is_in_lobby:
		push_warning("[LobbyManager] Already in a lobby")
		return

	# Use Steam lobby if available
	if SteamManager.is_steam_running:
		SteamManager.create_lobby(MAX_PLAYERS)
		# Lobby state will be initialized in _on_steam_lobby_created callback
		return

	# Fallback: require network connection for ENet mode
	if NetworkManager.get_connection_state() == NetworkManager.ConnectionState.DISCONNECTED:
		push_error("[LobbyManager] Must connect to network first")
		return

	_setup_local_lobby()


## Joins an existing lobby using a 6-character code (Steam only).
func join_lobby_by_code(code: String) -> void:
	if is_in_lobby:
		push_warning("[LobbyManager] Already in a lobby")
		return

	if not SteamManager.is_steam_running:
		push_error("[LobbyManager] Steam lobby codes require Steam to be running")
		return

	SteamManager.join_lobby(code)
	# Lobby state will be initialized in _on_steam_lobby_joined callback


## Joins a lobby by IP address (ENet fallback when Steam unavailable).
func join_lobby_by_ip(address: String, port: int = NetworkManager.DEFAULT_PORT) -> void:
	if is_in_lobby:
		push_warning("[LobbyManager] Already in a lobby")
		return

	if SteamManager.is_steam_running:
		push_warning("[LobbyManager] Steam available - use join_lobby_by_code() instead")

	NetworkManager.join_game(address, port)
	# Lobby state will be initialized when connected


## Returns true if Steam is available for lobby codes.
func is_steam_available() -> bool:
	return SteamManager.is_steam_running


## Internal: Sets up local lobby state (called after network/Steam lobby is ready)
func _setup_local_lobby() -> void:
	_reset_lobby_state()
	is_in_lobby = true
	is_lobby_host = true
	game_started = false

	# Add host to first slot
	var host_id: int = NetworkManager.local_peer_id
	var host_name: String = _get_player_username(host_id)
	_add_player_to_slot(host_id, host_name, true)

	host_peer_id = host_id

	# Transition game state
	GameManager.change_state(GameManager.GameState.LOBBY)

	print("[LobbyManager] Lobby created - Host: %s (%d)" % [host_name, host_id])
	lobby_created.emit(true)
	EventBus.lobby_state_changed.emit(true, true)


## Joins an existing lobby.
func join_lobby() -> void:
	if is_in_lobby:
		push_warning("[LobbyManager] Already in a lobby")
		return

	if NetworkManager.get_connection_state() == NetworkManager.ConnectionState.DISCONNECTED:
		push_error("[LobbyManager] Must connect to network first")
		return

	_reset_lobby_state()
	is_in_lobby = true
	is_lobby_host = false
	game_started = false

	print("[LobbyManager] Joining lobby...")
	EventBus.lobby_state_changed.emit(true, false)
	# Full state will be received from host


## Leaves the current lobby.
func leave_lobby() -> void:
	if not is_in_lobby:
		return

	var was_host: bool = is_lobby_host

	if was_host:
		# Host leaving closes the lobby
		_send_lobby_packet(0, {"action": "lobby_closed", "reason": "Host left"})

	# Leave Steam lobby if using Steam
	if SteamManager.is_steam_running and SteamManager.current_lobby_id != 0:
		SteamManager.leave_lobby()

	_steam_lobby_code = ""
	_reset_lobby_state()
	NetworkManager.leave_game()

	GameManager.change_state(GameManager.GameState.NONE)

	print("[LobbyManager] Left lobby")
	lobby_left.emit()
	EventBus.lobby_state_changed.emit(false, false)


## Toggles ready state for the local player.
func toggle_ready() -> void:
	if not is_in_lobby:
		push_warning("[LobbyManager] Not in a lobby")
		return

	if local_slot_index < 0:
		push_warning("[LobbyManager] Not assigned to a slot")
		return

	var slot: LobbySlot = _slots[local_slot_index]
	slot.is_ready = not slot.is_ready

	print("[LobbyManager] Ready state: %s" % str(slot.is_ready))
	player_ready_changed.emit(NetworkManager.local_peer_id, slot.is_ready)
	EventBus.lobby_player_ready_changed.emit(NetworkManager.local_peer_id, slot.is_ready)
	player_slot_updated.emit(local_slot_index, slot)

	# Notify others
	_send_lobby_packet(0, {
		"action": "ready_changed",
		"peer_id": NetworkManager.local_peer_id,
		"is_ready": slot.is_ready,
	})

	_check_all_ready()


## Sets ready state for the local player.
func set_ready(ready: bool) -> void:
	if not is_in_lobby or local_slot_index < 0:
		return

	var slot: LobbySlot = _slots[local_slot_index]
	if slot.is_ready == ready:
		return

	slot.is_ready = ready
	player_ready_changed.emit(NetworkManager.local_peer_id, ready)
	player_slot_updated.emit(local_slot_index, slot)

	_send_lobby_packet(0, {
		"action": "ready_changed",
		"peer_id": NetworkManager.local_peer_id,
		"is_ready": ready,
	})

	_check_all_ready()


## Host starts the game (only callable by host).
func start_game() -> bool:
	if not is_lobby_host:
		push_error("[LobbyManager] Only host can start the game")
		return false

	if not can_start_game():
		push_warning("[LobbyManager] Cannot start game - conditions not met")
		return false

	game_started = true

	# Notify all players
	_send_lobby_packet(0, {"action": "game_starting"})

	print("[LobbyManager] Starting game!")
	game_starting.emit()

	# Transition to SETUP state
	GameManager.change_state(GameManager.GameState.SETUP)

	return true


## Returns true if the game can be started.
func can_start_game() -> bool:
	if not is_lobby_host:
		return false

	var player_count: int = get_player_count()
	if player_count < MIN_PLAYERS:
		return false

	return are_all_players_ready()


## Returns true if all players are ready.
func are_all_players_ready() -> bool:
	for slot in _slots:
		if slot.is_occupied() and not slot.is_ready:
			return false
	return get_player_count() > 0


## Returns the number of players in the lobby.
func get_player_count() -> int:
	var count: int = 0
	for slot in _slots:
		if slot.is_occupied():
			count += 1
	return count


## Returns all slots.
func get_slots() -> Array[LobbySlot]:
	return _slots


## Returns the slot for a given peer ID, or null if not found.
func get_slot_by_peer_id(peer_id: int) -> LobbySlot:
	for slot in _slots:
		if slot.peer_id == peer_id:
			return slot
	return null


## Returns the local player's slot, or null if not in lobby.
func get_local_slot() -> LobbySlot:
	if local_slot_index >= 0 and local_slot_index < _slots.size():
		return _slots[local_slot_index]
	return null


## Host kicks a player from the lobby.
func kick_player(peer_id: int, reason: String = "Kicked by host") -> bool:
	if not is_lobby_host:
		push_error("[LobbyManager] Only host can kick players")
		return false

	if peer_id == NetworkManager.local_peer_id:
		push_error("[LobbyManager] Cannot kick yourself")
		return false

	var slot: LobbySlot = get_slot_by_peer_id(peer_id)
	if not slot:
		push_warning("[LobbyManager] Player not found: %d" % peer_id)
		return false

	# Notify the player they're being kicked
	_send_lobby_packet(peer_id, {"action": "kicked", "reason": reason})

	# Remove from slot
	var slot_index: int = slot.slot_index
	slot.clear()

	print("[LobbyManager] Kicked player %d: %s" % [peer_id, reason])
	player_kicked.emit(peer_id, reason)
	player_slot_updated.emit(slot_index, slot)

	_broadcast_lobby_state()
	_check_all_ready()

	return true


## Returns true if late joining is prevented (game has started).
func is_late_join_prevented() -> bool:
	return game_started


## Returns the Steam lobby code (empty if not using Steam or no lobby).
func get_lobby_code() -> String:
	return _steam_lobby_code


# =============================================================================
# INTERNAL - Slot Management
# =============================================================================


func _initialize_slots() -> void:
	_slots.clear()
	for i in range(MAX_PLAYERS):
		_slots.append(LobbySlot.new(i))


func _reset_lobby_state() -> void:
	is_in_lobby = false
	is_lobby_host = false
	local_slot_index = -1
	host_peer_id = 0
	game_started = false
	_next_join_order = 0
	_sync_timer = 0.0
	_initialize_slots()


func _add_player_to_slot(peer_id: int, username: String, is_host: bool) -> int:
	# Find first empty slot
	for slot in _slots:
		if slot.is_empty():
			slot.peer_id = peer_id
			slot.username = username
			slot.is_host = is_host
			slot.is_ready = false
			slot.join_order = _next_join_order
			_next_join_order += 1

			if peer_id == NetworkManager.local_peer_id:
				local_slot_index = slot.slot_index
				lobby_joined.emit(slot.slot_index)

			print("[LobbyManager] Player added to slot %d: %s (%d)" % [
				slot.slot_index, username, peer_id
			])
			player_slot_updated.emit(slot.slot_index, slot)
			lobby_state_updated.emit(_get_slots_as_array())
			EventBus.lobby_players_updated.emit(get_player_count(), _get_slots_as_array())
			return slot.slot_index

	push_warning("[LobbyManager] No empty slots available")
	return -1


func _remove_player_from_slot(peer_id: int) -> void:
	for slot in _slots:
		if slot.peer_id == peer_id:
			var was_host: bool = slot.is_host
			var slot_index: int = slot.slot_index
			slot.clear()

			if peer_id == NetworkManager.local_peer_id:
				local_slot_index = -1

			print("[LobbyManager] Player removed from slot %d" % slot_index)
			player_slot_updated.emit(slot_index, slot)
			lobby_state_updated.emit(_get_slots_as_array())
			EventBus.lobby_players_updated.emit(get_player_count(), _get_slots_as_array())

			# Handle host migration if the host left
			if was_host and is_in_lobby:
				_handle_host_migration()

			_check_all_ready()
			return


func _handle_host_migration() -> void:
	if not is_in_lobby:
		return

	# Find the player with the lowest join_order
	var new_host_slot: LobbySlot = null
	var lowest_order: int = 999999

	for slot in _slots:
		if slot.is_occupied() and slot.join_order < lowest_order:
			lowest_order = slot.join_order
			new_host_slot = slot

	if new_host_slot:
		new_host_slot.is_host = true
		host_peer_id = new_host_slot.peer_id

		# Check if we became the host
		if new_host_slot.peer_id == NetworkManager.local_peer_id:
			is_lobby_host = true
			print("[LobbyManager] We are now the host!")
		else:
			is_lobby_host = false

		print("[LobbyManager] Host migrated to: %s (%d)" % [
			new_host_slot.username, new_host_slot.peer_id
		])
		host_changed.emit(new_host_slot.peer_id, new_host_slot.username)
		EventBus.lobby_host_changed.emit(new_host_slot.peer_id, new_host_slot.username)
		player_slot_updated.emit(new_host_slot.slot_index, new_host_slot)
		lobby_state_updated.emit(_get_slots_as_array())

		# If we're the new host, broadcast state
		if is_lobby_host:
			_broadcast_lobby_state()
	else:
		# No players left, close lobby
		print("[LobbyManager] No players left, closing lobby")
		lobby_closed.emit("All players left")
		_reset_lobby_state()


func _check_all_ready() -> void:
	var can_start: bool = can_start_game()
	all_players_ready.emit(can_start)
	EventBus.lobby_can_start.emit(can_start)


func _get_slots_as_array() -> Array:
	var result: Array = []
	for slot in _slots:
		result.append(slot.to_dict())
	return result


func _get_player_username(peer_id: int) -> String:
	var player: Resource = NetworkManager.get_player(peer_id)
	if player:
		return player.username
	return "Player_%d" % peer_id


# =============================================================================
# INTERNAL - Network Communication
# =============================================================================


func _connect_network_signals() -> void:
	NetworkManager.player_joined_network.connect(_on_player_joined_network)
	NetworkManager.player_left_network.connect(_on_player_left_network)
	NetworkManager.connection_state_changed.connect(_on_connection_state_changed)
	NetworkManager.packet_received.connect(_on_packet_received)
	NetworkManager.lobby_joined.connect(_on_network_lobby_joined)


func _connect_steam_signals() -> void:
	if not SteamManager.is_steam_running:
		return

	SteamManager.lobby_created.connect(_on_steam_lobby_created)
	SteamManager.lobby_create_failed.connect(_on_steam_lobby_create_failed)
	SteamManager.lobby_joined.connect(_on_steam_lobby_joined)
	SteamManager.lobby_join_failed.connect(_on_steam_lobby_join_failed)
	SteamManager.lobby_member_joined.connect(_on_steam_member_joined)
	SteamManager.lobby_member_left.connect(_on_steam_member_left)


func _send_lobby_packet(target: int, data: Dictionary) -> void:
	data["_lobby"] = true
	NetworkManager.send_game_packet(target, data, true)


func _broadcast_lobby_state() -> void:
	if not is_lobby_host:
		return

	_send_lobby_packet(0, {
		"action": "full_state",
		"slots": _get_slots_as_array(),
		"host_peer_id": host_peer_id,
		"game_started": game_started,
	})


func _on_player_joined_network(peer_id: int, username: String) -> void:
	if not is_in_lobby:
		return

	# Prevent late joins
	if game_started:
		if is_lobby_host:
			_send_lobby_packet(peer_id, {
				"action": "join_rejected",
				"reason": "Game already started",
			})
		return

	# Only host adds players to slots
	if is_lobby_host:
		var slot_index: int = _add_player_to_slot(peer_id, username, false)
		if slot_index >= 0:
			# Send full state to the new player
			_send_lobby_packet(peer_id, {
				"action": "full_state",
				"slots": _get_slots_as_array(),
				"host_peer_id": host_peer_id,
				"game_started": game_started,
			})
		else:
			# Lobby full
			_send_lobby_packet(peer_id, {
				"action": "join_rejected",
				"reason": "Lobby is full",
			})


func _on_player_left_network(peer_id: int) -> void:
	if not is_in_lobby:
		return

	_remove_player_from_slot(peer_id)


func _on_connection_state_changed(state: int) -> void:
	if state == NetworkManager.ConnectionState.DISCONNECTED:
		if is_in_lobby:
			print("[LobbyManager] Connection lost")
			lobby_closed.emit("Connection lost")
			_reset_lobby_state()


func _on_network_lobby_joined(_lobby_id: int) -> void:
	# When we join a network lobby, join the game lobby too
	if not is_in_lobby:
		join_lobby()


func _on_packet_received(sender_id: int, data: Dictionary) -> void:
	if not data.has("_lobby"):
		return

	if not data.has("action"):
		return

	match data.action:
		"full_state":
			_handle_full_state(data)
		"ready_changed":
			_handle_ready_changed(sender_id, data)
		"game_starting":
			_handle_game_starting()
		"lobby_closed":
			_handle_lobby_closed(data)
		"kicked":
			_handle_kicked(data)
		"join_rejected":
			_handle_join_rejected(data)


func _handle_full_state(data: Dictionary) -> void:
	if not data.has("slots"):
		return

	# Update local slots from received data
	for slot_data in data.slots:
		var idx: int = slot_data.get("slot_index", -1)
		if idx >= 0 and idx < _slots.size():
			_slots[idx].from_dict(slot_data)

			# Track our local slot
			if _slots[idx].peer_id == NetworkManager.local_peer_id:
				local_slot_index = idx

	if data.has("host_peer_id"):
		host_peer_id = data.host_peer_id
		is_lobby_host = (host_peer_id == NetworkManager.local_peer_id)

	if data.has("game_started"):
		game_started = data.game_started

	lobby_state_updated.emit(_get_slots_as_array())
	_check_all_ready()

	print("[LobbyManager] Received full state - %d players" % get_player_count())


func _handle_ready_changed(sender_id: int, data: Dictionary) -> void:
	var peer_id: int = data.get("peer_id", sender_id)
	var is_ready: bool = data.get("is_ready", false)

	var slot: LobbySlot = get_slot_by_peer_id(peer_id)
	if slot:
		slot.is_ready = is_ready
		player_ready_changed.emit(peer_id, is_ready)
		player_slot_updated.emit(slot.slot_index, slot)
		_check_all_ready()

		print("[LobbyManager] Player %d ready: %s" % [peer_id, str(is_ready)])


func _handle_game_starting() -> void:
	game_started = true
	print("[LobbyManager] Game starting!")
	game_starting.emit()

	# Non-host players transition to SETUP
	if not is_lobby_host:
		GameManager.change_state(GameManager.GameState.SETUP)


func _handle_lobby_closed(data: Dictionary) -> void:
	var reason: String = data.get("reason", "Unknown")
	print("[LobbyManager] Lobby closed: %s" % reason)
	lobby_closed.emit(reason)
	_reset_lobby_state()

	GameManager.change_state(GameManager.GameState.NONE)


func _handle_kicked(data: Dictionary) -> void:
	var reason: String = data.get("reason", "Kicked by host")
	print("[LobbyManager] You were kicked: %s" % reason)
	lobby_closed.emit(reason)
	_reset_lobby_state()
	NetworkManager.leave_game()

	GameManager.change_state(GameManager.GameState.NONE)


func _handle_join_rejected(data: Dictionary) -> void:
	var reason: String = data.get("reason", "Join rejected")
	print("[LobbyManager] Join rejected: %s" % reason)
	lobby_closed.emit(reason)
	_reset_lobby_state()
	NetworkManager.leave_game()

	GameManager.change_state(GameManager.GameState.NONE)


# =============================================================================
# STEAM LOBBY INTEGRATION (FW-013-08)
# =============================================================================


func _on_steam_lobby_created(steam_lobby_id: int, code: String) -> void:
	_steam_lobby_code = code

	# Now set up the lobby state
	_reset_lobby_state()
	is_in_lobby = true
	is_lobby_host = true
	game_started = false

	# Host uses Steam ID as peer ID
	var host_id: int = SteamManager.steam_id
	var host_name: String = SteamManager.steam_username
	NetworkManager.local_peer_id = host_id  # Sync with NetworkManager

	_add_player_to_slot(host_id, host_name, true)
	host_peer_id = host_id

	# Also start NetworkManager with this Steam lobby
	NetworkManager.host_game(MAX_PLAYERS, false)

	# Transition game state
	GameManager.change_state(GameManager.GameState.LOBBY)

	print("[LobbyManager] Steam lobby created - Code: %s (ID: %d)" % [code, steam_lobby_id])
	lobby_created.emit(true)
	lobby_code_received.emit(code)
	EventBus.lobby_state_changed.emit(true, true)


func _on_steam_lobby_create_failed(reason: String) -> void:
	print("[LobbyManager] Steam lobby creation failed: %s" % reason)
	lobby_closed.emit(reason)


func _on_steam_lobby_joined(steam_lobby_id: int) -> void:
	_steam_lobby_code = SteamManager.current_lobby_code

	# Set up local lobby state as non-host
	_reset_lobby_state()
	is_in_lobby = true
	is_lobby_host = false
	game_started = false

	# Get lobby owner as host
	var owner_id: int = Steam.getLobbyOwner(steam_lobby_id)

	# Use Steam ID as peer ID
	var local_id: int = SteamManager.steam_id
	var local_name: String = SteamManager.steam_username
	NetworkManager.local_peer_id = local_id  # Sync with NetworkManager

	# Add ourselves to a slot
	_add_player_to_slot(local_id, local_name, false)
	host_peer_id = owner_id

	# Also start NetworkManager connection
	NetworkManager.join_game(steam_lobby_id)

	# Transition game state
	GameManager.change_state(GameManager.GameState.LOBBY)

	print("[LobbyManager] Joined Steam lobby - Code: %s (ID: %d)" % [
		_steam_lobby_code, steam_lobby_id
	])
	lobby_joined.emit(local_slot_index)
	lobby_code_received.emit(_steam_lobby_code)
	EventBus.lobby_state_changed.emit(true, false)


func _on_steam_lobby_join_failed(reason: String) -> void:
	print("[LobbyManager] Steam lobby join failed: %s" % reason)
	lobby_closed.emit(reason)


func _on_steam_member_joined(member_steam_id: int) -> void:
	if not is_in_lobby:
		return

	# Don't add ourselves again
	if member_steam_id == SteamManager.steam_id:
		return

	# Prevent late joins
	if game_started:
		return

	var member_name: String = SteamManager.get_member_name(member_steam_id)
	var slot_index: int = _add_player_to_slot(member_steam_id, member_name, false)

	if slot_index >= 0:
		print("[LobbyManager] Steam member joined: %s" % member_name)


func _on_steam_member_left(member_steam_id: int) -> void:
	if not is_in_lobby:
		return

	_remove_player_from_slot(member_steam_id)
	print("[LobbyManager] Steam member left: %d" % member_steam_id)
