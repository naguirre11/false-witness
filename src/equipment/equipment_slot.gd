class_name EquipmentSlot
extends Resource
## Represents a single equipment slot in a player's inventory.
##
## Tracks what equipment is assigned to this slot and provides
## serialization for network sync and save/load.

# --- Signals ---

signal equipment_changed(old_type: int, new_type: int)

# --- State ---

## The equipment type assigned to this slot (-1 = empty)
var equipment_type: int = -1

## The equipment instance (set when equipment is instantiated)
var equipment_instance: Node = null

## Slot index (0-2 for standard 3-slot loadout)
var slot_index: int = 0

# --- Public API ---


## Assigns an equipment type to this slot.
func assign(type: int) -> void:
	var old_type := equipment_type
	equipment_type = type
	if old_type != type:
		equipment_changed.emit(old_type, type)


## Clears this slot.
func clear() -> void:
	var old_type := equipment_type
	equipment_type = -1
	equipment_instance = null
	if old_type != -1:
		equipment_changed.emit(old_type, -1)


## Returns true if this slot has equipment assigned.
func has_equipment() -> bool:
	return equipment_type >= 0


## Returns true if this slot has an instantiated equipment.
func has_instance() -> bool:
	return equipment_instance != null and is_instance_valid(equipment_instance)


## Gets the equipment type name.
func get_type_name() -> String:
	if equipment_type < 0:
		return "Empty"
	return EquipmentSlot.type_to_name(equipment_type)


## Serializes slot data for network sync.
func to_dict() -> Dictionary:
	return {
		"slot_index": slot_index,
		"equipment_type": equipment_type,
	}


## Deserializes slot data from network.
func from_dict(data: Dictionary) -> void:
	if data.has("slot_index"):
		slot_index = data.slot_index
	if data.has("equipment_type"):
		assign(data.equipment_type)


# --- Static Helpers ---


## Converts equipment type enum to display name.
static func type_to_name(type: int) -> String:
	var names: Dictionary = {
		0: "EMF Reader",
		1: "Spirit Box",
		2: "Journal",
		3: "Thermometer",
		4: "UV Flashlight",
		5: "DOTS Projector",
		6: "Video Camera",
		7: "Parabolic Mic",
	}
	return names.get(type, "Unknown")


## Converts display name to equipment type enum.
static func name_to_type(equipment_name: String) -> int:
	var types: Dictionary = {
		"EMF Reader": 0,
		"Spirit Box": 1,
		"Journal": 2,
		"Thermometer": 3,
		"UV Flashlight": 4,
		"DOTS Projector": 5,
		"Video Camera": 6,
		"Parabolic Mic": 7,
	}
	return types.get(equipment_name, -1)


## Gets the default equipment scene path for a type.
static func get_scene_path(type: int) -> String:
	var paths: Dictionary = {
		0: "res://scenes/equipment/emf_reader.tscn",
		1: "res://scenes/equipment/spirit_box.tscn",
		2: "res://scenes/equipment/journal.tscn",
		3: "res://scenes/equipment/thermometer.tscn",
		4: "res://scenes/equipment/uv_flashlight.tscn",
		5: "res://scenes/equipment/dots_projector.tscn",
		6: "res://scenes/equipment/video_camera.tscn",
		7: "res://scenes/equipment/parabolic_mic.tscn",
	}
	return paths.get(type, "")
