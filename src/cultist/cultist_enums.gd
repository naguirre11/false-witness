class_name CultistEnums
extends RefCounted
## Enum definitions for the Cultist traitor system.
##
## Contains:
## - PlayerRole: Role types (Investigator vs Cultist)
## - DiscoveryState: Cultist discovery progression
## - Ability-related enums and data structures


# --- Player Roles ---

## The possible roles a player can have in a match.
enum PlayerRole {
	INVESTIGATOR = 0,  ## Default role: investigate the entity, identify the Cultist
	CULTIST = 1,  ## Traitor role: plant false evidence, misdirect team
}


# --- Discovery State ---

## Discovery state for a Cultist player.
enum DiscoveryState {
	HIDDEN = 0,  ## Cultist identity unknown to investigators
	SUSPECTED = 1,  ## Players suspect this person (no mechanical effect)
	DISCOVERED = 2,  ## Cultist has been identified via vote - abilities disabled
}


# --- Decay State ---

## Decay state for contaminated evidence planted by Cultist.
enum DecayState {
	PLANTED = 0,  ## 0-60 seconds: Evidence appears authentic
	UNSTABLE = 1,  ## 60-120 seconds: Subtle visual anomalies
	DEGRADED = 2,  ## 120-180 seconds: Clear visual artifacts
	EXPIRED = 3,  ## 180+ seconds: Evidence disappears
}


# --- Ability Types ---

## Types of Cultist abilities.
enum AbilityType {
	EMF_SPOOF,  ## Plant false EMF_SIGNATURE readings
	TEMPERATURE_MANIPULATION,  ## Create false FREEZING_TEMPERATURE zone
	PRISM_INTERFERENCE,  ## Corrupt next PRISM_READING data
	AURA_DISRUPTION,  ## Plant false AURA_PATTERN trails
	PROVOCATION,  ## Force immediate hunt
	FALSE_ALARM,  ## Trigger hunt warning without actual hunt
	EQUIPMENT_SABOTAGE,  ## Disable teammate equipment temporarily
}


# --- Ability Data ---

## Default charges for each ability type.
const DEFAULT_CHARGES := {
	AbilityType.EMF_SPOOF: 2,
	AbilityType.TEMPERATURE_MANIPULATION: 2,
	AbilityType.PRISM_INTERFERENCE: 1,
	AbilityType.AURA_DISRUPTION: 2,
	AbilityType.PROVOCATION: 1,
	AbilityType.FALSE_ALARM: 1,
	AbilityType.EQUIPMENT_SABOTAGE: 1,
}


## Default placement time in seconds for contamination abilities.
const DEFAULT_PLACEMENT_TIME := 5.0


## Decay timing thresholds in seconds.
const DECAY_THRESHOLDS := {
	DecayState.PLANTED: 0.0,  # Start
	DecayState.UNSTABLE: 60.0,  # 1 minute
	DecayState.DEGRADED: 120.0,  # 2 minutes
	DecayState.EXPIRED: 180.0,  # 3 minutes
}


# --- Helper Methods ---


## Get human-readable name for a player role.
static func get_role_name(role: PlayerRole) -> String:
	match role:
		PlayerRole.INVESTIGATOR:
			return "Investigator"
		PlayerRole.CULTIST:
			return "Cultist"
	return "Unknown"


## Get human-readable name for a discovery state.
static func get_discovery_state_name(state: DiscoveryState) -> String:
	match state:
		DiscoveryState.HIDDEN:
			return "Hidden"
		DiscoveryState.SUSPECTED:
			return "Suspected"
		DiscoveryState.DISCOVERED:
			return "Discovered"
	return "Unknown"


## Get human-readable name for a decay state.
static func get_decay_state_name(state: DecayState) -> String:
	match state:
		DecayState.PLANTED:
			return "Planted"
		DecayState.UNSTABLE:
			return "Unstable"
		DecayState.DEGRADED:
			return "Degraded"
		DecayState.EXPIRED:
			return "Expired"
	return "Unknown"


