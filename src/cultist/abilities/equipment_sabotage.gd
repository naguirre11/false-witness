class_name EquipmentSabotageAbility
extends CultistAbility
## Equipment Sabotage ability - Disable teammate equipment temporarily.
##
## Targets another player's equipment and disables it for a short duration.
## The affected player sees their equipment malfunction.

## Duration that equipment stays disabled (seconds).
const SABOTAGE_DURATION := 30.0


func _init() -> void:
	ability_name = "Equipment Sabotage"
	ability_description = "Disable a teammate's equipment for 30 seconds. Requires line of sight."
	max_charges = 1
	current_charges = 1
	placement_time = 3.0
	cooldown_time = 60.0  # Long cooldown - powerful ability
	ability_type = CultistEnums.AbilityType.EQUIPMENT_SABOTAGE


## Executes the ability - sabotages target player's equipment.
## target_player_id: The player whose equipment will be disabled.
func execute_on_target(cultist_id: int, target_player_id: int, location: Vector3) -> bool:
	if not can_use():
		return false

	if target_player_id == cultist_id:
		# Can't sabotage own equipment
		return false

	# Use the charge and emit signals
	use(location)

	# Emit sabotage event for equipment system to handle
	if has_node("/root/EventBus"):
		var event_bus := get_node("/root/EventBus")

		# Custom signal for equipment sabotage
		if event_bus.has_signal("equipment_sabotaged"):
			event_bus.equipment_sabotaged.emit(target_player_id, SABOTAGE_DURATION)

		if event_bus.has_signal("cultist_ability_used"):
			event_bus.cultist_ability_used.emit("EQUIPMENT_SABOTAGE")

	return true


## Standard execute (needs target selection elsewhere).
func execute(_cultist_id: int, _location: Vector3) -> bool:
	push_warning("[EquipmentSabotage] Use execute_on_target() instead")
	return false


## Override get_node for Resource (needs tree access for EventBus).
func get_node(path: NodePath) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(path)


## Check if node exists.
func has_node(path: NodePath) -> bool:
	return get_node(path) != null
