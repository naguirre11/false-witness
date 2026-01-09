class_name SpectralAnchor
extends Node3D
## Mock anchor point for Spectral Prism testing.
##
## In the full game, entities will provide anchor points with true patterns.
## This class simulates that for development and testing of the Calibrator.

const PrismEnumsScript := preload("res://src/equipment/spectral_prism/prism_enums.gd")

## The true pattern this anchor represents (determined by entity type).
@export var true_pattern: PrismEnumsScript.PrismPattern = PrismEnumsScript.PrismPattern.NONE

## The corresponding color for the true pattern.
@export var true_color: PrismEnumsScript.PrismColor = PrismEnumsScript.PrismColor.NONE

## Detection range for line-of-sight checks.
@export var detection_range: float = 15.0


func _ready() -> void:
	# Auto-set color from pattern if not manually set
	var color_none := PrismEnumsScript.PrismColor.NONE
	var pattern_none := PrismEnumsScript.PrismPattern.NONE
	if true_color == color_none and true_pattern != pattern_none:
		true_color = PrismEnumsScript.get_expected_color(true_pattern)


## Returns the true pattern for this anchor.
func get_true_pattern() -> PrismEnumsScript.PrismPattern:
	return true_pattern


## Returns the true color for this anchor.
func get_true_color() -> PrismEnumsScript.PrismColor:
	return true_color


## Returns the entity category this anchor represents.
func get_entity_category() -> PrismEnumsScript.EntityCategory:
	return PrismEnumsScript.get_category_from_pattern(true_pattern)


## Sets the anchor's pattern (and auto-updates color).
func set_pattern(pattern: PrismEnumsScript.PrismPattern) -> void:
	true_pattern = pattern
	true_color = PrismEnumsScript.get_expected_color(pattern)
