extends Node
## Manages Cultist role tracking, assignment, and abilities.
## Autoload: CultistManager
##
## Handles:
## - Cultist role assignment at match start
## - Server-authoritative role storage
## - Cultist-specific data (entity type, evidence types)
## - Ability charge tracking and validation
##
## Note: No class_name to avoid conflicts with autoload singleton name.

# --- Signals ---

## Emitted when roles are assigned at match start.
signal roles_assigned(role_map: Dictionary)

## Emitted when a Cultist uses an ability.
signal ability_used(player_id: int, ability_type: String, location: Vector3)

## Emitted when a Cultist is discovered via vote.
signal cultist_discovered(player_id: int)

## Emitted when local player receives their role.
signal local_role_received(role: int, is_cultist: bool)

## Emitted when action log is sent at match end (for results screen).
signal action_log_received(action_log: Array)

# --- Constants ---

## Minimum players required for a match
const MIN_PLAYERS := 4

## Maximum players in a match
const MAX_PLAYERS := 6

## Default Cultist count for 6-player games (can be 1 or 2)
const DEFAULT_CULTIST_COUNT_6P := 1

# --- State ---

## Array of player IDs who are Cultists (server-only)
var _cultist_ids: Array[int] = []

## True entity type for this match (known to Cultists, server-only)
var _entity_type: String = ""

## Evidence types that the entity produces (known to Cultists, server-only)
var _entity_evidence: Array[String] = []

## Role map: player_id -> CultistEnums.PlayerRole (server-only)
var _role_map: Dictionary = {}

## Whether this instance is the server/host
var _is_server: bool = false

## Local player's role (received from server)
var _local_role: int = -1  # CultistEnums.PlayerRole, -1 = unassigned

## Local player's Cultist data (only set if player is Cultist)
var _local_entity_type: String = ""
var _local_entity_evidence: Array[String] = []

## Allied Cultist IDs (for 2-Cultist variant, only set if player is Cultist)
var _local_allied_cultists: Array[int] = []

## Cultist count setting for 6-player games
var _cultist_count_6p: int = DEFAULT_CULTIST_COUNT_6P

## Random number generator for role assignment
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

## Action log for post-game reveal (server-only)
## Each entry: {timestamp, ability_type, player_id, location, target, evidence_uid}
var _action_log: Array[Dictionary] = []


func _ready() -> void:
	# Connect to game state changes
	if EventBus:
		EventBus.game_state_changed.connect(_on_game_state_changed)
	print("[CultistManager] Initialized")


# --- Public API ---


## Returns true if the given player is a Cultist.
## Server-authoritative: only server has accurate data.
func is_cultist(player_id: int) -> bool:
	return player_id in _cultist_ids


## Returns the number of Cultists in the current match.
func get_cultist_count() -> int:
	return _cultist_ids.size()


## Gets the array of Cultist player IDs (server-only).
func get_cultist_ids() -> Array[int]:
	if not _is_server:
		push_warning("[CultistManager] get_cultist_ids() called on client")
		return []
	return _cultist_ids.duplicate()


## Gets the true entity type (server-only, or local if Cultist).
func get_entity_type() -> String:
	if _is_server:
		return _entity_type
	return _local_entity_type


## Gets the entity's evidence types (server-only, or local if Cultist).
func get_entity_evidence() -> Array[String]:
	if _is_server:
		return _entity_evidence.duplicate()
	return _local_entity_evidence.duplicate()


## Gets the local player's role.
## Returns -1 if role not yet assigned.
func get_local_role() -> int:
	return _local_role


## Returns true if local player is a Cultist.
func is_local_player_cultist() -> bool:
	if _local_role == -1:
		return false
	# CultistEnums.PlayerRole.CULTIST = 1
	return _local_role == 1


## Gets allied Cultist IDs (only valid if local player is Cultist).
func get_allied_cultist_ids() -> Array[int]:
	return _local_allied_cultists.duplicate()


## Sets the Cultist count for 6-player games.
func set_cultist_count_6p(count: int) -> void:
	_cultist_count_6p = clampi(count, 1, 2)


## Gets the Cultist count setting for 6-player games.
func get_cultist_count_6p() -> int:
	return _cultist_count_6p


