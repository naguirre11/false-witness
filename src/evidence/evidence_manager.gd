extends Node
## Server-authoritative evidence collection and tracking manager.
## Autoload: EvidenceManager
##
## Manages all collected evidence during investigation. Evidence collection
## is server-authoritative to prevent cheating and ensure consistency.
##
## The evidence system supports social deduction through trust levels:
## - UNFALSIFIABLE evidence (hunt behavior) cannot be disputed
## - HIGH trust evidence has shared displays
## - LOW trust evidence relies on player reports
## - SABOTAGE_RISK evidence can be corrupted before collection
##
## Note: No class_name to avoid conflicts with autoload singleton name.

# --- Signals ---

## Emitted when new evidence is collected (server broadcasts to all).
signal evidence_collected(evidence: Evidence)

## Emitted when evidence verification state changes.
signal evidence_verification_changed(evidence: Evidence)

## Emitted when conflicting evidence reports are received.
signal evidence_contested(evidence: Evidence, contesting_player_id: int)

## Emitted when all evidence is cleared (new round).
signal evidence_cleared

## Emitted when an entity identification is submitted.
signal identification_submitted(entity_type: String, submitter_id: int)

## Emitted when identification voting completes with approval.
signal identification_approved(entity_type: String)

## Emitted when identification voting completes with rejection.
signal identification_rejected(entity_type: String)

## Emitted when entity eliminations change.
signal eliminations_changed(eliminated: Array, remaining: Array)

# --- Constants ---

## All possible entity types (must match EntityMatrix.ALL_ENTITIES).
const ALL_ENTITIES: Array[String] = [
	"Phantom", "Banshee", "Revenant", "Shade",
	"Poltergeist", "Wraith", "Mare", "Demon",
]

## Entity evidence production map (must match EntityMatrix.ENTITY_EVIDENCE_MAP).
const ENTITY_EVIDENCE_MAP: Dictionary = {
	"Phantom": [
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		EvidenceEnums.EvidenceType.FREEZING_TEMPERATURE,
		EvidenceEnums.EvidenceType.VISUAL_MANIFESTATION,
	],
	"Banshee": [
		EvidenceEnums.EvidenceType.PRISM_READING,
		EvidenceEnums.EvidenceType.AURA_PATTERN,
		EvidenceEnums.EvidenceType.HUNT_BEHAVIOR,
	],
	"Revenant": [
		EvidenceEnums.EvidenceType.FREEZING_TEMPERATURE,
		EvidenceEnums.EvidenceType.GHOST_WRITING,
		EvidenceEnums.EvidenceType.HUNT_BEHAVIOR,
	],
	"Shade": [
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		EvidenceEnums.EvidenceType.GHOST_WRITING,
		EvidenceEnums.EvidenceType.VISUAL_MANIFESTATION,
	],
	"Poltergeist": [
		EvidenceEnums.EvidenceType.PHYSICAL_INTERACTION,
		EvidenceEnums.EvidenceType.GHOST_WRITING,
		EvidenceEnums.EvidenceType.AURA_PATTERN,
	],
	"Wraith": [
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		EvidenceEnums.EvidenceType.PRISM_READING,
		EvidenceEnums.EvidenceType.PHYSICAL_INTERACTION,
	],
	"Mare": [
		EvidenceEnums.EvidenceType.FREEZING_TEMPERATURE,
		EvidenceEnums.EvidenceType.PRISM_READING,
		EvidenceEnums.EvidenceType.GHOST_WRITING,
	],
	"Demon": [
		EvidenceEnums.EvidenceType.AURA_PATTERN,
		EvidenceEnums.EvidenceType.PHYSICAL_INTERACTION,
		EvidenceEnums.EvidenceType.HUNT_BEHAVIOR,
	],
}

# --- State ---

## All collected evidence indexed by UID.
var _evidence_by_uid: Dictionary = {}

## Evidence indexed by type for fast queries.
var _evidence_by_type: Dictionary = {}

## Evidence indexed by collector ID for fast queries.
var _evidence_by_collector: Dictionary = {}

## Whether evidence collection is currently allowed.
var _collection_enabled: bool = false

