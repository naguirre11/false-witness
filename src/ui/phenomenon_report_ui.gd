class_name PhenomenonReportUI
extends Control
## UI panel for players to report witnessed phenomena.
##
## When a player is near a recent phenomenon location, they can open this
## UI to file a report. The system auto-detects recent phenomena in the area
## and lets the player select what they witnessed.
##
## Multiple witness reports increase evidence trust level.
## Single-witness reports are marked as such.

# --- Signals ---

## Emitted when a report is submitted.
signal report_submitted(report_data: Dictionary)

## Emitted when UI is closed without submitting.
signal report_cancelled

## Emitted when phenomena detection updates.
signal detected_phenomena_changed(count: int)

# --- Constants ---

## Range to detect nearby phenomena (meters).
const DETECTION_RANGE := 5.0

## Time window for recent phenomena (seconds).
const RECENT_TIME_WINDOW := 60.0

## Minimum hold time before auto-close (seconds).
const MIN_DISPLAY_TIME := 0.5

# --- Export: UI References ---

@export_group("UI Elements")
@export var phenomenon_list: ItemList
@export var type_label: Label
@export var location_label: Label
@export var timestamp_label: Label
@export var witness_count_label: Label
@export var submit_button: Button
@export var cancel_button: Button
@export var no_phenomena_label: Label

# --- State ---

var _detected_phenomena: Array[Dictionary] = []
var _selected_phenomenon: Dictionary = {}
var _player_position: Vector3 = Vector3.ZERO
var _player_id: int = 0
var _is_open: bool = false


func _ready() -> void:
	visible = false

	if submit_button:
		submit_button.pressed.connect(_on_submit_pressed)
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel_pressed)
	if phenomenon_list:
		phenomenon_list.item_selected.connect(_on_phenomenon_selected)


func _input(event: InputEvent) -> void:
	if not _is_open:
		return

	if event.is_action_pressed("ui_cancel"):
		close_ui()
		get_viewport().set_input_as_handled()


# --- Public Interface ---


## Opens the UI for phenomenon reporting.
## player_pos: Current player position for detection.
## player_id: Reporting player's ID.
func open_ui(player_pos: Vector3, player_id: int) -> void:
	_player_position = player_pos
	_player_id = player_id
	_is_open = true

	_detect_nearby_phenomena()
	_update_ui_state()

	visible = true
	if phenomenon_list and _detected_phenomena.size() > 0:
		phenomenon_list.grab_focus()
	elif cancel_button:
		cancel_button.grab_focus()


## Closes the UI.
func close_ui() -> void:
	_is_open = false
	visible = false
	_selected_phenomenon = {}
	report_cancelled.emit()


## Returns true if UI is currently open.
func is_open() -> bool:
	return _is_open


## Manually adds a phenomenon to the detected list.
## Used for testing or forced detection.
func add_detected_phenomenon(phenomenon_data: Dictionary) -> void:
	_detected_phenomena.append(phenomenon_data)
	_update_phenomenon_list()


## Returns the currently detected phenomena.
func get_detected_phenomena() -> Array[Dictionary]:
	return _detected_phenomena


# --- Detection ---


func _detect_nearby_phenomena() -> void:
	_detected_phenomena.clear()

	var current_time := Time.get_ticks_msec() / 1000.0

	# Check throwable objects that were recently thrown
	var throwables := get_tree().get_nodes_in_group("throwable_objects")
	for node in throwables:
		if node is ThrowableObject:
			var throwable := node as ThrowableObject
			_check_throwable_phenomenon(throwable, current_time)

	# Check doors that were recently manipulated
	var doors := get_tree().get_nodes_in_group("doors")
	for node in doors:
		if node is InteractableDoor:
			var door := node as InteractableDoor
			_check_door_phenomenon(door, current_time)

	# Check lights that are flickering or broken
	var lights := get_tree().get_nodes_in_group("lights")
	for node in lights:
		if node is FlickeringLight:
			var light := node as FlickeringLight
			_check_light_phenomenon(light, current_time)

	# Check surface manifestations
	var manifestations := get_tree().get_nodes_in_group("surface_manifestations")
	for node in manifestations:
		if node is SurfaceManifestation:
			var manifestation := node as SurfaceManifestation
			_check_manifestation_phenomenon(manifestation, current_time)

	detected_phenomena_changed.emit(_detected_phenomena.size())


func _check_throwable_phenomenon(obj: ThrowableObject, _current_time: float) -> void:
	if not _is_in_range(obj.global_position):
		return

	if obj.get_throw_state() != ThrowableObject.ThrowState.RESTING:
		return

	var entity_type := obj.get_last_throw_entity()
	if entity_type.is_empty():
		return

	_detected_phenomena.append({
		"type": "OBJECT_THROW",
		"display_name": "Object Thrown",
		"entity_type": entity_type,
		"location": obj.global_position,
		"node_path": obj.get_path(),
	})


func _check_door_phenomenon(door: InteractableDoor, _current_time: float) -> void:
	if not _is_in_range(door.global_position):
		return

	var entity_type := door.get_last_entity_type()
	if entity_type.is_empty():
		return

	_detected_phenomena.append({
		"type": "DOOR_MANIPULATION",
		"display_name": "Door Moved",
		"entity_type": entity_type,
		"location": door.global_position,
		"node_path": door.get_path(),
	})


