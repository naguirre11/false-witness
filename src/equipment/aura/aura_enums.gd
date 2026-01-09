class_name AuraEnums
extends RefCounted
## Aura Imager equipment enumerations.
##
## Centralizes color and form enums for the cooperative Dowsing Rods + Aura Imager equipment.
## Colors map to entity temperament, forms map to entity behavior patterns.
## When color and form categories match, the reading is consistent.

## Aura colors seen through the Aura Imager screen.
## Each color indicates entity temperament.
enum AuraColor {
	NONE,  ## No color visible (not resolved)
	COLD_BLUE,  ## Passive/shy entity
	HOT_RED,  ## Aggressive entity
	PALE_GREEN,  ## Territorial entity
	DEEP_PURPLE,  ## Roaming entity
}

## Aura forms (patterns) seen through the Aura Imager screen.
## Each form indicates entity behavioral pattern.
enum AuraForm {
	NONE,  ## No form visible (not resolved)
	TIGHT_CONTAINED,  ## Passive behavior (stays in place, avoids)
	SPIKING_ERRATIC,  ## Aggressive behavior (unpredictable, attacks)
	DIFFUSE_SPREADING,  ## Territorial behavior (expands from anchor)
	SWIRLING_MOBILE,  ## Roaming behavior (moves freely)
}

## Entity temperament categories for color mapping.
enum EntityTemperament {
	UNKNOWN,
	PASSIVE,  ## Shy, avoids contact
	AGGRESSIVE,  ## Actively hostile
	TERRITORIAL,  ## Guards specific area
	ROAMING,  ## Moves freely, unpredictable location
}


## Maps an aura color to its corresponding entity temperament.
static func get_temperament_from_color(color: AuraColor) -> EntityTemperament:
	match color:
		AuraColor.COLD_BLUE:
			return EntityTemperament.PASSIVE
		AuraColor.HOT_RED:
			return EntityTemperament.AGGRESSIVE
		AuraColor.PALE_GREEN:
			return EntityTemperament.TERRITORIAL
		AuraColor.DEEP_PURPLE:
			return EntityTemperament.ROAMING
		_:
			return EntityTemperament.UNKNOWN


## Maps an aura form to its corresponding entity temperament.
static func get_temperament_from_form(form: AuraForm) -> EntityTemperament:
	match form:
		AuraForm.TIGHT_CONTAINED:
			return EntityTemperament.PASSIVE
		AuraForm.SPIKING_ERRATIC:
			return EntityTemperament.AGGRESSIVE
		AuraForm.DIFFUSE_SPREADING:
			return EntityTemperament.TERRITORIAL
		AuraForm.SWIRLING_MOBILE:
			return EntityTemperament.ROAMING
		_:
			return EntityTemperament.UNKNOWN


## Returns the expected form for a given color (for consistency checking).
static func get_expected_form(color: AuraColor) -> AuraForm:
	match color:
		AuraColor.COLD_BLUE:
			return AuraForm.TIGHT_CONTAINED
		AuraColor.HOT_RED:
			return AuraForm.SPIKING_ERRATIC
		AuraColor.PALE_GREEN:
			return AuraForm.DIFFUSE_SPREADING
		AuraColor.DEEP_PURPLE:
			return AuraForm.SWIRLING_MOBILE
		_:
			return AuraForm.NONE


## Returns the expected color for a given form.
static func get_expected_color(form: AuraForm) -> AuraColor:
	match form:
		AuraForm.TIGHT_CONTAINED:
			return AuraColor.COLD_BLUE
		AuraForm.SPIKING_ERRATIC:
			return AuraColor.HOT_RED
		AuraForm.DIFFUSE_SPREADING:
			return AuraColor.PALE_GREEN
		AuraForm.SWIRLING_MOBILE:
			return AuraColor.DEEP_PURPLE
		_:
			return AuraColor.NONE


## Returns true if color and form temperaments match.
## Inconsistency indicates either misalignment or deception.
static func is_consistent(color: AuraColor, form: AuraForm) -> bool:
	if color == AuraColor.NONE or form == AuraForm.NONE:
		return false
	return get_temperament_from_color(color) == get_temperament_from_form(form)


## Returns the display name for a color.
static func get_color_name(color: AuraColor) -> String:
	match color:
		AuraColor.NONE:
			return "None"
		AuraColor.COLD_BLUE:
			return "Cold Blue"
		AuraColor.HOT_RED:
			return "Hot Red"
		AuraColor.PALE_GREEN:
			return "Pale Green"
		AuraColor.DEEP_PURPLE:
			return "Deep Purple"
		_:
			return "Unknown"


## Returns the display name for a form.
static func get_form_name(form: AuraForm) -> String:
	match form:
		AuraForm.NONE:
			return "None"
		AuraForm.TIGHT_CONTAINED:
			return "Tight/Contained"
		AuraForm.SPIKING_ERRATIC:
			return "Spiking/Erratic"
		AuraForm.DIFFUSE_SPREADING:
			return "Diffuse/Spreading"
		AuraForm.SWIRLING_MOBILE:
			return "Swirling/Mobile"
		_:
			return "Unknown"


## Returns the display name for a temperament.
static func get_temperament_name(temperament: EntityTemperament) -> String:
	match temperament:
		EntityTemperament.UNKNOWN:
			return "Unknown"
		EntityTemperament.PASSIVE:
			return "Passive"
		EntityTemperament.AGGRESSIVE:
			return "Aggressive"
		EntityTemperament.TERRITORIAL:
			return "Territorial"
		EntityTemperament.ROAMING:
			return "Roaming"
		_:
			return "Unknown"


## Returns the temperament description for UI display.
static func get_temperament_description(temperament: EntityTemperament) -> String:
	match temperament:
		EntityTemperament.PASSIVE:
			return "Shy, avoids contact with investigators"
		EntityTemperament.AGGRESSIVE:
			return "Actively hostile, prone to attacking"
		EntityTemperament.TERRITORIAL:
			return "Guards a specific area or room"
		EntityTemperament.ROAMING:
			return "Moves freely throughout the location"
		_:
			return "Unknown behavior pattern"


## Returns all valid colors (excluding NONE).
static func get_all_colors() -> Array[AuraColor]:
	return [
		AuraColor.COLD_BLUE,
		AuraColor.HOT_RED,
		AuraColor.PALE_GREEN,
		AuraColor.DEEP_PURPLE,
	]


## Returns all valid forms (excluding NONE).
static func get_all_forms() -> Array[AuraForm]:
	return [
		AuraForm.TIGHT_CONTAINED,
		AuraForm.SPIKING_ERRATIC,
		AuraForm.DIFFUSE_SPREADING,
		AuraForm.SWIRLING_MOBILE,
	]


## Returns a combined signature string for evidence display.
static func get_combined_signature(color: AuraColor, form: AuraForm) -> String:
	if color == AuraColor.NONE and form == AuraForm.NONE:
		return "No reading"
	if color == AuraColor.NONE:
		return "Form: %s (color unresolved)" % get_form_name(form)
	if form == AuraForm.NONE:
		return "Color: %s (form unresolved)" % get_color_name(color)
	return "%s aura, %s pattern" % [get_color_name(color), get_form_name(form)]
