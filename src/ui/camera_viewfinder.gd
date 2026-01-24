extends CanvasLayer
## Camera viewfinder UI for aiming and capturing photos.
##
## Shows full-screen overlay when aiming, displays frame guide, film counter,
## cooldown progress, and capture flash effects.

const DesignTokens := preload("res://themes/design_tokens.gd")

# --- State ---

var _bound_camera: Node = null
var _flash_tween: Tween = null

# --- Node References ---

@onready var _viewfinder_container: Control = %ViewfinderContainer
@onready var _frame: Panel = %Frame
@onready var _film_counter: Label = %FilmCounter
@onready var _cooldown_bar: ProgressBar = %CooldownBar
@onready var _flash_overlay: ColorRect = %FlashOverlay


func _ready() -> void:
	_viewfinder_container.visible = false
	_cooldown_bar.visible = false
	_flash_overlay.modulate = Color(1, 1, 1, 0)

	_film_counter.add_theme_color_override("font_color", DesignTokens.COLORS.text_primary)


## Bind to a camera and connect to its signals.
func bind_camera(camera: Node) -> void:
	if _bound_camera != null:
		unbind_camera()

	_bound_camera = camera

	if camera.has_signal("aim_started"):
		camera.aim_started.connect(_on_aim_started)
	if camera.has_signal("aim_ended"):
		camera.aim_ended.connect(_on_aim_ended)
	if camera.has_signal("photo_captured"):
		camera.photo_captured.connect(_on_photo_captured)
	if camera.has_signal("photo_missed"):
		camera.photo_missed.connect(_on_photo_missed)
	if camera.has_signal("film_changed"):
		camera.film_changed.connect(_update_film_display)
	if camera.has_signal("cooldown_changed"):
		camera.cooldown_changed.connect(_update_cooldown_display)


## Disconnect from bound camera.
func unbind_camera() -> void:
	if _bound_camera == null:
		return

	if _bound_camera.has_signal("aim_started"):
		_bound_camera.aim_started.disconnect(_on_aim_started)
	if _bound_camera.has_signal("aim_ended"):
		_bound_camera.aim_ended.disconnect(_on_aim_ended)
	if _bound_camera.has_signal("photo_captured"):
		_bound_camera.photo_captured.disconnect(_on_photo_captured)
	if _bound_camera.has_signal("photo_missed"):
		_bound_camera.photo_missed.disconnect(_on_photo_missed)
	if _bound_camera.has_signal("film_changed"):
		_bound_camera.film_changed.disconnect(_update_film_display)
	if _bound_camera.has_signal("cooldown_changed"):
		_bound_camera.cooldown_changed.disconnect(_update_cooldown_display)

	_bound_camera = null


## Update film counter display.
func _update_film_display(remaining: int, max_film: int) -> void:
	_film_counter.text = "%d/%d" % [remaining, max_film]

	# Change color if low on film (1 or 0 remaining)
	if remaining <= 1:
		_film_counter.add_theme_color_override(
			"font_color",
			DesignTokens.COLORS.accent_warning
		)
	else:
		_film_counter.add_theme_color_override(
			"font_color",
			DesignTokens.COLORS.text_primary
		)


## Update cooldown progress bar.
func _update_cooldown_display(cooldown_remaining: float, cooldown_max: float) -> void:
	if cooldown_remaining > 0.0:
		_cooldown_bar.visible = true
		_cooldown_bar.max_value = cooldown_max
		_cooldown_bar.value = cooldown_remaining
	else:
		_cooldown_bar.visible = false


## Play capture flash effect.
func _play_capture_flash(success: bool) -> void:
	if _flash_tween != null:
		_flash_tween.kill()

	_flash_tween = create_tween()

	if success:
		# White flash for success
		_flash_overlay.color = Color.WHITE
		_flash_overlay.modulate = Color(1, 1, 1, 0.8)
	else:
		# Red tint for miss
		_flash_overlay.color = DesignTokens.COLORS.text_danger
		_flash_overlay.modulate = Color(1, 1, 1, 0.6)

	_flash_tween.tween_property(
		_flash_overlay,
		"modulate:a",
		0.0,
		DesignTokens.ANIMATION.duration_fast
	)


# --- Signal Handlers ---


func _on_aim_started() -> void:
	_viewfinder_container.visible = true


func _on_aim_ended() -> void:
	_viewfinder_container.visible = false


func _on_photo_captured(_record: PhotoRecord) -> void:
	_play_capture_flash(true)


func _on_photo_missed() -> void:
	_play_capture_flash(false)
