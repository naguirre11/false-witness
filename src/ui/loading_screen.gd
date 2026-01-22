extends Control
## Loading screen displayed during map loading.
##
## Shows a progress bar and status message while the map scene
## loads asynchronously in the background.

# --- Signals ---

## Emitted when the loading screen has finished fading in and is ready.
signal ready_to_load

## Emitted when the loading is complete and ready to fade out.
signal loading_complete

# --- Constants ---

const FADE_DURATION: float = 0.3

# --- State Variables ---

var _target_progress: float = 0.0
var _current_progress: float = 0.0
var _is_loading: bool = false

# --- Node References ---

@onready var _dimmer: ColorRect = %Dimmer
@onready var _panel: PanelContainer = %Panel
@onready var _title_label: Label = %TitleLabel
@onready var _status_label: Label = %StatusLabel
@onready var _progress_bar: ProgressBar = %ProgressBar


func _ready() -> void:
	# Start invisible
	modulate.a = 0.0
	visible = false
	_progress_bar.value = 0.0


func _process(delta: float) -> void:
	if _is_loading:
		# Smoothly interpolate progress bar
		_current_progress = lerpf(_current_progress, _target_progress, delta * 5.0)
		_progress_bar.value = _current_progress


## Shows the loading screen with a fade-in animation.
func show_loading(map_name: String = "") -> void:
	visible = true
	_is_loading = true
	_current_progress = 0.0
	_target_progress = 0.0
	_progress_bar.value = 0.0

	if map_name.is_empty():
		_title_label.text = "LOADING"
	else:
		_title_label.text = "LOADING: %s" % map_name.to_upper().replace("_", " ")

	_status_label.text = "Preparing..."

	# Fade in
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)
	tween.tween_callback(func(): ready_to_load.emit())


## Updates the loading progress (0.0 to 1.0).
func set_progress(progress: float, status: String = "") -> void:
	_target_progress = clampf(progress * 100.0, 0.0, 100.0)

	if not status.is_empty():
		_status_label.text = status


## Hides the loading screen with a fade-out animation.
func hide_loading() -> void:
	_is_loading = false
	_status_label.text = "Complete!"
	_progress_bar.value = 100.0

	# Small delay before fade out
	var tween := create_tween()
	tween.tween_interval(0.3)
	tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(func():
		visible = false
		loading_complete.emit()
	)
