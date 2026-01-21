class_name ProvocationAbility
extends CultistAbility
## Provocation ability - Force immediate hunt.
##
## Cultist can trigger an entity hunt immediately, bypassing normal
## sanity threshold requirements. Observable tell: brief electrical surge.

func _init() -> void:
	ability_name = "Provocation"
	ability_description = "Force the entity to hunt immediately. Bypasses normal triggers."
	max_charges = 1
	current_charges = 1
	placement_time = 3.0  # Faster - time pressure ability
	cooldown_time = 5.0
	ability_type = CultistEnums.AbilityType.PROVOCATION


## Executes the ability - triggers a hunt.
func execute(_cultist_id: int, location: Vector3) -> bool:
	if not can_use():
		return false

	# Use the charge and emit signals
	use(location)

	# Trigger hunt via EntityManager
	if has_node("/root/EntityManager"):
		var entity_manager := get_node("/root/EntityManager")
		if entity_manager.has_method("trigger_hunt"):
			entity_manager.trigger_hunt()

	# Emit ability used event
	if has_node("/root/EventBus"):
		var event_bus := get_node("/root/EventBus")
		if event_bus.has_signal("cultist_ability_used"):
			event_bus.cultist_ability_used.emit("PROVOCATION")

	return true


## Override get_node for Resource (needs tree access for EventBus).
func get_node(path: NodePath) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(path)


## Check if node exists.
func has_node(path: NodePath) -> bool:
	return get_node(path) != null
