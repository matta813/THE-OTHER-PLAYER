class_name MenuUI
extends Control

var game_root: Node3D
var content: VBoxContainer
var heading: Label
var info: Label
var page := "home"
var waiting_action := ""
var binding_action := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.006, 0.012, 0.016, 0.86 if game_root else 0.24)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_top", 66)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_bottom", 52)
	add_child(margin)
	var frame := HBoxContainer.new(); margin.add_child(frame)
	var column := VBoxContainer.new(); column.custom_minimum_size.x = 430; frame.add_child(column)
	var eyebrow := _label("FACILITY LINK  /  01", 13, Color(0.43, 0.72, 0.6)); column.add_child(eyebrow)
	column.add_child(_spacer(22))
	heading = _label(ReleaseInfo.TITLE, 39, Color(0.86, 0.91, 0.87)); column.add_child(heading)
	column.add_child(_spacer(30))
	content = VBoxContainer.new(); content.add_theme_constant_override("separation", 7); column.add_child(content)
	column.add_spacer(false)
	info = _label("", 14, Color(0.72, 0.81, 0.77)); column.add_child(info)
	column.add_child(_spacer(12))
	column.add_child(_label("%s   •   CHAPTER 1 / CONNECTION" % ReleaseInfo.VERSION, 12, Color(0.43, 0.56, 0.53)))
	_show_home()

func _label(value: String, size: int, color: Color) -> Label:
	var label := Label.new(); label.text = value; label.add_theme_font_size_override("font_size", size); label.add_theme_color_override("font_color", color); label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _spacer(height: float) -> Control:
	var node := Control.new(); node.custom_minimum_size.y = height; return node

func _button(label: String, action: Callable) -> Button:
	var button := Button.new(); button.text = label; button.custom_minimum_size = Vector2(350, 39); button.alignment = HORIZONTAL_ALIGNMENT_LEFT; button.focus_mode = Control.FOCUS_ALL
	button.add_theme_color_override("font_color", Color(0.77, 0.88, 0.82))
	button.pressed.connect(action)
	content.add_child(button)
	return button

func _clear() -> void:
	for child in content.get_children(): child.queue_free()
	info.text = ""

func _show_home() -> void:
	page = "home"; _clear(); heading.text = "PAUSED" if game_root else ReleaseInfo.TITLE
	if game_root:
		_button("RESUME", _resume)
		_button("SETTINGS", func() -> void: _show_settings("VIDEO"))
		_button("SAVE", func() -> void: _show_slots(true))
		_button("LOAD", func() -> void: _show_slots(false))
		_button("RETURN TO MAIN MENU", func() -> void: _confirm("menu"))
		_button("QUIT TO DESKTOP", func() -> void: _confirm("quit"))
	else:
		var latest := SaveSystem.recent_path()
		if not latest.is_empty(): _button("CONTINUE", func() -> void: GameFlow.start_game(latest))
		_button("NEW GAME", func() -> void: _confirm("new") if not SaveSystem.recent_path().is_empty() else GameFlow.start_game())
		_button("LOAD GAME", func() -> void: _show_slots(false))
		_button("SETTINGS", func() -> void: _show_settings("VIDEO"))
		_button("CREDITS", _show_credits)
		_button("QUIT", GameFlow.quit)

func _confirm(action: String) -> void:
	waiting_action = action; page = "confirm"; _clear(); heading.text = "CONFIRM"
	var prompt := "Start a new game? Existing manual slots are kept. The next checkpoint will be replaced."
	if action == "menu": prompt = "Return to the main menu? Unsaved progress will be lost."
	if action == "quit": prompt = "Quit to desktop? Unsaved progress will be lost."
	content.add_child(_label(prompt, 17, Color(0.78, 0.85, 0.81)))
	_button("CONFIRM", _confirm_action)
	_button("CANCEL", _show_home)

func _confirm_action() -> void:
	match waiting_action:
		"new": GameFlow.start_game()
		"menu": GameFlow.main_menu()
		"quit": GameFlow.quit()