## Pending identification submission (during DELIBERATION).
var _pending_identification: Dictionary = {}  # {entity_type, submitter_id, votes: {}}

## Whether we're in DELIBERATION state (identification allowed).
var _deliberation_active: bool = false

## Number of alive players who can vote. Set externally by game systems.
var _alive_player_count: int = 4

## Entity types that have been eliminated by collected evidence.
var _eliminated_entities: Array[String] = []


func _ready() -> void:
	_connect_to_event_bus()
	_initialize_type_index()
	print("[EvidenceManager] Initialized - Evidence tracking ready")


func _connect_to_event_bus() -> void:
	var event_bus := _get_event_bus()
	if event_bus:
		if event_bus.has_signal("game_state_changed"):
			event_bus.game_state_changed.connect(_on_game_state_changed)


func _initialize_type_index() -> void:
	for evidence_type: int in EvidenceEnums.EvidenceType.values():
		_evidence_by_type[evidence_type] = []


func _get_event_bus() -> Node:
	if has_node("/root/EventBus"):
		return get_node("/root/EventBus")
	return null


func _get_network_manager() -> Node:
	if has_node("/root/NetworkManager"):
		return get_node("/root/NetworkManager")
	return null


func _get_verification_manager() -> Node:
	if has_node("/root/VerificationManager"):
		return get_node("/root/VerificationManager")
	return null


# --- Public API: Collection ---


## Collects evidence from a player. Server-authoritative.
## Returns the created Evidence if successful, null if rejected.
func collect_evidence(
	evidence_type: EvidenceEnums.EvidenceType,
	collector_id: int,
	location: Vector3,
	quality: EvidenceEnums.ReadingQuality = EvidenceEnums.ReadingQuality.STRONG,
	equipment: String = ""
) -> Evidence:
	if not _collection_enabled:
		push_warning("[EvidenceManager] Collection attempted while disabled")
		return null

	if not _is_server():
		_request_collect_evidence(evidence_type, collector_id, location, quality, equipment)
		return null

	var evidence := Evidence.create(evidence_type, collector_id, location, quality)
	evidence.equipment_used = equipment

	_add_evidence(evidence)
	_broadcast_evidence_collected(evidence)

	return evidence


## Collects cooperative evidence requiring two players.
func collect_cooperative_evidence(
	evidence_type: EvidenceEnums.EvidenceType,
	primary_collector: int,
	secondary_collector: int,
	location: Vector3,
	quality: EvidenceEnums.ReadingQuality = EvidenceEnums.ReadingQuality.STRONG,
	equipment: String = ""
) -> Evidence:
	if not _collection_enabled:
		push_warning("[EvidenceManager] Collection attempted while disabled")
		return null

	if not EvidenceEnums.is_cooperative(evidence_type):
		push_warning("[EvidenceManager] Non-cooperative evidence type used with cooperative collection")
		return collect_evidence(evidence_type, primary_collector, location, quality, equipment)

	if not _is_server():
		_request_collect_cooperative_evidence(
			evidence_type, primary_collector, secondary_collector, location, quality, equipment
		)
		return null

	var evidence := Evidence.create_cooperative(
		evidence_type, primary_collector, secondary_collector, location, quality
	)
	evidence.equipment_used = equipment

	_add_evidence(evidence)
	_broadcast_evidence_collected(evidence)

	return evidence


## Verifies evidence by UID. Called when another player corroborates.
## Uses VerificationManager to validate against trust-level rules.
func verify_evidence(uid: String, verifier_id: int) -> bool:
	if not _is_server():
		_request_verify_evidence(uid, verifier_id)
		return false

	var evidence: Evidence = _evidence_by_uid.get(uid)
	if evidence == null:
		return false

	# Use VerificationManager for trust-level validation
	var verification_manager := _get_verification_manager()
	if verification_manager:
		var result: Dictionary = verification_manager.try_verify(evidence, verifier_id)
		if not result.get("success", false):
			return false

	# Perform the actual verification with timestamp tracking
	evidence.verify()
	evidence.record_verification(verifier_id)
	evidence_verification_changed.emit(evidence)
	_broadcast_verification_changed(evidence)
	_emit_verification_to_event_bus(evidence)

	return true


