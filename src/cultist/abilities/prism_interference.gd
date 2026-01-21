class_name PrismInterferenceAbility
extends CultistAbility
## Prism Interference ability - Corrupt PRISM_READING data.
##
## Creates a contaminated spectral anchor that appears as a valid prism reading.
## The reading decays over time with visible tells.
##
## Decay visual tells (via ContaminatedSpectralAnchor):
## - PLANTED (0-60s): Consistent shape and color, indistinguishable from real
## - UNSTABLE (60-120s): Shape flickers occasionally
## - DEGRADED (120-180s): Shape unstable, color shifts erratically
## - EXPIRED (180+s): Reading becomes completely garbled

const ContaminatedEvidenceScript := preload("res://src/cultist/contaminated_evidence.gd")
const ContaminatedAnchorScript := preload("res://src/cultist/contaminated_spectral_anchor.gd")


func _init() -> void:
	ability_name = "Prism Interference"
	ability_description = "Corrupt Prism Rig readings. Shows wrong shape or color, decays over time."
	max_charges = 1
	current_charges = 1
	placement_time = 3.0  # Faster activation
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
	# Mark this as interference mode
	evidence.set_metadata("interference_mode", true)
	return evidence


## Creates the contaminated spectral anchor node that applies decay visual tells.
## Returns the node which must be added to the scene tree by the caller.
func create_spectral_anchor(evidence: ContaminatedEvidence, location: Vector3) -> Node3D:
	var anchor: Node3D = ContaminatedAnchorScript.new()
	anchor.name = "ContaminatedAnchor_%s" % evidence.uid
	anchor.position = location
	anchor.initialize(evidence)

	# Connect expiration to auto-cleanup
	if anchor.has_signal("expired"):
		anchor.expired.connect(_on_anchor_expired.bind(anchor))

	return anchor


## Executes the ability - creates evidence, spawns anchor, and emits signals.
## Returns both the evidence and the anchor node in a Dictionary.
func execute(cultist_id: int, location: Vector3) -> Dictionary:
	if not can_use():
		return {}

	var evidence := create_evidence(cultist_id, location)
	if evidence == null:
		return {}

	# Create the spectral anchor node for detection
	var anchor := create_spectral_anchor(evidence, location)

	# Use the charge and emit signals
	use(location)

	# Emit global contamination events
	if has_node("/root/EventBus"):
		var event_bus := get_node("/root/EventBus")
		if event_bus.has_signal("evidence_contaminated"):
			event_bus.evidence_contaminated.emit("PRISM_READING")
		if event_bus.has_signal("contaminated_evidence_planted"):
			event_bus.contaminated_evidence_planted.emit(evidence)

	return {"evidence": evidence, "anchor": anchor}


## Called when a contaminated spectral anchor expires.
func _on_anchor_expired(anchor: Node3D) -> void:
	if anchor and is_instance_valid(anchor):
		anchor.queue_free()


## Override get_node for Resource (needs tree access for EventBus).
func get_node(path: NodePath) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(path)


## Check if node exists.
func has_node(path: NodePath) -> bool:
	return get_node(path) != null
