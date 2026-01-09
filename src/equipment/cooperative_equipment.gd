class_name CooperativeEquipment
extends Equipment
## Base class for cooperative equipment requiring two players.
##
## Cooperative equipment consists of paired pieces that must work together.
## Players must remain within proximity during operation.
##
## Examples:
## - Spectral Prism: Calibrator + Lens Reader (symmetric trust - both can lie)
## - Aura Imager: Dowsing Rods + Imager (asymmetric trust - one sees more)

# --- Signals ---

## Emitted when partner equipment is linked.
signal partner_linked(partner: CooperativeEquipment)

## Emitted when partner equipment is unlinked.
signal partner_unlinked

## Emitted when distance warning threshold is crossed.
signal proximity_warning(distance: float, max_distance: float)

## Emitted when proximity check fails (too far apart).
signal proximity_failed(distance: float)

## Emitted when operation is cancelled due to proximity failure.
signal operation_cancelled(reason: String)

# --- Enums ---

## Trust dynamic for cooperative equipment.
enum TrustDynamic {
	SYMMETRIC,  ## Both operators can lie equally (Spectral Prism)
	ASYMMETRIC,  ## One operator has more information (Aura Imager)
}

## Operation state for cooperative equipment.
enum OperationState {
	IDLE,  ## Not in operation
	WAITING,  ## Waiting for partner action
	OPERATING,  ## Operation in progress
	COMPLETED,  ## Operation finished successfully
	FAILED,  ## Operation failed (proximity, etc.)
}

# --- Export: Cooperative Settings ---

@export_group("Cooperative")
@export var max_partner_distance: float = 5.0  ## Maximum distance to partner
@export var proximity_warning_distance: float = 4.0  ## Distance to trigger warning
@export var trust_dynamic: TrustDynamic = TrustDynamic.SYMMETRIC
@export var is_primary: bool = false  ## True for primary piece (e.g., Calibrator)

@export_group("Proximity Checking")
@export var check_proximity_while_active: bool = true
@export var proximity_check_interval: float = 0.25  ## How often to check distance

# --- State ---

var _partner: CooperativeEquipment = null
var _operation_state: OperationState = OperationState.IDLE
var _proximity_timer: float = 0.0
var _last_partner_distance: float = 0.0


func _process(delta: float) -> void:
	super._process(delta)

	if not check_proximity_while_active:
		return

	if _current_state != EquipmentState.ACTIVE:
		return

	if _partner == null:
		return

	# Throttled proximity check
	_proximity_timer += delta
	if _proximity_timer >= proximity_check_interval:
		_proximity_timer = 0.0
		_check_partner_proximity()


# --- Partner Management ---


## Links this equipment to a partner equipment piece.
func link_partner(partner: CooperativeEquipment) -> bool:
	if partner == null:
		return false

	if partner == self:
		push_warning("Cannot link equipment to itself")
		return false

	if _partner != null:
		unlink_partner()

	_partner = partner
	partner_linked.emit(_partner)

	# Reciprocal link if not already linked
	if partner._partner != self:
		partner.link_partner(self)

	return true


## Unlinks the current partner.
func unlink_partner() -> void:
	if _partner == null:
		return

	var old_partner := _partner
	_partner = null
	partner_unlinked.emit()

	# Break reciprocal link
	if old_partner._partner == self:
		old_partner.unlink_partner()


## Returns true if this equipment has a linked partner.
func has_partner() -> bool:
	return _partner != null


## Returns the linked partner equipment.
func get_partner() -> CooperativeEquipment:
	return _partner


# --- Proximity System ---


## Returns true if the partner is within operating range.
func is_partner_in_range() -> bool:
	if _partner == null:
		return false

	var distance := get_partner_distance()
	return distance <= max_partner_distance


## Returns the distance to the partner equipment holder.
func get_partner_distance() -> float:
	if _partner == null:
		return INF

	if not _has_valid_position() or not _partner._has_valid_position():
		return INF

	var my_pos := _get_equipment_position()
	var partner_pos := _partner._get_equipment_position()

	return my_pos.distance_to(partner_pos)


## Returns true if this equipment has a valid position source.
func _has_valid_position() -> bool:
	return _owning_player != null and _owning_player is Node3D


## Checks proximity and emits appropriate signals.
func _check_partner_proximity() -> void:
	if _partner == null:
		return

	var distance := get_partner_distance()
	_last_partner_distance = distance

	if distance > max_partner_distance:
		proximity_failed.emit(distance)
		_handle_proximity_failure()
	elif distance > proximity_warning_distance:
		proximity_warning.emit(distance, max_partner_distance)


## Handles proximity failure (can be overridden).
func _handle_proximity_failure() -> void:
	if _operation_state == OperationState.OPERATING:
		_set_operation_state(OperationState.FAILED)
		operation_cancelled.emit("Partner too far away")
		_stop_use(_owning_player)


## Returns the position of this equipment's owner.
func _get_equipment_position() -> Vector3:
	if _owning_player and _owning_player is Node3D:
		var player_3d := _owning_player as Node3D
		# Use position directly if not in tree (for testing), else global_position
		if player_3d.is_inside_tree():
			return player_3d.global_position
		return player_3d.position
	return Vector3.ZERO


# --- Operation State ---


## Sets the operation state.
func _set_operation_state(new_state: OperationState) -> void:
	_operation_state = new_state


## Returns the current operation state.
func get_operation_state() -> OperationState:
	return _operation_state


## Returns true if currently in an active operation.
func is_operating() -> bool:
	return _operation_state == OperationState.OPERATING


## Returns true if waiting for partner.
func is_waiting_for_partner() -> bool:
	return _operation_state == OperationState.WAITING


## Resets operation state to IDLE.
func reset_operation() -> void:
	_set_operation_state(OperationState.IDLE)


# --- Overrides ---


## Override to add partner check before use.
func _can_use_impl(player: Node) -> bool:
	if not super._can_use_impl(player):
		return false

	# Must have a partner linked
	if not has_partner():
		return false

	# Partner must be in range
	if not is_partner_in_range():
		return false

	return true


## Override to set operation state on use.
func _use_impl() -> void:
	super._use_impl()
	_set_operation_state(OperationState.OPERATING)


## Override to reset operation state on stop.
func _stop_using_impl() -> void:
	super._stop_using_impl()
	if _operation_state != OperationState.FAILED:
		_set_operation_state(OperationState.IDLE)


## Override to include cooperative state.
func get_network_state() -> Dictionary:
	var state := super.get_network_state()
	state["operation_state"] = _operation_state
	state["partner_distance"] = _last_partner_distance
	return state


## Override to apply cooperative state.
func apply_network_state(state: Dictionary) -> void:
	super.apply_network_state(state)
	if state.has("operation_state"):
		_operation_state = state.operation_state as OperationState
	if state.has("partner_distance"):
		_last_partner_distance = state.partner_distance
