class_name TemperatureManipulationAbility
extends CultistAbility
## Temperature Manipulation ability - Plant false FREEZING_TEMPERATURE zone.
##
## Creates a localized cold zone that thermometers detect as freezing.
## Zone persists for standard decay timing and then disappears.
##
## Decay visual tells (via ContaminatedTemperatureZone):
## - PLANTED (0-60s): Consistent freezing temperature (< 0°C)
## - UNSTABLE (60-120s): Temperature swings ±5° every few seconds
## - DEGRADED (120-180s): Temperature rapidly fluctuates, clearly unnatural
## - EXPIRED (180+s): Temperature returns to ambient

const ContaminatedEvidenceScript := preload("res://src/cultist/contaminated_evidence.gd")
const ContaminatedTempZoneScript := preload("res://src/cultist/contaminated_temperature_zone.gd")


func _init() -> void:
	ability_name = "Temperature Manipulation"
	ability_description = "Create a localized freezing zone. Thermometers detect false freezing temps."
	max_charges = 2
	current_charges = 2
	placement_time = 5.0
	cooldown_time = 10.0
	ability_type = CultistEnums.AbilityType.TEMPERATURE_MANIPULATION


## Creates the contaminated temperature evidence at the given location.
func create_evidence(cultist_id: int, location: Vector3) -> ContaminatedEvidence:
	var evidence: ContaminatedEvidence = ContaminatedEvidenceScript.create_contaminated(
		EvidenceEnums.EvidenceType.FREEZING_TEMPERATURE,
		cultist_id,
		location,
		CultistEnums.AbilityType.TEMPERATURE_MANIPULATION
	)
	return evidence


## Creates the contaminated temperature zone node that applies decay visual tells.
## Returns the node which must be added to the scene tree by the caller.
func create_temperature_zone(evidence: ContaminatedEvidence, location: Vector3) -> Node3D:
	var zone: Node3D = ContaminatedTempZoneScript.new()
	zone.name = "ContaminatedTempZone_%s" % evidence.uid
	zone.position = location
	zone.initialize(evidence)

	# Connect expiration to auto-cleanup
	if zone.has_signal("expired"):
		zone.expired.connect(_on_zone_expired.bind(zone))

	return zone


## Executes the ability - creates evidence, spawns zone, and emits signals.
## Returns both the evidence and the zone node in a Dictionary.
func execute(cultist_id: int, location: Vector3) -> Dictionary:
	if not can_use():
		return {}

	var evidence := create_evidence(cultist_id, location)
	if evidence == null:
		return {}

	# Create the temperature zone node for detection
	var zone := create_temperature_zone(evidence, location)

	# Use the charge and emit signals
	use(location)

	# Emit global contamination events
	if has_node("/root/EventBus"):
		var event_bus := get_node("/root/EventBus")
		if event_bus.has_signal("evidence_contaminated"):
			event_bus.evidence_contaminated.emit("FREEZING_TEMPERATURE")
		if event_bus.has_signal("contaminated_evidence_planted"):
			event_bus.contaminated_evidence_planted.emit(evidence)

	return {"evidence": evidence, "zone": zone}


## Called when a contaminated temperature zone expires.
func _on_zone_expired(zone: Node3D) -> void:
	if zone and is_instance_valid(zone):
		zone.queue_free()


## Override get_node for Resource (needs tree access for EventBus).
func get_node(path: NodePath) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(path)


## Check if node exists.
func has_node(path: NodePath) -> bool:
	return get_node(path) != null
