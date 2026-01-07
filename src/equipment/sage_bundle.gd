class_name SageBundle
extends ProtectionItem
## Sage Bundle (Smudge Sticks) protection item for hunt counterplay.
##
## The sage bundle is a held item that provides two effects:
## 1. During an active hunt: Blinds the entity for 5 seconds
## 2. After use: Prevents new hunts for 60 seconds (30s for Demon)
##
## - 1 charge per bundle
## - Can be used while moving
## - Smoke visual effect when used

# --- Constants ---

const BLIND_DURATION: float = 5.0
const HUNT_PREVENTION_DURATION: float = 60.0
const DEMON_PREVENTION_DURATION: float = 30.0
const SMOKE_DURATION: float = 3.0

# --- State ---

var _prevention_timer: float = 0.0
var _is_preventing_hunts: bool = false
var _smoke_effect: Node3D = null


func _init() -> void:
	equipment_type = EquipmentType.SAGE_BUNDLE
	equipment_name = "Sage Bundle"
	use_mode = UseMode.INSTANT
	max_charges = 1
	placement_mode = PlacementMode.HELD
	demon_duration_multiplier = 0.5  # 30s for Demon (half duration)


func _ready() -> void:
	super._ready()
	can_use_during_hunt = true  # Critical - must work during hunts


func _process(delta: float) -> void:
	super._process(delta)

	# Handle hunt prevention timer
	if _is_preventing_hunts:
		_prevention_timer -= delta
		if _prevention_timer <= 0.0:
			_end_hunt_prevention()


func _on_triggered(_target: Node) -> bool:
	# Create smoke effect
	_create_smoke_effect()

	# Check if currently in a hunt
	if _is_hunt_active():
		_blind_entity()

	# Start hunt prevention
	_start_hunt_prevention()

	return true


func _blind_entity() -> void:
	var event_bus := _get_event_bus()
	if event_bus and event_bus.has_signal("entity_blinded"):
		event_bus.entity_blinded.emit(BLIND_DURATION)

	print("[SageBundle] Entity blinded for %.1f seconds" % BLIND_DURATION)


func _start_hunt_prevention() -> void:
	var duration := _get_prevention_duration()
	_prevention_timer = duration
	_is_preventing_hunts = true

	var event_bus := _get_event_bus()
	if event_bus and event_bus.has_signal("hunt_prevention_started"):
		event_bus.hunt_prevention_started.emit(duration)

	print("[SageBundle] Hunt prevention started for %.1f seconds" % duration)


func _end_hunt_prevention() -> void:
	_is_preventing_hunts = false
	_prevention_timer = 0.0

	var event_bus := _get_event_bus()
	if event_bus and event_bus.has_signal("hunt_prevention_ended"):
		event_bus.hunt_prevention_ended.emit()

	print("[SageBundle] Hunt prevention ended")


func _get_prevention_duration() -> float:
	# Check if entity is Demon for reduced duration
	if _is_current_entity_demon():
		return HUNT_PREVENTION_DURATION * demon_duration_multiplier
	return HUNT_PREVENTION_DURATION


func _is_current_entity_demon() -> bool:
	# This would check the current entity type
	# For now, return false - entity system will handle this
	return false


func _create_smoke_effect() -> void:
	# Create smoke visual at player position
	if not _owning_player:
		return

	_smoke_effect = _create_smoke_visual()
	if _smoke_effect:
		_smoke_effect.global_position = _owning_player.global_position
		_add_placed_item_to_world(_smoke_effect)

		# Auto-remove smoke after duration
		var timer := get_tree().create_timer(SMOKE_DURATION)
		timer.timeout.connect(_remove_smoke_effect)


func _create_smoke_visual() -> Node3D:
	# Create a simple smoke placeholder
	# In production, this would be a GPU particle system
	var smoke := Node3D.new()
	smoke.name = "SageSmoke"

	# Simple sphere to represent smoke cloud
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "SmokeMesh"

	var sphere := SphereMesh.new()
	sphere.radius = 1.5
	sphere.height = 3.0
	mesh_instance.mesh = sphere

	# Semi-transparent material
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.7, 0.7, 0.7, 0.4)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = material

	smoke.add_child(mesh_instance)

	# Animate scale up
	smoke.scale = Vector3(0.1, 0.1, 0.1)
	var tween := create_tween()
	tween.tween_property(smoke, "scale", Vector3(1.0, 1.0, 1.0), 0.5)

	return smoke


func _remove_smoke_effect() -> void:
	if _smoke_effect and is_instance_valid(_smoke_effect):
		# Fade out animation
		var tween := create_tween()
		tween.tween_property(_smoke_effect, "scale", Vector3(0.1, 0.1, 0.1), 0.3)
		tween.tween_callback(_smoke_effect.queue_free)
		_smoke_effect = null


## Returns true if hunt prevention is active.
func is_preventing_hunts() -> bool:
	return _is_preventing_hunts


## Gets remaining hunt prevention time.
func get_prevention_time_remaining() -> float:
	return _prevention_timer


func get_network_state() -> Dictionary:
	var state := super.get_network_state()
	state["preventing"] = _is_preventing_hunts
	state["prevention_timer"] = _prevention_timer
	return state


func apply_network_state(state: Dictionary) -> void:
	super.apply_network_state(state)
	if state.has("preventing"):
		_is_preventing_hunts = state.preventing
	if state.has("prevention_timer"):
		_prevention_timer = state.prevention_timer
