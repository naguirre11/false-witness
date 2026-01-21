class_name AuraImagerView
extends Control
## Screen UI for the Aura Imager equipment.
##
## Displays the aura pattern (color + form) when the Imager is properly
## positioned behind the Dowser. Only the Imager can see this screen clearly.
##
## Trust Dynamic: Only the Imager sees this screen. They can lie about what
## color and form they see. A third player can potentially verify by looking
## over the Imager's shoulder.

# --- Signals ---

## Emitted when player requests to start capture.
signal capture_requested

## Emitted when player cancels capture.
signal capture_cancelled

## Emitted when a direction command is requested.
signal direction_requested(command: int)

# --- Constants ---

const AuraEnumsScript := preload("res://src/equipment/aura/aura_enums.gd")

## Aura colors for visualization.
const AURA_COLORS: Dictionary = {
	AuraEnumsScript.AuraColor.NONE: Color(0.3, 0.3, 0.3, 0.3),
	AuraEnumsScript.AuraColor.COLD_BLUE: Color(0.2, 0.4, 0.9, 0.8),
	AuraEnumsScript.AuraColor.HOT_RED: Color(0.95, 0.2, 0.15, 0.8),
	AuraEnumsScript.AuraColor.PALE_GREEN: Color(0.4, 0.85, 0.5, 0.8),
	AuraEnumsScript.AuraColor.DEEP_PURPLE: Color(0.6, 0.2, 0.8, 0.8),
}

## Resolution thresholds (match AuraImager constants).
const COLOR_VISIBLE_THRESHOLD := 0.3
const FORM_VISIBLE_THRESHOLD := 0.5
const FULL_CLARITY_THRESHOLD := 0.7

# --- State ---

var _aura_imager: Node = null
var _is_positioned: bool = false
var _current_resolution: float = 0.0
var _current_color: int = AuraEnumsScript.AuraColor.NONE
var _current_form: int = AuraEnumsScript.AuraForm.NONE
var _is_consistent: bool = false
var _capture_progress: float = 0.0
var _is_capturing: bool = false
var _positioning_violations: Array[String] = []
var _animation_time: float = 0.0

# --- Node References ---

@onready var _status_label: Label = %StatusLabel
@onready var _aura_display: Control = %AuraDisplay
@onready var _resolution_bar: ProgressBar = %ResolutionProgress
@onready var _resolution_label: Label = %ResolutionLabel
@onready var _color_label: Label = %ColorLabel
@onready var _form_label: Label = %FormLabel
@onready var _temperament_label: Label = %TemperamentLabel
@onready var _consistency_label: Label = %ConsistencyLabel
@onready var _capture_progress_bar: ProgressBar = %CaptureProgress
@onready var _capture_button: Button = %CaptureButton
@onready var _positioning_panel: Panel = %PositioningPanel
@onready var _aura_panel: Panel = %AuraPanel
@onready var _violations_label: Label = %ViolationsLabel
@onready var _reference_guide: Control = %ReferenceGuide


func _ready() -> void:
	_capture_button.pressed.connect(_on_capture_pressed)
	_update_display()


func _process(delta: float) -> void:
	_animation_time += delta
	if _is_positioned:
		_aura_display.queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	# Space or Enter to start/cancel capture
	if event.is_action_pressed("ui_accept"):
		if _is_capturing:
			capture_cancelled.emit()
		elif _is_positioned and _current_resolution >= COLOR_VISIBLE_THRESHOLD:
			capture_requested.emit()
		get_viewport().set_input_as_handled()


# --- Public API ---


## Binds this view to an AuraImager equipment instance.
func bind_aura_imager(aura_imager: Node) -> void:
	if _aura_imager:
		_disconnect_aura_imager()

	_aura_imager = aura_imager
	if _aura_imager:
		_connect_aura_imager()
		_sync_from_aura_imager()


## Unbinds the current aura imager.
func unbind_aura_imager() -> void:
	if _aura_imager:
		_disconnect_aura_imager()
		_aura_imager = null
	_reset_state()


## Sets the positioning state.
func set_positioned(positioned: bool) -> void:
	_is_positioned = positioned
	_update_display()


## Sets the current resolution (0.0 to 1.0).
func set_resolution(resolution: float) -> void:
	_current_resolution = clampf(resolution, 0.0, 1.0)
	_update_display()


## Sets the current aura color.
func set_aura_color(color: int) -> void:
	_current_color = color
	_update_display()


## Sets the current aura form.
func set_aura_form(form: int) -> void:
	_current_form = form
	_update_display()


