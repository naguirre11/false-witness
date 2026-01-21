class_name PrismCalibratorView
extends Control
## Viewfinder UI for the Spectral Prism Calibrator.
##
## Displays abstract color blobs that resolve into a recognizable pattern shape
## when the player correctly aligns all three filters. The Calibrator player
## sees this view through the viewfinder and must verbally communicate what
## they see to their partner (the Lens Reader).
##
## Trust Dynamic: Only the Calibrator sees this view. They can lie about what
## shape they see after alignment.

# --- Signals ---

## Emitted when player clicks the lock button.
signal lock_requested

## Emitted when filter rotation is requested (filter_index 0-2, direction +/-1).
signal filter_rotation_requested(filter_index: int, direction: int)

# --- Constants ---

const PrismEnumsScript := preload("res://src/equipment/spectral_prism/prism_enums.gd")

## Colors for the four pattern shapes (matched to PrismColor meanings).
const PATTERN_COLORS: Dictionary = {
	PrismEnumsScript.PrismPattern.TRIANGLE: Color(0.5, 0.3, 0.8, 1.0),  # Blue-violet
	PrismEnumsScript.PrismPattern.CIRCLE: Color(0.9, 0.3, 0.2, 1.0),  # Red-orange
	PrismEnumsScript.PrismPattern.SQUARE: Color(0.2, 0.8, 0.3, 1.0),  # Green
	PrismEnumsScript.PrismPattern.SPIRAL: Color(0.9, 0.8, 0.2, 1.0),  # Yellow
}

## Lock button appears when alignment reaches this threshold.
const LOCK_THRESHOLD: float = 0.8

# --- State ---

var _calibrator: Node = null
var _current_pattern: int = PrismEnumsScript.PrismPattern.NONE
var _alignment_progress: float = 0.0
var _filter_positions: Array[int] = [0, 0, 0]
var _is_locked: bool = false
var _blob_animation_time: float = 0.0

# --- Node References ---

@onready var _blob_display: Control = %BlobDisplay
@onready var _progress_bar: ProgressBar = %AlignmentProgress
@onready var _progress_label: Label = %ProgressLabel
@onready var _lock_button: Button = %LockButton
@onready var _status_label: Label = %StatusLabel
@onready var _filter_indicators: Array[Control] = [
	%Filter1Indicator,
	%Filter2Indicator,
	%Filter3Indicator,
]


func _ready() -> void:
	_lock_button.pressed.connect(_on_lock_pressed)
	_lock_button.visible = false
	_update_display()