## Contests evidence by UID. Called when a player disputes a report.
## Uses VerificationManager to validate (UNFALSIFIABLE cannot be contested).
func contest_evidence(uid: String, contester_id: int) -> bool:
	if not _is_server():
		_request_contest_evidence(uid, contester_id)
		return false

	var evidence: Evidence = _evidence_by_uid.get(uid)
	if evidence == null:
		return false

	# Use VerificationManager for trust-level validation
	var verification_manager := _get_verification_manager()
	if verification_manager:
		var result: Dictionary = verification_manager.try_contest(evidence, contester_id)
		if not result.get("success", false):
			return false

	evidence.contest()
	evidence_verification_changed.emit(evidence)
	evidence_contested.emit(evidence, contester_id)
	_broadcast_verification_changed(evidence)
	_emit_verification_to_event_bus(evidence)
	_emit_contested_to_event_bus(evidence, contester_id)

	# Recalculate eliminations - contested evidence doesn't eliminate
	recalculate_eliminations()

	return true


func _emit_verification_to_event_bus(evidence: Evidence) -> void:
	var event_bus := _get_event_bus()
	if event_bus and event_bus.has_signal("evidence_verification_changed"):
		event_bus.evidence_verification_changed.emit(evidence.uid, evidence.verification_state)


func _emit_contested_to_event_bus(evidence: Evidence, contester_id: int) -> void:
	var event_bus := _get_event_bus()
	if event_bus and event_bus.has_signal("evidence_contested"):
		event_bus.evidence_contested.emit(evidence.uid, contester_id)


# --- Public API: Elimination ---


## Returns the list of eliminated entity types.
func get_eliminated_entities() -> Array[String]:
	return _eliminated_entities.duplicate()


## Returns the list of remaining (non-eliminated) entity types.
func get_remaining_entities() -> Array[String]:
	var remaining: Array[String] = []
	for entity_type in ALL_ENTITIES:
		if entity_type not in _eliminated_entities:
			remaining.append(entity_type)
	return remaining


## Recalculates entity eliminations based on collected evidence.
## Called automatically when evidence is collected or contested.
func recalculate_eliminations() -> void:
	var old_eliminated := _eliminated_entities.duplicate()
	_eliminated_entities.clear()

	# Get all collected evidence types (not contested)
	var collected_types: Array[int] = []
	for evidence: Evidence in _evidence_by_uid.values():
		# Skip contested evidence - it doesn't eliminate
		if evidence.is_contested():
			continue
		if evidence.type not in collected_types:
			collected_types.append(evidence.type)

	# An entity is eliminated if it CANNOT produce any of the collected evidence
	for entity_type in ALL_ENTITIES:
		var entity_evidence: Array = ENTITY_EVIDENCE_MAP.get(entity_type, [])
		var is_eliminated := false

		for collected_type in collected_types:
			if collected_type not in entity_evidence:
				is_eliminated = true
				break

		if is_eliminated:
			_eliminated_entities.append(entity_type)

	# Only emit if eliminations changed
	if _eliminated_entities != old_eliminated:
		var remaining := get_remaining_entities()
		eliminations_changed.emit(_eliminated_entities.duplicate(), remaining)


## Checks if an entity type has been eliminated.
func is_entity_eliminated(entity_type: String) -> bool:
	return entity_type in _eliminated_entities


## Checks if evidence type can be produced by an entity.
static func entity_produces_evidence(
	entity_type: String, evidence_type: EvidenceEnums.EvidenceType
) -> bool:
	var entity_evidence: Array = ENTITY_EVIDENCE_MAP.get(entity_type, [])
	return evidence_type in entity_evidence


# --- Public API: Identification ---


