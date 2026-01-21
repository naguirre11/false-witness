class_name Evidence
extends Resource
## Represents a single piece of collected evidence.
##
## Evidence is definitive when collected properly. Ambiguity comes from trust
## and collection conditions, not RNG. The Cultist hides in the space between
## "I messed up" and "I lied."
##
## Evidence is serializable for network sync and persistence.

# --- Exported Properties ---

@export var type: EvidenceEnums.EvidenceType
@export var category: EvidenceEnums.EvidenceCategory
@export var quality: EvidenceEnums.ReadingQuality
@export var trust_level: EvidenceEnums.TrustLevel
@export var verification_state: EvidenceEnums.VerificationState

@export_group("Collection Info")
@export var collector_id: int = 0  ## Player peer ID who collected this evidence
@export var location: Vector3 = Vector3.ZERO  ## World position where collected
@export var timestamp: float = 0.0  ## Game time when collected (seconds)

@export_group("Cooperative Evidence")
@export var secondary_collector_id: int = 0  ## For cooperative evidence (Prism, Aura)
@export var equipment_used: String = ""  ## Equipment type used to collect

@export_group("Witness Tracking")
@export var witness_ids: Array[int] = []  ## Players who witnessed this evidence
@export var verifier_id: int = 0  ## Player who verified this evidence (primary/first verifier)
@export var verification_timestamp: float = 0.0  ## When evidence was verified
## Multiple verifications: {verifier_id, timestamp}
@export var verification_history: Array[Dictionary] = []

@export_group("Ghost Writing Witnesses")
@export var setup_witness_id: int = 0  ## Player who witnessed book setup
@export var result_witness_id: int = 0  ## Player who witnessed result collection

@export_group("Sabotage Detection")
## Flags for detecting potential sabotage (Ghost Writing)
## Keys: "book_moved", "wrong_room", "setup_broken"
@export var sabotage_flags: Dictionary = {}

@export_group("Verification Metadata")
## Additional verification context
## Keys: "single_witness", "late_verification", "different_operators"
@export var verification_metadata: Dictionary = {}

@export_group("Evidence-Specific Metadata")
## Stores evidence-specific data (prism_shape, aura_color, behavior_category, etc.)
## This is separate from verification_metadata which tracks verification context.
@export var evidence_metadata: Dictionary = {}

@export_group("Metadata")
@export var uid: String = ""  ## Unique identifier for network sync
@export var notes: String = ""  ## Optional player notes


## Creates a new Evidence instance with the given type.
## Automatically sets category and trust_level based on type.
static func create(
	evidence_type: EvidenceEnums.EvidenceType,
	collector: int,
	pos: Vector3,
	reading_quality: EvidenceEnums.ReadingQuality = EvidenceEnums.ReadingQuality.STRONG
) -> Evidence:
	var evidence := Evidence.new()
	evidence.type = evidence_type
	evidence.category = EvidenceEnums.get_category(evidence_type)
	evidence.trust_level = EvidenceEnums.get_trust_level(evidence_type)
	evidence.quality = reading_quality
	evidence.collector_id = collector
	evidence.location = pos
	evidence.timestamp = Time.get_ticks_msec() / 1000.0
	evidence.uid = _generate_uid()
	return evidence


## Creates cooperative evidence that requires two players.
static func create_cooperative(
	evidence_type: EvidenceEnums.EvidenceType,
	primary_collector: int,
	secondary_collector: int,
	pos: Vector3,
	reading_quality: EvidenceEnums.ReadingQuality = EvidenceEnums.ReadingQuality.STRONG
) -> Evidence:
	var evidence := create(evidence_type, primary_collector, pos, reading_quality)
	evidence.secondary_collector_id = secondary_collector
	return evidence


## Returns true if this evidence is cooperative (requires 2 players).
func is_cooperative() -> bool:
	return EvidenceEnums.is_cooperative(type)


