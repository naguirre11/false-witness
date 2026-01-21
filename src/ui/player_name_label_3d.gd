extends Node3D
## 3D label that shows player name above their head and Cultist indicator when discovered.
##
## Billboards to always face the camera.
## Shows player name normally, adds "CULTIST" indicator when discovered.

# --- Constants ---

## Color for normal player name.
const NAME_COLOR := Color(1.0, 1.0, 1.0, 1.0)

## Color for discovered Cultist indicator and name.
const CULTIST_COLOR := Color(0.9, 0.15, 0.15, 1.0)

## Outline color for visibility.
const OUTLINE_COLOR := Color(0.0, 0.0, 0.0, 1.0)

## Font size for player name.
const NAME_FONT_SIZE := 16

## Font size for Cultist indicator.
const CULTIST_FONT_SIZE := 20

## Height offset above player head for name.
const NAME_HEIGHT_OFFSET := 0.3

## Height offset for Cultist indicator (above name).
const CULTIST_HEIGHT_OFFSET := 0.5

# --- State ---

var _player_id: int = -1
var _player_name: String = ""
var _is_discovered_cultist: bool = false

# --- Node References ---

var _name_label: Label3D
var _cultist_label: Label3D


func _ready() -> void:
	_setup_labels()
	_connect_signals()


func _setup_labels() -> void:
	# Name label - always visible when player has a name
	_name_label = Label3D.new()
	_name_label.name = "NameLabel3D"
	_name_label.font_size = NAME_FONT_SIZE
	_name_label.modulate = NAME_COLOR
	_name_label.outline_modulate = OUTLINE_COLOR
	_name_label.outline_size = 2
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.no_depth_test = true
	_name_label.position.y = NAME_HEIGHT_OFFSET
	_name_label.visible = false
	add_child(_name_label)

	# Cultist indicator - only visible when discovered
	_cultist_label = Label3D.new()
	_cultist_label.name = "CultistLabel3D"
	_cultist_label.text = "CULTIST"
	_cultist_label.font_size = CULTIST_FONT_SIZE
	_cultist_label.modulate = CULTIST_COLOR
	_cultist_label.outline_modulate = OUTLINE_COLOR
	_cultist_label.outline_size = 4
	_cultist_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_cultist_label.no_depth_test = true
	_cultist_label.position.y = CULTIST_HEIGHT_OFFSET
	_cultist_label.visible = false
	add_child(_cultist_label)


func _connect_signals() -> void:
	# Connect to CultistManager signals
	if has_node("/root/CultistManager"):
		var cultist_manager := get_node("/root/CultistManager")
		if cultist_manager.has_signal("cultist_discovered"):
			cultist_manager.cultist_discovered.connect(_on_cultist_discovered)


## Sets the player ID this label is tracking.
func set_player_id(player_id: int) -> void:
	_player_id = player_id
	# Check if already discovered
	_check_discovery_state()


## Gets the player ID this label is tracking.
func get_player_id() -> int:
	return _player_id


## Sets the player name to display.
func set_player_name(player_name: String) -> void:
	_player_name = player_name
	if _name_label:
		_name_label.text = player_name
		_name_label.visible = player_name.length() > 0
		_update_label_positions()


## Gets the player name being displayed.
func get_player_name() -> String:
	return _player_name


func _on_cultist_discovered(discovered_player_id: int) -> void:
	if discovered_player_id == _player_id:
		_show_cultist_indicator()


func _show_cultist_indicator() -> void:
	if _is_discovered_cultist:
		return

	_is_discovered_cultist = true

	if _cultist_label:
		_cultist_label.visible = true
		_animate_cultist_appear()

	# Change name label color to red
	if _name_label:
		_name_label.modulate = CULTIST_COLOR

	_update_label_positions()


func _check_discovery_state() -> void:
	if _player_id < 0:
		return

	if has_node("/root/CultistManager"):
		var cultist_manager := get_node("/root/CultistManager")
		if cultist_manager.has_method("is_cultist_discovered"):
			var is_discovered: bool = cultist_manager.is_cultist_discovered(_player_id)
			if is_discovered:
				_show_cultist_indicator()


func _update_label_positions() -> void:
	# If Cultist indicator is showing, move name label down slightly
	if _name_label:
		_name_label.position.y = NAME_HEIGHT_OFFSET

	if _cultist_label and _is_discovered_cultist:
		_cultist_label.position.y = CULTIST_HEIGHT_OFFSET


func _animate_cultist_appear() -> void:
	if not _cultist_label:
		return

	# Simple fade in animation with scale pop
	var tween := create_tween()
	_cultist_label.modulate.a = 0.0
	_cultist_label.scale = Vector3(1.5, 1.5, 1.5)
	tween.tween_property(_cultist_label, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(_cultist_label, "scale", Vector3.ONE, 0.3)


## Returns true if this player has been discovered as a Cultist.
func is_discovered() -> bool:
	return _is_discovered_cultist
