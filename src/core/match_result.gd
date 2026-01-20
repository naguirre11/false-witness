class_name MatchResult
extends Resource
## Stores the result of a completed match.
##
## Contains information about who won, how they won, the actual entity type,
## and who the Cultist was. Used by the results screen and post-match analytics.

# --- Enums ---

## The possible win conditions for a match.
enum WinCondition {
	CORRECT_IDENTIFICATION,  ## Investigators correctly identified the entity
	INCORRECT_IDENTIFICATION,  ## Team guessed wrong entity (Cultist wins)
	CULTIST_VOTED_OUT,  ## Investigators identified and voted out the Cultist
	INNOCENT_VOTED_OUT,  ## Team voted out an innocent player (Cultist wins)
	TIME_EXPIRED,  ## Deliberation timer ran out without decision (Cultist wins)
}

## Which team won the match.
enum WinningTeam {
	INVESTIGATORS,  ## The investigation team won
	CULTIST,  ## The Cultist won
}

# --- Export: Match Data ---

@export var winning_team: WinningTeam = WinningTeam.INVESTIGATORS
@export var win_condition: WinCondition = WinCondition.CORRECT_IDENTIFICATION
@export var entity_type: String = ""
@export var cultist_id: int = -1
@export var cultist_username: String = ""
@export var match_duration: float = 0.0

# --- Additional Data ---

## Evidence that was collected during the match.
var collected_evidence: Array[Dictionary] = []

## The entity's evidence signature (3 evidence types).
var entity_evidence: Array[String] = []

## Which evidence was correctly identified vs missed.
var evidence_collected_correctly: Array[String] = []
var evidence_missed: Array[String] = []

## Contaminated evidence that was trusted.
var contaminated_trusted: Array[Dictionary] = []

## Player statistics for the match.
var player_stats: Dictionary = {}

## Cultist action timeline.
var cultist_actions: Array[Dictionary] = []


# --- Convenience Methods ---


## Returns a human-readable win condition string.
func get_win_condition_text() -> String:
	match win_condition:
		WinCondition.CORRECT_IDENTIFICATION:
			return "The team correctly identified the entity!"
		WinCondition.INCORRECT_IDENTIFICATION:
			return "The team identified the wrong entity."
		WinCondition.CULTIST_VOTED_OUT:
			return "The Cultist was discovered and voted out!"
		WinCondition.INNOCENT_VOTED_OUT:
			return "An innocent investigator was wrongly accused."
		WinCondition.TIME_EXPIRED:
			return "Time ran out before a decision was made."
		_:
			return "Unknown outcome."


## Returns true if investigators won.
func did_investigators_win() -> bool:
	return winning_team == WinningTeam.INVESTIGATORS


## Returns true if cultist won.
func did_cultist_win() -> bool:
	return winning_team == WinningTeam.CULTIST


## Serializes result for network transmission.
func to_dict() -> Dictionary:
	return {
		"winning_team": winning_team,
		"win_condition": win_condition,
		"entity_type": entity_type,
		"cultist_id": cultist_id,
		"cultist_username": cultist_username,
		"match_duration": match_duration,
		"collected_evidence": collected_evidence,
		"entity_evidence": entity_evidence,
		"evidence_collected_correctly": evidence_collected_correctly,
		"evidence_missed": evidence_missed,
		"contaminated_trusted": contaminated_trusted,
		"player_stats": player_stats,
		"cultist_actions": cultist_actions,
	}


## Deserializes from network data.
static func from_dict(data: Dictionary) -> MatchResult:
	var result := MatchResult.new()

	if data.has("winning_team"):
		result.winning_team = data.winning_team as WinningTeam
	if data.has("win_condition"):
		result.win_condition = data.win_condition as WinCondition
	if data.has("entity_type"):
		result.entity_type = data.entity_type
	if data.has("cultist_id"):
		result.cultist_id = data.cultist_id
	if data.has("cultist_username"):
		result.cultist_username = data.cultist_username
	if data.has("match_duration"):
		result.match_duration = data.match_duration
	if data.has("collected_evidence"):
		result.collected_evidence.assign(data.collected_evidence)
	if data.has("entity_evidence"):
		result.entity_evidence.assign(data.entity_evidence)
	if data.has("evidence_collected_correctly"):
		result.evidence_collected_correctly.assign(data.evidence_collected_correctly)
	if data.has("evidence_missed"):
		result.evidence_missed.assign(data.evidence_missed)
	if data.has("contaminated_trusted"):
		result.contaminated_trusted.assign(data.contaminated_trusted)
	if data.has("player_stats"):
		result.player_stats = data.player_stats
	if data.has("cultist_actions"):
		result.cultist_actions.assign(data.cultist_actions)

	return result
