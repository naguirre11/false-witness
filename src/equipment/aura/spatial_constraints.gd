class_name SpatialConstraints
extends RefCounted
## Validates spatial positioning for asymmetric cooperative equipment.
##
## The Dowsing Rods + Aura Imager require specific spatial relationships:
## - Dowser must face the anchor point (entity location)
## - Imager must be behind the Dowser (to aim at their back/rods)
##
## These constraints emerge from the equipment's physical operation and create
## the asymmetric trust dynamic: the Dowser's position is visible to all,
## while only the Imager sees the screen.

## Result of a constraint validation check.
class ConstraintResult:
	var is_valid: bool = false
	var violations: Array[String] = []
	var dowser_facing_angle: float = 0.0  ## Angle between Dowser forward and anchor
	var imager_behind_angle: float = 0.0  ## Angle between Dowser back and Imager direction

	func _init(valid: bool = false) -> void:
		is_valid = valid
		violations = []


## Configuration for spatial constraint checking.
class ConstraintConfig:
	## Maximum angle (radians) Dowser can deviate from facing anchor.
	var dowser_facing_tolerance: float = deg_to_rad(30.0)

	## Maximum angle (radians) Imager can deviate from being behind Dowser.
	var imager_behind_tolerance: float = deg_to_rad(60.0)

	## Minimum distance Imager must be from Dowser.
	var min_imager_distance: float = 1.0

	## Maximum distance Imager can be from Dowser.
	var max_imager_distance: float = 5.0

	func _init() -> void:
		pass

	## Creates config with custom values.
	static func custom(
		facing_tolerance_deg: float,
		behind_tolerance_deg: float,
		min_dist: float = 1.0,
		max_dist: float = 5.0
	) -> ConstraintConfig:
		var config := ConstraintConfig.new()
		config.dowser_facing_tolerance = deg_to_rad(facing_tolerance_deg)
		config.imager_behind_tolerance = deg_to_rad(behind_tolerance_deg)
		config.min_imager_distance = min_dist
		config.max_imager_distance = max_dist
		return config


## Quality level based on alignment quality value.
enum AlignmentQuality {
	NONE,  ## Invalid positioning
	WEAK,  ## Barely within tolerance
	MODERATE,  ## Acceptable positioning
	STRONG,  ## Good positioning
}


## Default configuration instance.
static var default_config := ConstraintConfig.new()


## Validates all spatial constraints for the Dowser-Imager-Anchor triangle.
## Returns a ConstraintResult with validity and any violations.
static func validate_positions(
	dowser_position: Vector3,
	dowser_forward: Vector3,
	imager_position: Vector3,
	anchor_position: Vector3,
	config: ConstraintConfig = null
) -> ConstraintResult:
	if config == null:
		config = default_config

	var result := ConstraintResult.new(true)

	# Check Dowser facing anchor
	var facing_result := check_dowser_facing_anchor(
		dowser_position, dowser_forward, anchor_position, config.dowser_facing_tolerance
	)
	result.dowser_facing_angle = facing_result.angle
	if not facing_result.is_valid:
		result.is_valid = false
		result.violations.append(facing_result.violation)

	# Check Imager behind Dowser
	var behind_result := check_imager_behind_dowser(
		dowser_position, dowser_forward, imager_position, config.imager_behind_tolerance
	)
	result.imager_behind_angle = behind_result.angle
	if not behind_result.is_valid:
		result.is_valid = false
		result.violations.append(behind_result.violation)

	# Check Imager distance from Dowser
	var distance_result := check_imager_distance(
		dowser_position, imager_position, config.min_imager_distance, config.max_imager_distance
	)
	if not distance_result.is_valid:
		result.is_valid = false
		result.violations.append(distance_result.violation)

	return result


## Checks if the Dowser is facing the anchor point within tolerance.
static func check_dowser_facing_anchor(
	dowser_position: Vector3,
	dowser_forward: Vector3,
	anchor_position: Vector3,
	tolerance: float = deg_to_rad(30.0)
) -> Dictionary:
	var to_anchor := (anchor_position - dowser_position).normalized()

	# Flatten to horizontal plane for facing check (ignore vertical angle)
	var forward_flat := Vector3(dowser_forward.x, 0, dowser_forward.z).normalized()
	var to_anchor_flat := Vector3(to_anchor.x, 0, to_anchor.z).normalized()

	# Handle edge case where vectors are zero length
	if forward_flat.length_squared() < 0.001 or to_anchor_flat.length_squared() < 0.001:
		return {
			"is_valid": false,
			"angle": PI,
			"violation": "Cannot determine facing direction"
		}

	var angle := forward_flat.angle_to(to_anchor_flat)

	if angle <= tolerance:
		return {"is_valid": true, "angle": angle, "violation": ""}

	return {
		"is_valid": false,
		"angle": angle,
		"violation": "Dowser not facing anchor (%.1f° off, max %.1f°)" % [
			rad_to_deg(angle), rad_to_deg(tolerance)
		]
	}


