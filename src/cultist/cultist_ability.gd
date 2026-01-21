class_name CultistAbility
extends Resource
## Base class for all Cultist abilities.
##
## Cultist abilities allow the traitor player to plant false evidence,
## disrupt investigations, and manipulate the game state. Each ability
## has a limited number of charges and requires time to activate.

# --- Signals ---

## Emitted when a charge is used.
signal charge_used(remaining: int)

## Emitted when the ability completes activation.
signal ability_activated(ability: CultistAbility, location: Vector3)

## Emitted when the ability activation is cancelled.
signal ability_cancelled()

# --- Exported Properties ---

## Display name of the ability.
@export var ability_name: String = "Unknown Ability"

## Description shown in UI.
@export var ability_description: String = ""

## Icon resource for UI display.
@export var icon: Texture2D

## Maximum number of charges.
@export var max_charges: int = 1

## Time in seconds to activate the ability (player must stand still).
@export var placement_time: float = 5.0

## Cooldown in seconds after use before ability can be used again.
@export var cooldown_time: float = 0.0

## Ability type from CultistEnums.
@export var ability_type: int = 0  # CultistEnums.AbilityType

# --- Runtime State ---

## Current remaining charges.
var current_charges: int = 0

## Whether the ability is currently on cooldown.
var is_on_cooldown: bool = false

## Time remaining on cooldown.
var cooldown_remaining: float = 0.0

## Whether the ability is currently being activated.
var is_activating: bool = false

## Time remaining for current activation.
var activation_remaining: float = 0.0


func _init() -> void:
	current_charges = max_charges


# --- Public API ---


## Returns true if the ability can be used.
func can_use() -> bool:
	if current_charges <= 0:
		return false
	if is_on_cooldown:
		return false
	if is_activating:
		return false
	return true


## Starts the ability activation. Returns true if activation started.
func start_activation() -> bool:
	if not can_use():
		return false

	is_activating = true
	activation_remaining = placement_time
	return true


## Updates the activation timer. Returns true if activation completed.
func update_activation(delta: float) -> bool:
	if not is_activating:
		return false

	activation_remaining -= delta

	if activation_remaining <= 0.0:
		is_activating = false
		return true

	return false


## Cancels the current activation.
func cancel_activation() -> void:
	if is_activating:
		is_activating = false
		activation_remaining = 0.0
		ability_cancelled.emit()


## Gets the activation progress as a value from 0 to 1.
func get_activation_progress() -> float:
	if not is_activating or placement_time <= 0:
		return 0.0
	return 1.0 - (activation_remaining / placement_time)


## Uses a charge and applies the ability effect.
## Override in subclasses to implement specific effects.
## Returns true if the ability was used successfully.
func use(location: Vector3 = Vector3.ZERO) -> bool:
	if current_charges <= 0:
		return false

	current_charges -= 1
	charge_used.emit(current_charges)

	# Start cooldown if configured
	if cooldown_time > 0.0:
		is_on_cooldown = true
		cooldown_remaining = cooldown_time

	ability_activated.emit(self, location)
	return true


## Updates the cooldown timer.
func update_cooldown(delta: float) -> void:
	if not is_on_cooldown:
		return

	cooldown_remaining -= delta

	if cooldown_remaining <= 0.0:
		is_on_cooldown = false
		cooldown_remaining = 0.0


## Resets the ability to its initial state.
func reset() -> void:
	current_charges = max_charges
	is_on_cooldown = false
	cooldown_remaining = 0.0
	is_activating = false
	activation_remaining = 0.0


## Returns true if there are charges remaining.
func has_charges() -> bool:
	return current_charges > 0


## Gets the ability display info for UI.
func get_display_info() -> Dictionary:
	return {
		"name": ability_name,
		"description": ability_description,
		"icon": icon,
		"max_charges": max_charges,
		"current_charges": current_charges,
		"placement_time": placement_time,
		"cooldown_time": cooldown_time,
		"is_on_cooldown": is_on_cooldown,
		"cooldown_remaining": cooldown_remaining,
		"is_activating": is_activating,
		"activation_progress": get_activation_progress(),
		"can_use": can_use(),
	}


## Creates a copy of this ability with reset state.
func create_instance() -> CultistAbility:
	var instance := duplicate() as CultistAbility
	instance.reset()
	return instance
