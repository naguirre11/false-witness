class_name Interactable
extends Node3D
## Base class for all interactable objects in the game.
##
## Extend this class to create specific interactable types like doors, switches,
## pickup items, etc. Override the virtual methods to customize behavior.

# --- Signals ---

signal interacted(player: Node)
signal interaction_enabled_changed(enabled: bool)

# --- Enums ---

enum InteractionType {
	USE,       ## Generic use action (doors, switches)
	PICKUP,    ## Pick up the object
	TOGGLE,    ## Toggle state on/off
	EXAMINE,   ## Look at/examine without taking
}

# --- Export: Interaction Settings ---

@export_group("Interaction")
@export var interaction_type: InteractionType = InteractionType.USE
@export var interaction_prompt: String = "Interact"
@export var interaction_range: float = 2.5
@export var interaction_cooldown: float = 0.2
@export var one_shot: bool = false
@export var requires_line_of_sight: bool = true

@export_group("Network")
@export var sync_to_network: bool = true

# --- State ---

var _interaction_enabled: bool = true
var _cooldown_timer: float = 0.0
var _has_been_used: bool = false


func _ready() -> void:
	# Add to interactable group for easy querying
	add_to_group("interactables")


func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta


# --- Virtual Methods (Override These) ---

## Override to add custom interaction conditions.
## Called before interaction to check if it's possible.
func can_interact(player: Node) -> bool:
	if not _interaction_enabled:
		return false
	if _cooldown_timer > 0.0:
		return false
	if one_shot and _has_been_used:
		return false
	return _can_interact_impl(player)


## Override for custom interaction logic.
## Returns true if interaction was successful.
func interact(player: Node) -> bool:
	if not can_interact(player):
		return false

	_cooldown_timer = interaction_cooldown
	_has_been_used = true

	var success: bool = _interact_impl(player)
	if success:
		interacted.emit(player)

		if sync_to_network:
			_sync_interaction(player)

	return success


## Override to customize the prompt shown to players.
## Can include contextual information (e.g., "[E] Open Door" vs "[E] Close Door").
func get_interaction_prompt() -> String:
	return interaction_prompt


## Override to add additional interaction checks.
func _can_interact_impl(_player: Node) -> bool:
	return true


## Override to implement actual interaction behavior.
func _interact_impl(_player: Node) -> bool:
	return true


## Override to handle network synchronization of the interaction.
## Default implementation emits EventBus signal for network layer to handle.
func _sync_interaction(player: Node) -> void:
	var event_bus := _get_event_bus()
	if event_bus:
		var player_id: int = _get_player_id(player)
		event_bus.player_interacted.emit(player_id, get_path())


## Helper to get EventBus autoload (works in Node context).
func _get_event_bus() -> Node:
	if has_node("/root/EventBus"):
		return get_node("/root/EventBus")
	return null


## Helper to extract player ID from player node.
func _get_player_id(player: Node) -> int:
	# Try to get peer_id from PlayerController or parent
	if player.has_method("get_peer_id"):
		return player.get_peer_id()
	if player.get("peer_id") != null:
		return player.peer_id
	# Fallback: use multiplayer authority
	return player.get_multiplayer_authority() if player.is_inside_tree() else 0


# --- Public API ---

## Gets whether this object can currently be interacted with.
func is_interaction_enabled() -> bool:
	return _interaction_enabled


## Enables or disables interaction with this object.
func set_interaction_enabled(enabled: bool) -> void:
	if _interaction_enabled != enabled:
		_interaction_enabled = enabled
		interaction_enabled_changed.emit(enabled)


## Gets the maximum range at which this object can be interacted with.
func get_interaction_range() -> float:
	return interaction_range


## Gets the interaction type for UI/input handling.
func get_interaction_type() -> InteractionType:
	return interaction_type


## Resets the one-shot state, allowing the object to be used again.
func reset_one_shot() -> void:
	_has_been_used = false


## Gets whether this object has been used (for one-shot items).
func has_been_used() -> bool:
	return _has_been_used


## Gets the current cooldown remaining.
func get_cooldown_remaining() -> float:
	return _cooldown_timer


## Forces the cooldown to end immediately.
func clear_cooldown() -> void:
	_cooldown_timer = 0.0


## Gets state for network synchronization.
func get_network_state() -> Dictionary:
	return {
		"enabled": _interaction_enabled,
		"used": _has_been_used,
	}


## Applies network state from host.
func apply_network_state(state: Dictionary) -> void:
	if state.has("enabled"):
		set_interaction_enabled(state.enabled)
	if state.has("used"):
		_has_been_used = state.used
