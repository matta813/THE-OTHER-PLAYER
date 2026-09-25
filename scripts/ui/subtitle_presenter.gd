class_name SubtitlePresenter
extends CanvasLayer

var speaker_label: Label
var text_label: Label
var queue: Array[Dictionary] = []
var active_priority := -1
var remaining := 0.0

func _ready() -> void:
	layer = 5
	var panel := PanelContainer.new(); panel.name = "CaptionPanel"; panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM); panel.position = Vector2(-280, -132); panel.custom_minimum_size = Vector2(560, 0); panel.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(panel)
	var style := StyleBoxFlat.new(); style.bg_color = Color(0.01, 0.024, 0.025, 0.9); style.content_margin_left = 16; style.content_margin_right = 16; style.content_margin_top = 10; style.content_margin_bottom = 12; style.border_width_left = 2; style.border_color = Color(0.26, 0.52, 0.43); panel.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new(); panel.add_child(column)
	speaker_label = Label.new(); speaker_label.add_theme_font_size_override("font_size", 13); speaker_label.add_theme_color_override("font_color", Color(0.47, 0.8, 0.63)); column.add_child(speaker_label)
	text_label = Label.new(); text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; text_label.custom_minimum_size.x = 520; text_label.add_theme_color_override("font_color", Color(0.88, 0.92, 0.88)); column.add_child(text_label)
	panel.visible = false

func show_caption(speaker: String, caption: String, duration: float = 3.5, priority: int = 0, interrupt: bool = false) -> void:
	if not GameSettings.get_value("subtitles") or caption.is_empty(): return
	var entry := {"speaker": speaker, "text": caption, "duration": maxf(duration, 1.0), "priority": priority}
	if remaining <= 0.0 or (interrupt and priority >= active_priority):
		_show(entry)
	else:
		queue.append(entry)
		queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.priority) > int(b.priority))
		if queue.size() > 8: queue.resize(8)

func _show(entry: Dictionary) -> void:
	active_priority = int(entry.priority); remaining = float(entry.duration)
	speaker_label.text = String(entry.speaker).to_upper(); text_label.text = String(entry.text)
	text_label.add_theme_font_size_override("font_size", int(GameSettings.get_value("subtitle_size")))
	$CaptionPanel.visible = true

func _process(delta: float) -> void:
	if remaining <= 0.0: return
	remaining -= delta
	if remaining > 0.0: return
	if queue.is_empty(): $CaptionPanel.visible = false; active_priority = -1
	else: _show(queue.pop_front())
