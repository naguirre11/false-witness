extends Control
## Post-match results screen displaying match outcome, entity reveal, and statistics.
##
## Shows: winning team, entity type, cultist identity, evidence collected/missed,
## cultist action timeline, player contributions, and humorous superlatives.
##
## Automatically shows when GameManager enters RESULTS state and receives
## MatchResult data from MatchManager.match_ended signal.

# --- Signals ---

signal return_to_lobby_requested

# --- Constants ---

const RESULTS_STATE: int = 6  # GameManager.GameState.RESULTS

# --- State Variables ---

var _is_active: bool = false

# --- Node References ---

@onready var _win_loss_label: Label = %WinLossLabel
@onready var _win_condition_label: Label = %WinConditionLabel
@onready var _match_duration_label: Label = %MatchDurationLabel
@onready var _entity_name: Label = %EntityName
@onready var _evidence_list: VBoxContainer = %EvidenceList
@onready var _cultist_name: Label = %CultistName
@onready var _cultist_status: Label = %CultistStatus
@onready var _timeline_list: VBoxContainer = %TimelineList
@onready var _contrib_list: VBoxContainer = %ContribList
@onready var _superlatives: HBoxContainer = %SuperlativesContainer
@onready var _return_button: Button = %ReturnButton


func _ready() -> void:
	_return_button.pressed.connect(_on_return_pressed)
	_setup_signals()
	hide()


func _setup_signals() -> void:
	# Connect to EventBus signals
	if has_node("/root/EventBus"):
		EventBus.game_state_changed.connect(_on_game_state_changed)
		EventBus.match_ended.connect(_on_match_ended)

	# Connect to MatchManager if available
	if has_node("/root/MatchManager"):
		if MatchManager.has_signal("match_ended"):
			MatchManager.match_ended.connect(_on_match_result_received)


func _on_game_state_changed(old_state: int, new_state: int) -> void:
	if new_state == RESULTS_STATE:
		# Show results screen
		show()
		_is_active = true
		print("[ResultsScreen] RESULTS state entered - showing results screen")
	elif old_state == RESULTS_STATE:
		# Hide results screen
		hide()
		_is_active = false


func _on_match_ended(result: Dictionary) -> void:
	# Receive match result from EventBus
	var match_result := MatchResult.from_dict(result)
	setup(match_result)
	print("[ResultsScreen] Received match result from EventBus")


func _on_match_result_received(result: MatchResult) -> void:
	# Receive match result directly from MatchManager
	setup(result)
	print("[ResultsScreen] Received match result from MatchManager")


## Sets up the results screen with match result data.
func setup(result: MatchResult) -> void:
	_setup_header(result)
	_setup_entity_reveal(result)
	_setup_cultist_reveal(result)
	_setup_timeline(result)
	_setup_contributions(result)
	_setup_superlatives(result)


func _setup_header(result: MatchResult) -> void:
	# Win/Loss header
	if result.did_investigators_win():
		_win_loss_label.text = "INVESTIGATORS WIN!"
		_win_loss_label.modulate = DesignTokens.COLORS.accent_success
	else:
		_win_loss_label.text = "CULTIST WINS!"
		_win_loss_label.modulate = DesignTokens.COLORS.text_danger

	_win_condition_label.text = result.get_win_condition_text()

	# Match duration
	var minutes := int(result.match_duration) / 60
	var seconds := int(result.match_duration) % 60
	_match_duration_label.text = "Match Duration: %d:%02d" % [minutes, seconds]


func _setup_entity_reveal(result: MatchResult) -> void:
	_entity_name.text = result.entity_type if result.entity_type else "Unknown Entity"

	# Clear and rebuild evidence list
	for child in _evidence_list.get_children():
		child.queue_free()

	for evidence in result.entity_evidence:
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		if evidence in result.evidence_collected_correctly:
			label.text = "✓ " + evidence
			label.add_theme_color_override("font_color", DesignTokens.COLORS.accent_success)
		else:
			label.text = "✗ " + evidence + " (missed)"
			label.add_theme_color_override("font_color", DesignTokens.COLORS.text_danger)

		_evidence_list.add_child(label)


func _setup_cultist_reveal(result: MatchResult) -> void:
	_cultist_name.text = result.cultist_username if result.cultist_username else "Unknown"

	# Status based on win condition
	match result.win_condition:
		MatchResult.WinCondition.CULTIST_VOTED_OUT:
			_cultist_status.text = "Was discovered and voted out!"
			_cultist_status.modulate = DesignTokens.COLORS.accent_success
		MatchResult.WinCondition.INNOCENT_VOTED_OUT:
			_cultist_status.text = "Successfully framed an innocent!"
			_cultist_status.modulate = DesignTokens.COLORS.action_ability
		_:
			if result.did_cultist_win():
				_cultist_status.text = "Successfully deceived the team!"
				_cultist_status.modulate = DesignTokens.COLORS.accent_warning
			else:
				_cultist_status.text = "Was not discovered during the match"
				_cultist_status.modulate = DesignTokens.COLORS.text_secondary


