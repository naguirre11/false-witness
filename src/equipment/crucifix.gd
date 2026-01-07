class_name Crucifix
extends ProtectionItem
## Crucifix protection item that prevents entity hunts from starting.
##
## The crucifix must be placed BEFORE a hunt begins. When an entity attempts
## to start a hunt within the crucifix's effective radius, the hunt is
## prevented and one charge is consumed.
##
## - 2 charges per crucifix
## - 3m effective radius (2m for Demon)
## - Does NOT stop active hunts
## - Visual feedback when charge is consumed


func _init() -> void:
	equipment_type = EquipmentType.CRUCIFIX
	equipment_name = "Crucifix"
	use_mode = UseMode.INSTANT
	max_charges = 2
	placement_mode = PlacementMode.PLACED
	effective_radius = 3.0
	demon_radius_multiplier = 0.667  # 2m for Demon (2/3 of normal)
	placement_range = 2.5


func _ready() -> void:
	super._ready()
	_connect_hunt_signals()


func _connect_hunt_signals() -> void:
	# Listen for hunt attempts from the entity system
	var event_bus := _get_event_bus()
	if event_bus:
		# We need to listen for a pre-hunt signal that allows prevention
		# This will be emitted by the entity before hunt_started
		if event_bus.has_signal("hunt_starting"):
			if not event_bus.hunt_starting.is_connected(_on_hunt_starting):
				event_bus.hunt_starting.connect(_on_hunt_starting)


func _on_hunt_starting(entity_position: Vector3, entity: Node) -> void:
	# Check if crucifix can prevent this hunt
	if not _is_placed or not has_charges():
		return

	var radius := get_effective_radius(_is_entity_demon(entity))
	var distance := _placed_position.distance_to(entity_position)

	if distance <= radius:
		# Prevent the hunt
		trigger(entity)


func _on_triggered(_target: Node) -> bool:
	# Visual feedback
	_show_charge_consumed_effect()

	# Emit hunt prevented signal
	var event_bus := _get_event_bus()
	if event_bus and event_bus.has_signal("hunt_prevented"):
		event_bus.hunt_prevented.emit(_placed_position, _charges_remaining - 1)

	return true


func _on_placed(location: Vector3) -> void:
	print("[Crucifix] Placed at %v with %d charges" % [location, _charges_remaining])


func _create_placed_visual() -> Node3D:
	# Create a simple visual placeholder
	# In production, this would load a proper crucifix model
	var visual := Node3D.new()
	visual.name = "PlacedCrucifix"

	# Add a simple mesh for now
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "CrucifixMesh"

	var box := BoxMesh.new()
	box.size = Vector3(0.05, 0.2, 0.02)
	mesh_instance.mesh = box

	# Crossbar
	var crossbar := MeshInstance3D.new()
	crossbar.name = "Crossbar"
	var crossbar_mesh := BoxMesh.new()
	crossbar_mesh.size = Vector3(0.12, 0.02, 0.02)
	crossbar.mesh = crossbar_mesh
	crossbar.position = Vector3(0, 0.05, 0)

	visual.add_child(mesh_instance)
	visual.add_child(crossbar)

	return visual


func _show_charge_consumed_effect() -> void:
	# Visual feedback when a charge is consumed
	# In production, this would be a particle effect or shader animation
	if _placed_item:
		# Flash effect (simple scale pulse for now)
		var tween := create_tween()
		tween.tween_property(_placed_item, "scale", Vector3(1.3, 1.3, 1.3), 0.1)
		tween.tween_property(_placed_item, "scale", Vector3(1.0, 1.0, 1.0), 0.2)


func _is_entity_demon(entity: Node) -> bool:
	# Check if the entity is a Demon type
	if entity and entity.has_method("get_entity_type"):
		return entity.get_entity_type() == "Demon"
	if entity and entity.get("entity_type") != null:
		return entity.entity_type == "Demon"
	return false


func _on_depleted() -> void:
	super._on_depleted()

	# Visual feedback for depleted crucifix - shrink animation since Node3D has no modulate
	if _placed_item:
		var tween := create_tween()
		tween.tween_property(_placed_item, "scale", Vector3(0.5, 0.5, 0.5), 0.5)

	print("[Crucifix] Depleted at %v" % _placed_position)
