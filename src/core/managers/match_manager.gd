extends Node
## Central manager for match resolution and win condition logic.
## Autoload: MatchManager
##
## Responsible for tracking the true match state (which entity is present,
## who the Cultist is) and determining when win/loss conditions are met.
##
## Win conditions:
## - Investigators win: Correct entity identification
## - Cultist wins: Incorrect identification, time expires, or innocent voted out
##
## Note: No class_name to avoid conflicts with autoload singleton name.

# --- Signals ---

## Emitted when the match ends with a result.
signal match_ended(result: MatchResult)

# --- Match State ---

## The actual entity type present in this match.
var _actual_entity_type: String = ""

## The peer ID of the Cultist.
var _cultist_id: int = -1

## The username of the Cultist.
var _cultist_username: String = ""

## When the match started (for duration tracking).
var _match_start_time: float = 0.0

## Whether a match is currently active.
var _match_active: bool = false

## The result of the match, if ended.
var _match_result: MatchResult = null


func _ready() -> void:
	_connect_to_signals()
	print("[MatchManager] Initialized - Win condition checking ready")


func _connect_to_signals() -> void:
	var event_bus := _get_event_bus()
	if event_bus:
		if event_bus.has_signal("phase_timer_expired"):
			event_bus.phase_timer_expired.connect(_on_phase_timer_expired)

	var evidence_manager := _get_evidence_manager()
	if evidence_manager:
		if evidence_manager.has_signal("identification_approved"):
			evidence_manager.identification_approved.connect(_on_identification_approved)


func _get_event_bus() -> Node:
	if has_node("/root/EventBus"):
		return get_node("/root/EventBus")
	return null


func _get_evidence_manager() -> Node:
	if has_node("/root/EvidenceManager"):
		return get_node("/root/EvidenceManager")
	return null


func _get_game_manager() -> Node:
	if has_node("/root/GameManager"):
		return get_node("/root/GameManager")
	return null


# --- Public API: Match Setup ---


## Initializes a new match with the specified entity and cultist.
## Called by the server when the game starts.
func initialize_match(entity_type: String, cultist_id: int, cultist_username: String) -> void:
	_actual_entity_type = entity_type
	_cultist_id = cultist_id
	_cultist_username = cultist_username
	_match_start_time = Time.get_ticks_msec() / 1000.0
	_match_active = true
	_match_result = null

	print(
		"[MatchManager] Match initialized - Entity: %s, Cultist: %s (ID: %d)"
		% [entity_type, cultist_username, cultist_id]
	)


## Ends the current match and clears state.
func end_match() -> void:
	_match_active = false
	print("[MatchManager] Match ended")


## Resets all match state for a new game.
func reset() -> void:
	_actual_entity_type = ""
	_cultist_id = -1
	_cultist_username = ""
	_match_start_time = 0.0
	_match_active = false
	_match_result = null
	print("[MatchManager] Match state reset")


# --- Public API: Match State Queries ---


## Returns true if a match is currently active.
func is_match_active() -> bool:
	return _match_active


## Returns the actual entity type for this match.
func get_actual_entity_type() -> String:
	return _actual_entity_type


## Returns the Cultist's peer ID.
func get_cultist_id() -> int:
	return _cultist_id


## Returns the Cultist's username.
func get_cultist_username() -> String:
	return _cultist_username


## Returns the match duration so far in seconds.
func get_match_duration() -> float:
	if not _match_active:
		return 0.0
	return (Time.get_ticks_msec() / 1000.0) - _match_start_time


## Returns the last match result, or null if no result yet.
func get_match_result() -> MatchResult:
	return _match_result


# --- Public API: Win Condition Checking ---


