class_name TemperatureManipulationAbility
extends CultistAbility
## Temperature Manipulation ability - Plant false FREEZING_TEMPERATURE zone.
##
## Creates a localized cold zone that thermometers detect as freezing.
## Zone persists for standard decay timing and then disappears.

const ContaminatedEvidenceScript := preload("res://src/cultist/contaminated_evidence.gd")


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


## Executes the ability - creates evidence and emits signals.
func execute(cultist_id: int, location: Vector3) -> ContaminatedEvidence:
	if not can_use():
		return null

	var evidence := create_evidence(cultist_id, location)
	if evidence == null:
		return null

	# Use the charge and emit signals
	use(location)

	# Emit global contamination events
	if has_node("/root/EventBus"):
		var event_bus := get_node("/root/EventBus")
		if event_bus.has_signal("evidence_contaminated"):
			event_bus.evidence_contaminated.emit("FREEZING_TEMPERATURE")
		if event_bus.has_signal("contaminated_evidence_planted"):
			event_bus.contaminated_evidence_planted.emit(evidence)

	return evidence


## Override get_node for Resource (needs tree access for EventBus).
func get_node(path: NodePath) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(path)


## Check if node exists.
func has_node(path: NodePath) -> bool:
	return get_node(path) != null