## Returns true if this evidence was collected with strong quality.
func is_definitive() -> bool:
	return quality == EvidenceEnums.ReadingQuality.STRONG


## Returns true if this evidence has been verified by another player.
func is_verified() -> bool:
	return verification_state == EvidenceEnums.VerificationState.VERIFIED


## Returns true if this evidence has conflicting reports.
func is_contested() -> bool:
	return verification_state == EvidenceEnums.VerificationState.CONTESTED


## Returns the display name for this evidence type.
func get_display_name() -> String:
	return EvidenceEnums.get_evidence_name(type)


## Returns the category display name.
func get_category_name() -> String:
	return EvidenceEnums.get_category_name(category)


## Returns the trust level display name.
func get_trust_name() -> String:
	return EvidenceEnums.get_trust_name(trust_level)


## Marks this evidence as verified. Records timestamp if not already set.
func verify() -> void:
	verification_state = EvidenceEnums.VerificationState.VERIFIED
	if verification_timestamp == 0.0:
		verification_timestamp = Time.get_ticks_msec() / 1000.0


## Marks this evidence as contested.
func contest() -> void:
	verification_state = EvidenceEnums.VerificationState.CONTESTED


## Resets verification to unverified.
func reset_verification() -> void:
	verification_state = EvidenceEnums.VerificationState.UNVERIFIED


## Records a verification by a specific player with timestamp.
func record_verification(peer_id: int) -> void:
	var timestamp := Time.get_ticks_msec() / 1000.0

	# Set primary verifier if not already set
	if verifier_id == 0:
		verifier_id = peer_id
		verification_timestamp = timestamp

	# Add to verification history
	verification_history.append({
		"verifier_id": peer_id,
		"timestamp": timestamp,
	})


## Returns the number of verifications recorded.
func get_verification_count() -> int:
	return verification_history.size()


## Returns the verification history as an array of {verifier_id, timestamp} dicts.
func get_verification_history() -> Array[Dictionary]:
	return verification_history.duplicate()


## Adds a witness to this evidence.
func add_witness(peer_id: int) -> void:
	if peer_id not in witness_ids:
		witness_ids.append(peer_id)


## Returns true if this evidence has multiple witnesses.
func has_multiple_witnesses() -> bool:
	return witness_ids.size() >= 2


## Returns the number of witnesses.
func get_witness_count() -> int:
	return witness_ids.size()


## Returns true if this evidence was witnessed by a specific player.
func was_witnessed_by(peer_id: int) -> bool:
	return peer_id in witness_ids


## Returns true if Ghost Writing has proper buddy system witnesses.
func has_ghost_writing_witnesses() -> bool:
	return setup_witness_id != 0 and result_witness_id != 0


## Returns true if any sabotage flags are set.
func has_sabotage_flags() -> bool:
	return not sabotage_flags.is_empty()


## Sets a sabotage flag.
func set_sabotage_flag(flag_name: String, value: bool = true) -> void:
	if value:
		sabotage_flags[flag_name] = true
	else:
		sabotage_flags.erase(flag_name)


## Gets a verification metadata value.
func get_verification_meta(key: String, default_value: Variant = null) -> Variant:
	return verification_metadata.get(key, default_value)


## Sets a verification metadata value.
func set_verification_meta(key: String, value: Variant) -> void:
	verification_metadata[key] = value


## Gets an evidence-specific metadata value (e.g., prism_shape, aura_color).
func get_metadata(key: String, default_value: Variant = null) -> Variant:
	return evidence_metadata.get(key, default_value)


## Sets an evidence-specific metadata value.
func set_metadata(key: String, value: Variant) -> void:
	evidence_metadata[key] = value


