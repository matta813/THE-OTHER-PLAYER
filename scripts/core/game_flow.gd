extends Node

const GAME_SCENE := "res://scenes/chapter_01.tscn"
const MENU_SCENE := "res://scenes/main_menu.tscn"
var pending_save := ""
var loading := false
var loading_layer: CanvasLayer

func start_game(path := "") -> void:
	if loading: return
	pending_save = path
	GameRuntime.reset_state()
	get_tree().paused = false
	loading = true
	_show_loading()
	call_deferred("_load_game")

func _show_loading() -> void:
	loading_layer = CanvasLayer.new()
	loading_layer.name = "LoadingPresentation"
	loading_layer.layer = 100
	loading_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(loading_layer)
	var background := ColorRect.new()
	background.color = Color(0.006, 0.012, 0.014)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	loading_layer.add_child(background)
	var title := Label.new()
	title.text = "FACILITY LINK  /  01"
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	title.position = Vector2(-180, -48)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.54, 0.75, 0.62))
	loading_layer.add_child(title)
	var status := Label.new()
	status.text = "ESTABLISHING CONNECTION"
	status.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	status.position = Vector2(-180, -12)
	status.add_theme_font_size_override("font_size", 13)
	status.add_theme_color_override("font_color", Color(0.73, 0.82, 0.76))
	loading_layer.add_child(status)

func _load_game() -> void:
	var result := ResourceLoader.load_threaded_request(GAME_SCENE)
	if result != OK:
		push_error("Could not request Chapter 1 scene: %s" % result)
		_finish_loading()
		return
	var state := ResourceLoader.THREAD_LOAD_IN_PROGRESS
	while state == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
		state = ResourceLoader.load_threaded_get_status(GAME_SCENE)
	if state != ResourceLoader.THREAD_LOAD_LOADED:
		push_error("Chapter 1 scene failed to load")
		_finish_loading()
		return
	var scene := ResourceLoader.load_threaded_get(GAME_SCENE) as PackedScene
	if scene == null:
		push_error("Chapter 1 scene is invalid")
		_finish_loading()
		return
	await get_tree().create_timer(0.12).timeout
	var changed := get_tree().change_scene_to_packed(scene)
	if changed != OK: push_error("Chapter 1 scene transition failed: %s" % changed)
	await get_tree().process_frame
	_finish_loading()

func _finish_loading() -> void:
	loading = false
	if loading_layer:
		loading_layer.queue_free()
		loading_layer = null

func main_menu() -> void:
	pending_save = ""
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_finish_loading()
	get_tree().change_scene_to_file(MENU_SCENE)

func quit() -> void:
	get_tree().paused = false
	get_tree().quit()