## Sets the consistency state.
func set_consistency(consistent: bool) -> void:
	_is_consistent = consistent
	_update_display()


## Sets the capture progress (0.0 to 1.0).
func set_capture_progress(progress: float) -> void:
	_capture_progress = clampf(progress, 0.0, 1.0)
	_is_capturing = progress > 0.0 and progress < 1.0
	_update_capture_display()


## Sets the positioning violations.
func set_positioning_violations(violations: Array) -> void:
	_positioning_violations.clear()
	for v in violations:
		_positioning_violations.append(str(v))
	_update_violations_display()


# --- Private: Aura Imager Connection ---


func _connect_aura_imager() -> void:
	if not _aura_imager:
		return

	if _aura_imager.has_signal("imager_state_changed"):
		_aura_imager.imager_state_changed.connect(_on_imager_state_changed)
	if _aura_imager.has_signal("resolution_changed"):
		_aura_imager.resolution_changed.connect(_on_resolution_changed)
	if _aura_imager.has_signal("positioning_changed"):
		_aura_imager.positioning_changed.connect(_on_positioning_changed)
	if _aura_imager.has_signal("aura_resolved"):
		_aura_imager.aura_resolved.connect(_on_aura_resolved)


func _disconnect_aura_imager() -> void:
	if not _aura_imager:
		return

	if _aura_imager.has_signal("imager_state_changed"):
		if _aura_imager.imager_state_changed.is_connected(_on_imager_state_changed):
			_aura_imager.imager_state_changed.disconnect(_on_imager_state_changed)
	if _aura_imager.has_signal("resolution_changed"):
		if _aura_imager.resolution_changed.is_connected(_on_resolution_changed):
			_aura_imager.resolution_changed.disconnect(_on_resolution_changed)
	if _aura_imager.has_signal("positioning_changed"):
		if _aura_imager.positioning_changed.is_connected(_on_positioning_changed):
			_aura_imager.positioning_changed.disconnect(_on_positioning_changed)
	if _aura_imager.has_signal("aura_resolved"):
		if _aura_imager.aura_resolved.is_connected(_on_aura_resolved):
			_aura_imager.aura_resolved.disconnect(_on_aura_resolved)


func _sync_from_aura_imager() -> void:
	if not _aura_imager:
		return

	if _aura_imager.has_method("is_properly_positioned"):
		_is_positioned = _aura_imager.is_properly_positioned()
	if _aura_imager.has_method("get_resolution"):
		_current_resolution = _aura_imager.get_resolution()
	if _aura_imager.has_method("get_aura_color"):
		_current_color = _aura_imager.get_aura_color()
	if _aura_imager.has_method("get_aura_form"):
		_current_form = _aura_imager.get_aura_form()
	if _aura_imager.has_method("is_consistent"):
		_is_consistent = _aura_imager.is_consistent()
	if _aura_imager.has_method("get_capture_progress"):
		_capture_progress = _aura_imager.get_capture_progress()
	if _aura_imager.has_method("is_capturing"):
		_is_capturing = _aura_imager.is_capturing()
	if _aura_imager.has_method("get_positioning_violations"):
		_positioning_violations.clear()
		for v in _aura_imager.get_positioning_violations():
			_positioning_violations.append(str(v))

	_update_display()


# --- Private: Signal Handlers ---


func _on_imager_state_changed(_new_state: int) -> void:
	_sync_from_aura_imager()


func _on_resolution_changed(new_resolution: float) -> void:
	_current_resolution = new_resolution
	_update_display()


func _on_positioning_changed(is_valid: bool, violations: Array) -> void:
	_is_positioned = is_valid
	_positioning_violations.clear()
	for v in violations:
		_positioning_violations.append(str(v))
	_update_display()


func _on_aura_resolved(color: int, form: int) -> void:
	_current_color = color
	_current_form = form
	_update_display()


func _on_capture_pressed() -> void:
	if _is_capturing:
		capture_cancelled.emit()
	elif _is_positioned and _current_resolution >= COLOR_VISIBLE_THRESHOLD:
		capture_requested.emit()


# --- Private: Display Updates ---


func _update_display() -> void:
	_update_panel_visibility()
	_update_status_label()
	_update_resolution_display()
	_update_aura_info()
	_update_capture_display()
	if _aura_display:
		_aura_display.queue_redraw()


func _update_panel_visibility() -> void:
	if _positioning_panel:
		_positioning_panel.visible = not _is_positioned
	if _aura_panel:
		_aura_panel.visible = _is_positioned