## Submits an entity identification during deliberation phase.
## Only valid during DELIBERATION state. Server-authoritative.
## Returns true if submission was accepted.
func submit_identification(entity_type: String, submitter_id: int) -> bool:
	if not _deliberation_active:
		push_warning("[EvidenceManager] Identification attempted outside DELIBERATION")
		return false

	if entity_type.is_empty():
		push_warning("[EvidenceManager] Empty entity type submitted")
		return false

	if not _is_server():
		_request_submit_identification(entity_type, submitter_id)
		return true  # Optimistic - actual result comes from server

	# Clear any previous pending identification
	_pending_identification = {
		"entity_type": entity_type,
		"submitter_id": submitter_id,
		"votes": {},  # player_id -> bool (approve/reject)
	}

	print(
		"[EvidenceManager] Identification submitted: %s by player %d"
		% [entity_type, submitter_id]
	)

	identification_submitted.emit(entity_type, submitter_id)
	_broadcast_identification_submitted(entity_type, submitter_id)

	return true


## Returns the current pending identification, or empty dict if none.
func get_pending_identification() -> Dictionary:
	return _pending_identification.duplicate()


## Returns true if there's a pending identification.
func has_pending_identification() -> bool:
	return not _pending_identification.is_empty()


## Clears any pending identification. Called when moving to RESULTS or new round.
func clear_pending_identification() -> void:
	_pending_identification.clear()


## Enables deliberation mode. Called when entering DELIBERATION state.
func enable_deliberation() -> void:
	_deliberation_active = true
	print("[EvidenceManager] Deliberation mode enabled")


## Disables deliberation mode. Called when leaving DELIBERATION state.
func disable_deliberation() -> void:
	_deliberation_active = false
	clear_pending_identification()
	print("[EvidenceManager] Deliberation mode disabled")


## Returns true if deliberation is active.
func is_deliberation_active() -> bool:
	return _deliberation_active


# --- Public API: Voting ---


## Casts a vote on the current identification proposal.
## Only valid during DELIBERATION with a pending identification. Server-authoritative.
## Returns true if the vote was accepted.
func vote_for_identification(voter_id: int, approve: bool) -> bool:
	if not _deliberation_active:
		push_warning("[EvidenceManager] Vote attempted outside DELIBERATION")
		return false

	if _pending_identification.is_empty():
		push_warning("[EvidenceManager] No pending identification to vote on")
		return false

	if not _is_server():
		_request_vote_identification(voter_id, approve)
		return true  # Optimistic - actual result comes from server

	# Record vote
	var votes: Dictionary = _pending_identification.get("votes", {})
	votes[voter_id] = approve
	_pending_identification["votes"] = votes

	print(
		"[EvidenceManager] Vote recorded: player %d voted %s"
		% [voter_id, "approve" if approve else "reject"]
	)

	_broadcast_vote_cast(voter_id, approve)

	# Check if majority reached
	_check_vote_result()

	return true


## Sets the number of alive players for majority calculation.
func set_alive_player_count(player_count: int) -> void:
	_alive_player_count = maxi(1, player_count)


## Returns the current alive player count.
func get_alive_player_count() -> int:
	return _alive_player_count


## Returns the number of votes needed for majority.
func get_majority_threshold() -> int:
	# Majority = more than 50%, so (count / 2) + 1 for even, ceil for odd
	return (_alive_player_count / 2) + 1


## Returns the current vote counts: {approve: int, reject: int}.
func get_vote_counts() -> Dictionary:
	if _pending_identification.is_empty():
		return {"approve": 0, "reject": 0}

	var votes: Dictionary = _pending_identification.get("votes", {})
	var approve_count: int = 0
	var reject_count: int = 0

	for vote_value: bool in votes.values():
		if vote_value:
			approve_count += 1
		else:
			reject_count += 1

	return {"approve": approve_count, "reject": reject_count}


## Checks if voting has concluded and emits appropriate signal.
func _check_vote_result() -> void:
	if _pending_identification.is_empty():
		return

	var counts := get_vote_counts()
	var threshold := get_majority_threshold()
	var entity_type: String = _pending_identification.get("entity_type", "")

	if counts["approve"] >= threshold:
		print(
			"[EvidenceManager] Identification APPROVED: %s (%d/%d votes)"
			% [entity_type, counts["approve"], threshold]
		)
		identification_approved.emit(entity_type)
		_broadcast_identification_result(entity_type, true)
	elif counts["reject"] >= threshold:
		print(
			"[EvidenceManager] Identification REJECTED: %s (%d/%d votes)"
			% [entity_type, counts["reject"], threshold]
		)
		identification_rejected.emit(entity_type)
		_broadcast_identification_result(entity_type, false)
		# Clear pending so another proposal can be made
		_pending_identification.clear()


