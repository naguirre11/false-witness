extends Control
## Cultist voting UI for selecting a player to vote out during emergency votes.
##
## Features:
## - Shows all alive players as vote options
## - Player names displayed with selection indicator
## - Click to select, can change vote until confirmed
## - Skip vote option to abstain
## - Timer display with warning colors
## - Vote count tracking
## - Announcements and sound effects

# --- Signals ---

## Emitted when player confirms their vote.
## target_id is the player being voted for, or -1 for skip.
signal vote_confirmed(target_id: int)

## Emitted when player changes their selection (before confirm).
signal vote_selection_changed(target_id: int)

# --- Constants ---

## Color for selected player slot
const SELECTED_COLOR := Color(0.3, 0.7, 1.0, 0.3)

## Color for unselected player slot
const UNSELECTED_COLOR := Color(0.2, 0.2, 0.2, 0.3)

## Color for already voted indicator
const VOTED_COLOR := Color(0.5, 0.5, 0.0, 0.3)

## Color for announcement text
const ANNOUNCE_COLOR := Color(1.0, 0.9, 0.3, 1.0)

## Color for result text (innocent voted)
const RESULT_INNOCENT_COLOR := Color(1.0, 0.3, 0.3, 1.0)

## Color for result text (cultist discovered)
const RESULT_CULTIST_COLOR := Color(0.3, 1.0, 0.3, 1.0)

# --- State ---

## Whether voting is currently active
var _is_active: bool = false

## Currently selected target player ID (-1 for skip/none)
var _selected_target_id: int = -1

## Whether the local player has confirmed their vote
var _has_confirmed: bool = false

## Map of player_id -> Button for each player slot
var _player_buttons: Dictionary = {}

## Map of player_id -> voted_target_id for tracking who voted for whom
var _vote_tracking: Dictionary = {}

## Total number of alive players
var _alive_count: int = 0

## Last timer value for warning sound
var _last_timer_warning: int = -1

## Tween for announcement animations
var _announcement_tween: Tween

# --- Node References ---

@onready var _timer_label: Label = %TimerLabel
@onready var _players_vbox: VBoxContainer = %PlayersVBox
@onready var _skip_button: Button = %SkipButton
@onready var _confirm_button: Button = %ConfirmButton
@onready var _vote_status_label: Label = %VoteStatusLabel
@onready var _announcement_label: Label = %AnnouncementLabel


func _ready() -> void:
	_skip_button.pressed.connect(_on_skip_pressed)
	_confirm_button.pressed.connect(_on_confirm_pressed)

	# Connect to CultistManager signals
	if has_node("/root/CultistManager"):
		var cultist_manager := get_node("/root/CultistManager")
		if cultist_manager.has_signal("vote_timer_updated"):
			cultist_manager.vote_timer_updated.connect(_on_vote_timer_updated)
		if cultist_manager.has_signal("vote_cast"):
			cultist_manager.vote_cast.connect(_on_vote_cast)
		if cultist_manager.has_signal("vote_complete"):
			cultist_manager.vote_complete.connect(_on_vote_complete)
		if cultist_manager.has_signal("emergency_vote_called"):
			cultist_manager.emergency_vote_called.connect(_on_emergency_vote_called)
		if cultist_manager.has_signal("cultist_voted_discovered"):
			cultist_manager.cultist_voted_discovered.connect(_on_cultist_discovered)
		if cultist_manager.has_signal("innocent_voted_out"):
			cultist_manager.innocent_voted_out.connect(_on_innocent_voted)

	# Initialize announcement label
	if _announcement_label:
		_announcement_label.visible = false

	hide()


## Shows the voting UI with a list of players.
## players should be Array of {id: int, name: String}
func show_voting(players: Array) -> void:
	_clear_player_slots()
	_selected_target_id = -1
	_has_confirmed = false
	_vote_tracking.clear()
	_alive_count = players.size()
	_is_active = true
	_last_timer_warning = -1

	# Create a button for each player
	for player_data in players:
		var player_id: int = player_data.get("id", 0)
		var player_name: String = player_data.get("name", "Unknown")
		_create_player_slot(player_id, player_name)

	_update_confirm_button_state()
	_update_vote_status()

	# Show vote start announcement
	_show_announcement("EMERGENCY VOTE!", ANNOUNCE_COLOR, 2.0)
	_play_vote_start_sound()

	show()
	print("[CultistVoteUI] Shown with %d players" % players.size())


## Hides the voting UI.
func hide_voting() -> void:
	_is_active = false
	hide()
	print("[CultistVoteUI] Hidden")