func _update_status_label() -> void:
	if not _status_label:
		return

	if not _is_positioned:
		_status_label.text = "POSITIONING"
		_status_label.add_theme_color_override("font_color", Color.ORANGE)
	elif _current_resolution >= FULL_CLARITY_THRESHOLD:
		_status_label.text = "FULLY RESOLVED"
		_status_label.add_theme_color_override("font_color", Color.GREEN)
	elif _current_resolution >= COLOR_VISIBLE_THRESHOLD:
		_status_label.text = "RESOLVING..."
		_status_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		_status_label.text = "LOW SIGNAL"
		_status_label.add_theme_color_override("font_color", Color.RED)


func _update_resolution_display() -> void:
	if _resolution_bar:
		_resolution_bar.value = _current_resolution * 100.0

	if _resolution_label:
		var percent := int(_current_resolution * 100.0)
		_resolution_label.text = "%d%% Clarity" % percent


func _update_aura_info() -> void:
	if not _is_positioned:
		return

	# Color (visible at 30%)
	if _color_label:
		if _current_resolution >= COLOR_VISIBLE_THRESHOLD:
			_color_label.text = "Color: %s" % AuraEnumsScript.get_color_name(_current_color)
			var display_color: Color = AURA_COLORS.get(_current_color, Color.GRAY)
			_color_label.add_theme_color_override("font_color", display_color)
		else:
			_color_label.text = "Color: (resolving...)"
			_color_label.add_theme_color_override("font_color", Color.GRAY)

	# Form (visible at 50%)
	if _form_label:
		if _current_resolution >= FORM_VISIBLE_THRESHOLD:
			_form_label.text = "Form: %s" % AuraEnumsScript.get_form_name(_current_form)
		else:
			_form_label.text = "Form: (resolving...)"

	# Temperament
	if _temperament_label:
		if _current_resolution >= FULL_CLARITY_THRESHOLD:
			var temp := AuraEnumsScript.get_temperament_from_color(_current_color)
			_temperament_label.text = "Type: %s" % AuraEnumsScript.get_temperament_name(temp)
		else:
			_temperament_label.text = "Type: (unknown)"

	# Consistency
	if _consistency_label:
		if _current_resolution >= FULL_CLARITY_THRESHOLD:
			if _is_consistent:
				_consistency_label.text = "Reading: CONSISTENT"
				_consistency_label.add_theme_color_override("font_color", Color.GREEN)
			else:
				_consistency_label.text = "Reading: INCONSISTENT!"
				_consistency_label.add_theme_color_override("font_color", Color.RED)
		else:
			_consistency_label.text = "Reading: ---"
			_consistency_label.add_theme_color_override("font_color", Color.GRAY)


func _update_capture_display() -> void:
	if _capture_progress_bar:
		_capture_progress_bar.value = _capture_progress * 100.0
		_capture_progress_bar.visible = _is_capturing or _capture_progress > 0.0

	if _capture_button:
		var can_capture := _is_positioned and _current_resolution >= COLOR_VISIBLE_THRESHOLD
		_capture_button.visible = _is_positioned
		_capture_button.disabled = not can_capture and not _is_capturing

		if _is_capturing:
			_capture_button.text = "CANCEL"
		else:
			_capture_button.text = "CAPTURE"


func _update_violations_display() -> void:
	if not _violations_label:
		return

	if _positioning_violations.is_empty():
		_violations_label.text = "Move to position behind Dowser"
	else:
		_violations_label.text = "\n".join(_positioning_violations)


func _reset_state() -> void:
	_is_positioned = false
	_current_resolution = 0.0
	_current_color = AuraEnumsScript.AuraColor.NONE
	_current_form = AuraEnumsScript.AuraForm.NONE
	_is_consistent = false
	_capture_progress = 0.0
	_is_capturing = false
	_positioning_violations.clear()
	_update_display()


# --- Custom Drawing for Aura ---


## Called by AuraDisplay's _draw() to render the aura visualization.
func draw_aura(canvas: Control) -> void:
	var center := canvas.size / 2.0
	var base_radius: float = minf(canvas.size.x, canvas.size.y) * 0.35

	if not _is_positioned:
		_draw_no_signal(canvas, center, base_radius)
		return

	# Get color for visualization
	var aura_color: Color = AURA_COLORS.get(_current_color, Color.GRAY)

	# Adjust alpha based on resolution
	aura_color.a = lerpf(0.2, 0.9, _current_resolution)

	# Draw base aura glow
	var glow_radius: float = base_radius * (1.0 + 0.3 * _current_resolution)
	var glow_color := aura_color
	glow_color.a *= 0.4
	canvas.draw_circle(center, glow_radius, glow_color)

	# Draw aura form based on type
	if _current_resolution >= FORM_VISIBLE_THRESHOLD:
		_draw_aura_form(canvas, center, base_radius, aura_color)
	else:
		# Fuzzy undefined shape when form not resolved
		_draw_fuzzy_aura(canvas, center, base_radius, aura_color)


