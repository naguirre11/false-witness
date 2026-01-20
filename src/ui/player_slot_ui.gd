extends HBoxContainer
## Displays a single player slot in the lobby.
## Shows slot number, player name, host indicator, and ready status.


@onready var _slot_number_label: Label = %SlotNumberLabel
@onready var _host_crown_label: Label = %HostCrownLabel
@onready var _player_name_label: Label = %PlayerNameLabel
@onready var _ready_indicator: Label = %ReadyIndicator


var _slot_index: int = 0
var _is_occupied: bool = false


func _ready() -> void:
	clear()


## Sets the slot index (0-5), displays as 1-6.
func set_slot_index(index: int) -> void:
	_slot_index = index
	_slot_number_label.text = "%d." % (index + 1)


## Clears the slot to empty state.
func clear() -> void:
	_is_occupied = false
	_player_name_label.text = "Empty"
	_player_name_label.modulate = Color(0.5, 0.5, 0.5, 1.0)
	_host_crown_label.visible = false
	_ready_indicator.text = ""


## Updates the slot with player data.
func set_player(username: String, is_host: bool, is_ready: bool) -> void:
	_is_occupied = true
	_player_name_label.text = username
	_player_name_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_host_crown_label.visible = is_host
	_update_ready_state(is_ready)


## Updates just the ready state.
func set_ready(is_ready: bool) -> void:
	if _is_occupied:
		_update_ready_state(is_ready)


## Updates the host indicator.
func set_host(is_host: bool) -> void:
	_host_crown_label.visible = is_host


func _update_ready_state(is_ready: bool) -> void:
	if is_ready:
		_ready_indicator.text = "[Ready]"
		_ready_indicator.modulate = Color(0.3, 0.9, 0.3, 1.0)
	else:
		_ready_indicator.text = "[Not Ready]"
		_ready_indicator.modulate = Color(0.9, 0.5, 0.3, 1.0)


## Returns true if the slot has a player.
func is_occupied() -> bool:
	return _is_occupied


## Returns the slot index.
func get_slot_index() -> int:
	return _slot_index