func _show_slots(saving: bool) -> void:
	page = "slots"; _clear(); heading.text = "SAVE GAME" if saving else "LOAD GAME"
	for index in range(1, SaveSystem.SLOT_COUNT + 1):
		var path := SaveSystem.slot_path(index)
		var slot := SaveSystem.slot_info(path)
		var detail := "EMPTY"
		if slot.state == "invalid": detail = "INVALID SAVE"
		elif slot.state == "valid":
			var time_text := "UNKNOWN DATE" if int(slot.timestamp) <= 0 else Time.get_datetime_string_from_unix_time(int(slot.timestamp), true)
			var minutes := int(float(slot.playtime) / 60.0)
			detail = "%s  /  %s\n       %02d:%02d  /  %s  /  v%s" % [slot.chapter, slot.location, minutes / 60, minutes % 60, time_text, slot.game_version]
		var number := index
		var button := _button("%02d   %s" % [index, detail], func() -> void: _choose_slot(number, saving))
		button.custom_minimum_size.y = 59 if slot.state == "valid" else 39
		button.disabled = not saving and slot.state != "valid"
	if not saving:
		for path in [SaveSystem.PATH, SaveSystem.CHECKPOINT_PATH]:
			var info_data := SaveSystem.slot_info(path)
			if info_data.state == "valid":
				var selected: String = path
				_button("%s   /   %s" % ["QUICK SAVE" if path == SaveSystem.PATH else "CHECKPOINT", info_data.location], func() -> void: _load_path(selected))
	_button("BACK", _show_home)

func _choose_slot(index: int, saving: bool) -> void:
	if saving:
		if SaveSystem.slot_info(SaveSystem.slot_path(index)).state != "empty":
			page = "overwrite"; _clear(); heading.text = "OVERWRITE SLOT %02d?" % index
			_button("OVERWRITE", func() -> void: _save_slot(index))
			_button("CANCEL", func() -> void: _show_slots(true))
		else: _save_slot(index)
	else: _load_path(SaveSystem.slot_path(index))

func _save_slot(index: int) -> void:
	info.text = "SAVED" if SaveSystem.save_slot(index, game_root.get_node("Player")) else "SAVE FAILED"
	_show_slots(true)

func _load_path(path: String) -> void:
	if game_root:
		if SaveSystem.load_from(path, game_root.get_node("Player")):
			game_root.call("_restore_visual_state")
			_resume()
		else: info.text = "SAVE COULD NOT BE LOADED"
	else: GameFlow.start_game(path)