## Assigns roles to players at match start.
## Server-only. Returns Dictionary mapping player_id -> PlayerRole.
## player_ids: Array of player IDs in the match
## entity_type: The true entity type for this match
## entity_evidence: The evidence types the entity produces
func assign_roles(
	player_ids: Array[int], entity_type: String, entity_evidence: Array[String]
) -> Dictionary:
	if not _is_server:
		push_warning("[CultistManager] Only server can assign roles")
		return {}

	var player_count := player_ids.size()
	if player_count < MIN_PLAYERS or player_count > MAX_PLAYERS:
		push_error("[CultistManager] Invalid player count: %d" % player_count)
		return {}

	# Store entity info
	_entity_type = entity_type
	_entity_evidence = entity_evidence.duplicate()

	# Determine Cultist count
	var cultist_count := 1
	if player_count == 6:
		cultist_count = _cultist_count_6p

	# Randomly select Cultists
	_rng.randomize()
	var shuffled := player_ids.duplicate()
	_shuffle_array(shuffled)

	_cultist_ids.clear()
	for i in range(cultist_count):
		_cultist_ids.append(shuffled[i])

	# Build role map
	_role_map.clear()
	for player_id in player_ids:
		if player_id in _cultist_ids:
			_role_map[player_id] = 1  # CULTIST
		else:
			_role_map[player_id] = 0  # INVESTIGATOR

	roles_assigned.emit(_role_map)

	print(
		"[CultistManager] Roles assigned: %d Cultists among %d players"
		% [_cultist_ids.size(), player_count]
	)

	return _role_map.duplicate()


## Seeds the RNG for reproducible testing.
func seed_rng(seed_value: int) -> void:
	_rng.seed = seed_value


## Sets whether this instance is the server/host.
func set_is_server(is_server: bool) -> void:
	_is_server = is_server


## Returns whether this instance is the server/host.
func is_server() -> bool:
	return _is_server


## Resets the manager state for a new match.
func reset() -> void:
	_cultist_ids.clear()
	_entity_type = ""
	_entity_evidence.clear()
	_role_map.clear()
	_local_role = -1
	_local_entity_type = ""
	_local_entity_evidence.clear()
	_local_allied_cultists.clear()
	_action_log.clear()
	print("[CultistManager] Reset for new match")


# --- Action Logging API ---


## Logs a Cultist ability use for post-game reveal.
## Called when a Cultist uses a contamination ability.
## Returns the action entry dictionary for linking with evidence.
func log_ability_use(
	player_id: int,
	ability_type: int,
	location: Vector3,
	target: int = -1,  # Optional target player ID
	evidence_uid: String = ""  # Optional link to ContaminatedEvidence
) -> Dictionary:
	if not _is_server:
		push_warning("[CultistManager] Only server can log ability use")
		return {}

	var entry := {
		"timestamp": Time.get_unix_time_from_system(),
		"ability_type": ability_type,
		"player_id": player_id,
		"location": {"x": location.x, "y": location.y, "z": location.z},
		"target": target,
		"evidence_uid": evidence_uid,
	}

	_action_log.append(entry)

	# Emit signal for real-time tracking
	var ability_name := _get_ability_name(ability_type)
	ability_used.emit(player_id, ability_name, location)

	print("[CultistManager] Logged ability use: %s by player %d" % [ability_name, player_id])
	return entry


## Links an evidence UID to an existing action log entry.
## Call this after evidence is created to connect it to the ability use.
func link_evidence_to_action(evidence_uid: String, action_index: int = -1) -> void:
	if not _is_server:
		return

	# Default to most recent action if index not specified
	var idx := action_index if action_index >= 0 else _action_log.size() - 1
	if idx >= 0 and idx < _action_log.size():
		_action_log[idx]["evidence_uid"] = evidence_uid


## Gets the full action log (server-only).
func get_action_log() -> Array[Dictionary]:
	if not _is_server:
		push_warning("[CultistManager] Only server can get full action log")
		return []
	return _action_log.duplicate()


## Gets the number of logged actions.
func get_action_count() -> int:
	return _action_log.size()


