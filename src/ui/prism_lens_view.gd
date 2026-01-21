class_name PrismLensView
extends Control
## Eyepiece UI for the Spectral Prism Lens Reader.
##
## Displays the entity signature (shape + color) after the Calibrator has
## locked their alignment. The Lens Reader sees this view through the eyepiece
## and must verbally communicate what they see to other players.
##
## Trust Dynamic: Only the Lens Reader sees this view. They can lie about what
## pattern and color they see. Combined with Calibrator lying potential, this
## makes PRISM_READING evidence LOW trust.

# --- Signals ---

## Emitted when player requests to start recording.
signal recording_requested

## Emitted when player cancels recording.
signal recording_cancelled

# --- Constants ---

const PrismEnumsScript := preload("res://src/equipment/spectral_prism/prism_enums.gd")

## Pattern colors for visualization.
const PATTERN_COLORS: Dictionary = {
	PrismEnumsScript.PrismColor.NONE: Color(0.5, 0.5, 0.5, 0.5),
	PrismEnumsScript.PrismColor.BLUE_VIOLET: Color(0.4, 0.3, 0.9, 0.8),
	PrismEnumsScript.PrismColor.RED_ORANGE: Color(0.9, 0.35, 0.2, 0.8),
	PrismEnumsScript.PrismColor.GREEN: Color(0.2, 0.85, 0.35, 0.8),
	PrismEnumsScript.PrismColor.YELLOW: Color(0.95, 0.85, 0.2, 0.8),
}

# --- State ---

var _lens_reader: Node = null
var _has_calibration: bool = false
var _current_pattern: int = PrismEnumsScript.PrismPattern.NONE
var _current_color: int = PrismEnumsScript.PrismColor.NONE
var _is_consistent: bool = false
var _reading_progress: float = 0.0
var _is_recording: bool = false
var _animation_time: float = 0.0

# --- Node References ---

@onready var _status_label: Label = %StatusLabel
@onready var _pattern_display: Control = %PatternDisplay
@onready var _pattern_name_label: Label = %PatternNameLabel
@onready var _color_name_label: Label = %ColorNameLabel
@onready var _category_label: Label = %CategoryLabel
@onready var _consistency_label: Label = %ConsistencyLabel
@onready var _recording_progress: ProgressBar = %RecordingProgress
@onready var _record_button: Button = %RecordButton
@onready var _no_signal_panel: Panel = %NoSignalPanel
@onready var _signal_panel: Panel = %SignalPanel
@onready var _reference_guide: Control = %ReferenceGuide


func _ready() -> void:
	_record_button.pressed.connect(_on_record_pressed)
	_update_display()


func _process(delta: float) -> void:
	_animation_time += delta
	if _has_calibration:
		_pattern_display.queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	# Space or Enter to start/cancel recording
	if event.is_action_pressed("ui_accept"):
		if _is_recording:
			recording_cancelled.emit()
		elif _has_calibration:
			recording_requested.emit()
		get_viewport().set_input_as_handled()


# --- Public API ---


## Binds this view to a SpectralPrismLensReader equipment instance.
func bind_lens_reader(lens_reader: Node) -> void:
	if _lens_reader:
		_disconnect_lens_reader()

	_lens_reader = lens_reader
	if _lens_reader:
		_connect_lens_reader()
		_sync_from_lens_reader()


## Unbinds the current lens reader.
func unbind_lens_reader() -> void:
	if _lens_reader:
		_disconnect_lens_reader()
		_lens_reader = null
	_reset_state()


## Updates calibration status.
func set_has_calibration(has_cal: bool) -> void:
	_has_calibration = has_cal
	_update_display()


## Updates the current pattern (shape from Calibrator).
func set_current_pattern(pattern: int) -> void:
	_current_pattern = pattern
	_update_display()


## Updates the current color (from entity).
func set_current_color(color: int) -> void:
	_current_color = color
	_update_display()


## Updates consistency between pattern and color.
func set_consistency(consistent: bool) -> void:
	_is_consistent = consistent
	_update_display()


## Updates recording progress (0.0 to 1.0).
func set_recording_progress(progress: float) -> void:
	_reading_progress = clampf(progress, 0.0, 1.0)
	_is_recording = progress > 0.0 and progress < 1.0
	_update_progress_display()


# --- Private: Lens Reader Connection ---


