extends Node

const GAME_SCENE := "res://scenes/chapter_01.tscn"
const MENU_SCENE := "res://scenes/main_menu.tscn"
var pending_save := ""

func start_game(path := "") -> void:
	pending_save = path
	GameRuntime.reset_state()
	get_tree().paused = false
	get_tree().change_scene_to_file(GAME_SCENE)

func main_menu() -> void:
	pending_save = ""
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MENU_SCENE)

func quit() -> void:
	get_tree().paused = false
	get_tree().quit()
