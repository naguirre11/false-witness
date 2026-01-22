extends Node
## Manages Steam initialization and callbacks.
## Autoload: SteamManager
##
## Based on GodotSteam Template (https://github.com/wahan-h/GodotSteam-Template)
## Adapted for False Witness multiplayer architecture.

signal steam_initialized(success: bool)
signal lobby_created(lobby_id: int, code: String)
signal lobby_create_failed(reason: String)
signal lobby_joined(lobby_id: int)
signal lobby_join_failed(reason: String)
signal lobby_member_joined(steam_id: int)
signal lobby_member_left(steam_id: int)
signal lobby_data_changed(key: String, value: String)

const APP_ID: int = 480  # Spacewar test app - replace with real ID for release
const LOBBY_CODE_CHARS: String = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const STEAM_APP_ID_ENV: String = "SteamAppId"
const STEAM_GAME_ID_ENV: String = "SteamGameId"

var steam_id: int = 0
var steam_username: String = ""
var is_steam_running: bool = false

# Lobby state
var current_lobby_id: int = 0
var current_lobby_code: String = ""
var _lobby_members: Array[int] = []
var _code_to_lobby: Dictionary = {}  # code -> lobby_id mapping


func _init() -> void:
	# Set environment variables before Steam initializes
	OS.set_environment(STEAM_APP_ID_ENV, str(APP_ID))
	OS.set_environment(STEAM_GAME_ID_ENV, str(APP_ID))


func _ready() -> void:
	_initialize_steam()


func _process(_delta: float) -> void:
	if is_steam_running:
		Steam.run_callbacks()


func _initialize_steam() -> void:
	var init_result: Dictionary = Steam.steamInitEx(false, APP_ID)

	match init_result.status:
		Steam.STEAM_API_INIT_RESULT_OK:
			is_steam_running = true
			steam_id = Steam.getSteamID()
			steam_username = Steam.getPersonaName()
			_connect_steam_signals()
			print("[SteamManager] Initialized - User: %s (ID: %d)" % [steam_username, steam_id])
			steam_initialized.emit(true)
		Steam.STEAM_API_INIT_RESULT_FAILED_GENERIC:
			push_error("[SteamManager] Failed to initialize: %s" % init_result.verbal)
			steam_initialized.emit(false)
		_:
			push_error("[SteamManager] Steam not running or other error: %s" % init_result.verbal)
			steam_initialized.emit(false)


func _connect_steam_signals() -> void:
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_data_update.connect(_on_lobby_data_update)
	Steam.join_requested.connect(_on_join_requested)


func get_steam_id() -> int:
	return steam_id


func get_steam_username() -> String:
	return steam_username


# =============================================================================
# LOBBY CREATION AND MANAGEMENT (FW-013-03, FW-013-04, FW-013-05, FW-013-06)
# =============================================================================

## Create a new Steam lobby. Results arrive via lobby_created or lobby_create_failed.
func create_lobby(max_members: int = 6) -> void:
	if not is_steam_running:
		lobby_create_failed.emit("Steam not running")
		return

	if current_lobby_id != 0:
		lobby_create_failed.emit("Already in a lobby")
		return

	Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, max_members)
	print("[SteamManager] Creating lobby for %d players..." % max_members)


## Join a lobby using the 6-character code.
func join_lobby(code: String) -> void:
	if not is_steam_running:
		lobby_join_failed.emit("Steam not running")
		return

	if current_lobby_id != 0:
		lobby_join_failed.emit("Already in a lobby")
		return

	var lobby_id := _decode_lobby_code(code.to_upper())
	if lobby_id == 0:
		lobby_join_failed.emit("Invalid lobby code")
		return

	Steam.joinLobby(lobby_id)
	print("[SteamManager] Joining lobby %s (ID: %d)..." % [code, lobby_id])


## Leave the current lobby.
func leave_lobby() -> void:
	if current_lobby_id != 0:
		Steam.leaveLobby(current_lobby_id)
		print("[SteamManager] Left lobby %d" % current_lobby_id)
		current_lobby_id = 0
		current_lobby_code = ""
		_lobby_members.clear()


