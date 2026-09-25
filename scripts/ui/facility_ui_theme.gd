class_name FacilityUITheme
extends RefCounted

static func create() -> Theme:
	var result := Theme.new()
	result.default_font_size = 16
	var normal := _box(Color(0.015, 0.026, 0.028, 0.94), Color(0.17, 0.31, 0.27), 2)
	var hover := _box(Color(0.038, 0.065, 0.061, 0.98), Color(0.43, 0.72, 0.60), 3)
	var pressed := _box(Color(0.065, 0.12, 0.103, 1.0), Color(0.58, 0.84, 0.67), 3)
	var disabled := _box(Color(0.018, 0.025, 0.025, 0.72), Color(0.10, 0.16, 0.15), 2)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color(0.62, 0.84, 0.71, 0.9)
	focus.set_border_width_all(1)
	for type in ["Button", "OptionButton", "CheckBox"]:
		result.set_stylebox("normal", type, normal)
		result.set_stylebox("hover", type, hover)
		result.set_stylebox("pressed", type, pressed)
		result.set_stylebox("disabled", type, disabled)
		result.set_stylebox("focus", type, focus)
		result.set_color("font_color", type, Color(0.78, 0.86, 0.81))
		result.set_color("font_hover_color", type, Color(0.91, 0.96, 0.92))
		result.set_color("font_pressed_color", type, Color.WHITE)
		result.set_color("font_disabled_color", type, Color(0.36, 0.47, 0.44))
		result.set_font_size("font_size", type, 15)
	result.set_stylebox("panel", "Panel", _box(Color(0.01, 0.024, 0.025, 0.94), Color(0.17, 0.38, 0.31), 1))
	result.set_stylebox("panel", "PopupMenu", _box(Color(0.015, 0.03, 0.031, 0.99), Color(0.28, 0.48, 0.4), 1))
	result.set_color("font_color", "PopupMenu", Color(0.77, 0.88, 0.8))
	result.set_color("font_hover_color", "PopupMenu", Color.WHITE)
	return result

static func _box(fill: Color, border: Color, left: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = left
	style.content_margin_left = 17
	style.content_margin_right = 12
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style
