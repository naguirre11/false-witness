class_name EntityMatrix
extends Control
## Entity possibility matrix showing which entities could match collected evidence.
##
## Displays a grid with entity types as rows and evidence types as columns.
## Checkmarks show which evidence each entity can produce.
## Entities that don't match collected evidence are grayed out (eliminated).
## Remaining possibilities are highlighted.

signal entity_selected(entity_type: String)

# --- Constants ---

## All entity types in the game (matching EntitySelection.ALL_ENTITIES)
const ALL_ENTITIES: Array[String] = [
	"Phantom",
	"Banshee",
	"Revenant",
	"Shade",
	"Poltergeist",
	"Wraith",
	"Mare",
	"Demon",
]

## Map entity types to evidence they can produce (using EvidenceEnums.EvidenceType names)
## Each entity produces exactly 3 evidence types
const ENTITY_EVIDENCE_MAP: Dictionary = {
	"Phantom": [
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		EvidenceEnums.EvidenceType.FREEZING_TEMPERATURE,
		EvidenceEnums.EvidenceType.VISUAL_MANIFESTATION,
	],
	"Banshee": [
		EvidenceEnums.EvidenceType.PRISM_READING,
		EvidenceEnums.EvidenceType.AURA_PATTERN,
		EvidenceEnums.EvidenceType.HUNT_BEHAVIOR,
	],
	"Revenant": [
		EvidenceEnums.EvidenceType.FREEZING_TEMPERATURE,
		EvidenceEnums.EvidenceType.GHOST_WRITING,
		EvidenceEnums.EvidenceType.HUNT_BEHAVIOR,
	],
	"Shade": [
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		EvidenceEnums.EvidenceType.GHOST_WRITING,
		EvidenceEnums.EvidenceType.VISUAL_MANIFESTATION,
	],
	"Poltergeist": [
		EvidenceEnums.EvidenceType.PHYSICAL_INTERACTION,
		EvidenceEnums.EvidenceType.GHOST_WRITING,
		EvidenceEnums.EvidenceType.AURA_PATTERN,
	],
	"Wraith": [
		EvidenceEnums.EvidenceType.EMF_SIGNATURE,
		EvidenceEnums.EvidenceType.PRISM_READING,
		EvidenceEnums.EvidenceType.PHYSICAL_INTERACTION,
	],
	"Mare": [
		EvidenceEnums.EvidenceType.FREEZING_TEMPERATURE,
		EvidenceEnums.EvidenceType.PRISM_READING,
		EvidenceEnums.EvidenceType.GHOST_WRITING,
	],
	"Demon": [
		EvidenceEnums.EvidenceType.AURA_PATTERN,
		EvidenceEnums.EvidenceType.PHYSICAL_INTERACTION,
		EvidenceEnums.EvidenceType.HUNT_BEHAVIOR,
	],
}

## All 8 evidence types in display order
const ALL_EVIDENCE_TYPES: Array[int] = [
	EvidenceEnums.EvidenceType.EMF_SIGNATURE,
	EvidenceEnums.EvidenceType.FREEZING_TEMPERATURE,
	EvidenceEnums.EvidenceType.PRISM_READING,
	EvidenceEnums.EvidenceType.AURA_PATTERN,
	EvidenceEnums.EvidenceType.GHOST_WRITING,
	EvidenceEnums.EvidenceType.VISUAL_MANIFESTATION,
	EvidenceEnums.EvidenceType.PHYSICAL_INTERACTION,
	EvidenceEnums.EvidenceType.HUNT_BEHAVIOR,
]

## Short evidence type abbreviations for column headers
const EVIDENCE_ABBREVIATIONS: Dictionary = {
	EvidenceEnums.EvidenceType.EMF_SIGNATURE: "EMF",
	EvidenceEnums.EvidenceType.FREEZING_TEMPERATURE: "Temp",
	EvidenceEnums.EvidenceType.PRISM_READING: "Prism",
	EvidenceEnums.EvidenceType.AURA_PATTERN: "Aura",
	EvidenceEnums.EvidenceType.GHOST_WRITING: "Write",
	EvidenceEnums.EvidenceType.VISUAL_MANIFESTATION: "Visual",
	EvidenceEnums.EvidenceType.PHYSICAL_INTERACTION: "Phys",
	EvidenceEnums.EvidenceType.HUNT_BEHAVIOR: "Hunt",
}

# --- State ---

var _eliminated_entities: Array[String] = []
var _collected_evidence: Array[int] = []  # EvidenceType values

# --- Node References ---

@onready var _grid: GridContainer = %MatrixGrid
@onready var _remaining_label: Label = %RemainingLabel


func _ready() -> void:
	_build_matrix()
	_connect_signals()
	_update_eliminations()


func _connect_signals() -> void:
	var evidence_manager := _get_evidence_manager()
	if evidence_manager:
		if evidence_manager.has_signal("evidence_collected"):
			evidence_manager.evidence_collected.connect(_on_evidence_collected)
		if evidence_manager.has_signal("evidence_cleared"):
			evidence_manager.evidence_cleared.connect(_on_evidence_cleared)