# --- Public API: Queries ---


## Returns all collected evidence.
func get_all_evidence() -> Array[Evidence]:
	var result: Array[Evidence] = []
	for evidence: Evidence in _evidence_by_uid.values():
		result.append(evidence)
	return result


## Returns evidence of a specific type.
func get_evidence_by_type(evidence_type: EvidenceEnums.EvidenceType) -> Array[Evidence]:
	var result: Array[Evidence] = []
	var evidence_list: Array = _evidence_by_type.get(evidence_type, [])
	for evidence: Evidence in evidence_list:
		result.append(evidence)
	return result


## Returns all evidence collected by a specific player.
func get_evidence_by_collector(collector_id: int) -> Array[Evidence]:
	var result: Array[Evidence] = []
	var evidence_list: Array = _evidence_by_collector.get(collector_id, [])
	for evidence: Evidence in evidence_list:
		result.append(evidence)
	return result


## Returns evidence by its UID.
func get_evidence_by_uid(uid: String) -> Evidence:
	return _evidence_by_uid.get(uid)


## Returns all verified evidence.
func get_verified_evidence() -> Array[Evidence]:
	var result: Array[Evidence] = []
	for evidence: Evidence in _evidence_by_uid.values():
		if evidence.is_verified():
			result.append(evidence)
	return result


## Returns all contested evidence.
func get_contested_evidence() -> Array[Evidence]:
	var result: Array[Evidence] = []
	for evidence: Evidence in _evidence_by_uid.values():
		if evidence.is_contested():
			result.append(evidence)
	return result


## Returns all strong/definitive evidence.
func get_definitive_evidence() -> Array[Evidence]:
	var result: Array[Evidence] = []
	for evidence: Evidence in _evidence_by_uid.values():
		if evidence.is_definitive():
			result.append(evidence)
	return result


## Returns true if evidence of this type has been collected.
func has_evidence_type(evidence_type: EvidenceEnums.EvidenceType) -> bool:
	return not _evidence_by_type.get(evidence_type, []).is_empty()


## Returns the count of collected evidence.
func get_evidence_count() -> int:
	return _evidence_by_uid.size()


## Returns true if collection is currently enabled.
func is_collection_enabled() -> bool:
	return _collection_enabled


# --- Public API: Management ---


## Enables evidence collection. Called when investigation starts.
func enable_collection() -> void:
	_collection_enabled = true
	print("[EvidenceManager] Evidence collection enabled")


## Disables evidence collection. Called when investigation ends.
func disable_collection() -> void:
	_collection_enabled = false
	print("[EvidenceManager] Evidence collection disabled")


## Clears all collected evidence. Called at round start.
func clear_evidence() -> void:
	_evidence_by_uid.clear()
	_initialize_type_index()
	_evidence_by_collector.clear()
	_eliminated_entities.clear()
	evidence_cleared.emit()
	eliminations_changed.emit([], ALL_ENTITIES.duplicate())
	print("[EvidenceManager] All evidence cleared")


## Syncs evidence state to a late-joining player.
func sync_to_player(peer_id: int) -> void:
	if not _is_server():
		return

	var all_data: Array[Dictionary] = []
	for evidence: Evidence in _evidence_by_uid.values():
		all_data.append(evidence.to_network_dict())

	_rpc_sync_all_evidence.rpc_id(peer_id, all_data)


# --- Internal: Evidence Management ---


