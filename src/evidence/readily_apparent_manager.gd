extends Node
## Tracks readily-apparent evidence events (manifestations and interactions).
## Autoload: ReadilyApparentManager
##
## Readily-apparent evidence includes visual manifestations (entity appearances)
## and physical interactions (object throws, door slams, etc.). These events
## are observable by all nearby players, making them high-trust evidence.
##
## Key responsibilities:
## - Track when phenomena occur and who witnessed them
## - Enable evidence generation with witness counts
## - Support Cultist omission tracking (failing to report witnessed events)
##
## Note: No class_name to avoid conflicts with autoload singleton name.


# --- Signals ---

## Emitted when a visual manifestation occurs.
## location is the world position, manifestation_type is ManifestationEnums value.
signal phenomenon_occurred(
	phenomenon_type: String, location: Vector3, witnesses: Array[int]
)

## Emitted when a physical interaction occurs.
signal interaction_occurred(
	interaction_type: int, location: Vector3, witnesses: Array[int]
)

## Emitted when a player reports a phenomenon they witnessed.
signal phenomenon_reported(
	phenomenon_uid: String, reporter_id: int, phenomenon_type: String
)

## Emitted to notify witnesses that something happened nearby.
signal witness_notification(player_id: int, location: Vector3, phenomenon_type: String)


# --- Constants ---

## How long a phenomenon is valid for reporting (seconds).
const REPORT_WINDOW_SECONDS := 120.0

## Default visibility check distance when proximity tracking is disabled.
const DEFAULT_VISIBILITY_RANGE := 15.0


# --- State ---

## Stored phenomenon records indexed by UID.
## Each record: {uid, type, subtype, location, timestamp, witnesses, reported_by}
var _phenomena: Dictionary = {}

## Running counter for generating unique phenomenon IDs.
var _phenomenon_counter: int = 0

## Phenomena witnessed by each player (for omission tracking).
## {player_id: [phenomenon_uid, ...]}
var _witnessed_by_player: Dictionary = {}

## Phenomena reported by each player.
## {player_id: [phenomenon_uid, ...]}
var _reported_by_player: Dictionary = {}


func _ready() -> void:
	_connect_to_event_bus()
	print("[ReadilyApparentManager] Initialized - Witness tracking ready")


func _connect_to_event_bus() -> void:
	var event_bus := _get_event_bus()
	if not event_bus:
		return

	# Connect to entity manifestation signals
	if event_bus.has_signal("entity_manifesting"):
		event_bus.entity_manifesting.connect(_on_entity_manifesting)

	# Connect to game state for cleanup
	if event_bus.has_signal("game_state_changed"):
		event_bus.game_state_changed.connect(_on_game_state_changed)


func _get_event_bus() -> Node:
	if has_node("/root/EventBus"):
		return get_node("/root/EventBus")
	return null


func _get_network_manager() -> Node:
	if has_node("/root/NetworkManager"):
		return get_node("/root/NetworkManager")
	return null


# ===========================================================================
# Public API: Phenomenon Registration
# ===========================================================================


## Registers a visual manifestation and tracks witnesses.
## Returns the phenomenon UID for reference.
func register_manifestation(
	manifestation_type: ManifestationEnums.ManifestationType,
	location: Vector3,
	duration: float = 0.0
) -> String:
	var visibility_range := ManifestationEnums.get_visibility_range(manifestation_type)
	var witnesses := get_witnesses_in_area(location, visibility_range)

	var uid := _generate_phenomenon_uid()
	var record := {
		"uid": uid,
		"type": "manifestation",
		"subtype": manifestation_type,
		"location": location,
		"timestamp": Time.get_ticks_msec() / 1000.0,
		"duration": duration,
		"witnesses": witnesses,
		"reported_by": [] as Array[int],
	}
	_phenomena[uid] = record

	# Track what each player witnessed
	for witness_id: int in witnesses:
		if witness_id not in _witnessed_by_player:
			_witnessed_by_player[witness_id] = []
		_witnessed_by_player[witness_id].append(uid)

		# Notify witnesses
		witness_notification.emit(witness_id, location, "manifestation")

	phenomenon_occurred.emit("manifestation", location, witnesses)
	return uid


