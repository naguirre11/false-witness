class_name EvidenceEnums
extends RefCounted
## Evidence system enumerations.
##
## Centralizes all evidence-related enums for type safety and discoverability.
## These enums are used across Evidence, EvidenceManager, and equipment classes.


## Evidence categories determine how evidence is collected and verified.
## Each evidence type belongs to exactly one category.
enum EvidenceCategory {
	READILY_APPARENT,  ## Visible to all nearby players (visual/physical manifestation)
	EQUIPMENT_DERIVED,  ## Requires equipment to detect (EMF, thermometer, etc.)
	TRIGGERED_TEST,  ## Requires player setup and entity response (ghost writing)
	BEHAVIOR_BASED,  ## Observed through entity actions during hunts
}


## Evidence types available in the game.
## Distribution: 2 Readily-Apparent, 4 Equipment-Derived, 1 Triggered, 1 Behavior
enum EvidenceType {
	# Equipment-Derived (4)
	FREEZING_TEMPERATURE,  ## Detected by Thermometer
	EMF_SIGNATURE,  ## Detected by EMF Reader (level 5 = evidence)
	PRISM_READING,  ## Cooperative symmetric - both players see same reading
	AURA_PATTERN,  ## Cooperative asymmetric - Imager sees aura, Rods point

	# Triggered Test (1)
	GHOST_WRITING,  ## Requires book placement, entity writes

	# Readily-Apparent (2)
	VISUAL_MANIFESTATION,  ## Full/partial entity appearances
	PHYSICAL_INTERACTION,  ## Thrown objects, door manipulation

	# Behavior-Based (1)
	HUNT_BEHAVIOR,  ## Entity behavior patterns during hunts
}


## Reading quality affects how definitive the evidence is.
## Strong = definitive, Weak = suggestive only.
enum ReadingQuality {
	STRONG,  ## Definitive evidence - proper conditions met
	WEAK,  ## Suggestive only - suboptimal conditions
}


## Trust levels indicate how reliable evidence is in social deduction context.
## This affects UI presentation and cross-verification requirements.
enum TrustLevel {
	UNFALSIFIABLE,  ## Cannot be faked (hunt behavior - all see it)
	HIGH,  ## Difficult to fake (shared displays, omission only)
	VARIABLE,  ## Depends on collection method (one party can lie)
	LOW,  ## Easy to dispute (both parties can lie)
	SABOTAGE_RISK,  ## Can be corrupted before collection (ghost writing)
}


## Verification state tracks cross-verification status.
enum VerificationState {
	UNVERIFIED,  ## No second opinion yet
	VERIFIED,  ## Corroborated by another player
	CONTESTED,  ## Conflicting reports exist
}


## Maps evidence types to their categories.
static func get_category(evidence_type: EvidenceType) -> EvidenceCategory:
	match evidence_type:
		EvidenceType.FREEZING_TEMPERATURE, \
		EvidenceType.EMF_SIGNATURE, \
		EvidenceType.PRISM_READING, \
		EvidenceType.AURA_PATTERN:
			return EvidenceCategory.EQUIPMENT_DERIVED
		EvidenceType.GHOST_WRITING:
			return EvidenceCategory.TRIGGERED_TEST
		EvidenceType.VISUAL_MANIFESTATION, \
		EvidenceType.PHYSICAL_INTERACTION:
			return EvidenceCategory.READILY_APPARENT
		EvidenceType.HUNT_BEHAVIOR:
			return EvidenceCategory.BEHAVIOR_BASED
		_:
			return EvidenceCategory.EQUIPMENT_DERIVED


## Maps evidence types to their default trust levels.
static func get_trust_level(evidence_type: EvidenceType) -> TrustLevel:
	match evidence_type:
		EvidenceType.HUNT_BEHAVIOR:
			return TrustLevel.UNFALSIFIABLE
		EvidenceType.EMF_SIGNATURE, \
		EvidenceType.FREEZING_TEMPERATURE, \
		EvidenceType.VISUAL_MANIFESTATION, \
		EvidenceType.PHYSICAL_INTERACTION:
			return TrustLevel.HIGH
		EvidenceType.AURA_PATTERN:
			return TrustLevel.VARIABLE
		EvidenceType.PRISM_READING:
			return TrustLevel.LOW
		EvidenceType.GHOST_WRITING:
			return TrustLevel.SABOTAGE_RISK
		_:
			return TrustLevel.HIGH


## Returns true if this evidence type is cooperative (requires 2 players).
static func is_cooperative(evidence_type: EvidenceType) -> bool:
	return evidence_type == EvidenceType.PRISM_READING \
		or evidence_type == EvidenceType.AURA_PATTERN


## Returns the display name for an evidence type.
static func get_evidence_name(evidence_type: EvidenceType) -> String:
	match evidence_type:
		EvidenceType.FREEZING_TEMPERATURE:
			return "Freezing Temperature"
		EvidenceType.EMF_SIGNATURE:
			return "EMF Level 5"
		EvidenceType.PRISM_READING:
			return "Spectral Prism Reading"
		EvidenceType.AURA_PATTERN:
			return "Aura Pattern"
		EvidenceType.GHOST_WRITING:
			return "Ghost Writing"
		EvidenceType.VISUAL_MANIFESTATION:
			return "Visual Manifestation"
		EvidenceType.PHYSICAL_INTERACTION:
			return "Physical Interaction"
		EvidenceType.HUNT_BEHAVIOR:
			return "Hunt Behavior"
		_:
			return "Unknown"


## Returns the display name for a category.
static func get_category_name(category: EvidenceCategory) -> String:
	match category:
		EvidenceCategory.READILY_APPARENT:
			return "Readily Apparent"
		EvidenceCategory.EQUIPMENT_DERIVED:
			return "Equipment-Derived"
		EvidenceCategory.TRIGGERED_TEST:
			return "Triggered Test"
		EvidenceCategory.BEHAVIOR_BASED:
			return "Behavior-Based"
		_:
			return "Unknown"


## Returns the display name for a trust level.
static func get_trust_name(trust: TrustLevel) -> String:
	match trust:
		TrustLevel.UNFALSIFIABLE:
			return "Unfalsifiable"
		TrustLevel.HIGH:
			return "High Trust"
		TrustLevel.VARIABLE:
			return "Variable Trust"
		TrustLevel.LOW:
			return "Low Trust"
		TrustLevel.SABOTAGE_RISK:
			return "Sabotage Risk"
		_:
			return "Unknown"


## Returns the display name for a verification state.
static func get_verification_name(state: VerificationState) -> String:
	match state:
		VerificationState.UNVERIFIED:
			return "Unverified"
		VerificationState.VERIFIED:
			return "Verified"
		VerificationState.CONTESTED:
			return "Contested"
		_:
			return "Unknown"


## Returns the display name for a reading quality.
static func get_quality_name(quality: ReadingQuality) -> String:
	match quality:
		ReadingQuality.STRONG:
			return "Strong"
		ReadingQuality.WEAK:
			return "Weak"
		_:
			return "Unknown"
