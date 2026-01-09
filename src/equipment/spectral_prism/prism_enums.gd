class_name PrismEnums
extends RefCounted
## Spectral Prism Rig enumerations.
##
## Centralizes pattern and color enums for the cooperative Spectral Prism equipment.
## Patterns map to entity categories, colors provide secondary verification.

## Pattern shapes seen through the Calibrator viewfinder.
## Each shape corresponds to an entity behavioral category.
enum PrismPattern {
	NONE,  ## No pattern (not aligned)
	TRIANGLE,  ## Passive entity (Shade, Spirit-type)
	CIRCLE,  ## Aggressive entity (Demon, Oni-type)
	SQUARE,  ## Territorial entity (Goryo, Hantu-type)
	SPIRAL,  ## Mobile entity (Wraith, Phantom-type)
}

## Pattern colors seen through the Lens Reader.
## Colors provide secondary confirmation of entity category.
enum PrismColor {
	NONE,  ## No color (not calibrated)
	BLUE_VIOLET,  ## Passive entity confirmation
	RED_ORANGE,  ## Aggressive entity confirmation
	GREEN,  ## Territorial entity confirmation
	YELLOW,  ## Mobile entity confirmation
}

## Entity behavioral categories for pattern/color mapping.
enum EntityCategory {
	UNKNOWN,
	PASSIVE,  ## Shade, Spirit-type - avoids players
	AGGRESSIVE,  ## Demon, Oni-type - actively hunts
	TERRITORIAL,  ## Goryo, Hantu-type - room-bound
	MOBILE,  ## Wraith, Phantom-type - roams freely
}


## Maps a pattern to its corresponding entity category.
static func get_category_from_pattern(pattern: PrismPattern) -> EntityCategory:
	match pattern:
		PrismPattern.TRIANGLE:
			return EntityCategory.PASSIVE
		PrismPattern.CIRCLE:
			return EntityCategory.AGGRESSIVE
		PrismPattern.SQUARE:
			return EntityCategory.TERRITORIAL
		PrismPattern.SPIRAL:
			return EntityCategory.MOBILE
		_:
			return EntityCategory.UNKNOWN


## Maps a color to its corresponding entity category.
static func get_category_from_color(color: PrismColor) -> EntityCategory:
	match color:
		PrismColor.BLUE_VIOLET:
			return EntityCategory.PASSIVE
		PrismColor.RED_ORANGE:
			return EntityCategory.AGGRESSIVE
		PrismColor.GREEN:
			return EntityCategory.TERRITORIAL
		PrismColor.YELLOW:
			return EntityCategory.MOBILE
		_:
			return EntityCategory.UNKNOWN


## Returns the expected color for a given pattern (for consistency checking).
static func get_expected_color(pattern: PrismPattern) -> PrismColor:
	match pattern:
		PrismPattern.TRIANGLE:
			return PrismColor.BLUE_VIOLET
		PrismPattern.CIRCLE:
			return PrismColor.RED_ORANGE
		PrismPattern.SQUARE:
			return PrismColor.GREEN
		PrismPattern.SPIRAL:
			return PrismColor.YELLOW
		_:
			return PrismColor.NONE


## Returns the expected pattern for a given color.
static func get_expected_pattern(color: PrismColor) -> PrismPattern:
	match color:
		PrismColor.BLUE_VIOLET:
			return PrismPattern.TRIANGLE
		PrismColor.RED_ORANGE:
			return PrismPattern.CIRCLE
		PrismColor.GREEN:
			return PrismPattern.SQUARE
		PrismColor.YELLOW:
			return PrismPattern.SPIRAL
		_:
			return PrismPattern.NONE


## Returns true if pattern and color categories match.
static func is_consistent(pattern: PrismPattern, color: PrismColor) -> bool:
	if pattern == PrismPattern.NONE or color == PrismColor.NONE:
		return false
	return get_category_from_pattern(pattern) == get_category_from_color(color)


## Returns the display name for a pattern.
static func get_pattern_name(pattern: PrismPattern) -> String:
	match pattern:
		PrismPattern.NONE:
			return "None"
		PrismPattern.TRIANGLE:
			return "Triangle"
		PrismPattern.CIRCLE:
			return "Circle"
		PrismPattern.SQUARE:
			return "Square"
		PrismPattern.SPIRAL:
			return "Spiral"
		_:
			return "Unknown"


## Returns the display name for a color.
static func get_color_name(color: PrismColor) -> String:
	match color:
		PrismColor.NONE:
			return "None"
		PrismColor.BLUE_VIOLET:
			return "Blue-Violet"
		PrismColor.RED_ORANGE:
			return "Red-Orange"
		PrismColor.GREEN:
			return "Green"
		PrismColor.YELLOW:
			return "Yellow"
		_:
			return "Unknown"


## Returns the display name for an entity category.
static func get_category_name(category: EntityCategory) -> String:
	match category:
		EntityCategory.UNKNOWN:
			return "Unknown"
		EntityCategory.PASSIVE:
			return "Passive"
		EntityCategory.AGGRESSIVE:
			return "Aggressive"
		EntityCategory.TERRITORIAL:
			return "Territorial"
		EntityCategory.MOBILE:
			return "Mobile"
		_:
			return "Unknown"


## Returns all valid patterns (excluding NONE).
static func get_all_patterns() -> Array[PrismPattern]:
	return [
		PrismPattern.TRIANGLE,
		PrismPattern.CIRCLE,
		PrismPattern.SQUARE,
		PrismPattern.SPIRAL,
	]


## Returns all valid colors (excluding NONE).
static func get_all_colors() -> Array[PrismColor]:
	return [
		PrismColor.BLUE_VIOLET,
		PrismColor.RED_ORANGE,
		PrismColor.GREEN,
		PrismColor.YELLOW,
	]
