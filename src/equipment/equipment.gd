class_name Equipment
extends Node3D
## Base class for all equipment items that players can carry.
##
## Equipment provides evidence detection capabilities during investigation.
## Players select 3 equipment items before a match begins.
##
## Override `_use_impl()` and `_stop_using_impl()` in subclasses.
## Equipment can be toggled (flashlight) or held to use (EMF reader).

# --- Signals ---

signal used(player: Node)
signal stopped_using(player: Node)
signal state_changed(new_state: EquipmentState)

# --- Enums ---

enum EquipmentType {
	EMF_READER,
	SPIRIT_BOX,
	JOURNAL,
	THERMOMETER,
	UV_FLASHLIGHT,
	DOTS_PROJECTOR,
	VIDEO_CAMERA,
	PARABOLIC_MIC,
	# Cooperative Equipment
	SPECTRAL_PRISM_CALIBRATOR,
	SPECTRAL_PRISM_LENS,
	DOWSING_RODS,
	AURA_IMAGER,
	# Triggered Test Equipment
	GHOST_WRITING_BOOK,
	# Protection Items
	CRUCIFIX,
	SAGE_BUNDLE,
	SALT,
}

enum EquipmentState {
	INACTIVE,  ## Not in use
	ACTIVE,  ## Currently being used
	COOLDOWN,  ## Recovering from use
}

enum UseMode {
	HOLD,  ## Must hold button to use (EMF, thermometer)
	TOGGLE,  ## Click to toggle on/off (flashlight, DOTS)
	INSTANT,  ## Single use action (journal entry)
}

# --- Export: Equipment Settings ---

@export_group("Equipment")
@export var equipment_type: EquipmentType = EquipmentType.EMF_READER
@export var equipment_name: String = "Equipment"
@export var use_mode: UseMode = UseMode.HOLD
@export var cooldown_time: float = 0.0
@export var can_use_during_hunt: bool = true

@export_group("Visual")
@export var first_person_offset: Vector3 = Vector3(0.25, -0.2, -0.4)
@export var first_person_rotation: Vector3 = Vector3.ZERO

@export_group("Network")
@export var sync_state: bool = true

# --- State ---

var _current_state: EquipmentState = EquipmentState.INACTIVE
var _cooldown_timer: float = 0.0
var _owning_player: Node = null
var _is_equipped: bool = false


func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
		if _cooldown_timer <= 0.0:
			_cooldown_timer = 0.0
			_set_state(EquipmentState.INACTIVE)


# --- Virtual Methods (Override These) ---


## Override to implement equipment-specific use behavior.
## Called when player starts using the equipment.
func _use_impl() -> void:
	pass


## Override to implement equipment-specific stop behavior.
## Called when player stops using the equipment.
func _stop_using_impl() -> void:
	pass


## Override to implement equipment update logic while active.
## Called every frame while equipment is in ACTIVE state.
func _active_process(_delta: float) -> void:
	pass


## Override to return evidence types this equipment can detect.
func get_detectable_evidence() -> Array[String]:
	return []


# --- Public API ---


## Attempts to use this equipment. Returns true if successful.
func use(player: Node) -> bool:
	if not can_use(player):
		return false

	match use_mode:
		UseMode.HOLD, UseMode.INSTANT:
			_start_use(player)
		UseMode.TOGGLE:
			if _current_state == EquipmentState.ACTIVE:
				_stop_use(player)
			else:
				_start_use(player)

	return true


## Stops using the equipment. For HOLD mode, called when button released.
func stop_using(player: Node) -> void:
	if _current_state != EquipmentState.ACTIVE:
		return

	if use_mode == UseMode.HOLD:
		_stop_use(player)


## Returns true if the equipment can currently be used.
func can_use(player: Node) -> bool:
	if _current_state == EquipmentState.COOLDOWN:
		return false

	if not _is_equipped:
		return false

	if not can_use_during_hunt and _is_hunt_active():
		return false

	return _can_use_impl(player)


## Override to add custom use conditions.
func _can_use_impl(_player: Node) -> bool:
	return true


## Equips this equipment to a player.
func equip(player: Node) -> void:
	_owning_player = player
	_is_equipped = true
	_on_equipped(player)


## Unequips this equipment from its owner.
func unequip() -> void:
	if _current_state == EquipmentState.ACTIVE and _owning_player:
		_stop_use(_owning_player)

	var prev_owner := _owning_player
	_owning_player = null
	_is_equipped = false
	_on_unequipped(prev_owner)


## Called when equipment is equipped. Override for setup.
func _on_equipped(_player: Node) -> void:
	pass


## Called when equipment is unequipped. Override for cleanup.
func _on_unequipped(_player: Node) -> void:
	pass


## Gets the current equipment state.
func get_state() -> EquipmentState:
	return _current_state


## Gets the owning player.
func get_owner_player() -> Node:
	return _owning_player


## Gets whether this equipment is currently equipped.
func is_equipped() -> bool:
	return _is_equipped


## Gets whether this equipment is currently active.
func is_active() -> bool:
	return _current_state == EquipmentState.ACTIVE


## Gets the remaining cooldown time.
func get_cooldown_remaining() -> float:
	return _cooldown_timer


## Gets equipment display name.
func get_display_name() -> String:
	return equipment_name


## Gets state for network synchronization.
func get_network_state() -> Dictionary:
	return {
		"state": _current_state,
		"cooldown": _cooldown_timer,
	}


## Applies network state from host.
func apply_network_state(state: Dictionary) -> void:
	if state.has("state"):
		_set_state(state.state as EquipmentState)
	if state.has("cooldown"):
		_cooldown_timer = state.cooldown


# --- Internal Methods ---


func _start_use(player: Node) -> void:
	_set_state(EquipmentState.ACTIVE)
	_use_impl()
	used.emit(player)

	if sync_state:
		_sync_use(player, true)


func _stop_use(player: Node) -> void:
	_stop_using_impl()
	stopped_using.emit(player)

	if cooldown_time > 0.0:
		_cooldown_timer = cooldown_time
		_set_state(EquipmentState.COOLDOWN)
	else:
		_set_state(EquipmentState.INACTIVE)

	if sync_state:
		_sync_use(player, false)


func _set_state(new_state: EquipmentState) -> void:
	if _current_state != new_state:
		_current_state = new_state
		state_changed.emit(new_state)


func _sync_use(player: Node, is_using: bool) -> void:
	var event_bus := _get_event_bus()
	if event_bus and event_bus.has_signal("equipment_used"):
		var player_id: int = _get_player_id(player)
		event_bus.equipment_used.emit(player_id, get_path(), is_using)


func _is_hunt_active() -> bool:
	var game_manager := _get_game_manager()
	if game_manager:
		return game_manager.current_state == 4  # GameState.HUNT
	return false


func _get_event_bus() -> Node:
	if has_node("/root/EventBus"):
		return get_node("/root/EventBus")
	return null


func _get_game_manager() -> Node:
	if has_node("/root/GameManager"):
		return get_node("/root/GameManager")
	return null


func _get_player_id(player: Node) -> int:
	if player.has_method("get_peer_id"):
		return player.get_peer_id()
	if player.get("peer_id") != null:
		return player.peer_id
	return player.get_multiplayer_authority() if player.is_inside_tree() else 0
