class_name FalseAlarmAbility
extends CultistAbility
## False Alarm ability - Trigger hunt warning without actual hunt.
##
## Creates the visual/audio effects of a hunt warning phase without
## an actual hunt occurring. Subtle difference in flicker pattern.

func _init() -> void:
	ability_name = "False Alarm"
	ability_description = "Trigger hunt warning effects without actual danger. Causes panic."
	max_charges = 1
	current_charges = 1
	placement_time = 2.0  # Quick activation for surprise
	cooldown_time = 30.0  # Long cooldown - can't spam
	ability_type = CultistEnums.AbilityType.FALSE_ALARM


## Executes the ability - triggers fake hunt warning.
func execute(_cultist_id: int, location: Vector3) -> bool:
	if not can_use():
		return false

	# Use the charge and emit signals
	use(location)

	# Trigger hunt warning (false) via EventBus
	# This will cause visual/audio effects but no actual chase
	if has_node("/root/EventBus"):
		var event_bus := get_node("/root/EventBus")

		# Emit warning with "false" flag position (entity won't actually hunt)
		if event_bus.has_signal("hunt_warning_started"):
			# Use location with special marker for false alarm
			# Duration is slightly shorter than real hunt warning
			event_bus.hunt_warning_started.emit(location, 4.0)

		# Schedule the warning end (no hunt)
		_schedule_warning_end()

		if event_bus.has_signal("cultist_ability_used"):
			event_bus.cultist_ability_used.emit("FALSE_ALARM")

	return true


## Schedules the hunt warning to end without a hunt.
func _schedule_warning_end() -> void:
	# Create a timer in the scene tree to end the warning
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return

	var timer := tree.create_timer(4.0)
	timer.timeout.connect(_on_warning_timeout)


func _on_warning_timeout() -> void:
	if has_node("/root/EventBus"):
		var event_bus := get_node("/root/EventBus")
		if event_bus.has_signal("hunt_warning_ended"):
			# hunt_proceeding = false means no actual hunt
			event_bus.hunt_warning_ended.emit(false)


## Override get_node for Resource (needs tree access for EventBus).
func get_node(path: NodePath) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(path)


## Check if node exists.
func has_node(path: NodePath) -> bool:
	return get_node(path) != null
