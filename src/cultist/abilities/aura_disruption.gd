class_name AuraDisruptionAbility
extends CultistAbility
## Aura Disruption ability - Plant false AURA_PATTERN trails.
##
## Creates a contaminated aura anchor that appears as a valid aura reading.
## The reading decays over time with visible tells.
##
## Decay visual tells (via ContaminatedAuraAnchor):
## - PLANTED (0-60s): Clear aura trail, consistent color/form
## - UNSTABLE (60-120s): Trail fades slightly, occasional flicker
## - DEGRADED (120-180s): Trail direction inconsistent, form unstable
## - EXPIRED (180+s): Aura trail disappears

const ContaminatedEvidenceScript := preload("res://src/cultist/contaminated_evidence.gd")
const ContaminatedAuraAnchorScript := preload("res://src/cultist/contaminated_aura_anchor.gd")


func _init() -> void:
	ability_name = "Aura Disruption"
	ability_description = "Plant false aura trails. Shows misleading color/form patterns, decays over time."
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


## Creates the contaminated aura anchor node that applies decay visual tells.
## Returns the node which must be added to the scene tree by the caller.
func create_aura_anchor(evidence: ContaminatedEvidence, location: Vector3) -> Node3D:
	var anchor: Node3D = ContaminatedAuraAnchorScript.new()
	anchor.name = "ContaminatedAuraAnchor_%s" % evidence.uid
	anchor.position = location

	# Use the colors/forms from evidence metadata
	var false_color: int = evidence.get_metadata("false_color")
	var false_form: int = evidence.get_metadata("false_form")
	anchor.initialize_with_aura(evidence, false_color, false_form)

	# Connect expiration to auto-cleanup
	if anchor.has_signal("expired"):
		anchor.expired.connect(_on_anchor_expired.bind(anchor))

	return anchor


## Generates a random false aura color.
func _generate_false_color() -> int:
	# AuraEnums.AuraColor values: COLD_BLUE=1, HOT_RED=2, PALE_GREEN=3, DEEP_PURPLE=4
	return (randi() % 4) + 1


## Generates a random false aura form.
func _generate_false_form() -> int:
	# AuraEnums.AuraForm values: TIGHT_CONTAINED=1, SPIKING_ERRATIC=2, etc.
	return (randi() % 4) + 1


## Executes the ability - creates evidence, spawns anchor, and emits signals.
## Returns both the evidence and the anchor node in a Dictionary.
func execute(cultist_id: int, location: Vector3) -> Dictionary:
	if not can_use():
		return {}

	var evidence := create_evidence(cultist_id, location)
	if evidence == null:
		return {}

	# Create the aura anchor node for detection
	var anchor := create_aura_anchor(evidence, location)

	# Use the charge and emit signals
	use(location)

	# Emit global contamination events
	if has_node("/root/EventBus"):
		var event_bus := get_node("/root/EventBus")
		if event_bus.has_signal("evidence_contaminated"):
			event_bus.evidence_contaminated.emit("AURA_PATTERN")
		if event_bus.has_signal("contaminated_evidence_planted"):
			event_bus.contaminated_evidence_planted.emit(evidence)

	return {"evidence": evidence, "anchor": anchor}


## Called when a contaminated aura anchor expires.
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
