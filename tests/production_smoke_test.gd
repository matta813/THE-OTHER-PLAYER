extends Node

var failures := 0
var checks := 0

func _ready() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("PRODUCTION SMOKE: " + description)

func _run() -> void:
	var game: Node3D = load("res://scenes/chapter_01.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	var player: FirstPersonController = game.get_node("Player")
	check(player != null and game.get_node("ChapterOne") != null, "Chapter 1 boots")
	var saved_position := player.global_position
	check(SaveSystem.save_slot(4, player), "manual slot writes")
	var info := SaveSystem.slot_info(SaveSystem.slot_path(4))
	check(info.state == "valid" and info.game_version == ReleaseInfo.VERSION, "slot metadata is readable")
	player.global_position = Vector3(1, 1, 1)
	check(SaveSystem.load_slot(4, player), "manual slot loads")
	check(player.global_position.distance_to(saved_position) < 0.01, "slot restores player position")
	var invalid_file := FileAccess.open(SaveSystem.slot_path(3), FileAccess.WRITE)
	invalid_file.store_string("{bad json"); invalid_file.close()
	check(SaveSystem.slot_info(SaveSystem.slot_path(3)).state == "invalid", "corrupt slot is displayed safely")
	check(not SaveSystem.load_slot(3, player), "corrupt slot is rejected")
	var malformed := SaveSystem.build_data(player)
	malformed["metadata"] = "broken"
	var nested_file := FileAccess.open(SaveSystem.slot_path(3), FileAccess.WRITE)
	nested_file.store_string(JSON.stringify(malformed)); nested_file.close()
	check(SaveSystem.slot_info(SaveSystem.slot_path(3)).state == "invalid", "malformed metadata is rejected")
	GameSettings.set_value("fov", 82)
	GameSettings.load_settings()
	check(int(GameSettings.get_value("fov")) == 82, "settings persist separately")
	var menu := MenuUI.new(); add_child(menu)
	check(menu.content.get_child_count() >= 6, "main menu has actions")
	menu.call("_show_slots", false)
	check(menu.page == "slots", "load slot view opens")
	for category in ["VIDEO", "AUDIO", "CONTROLS", "GAMEPLAY", "ACCESSIBILITY"]: menu.call("_show_settings", category)
	check(menu.page == "settings", "all settings categories open")
	menu.queue_free()
	var pause_ui := MenuUI.new(); pause_ui.game_root = game; add_child(pause_ui)
	check(pause_ui.content.get_child_count() == 6, "pause menu has six actions")
	pause_ui.queue_free()
	var before_pause := GameRuntime.other_player.now()
	get_tree().paused = true
	await get_tree().create_timer(0.08, true).timeout
	check(is_equal_approx(GameRuntime.other_player.now(), before_pause), "remote clock stops while paused")
	get_tree().paused = false
	game.queue_free()
	await get_tree().process_frame
	print("PRODUCTION SMOKE: %d checks, %d failed" % [checks, failures])
	get_tree().quit(1 if failures else 0)
