extends Control
## Custom drawing canvas for the Aura Imager aura visualization.
##
## This control delegates its _draw() call to the parent AuraImagerView,
## which handles the actual aura rendering based on resolution and form.


func _draw() -> void:
	var parent := get_parent()
	while parent:
		if parent.has_method("draw_aura"):
			parent.draw_aura(self)
			return
		parent = parent.get_parent()

	# Fallback: draw a placeholder if no parent handler found
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.1, 0.15, 0.8))
	draw_string(
		ThemeDB.fallback_font,
		size / 2.0 - Vector2(40, 0),
		"No Signal",
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		14,
		Color.GRAY
	)
