class_name AuraDisruptionAbility
extends CultistAbility
## Aura Disruption ability - Plant false AURA_PATTERN trails.
##
## Creates false aura trails that show wrong color/form combinations.
## Aura Imager detects these false patterns.

const ContaminatedEvidenceScript := preload("res://src/cultist/contaminated_evidence.gd")


func _init() -> void:
	ability_name = "Aura Disruption"
	ability_description = "Plant false aura trails. Shows misleading color/form patterns."
	max_charges = 2
	current_charges = 2
	placement_time = 5.0
	cooldown_time = 10.0
	ability_type = CultistEnums.AbilityType.AURA_DISRUPTION


## Creates the contaminated aura evidence at the given location.
func create_evidence(cultist_id: int, location: Vector3) -> ContaminatedEvidence:
	var evidence: ContaminatedEvidence = ContaminatedEvidenceScript.create_contaminated(
		EvidenceEnums.EvidenceType.AURA_PATTERN,
		cultist_id,
		location,
		CultistEnums.AbilityType.AURA_DISRUPTION
	)
	# Set false aura data - inconsistent color/form
	evidence.set_metadata("false_color", _generate_false_color())
	evidence.set_metadata("false_form", _generate_false_form())
	return evidence


## Generates a random false aura color.
func _generate_false_color() -> int:
	# AuraEnums.AuraColor values: COLD_BLUE, HOT_RED, PALE_GREEN, DEEP_PURPLE
	return randi() % 4


## Generates a random false aura form.
func _generate_false_form() -> int:
	# AuraEnums.AuraForm values: TIGHT_CONTAINED, SPIKING_ERRATIC, DIFFUSE_SPREADING, SWIRLING_MOBILE
	return randi() % 4


## Executes the ability - creates false aura trail.
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
			event_bus.evidence_contaminated.emit("AURA_PATTERN")
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