## Checks the win condition based on the submitted entity identification.
## Returns the resulting MatchResult.
func check_win_condition(submitted_entity: String) -> MatchResult:
	if not _match_active:
		push_warning("[MatchManager] check_win_condition called without active match")
		return null

	var result := MatchResult.new()
	result.entity_type = _actual_entity_type
	result.cultist_id = _cultist_id
	result.cultist_username = _cultist_username
	result.match_duration = get_match_duration()

	if submitted_entity == _actual_entity_type:
		# Correct identification - Investigators win
		result.winning_team = MatchResult.WinningTeam.INVESTIGATORS
		result.win_condition = MatchResult.WinCondition.CORRECT_IDENTIFICATION
		print("[MatchManager] WIN: Investigators - Correct identification!")
	else:
		# Incorrect identification - Cultist wins
		result.winning_team = MatchResult.WinningTeam.CULTIST
		result.win_condition = MatchResult.WinCondition.INCORRECT_IDENTIFICATION
		print(
			"[MatchManager] WIN: Cultist - Incorrect identification (guessed %s, was %s)"
			% [submitted_entity, _actual_entity_type]
		)

	_match_result = result
	return result


## Triggers a Cultist win due to time expiration.
## Called when the deliberation timer runs out.
func trigger_time_expired_loss() -> MatchResult:
	if not _match_active:
		push_warning("[MatchManager] trigger_time_expired_loss called without active match")
		return null

	var result := MatchResult.new()
	result.entity_type = _actual_entity_type
	result.cultist_id = _cultist_id
	result.cultist_username = _cultist_username
	result.match_duration = get_match_duration()
	result.winning_team = MatchResult.WinningTeam.CULTIST
	result.win_condition = MatchResult.WinCondition.TIME_EXPIRED

	print("[MatchManager] WIN: Cultist - Time expired!")

	_match_result = result
	return result


## Resolves the match with the given result.
## Emits match_ended signal and triggers state transition to RESULTS.
func resolve_match(result: MatchResult) -> void:
	if not result:
		push_error("[MatchManager] resolve_match called with null result")
		return

	_match_result = result
	_match_active = false

	match_ended.emit(result)
	_broadcast_match_result(result)

	# Emit to EventBus for other systems
	var event_bus := _get_event_bus()
	if event_bus and event_bus.has_signal("match_ended"):
		event_bus.match_ended.emit(result.to_dict())

	# Transition to RESULTS state
	var game_manager := _get_game_manager()
	if game_manager and game_manager.has_method("change_state"):
		# GameState.RESULTS = 6
		game_manager.change_state(6)

	print("[MatchManager] Match resolved - %s wins!" % (
		"Investigators" if result.did_investigators_win() else "Cultist"
	))


# --- Signal Handlers ---


func _on_identification_approved(entity_type: String) -> void:
	if not _match_active:
		return

	print("[MatchManager] Identification approved: %s" % entity_type)

	var result := check_win_condition(entity_type)
	if result:
		resolve_match(result)


func _on_phase_timer_expired(state: int) -> void:
	if not _match_active:
		return

	# Check if this is DELIBERATION (state = 5)
	const DELIBERATION := 5
	if state != DELIBERATION:
		return

	print("[MatchManager] Deliberation timer expired")

	# Check if there's a pending identification to auto-approve
	var evidence_manager := _get_evidence_manager()
	if evidence_manager and evidence_manager.has_method("has_pending_identification"):
		if evidence_manager.has_pending_identification():
			# Auto-approve the pending identification
			var pending: Dictionary = evidence_manager.get_pending_identification()
			var entity_type: String = pending.get("entity_type", "")
			if not entity_type.is_empty():
				print("[MatchManager] Auto-approving pending identification: %s" % entity_type)
				var result := check_win_condition(entity_type)
				if result:
					resolve_match(result)
				return

	# No pending identification - Cultist wins by timeout
	var result := trigger_time_expired_loss()
	if result:
		resolve_match(result)


# --- Networking ---


func _is_server() -> bool:
	if not multiplayer:
		return true
	if not multiplayer.has_multiplayer_peer():
		return true
	return multiplayer.is_server()


func _broadcast_match_result(result: MatchResult) -> void:
	if not multiplayer or not multiplayer.has_multiplayer_peer():
		return

	if not _is_server():
		return

	_rpc_match_result.rpc(result.to_dict())


@rpc("authority", "call_remote", "reliable")
func _rpc_match_result(data: Dictionary) -> void:
	if _is_server():
		return

	_match_result = MatchResult.from_dict(data)
	_match_active = false
	match_ended.emit(_match_result)

	print(
		"[MatchManager] Received match result - %s wins!"
		% ("Investigators" if _match_result.did_investigators_win() else "Cultist")
	)
