extends Control
## Custom drawing canvas for the Prism Lens Reader pattern visualization.
##
## This control delegates its _draw() call to the parent PrismLensView,
## which handles the actual pattern rendering based on calibration state.


func _draw() -> void:
	var parent := get_parent()
	while parent:
		if parent.has_method("draw_pattern"):
			parent.draw_pattern(self)
			return
		parent = parent.get_parent()

	# Fallback: draw a placeholder if no parent handler found
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.15, 0.15, 0.15, 0.8))
	draw_string(
		ThemeDB.fallback_font,
		size / 2.0 - Vector2(40, 0),
		"No Signal",
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		14,
		Color.GRAY
	)
