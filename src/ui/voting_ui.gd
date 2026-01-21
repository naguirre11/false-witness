extends Control
## Voting UI for identification proposals during deliberation.
##
## Shows when someone proposes an entity identification, allowing players
## to approve or reject. Auto-closes when majority reached.

# --- Signals ---

signal vote_submitted(approve: bool)
signal voting_closed

# --- State Variables ---

var _is_active: bool = false
var _entity_type: String = ""
var _submitter_name: String = ""
var _votes_for: int = 0
var _votes_against: int = 0
var _votes_needed: int = 0
var _total_voters: int = 0
var _has_voted: bool = false

# --- Node References ---

@onready var _proposal_label: Label = %ProposalLabel
@onready var _vote_status: Label = %VoteStatus
@onready var _approve_button: Button = %ApproveButton
@onready var _reject_button: Button = %RejectButton
@onready var _waiting_label: Label = %WaitingLabel


func _ready() -> void:
	_approve_button.pressed.connect(_on_approve_pressed)
	_reject_button.pressed.connect(_on_reject_pressed)
	hide()


## Shows the voting UI for a proposal.
func show_voting(
	entity_type: String, submitter_name: String, votes_needed: int, total_voters: int
) -> void:
	_entity_type = entity_type
	_submitter_name = submitter_name
	_votes_needed = votes_needed
	_total_voters = total_voters
	_votes_for = 0
	_votes_against = 0
	_has_voted = false
	_is_active = true

	_proposal_label.text = "%s proposes: %s" % [submitter_name, entity_type]
	_update_vote_display()

	# Enable voting buttons
	_approve_button.disabled = false
	_reject_button.disabled = false
	_waiting_label.visible = false

	show()
	_approve_button.grab_focus()
	print("[VotingUI] Shown - %s proposes %s (need %d/%d)" % [
		submitter_name, entity_type, votes_needed, total_voters
	])


## Hides the voting UI.
func hide_voting() -> void:
	_is_active = false
	hide()
	voting_closed.emit()
	print("[VotingUI] Hidden")


## Updates the vote counts (called from network updates).
func update_votes(votes_for: int, votes_against: int) -> void:
	_votes_for = votes_for
	_votes_against = votes_against
	_update_vote_display()

	# Check if majority reached
	if _votes_for >= _votes_needed:
		_show_result_and_close("APPROVED!", Color(0.3, 1.0, 0.3))
	elif _votes_against > _total_voters - _votes_needed:
		# If enough people voted against, rejection is guaranteed
		_show_result_and_close("REJECTED", Color(1.0, 0.3, 0.3))


## Sets whether the local player has already voted.
func set_voted(has_voted: bool) -> void:
	_has_voted = has_voted
	_approve_button.disabled = has_voted
	_reject_button.disabled = has_voted
	_waiting_label.visible = has_voted


## Returns true if voting is currently active.
func is_active() -> bool:
	return _is_active


## Returns the current vote counts.
func get_vote_counts() -> Dictionary:
	return {
		"for": _votes_for,
		"against": _votes_against,
		"needed": _votes_needed,
		"total": _total_voters,
	}


# --- Private Methods ---


func _update_vote_display() -> void:
	_vote_status.text = "Approve: %d/%d needed | Reject: %d" % [
		_votes_for, _votes_needed, _votes_against
	]

	# Color coding
	if _votes_for >= _votes_needed:
		_vote_status.modulate = Color(0.3, 1.0, 0.3)
	elif _votes_against > _total_voters - _votes_needed:
		_vote_status.modulate = Color(1.0, 0.3, 0.3)
	else:
		_vote_status.modulate = Color.WHITE


func _show_result_and_close(result_text: String, result_color: Color) -> void:
	_proposal_label.text = result_text
	_proposal_label.modulate = result_color
	_approve_button.disabled = true
	_reject_button.disabled = true
	_waiting_label.visible = false

	# Auto-close after delay
	await get_tree().create_timer(2.0).timeout
	hide_voting()


func _on_approve_pressed() -> void:
	if _has_voted:
		return

	_has_voted = true
	_approve_button.disabled = true
	_reject_button.disabled = true
	_waiting_label.visible = true
	_waiting_label.text = "Vote submitted (Approve)"

	vote_submitted.emit(true)
	print("[VotingUI] Local player voted: Approve")

	# Submit to network
	_submit_vote_to_network(true)


func _on_reject_pressed() -> void:
	if _has_voted:
		return

	_has_voted = true
	_approve_button.disabled = true
	_reject_button.disabled = true
	_waiting_label.visible = true
	_waiting_label.text = "Vote submitted (Reject)"

	vote_submitted.emit(false)
	print("[VotingUI] Local player voted: Reject")

	# Submit to network
	_submit_vote_to_network(false)


func _submit_vote_to_network(approve: bool) -> void:
	# Call EvidenceManager to submit the vote
	if has_node("/root/EvidenceManager"):
		var local_id: int = _get_local_player_id()
		EvidenceManager.vote_for_identification(local_id, approve)


func _get_local_player_id() -> int:
	if multiplayer.has_multiplayer_peer():
		return multiplayer.get_unique_id()
	return 1