## Registers a physical interaction and tracks witnesses.
## Returns the phenomenon UID for reference.
func register_interaction(
	interaction_type: ManifestationEnums.InteractionType,
	location: Vector3,
	affected_object: String = ""
) -> String:
	var audibility_range := ManifestationEnums.get_audibility_range(interaction_type)
	var witnesses := get_witnesses_in_area(location, audibility_range)

	var uid := _generate_phenomenon_uid()
	var record := {
		"uid": uid,
		"type": "interaction",
		"subtype": interaction_type,
		"location": location,
		"timestamp": Time.get_ticks_msec() / 1000.0,
		"affected_object": affected_object,
		"witnesses": witnesses,
		"reported_by": [] as Array[int],
	}
	_phenomena[uid] = record

	# Track what each player witnessed
	for witness_id: int in witnesses:
		if witness_id not in _witnessed_by_player:
			_witnessed_by_player[witness_id] = []
		_witnessed_by_player[witness_id].append(uid)

		# Notify witnesses
		witness_notification.emit(witness_id, location, "interaction")

	interaction_occurred.emit(interaction_type, location, witnesses)
	return uid


# ===========================================================================
# Public API: Witness Queries
# ===========================================================================


## Returns player IDs of all players who could potentially see/hear an event.
## Uses proximity check and optionally line-of-sight.
func get_witnesses_in_area(location: Vector3, radius: float) -> Array[int]:
	var witnesses: Array[int] = []

	# Get all players in the game
	var players := _get_all_players()
	for player in players:
		if not is_instance_valid(player):
			continue

		var player_pos: Vector3 = player.global_position
		var distance := location.distance_to(player_pos)

		if distance <= radius:
			var player_id := _get_player_id(player)
			if player_id != 0:
				witnesses.append(player_id)

	return witnesses


## Returns player IDs who were facing the location (stricter witness check).
## For visual manifestations, only players looking at the event.
func get_definite_witnesses(location: Vector3, radius: float) -> Array[int]:
	var witnesses: Array[int] = []

	var players := _get_all_players()
	for player in players:
		if not is_instance_valid(player):
			continue

		var player_pos: Vector3 = player.global_position
		var distance := location.distance_to(player_pos)

		if distance > radius:
			continue

		# Check if player is facing the location
		if _is_player_facing(player, location):
			var player_id := _get_player_id(player)
			if player_id != 0:
				witnesses.append(player_id)

	return witnesses


## Returns all phenomena that a player witnessed but hasn't reported.
func get_unreported_phenomena(player_id: int) -> Array[String]:
	var unreported: Array[String] = []

	if player_id not in _witnessed_by_player:
		return unreported

	var witnessed: Array = _witnessed_by_player[player_id]
	var reported: Array = _reported_by_player.get(player_id, [])

	for uid: String in witnessed:
		if uid not in reported:
			# Check if still within report window
			if _is_reportable(uid):
				unreported.append(uid)

	return unreported


## Returns the phenomenon record for a UID.
func get_phenomenon(uid: String) -> Dictionary:
	return _phenomena.get(uid, {})


## Returns all phenomena near a location within the report window.
func get_recent_phenomena_at_location(location: Vector3, radius: float = 5.0) -> Array[Dictionary]:
	var nearby: Array[Dictionary] = []

	for uid: String in _phenomena:
		var record: Dictionary = _phenomena[uid]
		if not _is_reportable(uid):
			continue

		var phenomenon_location: Vector3 = record["location"]
		if location.distance_to(phenomenon_location) <= radius:
			nearby.append(record)

	return nearby


# ===========================================================================
# Public API: Reporting
# ===========================================================================


## Records that a player reported a phenomenon.
## Returns true if the report was accepted.
func report_phenomenon(uid: String, reporter_id: int) -> bool:
	if uid not in _phenomena:
		return false

	var record: Dictionary = _phenomena[uid]

	# Check report window
	if not _is_reportable(uid):
		return false

	# Record the report
	if reporter_id not in record["reported_by"]:
		record["reported_by"].append(reporter_id)

	# Track player's reports
	if reporter_id not in _reported_by_player:
		_reported_by_player[reporter_id] = []
	if uid not in _reported_by_player[reporter_id]:
		_reported_by_player[reporter_id].append(uid)

	phenomenon_reported.emit(uid, reporter_id, record["type"])
	return true