func _connect_lens_reader() -> void:
	if not _lens_reader:
		return

	if _lens_reader.has_signal("reader_state_changed"):
		_lens_reader.reader_state_changed.connect(_on_reader_state_changed)
	if _lens_reader.has_signal("calibration_received"):
		_lens_reader.calibration_received.connect(_on_calibration_received)
	if _lens_reader.has_signal("quality_changed"):
		_lens_reader.quality_changed.connect(_on_quality_changed)


func _disconnect_lens_reader() -> void:
	if not _lens_reader:
		return

	if _lens_reader.has_signal("reader_state_changed"):
		if _lens_reader.reader_state_changed.is_connected(_on_reader_state_changed):
			_lens_reader.reader_state_changed.disconnect(_on_reader_state_changed)
	if _lens_reader.has_signal("calibration_received"):
		if _lens_reader.calibration_received.is_connected(_on_calibration_received):
			_lens_reader.calibration_received.disconnect(_on_calibration_received)
	if _lens_reader.has_signal("quality_changed"):
		if _lens_reader.quality_changed.is_connected(_on_quality_changed):
			_lens_reader.quality_changed.disconnect(_on_quality_changed)


func _sync_from_lens_reader() -> void:
	if not _lens_reader:
		return

	if _lens_reader.has_method("has_calibration"):
		_has_calibration = _lens_reader.has_calibration()
	if _lens_reader.has_method("get_pattern_shape"):
		_current_pattern = _lens_reader.get_pattern_shape()
	if _lens_reader.has_method("get_pattern_color"):
		_current_color = _lens_reader.get_pattern_color()
	if _lens_reader.has_method("is_consistent"):
		_is_consistent = _lens_reader.is_consistent()
	if _lens_reader.has_method("get_reading_progress"):
		_reading_progress = _lens_reader.get_reading_progress()
	if _lens_reader.has_method("is_reading"):
		_is_recording = _lens_reader.is_reading()

	_update_display()


# --- Private: Signal Handlers ---


func _on_reader_state_changed(new_state: int) -> void:
	# ReaderState enum: IDLE=0, WAITING=1, VIEWING=2, READING=3
	_is_recording = (new_state == 3)
	_sync_from_lens_reader()


func _on_calibration_received(pattern: int) -> void:
	_current_pattern = pattern
	_has_calibration = true
	_sync_from_lens_reader()


func _on_quality_changed(_new_quality: int) -> void:
	_sync_from_lens_reader()


func _on_record_pressed() -> void:
	if _is_recording:
		recording_cancelled.emit()
	elif _has_calibration:
		recording_requested.emit()


# --- Private: Display Updates ---


func _update_display() -> void:
	_update_signal_visibility()
	_update_pattern_info()
	_update_progress_display()
	if _pattern_display:
		_pattern_display.queue_redraw()


func _update_signal_visibility() -> void:
	if _no_signal_panel:
		_no_signal_panel.visible = not _has_calibration
	if _signal_panel:
		_signal_panel.visible = _has_calibration

	if _status_label:
		if _has_calibration:
			_status_label.text = "SIGNAL LOCKED"
			_status_label.add_theme_color_override("font_color", Color.GREEN)
		else:
			_status_label.text = "WAITING FOR CALIBRATION"
			_status_label.add_theme_color_override("font_color", Color.ORANGE)


func _update_pattern_info() -> void:
	if not _has_calibration:
		return

	if _pattern_name_label:
		var pattern_name := PrismEnumsScript.get_pattern_name(_current_pattern)
		_pattern_name_label.text = "Shape: %s" % pattern_name

	if _color_name_label:
		var color_name := PrismEnumsScript.get_color_name(_current_color)
		_color_name_label.text = "Color: %s" % color_name

	if _category_label:
		var category := PrismEnumsScript.get_category_from_color(_current_color)
		var category_name := PrismEnumsScript.get_category_name(category)
		_category_label.text = "Category: %s" % category_name

	if _consistency_label:
		if _current_pattern == PrismEnumsScript.PrismPattern.NONE:
			_consistency_label.text = "Pattern: Not aligned"
			_consistency_label.add_theme_color_override("font_color", Color.GRAY)
		elif _is_consistent:
			_consistency_label.text = "Reading: CONSISTENT"
			_consistency_label.add_theme_color_override("font_color", Color.GREEN)
		else:
			_consistency_label.text = "Reading: INCONSISTENT!"
			_consistency_label.add_theme_color_override("font_color", Color.RED)


