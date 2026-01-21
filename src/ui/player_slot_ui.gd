extends HBoxContainer
## Displays a single player slot in the lobby/player list.
## Shows slot number, player name, host indicator, ready status, and Cultist indicator.

# --- Constants ---

## Color for discovered Cultist indicator.
const CULTIST_COLOR := Color(0.9, 0.15, 0.15, 1.0)

# --- State Variables ---

var _slot_index: int = 0
var _is_occupied: bool = false
var _player_id: int = -1
var _is_discovered_cultist: bool = false

# --- Node References ---

@onready var _slot_number_label: Label = %SlotNumberLabel
@onready var _host_crown_label: Label = %HostCrownLabel
@onready var _player_name_label: Label = %PlayerNameLabel
@onready var _ready_indicator: Label = %ReadyIndicator
@onready var _cultist_indicator: Label = %CultistIndicator


func _ready() -> void:
	_connect_signals()
	clear()


func _connect_signals() -> void:
	# Connect to CultistManager signals
	if has_node("/root/CultistManager"):
		var cultist_manager := get_node("/root/CultistManager")
		if cultist_manager.has_signal("cultist_discovered"):
			cultist_manager.cultist_discovered.connect(_on_cultist_discovered)


## Sets the slot index (0-5), displays as 1-6.
func set_slot_index(index: int) -> void:
	_slot_index = index
	_slot_number_label.text = "%d." % (index + 1)


## Clears the slot to empty state.
func clear() -> void:
	_is_occupied = false
	_player_id = -1
	_is_discovered_cultist = false
	_player_name_label.text = "Empty"
	_player_name_label.modulate = Color(0.5, 0.5, 0.5, 1.0)
	_host_crown_label.visible = false
	_ready_indicator.text = ""
	_update_cultist_indicator()


## Updates the slot with player data.
func set_player(username: String, is_host: bool, is_ready: bool) -> void:
	_is_occupied = true
	_player_name_label.text = username
	_player_name_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_host_crown_label.visible = is_host
	_update_ready_state(is_ready)
	_update_cultist_indicator()


## Sets the player ID for this slot (for Cultist tracking).
func set_player_id(player_id: int) -> void:
	_player_id = player_id
	# Check if this player is already a discovered Cultist
	_check_discovery_state()


## Returns the player ID for this slot.
func get_player_id() -> int:
	return _player_id


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


## Marks this slot's player as a discovered Cultist.
func set_discovered_cultist(is_discovered: bool) -> void:
	_is_discovered_cultist = is_discovered
	_update_cultist_indicator()
	# Also change name color to red when discovered
	if _is_occupied and _is_discovered_cultist:
		_player_name_label.modulate = CULTIST_COLOR


func _on_cultist_discovered(discovered_player_id: int) -> void:
	if discovered_player_id == _player_id:
		set_discovered_cultist(true)


func _check_discovery_state() -> void:
	if _player_id < 0:
		return

	if has_node("/root/CultistManager"):
		var cultist_manager := get_node("/root/CultistManager")
		if cultist_manager.has_method("is_cultist_discovered"):
			var is_discovered: bool = cultist_manager.is_cultist_discovered(_player_id)
			if is_discovered:
				set_discovered_cultist(true)


func _update_cultist_indicator() -> void:
	if not _cultist_indicator:
		return

	if _is_discovered_cultist and _is_occupied:
		_cultist_indicator.text = "[CULTIST]"
		_cultist_indicator.modulate = CULTIST_COLOR
		_cultist_indicator.visible = true
	else:
		_cultist_indicator.text = ""
		_cultist_indicator.visible = false