## Returns the number of witnesses who reported a phenomenon.
func get_report_count(uid: String) -> int:
	if uid not in _phenomena:
		return 0
	var record: Dictionary = _phenomena[uid]
	return record["reported_by"].size()


## Returns true if multiple witnesses reported the phenomenon.
func is_multi_witness_report(uid: String) -> bool:
	return get_report_count(uid) >= 2


# ===========================================================================
# Public API: Cultist Omission Tracking
# ===========================================================================


## Returns phenomena a player witnessed but didn't report (for post-game).
## Used to reveal Cultist omissions.
func get_omissions_for_player(player_id: int) -> Array[Dictionary]:
	var omissions: Array[Dictionary] = []

	if player_id not in _witnessed_by_player:
		return omissions

	var witnessed: Array = _witnessed_by_player[player_id]
	var reported: Array = _reported_by_player.get(player_id, [])

	for uid: String in witnessed:
		if uid not in reported and uid in _phenomena:
			omissions.append(_phenomena[uid])

	return omissions


## Returns true if a player was present for a phenomenon.
func was_player_present(player_id: int, uid: String) -> bool:
	if uid not in _phenomena:
		return false
	var record: Dictionary = _phenomena[uid]
	return player_id in record["witnesses"]


# ===========================================================================
# Public API: State Management
# ===========================================================================


## Clears all tracked phenomena (called at round start).
func clear_all_phenomena() -> void:
	_phenomena.clear()
	_witnessed_by_player.clear()
	_reported_by_player.clear()
	_phenomenon_counter = 0


## Returns all phenomena records (for serialization).
func get_all_phenomena() -> Dictionary:
	return _phenomena.duplicate(true)


# ===========================================================================
# Private Methods
# ===========================================================================


func _generate_phenomenon_uid() -> String:
	_phenomenon_counter += 1
	return "phenomenon_%d_%d" % [Time.get_ticks_msec(), _phenomenon_counter]


func _is_reportable(uid: String) -> bool:
	if uid not in _phenomena:
		return false

	var record: Dictionary = _phenomena[uid]
	var elapsed: float = (Time.get_ticks_msec() / 1000.0) - record["timestamp"]
	return elapsed <= REPORT_WINDOW_SECONDS


func _get_all_players() -> Array[Node]:
	var players: Array[Node] = []

	# Try to get from player group
	var player_nodes := get_tree().get_nodes_in_group("players")
	for node in player_nodes:
		if node is Node3D:
			players.append(node)

	return players


func _get_player_id(player: Node) -> int:
	# Try various methods to get player ID
	if player.has_method("get_player_id"):
		return player.get_player_id()
	if "player_id" in player:
		return player.player_id
	if "peer_id" in player:
		return player.peer_id
	# Fallback to instance ID as unique identifier
	return player.get_instance_id()


func _is_player_facing(player: Node, location: Vector3) -> bool:
	if not player is Node3D:
		return false

	var player_3d: Node3D = player as Node3D
	var player_pos := player_3d.global_position
	var forward := -player_3d.global_transform.basis.z
	var to_location := (location - player_pos).normalized()

	# Check if facing within ~120 degree cone
	var dot := forward.dot(to_location)
	return dot > 0.5  # cos(60 degrees)


func _on_entity_manifesting(position: Vector3) -> void:
	# Auto-register manifestation when entity starts manifesting
	# Subtype can be enhanced later with actual manifestation type from entity
	register_manifestation(ManifestationEnums.ManifestationType.PARTIAL, position)


func _on_game_state_changed(old_state: int, new_state: int) -> void:
	# GameManager.GameState.LOBBY = 1
	# Clear phenomena when entering lobby (new round)
	const LOBBY_STATE := 1
	if new_state == LOBBY_STATE:
		clear_all_phenomena()
