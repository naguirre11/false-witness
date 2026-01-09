class_name AuraAnchor
extends Node3D
## Mock anchor point for Aura equipment testing.
##
## In the full game, entities will provide anchor points with aura properties.
## This class simulates that for development and testing of the Dowsing Rods
## and Aura Imager equipment.

const AuraEnumsScript := preload("res://src/equipment/aura/aura_enums.gd")
const SpatialConstraintsScript := preload("res://src/equipment/aura/spatial_constraints.gd")

## The true aura color this anchor emits (determined by entity temperament).
@export var true_color: AuraEnumsScript.AuraColor = AuraEnumsScript.AuraColor.NONE

## The true aura form this anchor emits (determined by entity behavior).
@export var true_form: AuraEnumsScript.AuraForm = AuraEnumsScript.AuraForm.NONE

## Ideal position for the Dowser relative to anchor (for strong alignment).
@export var ideal_dowser_offset: Vector3 = Vector3(0, 0, 3)

## Detection range for line-of-sight checks.
@export var detection_range: float = 15.0


func _ready() -> void:
	add_to_group("aura_anchors")

	# Auto-set form from color if only color is specified
	var form_none := AuraEnumsScript.AuraForm.NONE
	var color_none := AuraEnumsScript.AuraColor.NONE
	if true_form == form_none and true_color != color_none:
		true_form = AuraEnumsScript.get_expected_form(true_color)


## Returns the true aura color for this anchor.
func get_true_color() -> AuraEnumsScript.AuraColor:
	return true_color


## Returns the true aura form for this anchor.
func get_true_form() -> AuraEnumsScript.AuraForm:
	return true_form


## Returns the entity temperament this anchor represents.
func get_entity_temperament() -> AuraEnumsScript.EntityTemperament:
	return AuraEnumsScript.get_temperament_from_color(true_color)


## Returns true if the color and form are consistent.
func is_consistent() -> bool:
	return AuraEnumsScript.is_consistent(true_color, true_form)


## Returns the combined signature string.
func get_signature() -> String:
	return AuraEnumsScript.get_combined_signature(true_color, true_form)


## Sets the anchor's color (and auto-updates form for consistency).
func set_color(color: AuraEnumsScript.AuraColor) -> void:
	true_color = color
	true_form = AuraEnumsScript.get_expected_form(color)


## Sets the anchor's form (and auto-updates color for consistency).
func set_form(form: AuraEnumsScript.AuraForm) -> void:
	true_form = form
	true_color = AuraEnumsScript.get_expected_color(form)


## Returns the ideal Dowser position for this anchor (world space).
func get_ideal_dowser_position() -> Vector3:
	if is_inside_tree():
		return global_position + global_transform.basis * ideal_dowser_offset
	return position + transform.basis * ideal_dowser_offset


## Returns the facing direction the Dowser should have for ideal alignment.
func get_ideal_dowser_facing() -> Vector3:
	if is_inside_tree():
		return (global_position - get_ideal_dowser_position()).normalized()
	return (position - get_ideal_dowser_position()).normalized()


## Returns alignment quality for a given Dowser-Imager configuration.
func calculate_alignment(
	dowser_position: Vector3, dowser_facing: Vector3, imager_position: Vector3
) -> float:
	var anchor_pos: Vector3
	if is_inside_tree():
		anchor_pos = global_position
	else:
		anchor_pos = position

	return SpatialConstraintsScript.calculate_alignment_quality(
		dowser_position, dowser_facing, imager_position, anchor_pos
	)