## Get list of Steam IDs in the current lobby.
func get_lobby_members() -> Array[int]:
	return _lobby_members.duplicate()


## Get display name for a Steam ID.
func get_member_name(member_steam_id: int) -> String:
	return Steam.getFriendPersonaName(member_steam_id)


## Check if this client is the lobby owner (host).
func is_lobby_owner() -> bool:
	if current_lobby_id == 0:
		return false
	return Steam.getLobbyOwner(current_lobby_id) == steam_id


# =============================================================================
# LOBBY DATA SYNC (FW-013-07)
# =============================================================================

## Set lobby data (host only). Syncs to all members.
func set_lobby_data(key: String, value: String) -> void:
	if current_lobby_id == 0:
		push_warning("[SteamManager] Cannot set lobby data: not in a lobby")
		return

	if not is_lobby_owner():
		push_warning("[SteamManager] Cannot set lobby data: not the lobby owner")
		return

	Steam.setLobbyData(current_lobby_id, key, value)


## Get lobby data by key.
func get_lobby_data(key: String) -> String:
	if current_lobby_id == 0:
		return ""
	return Steam.getLobbyData(current_lobby_id, key)


# =============================================================================
# FRIEND INVITES (FW-013-09)
# =============================================================================

## Invite a Steam friend to the current lobby.
func invite_friend(friend_steam_id: int) -> void:
	if current_lobby_id == 0:
		push_warning("[SteamManager] Cannot invite: not in a lobby")
		return

	Steam.inviteUserToLobby(current_lobby_id, friend_steam_id)
	print("[SteamManager] Invited %s to lobby" % Steam.getFriendPersonaName(friend_steam_id))


# =============================================================================
# RICH PRESENCE (FW-013-12)
# =============================================================================

## Update Steam rich presence for friends list display.
func update_rich_presence(status: String) -> void:
	if not is_steam_running:
		return

	Steam.setRichPresence("status", status)

	# Set steam_display key for proper formatting
	Steam.setRichPresence("steam_display", "#Status")


## Clear rich presence when leaving game.
func clear_rich_presence() -> void:
	if is_steam_running:
		Steam.clearRichPresence()


# =============================================================================
# LOBBY CODE ENCODING/DECODING (FW-013-04)
# =============================================================================

## Generate a 6-character alphanumeric code from a lobby ID using base36.
func _generate_lobby_code(lobby_id: int) -> String:
	var code := ""
	var value := lobby_id

	# Generate 6 base36 characters
	for i in range(6):
		code = LOBBY_CODE_CHARS[value % 36] + code
		value = value / 36

	return code


## Decode a 6-character code back to a lobby ID.
func _decode_lobby_code(code: String) -> int:
	if code.length() != 6:
		return 0

	var lobby_id := 0
	for i in range(6):
		var char_idx := LOBBY_CODE_CHARS.find(code[i])
		if char_idx == -1:
			return 0  # Invalid character
		lobby_id = lobby_id * 36 + char_idx

	return lobby_id


# =============================================================================
# STEAM CALLBACK HANDLERS
# =============================================================================

func _on_lobby_created(result: int, lobby_id: int) -> void:
	if result == Steam.RESULT_OK:
		current_lobby_id = lobby_id
		current_lobby_code = _generate_lobby_code(lobby_id)
		_code_to_lobby[current_lobby_code] = lobby_id

		# Store code in lobby data for members to retrieve
		Steam.setLobbyData(lobby_id, "code", current_lobby_code)

		_refresh_lobby_members()

		print("[SteamManager] Lobby created: %s (ID: %d)" % [current_lobby_code, lobby_id])
		lobby_created.emit(lobby_id, current_lobby_code)
	else:
		var reason := "Unknown error (code: %d)" % result
		push_error("[SteamManager] Lobby creation failed: %s" % reason)
		lobby_create_failed.emit(reason)