func _update_progress_display() -> void:
	if _recording_progress:
		_recording_progress.value = _reading_progress * 100.0
		_recording_progress.visible = _is_recording or _reading_progress > 0.0

	if _record_button:
		_record_button.visible = _has_calibration
		if _is_recording:
			_record_button.text = "CANCEL"
		else:
			_record_button.text = "RECORD READING"
		_record_button.disabled = not _has_calibration


func _reset_state() -> void:
	_has_calibration = false
	_current_pattern = PrismEnumsScript.PrismPattern.NONE
	_current_color = PrismEnumsScript.PrismColor.NONE
	_is_consistent = false
	_reading_progress = 0.0
	_is_recording = false
	_update_display()


# --- Custom Drawing for Pattern ---


## Called by PatternDisplay's _draw() to render the signature.
func draw_pattern(canvas: Control) -> void:
	if not _has_calibration:
		_draw_no_signal(canvas)
		return

	var center := canvas.size / 2.0
	var base_size: float = minf(canvas.size.x, canvas.size.y) * 0.35

	# Get color for the pattern
	var pattern_color: Color = PATTERN_COLORS.get(_current_color, Color.GRAY)

	# Draw glowing background circle
	var glow_color := pattern_color
	glow_color.a = 0.2 + 0.1 * sin(_animation_time * 2.0)
	canvas.draw_circle(center, base_size * 1.3, glow_color)

	# Draw the pattern shape
	match _current_pattern:
		PrismEnumsScript.PrismPattern.TRIANGLE:
			_draw_triangle(canvas, center, base_size, pattern_color)
		PrismEnumsScript.PrismPattern.CIRCLE:
			canvas.draw_circle(center, base_size, pattern_color)
		PrismEnumsScript.PrismPattern.SQUARE:
			var rect := Rect2(center - Vector2(base_size, base_size), Vector2(base_size * 2, base_size * 2))
			canvas.draw_rect(rect, pattern_color)
		PrismEnumsScript.PrismPattern.SPIRAL:
			_draw_spiral(canvas, center, base_size, pattern_color)
		PrismEnumsScript.PrismPattern.NONE:
			_draw_unknown(canvas, center, base_size)


func _draw_no_signal(canvas: Control) -> void:
	var center := canvas.size / 2.0

	# Draw static noise effect
	var noise_color := Color(0.3, 0.3, 0.3, 0.6)
	for i in range(20):
		var offset := Vector2(
			sin(i * 1.3 + _animation_time * 3.0) * 30,
			cos(i * 1.7 + _animation_time * 2.5) * 30
		)
		canvas.draw_circle(center + offset, 3.0 + sin(i + _animation_time) * 2.0, noise_color)


func _draw_triangle(canvas: Control, center: Vector2, size: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(3):
		var angle := (TAU / 3.0) * i - PI / 2.0
		points.append(center + Vector2(cos(angle), sin(angle)) * size)
	canvas.draw_polygon(points, PackedColorArray([color, color, color]))

	# Draw outline
	var outline_color := color
	outline_color.v = minf(outline_color.v + 0.3, 1.0)
	for i in range(3):
		canvas.draw_line(points[i], points[(i + 1) % 3], outline_color, 2.0)


func _draw_spiral(canvas: Control, center: Vector2, size: float, color: Color) -> void:
	var points := PackedVector2Array()
	var point_count := 40
	for i in range(point_count):
		var t: float = float(i) / float(point_count - 1)
		var angle: float = t * TAU * 2.5
		var radius: float = size * (0.15 + t * 0.85)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)

	# Draw spiral line
	for i in range(points.size() - 1):
		var alpha: float = 0.5 + 0.5 * (float(i) / float(points.size()))
		var segment_color := color
		segment_color.a = alpha
		canvas.draw_line(points[i], points[i + 1], segment_color, 3.0)


func _draw_unknown(canvas: Control, center: Vector2, size: float) -> void:
	# Draw question mark-like shape
	var gray := Color(0.5, 0.5, 0.5, 0.7)
	canvas.draw_circle(center - Vector2(0, size * 0.3), size * 0.4, gray)
	canvas.draw_rect(Rect2(center + Vector2(-size * 0.1, size * 0.1), Vector2(size * 0.2, size * 0.3)), gray)
	canvas.draw_circle(center + Vector2(0, size * 0.6), size * 0.1, gray)
