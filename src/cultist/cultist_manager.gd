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

## Emitted when ability charges change (for UI updates).
signal ability_charges_changed(player_id: int, ability_type: int, current: int, maximum: int)

## Emitted when a Cultist is discovered via vote.
signal cultist_discovered(player_id: int)

## Emitted when local player receives their role.
signal local_role_received(role: int, is_cultist: bool)

## Emitted when action log is sent at match end (for results screen).
signal action_log_received(action_log: Array)

## Emitted when an emergency vote is called.
signal emergency_vote_called(caller_id: int)

## Emitted when vote cannot be called (reason provided).
signal emergency_vote_rejected(reason: String)

## Emitted when a player casts a vote.
signal vote_cast(voter_id: int, target_id: int)

## Emitted when voting completes.
signal vote_complete(target_id: int, is_majority: bool)

## Emitted when voting timer updates.
signal vote_timer_updated(seconds_remaining: float)

## Emitted when a Cultist is discovered via vote.
signal cultist_voted_discovered(player_id: int)

## Emitted when an innocent player is wrongly voted out.
signal innocent_voted_out(player_id: int)

# --- Constants ---

## Minimum players required for a match
const MIN_PLAYERS := 4

## Maximum players in a match
const MAX_PLAYERS := 6

## Default Cultist count for 6-player games (can be 1 or 2)
const DEFAULT_CULTIST_COUNT_6P := 1

## Maximum emergency votes allowed per match
const MAX_EMERGENCY_VOTES := 2

## Time cost (seconds) to call an emergency vote
const EMERGENCY_VOTE_TIME_COST := 30.0

## Duration of voting period
const VOTING_DURATION := 30.0

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

## Number of emergency votes used this match
var _emergency_votes_used: int = 0

## Whether a vote is currently in progress
var _voting_in_progress: bool = false

## Votes cast: voter_id -> target_id (-1 = skip)
var _current_votes: Dictionary = {}

## Voting timer remaining
var _voting_timer: float = 0.0

## List of alive player IDs for current vote
var _alive_players: Array[int] = []

## Discovered Cultist IDs (discovery_state = DISCOVERED)
var _discovered_cultists: Array[int] = []

## Server-authoritative ability charges by player.
## Structure: {player_id: {ability_type: current_charges}}
var _player_ability_charges: Dictionary = {}

## Maximum charges for each ability type (loaded from CultistEnums).
var _ability_max_charges: Dictionary = {}


func _ready() -> void:
	# Connect to game state changes
	if EventBus:
		EventBus.game_state_changed.connect(_on_game_state_changed)

	# Initialize max charges from CultistEnums
	_init_ability_max_charges()
	print("[CultistManager] Initialized")


func _init_ability_max_charges() -> void:
	# Load default max charges for each ability type
	_ability_max_charges = {
		CultistEnums.AbilityType.EMF_SPOOF: CultistEnums.get_default_charges(
			CultistEnums.AbilityType.EMF_SPOOF
		),
		CultistEnums.AbilityType.TEMPERATURE_MANIPULATION: CultistEnums.get_default_charges(
			CultistEnums.AbilityType.TEMPERATURE_MANIPULATION
		),
		CultistEnums.AbilityType.PRISM_INTERFERENCE: CultistEnums.get_default_charges(
			CultistEnums.AbilityType.PRISM_INTERFERENCE
		),
		CultistEnums.AbilityType.AURA_DISRUPTION: CultistEnums.get_default_charges(
			CultistEnums.AbilityType.AURA_DISRUPTION
		),
		CultistEnums.AbilityType.PROVOCATION: CultistEnums.get_default_charges(
			CultistEnums.AbilityType.PROVOCATION
		),
		CultistEnums.AbilityType.FALSE_ALARM: CultistEnums.get_default_charges(
			CultistEnums.AbilityType.FALSE_ALARM
		),
		CultistEnums.AbilityType.EQUIPMENT_SABOTAGE: CultistEnums.get_default_charges(
			CultistEnums.AbilityType.EQUIPMENT_SABOTAGE
		),
	}