func _draw_no_signal(canvas: Control, center: Vector2, _radius: float) -> void:
	# Draw static/noise effect
	var noise_color := Color(0.3, 0.3, 0.3, 0.5)
	for i in range(15):
		var angle: float = randf() * TAU + _animation_time * 0.5
		var dist: float = randf() * 50.0
		var pos := center + Vector2(cos(angle), sin(angle)) * dist
		canvas.draw_circle(pos, 2.0 + randf() * 3.0, noise_color)


func _draw_fuzzy_aura(canvas: Control, center: Vector2, radius: float, color: Color) -> void:
	# Draw blurry, undefined shape
	var blur_count := 8
	for i in range(blur_count):
		var angle: float = (TAU / blur_count) * i + _animation_time * 0.3
		var offset := Vector2(cos(angle), sin(angle)) * radius * 0.3
		var blob_color := color
		blob_color.a *= 0.5
		canvas.draw_circle(center + offset, radius * 0.4, blob_color)


func _draw_aura_form(canvas: Control, center: Vector2, radius: float, color: Color) -> void:
	match _current_form:
		AuraEnumsScript.AuraForm.TIGHT_CONTAINED:
			_draw_tight_form(canvas, center, radius, color)
		AuraEnumsScript.AuraForm.SPIKING_ERRATIC:
			_draw_spiking_form(canvas, center, radius, color)
		AuraEnumsScript.AuraForm.DIFFUSE_SPREADING:
			_draw_diffuse_form(canvas, center, radius, color)
		AuraEnumsScript.AuraForm.SWIRLING_MOBILE:
			_draw_swirling_form(canvas, center, radius, color)
		_:
			_draw_fuzzy_aura(canvas, center, radius, color)


func _draw_tight_form(canvas: Control, center: Vector2, radius: float, color: Color) -> void:
	# Compact, dense circle - passive
	canvas.draw_circle(center, radius * 0.6, color)
	var inner_color := color
	inner_color.v = minf(inner_color.v + 0.2, 1.0)
	canvas.draw_circle(center, radius * 0.3, inner_color)


func _draw_spiking_form(canvas: Control, center: Vector2, radius: float, color: Color) -> void:
	# Spiky, erratic - aggressive
	var spike_count := 8
	var points := PackedVector2Array()

	for i in range(spike_count * 2):
		var angle: float = (TAU / (spike_count * 2)) * i + _animation_time * 2.0
		var spike_offset: float = 0.2 * sin(_animation_time * 5.0 + i)
		var dist: float
		if i % 2 == 0:
			dist = radius * (0.9 + spike_offset)
		else:
			dist = radius * (0.4 + spike_offset * 0.5)
		points.append(center + Vector2(cos(angle), sin(angle)) * dist)

	var colors := PackedColorArray()
	for _i in range(points.size()):
		colors.append(color)
	canvas.draw_polygon(points, colors)


func _draw_diffuse_form(canvas: Control, center: Vector2, radius: float, color: Color) -> void:
	# Spreading, diffuse - territorial
	var ring_count := 4
	for i in range(ring_count):
		var ring_radius: float = radius * (0.3 + 0.25 * i)
		var ring_color := color
		ring_color.a *= (1.0 - 0.2 * i)
		ring_color.a *= 0.8 + 0.2 * sin(_animation_time * 1.5 + i)
		canvas.draw_arc(center, ring_radius, 0, TAU, 32, ring_color, 3.0)


func _draw_swirling_form(canvas: Control, center: Vector2, radius: float, color: Color) -> void:
	# Swirling, mobile pattern - roaming
	var arm_count := 3
	for arm in range(arm_count):
		var points := PackedVector2Array()
		var point_count := 20
		var arm_offset: float = (TAU / arm_count) * arm + _animation_time

		for i in range(point_count):
			var t: float = float(i) / float(point_count - 1)
			var angle: float = arm_offset + t * TAU * 1.5
			var r: float = radius * (0.15 + t * 0.85)
			points.append(center + Vector2(cos(angle), sin(angle)) * r)

		for i in range(points.size() - 1):
			var alpha: float = 0.4 + 0.6 * (float(i) / float(points.size()))
			var line_color := color
			line_color.a = alpha
			canvas.draw_line(points[i], points[i + 1], line_color, 2.5)
