extends Node

signal changed
const PATH := "user://settings.json"
const ACTIONS := ["move_forward", "move_back", "move_left", "move_right", "sprint", "crouch", "interact", "quick_save", "quick_load"]
const BUS_NAMES := ["Ambience", "SFX", "UI", "Voice"]
const DEFAULTS := {
	"display_mode": 0, "resolution": 0, "vsync": true, "fps_limit": 0,
	"render_scale": 1.0, "antialiasing": 1, "shadows": true,
	"volumetric": true, "ambient_occlusion": true, "reflections": true,
	"fov": 75.0,
	"master": 0.8, "ambience": 0.65, "sfx": 0.8, "ui": 0.8, "voice": 0.85,
	"mouse_sensitivity": 0.0019, "invert_y": false, "sprint_toggle": false,
	"crouch_toggle": false, "subtitles": true, "subtitle_size": 20,
	"high_contrast_prompt": false, "camera_bob": 0.6,
	"reduce_motion": false
}
const RESOLUTIONS := [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]
var values: Dictionary = DEFAULTS.duplicate(true)
var default_bindings: Dictionary = {}
var bindings: Dictionary = {}

func _ready() -> void:
	for action in ACTIONS:
		var events := InputMap.action_get_events(action)
		if not events.is_empty() and events[0] is InputEventKey:
			default_bindings[action] = (events[0] as InputEventKey).physical_keycode
	bindings = default_bindings.duplicate()
	for bus_name in BUS_NAMES:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
	load_settings()

func get_value(key: String) -> Variant: return values.get(key, DEFAULTS.get(key))

func set_value(key: String, value: Variant) -> void:
	if not DEFAULTS.has(key): return
	values[key] = value
	apply()
	save_settings()
	changed.emit()

func set_preset(name: String) -> void:
	var presets := {
		"LOW": [0.7, 0, false, false, false, false],
		"MEDIUM": [0.85, 1, true, false, true, false],
		"HIGH": [1.0, 1, true, true, true, true],
		"ULTRA": [1.0, 2, true, true, true, true]
	}
	if not presets.has(name): return
	var preset: Array = presets[name]
	for i in ["render_scale", "antialiasing", "shadows", "volumetric", "ambient_occlusion", "reflections"].size():
		values[["render_scale", "antialiasing", "shadows", "volumetric", "ambient_occlusion", "reflections"][i]] = preset[i]
	apply(); save_settings(); changed.emit()

func apply() -> void:
	var window := get_window()
	if window:
		window.mode = [Window.MODE_WINDOWED, Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN][clampi(int(values.display_mode), 0, 2)]
		if window.mode == Window.MODE_WINDOWED:
			window.size = RESOLUTIONS[clampi(int(values.resolution), 0, RESOLUTIONS.size() - 1)]
		window.title = "%s  |  %s" % [ReleaseInfo.TITLE, ReleaseInfo.VERSION]
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if bool(values.vsync) else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = maxi(int(values.fps_limit), 0)
	get_viewport().scaling_3d_scale = clampf(float(values.render_scale), 0.5, 1.0)
	get_viewport().msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][clampi(int(values.antialiasing), 0, 2)]
	for name in ["master", "ambience", "sfx", "ui", "voice"]:
		var bus: String = "Master" if name == "master" else name.capitalize()
		var index := AudioServer.get_bus_index(bus)
		if index >= 0: AudioServer.set_bus_volume_db(index, linear_to_db(maxf(float(values[name]), 0.001)))
	for action in bindings:
		_apply_binding(action, int(bindings[action]))

func apply_environment(environment: Environment) -> void:
	if environment == null: return
	environment.volumetric_fog_enabled = bool(values.volumetric)
	environment.ssao_enabled = bool(values.ambient_occlusion)
	environment.ssr_enabled = bool(values.reflections)

func rebind(action: String, physical_code: Key) -> String:
	if not ACTIONS.has(action) or physical_code == KEY_NONE: return "Invalid key"
	for other in bindings:
		if other != action and int(bindings[other]) == physical_code: return "%s already uses this key" % other.replace("_", " ").capitalize()
	bindings[action] = physical_code
	_apply_binding(action, physical_code)
	save_settings(); changed.emit()
	return ""

func reset_bindings() -> void:
	bindings = default_bindings.duplicate()
	apply(); save_settings(); changed.emit()

func _apply_binding(action: String, physical_code: Key) -> void:
	InputMap.action_erase_events(action)
	var event := InputEventKey.new()
	event.physical_keycode = physical_code
	InputMap.action_add_event(action, event)

func save_settings() -> void:
	var file := FileAccess.open(PATH + ".tmp", FileAccess.WRITE)
	if file == null: return
	file.store_string(JSON.stringify({"values": values, "bindings": bindings}, "  "))
	file.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(PATH + ".tmp"), ProjectSettings.globalize_path(PATH))

func load_settings() -> void:
	if FileAccess.file_exists(PATH):
		var parser := JSON.new()
		var parsed: Variant = parser.data if parser.parse(FileAccess.get_file_as_string(PATH)) == OK else null
		if parsed is Dictionary:
			var loaded_values: Variant = parsed.get("values", {})
			if loaded_values is Dictionary:
				for key in DEFAULTS:
					if loaded_values.has(key) and (typeof(loaded_values[key]) == typeof(DEFAULTS[key]) or (loaded_values[key] is float and DEFAULTS[key] is int) or (loaded_values[key] is int and DEFAULTS[key] is float)): values[key] = loaded_values[key]
			var loaded_bindings: Variant = parsed.get("bindings", {})
			if loaded_bindings is Dictionary:
				for action in ACTIONS:
					if loaded_bindings.has(action) and (loaded_bindings[action] is int or loaded_bindings[action] is float) and int(loaded_bindings[action]) > 0: bindings[action] = int(loaded_bindings[action])
	apply()