func _process(delta: float) -> void:
	if not _is_server or not _voting_in_progress:
		return

	# Update voting timer
	_voting_timer -= delta
	if _voting_timer <= 0.0:
		_end_voting()
	elif int(_voting_timer) != int(_voting_timer + delta):
		# Emit every second
		vote_timer_updated.emit(_voting_timer)
		_notify_vote_timer.rpc(_voting_timer)


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
	_emergency_votes_used = 0
	_voting_in_progress = false
	_current_votes.clear()
	_voting_timer = 0.0
	_alive_players.clear()
	_discovered_cultists.clear()
	_player_ability_charges.clear()
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


# --- Ability Charge API (Server-Authoritative) ---


## Initializes ability charges for a Cultist player.
## Called when roles are assigned.
func _init_player_charges(player_id: int) -> void:
	if not _is_server:
		return

	var charges: Dictionary = {}
	for ability_type in _ability_max_charges.keys():
		charges[ability_type] = _ability_max_charges[ability_type]

	_player_ability_charges[player_id] = charges
	print("[CultistManager] Initialized charges for player %d" % player_id)


## Gets the current charges for an ability (server-only for full data).
## Returns -1 if player not found or not a Cultist.
func get_ability_charges(player_id: int, ability_type: int) -> int:
	if player_id not in _player_ability_charges:
		return -1
	var charges: Dictionary = _player_ability_charges[player_id]
	if ability_type not in charges:
		return -1
	return charges[ability_type]


## Gets all ability charges for a player.
## Returns empty dictionary if player not found.
func get_all_ability_charges(player_id: int) -> Dictionary:
	if player_id not in _player_ability_charges:
		return {}
	return _player_ability_charges[player_id].duplicate()


## Gets the maximum charges for an ability type.
func get_ability_max_charges(ability_type: int) -> int:
	if ability_type not in _ability_max_charges:
		return 0
	return _ability_max_charges[ability_type]


## Checks if a Cultist can use an ability (has charges and not discovered).
func can_use_ability(player_id: int, ability_type: int) -> bool:
	if not is_cultist(player_id):
		return false
	if is_cultist_discovered(player_id):
		return false
	return get_ability_charges(player_id, ability_type) > 0


## Consumes a charge for an ability (server-only).
## Returns true if charge was consumed, false if no charges available.
func consume_ability_charge(player_id: int, ability_type: int) -> bool:
	if not _is_server:
		push_warning("[CultistManager] Only server can consume charges")
		return false

	var current := get_ability_charges(player_id, ability_type)
	if current <= 0:
		return false

	# Decrement charge
	_player_ability_charges[player_id][ability_type] = current - 1
	var new_count: int = _player_ability_charges[player_id][ability_type]
	var max_count: int = _ability_max_charges.get(ability_type, 0)

	# Emit signal
	ability_charges_changed.emit(player_id, ability_type, new_count, max_count)

	# Sync to client
	_sync_ability_charges(player_id, ability_type, new_count, max_count)

	print("[CultistManager] Consumed charge: player=%d, ability=%d, remaining=%d" % [
		player_id, ability_type, new_count
	])

	return true


## Syncs ability charges to a specific client.
func _sync_ability_charges(
	player_id: int, ability_type: int, current: int, maximum: int
) -> void:
	if not _is_server:
		return

	# Send to the Cultist player
	if player_id == multiplayer.get_unique_id():
		# Local server player
		_receive_ability_charges(ability_type, current, maximum)
	else:
		# Remote player
		_receive_ability_charges.rpc_id(player_id, ability_type, current, maximum)


## Sends all ability charges to a Cultist (called after role assignment).
func send_initial_charges_to_cultist(player_id: int) -> void:
	if not _is_server:
		return

	if player_id not in _player_ability_charges:
		return

	var charges: Dictionary = _player_ability_charges[player_id]
	for ability_type in charges.keys():
		var current: int = charges[ability_type]
		var maximum: int = _ability_max_charges.get(ability_type, 0)
		_sync_ability_charges(player_id, ability_type, current, maximum)