func _check_light_phenomenon(light: FlickeringLight, _current_time: float) -> void:
	if not _is_in_range(light.global_position):
		return

	var entity_type := light.get_last_entity_type()
	if entity_type.is_empty():
		return

	var display_name := "Light Flickered"
	var phenomenon_type := "LIGHT_FLICKER"

	if light.is_broken():
		display_name = "Light Broken"
		phenomenon_type = "LIGHT_BROKEN"

	_detected_phenomena.append({
		"type": phenomenon_type,
		"display_name": display_name,
		"entity_type": entity_type,
		"location": light.global_position,
		"node_path": light.get_path(),
	})


func _check_manifestation_phenomenon(manifestation: SurfaceManifestation, _current_time: float) -> void:
	if not _is_in_range(manifestation.global_position):
		return

	if not manifestation.is_manifestation_visible():
		return

	var type_name := SurfaceManifestation.get_type_name(manifestation.get_manifestation_type())

	_detected_phenomena.append({
		"type": "SURFACE_MANIFESTATION",
		"display_name": type_name + " Appeared",
		"entity_type": manifestation.get_entity_type(),
		"location": manifestation.global_position,
		"node_path": manifestation.get_path(),
		"manifestation_type": manifestation.get_manifestation_type(),
	})


func _is_in_range(position: Vector3) -> bool:
	return _player_position.distance_to(position) <= DETECTION_RANGE


# --- UI State ---


func _update_ui_state() -> void:
	_update_phenomenon_list()
	_update_details_panel()
	_update_buttons()


func _update_phenomenon_list() -> void:
	if not phenomenon_list:
		return

	phenomenon_list.clear()

	for phenomenon in _detected_phenomena:
		var display: String = phenomenon.get("display_name", "Unknown Phenomenon")
		phenomenon_list.add_item(display)

	if no_phenomena_label:
		no_phenomena_label.visible = _detected_phenomena.is_empty()

	phenomenon_list.visible = not _detected_phenomena.is_empty()


func _update_details_panel() -> void:
	if _selected_phenomenon.is_empty():
		_clear_details()
		return

	if type_label:
		type_label.text = _selected_phenomenon.get("display_name", "Unknown")

	if location_label:
		var loc: Vector3 = _selected_phenomenon.get("location", Vector3.ZERO)
		location_label.text = "Location: (%.1f, %.1f, %.1f)" % [loc.x, loc.y, loc.z]

	if timestamp_label:
		timestamp_label.text = "Detected just now"

	if witness_count_label:
		witness_count_label.text = "Witnesses: 1 (you)"


func _clear_details() -> void:
	if type_label:
		type_label.text = "Select a phenomenon"
	if location_label:
		location_label.text = ""
	if timestamp_label:
		timestamp_label.text = ""
	if witness_count_label:
		witness_count_label.text = ""


func _update_buttons() -> void:
	if submit_button:
		submit_button.disabled = _selected_phenomenon.is_empty()


# --- Event Handlers ---


func _on_phenomenon_selected(index: int) -> void:
	if index < 0 or index >= _detected_phenomena.size():
		_selected_phenomenon = {}
	else:
		_selected_phenomenon = _detected_phenomena[index]

	_update_details_panel()
	_update_buttons()


func _on_submit_pressed() -> void:
	if _selected_phenomenon.is_empty():
		return

	var report_data := _create_report()
	report_submitted.emit(report_data)

	# Emit to EventBus for evidence system
	_emit_report_event(report_data)

	close_ui()


func _on_cancel_pressed() -> void:
	close_ui()


# --- Report Creation ---


func _create_report() -> Dictionary:
	var current_time := Time.get_ticks_msec() / 1000.0

	return {
		"phenomenon_type": _selected_phenomenon.get("type", "UNKNOWN"),
		"display_name": _selected_phenomenon.get("display_name", "Unknown"),
		"entity_type": _selected_phenomenon.get("entity_type", ""),
		"location": _selected_phenomenon.get("location", Vector3.ZERO),
		"reporter_id": _player_id,
		"timestamp": current_time,
		"witness_count": 1,
		"single_witness": true,
		"node_path": _selected_phenomenon.get("node_path", ""),
	}


func _emit_report_event(report_data: Dictionary) -> void:
	var event_bus := _get_event_bus()
	if event_bus and event_bus.has_signal("phenomenon_reported"):
		event_bus.phenomenon_reported.emit(report_data)


func _get_event_bus() -> Node:
	if has_node("/root/EventBus"):
		return get_node("/root/EventBus")
	return null


# --- Static Helpers ---


## Returns display name for a phenomenon type.
static func get_phenomenon_type_name(type: String) -> String:
	match type:
		"OBJECT_THROW":
			return "Object Thrown"
		"DOOR_MANIPULATION":
			return "Door Moved"
		"LIGHT_FLICKER":
			return "Light Flickered"
		"LIGHT_BROKEN":
			return "Light Broken"
		"SURFACE_MANIFESTATION":
			return "Surface Mark"
		_:
			return "Unknown Phenomenon"
