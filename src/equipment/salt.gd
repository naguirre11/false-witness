class_name Salt
extends ProtectionItem
## Salt protection item for entity identification.
##
## Salt is unique among protection items - it's primarily for entity
## identification rather than direct protection:
## - Reveals entity footsteps when entity crosses the salt pile
## - Footprints are UV-visible for identification
## - Slows some entities temporarily
## - Wraith ignores salt entirely (behavioral tell)
##
## - 3 uses per salt pile
## - Footprints visible under UV light

# --- Constants ---

const SLOWDOWN_DURATION: float = 3.0
const SLOWDOWN_FACTOR: float = 0.5  # 50% speed reduction
const FOOTPRINT_DURATION: float = 120.0  # 2 minutes visible

# --- State ---

var _footprint_locations: Array[Vector3] = []
var _active_area: Area3D = null


func _init() -> void:
	equipment_type = EquipmentType.SALT
	equipment_name = "Salt"
	use_mode = UseMode.INSTANT
	max_charges = 3
	placement_mode = PlacementMode.PLACED
	effective_radius = 0.5  # Small detection radius
	placement_range = 2.0


func _ready() -> void:
	super._ready()
	can_use_during_hunt = false  # Can't place salt during hunt


func _on_placed(location: Vector3) -> void:
	# Create detection area
	_create_detection_area(location)
	print("[Salt] Placed at %v with %d uses" % [location, _charges_remaining])


func _on_triggered(target: Node) -> bool:
	# Check if entity is Wraith (ignores salt)
	if _is_entity_wraith(target):
		print("[Salt] Wraith passed through - no footprints (behavioral tell)")
		# Emit tell signal but don't consume charge
		var event_bus := _get_event_bus()
		if event_bus and event_bus.has_signal("entity_tell_triggered"):
			event_bus.entity_tell_triggered.emit("wraith_salt_ignore")
		return false  # Don't consume charge for Wraith

	# Create footprint
	_create_footprint(target)

	# Apply slowdown to non-immune entities
	_apply_slowdown(target)

	# Emit salt triggered signal
	var event_bus := _get_event_bus()
	if event_bus and event_bus.has_signal("salt_triggered"):
		event_bus.salt_triggered.emit(_placed_position)

	return true


func _create_detection_area(location: Vector3) -> void:
	# Create Area3D for entity detection
	_active_area = Area3D.new()
	_active_area.name = "SaltDetectionArea"
	_active_area.collision_layer = 0
	_active_area.collision_mask = 4  # Entity layer

	var collision_shape := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = effective_radius
	collision_shape.shape = shape

	_active_area.add_child(collision_shape)
	_active_area.global_position = location

	# Connect signals
	_active_area.body_entered.connect(_on_body_entered)

	_add_placed_item_to_world(_active_area)


func _on_body_entered(body: Node3D) -> void:
	# Check if this is an entity
	if not _is_entity(body):
		return

	if not has_charges():
		return

	trigger(body)


func _create_footprint(entity: Node) -> void:
	var footprint_pos := _placed_position
	if entity:
		# Offset slightly in entity's movement direction
		footprint_pos = entity.global_position

	_footprint_locations.append(footprint_pos)

	# Create visual footprint
	var footprint := _create_footprint_visual(footprint_pos)
	if footprint:
		_add_placed_item_to_world(footprint)

		# Auto-remove footprint after duration
		var timer := get_tree().create_timer(FOOTPRINT_DURATION)
		timer.timeout.connect(func(): _remove_footprint(footprint, footprint_pos))

	print("[Salt] Footprint created at %v" % footprint_pos)


func _create_footprint_visual(location: Vector3) -> Node3D:
	var footprint := Node3D.new()
	footprint.name = "EntityFootprint"
	footprint.global_position = location

	# Create simple footprint mesh (two ovals)
	var left_foot := _create_foot_mesh(Vector3(-0.08, 0.01, 0))
	var right_foot := _create_foot_mesh(Vector3(0.08, 0.01, 0.15))

	footprint.add_child(left_foot)
	footprint.add_child(right_foot)

	return footprint


func _create_foot_mesh(offset: Vector3) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()

	# Ellipsoid shape for footprint
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.04
	capsule.height = 0.12
	mesh_instance.mesh = capsule
	mesh_instance.rotation_degrees = Vector3(90, 0, 0)  # Lay flat
	mesh_instance.position = offset

	# UV-reactive material (visible under UV light)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.1, 0.1, 0.1, 0.3)  # Nearly invisible normally
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(0.5, 0.0, 1.0)  # Purple/UV reactive
	material.emission_energy_multiplier = 0.0  # Only shows under UV
	mesh_instance.material_override = material

	# Add to UV_VISIBLE group for UV flashlight interaction
	mesh_instance.add_to_group("uv_visible")

	return mesh_instance


func _remove_footprint(footprint: Node, location: Vector3) -> void:
	if footprint and is_instance_valid(footprint):
		footprint.queue_free()
	_footprint_locations.erase(location)


func _apply_slowdown(entity: Node) -> void:
	# Apply temporary slowdown to entity
	if entity.has_method("apply_slowdown"):
		entity.apply_slowdown(SLOWDOWN_FACTOR, SLOWDOWN_DURATION)
	elif entity.has_method("set_speed_modifier"):
		entity.set_speed_modifier(SLOWDOWN_FACTOR, SLOWDOWN_DURATION)

	print("[Salt] Entity slowed for %.1f seconds" % SLOWDOWN_DURATION)


func _create_placed_visual() -> Node3D:
	# Create salt pile visual
	var visual := Node3D.new()
	visual.name = "SaltPile"

	# Simple cylinder for salt pile
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "SaltMesh"

	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.3
	cylinder.bottom_radius = 0.35
	cylinder.height = 0.02
	mesh_instance.mesh = cylinder

	# White material
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.95, 0.95, 0.95)
	material.roughness = 1.0
	mesh_instance.material_override = material

	visual.add_child(mesh_instance)

	return visual


func _is_entity(body: Node) -> bool:
	return body.is_in_group("entity") or body.has_method("get_entity_type")


func _is_entity_wraith(entity: Node) -> bool:
	if entity and entity.has_method("get_entity_type"):
		return entity.get_entity_type() == "Wraith"
	if entity and entity.get("entity_type") != null:
		return entity.entity_type == "Wraith"
	return false


## Gets all footprint locations.
func get_footprint_locations() -> Array[Vector3]:
	return _footprint_locations


func _on_depleted() -> void:
	super._on_depleted()

	# Visual feedback - salt pile becomes disturbed
	if _placed_item:
		# Scatter effect
		var tween := create_tween()
		tween.tween_property(_placed_item, "scale", Vector3(1.5, 0.5, 1.5), 0.3)

	print("[Salt] Depleted at %v" % _placed_position)


func get_network_state() -> Dictionary:
	var state := super.get_network_state()
	var footprints: Array[Dictionary] = []
	for loc in _footprint_locations:
		footprints.append({"x": loc.x, "y": loc.y, "z": loc.z})
	state["footprints"] = footprints
	return state


func apply_network_state(state: Dictionary) -> void:
	super.apply_network_state(state)
	if state.has("footprints"):
		_footprint_locations.clear()
		for fp in state.footprints:
			_footprint_locations.append(Vector3(fp.x, fp.y, fp.z))