## Get human-readable name for an ability type.
static func get_ability_name(ability: AbilityType) -> String:
	match ability:
		AbilityType.EMF_SPOOF:
			return "EMF Spoof"
		AbilityType.TEMPERATURE_MANIPULATION:
			return "Temperature Manipulation"
		AbilityType.PRISM_INTERFERENCE:
			return "Prism Interference"
		AbilityType.AURA_DISRUPTION:
			return "Aura Disruption"
		AbilityType.PROVOCATION:
			return "Provocation"
		AbilityType.FALSE_ALARM:
			return "False Alarm"
		AbilityType.EQUIPMENT_SABOTAGE:
			return "Equipment Sabotage"
	return "Unknown"


## Get the decay state for a given elapsed time.
static func get_decay_state_for_time(elapsed_seconds: float) -> DecayState:
	if elapsed_seconds >= DECAY_THRESHOLDS[DecayState.EXPIRED]:
		return DecayState.EXPIRED
	elif elapsed_seconds >= DECAY_THRESHOLDS[DecayState.DEGRADED]:
		return DecayState.DEGRADED
	elif elapsed_seconds >= DECAY_THRESHOLDS[DecayState.UNSTABLE]:
		return DecayState.UNSTABLE
	else:
		return DecayState.PLANTED


## Get default charges for an ability type.
static func get_default_charges(ability: AbilityType) -> int:
	return DEFAULT_CHARGES.get(ability, 1)


## Check if an ability is a contamination ability (plants evidence).
static func is_contamination_ability(ability: AbilityType) -> bool:
	return ability in [
		AbilityType.EMF_SPOOF,
		AbilityType.TEMPERATURE_MANIPULATION,
		AbilityType.PRISM_INTERFERENCE,
		AbilityType.AURA_DISRUPTION,
	]


# --- Cultist Data Structure ---

## Data structure for tracking a Cultist player's state.
## Used to store ability charges and discovery state per Cultist.
class CultistData:
	## The Cultist player's ID.
	var player_id: int = -1

	## Current discovery state.
	var discovery_state: int = DiscoveryState.HIDDEN

	## Ability charges remaining: AbilityType -> int
	var ability_charges: Dictionary = {}

	## Whether this Cultist is alive.
	var is_alive: bool = true

	## Whether abilities are disabled (due to discovery or death).
	var abilities_disabled: bool = false


	func _init(pid: int = -1) -> void:
		player_id = pid
		discovery_state = DiscoveryState.HIDDEN
		is_alive = true
		abilities_disabled = false
		_init_charges()


	func _init_charges() -> void:
		for ability_type in DEFAULT_CHARGES.keys():
			ability_charges[ability_type] = DEFAULT_CHARGES[ability_type]


	## Get remaining charges for an ability.
	func get_charges(ability: int) -> int:
		return ability_charges.get(ability, 0)


	## Use a charge of an ability. Returns true if successful.
	func use_charge(ability: int) -> bool:
		if abilities_disabled:
			return false
		var current: int = ability_charges.get(ability, 0)
		if current <= 0:
			return false
		ability_charges[ability] = current - 1
		return true


	## Check if an ability can be used.
	func can_use_ability(ability: int) -> bool:
		if abilities_disabled:
			return false
		return get_charges(ability) > 0


	## Disable all abilities (called on discovery or death).
	func disable_abilities() -> void:
		abilities_disabled = true


	## Mark as discovered.
	func mark_discovered() -> void:
		discovery_state = DiscoveryState.DISCOVERED
		disable_abilities()


	## Mark as dead.
	func mark_dead() -> void:
		is_alive = false
		disable_abilities()


	## Convert to Dictionary for network sync.
	func to_dict() -> Dictionary:
		return {
			"player_id": player_id,
			"discovery_state": discovery_state,
			"ability_charges": ability_charges.duplicate(),
			"is_alive": is_alive,
			"abilities_disabled": abilities_disabled,
		}


	## Create from Dictionary (network sync).
	static func from_dict(data: Dictionary) -> CultistData:
		var cd := CultistData.new(data.get("player_id", -1))
		cd.discovery_state = data.get("discovery_state", DiscoveryState.HIDDEN)
		cd.ability_charges = data.get("ability_charges", {}).duplicate()
		cd.is_alive = data.get("is_alive", true)
		cd.abilities_disabled = data.get("abilities_disabled", false)
		return cd