func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, result: int) -> void:
	if result == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		current_lobby_id = lobby_id

		# Retrieve lobby code from lobby data
		current_lobby_code = Steam.getLobbyData(lobby_id, "code")
		if current_lobby_code.is_empty():
			current_lobby_code = _generate_lobby_code(lobby_id)

		_code_to_lobby[current_lobby_code] = lobby_id
		_refresh_lobby_members()

		print("[SteamManager] Joined lobby: %s (ID: %d)" % [current_lobby_code, lobby_id])
		lobby_joined.emit(lobby_id)
	else:
		var reason := _get_join_error_message(result)
		push_error("[SteamManager] Failed to join lobby: %s" % reason)
		lobby_join_failed.emit(reason)


func _on_lobby_chat_update(
	lobby_id: int,
	changed_steam_id: int,
	making_change_steam_id: int,
	state_change: int
) -> void:
	if lobby_id != current_lobby_id:
		return

	# Ignore making_change_steam_id, just track the changed user
	var _unused := making_change_steam_id

	# Check state change flags
	if state_change & Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		if changed_steam_id not in _lobby_members:
			_lobby_members.append(changed_steam_id)
			var name := get_member_name(changed_steam_id)
			print("[SteamManager] Player joined: %s" % name)
			lobby_member_joined.emit(changed_steam_id)

	if state_change & Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
		_lobby_members.erase(changed_steam_id)
		var name := get_member_name(changed_steam_id)
		print("[SteamManager] Player left: %s" % name)
		lobby_member_left.emit(changed_steam_id)

	if state_change & Steam.CHAT_MEMBER_STATE_CHANGE_DISCONNECTED:
		_lobby_members.erase(changed_steam_id)
		var name := get_member_name(changed_steam_id)
		print("[SteamManager] Player disconnected: %s" % name)
		lobby_member_left.emit(changed_steam_id)

	if state_change & Steam.CHAT_MEMBER_STATE_CHANGE_KICKED:
		_lobby_members.erase(changed_steam_id)
		var name := get_member_name(changed_steam_id)
		print("[SteamManager] Player kicked: %s" % name)
		lobby_member_left.emit(changed_steam_id)

	if state_change & Steam.CHAT_MEMBER_STATE_CHANGE_BANNED:
		_lobby_members.erase(changed_steam_id)
		var name := get_member_name(changed_steam_id)
		print("[SteamManager] Player banned: %s" % name)
		lobby_member_left.emit(changed_steam_id)


func _on_lobby_data_update(lobby_id: int, member_steam_id: int, key: String) -> void:
	if lobby_id != current_lobby_id:
		return

	# Ignore member_steam_id (indicates who changed data, 0 = lobby data)
	var _unused := member_steam_id

	var value := Steam.getLobbyData(lobby_id, key)
	lobby_data_changed.emit(key, value)


func _on_join_requested(lobby_id: int, _friend_steam_id: int) -> void:
	# Friend clicked "Join Game" from Steam friends list
	print("[SteamManager] Join request received for lobby %d" % lobby_id)

	if current_lobby_id != 0:
		push_warning("[SteamManager] Already in a lobby, leaving first...")
		leave_lobby()

	Steam.joinLobby(lobby_id)


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

func _refresh_lobby_members() -> void:
	_lobby_members.clear()

	if current_lobby_id == 0:
		return

	var member_count := Steam.getNumLobbyMembers(current_lobby_id)
	for i in range(member_count):
		var member_id := Steam.getLobbyMemberByIndex(current_lobby_id, i)
		_lobby_members.append(member_id)


func _get_join_error_message(result: int) -> String:
	match result:
		Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST:
			return "Lobby does not exist"
		Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED:
			return "Not allowed to join"
		Steam.CHAT_ROOM_ENTER_RESPONSE_FULL:
			return "Lobby is full"
		Steam.CHAT_ROOM_ENTER_RESPONSE_ERROR:
			return "Unexpected error"
		Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED:
			return "Banned from lobby"
		Steam.CHAT_ROOM_ENTER_RESPONSE_LIMITED:
			return "Limited user account"
		Steam.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED:
			return "Clan disabled"
		Steam.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN:
			return "Community banned"
		Steam.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU:
			return "Blocked by member"
		Steam.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER:
			return "You blocked a member"
		_:
			return "Unknown error (code: %d)" % result
