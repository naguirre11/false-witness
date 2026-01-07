class_name EquipmentManager
extends Node
## Manages a player's equipment loadout and active equipment switching.
##
## Handles:
## - 3 equipment slots with selection during SETUP phase
## - Scroll wheel / number key switching
## - Equipment instantiation and visual display
## - Network synchronization of loadout and active slot

# --- Signals ---

signal loadout_changed(slots: Array[EquipmentSlot])
signal active_slot_changed(old_slot: int, new_slot: int)
signal equipment_used(slot: int, equipment: Equipment)
signal equipment_locked  ## Emitted when loadout is locked (investigation starts)

# --- Constants ---

const SLOT_COUNT: int = 3
const SCROLL_COOLDOWN: float = 0.15

# --- Export: Settings ---

@export_group("Input")
@export var scroll_sensitivity: float = 1.0
@export var enable_number_keys: bool = true
@export var enable_scroll_wheel: bool = true

@export_group("Visual")
@export var equipment_holder_path: NodePath = ^"../Head/EquipmentHolder"

# --- State ---

var _slots: Array[EquipmentSlot] = []
var _active_slot: int = 0
var _loadout_locked: bool = false
var _scroll_cooldown_timer: float = 0.0
var _input_enabled: bool = true
var _is_local_player: bool = true

# --- Node References ---

var _equipment_holder: Node3D = null
var _player: Node = null


func _ready() -> void:
	_initialize_slots()
	_setup_equipment_holder()


func _initialize_slots() -> void:
	_slots.clear()
	for i in range(SLOT_COUNT):
		var slot := EquipmentSlot.new()
		slot.slot_index = i
		_slots.append(slot)


func _setup_equipment_holder() -> void:
	if not equipment_holder_path.is_empty():
		_equipment_holder = get_node_or_null(equipment_holder_path)

	_player = get_parent()


func _process(delta: float) -> void:
	if _scroll_cooldown_timer > 0.0:
		_scroll_cooldown_timer -= delta


func _unhandled_input(event: InputEvent) -> void:
	if not _input_enabled or not _is_local_player:
		return

	# Scroll wheel switching
	if enable_scroll_wheel and event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.pressed and _scroll_cooldown_timer <= 0.0:
			if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_cycle_slot(-1)
				_scroll_cooldown_timer = SCROLL_COOLDOWN
			elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_cycle_slot(1)
				_scroll_cooldown_timer = SCROLL_COOLDOWN

	# Number key switching
	if enable_number_keys and event is InputEventKey:
		var key_event: InputEventKey = event
		if key_event.pressed and not key_event.echo:
			var slot: int = -1
			match key_event.keycode:
				KEY_1:
					slot = 0
				KEY_2:
					slot = 1
				KEY_3:
					slot = 2

			if slot >= 0 and slot < SLOT_COUNT:
				set_active_slot(slot)

	# Equipment use
	if event.is_action_pressed("use_equipment"):
		_start_use_equipment()
	elif event.is_action_released("use_equipment"):
		_stop_use_equipment()


# --- Public API: Loadout Management ---


## Assigns equipment to a slot. Only works before loadout is locked.
func assign_equipment(slot_index: int, equipment_type: int) -> bool:
	if _loadout_locked:
		push_warning("[EquipmentManager] Cannot modify loadout - already locked")
		return false

	if slot_index < 0 or slot_index >= SLOT_COUNT:
		push_warning("[EquipmentManager] Invalid slot index: %d" % slot_index)
		return false

	# Check for duplicates
	for i in range(SLOT_COUNT):
		if i != slot_index and _slots[i].equipment_type == equipment_type:
			push_warning("[EquipmentManager] Equipment type already in another slot")
			return false

	_slots[slot_index].assign(equipment_type)
	loadout_changed.emit(_slots)

	if _is_local_player:
		_sync_loadout()

	return true


## Clears a slot. Only works before loadout is locked.
func clear_slot(slot_index: int) -> bool:
	if _loadout_locked:
		return false

	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return false

	_slots[slot_index].clear()
	loadout_changed.emit(_slots)

	if _is_local_player:
		_sync_loadout()

	return true


