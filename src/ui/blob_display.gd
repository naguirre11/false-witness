extends Control
## Custom drawing canvas for the Prism Calibrator blob visualization.
##
## This control delegates its _draw() call to the parent PrismCalibratorView,
## which handles the actual blob rendering based on alignment state.


func _draw() -> void:
	var parent := get_parent()
	while parent:
		if parent.has_method("draw_blobs"):
			parent.draw_blobs(self)
			return
		parent = parent.get_parent()

	# Fallback: draw a placeholder if no parent handler found
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.2, 0.2, 0.2, 0.5))
	draw_string(
		ThemeDB.fallback_font,
		size / 2.0 - Vector2(50, 0),
		"No Signal",
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		16,
		Color.WHITE
	)