## Checks if the Imager is positioned behind the Dowser within tolerance.
static func check_imager_behind_dowser(
	dowser_position: Vector3,
	dowser_forward: Vector3,
	imager_position: Vector3,
	tolerance: float = deg_to_rad(60.0)
) -> Dictionary:
	var dowser_to_imager := (imager_position - dowser_position).normalized()
	var dowser_backward := -dowser_forward

	# Flatten to horizontal plane
	var backward_flat := Vector3(dowser_backward.x, 0, dowser_backward.z).normalized()
	var to_imager_flat := Vector3(dowser_to_imager.x, 0, dowser_to_imager.z).normalized()

	# Handle edge case where vectors are zero length
	if backward_flat.length_squared() < 0.001 or to_imager_flat.length_squared() < 0.001:
		return {
			"is_valid": false,
			"angle": PI,
			"violation": "Cannot determine relative position"
		}

	var angle := backward_flat.angle_to(to_imager_flat)

	if angle <= tolerance:
		return {"is_valid": true, "angle": angle, "violation": ""}

	return {
		"is_valid": false,
		"angle": angle,
		"violation": "Imager not behind Dowser (%.1f° off, max %.1f°)" % [
			rad_to_deg(angle), rad_to_deg(tolerance)
		]
	}


## Checks if the Imager is at a valid distance from the Dowser.
static func check_imager_distance(
	dowser_position: Vector3,
	imager_position: Vector3,
	min_distance: float = 1.0,
	max_distance: float = 5.0
) -> Dictionary:
	var distance := dowser_position.distance_to(imager_position)

	if distance < min_distance:
		return {
			"is_valid": false,
			"distance": distance,
			"violation": "Imager too close to Dowser (%.1fm, min %.1fm)" % [distance, min_distance]
		}

	if distance > max_distance:
		return {
			"is_valid": false,
			"distance": distance,
			"violation": "Imager too far from Dowser (%.1fm, max %.1fm)" % [distance, max_distance]
		}

	return {"is_valid": true, "distance": distance, "violation": ""}


## Calculates alignment quality based on how well constraints are satisfied.
## Returns a value from 0.0 (poor) to 1.0 (perfect).
static func calculate_alignment_quality(
	dowser_position: Vector3,
	dowser_forward: Vector3,
	imager_position: Vector3,
	anchor_position: Vector3,
	config: ConstraintConfig = null
) -> float:
	if config == null:
		config = default_config

	var result := validate_positions(
		dowser_position, dowser_forward, imager_position, anchor_position, config
	)

	if not result.is_valid:
		return 0.0

	# Calculate quality based on how centered the positions are
	# Perfect = facing exactly at anchor, imager exactly behind

	# Facing quality: 1.0 at 0°, 0.0 at tolerance
	var facing_quality := 1.0 - (result.dowser_facing_angle / config.dowser_facing_tolerance)
	facing_quality = clampf(facing_quality, 0.0, 1.0)

	# Behind quality: 1.0 at 0°, 0.0 at tolerance
	var behind_quality := 1.0 - (result.imager_behind_angle / config.imager_behind_tolerance)
	behind_quality = clampf(behind_quality, 0.0, 1.0)

	# Average the two quality factors
	return (facing_quality + behind_quality) / 2.0


## Converts a quality float (0-1) to a quality level.
static func get_quality_level(quality: float) -> AlignmentQuality:
	if quality <= 0.0:
		return AlignmentQuality.NONE
	if quality < 0.4:
		return AlignmentQuality.WEAK
	if quality < 0.7:
		return AlignmentQuality.MODERATE
	return AlignmentQuality.STRONG


## Returns the display name for a quality level.
static func get_quality_name(quality: AlignmentQuality) -> String:
	match quality:
		AlignmentQuality.NONE:
			return "No Alignment"
		AlignmentQuality.WEAK:
			return "Weak"
		AlignmentQuality.MODERATE:
			return "Moderate"
		AlignmentQuality.STRONG:
			return "Strong"
		_:
			return "Unknown"