## Client-side request to use an ability.
## Server validates and either allows or denies.
func request_use_ability(ability_type: int, position: Vector3) -> void:
	if _is_server:
		# Server processes directly
		var player_id := multiplayer.get_unique_id()
		_process_ability_use_request(player_id, ability_type, position)
	else:
		# Send request to server
		var pos_dict := {"x": position.x, "y": position.y, "z": position.z}
		_request_ability_use.rpc_id(1, ability_type, pos_dict)


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


# --- Emergency Vote API ---


## Calls an emergency vote to identify a Cultist.
## Can only be called during INVESTIGATION state.
## Costs 30 seconds of investigation time.
## Returns true if vote was successfully called.
func call_emergency_vote(caller_id: int) -> bool:
	if not _is_server:
		# Send request to server
		_request_emergency_vote.rpc_id(1, caller_id)
		return true  # Request sent, result will come via signal

	return _process_emergency_vote(caller_id)


## Processes an emergency vote request (server-only).
func _process_emergency_vote(caller_id: int) -> bool:
	# Check if in INVESTIGATION state
	var game_state := _get_game_state()
	const INVESTIGATION := 3  # GameManager.GameState.INVESTIGATION
	if game_state != INVESTIGATION:
		emergency_vote_rejected.emit("Can only call vote during investigation")
		print("[CultistManager] Emergency vote rejected: not in INVESTIGATION state")
		return false

	# Check vote limit
	if _emergency_votes_used >= MAX_EMERGENCY_VOTES:
		emergency_vote_rejected.emit("Maximum votes (%d) already used" % MAX_EMERGENCY_VOTES)
		print("[CultistManager] Emergency vote rejected: limit reached")
		return false

	# Consume the vote
	_emergency_votes_used += 1

	# Deduct time from investigation timer
	_deduct_investigation_time(EMERGENCY_VOTE_TIME_COST)

	# Emit signal to trigger vote UI
	emergency_vote_called.emit(caller_id)

	# Notify all clients
	_notify_emergency_vote.rpc(caller_id)

	print(
		"[CultistManager] Emergency vote called by player %d (vote %d/%d)"
		% [caller_id, _emergency_votes_used, MAX_EMERGENCY_VOTES]
	)

	return true


## Returns the number of emergency votes used this match.
func get_emergency_votes_used() -> int:
	return _emergency_votes_used


## Returns the number of emergency votes remaining.
func get_emergency_votes_remaining() -> int:
	return MAX_EMERGENCY_VOTES - _emergency_votes_used


## Returns true if an emergency vote can be called.
func can_call_emergency_vote() -> bool:
	if _emergency_votes_used >= MAX_EMERGENCY_VOTES:
		return false

	var game_state := _get_game_state()
	const INVESTIGATION := 3
	return game_state == INVESTIGATION


func _get_game_state() -> int:
	if has_node("/root/GameManager"):
		var game_manager := get_node("/root/GameManager")
		if game_manager.has_method("get_current_state"):
			return game_manager.get_current_state()
		if "current_state" in game_manager:
			return game_manager.current_state
	return -1


func _deduct_investigation_time(seconds: float) -> void:
	if has_node("/root/GameManager"):
		var game_manager := get_node("/root/GameManager")
		if game_manager.has_method("deduct_time"):
			game_manager.deduct_time(seconds)
		elif "remaining_time" in game_manager:
			game_manager.remaining_time = maxf(0.0, game_manager.remaining_time - seconds)
			print("[CultistManager] Deducted %.0f seconds from investigation time" % seconds)


# --- Vote Tracking API ---


## Starts the voting period. Called when emergency vote is triggered.
## alive_player_ids: List of players who can vote and be voted on.
func start_voting(alive_player_ids: Array[int]) -> void:
	if not _is_server:
		push_warning("[CultistManager] Only server can start voting")
		return

	if _voting_in_progress:
		push_warning("[CultistManager] Voting already in progress")
		return

	_voting_in_progress = true
	_current_votes.clear()
	_voting_timer = VOTING_DURATION
	_alive_players = alive_player_ids.duplicate()

	# Notify all clients
	_notify_voting_started.rpc(alive_player_ids, VOTING_DURATION)

	print("[CultistManager] Voting started: %d players, %.0fs timer" % [
		alive_player_ids.size(), VOTING_DURATION
	])


