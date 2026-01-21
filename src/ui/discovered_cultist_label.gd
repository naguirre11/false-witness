extends Node3D
## 3D label that appears above a discovered Cultist's head.
##
## Shows "CULTIST" in red text, visible to all players.
## Automatically hides when not discovered.
## Billboards to always face the camera.

# --- Constants ---

## Text to display above discovered Cultists.
const LABEL_TEXT := "CULTIST"

## Color for the Cultist label (distinctive red).
const LABEL_COLOR := Color(0.9, 0.15, 0.15, 1.0)

## Outline color for visibility.
const OUTLINE_COLOR := Color(0.0, 0.0, 0.0, 1.0)

## Font size for the label.
const FONT_SIZE := 24

## Height offset above player head.
const HEIGHT_OFFSET := 0.4

# --- State ---

var _player_id: int = -1
var _is_visible: bool = false

# --- Node References ---

var _label_3d: Label3D


func _ready() -> void:
	_setup_label()
	_connect_signals()
	# Start hidden
	visible = false


func _setup_label() -> void:
	_label_3d = Label3D.new()
	_label_3d.name = "CultistLabel3D"
	_label_3d.text = LABEL_TEXT
	_label_3d.font_size = FONT_SIZE
	_label_3d.modulate = LABEL_COLOR
	_label_3d.outline_modulate = OUTLINE_COLOR
	_label_3d.outline_size = 4
	_label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_3d.no_depth_test = true  # Always render on top
	_label_3d.position.y = HEIGHT_OFFSET
	add_child(_label_3d)


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
	if _is_player_discovered():
		_show_label()


## Returns the player ID this label is tracking.
func get_player_id() -> int:
	return _player_id


func _on_cultist_discovered(discovered_player_id: int) -> void:
	if discovered_player_id == _player_id:
		_show_label()


func _show_label() -> void:
	if _is_visible:
		return

	_is_visible = true
	visible = true

	# Optional: Animate the label appearing
	_animate_appear()


func _hide_label() -> void:
	if not _is_visible:
		return

	_is_visible = false
	visible = false


func _is_player_discovered() -> bool:
	if _player_id < 0:
		return false

	if has_node("/root/CultistManager"):
		var cultist_manager := get_node("/root/CultistManager")
		if cultist_manager.has_method("is_cultist_discovered"):
			return cultist_manager.is_cultist_discovered(_player_id)

	return false


func _animate_appear() -> void:
	# Simple fade in animation
	var tween := create_tween()
	modulate.a = 0.0
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

	# Optional: Scale pop effect
	if _label_3d:
		_label_3d.scale = Vector3(1.5, 1.5, 1.5)
		tween.parallel().tween_property(_label_3d, "scale", Vector3.ONE, 0.3)


## Static helper to create and attach a discovered label to a player node.
static func create_for_player(player_node: Node3D, player_id: int) -> Node3D:
	var label_script: GDScript = load("res://src/ui/discovered_cultist_label.gd")
	var label: Node3D = label_script.new()
	label.name = "DiscoveredCultistLabel"

	# Position above the player's head (player height is ~1.8m)
	label.position.y = 2.0

	# Set player ID before adding to tree (so _ready can check discovery state)
	label.set_player_id(player_id)

	player_node.add_child(label)
	return label