func _add_evidence(evidence: Evidence) -> void:
	_evidence_by_uid[evidence.uid] = evidence

	if not _evidence_by_type.has(evidence.type):
		_evidence_by_type[evidence.type] = []
	_evidence_by_type[evidence.type].append(evidence)

	if not _evidence_by_collector.has(evidence.collector_id):
		_evidence_by_collector[evidence.collector_id] = []
	_evidence_by_collector[evidence.collector_id].append(evidence)

	evidence_collected.emit(evidence)

	# Recalculate entity eliminations when evidence is collected
	recalculate_eliminations()

	var event_bus := _get_event_bus()
	if event_bus:
		if event_bus.has_signal("evidence_recorded"):
			var type_name := EvidenceEnums.get_evidence_name(evidence.type)
			event_bus.evidence_recorded.emit(type_name, evidence.equipment_used)
		if event_bus.has_signal("evidence_collected"):
			event_bus.evidence_collected.emit(evidence.uid, evidence.to_network_dict())


func _remove_evidence(uid: String) -> void:
	var evidence: Evidence = _evidence_by_uid.get(uid)
	if evidence == null:
		return

	_evidence_by_uid.erase(uid)

	var type_list: Array = _evidence_by_type.get(evidence.type, [])
	type_list.erase(evidence)

	var collector_list: Array = _evidence_by_collector.get(evidence.collector_id, [])
	collector_list.erase(evidence)


# --- Internal: Game State ---


func _on_game_state_changed(old_state: int, new_state: int) -> void:
	const INVESTIGATION := 3
	const HUNT := 4
	const LOBBY := 1
	const DELIBERATION := 5

	match new_state:
		INVESTIGATION:
			enable_collection()
		HUNT:
			pass
		DELIBERATION:
			disable_collection()
			enable_deliberation()
		LOBBY:
			clear_evidence()
			disable_collection()
			disable_deliberation()

	if old_state == INVESTIGATION and new_state != HUNT:
		disable_collection()

	if old_state == DELIBERATION and new_state != DELIBERATION:
		disable_deliberation()


# --- Internal: Networking ---


func _is_server() -> bool:
	if not multiplayer:
		return true
	if not multiplayer.has_multiplayer_peer():
		return true
	return multiplayer.is_server()


func _broadcast_evidence_collected(evidence: Evidence) -> void:
	if not multiplayer or not multiplayer.has_multiplayer_peer():
		return

	var data := evidence.to_network_dict()
	_rpc_evidence_collected.rpc(data)


func _broadcast_verification_changed(evidence: Evidence) -> void:
	if not multiplayer or not multiplayer.has_multiplayer_peer():
		return

	_rpc_verification_changed.rpc(evidence.uid, evidence.verification_state)


func _broadcast_identification_submitted(entity_type: String, submitter_id: int) -> void:
	if not multiplayer or not multiplayer.has_multiplayer_peer():
		return

	_rpc_identification_submitted.rpc(entity_type, submitter_id)


func _broadcast_vote_cast(voter_id: int, approve: bool) -> void:
	if not multiplayer or not multiplayer.has_multiplayer_peer():
		return

	_rpc_vote_cast.rpc(voter_id, approve)


func _broadcast_identification_result(entity_type: String, approved: bool) -> void:
	if not multiplayer or not multiplayer.has_multiplayer_peer():
		return

	_rpc_identification_result.rpc(entity_type, approved)


# --- RPC: Client Requests ---


func _request_collect_evidence(
	evidence_type: EvidenceEnums.EvidenceType,
	collector_id: int,
	location: Vector3,
	quality: EvidenceEnums.ReadingQuality,
	equipment: String
) -> void:
	if not multiplayer or not multiplayer.has_multiplayer_peer():
		return

	_rpc_request_collect.rpc_id(1, evidence_type, collector_id, location, quality, equipment)


func _request_collect_cooperative_evidence(
	evidence_type: EvidenceEnums.EvidenceType,
	primary_collector: int,
	secondary_collector: int,
	location: Vector3,
	quality: EvidenceEnums.ReadingQuality,
	equipment: String
) -> void:
	if not multiplayer or not multiplayer.has_multiplayer_peer():
		return

	_rpc_request_collect_coop.rpc_id(
		1, evidence_type, primary_collector, secondary_collector, location, quality, equipment
	)


func _request_verify_evidence(uid: String, verifier_id: int) -> void:
	if not multiplayer or not multiplayer.has_multiplayer_peer():
		return

	_rpc_request_verify.rpc_id(1, uid, verifier_id)


