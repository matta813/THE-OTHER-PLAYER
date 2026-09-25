extends Node

func _ready() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var output := OS.get_environment("TOP_CAPTURE_DIR")
	if output.is_empty(): output = "/tmp/top-captures"
	DirAccess.make_dir_recursive_absolute(output)
	var menu: Node3D = load("res://scenes/main_menu.tscn").instantiate()
	add_child(menu)
	await _frames(8)
	_save(output.path_join("menu.png"))
	var menu_ui := menu.get_node("UI/Menu") as MenuUI
	menu_ui.call("_show_settings", "VIDEO")
	await _frames(3)
	_save(output.path_join("settings.png"))
	menu_ui.call("_show_slots", false)
	await _frames(3)
	_save(output.path_join("load_slots.png"))
	menu.queue_free()
	await _frames(2)
	var game: Node3D = load("res://scenes/chapter_01.tscn").instantiate()
	add_child(game)
	var player: FirstPersonController = game.get_node("Player")
	player.set_physics_process(false)
	player.camera.make_current()
	var shots := [
		["arrival.png", Vector3(0, 1.0, 5), 0.0],
		["security.png", Vector3(0, 1.0, -22), -0.65],
		["generator.png", Vector3(-1.0, 1.0, -35), 0.65],
		["transfer.png", Vector3(1.0, 1.0, -43), -0.6],
		["airlock.png", Vector3(0, 1.0, -54.5), 0.0],
		["terminal_close.png", Vector3(-2.8, 1.0, 1.1), 0.0],
		["security_close.png", Vector3(4.2, 1.0, -21.4), 0.0],
		["generator_close.png", Vector3(-2.75, 1.0, -35.25), 0.55],
		["airlock_wall.png", Vector3(0, 1.0, -54.5), -PI / 2.0],
		["airlock_control.png", Vector3(0.0, 1.0, -54.0), -PI / 2.0],
		["transfer_close.png", Vector3(4.3, 1.0, -42.5), 0.0],
		["airlock_close.png", Vector3(0, 1.0, -56.0), 0.0]
	]
	var selected := OS.get_environment("TOP_CAPTURE_SHOT")
	for shot in shots:
		if shot[0] != (selected if not selected.is_empty() else "arrival.png"): continue
		player.global_position = shot[1]
		player.rotation.y = shot[2]
		player.reset_physics_interpolation()
		player.camera.reset_physics_interpolation()
		await get_tree().create_timer(0.4).timeout
		_save(output.path_join(shot[0]))
	game.queue_free()
	await _frames(2)
	get_tree().quit()

func _frames(count: int) -> void:
	for i in count: await get_tree().process_frame

func _save(path: String) -> void:
	var image := get_viewport().get_texture().get_image()
	if image: image.save_png(path); print("CAPTURE: ", path)