## Gets the equipment type in a slot (-1 if empty).
func get_slot_type(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return -1
	return _slots[slot_index].equipment_type


## Gets all slots.
func get_slots() -> Array[EquipmentSlot]:
	return _slots


## Gets the number of filled slots.
func get_filled_slot_count() -> int:
	var count: int = 0
	for slot in _slots:
		if slot.has_equipment():
			count += 1
	return count


## Returns true if the loadout is complete (all slots filled).
func is_loadout_complete() -> bool:
	return get_filled_slot_count() == SLOT_COUNT


## Returns true if the loadout has been locked.
func is_loadout_locked() -> bool:
	return _loadout_locked


## Locks the loadout and instantiates equipment. Called when investigation starts.
func lock_loadout() -> void:
	if _loadout_locked:
		return

	_loadout_locked = true
	_instantiate_all_equipment()
	equipment_locked.emit()

	print("[EquipmentManager] Loadout locked with %d equipment" % get_filled_slot_count())


## Unlocks the loadout. Called when returning to lobby.
func unlock_loadout() -> void:
	if not _loadout_locked:
		return

	_destroy_all_equipment()
	_loadout_locked = false

	print("[EquipmentManager] Loadout unlocked")


# --- Public API: Active Equipment ---


## Sets the active equipment slot.
func set_active_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return

	if slot_index == _active_slot:
		return

	var old_slot := _active_slot

	# Hide previous equipment
	_hide_slot_equipment(old_slot)

	# Show new equipment
	_active_slot = slot_index
	_show_slot_equipment(slot_index)

	active_slot_changed.emit(old_slot, slot_index)

	if _is_local_player:
		_sync_active_slot()


## Gets the current active slot index.
func get_active_slot() -> int:
	return _active_slot


## Gets the currently active equipment instance.
func get_active_equipment() -> Equipment:
	if _active_slot < 0 or _active_slot >= SLOT_COUNT:
		return null
	return _slots[_active_slot].equipment_instance as Equipment


## Returns true if any equipment is currently active (being used).
func is_equipment_active() -> bool:
	var equipment := get_active_equipment()
	return equipment != null and equipment.is_active()


# --- Public API: Input Control ---


## Enables or disables equipment input.
func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled

	# Stop using equipment if input disabled
	if not enabled:
		_stop_use_equipment()


## Sets whether this is the local player.
func set_local_player(is_local: bool) -> void:
	_is_local_player = is_local


# --- Public API: Network Sync ---


## Gets the full loadout state for network sync.
func get_network_state() -> Dictionary:
	var slots_data: Array[Dictionary] = []
	for slot in _slots:
		slots_data.append(slot.to_dict())

	return {
		"slots": slots_data,
		"active_slot": _active_slot,
		"locked": _loadout_locked,
	}


## Applies network state from host.
func apply_network_state(state: Dictionary) -> void:
	if state.has("slots"):
		var slots_data: Array = state.slots
		for i in range(mini(slots_data.size(), SLOT_COUNT)):
			_slots[i].from_dict(slots_data[i])

	if state.has("active_slot"):
		var new_slot: int = state.active_slot
		if new_slot != _active_slot:
			_hide_slot_equipment(_active_slot)
			_active_slot = new_slot
			_show_slot_equipment(_active_slot)

	if state.has("locked"):
		var was_locked := _loadout_locked
		_loadout_locked = state.locked
		if not was_locked and _loadout_locked:
			_instantiate_all_equipment()


# --- Internal Methods ---


func _cycle_slot(direction: int) -> void:
	var new_slot := _active_slot + direction
	if new_slot < 0:
		new_slot = SLOT_COUNT - 1
	elif new_slot >= SLOT_COUNT:
		new_slot = 0
	set_active_slot(new_slot)


func _start_use_equipment() -> void:
	var equipment := get_active_equipment()
	if equipment and _player:
		if equipment.use(_player):
			equipment_used.emit(_active_slot, equipment)


func _stop_use_equipment() -> void:
	var equipment := get_active_equipment()
	if equipment and _player:
		equipment.stop_using(_player)


func _instantiate_all_equipment() -> void:
	for i in range(SLOT_COUNT):
		_instantiate_slot_equipment(i)

	# Show active slot equipment
	_show_slot_equipment(_active_slot)


func _instantiate_slot_equipment(slot_index: int) -> void:
	var slot := _slots[slot_index]
	if not slot.has_equipment():
		return

	if slot.has_instance():
		return  # Already instantiated

	var scene_path: String = EquipmentSlot.get_scene_path(slot.equipment_type)
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		# Create placeholder if scene doesn't exist yet
		var placeholder := _create_placeholder_equipment(slot.equipment_type)
		slot.equipment_instance = placeholder
		_add_equipment_to_holder(placeholder)
		return

	var scene: PackedScene = load(scene_path)
	if scene:
		var instance: Node = scene.instantiate()
		slot.equipment_instance = instance
		_add_equipment_to_holder(instance)

		var equipment := instance as Equipment
		if equipment:
			equipment.equip(_player)


func _create_placeholder_equipment(equipment_type: int) -> Equipment:
	var equipment := Equipment.new()
	equipment.equipment_type = equipment_type as Equipment.EquipmentType
	equipment.equipment_name = EquipmentSlot.type_to_name(equipment_type)
	equipment.equip(_player)
	return equipment


func _add_equipment_to_holder(equipment: Node) -> void:
	if _equipment_holder and equipment:
		_equipment_holder.add_child(equipment)
		equipment.visible = false


func _destroy_all_equipment() -> void:
	for slot in _slots:
		if slot.has_instance():
			var equipment := slot.equipment_instance as Equipment
			if equipment:
				equipment.unequip()
			slot.equipment_instance.queue_free()
			slot.equipment_instance = null


func _show_slot_equipment(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return

	var slot := _slots[slot_index]
	if slot.has_instance():
		slot.equipment_instance.visible = true


func _hide_slot_equipment(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return

	var slot := _slots[slot_index]
	if slot.has_instance():
		slot.equipment_instance.visible = false

		# Stop using if active
		var equipment := slot.equipment_instance as Equipment
		if equipment and equipment.is_active() and _player:
			equipment.stop_using(_player)


func _sync_loadout() -> void:
	var event_bus := _get_event_bus()
	if event_bus and event_bus.has_signal("equipment_loadout_changed"):
		var player_id: int = _get_player_id()
		var loadout_data: Array[int] = []
		for slot in _slots:
			loadout_data.append(slot.equipment_type)
		event_bus.equipment_loadout_changed.emit(player_id, loadout_data)


func _sync_active_slot() -> void:
	var event_bus := _get_event_bus()
	if event_bus and event_bus.has_signal("equipment_slot_changed"):
		var player_id: int = _get_player_id()
		event_bus.equipment_slot_changed.emit(player_id, _active_slot)


func _get_event_bus() -> Node:
	if has_node("/root/EventBus"):
		return get_node("/root/EventBus")
	return null


func _get_player_id() -> int:
	if _player:
		if _player.has_method("get_peer_id"):
			return _player.get_peer_id()
		if _player.get("peer_id") != null:
			return _player.peer_id
	return get_multiplayer_authority() if is_inside_tree() else 0