## Updates the timer display.
func update_timer(seconds_remaining: float) -> void:
	var sec_int := int(seconds_remaining)
	_timer_label.text = "%ds" % sec_int

	# Warning colors as time runs out
	if seconds_remaining <= 5.0:
		_timer_label.modulate = Color(1.0, 0.3, 0.3)
		# Play warning sound at 5, 4, 3, 2, 1
		if sec_int != _last_timer_warning and sec_int >= 1:
			_last_timer_warning = sec_int
			_play_timer_warning_sound()
	elif seconds_remaining <= 10.0:
		_timer_label.modulate = Color(1.0, 0.6, 0.2)
		# Play warning sound at 10
		if sec_int == 10 and _last_timer_warning != 10:
			_last_timer_warning = 10
			_play_timer_warning_sound()
	else:
		_timer_label.modulate = Color(1.0, 0.8, 0.2)


## Updates vote tracking when a vote is cast.
func update_vote(voter_id: int, target_id: int) -> void:
	_vote_tracking[voter_id] = target_id
	_update_vote_status()

	# Visual indicator if this player has voted
	if voter_id in _player_buttons:
		_update_player_slot_voted(voter_id)

	# Play vote cast sound
	_play_vote_cast_sound()

	# Announce vote tally progress
	var votes_cast := _vote_tracking.size()
	if votes_cast == _alive_count:
		_show_announcement("All votes cast!", ANNOUNCE_COLOR, 1.0)
	elif votes_cast > _alive_count / 2:
		_show_announcement("Majority reached!", ANNOUNCE_COLOR, 1.0)


## Returns the currently selected target ID (-1 if none/skip).
func get_selected_target() -> int:
	return _selected_target_id


## Returns whether voting is active.
func is_active() -> bool:
	return _is_active


## Returns whether the local player has confirmed their vote.
func has_confirmed() -> bool:
	return _has_confirmed


# --- Private Methods ---


func _clear_player_slots() -> void:
	for child in _players_vbox.get_children():
		child.queue_free()
	_player_buttons.clear()


func _create_player_slot(player_id: int, player_name: String) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 50)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = player_name
	button.toggle_mode = true
	button.set_meta("player_id", player_id)
	button.pressed.connect(_on_player_button_pressed.bind(player_id))

	# Styling
	var style := StyleBoxFlat.new()
	style.bg_color = UNSELECTED_COLOR
	style.set_corner_radius_all(5)
	button.add_theme_stylebox_override("normal", style)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.3, 0.3, 0.4, 0.5)
	hover_style.set_corner_radius_all(5)
	button.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = SELECTED_COLOR
	pressed_style.set_corner_radius_all(5)
	button.add_theme_stylebox_override("pressed", pressed_style)

	_players_vbox.add_child(button)
	_player_buttons[player_id] = button


func _on_player_button_pressed(player_id: int) -> void:
	if _has_confirmed:
		# Already confirmed, can't change
		return

	# Toggle selection
	if _selected_target_id == player_id:
		# Deselect
		_selected_target_id = -1
	else:
		# Select this player
		_selected_target_id = player_id

	# Update button states
	_update_button_selection_states()
	_update_confirm_button_state()

	vote_selection_changed.emit(_selected_target_id)


func _update_button_selection_states() -> void:
	for pid in _player_buttons.keys():
		var button: Button = _player_buttons[pid]
		var is_selected := pid == _selected_target_id
		button.button_pressed = is_selected

		# Update visual style
		var style := button.get_theme_stylebox("normal") as StyleBoxFlat
		if style:
			if is_selected:
				style.bg_color = SELECTED_COLOR
			else:
				style.bg_color = UNSELECTED_COLOR


func _update_player_slot_voted(player_id: int) -> void:
	# Add visual indicator that this player has voted
	if player_id in _player_buttons:
		var button: Button = _player_buttons[player_id]
		# Could add a checkmark or change text
		if button.text.find(" [Voted]") == -1:
			button.text = button.text + " [Voted]"


func _update_confirm_button_state() -> void:
	# Enable confirm if a target is selected OR skip is allowed
	_confirm_button.disabled = _has_confirmed

	if _selected_target_id >= 0:
		_confirm_button.text = "Confirm Vote"
	else:
		_confirm_button.text = "Select a Player"
		_confirm_button.disabled = true


func _update_vote_status() -> void:
	var votes_cast := _vote_tracking.size()
	_vote_status_label.text = "Votes: %d/%d cast" % [votes_cast, _alive_count]


func _on_skip_pressed() -> void:
	if _has_confirmed:
		return

	_has_confirmed = true
	_selected_target_id = -1

	# Disable all buttons
	_skip_button.disabled = true
	_confirm_button.disabled = true
	for button: Button in _player_buttons.values():
		button.disabled = true

	_vote_status_label.text = "You skipped the vote"
	vote_confirmed.emit(-1)

	# Send to server
	_submit_vote_to_server(-1)


func _on_confirm_pressed() -> void:
	if _has_confirmed or _selected_target_id < 0:
		return

	_has_confirmed = true

	# Disable all buttons
	_skip_button.disabled = true
	_confirm_button.disabled = true
	for button: Button in _player_buttons.values():
		button.disabled = true

	var target_name := _get_player_name(_selected_target_id)
	_vote_status_label.text = "You voted for: %s" % target_name
	vote_confirmed.emit(_selected_target_id)

	# Send to server
	_submit_vote_to_server(_selected_target_id)