func _setup_timeline(result: MatchResult) -> void:
	# Clear existing
	for child in _timeline_list.get_children():
		child.queue_free()

	if result.cultist_actions.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No Cultist actions recorded"
		empty_label.add_theme_color_override("font_color", DesignTokens.COLORS.text_muted)
		empty_label.add_theme_font_size_override("font_size", DesignTokens.FONT_SIZES.xs)
		_timeline_list.add_child(empty_label)
		return

	for action in result.cultist_actions:
		var label := Label.new()
		label.add_theme_font_size_override("font_size", DesignTokens.FONT_SIZES.xs)

		var timestamp: float = action.get("timestamp", 0.0)
		var action_type: String = action.get("type", "unknown")
		var description: String = action.get("description", "")

		var minutes := int(timestamp) / 60
		var seconds := int(timestamp) % 60

		label.text = "%02d:%02d - %s" % [minutes, seconds, description]

		# Color based on action type
		match action_type:
			"contamination":
				label.add_theme_color_override("font_color", DesignTokens.COLORS.action_contamination)
			"ability":
				label.add_theme_color_override("font_color", DesignTokens.COLORS.action_ability)
			"sabotage":
				label.add_theme_color_override("font_color", DesignTokens.COLORS.action_sabotage)
			_:
				label.add_theme_color_override("font_color", DesignTokens.COLORS.text_primary)

		_timeline_list.add_child(label)


func _setup_contributions(result: MatchResult) -> void:
	# Clear existing
	for child in _contrib_list.get_children():
		child.queue_free()

	if result.player_stats.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No player stats recorded"
		empty_label.add_theme_color_override("font_color", DesignTokens.COLORS.text_muted)
		empty_label.add_theme_font_size_override("font_size", DesignTokens.FONT_SIZES.xs)
		_contrib_list.add_child(empty_label)
		return

	# Find top contributor
	var top_player := ""
	var top_evidence := 0
	for player_id in result.player_stats:
		var stats: Dictionary = result.player_stats[player_id]
		var collected: int = stats.get("evidence_collected", 0)
		if collected > top_evidence:
			top_evidence = collected
			top_player = str(player_id)

	# Build player list
	for player_id in result.player_stats:
		var stats: Dictionary = result.player_stats[player_id]
		var label := Label.new()
		label.add_theme_font_size_override("font_size", DesignTokens.FONT_SIZES.xs)

		var player_name: String = stats.get("username", "Player %s" % player_id)
		var collected: int = stats.get("evidence_collected", 0)
		var verified: int = stats.get("evidence_verified", 0)
		var is_echo: bool = stats.get("is_echo", false)

		var prefix := "★ " if str(player_id) == top_player else ""
		var suffix := " (Echo)" if is_echo else ""

		label.text = "%s%s - %d evidence collected (%d verified)%s" % [
			prefix, player_name, collected, verified, suffix
		]

		if is_echo:
			label.add_theme_color_override("font_color", DesignTokens.COLORS.text_muted)

		_contrib_list.add_child(label)


func _setup_superlatives(result: MatchResult) -> void:
	# Clear existing superlatives (keep container structure)
	for child in _superlatives.get_children():
		child.queue_free()

	# Generate superlatives from player stats
	var superlatives: Array[Dictionary] = _generate_superlatives(result)

	for award in superlatives:
		var vbox := VBoxContainer.new()

		var title_label := Label.new()
		title_label.text = "🏆 " + award.get("title", "Award")
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.add_theme_font_size_override("font_size", DesignTokens.FONT_SIZES.xs)
		title_label.add_theme_color_override("font_color", DesignTokens.COLORS.results_gold)
		vbox.add_child(title_label)

		var player_label := Label.new()
		player_label.text = award.get("player", "Unknown")
		player_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		player_label.add_theme_font_size_override("font_size", DesignTokens.FONT_SIZES.sm)
		vbox.add_child(player_label)

		_superlatives.add_child(vbox)


func _generate_superlatives(result: MatchResult) -> Array[Dictionary]:
	var awards: Array[Dictionary] = []

	if result.player_stats.is_empty():
		return awards

	# Find stats for awards
	var most_evidence := 0
	var most_evidence_player := ""
	var most_deaths := 0
	var most_deaths_player := ""
	var fastest_evidence := 999999.0
	var fastest_evidence_player := ""

	for player_id in result.player_stats:
		var stats: Dictionary = result.player_stats[player_id]
		var player_name: String = stats.get("username", "Player %s" % player_id)

		var collected: int = stats.get("evidence_collected", 0)
		if collected > most_evidence:
			most_evidence = collected
			most_evidence_player = player_name

		var deaths: int = stats.get("deaths", 0)
		if deaths > most_deaths:
			most_deaths = deaths
			most_deaths_player = player_name

		var first_evidence_time: float = stats.get("first_evidence_time", 999999.0)
		if first_evidence_time < fastest_evidence:
			fastest_evidence = first_evidence_time
			fastest_evidence_player = player_name

	# Add awards (max 3)
	if most_evidence_player:
		awards.append({"title": "Evidence Hunter", "player": most_evidence_player})

	if fastest_evidence_player and fastest_evidence < 999999.0:
		awards.append({"title": "Speed Demon", "player": fastest_evidence_player})

	if most_deaths_player and most_deaths > 0:
		awards.append({"title": "Most Screams", "player": most_deaths_player})

	# Fill with random awards if needed
	var fallback_awards: Array[String] = ["Lucky Survivor", "Team Player", "Eagle Eye"]
	var players: Array = result.player_stats.keys()

	while awards.size() < 2 and not players.is_empty():
		var idx := randi() % fallback_awards.size()
		var player_idx := randi() % players.size()
		var stats: Dictionary = result.player_stats[players[player_idx]]
		awards.append({
			"title": fallback_awards[idx],
			"player": stats.get("username", "Player")
		})
		fallback_awards.remove_at(idx)

	return awards


func _on_return_pressed() -> void:
	return_to_lobby_requested.emit()

	# Transition back to lobby
	if has_node("/root/LobbyManager"):
		var lobby_manager := get_node("/root/LobbyManager")
		if lobby_manager.has_method("reset_for_rematch"):
			lobby_manager.reset_for_rematch()

	# Change scene to lobby
	get_tree().change_scene_to_file("res://scenes/ui/lobby_screen.tscn")