## Casts a vote for a target player.
## voter_id: Player casting the vote.
## target_id: Player being voted for (-1 to skip).
func cast_vote(voter_id: int, target_id: int) -> void:
	if not _is_server:
		# Send to server
		_request_cast_vote.rpc_id(1, voter_id, target_id)
		return

	_process_vote(voter_id, target_id)


func _process_vote(voter_id: int, target_id: int) -> void:
	if not _voting_in_progress:
		push_warning("[CultistManager] No vote in progress")
		return

	if voter_id not in _alive_players:
		push_warning("[CultistManager] Voter %d not in alive players" % voter_id)
		return

	# Valid targets: alive players or -1 (skip)
	if target_id != -1 and target_id not in _alive_players:
		push_warning("[CultistManager] Invalid vote target %d" % target_id)
		return

	# Record or update vote
	_current_votes[voter_id] = target_id

	# Emit signal
	vote_cast.emit(voter_id, target_id)
	_notify_vote_cast.rpc(voter_id, target_id)

	print("[CultistManager] Vote cast: player %d -> target %d" % [voter_id, target_id])

	# Check if all alive players have voted
	if _current_votes.size() >= _alive_players.size():
		_end_voting()


## Returns true if a vote is currently in progress.
func is_voting_in_progress() -> bool:
	return _voting_in_progress


## Returns the current votes (voter_id -> target_id).
func get_current_votes() -> Dictionary:
	return _current_votes.duplicate()


## Returns the voting time remaining.
func get_voting_time_remaining() -> float:
	return _voting_timer


## Ends the voting period and calculates the result.
func _end_voting() -> void:
	if not _voting_in_progress:
		return

	_voting_in_progress = false
	_voting_timer = 0.0

	# Count votes for each target
	var vote_counts: Dictionary = {}
	for voter_id in _current_votes:
		var target_id: int = _current_votes[voter_id]
		if target_id == -1:
			continue  # Skip votes don't count
		if target_id not in vote_counts:
			vote_counts[target_id] = 0
		vote_counts[target_id] += 1

	# Find the target with most votes
	var majority_threshold := _alive_players.size() / 2.0  # More than 50%
	var top_target: int = -1
	var top_count: int = 0
	var is_tie := false

	for target_id in vote_counts:
		var count: int = vote_counts[target_id]
		if count > top_count:
			top_count = count
			top_target = target_id
			is_tie = false
		elif count == top_count:
			is_tie = true

	# Determine if majority was reached
	var is_majority := top_count > majority_threshold and not is_tie

	# Emit result
	vote_complete.emit(top_target if is_majority else -1, is_majority)
	_notify_vote_complete.rpc(top_target if is_majority else -1, is_majority)

	print("[CultistManager] Voting ended: target=%d, majority=%s (votes=%d, threshold=%.1f)" % [
		top_target if is_majority else -1, is_majority, top_count, majority_threshold
	])

	# Process the vote result if majority was reached
	if is_majority:
		_process_vote_result(top_target)


# --- Vote Result Processing ---


## Processes the result of a successful vote.
## Called when majority votes a player out.
func _process_vote_result(target_id: int) -> void:
	if not _is_server:
		return

	if is_cultist(target_id):
		# Correct vote - Cultist discovered!
		_discover_cultist(target_id)
	else:
		# Wrong vote - innocent voted out
		_innocent_voted(target_id)


## Marks a Cultist as discovered.
## Called when players correctly vote out a Cultist.
func _discover_cultist(player_id: int) -> void:
	if player_id in _discovered_cultists:
		return  # Already discovered

	_discovered_cultists.append(player_id)

	# Emit signals
	cultist_discovered.emit(player_id)
	cultist_voted_discovered.emit(player_id)

	# Notify all clients
	_notify_cultist_discovered.rpc(player_id)

	# Award bonus win condition progress to investigators
	_award_discovery_bonus()

	print("[CultistManager] Cultist %d discovered! Match continues." % player_id)