func _show_credits() -> void:
	page = "credits"; _clear(); heading.text = "CREDITS"
	content.add_child(_label("THE OTHER PLAYER\n\nBuilt with Godot Engine.\n\nOriginal development and generated in-project visuals and sounds.\nGodot Engine license: godotengine.org/license.
See THIRD_PARTY.md for verified attribution.", 18, Color(0.75, 0.84, 0.79)))
	_button("BACK", _show_home)

func _show_settings(category: String) -> void:
	page = "settings"; _clear(); heading.text = "SETTINGS"
	var categories := OptionButton.new()
	for name in ["VIDEO", "AUDIO", "CONTROLS", "GAMEPLAY", "ACCESSIBILITY"]: categories.add_item(name)
	categories.select(["VIDEO", "AUDIO", "CONTROLS", "GAMEPLAY", "ACCESSIBILITY"].find(category))
	categories.item_selected.connect(func(index: int) -> void: _show_settings(categories.get_item_text(index)))
	content.add_child(categories)
	var scroll := ScrollContainer.new(); scroll.custom_minimum_size.y = 390; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; content.add_child(scroll)
	var rows := VBoxContainer.new(); rows.custom_minimum_size.x = 390; rows.add_theme_constant_override("separation", 6); scroll.add_child(rows)
	match category:
		"VIDEO":
			_choice(rows, "Display mode", "display_mode", ["Windowed", "Fullscreen", "Exclusive fullscreen"])
			_choice(rows, "Resolution", "resolution", ["1280 × 720", "1600 × 900", "1920 × 1080", "2560 × 1440"])
			_toggle(rows, "VSync", "vsync")
			_choice(rows, "FPS limit", "fps_limit", ["Unlimited", "30", "60", "120", "144"], [0, 30, 60, 120, 144])
			_choice(rows, "Quality preset", "preset", ["CUSTOM", "LOW", "MEDIUM", "HIGH", "ULTRA"])
			_slider(rows, "Render scale", "render_scale", 0.5, 1.0, 0.05)
			_choice(rows, "Anti-aliasing", "antialiasing", ["Off", "2× MSAA", "4× MSAA"])
			_toggle(rows, "Shadows", "shadows")
			_toggle(rows, "Volumetric fog", "volumetric")
			_toggle(rows, "Reflections", "reflections")
			_toggle(rows, "Ambient occlusion", "ambient_occlusion")
			_slider(rows, "Field of view", "fov", 65, 100, 1)
		"AUDIO":
			for key in ["master", "ambience", "sfx", "ui", "voice"]: _slider(rows, key.capitalize(), key, 0, 1, 0.05)
		"CONTROLS":
			_slider(rows, "Mouse sensitivity", "mouse_sensitivity", 0.0005, 0.005, 0.0001)
			_toggle(rows, "Invert Y", "invert_y")
			_toggle(rows, "Toggle sprint", "sprint_toggle")
			_toggle(rows, "Toggle crouch", "crouch_toggle")
			for action in GameSettings.ACTIONS:
				var button := Button.new(); button.text = "%s  :  %s" % [action.replace("_", " ").capitalize(), OS.get_keycode_string(int(GameSettings.bindings[action]))]
				button.pressed.connect(func() -> void: binding_action = action; info.text = "Press a key for %s (Esc cancels)" % action.replace("_", " "))
				rows.add_child(button)
			var reset := Button.new(); reset.text = "RESET KEY BINDINGS"; reset.pressed.connect(func() -> void: GameSettings.reset_bindings(); _show_settings("CONTROLS")); rows.add_child(reset)
		"GAMEPLAY":
			_toggle(rows, "Subtitles", "subtitles")
			_toggle(rows, "Toggle sprint", "sprint_toggle")
			_toggle(rows, "Toggle crouch", "crouch_toggle")
		"ACCESSIBILITY":
			_toggle(rows, "Subtitles", "subtitles")
			_slider(rows, "Subtitle size", "subtitle_size", 16, 32, 1)
			_toggle(rows, "High contrast prompt", "high_contrast_prompt")
			_slider(rows, "Camera bob", "camera_bob", 0, 1, 0.1)
			_toggle(rows, "Reduce motion", "reduce_motion")
	_button("BACK", _show_home)

func _toggle(parent: Node, label: String, key: String) -> void:
	var check := CheckBox.new(); check.text = label; check.button_pressed = bool(GameSettings.get_value(key)); check.toggled.connect(func(value: bool) -> void: GameSettings.set_value(key, value)); parent.add_child(check)

func _choice(parent: Node, label: String, key: String, names: Array, mapped: Array = []) -> void:
	parent.add_child(_label(label, 14, Color(0.62, 0.77, 0.69)))
	var choice := OptionButton.new(); parent.add_child(choice)
	for name in names: choice.add_item(name)
	if key != "preset":
		var current: Variant = GameSettings.get_value(key)
		var selected: int = mapped.find(current) if not mapped.is_empty() else int(current)
		choice.select(maxi(selected, 0))
	choice.item_selected.connect(func(index: int) -> void:
		if key == "preset" and index > 0: GameSettings.set_preset(names[index]); _show_settings("VIDEO")
		else: GameSettings.set_value(key, mapped[index] if not mapped.is_empty() else index))

func _slider(parent: Node, label: String, key: String, minimum: float, maximum: float, step: float) -> void:
	var title := _label(label, 14, Color(0.62, 0.77, 0.69)); parent.add_child(title)
	var slider := HSlider.new(); slider.min_value = minimum; slider.max_value = maximum; slider.step = step; slider.value = float(GameSettings.get_value(key)); parent.add_child(slider)
	slider.value_changed.connect(func(value: float) -> void: GameSettings.set_value(key, int(value) if key in ["fov", "subtitle_size"] else value))

func _resume() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	queue_free()

func _input(event: InputEvent) -> void:
	if binding_action.is_empty() or not event is InputEventKey or not event.pressed or event.echo: return
	get_viewport().set_input_as_handled()
	if event.keycode != KEY_ESCAPE:
		var result := GameSettings.rebind(binding_action, event.physical_keycode)
		if not result.is_empty(): info.text = result; return
	binding_action = ""; _show_settings("CONTROLS")

func _unhandled_input(event: InputEvent) -> void:
	if game_root and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if page == "home": _resume()
		else: _show_home()