func _build_matrix() -> void:
	if not _grid:
		push_error("[EntityMatrix] MatrixGrid not found")
		return

	# Clear existing children
	for child in _grid.get_children():
		child.queue_free()

	# Grid has 9 columns: Entity name + 8 evidence types
	_grid.columns = 9

	# Header row: empty corner + evidence type abbreviations
	var corner := Label.new()
	corner.text = ""
	corner.custom_minimum_size = Vector2(80, 24)
	_grid.add_child(corner)

	for evidence_type in ALL_EVIDENCE_TYPES:
		var header := Label.new()
		header.text = EVIDENCE_ABBREVIATIONS.get(evidence_type, "?")
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.add_theme_font_size_override("font_size", 11)
		header.custom_minimum_size = Vector2(40, 24)
		header.tooltip_text = EvidenceEnums.get_evidence_name(evidence_type)
		_grid.add_child(header)

	# Entity rows
	for entity_type in ALL_ENTITIES:
		_add_entity_row(entity_type)


func _add_entity_row(entity_type: String) -> void:
	# Entity name label (clickable)
	var name_button := Button.new()
	name_button.text = entity_type
	name_button.flat = true
	name_button.custom_minimum_size = Vector2(80, 24)
	name_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_button.name = "Entity_%s" % entity_type
	name_button.pressed.connect(_on_entity_pressed.bind(entity_type))
	_grid.add_child(name_button)

	# Evidence checkmarks
	var entity_evidence: Array = ENTITY_EVIDENCE_MAP.get(entity_type, [])
	for evidence_type in ALL_EVIDENCE_TYPES:
		var cell := Label.new()
		if evidence_type in entity_evidence:
			cell.text = "✓"
			cell.add_theme_color_override("font_color", Color.WHITE)
		else:
			cell.text = "·"
			cell.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
		cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.custom_minimum_size = Vector2(40, 24)
		cell.name = "Cell_%s_%d" % [entity_type, evidence_type]
		_grid.add_child(cell)


func _update_eliminations() -> void:
	_eliminated_entities.clear()

	# An entity is eliminated if it CANNOT produce any of the collected evidence
	for entity_type in ALL_ENTITIES:
		var entity_evidence: Array = ENTITY_EVIDENCE_MAP.get(entity_type, [])
		var is_eliminated := false

		for collected_type in _collected_evidence:
			if collected_type not in entity_evidence:
				is_eliminated = true
				break

		if is_eliminated:
			_eliminated_entities.append(entity_type)

	_update_visual_state()
	_update_remaining_label()


func _update_visual_state() -> void:
	if not _grid:
		return

	for entity_type in ALL_ENTITIES:
		var is_eliminated := entity_type in _eliminated_entities

		# Update entity name button
		var name_button := _grid.get_node_or_null("Entity_%s" % entity_type)
		if name_button is Button:
			if is_eliminated:
				name_button.modulate = Color(0.4, 0.4, 0.4)
				name_button.disabled = true
			else:
				name_button.modulate = Color.WHITE
				name_button.disabled = false

		# Update evidence cells
		for evidence_type in ALL_EVIDENCE_TYPES:
			var cell := _grid.get_node_or_null("Cell_%s_%d" % [entity_type, evidence_type])
			if cell is Label:
				if is_eliminated:
					cell.modulate = Color(0.4, 0.4, 0.4)
				elif evidence_type in _collected_evidence:
					# Highlight collected evidence columns
					var entity_evidence: Array = ENTITY_EVIDENCE_MAP.get(entity_type, [])
					if evidence_type in entity_evidence:
						cell.add_theme_color_override("font_color", Color.GREEN)
					cell.modulate = Color.WHITE
				else:
					cell.modulate = Color.WHITE


func _update_remaining_label() -> void:
	if not _remaining_label:
		return

	var remaining := ALL_ENTITIES.size() - _eliminated_entities.size()
	if remaining == 1:
		# Find the remaining entity
		for entity_type in ALL_ENTITIES:
			if entity_type not in _eliminated_entities:
				_remaining_label.text = "Match: %s" % entity_type
				_remaining_label.add_theme_color_override("font_color", Color.GREEN)
				break
	else:
		_remaining_label.text = "%d possible entities" % remaining
		if remaining <= 3:
			_remaining_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			_remaining_label.add_theme_color_override("font_color", Color.WHITE)


## Returns true if the entity type can produce the given evidence.
func entity_produces_evidence(
	entity_type: String, evidence_type: EvidenceEnums.EvidenceType
) -> bool:
	var entity_evidence: Array = ENTITY_EVIDENCE_MAP.get(entity_type, [])
	return evidence_type in entity_evidence


## Returns the list of eliminated entities.
func get_eliminated_entities() -> Array[String]:
	return _eliminated_entities.duplicate()


## Returns the list of remaining (non-eliminated) entities.
func get_remaining_entities() -> Array[String]:
	var remaining: Array[String] = []
	for entity_type in ALL_ENTITIES:
		if entity_type not in _eliminated_entities:
			remaining.append(entity_type)
	return remaining


## Manually set collected evidence (for testing/debugging).
func set_collected_evidence(evidence_types: Array[int]) -> void:
	_collected_evidence = evidence_types.duplicate()
	_update_eliminations()


func _on_evidence_collected(evidence: Evidence) -> void:
	if evidence.type not in _collected_evidence:
		_collected_evidence.append(evidence.type)
		_update_eliminations()


func _on_evidence_cleared() -> void:
	_collected_evidence.clear()
	_update_eliminations()


func _on_entity_pressed(entity_type: String) -> void:
	entity_selected.emit(entity_type)


func _get_evidence_manager() -> Node:
	if has_node("/root/EvidenceManager"):
		return get_node("/root/EvidenceManager")
	return null