## Handles an innocent player being voted out.
## Results in immediate Cultist victory.
func _innocent_voted(player_id: int) -> void:
	# Emit signal
	innocent_voted_out.emit(player_id)

	# Notify all clients
	_notify_innocent_voted.rpc(player_id)

	# Trigger Cultist win via MatchManager
	_trigger_cultist_win_innocent_voted()

	print("[CultistManager] Innocent player %d voted out! Cultist wins." % player_id)


## Awards bonus win progress to investigators for correct discovery.
func _award_discovery_bonus() -> void:
	if has_node("/root/MatchManager"):
		var match_manager := get_node("/root/MatchManager")
		if match_manager.has_method("add_investigator_progress"):
			# Award 25% bonus progress for correct identification
			match_manager.add_investigator_progress(0.25)
		elif "investigator_progress" in match_manager:
			match_manager.investigator_progress = minf(
				1.0, match_manager.investigator_progress + 0.25
			)


## Triggers Cultist victory due to innocent being voted out.
func _trigger_cultist_win_innocent_voted() -> void:
	if has_node("/root/MatchManager"):
		var match_manager := get_node("/root/MatchManager")
		if match_manager.has_method("trigger_cultist_win"):
			match_manager.trigger_cultist_win("INNOCENT_VOTED_OUT")


## Returns true if the given Cultist has been discovered.
func is_cultist_discovered(player_id: int) -> bool:
	return player_id in _discovered_cultists


## Returns the discovery state for a player.
## Returns HIDDEN for non-Cultists, DISCOVERED for discovered Cultists.
func get_discovery_state(player_id: int) -> int:
	const DiscoveryState := CultistEnums.DiscoveryState
	if not is_cultist(player_id):
		return DiscoveryState.HIDDEN
	if player_id in _discovered_cultists:
		return DiscoveryState.DISCOVERED
	return DiscoveryState.HIDDEN


## Returns true if the Cultist can use abilities.
## Discovered Cultists cannot use abilities.
func can_cultist_use_abilities(player_id: int) -> bool:
	if not is_cultist(player_id):
		return false
	return not is_cultist_discovered(player_id)


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


## Receives ability charge update from server.
@rpc("authority", "call_remote", "reliable")
func _receive_ability_charges(ability_type: int, current: int, maximum: int) -> void:
	# Update local tracking for UI
	ability_charges_changed.emit(
		multiplayer.get_unique_id(), ability_type, current, maximum
	)
	print("[CultistManager] Received charge update: ability=%d, charges=%d/%d" % [
		ability_type, current, maximum
	])


## Client request to use an ability.
@rpc("any_peer", "call_remote", "reliable")
func _request_ability_use(ability_type: int, position_dict: Dictionary) -> void:
	if not _is_server:
		return

	var caller_id := multiplayer.get_remote_sender_id()
	var position := Vector3(
		position_dict.get("x", 0.0),
		position_dict.get("y", 0.0),
		position_dict.get("z", 0.0)
	)
	_process_ability_use_request(caller_id, ability_type, position)


## Server processes ability use request.
func _process_ability_use_request(player_id: int, ability_type: int, position: Vector3) -> void:
	if not _is_server:
		return

	# Validate player is a Cultist
	if not is_cultist(player_id):
		_notify_ability_denied.rpc_id(player_id, ability_type, "Not a Cultist")
		return

	# Check if discovered
	if is_cultist_discovered(player_id):
		_notify_ability_denied.rpc_id(player_id, ability_type, "Cultist discovered")
		return

	# Check charges
	var charges := get_ability_charges(player_id, ability_type)
	if charges <= 0:
		_notify_ability_denied.rpc_id(player_id, ability_type, "No charges remaining")
		return

	# Consume charge and approve
	consume_ability_charge(player_id, ability_type)

	# Notify client that ability is approved
	if player_id == multiplayer.get_unique_id():
		_receive_ability_approved(ability_type, position)
	else:
		var pos_dict := {"x": position.x, "y": position.y, "z": position.z}
		_notify_ability_approved.rpc_id(player_id, ability_type, pos_dict)

	# Log the ability use
	log_ability_use(player_id, ability_type, position)