func _request_contest_evidence(uid: String, contester_id: int) -> void:
	if not multiplayer or not multiplayer.has_multiplayer_peer():
		return

	_rpc_request_contest.rpc_id(1, uid, contester_id)


func _request_submit_identification(entity_type: String, submitter_id: int) -> void:
	if not multiplayer or not multiplayer.has_multiplayer_peer():
		return

	_rpc_request_identification.rpc_id(1, entity_type, submitter_id)


func _request_vote_identification(voter_id: int, approve: bool) -> void:
	if not multiplayer or not multiplayer.has_multiplayer_peer():
		return

	_rpc_request_vote.rpc_id(1, voter_id, approve)


# --- RPC: Server Handlers ---


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_collect(
	evidence_type: int,
	collector_id: int,
	location: Vector3,
	quality: int,
	equipment: String
) -> void:
	if not _is_server():
		return

	collect_evidence(
		evidence_type as EvidenceEnums.EvidenceType,
		collector_id,
		location,
		quality as EvidenceEnums.ReadingQuality,
		equipment
	)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_collect_coop(
	evidence_type: int,
	primary_collector: int,
	secondary_collector: int,
	location: Vector3,
	quality: int,
	equipment: String
) -> void:
	if not _is_server():
		return

	collect_cooperative_evidence(
		evidence_type as EvidenceEnums.EvidenceType,
		primary_collector,
		secondary_collector,
		location,
		quality as EvidenceEnums.ReadingQuality,
		equipment
	)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_verify(uid: String, verifier_id: int) -> void:
	if not _is_server():
		return

	verify_evidence(uid, verifier_id)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_contest(uid: String, contester_id: int) -> void:
	if not _is_server():
		return

	contest_evidence(uid, contester_id)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_identification(entity_type: String, submitter_id: int) -> void:
	if not _is_server():
		return

	submit_identification(entity_type, submitter_id)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_vote(voter_id: int, approve: bool) -> void:
	if not _is_server():
		return

	vote_for_identification(voter_id, approve)


# --- RPC: Server Broadcasts ---


@rpc("authority", "call_remote", "reliable")
func _rpc_evidence_collected(data: Dictionary) -> void:
	if _is_server():
		return

	var evidence := Evidence.from_network_dict(data)
	_add_evidence(evidence)


@rpc("authority", "call_remote", "reliable")
func _rpc_verification_changed(uid: String, new_state: int) -> void:
	if _is_server():
		return

	var evidence: Evidence = _evidence_by_uid.get(uid)
	if evidence:
		evidence.verification_state = new_state as EvidenceEnums.VerificationState
		evidence_verification_changed.emit(evidence)


@rpc("authority", "call_remote", "reliable")
func _rpc_sync_all_evidence(all_data: Array) -> void:
	if _is_server():
		return

	clear_evidence()
	for data: Dictionary in all_data:
		var evidence := Evidence.from_network_dict(data)
		_add_evidence(evidence)

	print("[EvidenceManager] Synced %d evidence items from server" % all_data.size())


@rpc("authority", "call_remote", "reliable")
func _rpc_identification_submitted(entity_type: String, submitter_id: int) -> void:
	if _is_server():
		return

	_pending_identification = {
		"entity_type": entity_type,
		"submitter_id": submitter_id,
		"votes": {},
	}

	identification_submitted.emit(entity_type, submitter_id)


@rpc("authority", "call_remote", "reliable")
func _rpc_vote_cast(voter_id: int, approve: bool) -> void:
	if _is_server():
		return

	# Update local pending identification votes
	if not _pending_identification.is_empty():
		var votes: Dictionary = _pending_identification.get("votes", {})
		votes[voter_id] = approve
		_pending_identification["votes"] = votes


@rpc("authority", "call_remote", "reliable")
func _rpc_identification_result(entity_type: String, approved: bool) -> void:
	if _is_server():
		return

	if approved:
		identification_approved.emit(entity_type)
	else:
		identification_rejected.emit(entity_type)
		# Clear pending so another proposal can be made
		_pending_identification.clear()
