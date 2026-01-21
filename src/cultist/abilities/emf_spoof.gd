class_name EMFSpoofAbility
extends CultistAbility
## EMF Spoof ability - Plant false EMF_SIGNATURE readings.
##
## Creates contaminated evidence that appears as EMF Level 5 readings.
## Evidence decays over 3 minutes and then disappears.
##
## Decay visual tells (via ContaminatedEMFSource):
## - PLANTED (0-60s): Steady Level 5, indistinguishable from real
## - UNSTABLE (60-120s): Flickers between levels randomly
## - DEGRADED (120-180s): Resets to 0 periodically, erratic behavior
## - EXPIRED (180+s): Source disappears, no longer detected

const ContaminatedEvidenceScript := preload("res://src/cultist/contaminated_evidence.gd")
const ContaminatedEMFSourceScript := preload("res://src/cultist/contaminated_emf_source.gd")


func _init() -> void:
	ability_name = "EMF Spoof"
	ability_description = "Plant false EMF Level 5 readings. Evidence appears authentic but decays over 3 minutes."
	max_charges = 2
	current_charges = 2
	placement_time = 5.0
	cooldown_time = 10.0
	ability_type = CultistEnums.AbilityType.EMF_SPOOF


## Creates the contaminated EMF evidence at the given location.
func create_evidence(cultist_id: int, location: Vector3) -> ContaminatedEvidence:
	var evidence: ContaminatedEvidence = ContaminatedEvidenceScript.create_contaminated(
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		cultist_id,
		location,
		CultistEnums.AbilityType.EMF_SPOOF
	)
	return evidence


## Creates the contaminated EMF source node that applies decay visual tells.
## Returns the node which must be added to the scene tree by the caller.
func create_emf_source(evidence: ContaminatedEvidence, location: Vector3) -> Node3D:
	var source: Node3D = ContaminatedEMFSourceScript.new()
	source.name = "ContaminatedEMFSource_%s" % evidence.uid
	source.position = location
	source.initialize(evidence)

	# Connect expiration to auto-cleanup
	if source.has_signal("expired"):
		source.expired.connect(_on_source_expired.bind(source))

	return source


## Executes the ability - creates evidence, spawns source, and emits signals.
## Returns both the evidence and the source node in a Dictionary.
func execute(cultist_id: int, location: Vector3) -> Dictionary:
	if not can_use():
		return {}

	var evidence := create_evidence(cultist_id, location)
	if evidence == null:
		return {}

	# Create the EMF source node for detection
	var source := create_emf_source(evidence, location)

	# Use the charge and emit signals
	use(location)

	# Emit global contamination events
	if has_node("/root/EventBus"):
		var event_bus := get_node("/root/EventBus")
		if event_bus.has_signal("evidence_contaminated"):
			event_bus.evidence_contaminated.emit("EMF_SIGNATURE")
		if event_bus.has_signal("contaminated_evidence_planted"):
			event_bus.contaminated_evidence_planted.emit(evidence)

	return {"evidence": evidence, "source": source}


## Called when a contaminated EMF source expires.
func _on_source_expired(source: Node3D) -> void:
	if source and is_instance_valid(source):
		source.queue_free()


## Override get_node for Resource (needs tree access for EventBus).
func get_node(path: NodePath) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(path)


## Check if node exists.
func has_node(path: NodePath) -> bool:
	return get_node(path) != null
