extends Control
## Lobby screen UI showing players, ready states, and host controls.
## Connects to LobbyManager to display and update lobby state.

const PlayerSlotUI = preload("res://scenes/ui/player_slot_ui.tscn")
const MAX_SLOTS: int = 6


@onready var _lobby_code_label: Label = %LobbyCodeLabel
@onready var _player_slots_container: VBoxContainer = %PlayerSlotsContainer
@onready var _player_count_label: Label = %PlayerCountLabel
@onready var _ready_count_label: Label = %ReadyCountLabel
@onready var _leave_btn: Button = %LeaveButton
@onready var _ready_btn: Button = %ReadyButton
@onready var _start_btn: Button = %StartGameButton


var _player_slots: Array = []
var _is_ready: bool = false


func _ready() -> void:
	_setup_player_slots()
	_connect_buttons()
	_connect_lobby_signals()
	_refresh_from_lobby_state()


func _setup_player_slots() -> void:
	# Clear any existing children
	for child in _player_slots_container.get_children():
		child.queue_free()
	_player_slots.clear()

	# Create 6 player slot UI instances
	for i in range(MAX_SLOTS):
		var slot_ui: HBoxContainer = PlayerSlotUI.instantiate()
		_player_slots_container.add_child(slot_ui)
		slot_ui.set_slot_index(i)
		_player_slots.append(slot_ui)


func _connect_buttons() -> void:
	_leave_btn.pressed.connect(_on_leave_pressed)
	_ready_btn.pressed.connect(_on_ready_pressed)
	_start_btn.pressed.connect(_on_start_pressed)


func _connect_lobby_signals() -> void:
	LobbyManager.player_slot_updated.connect(_on_player_slot_updated)
	LobbyManager.player_ready_changed.connect(_on_player_ready_changed)
	LobbyManager.host_changed.connect(_on_host_changed)
	LobbyManager.all_players_ready.connect(_on_all_players_ready)
	LobbyManager.lobby_state_updated.connect(_on_lobby_state_updated)
	LobbyManager.lobby_closed.connect(_on_lobby_closed)


func _refresh_from_lobby_state() -> void:
	# Get current lobby state and update UI
	var slots: Array = LobbyManager.get_slots()

	for i in range(slots.size()):
		var slot: Resource = slots[i]
		_update_slot_ui(i, slot)

	_update_counts()
	_update_host_controls()

	# Set lobby code (placeholder - actual code from network layer)
	_lobby_code_label.text = "------"


func _update_slot_ui(index: int, slot: Resource) -> void:
	if index < 0 or index >= _player_slots.size():
		return

	var slot_ui: HBoxContainer = _player_slots[index]

	if slot.is_occupied():
		slot_ui.set_player(slot.username, slot.is_host, slot.is_ready)
	else:
		slot_ui.clear()


func _update_counts() -> void:
	var player_count: int = LobbyManager.get_player_count()
	var ready_count: int = _count_ready_players()

	_player_count_label.text = "Players: %d/%d" % [player_count, MAX_SLOTS]
	_ready_count_label.text = "Ready: %d/%d" % [ready_count, player_count]


func _count_ready_players() -> int:
	var count: int = 0
	var slots: Array = LobbyManager.get_slots()
	for slot in slots:
		if slot.is_occupied() and slot.is_ready:
			count += 1
	return count


func _update_host_controls() -> void:
	_start_btn.visible = LobbyManager.is_lobby_host
	_start_btn.disabled = not LobbyManager.can_start_game()

	# Update start button text with player count
	var player_count: int = LobbyManager.get_player_count()
	var ready_count: int = _count_ready_players()
	_start_btn.text = "Start Game (%d/%d Ready)" % [ready_count, player_count]


# --- Signal Handlers ---


func _on_player_slot_updated(slot_index: int, slot: Resource) -> void:
	_update_slot_ui(slot_index, slot)
	_update_counts()
	_update_host_controls()


func _on_player_ready_changed(_peer_id: int, _is_ready_state: bool) -> void:
	_update_counts()
	_update_host_controls()


func _on_host_changed(_new_host_peer_id: int, _new_host_username: String) -> void:
	_refresh_from_lobby_state()


func _on_all_players_ready(_can_start: bool) -> void:
	_update_host_controls()


func _on_lobby_state_updated(_slots: Array) -> void:
	_refresh_from_lobby_state()


func _on_lobby_closed(_reason: String) -> void:
	# Return to main menu
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


# --- Button Handlers ---


func _on_leave_pressed() -> void:
	LobbyManager.leave_lobby()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_ready_pressed() -> void:
	_is_ready = not _is_ready
	LobbyManager.set_ready(_is_ready)
	_ready_btn.text = "Unready" if _is_ready else "Ready"


func _on_start_pressed() -> void:
	if LobbyManager.can_start_game():
		LobbyManager.start_game()


## Sets the lobby code display.
func set_lobby_code(code: String) -> void:
	_lobby_code_label.text = code