## Server notifies client that ability was approved.
@rpc("authority", "call_remote", "reliable")
func _notify_ability_approved(ability_type: int, position_dict: Dictionary) -> void:
	var position := Vector3(
		position_dict.get("x", 0.0),
		position_dict.get("y", 0.0),
		position_dict.get("z", 0.0)
	)
	_receive_ability_approved(ability_type, position)


## Local handler for approved ability use.
func _receive_ability_approved(ability_type: int, position: Vector3) -> void:
	# Emit signal for ability execution
	if EventBus:
		EventBus.cultist_ability_used.emit(_get_ability_name(ability_type))

	print("[CultistManager] Ability %d approved at %v" % [ability_type, position])


## Server notifies client that ability was denied.
@rpc("authority", "call_remote", "reliable")
func _notify_ability_denied(ability_type: int, reason: String) -> void:
	push_warning("[CultistManager] Ability %d denied: %s" % [ability_type, reason])


## Client request to call emergency vote.
@rpc("any_peer", "call_remote", "reliable")
func _request_emergency_vote(caller_id: int) -> void:
	if not _is_server:
		return
	_process_emergency_vote(caller_id)


## Server notifies all clients of emergency vote.
@rpc("authority", "call_local", "reliable")
func _notify_emergency_vote(caller_id: int) -> void:
	emergency_vote_called.emit(caller_id)


## Client request to cast vote.
@rpc("any_peer", "call_remote", "reliable")
func _request_cast_vote(voter_id: int, target_id: int) -> void:
	if not _is_server:
		return
	_process_vote(voter_id, target_id)


## Server notifies clients that voting has started.
@rpc("authority", "call_local", "reliable")
func _notify_voting_started(alive_player_ids: Array, duration: float) -> void:
	_voting_in_progress = true
	_alive_players.clear()
	for pid in alive_player_ids:
		_alive_players.append(int(pid))
	_voting_timer = duration
	_current_votes.clear()


## Server notifies clients of a vote cast.
@rpc("authority", "call_local", "reliable")
func _notify_vote_cast(voter_id: int, target_id: int) -> void:
	_current_votes[voter_id] = target_id
	vote_cast.emit(voter_id, target_id)


## Server notifies clients of voting timer.
@rpc("authority", "call_local", "reliable")
func _notify_vote_timer(seconds_remaining: float) -> void:
	_voting_timer = seconds_remaining
	vote_timer_updated.emit(seconds_remaining)


## Server notifies clients of vote completion.
@rpc("authority", "call_local", "reliable")
func _notify_vote_complete(target_id: int, is_majority: bool) -> void:
	_voting_in_progress = false
	vote_complete.emit(target_id, is_majority)


## Server notifies clients that a Cultist was discovered.
@rpc("authority", "call_local", "reliable")
func _notify_cultist_discovered(player_id: int) -> void:
	if player_id not in _discovered_cultists:
		_discovered_cultists.append(player_id)
	cultist_discovered.emit(player_id)
	cultist_voted_discovered.emit(player_id)


## Server notifies clients that an innocent was voted out.
@rpc("authority", "call_local", "reliable")
func _notify_innocent_voted(player_id: int) -> void:
	innocent_voted_out.emit(player_id)


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

	# Initialize ability charges for each Cultist on server
	for cultist_id in _cultist_ids:
		_init_player_charges(cultist_id)

	for player_id in role_map.keys():
		var role: int = role_map[player_id]

		# Send role to this player
		if player_id == multiplayer.get_unique_id():
			# Local server player
			_receive_role(role)
			if role == 1:  # CULTIST
				var allies := cultist_list.filter(func(id): return id != player_id)
				_receive_cultist_data(_entity_type, _entity_evidence, allies)
				# Send initial charges
				send_initial_charges_to_cultist(player_id)
		else:
			# Remote player
			_receive_role.rpc_id(player_id, role)
			if role == 1:  # CULTIST
				var allies := cultist_list.filter(func(id): return id != player_id)
				_receive_cultist_data.rpc_id(player_id, _entity_type, _entity_evidence, allies)
				# Send initial charges after small delay to ensure role is received first
				send_initial_charges_to_cultist(player_id)


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
