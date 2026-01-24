extends CanvasLayer
## Deliberation phase UI overlay.
##
## Displays:
## - Countdown timer prominently
## - "Propose Identification" button
## - Current proposal status (if any)
## - Evidence board access

# --- Signals ---

signal propose_identification_pressed
signal evidence_board_toggle_pressed

# --- Constants ---

const DELIBERATION_STATE: int = 5

# --- State Variables ---

var _is_active: bool = false
var _current_proposal: Dictionary = {}  # {entity_type, submitter_name, votes_for, votes_against}
var _time_warning_shown: bool = false

# --- Node References ---

@onready var _container: Control = $UIContainer
@onready var _timer_label: Label = %TimerLabel
@onready var _phase_title: Label = %PhaseTitle
@onready var _propose_button: Button = %ProposeButton
@onready var _proposal_panel: PanelContainer = %ProposalPanel
@onready var _proposal_text: Label = %ProposalText
@onready var _vote_progress: Label = %VoteProgress
@onready var _evidence_button: Button = %EvidenceBoardButton
@onready var _warning_label: Label = %WarningLabel


func _ready() -> void:
	_setup_signals()
	_reset_ui()
	hide()


func _setup_signals() -> void:
	# Connect to EventBus signals
	if has_node("/root/EventBus"):
		EventBus.game_state_changed.connect(_on_game_state_changed)
		EventBus.phase_timer_tick.connect(_on_timer_tick)

		# Identification signals
		if EventBus.has_signal("identification_submitted"):
			EventBus.connect("identification_submitted", _on_identification_submitted)

	# Button signals
	if _propose_button:
		_propose_button.pressed.connect(_on_propose_button_pressed)

	if _evidence_button:
		_evidence_button.pressed.connect(_on_evidence_button_pressed)


# --- Public API ---


## Shows the deliberation UI.
func show_deliberation_ui() -> void:
	_is_active = true
	_reset_ui()
	show()
	_propose_button.grab_focus()
	print("[DeliberationUI] Shown")


## Hides the deliberation UI.
func hide_deliberation_ui() -> void:
	_is_active = false
	hide()
	print("[DeliberationUI] Hidden")


## Updates the timer display.
func update_timer(time_remaining: float) -> void:
	var minutes := int(time_remaining) / 60
	var seconds := int(time_remaining) % 60
	_timer_label.text = "%d:%02d" % [minutes, seconds]

	# Visual warning when time low
	if time_remaining <= 60.0 and not _time_warning_shown:
		_time_warning_shown = true
		_warning_label.visible = true
		_warning_label.text = "Time running out!"
		_timer_label.modulate = Color(1.0, 0.3, 0.3)
	elif time_remaining <= 30.0:
		_timer_label.modulate = Color(1.0, 0.1, 0.1)
		_warning_label.text = "HURRY!"


## Shows the current proposal status.
func show_proposal(entity_type: String, submitter_name: String) -> void:
	_current_proposal = {
		"entity_type": entity_type,
		"submitter_name": submitter_name,
		"votes_for": 0,
		"votes_against": 0,
	}

	_proposal_panel.visible = true
	_proposal_text.text = "%s proposes: %s" % [submitter_name, entity_type]
	_vote_progress.text = "Votes: 0/? needed"

	# Disable propose button while proposal active
	_propose_button.disabled = true


## Updates the vote count display.
func update_vote_progress(votes_for: int, votes_needed: int, votes_against: int) -> void:
	_current_proposal["votes_for"] = votes_for
	_current_proposal["votes_against"] = votes_against
	_vote_progress.text = "Approve: %d/%d | Reject: %d" % [votes_for, votes_needed, votes_against]


## Clears the current proposal (approved, rejected, or cancelled).
func clear_proposal() -> void:
	_current_proposal.clear()
	_proposal_panel.visible = false
	_propose_button.disabled = false


## Returns true if deliberation UI is currently active.
func is_active() -> bool:
	return _is_active


# --- Signal Handlers ---


func _on_game_state_changed(old_state: int, new_state: int) -> void:
	if new_state == DELIBERATION_STATE:
		show_deliberation_ui()
	elif old_state == DELIBERATION_STATE:
		hide_deliberation_ui()


func _on_timer_tick(time_remaining: float) -> void:
	if _is_active:
		update_timer(time_remaining)


func _on_propose_button_pressed() -> void:
	propose_identification_pressed.emit()
	print("[DeliberationUI] Propose identification button pressed")


func _on_evidence_button_pressed() -> void:
	evidence_board_toggle_pressed.emit()
	print("[DeliberationUI] Evidence board button pressed")


func _on_identification_submitted(entity_type: String, submitter_id: int) -> void:
	# Get submitter name
	var submitter_name: String = "Player %d" % submitter_id
	if has_node("/root/LobbyManager"):
		var slot: Resource = LobbyManager.get_slot_by_peer_id(submitter_id)
		if slot:
			submitter_name = slot.username

	show_proposal(entity_type, submitter_name)


# --- Internal Methods ---


func _reset_ui() -> void:
	_time_warning_shown = false
	_timer_label.modulate = Color.WHITE
	_warning_label.visible = false
	clear_proposal()
	_propose_button.disabled = false