func _process(delta: float) -> void:
	if not _is_locked:
		_blob_animation_time += delta
		_blob_display.queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible or _is_locked:
		return

	# Filter rotation controls (Q/E for filter 1, Z/C for filter 2, 1/3 for filter 3)
	if event.is_action_pressed("calibrator_filter1_left"):
		filter_rotation_requested.emit(0, -1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("calibrator_filter1_right"):
		filter_rotation_requested.emit(0, 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("calibrator_filter2_left"):
		filter_rotation_requested.emit(1, -1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("calibrator_filter2_right"):
		filter_rotation_requested.emit(1, 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("calibrator_filter3_left"):
		filter_rotation_requested.emit(2, -1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("calibrator_filter3_right"):
		filter_rotation_requested.emit(2, 1)
		get_viewport().set_input_as_handled()

	# Lock with Space or Enter when available
	if event.is_action_pressed("ui_accept") and _lock_button.visible:
		_on_lock_pressed()
		get_viewport().set_input_as_handled()


# --- Public API ---


## Binds this view to a SpectralPrismCalibrator equipment instance.
func bind_calibrator(calibrator: Node) -> void:
	if _calibrator:
		_disconnect_calibrator()

	_calibrator = calibrator
	if _calibrator:
		_connect_calibrator()
		_sync_from_calibrator()


## Unbinds the current calibrator.
func unbind_calibrator() -> void:
	if _calibrator:
		_disconnect_calibrator()
		_calibrator = null
	_reset_state()


## Updates the current target pattern (entity's true pattern).
func set_target_pattern(pattern: int) -> void:
	_current_pattern = pattern
	_update_display()


## Updates the alignment progress (0.0 to 1.0).
func set_alignment_progress(progress: float) -> void:
	_alignment_progress = clampf(progress, 0.0, 1.0)
	_update_display()


## Updates the filter positions (array of 3 ints, 0-7 each).
func set_filter_positions(positions: Array[int]) -> void:
	_filter_positions = positions.duplicate()
	_update_filter_indicators()
	_update_display()


## Sets the locked state.
func set_locked(locked: bool) -> void:
	_is_locked = locked
	_update_display()


# --- Private: Calibrator Connection ---


func _connect_calibrator() -> void:
	if not _calibrator:
		return

	if _calibrator.has_signal("calibration_state_changed"):
		_calibrator.calibration_state_changed.connect(_on_calibration_state_changed)
	if _calibrator.has_signal("filter_rotated"):
		_calibrator.filter_rotated.connect(_on_filter_rotated)
	if _calibrator.has_signal("alignment_achieved"):
		_calibrator.alignment_achieved.connect(_on_alignment_achieved)
	if _calibrator.has_signal("alignment_lost"):
		_calibrator.alignment_lost.connect(_on_alignment_lost)
	if _calibrator.has_signal("calibration_locked"):
		_calibrator.calibration_locked.connect(_on_calibration_locked)


func _disconnect_calibrator() -> void:
	if not _calibrator:
		return

	if _calibrator.has_signal("calibration_state_changed"):
		if _calibrator.calibration_state_changed.is_connected(_on_calibration_state_changed):
			_calibrator.calibration_state_changed.disconnect(_on_calibration_state_changed)
	if _calibrator.has_signal("filter_rotated"):
		if _calibrator.filter_rotated.is_connected(_on_filter_rotated):
			_calibrator.filter_rotated.disconnect(_on_filter_rotated)
	if _calibrator.has_signal("alignment_achieved"):
		if _calibrator.alignment_achieved.is_connected(_on_alignment_achieved):
			_calibrator.alignment_achieved.disconnect(_on_alignment_achieved)
	if _calibrator.has_signal("alignment_lost"):
		if _calibrator.alignment_lost.is_connected(_on_alignment_lost):
			_calibrator.alignment_lost.disconnect(_on_alignment_lost)
	if _calibrator.has_signal("calibration_locked"):
		if _calibrator.calibration_locked.is_connected(_on_calibration_locked):
			_calibrator.calibration_locked.disconnect(_on_calibration_locked)


func _sync_from_calibrator() -> void:
	if not _calibrator:
		return

	if _calibrator.has_method("get_alignment_progress"):
		_alignment_progress = _calibrator.get_alignment_progress()
	if _calibrator.has_method("get_all_filter_positions"):
		var positions: Array = _calibrator.get_all_filter_positions()
		_filter_positions = [positions[0] as int, positions[1] as int, positions[2] as int]
	if _calibrator.has_method("get_current_pattern"):
		_current_pattern = _calibrator.get_current_pattern()
	if _calibrator.has_method("get_calibration_state"):
		var state: int = _calibrator.get_calibration_state()
		# LOCKED = 3 in CalibrationState enum
		_is_locked = (state == 3)

	_update_display()


# --- Private: Signal Handlers ---


func _on_calibration_state_changed(new_state: int) -> void:
	# LOCKED = 3
	_is_locked = (new_state == 3)
	_update_display()


func _on_filter_rotated(filter_index: int, position: int) -> void:
	if filter_index >= 0 and filter_index < 3:
		_filter_positions[filter_index] = position
		_update_filter_indicators()

	# Re-sync alignment progress
	if _calibrator and _calibrator.has_method("get_alignment_progress"):
		_alignment_progress = _calibrator.get_alignment_progress()
		_update_display()


func _on_alignment_achieved(pattern: int) -> void:
	_current_pattern = pattern
	_alignment_progress = 1.0
	_update_display()


func _on_alignment_lost() -> void:
	_alignment_progress = 0.0
	_update_display()


func _on_calibration_locked(_locked_pattern: int) -> void:
	_is_locked = true
	_update_display()


func _on_lock_pressed() -> void:
	lock_requested.emit()


# --- Private: Display Updates ---


func _update_display() -> void:
	_update_progress_bar()
	_update_status_label()
	_update_lock_button()
	_update_filter_indicators()
	if _blob_display:
		_blob_display.queue_redraw()


func _update_progress_bar() -> void:
	if not _progress_bar:
		return

	_progress_bar.value = _alignment_progress * 100.0
	if _progress_label:
		_progress_label.text = "%d%% Aligned" % int(_alignment_progress * 100.0)


func _update_status_label() -> void:
	if not _status_label:
		return

	if _is_locked:
		_status_label.text = "LOCKED"
		_status_label.add_theme_color_override("font_color", Color.GREEN)
	elif _alignment_progress >= 1.0:
		_status_label.text = "ALIGNED - Ready to Lock"
		_status_label.add_theme_color_override("font_color", Color.YELLOW)
	elif _alignment_progress >= LOCK_THRESHOLD:
		_status_label.text = "Nearly Aligned"
		_status_label.add_theme_color_override("font_color", Color.ORANGE)
	else:
		_status_label.text = "Adjusting Filters..."
		_status_label.add_theme_color_override("font_color", Color.WHITE)


func _update_lock_button() -> void:
	if not _lock_button:
		return

	# Show lock button when alignment >= 80% and not already locked
	_lock_button.visible = _alignment_progress >= LOCK_THRESHOLD and not _is_locked
	_lock_button.disabled = _is_locked


func _update_filter_indicators() -> void:
	for i in range(mini(_filter_indicators.size(), 3)):
		var indicator: Control = _filter_indicators[i]
		if indicator and indicator.has_method("set_position_value"):
			indicator.set_position_value(_filter_positions[i])
		elif indicator is ProgressBar:
			# Simple progress bar as filter indicator (0-7 mapped to 0-100)
			(indicator as ProgressBar).value = (_filter_positions[i] / 7.0) * 100.0


func _reset_state() -> void:
	_current_pattern = PrismEnumsScript.PrismPattern.NONE
	_alignment_progress = 0.0
	_filter_positions = [0, 0, 0]
	_is_locked = false
	_update_display()


# --- Custom Drawing for Blobs ---


## Called by BlobDisplay's _draw() to render the abstract blobs.
func draw_blobs(canvas: Control) -> void:
	var center := canvas.size / 2.0
	var base_radius: float = minf(canvas.size.x, canvas.size.y) * 0.3

	# Get the base color for the current pattern (or gray if none)
	var base_color: Color
	if _current_pattern != PrismEnumsScript.PrismPattern.NONE:
		base_color = PATTERN_COLORS.get(_current_pattern, Color.GRAY)
	else:
		base_color = Color(0.5, 0.5, 0.5, 0.6)

	# Draw multiple overlapping blobs that become more coherent with alignment
	var blob_count := 5
	var coherence := _alignment_progress  # 0.0 = chaotic, 1.0 = resolved

	for i in range(blob_count):
		var angle := (TAU / blob_count) * i
		angle += _blob_animation_time * 0.5 * (1.0 - coherence)  # Animate when not aligned

		# Offset decreases as alignment increases
		var offset_magnitude: float = base_radius * 0.6 * (1.0 - coherence)
		var offset := Vector2(cos(angle), sin(angle)) * offset_magnitude

		# Blob size varies chaotically when unaligned, uniform when aligned
		var size_variance: float = 0.3 * (1.0 - coherence)
		var blob_radius: float = base_radius * (0.4 + size_variance * sin(i * 1.7 + _blob_animation_time))

		# Color varies when unaligned
		var color_shift: float = (1.0 - coherence) * 0.3
		var blob_color := base_color
		blob_color.h += color_shift * sin(i * 2.3 + _blob_animation_time * 0.7)
		blob_color.s = lerpf(0.3, blob_color.s, coherence)
		blob_color.a = lerpf(0.3, 0.7, coherence)

		canvas.draw_circle(center + offset, blob_radius, blob_color)

	# When aligned, draw the pattern shape in the center
	if _alignment_progress >= 1.0:
		_draw_pattern_shape(canvas, center, base_radius * 0.5, base_color)


func _draw_pattern_shape(canvas: Control, center: Vector2, size: float, color: Color) -> void:
	var shape_color := color
	shape_color.a = 0.9

	match _current_pattern:
		PrismEnumsScript.PrismPattern.TRIANGLE:
			_draw_triangle(canvas, center, size, shape_color)
		PrismEnumsScript.PrismPattern.CIRCLE:
			canvas.draw_circle(center, size, shape_color)
		PrismEnumsScript.PrismPattern.SQUARE:
			var rect := Rect2(center - Vector2(size, size), Vector2(size * 2, size * 2))
			canvas.draw_rect(rect, shape_color)
		PrismEnumsScript.PrismPattern.SPIRAL:
			_draw_spiral(canvas, center, size, shape_color)


func _draw_triangle(canvas: Control, center: Vector2, size: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(3):
		var angle := (TAU / 3.0) * i - PI / 2.0  # Point up
		points.append(center + Vector2(cos(angle), sin(angle)) * size)
	canvas.draw_polygon(points, PackedColorArray([color, color, color]))


func _draw_spiral(canvas: Control, center: Vector2, size: float, color: Color) -> void:
	# Draw a simple spiral using connected arcs
	var points := PackedVector2Array()
	var point_count := 30
	for i in range(point_count):
		var t: float = float(i) / float(point_count - 1)
		var angle: float = t * TAU * 2.0  # Two full rotations
		var radius: float = size * (0.2 + t * 0.8)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)

	# Draw as connected lines
	for i in range(points.size() - 1):
		canvas.draw_line(points[i], points[i + 1], color, 3.0)