## Serializes this evidence for network transmission.
func to_network_dict() -> Dictionary:
	return {
		"uid": uid,
		"type": type,
		"category": category,
		"quality": quality,
		"trust_level": trust_level,
		"verification_state": verification_state,
		"collector_id": collector_id,
		"secondary_collector_id": secondary_collector_id,
		"location_x": location.x,
		"location_y": location.y,
		"location_z": location.z,
		"timestamp": timestamp,
		"equipment_used": equipment_used,
		"notes": notes,
		"witness_ids": witness_ids,
		"verifier_id": verifier_id,
		"verification_timestamp": verification_timestamp,
		"verification_history": verification_history,
		"setup_witness_id": setup_witness_id,
		"result_witness_id": result_witness_id,
		"sabotage_flags": sabotage_flags,
		"verification_metadata": verification_metadata,
		"evidence_metadata": evidence_metadata,
	}


## Creates an Evidence instance from network data.
static func from_network_dict(data: Dictionary) -> Evidence:
	var evidence := Evidence.new()
	evidence.uid = data.get("uid", "")
	var type_default := EvidenceEnums.EvidenceType.EMF_SIGNATURE
	evidence.type = data.get("type", type_default) as EvidenceEnums.EvidenceType
	var cat_default := EvidenceEnums.EvidenceCategory.EQUIPMENT_DERIVED
	evidence.category = data.get("category", cat_default) as EvidenceEnums.EvidenceCategory
	var qual_default := EvidenceEnums.ReadingQuality.STRONG
	evidence.quality = data.get("quality", qual_default) as EvidenceEnums.ReadingQuality
	var trust_default := EvidenceEnums.TrustLevel.HIGH
	evidence.trust_level = data.get("trust_level", trust_default) as EvidenceEnums.TrustLevel
	var verif_default := EvidenceEnums.VerificationState.UNVERIFIED
	var verif_val: int = data.get("verification_state", verif_default)
	evidence.verification_state = verif_val as EvidenceEnums.VerificationState
	evidence.collector_id = data.get("collector_id", 0)
	evidence.secondary_collector_id = data.get("secondary_collector_id", 0)
	evidence.location = Vector3(
		data.get("location_x", 0.0),
		data.get("location_y", 0.0),
		data.get("location_z", 0.0)
	)
	evidence.timestamp = data.get("timestamp", 0.0)
	evidence.equipment_used = data.get("equipment_used", "")
	evidence.notes = data.get("notes", "")
	# Witness tracking
	var raw_witness_ids: Array = data.get("witness_ids", [])
	evidence.witness_ids = []
	for id in raw_witness_ids:
		evidence.witness_ids.append(id as int)
	evidence.verifier_id = data.get("verifier_id", 0)
	evidence.verification_timestamp = data.get("verification_timestamp", 0.0)
	# Verification history
	var raw_history: Array = data.get("verification_history", [])
	evidence.verification_history = []
	for entry: Dictionary in raw_history:
		evidence.verification_history.append(entry.duplicate())
	# Ghost Writing witnesses
	evidence.setup_witness_id = data.get("setup_witness_id", 0)
	evidence.result_witness_id = data.get("result_witness_id", 0)
	# Sabotage and metadata
	evidence.sabotage_flags = data.get("sabotage_flags", {})
	evidence.verification_metadata = data.get("verification_metadata", {})
	evidence.evidence_metadata = data.get("evidence_metadata", {})
	return evidence


## Generates a unique identifier for this evidence.
static func _generate_uid() -> String:
	var time_part := str(Time.get_ticks_msec())
	var rand_part := str(randi() % 10000).pad_zeros(4)
	return time_part + "_" + rand_part


## Returns true if two evidence pieces are equivalent (same type and collector).
func equals(other: Evidence) -> bool:
	if other == null:
		return false
	return uid == other.uid


## Returns a debug string representation.
func _to_string() -> String:
	var quality_str := "STRONG" if quality == EvidenceEnums.ReadingQuality.STRONG else "WEAK"
	return "[Evidence: %s (%s) by %d]" % [get_display_name(), quality_str, collector_id]
