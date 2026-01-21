class_name ContaminatedEvidence
extends Evidence
## Evidence planted by a Cultist that decays over time.
##
## Contaminated evidence appears authentic initially but develops visual
## anomalies as it ages. After 180 seconds, it expires and disappears.
## Server tracks creation timestamp; visual effects are client-side.

# --- Signals ---

## Emitted when the decay state changes.
signal decay_state_changed(old_state: int, new_state: int)

## Emitted when the evidence expires (180+ seconds).
signal expired()

# --- Contamination Properties ---

## Unix timestamp (seconds) when this evidence was planted.
@export var creation_timestamp: float = 0.0

## Player ID of the Cultist who planted this evidence.
@export var planted_by: int = 0

## The ability type used to plant this evidence.
@export var source_ability: int = 0  # CultistEnums.AbilityType

## Whether this evidence has expired.
@export var is_expired: bool = false

# --- Runtime State ---

## Current decay state (not exported - computed from timestamp).
var _current_decay_state: int = CultistEnums.DecayState.PLANTED


## Creates contaminated evidence of the given type.
static func create_contaminated(
	evidence_type: EvidenceEnums.EvidenceType,
	cultist_id: int,
	pos: Vector3,
	ability_type: int
) -> ContaminatedEvidence:
	var evidence := ContaminatedEvidence.new()
	evidence.type = evidence_type
	evidence.category = EvidenceEnums.get_category(evidence_type)
	evidence.trust_level = EvidenceEnums.get_trust_level(evidence_type)
	evidence.quality = EvidenceEnums.ReadingQuality.STRONG  # Looks authentic initially
	evidence.collector_id = cultist_id
	evidence.location = pos
	evidence.timestamp = Time.get_ticks_msec() / 1000.0
	evidence.uid = Evidence._generate_uid()

	# Contamination-specific
	evidence.creation_timestamp = Time.get_unix_time_from_system()
	evidence.planted_by = cultist_id
	evidence.source_ability = ability_type
	evidence._current_decay_state = CultistEnums.DecayState.PLANTED

	return evidence


## Returns the current decay state based on elapsed time.
func get_decay_state() -> int:
	var elapsed := get_elapsed_time()
	return CultistEnums.get_decay_state_for_time(elapsed)


## Returns seconds since this evidence was planted.
func get_elapsed_time() -> float:
	if creation_timestamp <= 0:
		return 0.0
	return Time.get_unix_time_from_system() - creation_timestamp


## Returns seconds remaining before expiration.
func get_time_until_expiration() -> float:
	var elapsed := get_elapsed_time()
	var expire_threshold: float = CultistEnums.DECAY_THRESHOLDS[CultistEnums.DecayState.EXPIRED]
	return maxf(0.0, expire_threshold - elapsed)


## Updates the decay state. Call this periodically (e.g., every second).
## Returns true if the state changed.
func update_decay() -> bool:
	if is_expired:
		return false

	var new_state := get_decay_state()

	if new_state != _current_decay_state:
		var old_state := _current_decay_state
		_current_decay_state = new_state
		decay_state_changed.emit(old_state, new_state)

		if new_state == CultistEnums.DecayState.EXPIRED:
			is_expired = true
			expired.emit()

		return true

	return false


## Returns true if this evidence is in a visibly degraded state.
func is_visibly_degraded() -> bool:
	var state := get_decay_state()
	return state >= CultistEnums.DecayState.DEGRADED


## Returns true if this evidence shows subtle anomalies.
func has_subtle_anomalies() -> bool:
	var state := get_decay_state()
	return state >= CultistEnums.DecayState.UNSTABLE


## Returns true if this evidence has completely expired.
func has_expired() -> bool:
	return is_expired or get_decay_state() == CultistEnums.DecayState.EXPIRED


## Returns the decay progress as a value from 0 to 1.
## 0 = freshly planted, 1 = about to expire.
func get_decay_progress() -> float:
	var elapsed := get_elapsed_time()
	var expire_threshold: float = CultistEnums.DECAY_THRESHOLDS[CultistEnums.DecayState.EXPIRED]
	return clampf(elapsed / expire_threshold, 0.0, 1.0)


## Returns a description of the current visual state for UI.
func get_visual_state_description() -> String:
	var state := get_decay_state()
	match state:
		CultistEnums.DecayState.PLANTED:
			return "Evidence appears authentic"
		CultistEnums.DecayState.UNSTABLE:
			return "Subtle visual anomalies present"
		CultistEnums.DecayState.DEGRADED:
			return "Clear visual artifacts visible"
		CultistEnums.DecayState.EXPIRED:
			return "Evidence has faded away"
	return "Unknown state"


## Override to add contamination flag to network data.
func to_network_dict() -> Dictionary:
	var data := super.to_network_dict()
	data["is_contaminated"] = true
	data["creation_timestamp"] = creation_timestamp
	data["planted_by"] = planted_by
	data["source_ability"] = source_ability
	data["is_expired"] = is_expired
	return data


## Creates a ContaminatedEvidence from network data.
static func from_network_dict_contaminated(data: Dictionary) -> ContaminatedEvidence:
	var evidence := ContaminatedEvidence.new()

	# Base Evidence fields
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

	# Contamination-specific
	evidence.creation_timestamp = data.get("creation_timestamp", 0.0)
	evidence.planted_by = data.get("planted_by", 0)
	evidence.source_ability = data.get("source_ability", 0)
	evidence.is_expired = data.get("is_expired", false)

	return evidence


## Returns debug string.
func _to_string() -> String:
	var state_name := CultistEnums.get_decay_state_name(get_decay_state())
	return "[ContaminatedEvidence: %s (Decay: %s) by Cultist %d]" % [
		get_display_name(), state_name, planted_by
	]
