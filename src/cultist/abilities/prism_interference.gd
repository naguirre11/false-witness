class_name PrismInterferenceAbility
extends CultistAbility
## Prism Interference ability - Corrupt PRISM_READING data.
##
## When activated, the next Prism Rig reading shows false data.
## One-time use per charge - interference applies to next reading only.

const ContaminatedEvidenceScript := preload("res://src/cultist/contaminated_evidence.gd")


func _init() -> void:
	ability_name = "Prism Interference"
	ability_description = "Corrupt the next Prism Rig reading. Shows wrong shape or color."
	max_charges = 1
	current_charges = 1
	placement_time = 3.0  # Faster activation, one-time effect
	cooldown_time = 0.0  # No cooldown since single use
	ability_type = CultistEnums.AbilityType.PRISM_INTERFERENCE


## Creates the contaminated prism evidence at the given location.
func create_evidence(cultist_id: int, location: Vector3) -> ContaminatedEvidence:
	var evidence: ContaminatedEvidence = ContaminatedEvidenceScript.create_contaminated(
		EvidenceEnums.EvidenceType.PRISM_READING,
		cultist_id,
		location,
		CultistEnums.AbilityType.PRISM_INTERFERENCE
	)
	# Mark this as interference mode - affects next reading
	evidence.set_metadata("interference_mode", true)
	return evidence


## Executes the ability - registers interference with Prism system.
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
			event_bus.evidence_contaminated.emit("PRISM_READING")
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
