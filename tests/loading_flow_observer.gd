extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	GameFlow.start_game()
	if not GameFlow.loading or GameFlow.loading_layer == null:
		push_error("Loading presentation did not appear")
		get_tree().quit(1)
		return
	var deadline := Time.get_ticks_msec() + 10000
	while GameFlow.loading and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	if GameFlow.loading or get_tree().current_scene == null or get_tree().current_scene.scene_file_path != GameFlow.GAME_SCENE:
		push_error("Loading did not reach Chapter 1")
		get_tree().quit(1)
		return
	if get_tree().current_scene.get_node_or_null("ChapterOne") == null:
		push_error("Loaded chapter has no controller")
		get_tree().quit(1)
		return
	print("LOADING FLOW: Chapter 1 reached with presentation dismissed")
	get_tree().quit()