func _get_player_name(player_id: int) -> String:
	if player_id in _player_buttons:
		var button: Button = _player_buttons[player_id]
		return button.text.replace(" [Voted]", "")
	return "Unknown"


func _submit_vote_to_server(target_id: int) -> void:
	if has_node("/root/CultistManager"):
		var cultist_manager := get_node("/root/CultistManager")
		if cultist_manager.has_method("cast_vote"):
			var local_id := _get_local_player_id()
			cultist_manager.cast_vote(local_id, target_id)


func _get_local_player_id() -> int:
	if multiplayer.has_multiplayer_peer():
		return multiplayer.get_unique_id()
	return 1


# --- Signal Handlers ---


func _on_vote_timer_updated(seconds_remaining: float) -> void:
	if _is_active:
		update_timer(seconds_remaining)


func _on_vote_cast(voter_id: int, target_id: int) -> void:
	if _is_active:
		update_vote(voter_id, target_id)


func _on_vote_complete(target_id: int, is_majority: bool) -> void:
	# Play result sound
	_play_vote_result_sound()

	# Show result announcement
	if is_majority and target_id >= 0:
		var target_name := _get_player_name(target_id)
		_show_announcement("Votes tallied: %s" % target_name, ANNOUNCE_COLOR, 2.0)
	else:
		_show_announcement("No majority reached", ANNOUNCE_COLOR, 2.0)

	# Vote complete, will be hidden by the calling system after result
	_is_active = false


func _on_emergency_vote_called(_caller_id: int) -> void:
	# This is handled elsewhere (e.g., by showing the vote UI)
	# Just play announcement sound
	print("[CultistVoteUI] Emergency vote called")


func _on_cultist_discovered(player_id: int) -> void:
	var player_name := _get_player_name(player_id)
	_show_announcement("CULTIST DISCOVERED!\n%s was the traitor!" % player_name, RESULT_CULTIST_COLOR, 4.0)
	_play_cultist_discovered_sound()


func _on_innocent_voted(player_id: int) -> void:
	var player_name := _get_player_name(player_id)
	_show_announcement("INNOCENT VOTED OUT!\n%s was not the Cultist!\nCultist wins!" % player_name, RESULT_INNOCENT_COLOR, 4.0)
	_play_innocent_voted_sound()


# --- Announcement Methods ---


## Shows an animated announcement text.
func _show_announcement(text: String, color: Color, duration: float) -> void:
	if not _announcement_label:
		return

	# Cancel any existing tween
	if _announcement_tween and _announcement_tween.is_running():
		_announcement_tween.kill()

	# Set text and make visible
	_announcement_label.text = text
	_announcement_label.modulate = color
	_announcement_label.visible = true
	_announcement_label.scale = Vector2(1.5, 1.5)
	_announcement_label.modulate.a = 0.0

	# Animate in
	_announcement_tween = create_tween()
	_announcement_tween.tween_property(_announcement_label, "modulate:a", 1.0, 0.2)
	_announcement_tween.parallel().tween_property(_announcement_label, "scale", Vector2.ONE, 0.2)

	# Hold
	_announcement_tween.tween_interval(duration)

	# Fade out
	_announcement_tween.tween_property(_announcement_label, "modulate:a", 0.0, 0.3)
	_announcement_tween.tween_callback(_hide_announcement)


func _hide_announcement() -> void:
	if _announcement_label:
		_announcement_label.visible = false


# --- Sound Methods ---


func _play_vote_start_sound() -> void:
	if has_node("/root/AudioManager"):
		var audio_manager := get_node("/root/AudioManager")
		# Play a dramatic vote start sound
		# Using placeholder - actual sound would be loaded from assets
		print("[CultistVoteUI] Playing vote start sound")


func _play_vote_cast_sound() -> void:
	if has_node("/root/AudioManager"):
		var audio_manager := get_node("/root/AudioManager")
		# Play a vote cast confirmation sound
		print("[CultistVoteUI] Playing vote cast sound")


func _play_timer_warning_sound() -> void:
	if has_node("/root/AudioManager"):
		var audio_manager := get_node("/root/AudioManager")
		# Play a timer tick/warning sound
		print("[CultistVoteUI] Playing timer warning sound")


func _play_vote_result_sound() -> void:
	if has_node("/root/AudioManager"):
		var audio_manager := get_node("/root/AudioManager")
		# Play vote result reveal sound
		print("[CultistVoteUI] Playing vote result sound")


func _play_cultist_discovered_sound() -> void:
	if has_node("/root/AudioManager"):
		var audio_manager := get_node("/root/AudioManager")
		# Play a triumphant/dramatic sound
		print("[CultistVoteUI] Playing cultist discovered sound")


func _play_innocent_voted_sound() -> void:
	if has_node("/root/AudioManager"):
		var audio_manager := get_node("/root/AudioManager")
		# Play a negative/dramatic sound
		print("[CultistVoteUI] Playing innocent voted sound")