## Gets actions for a specific player.
func get_player_actions(player_id: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in _action_log:
		if entry.player_id == player_id:
			result.append(entry)
	return result


## Sends the action log to all clients at match end.
## Call this when the match ends to reveal Cultist actions.
func send_action_log_to_clients() -> void:
	if not _is_server:
		return

	# Convert to serializable format
	var log_data: Array = []
	for entry: Dictionary in _action_log:
		log_data.append(entry)

	# Send to all clients
	_receive_action_log.rpc(log_data)

	# Also emit locally for server player
	action_log_received.emit(log_data)

	print("[CultistManager] Sent action log (%d entries) to all clients" % _action_log.size())


func _get_ability_name(ability_type: int) -> String:
	# CultistEnums.AbilityType mapping
	match ability_type:
		0: return "NONE"
		1: return "EMF_SPOOF"
		2: return "TEMPERATURE_MANIPULATION"
		3: return "PRISM_INTERFERENCE"
		4: return "AURA_DISRUPTION"
		5: return "PROVOCATION"
		6: return "FALSE_ALARM"
		7: return "EQUIPMENT_SABOTAGE"
		_: return "UNKNOWN"


# --- RPC Methods ---


## Receives Cultist-specific data from server.
## Called only for Cultist players.
@rpc("authority", "call_remote", "reliable")
func _receive_cultist_data(
	entity_type: String, evidence_types: Array, allied_cultist_ids: Array
) -> void:
	_local_entity_type = entity_type
	_local_entity_evidence.clear()
	for ev in evidence_types:
		_local_entity_evidence.append(str(ev))
	_local_allied_cultists.clear()
	for cid in allied_cultist_ids:
		_local_allied_cultists.append(int(cid))
	print("[CultistManager] Received Cultist data: entity=%s, evidence=%s" % [entity_type, evidence_types])


## Receives role assignment from server.
@rpc("authority", "call_remote", "reliable")
func _receive_role(role: int) -> void:
	_local_role = role
	var is_cultist := role == 1  # CultistEnums.PlayerRole.CULTIST
	local_role_received.emit(role, is_cultist)
	print("[CultistManager] Received role: %s" % ("CULTIST" if is_cultist else "INVESTIGATOR"))


## Receives action log from server at match end.
@rpc("authority", "call_remote", "reliable")
func _receive_action_log(log_data: Array) -> void:
	action_log_received.emit(log_data)
	print("[CultistManager] Received action log with %d entries" % log_data.size())


# --- Internal Methods ---


## Fisher-Yates shuffle for random selection.
func _shuffle_array(arr: Array) -> void:
	var n := arr.size()
	for i in range(n - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var temp = arr[i]
		arr[i] = arr[j]
		arr[j] = temp


func _on_game_state_changed(old_state: int, new_state: int) -> void:
	# LOBBY = 0, SETUP = 1
	const LOBBY := 0
	const SETUP := 1

	if new_state == LOBBY:
		# Returning to lobby - reset state
		reset()

		# Determine if we're the server
		if NetworkManager:
			_is_server = NetworkManager.is_game_host()
		else:
			_is_server = true  # Single player fallback

	elif new_state == SETUP and old_state == LOBBY:
		# Transitioning from LOBBY to SETUP - server assigns roles
		if _is_server:
			_trigger_role_assignment()


## Server triggers role assignment and distributes to all clients.
func _trigger_role_assignment() -> void:
	if not _is_server:
		return

	# Get player IDs from LobbyManager
	var player_ids: Array[int] = _get_player_ids()
	if player_ids.size() < MIN_PLAYERS:
		push_warning("[CultistManager] Not enough players for role assignment")
		return

	# Get entity info from EntityManager (or placeholder if not available yet)
	var entity_type := _get_entity_type_for_match()
	var entity_evidence := _get_entity_evidence_for_match()

	# Assign roles
	var role_map := assign_roles(player_ids, entity_type, entity_evidence)

	# Distribute roles to clients
	_distribute_roles_to_clients(role_map)


## Distribute role assignments to all clients via RPC.
func _distribute_roles_to_clients(role_map: Dictionary) -> void:
	if not _is_server:
		return

	# Get allied Cultist IDs for 2-Cultist variant
	var cultist_list := _cultist_ids.duplicate()

	for player_id in role_map.keys():
		var role: int = role_map[player_id]

		# Send role to this player
		if player_id == multiplayer.get_unique_id():
			# Local server player
			_receive_role(role)
			if role == 1:  # CULTIST
				var allies := cultist_list.filter(func(id): return id != player_id)
				_receive_cultist_data(_entity_type, _entity_evidence, allies)
		else:
			# Remote player
			_receive_role.rpc_id(player_id, role)
			if role == 1:  # CULTIST
				var allies := cultist_list.filter(func(id): return id != player_id)
				_receive_cultist_data.rpc_id(player_id, _entity_type, _entity_evidence, allies)


func _get_player_ids() -> Array[int]:
	# Get player IDs from LobbyManager
	if has_node("/root/LobbyManager"):
		var lobby_manager := get_node("/root/LobbyManager")
		if lobby_manager.has_method("get_player_ids"):
			return lobby_manager.get_player_ids()
		# Fallback: try to get from slots
		if lobby_manager.has_method("get_player_slots"):
			var slots: Array = lobby_manager.get_player_slots()
			var ids: Array[int] = []
			for slot in slots:
				if slot.is_occupied and slot.peer_id > 0:
					ids.append(slot.peer_id)
			return ids

	# Single player fallback
	return [1]


func _get_entity_type_for_match() -> String:
	# Get entity type from EntityManager or random selection
	# For now, placeholder - will be connected to entity selection later
	return "Unknown Entity"


func _get_entity_evidence_for_match() -> Array[String]:
	# Get entity evidence types from EntityManager
	# For now, placeholder - will be connected to entity selection later
	return ["EMF_SIGNATURE", "FREEZING_TEMPERATURE", "GHOST_WRITING"]
