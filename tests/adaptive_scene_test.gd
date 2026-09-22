extends Node3D

var failures := 0
var checks := 0

func _ready() -> void:
	var level := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(level)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var player: Node3D = level.get_node("Player")
	var door: ElectronicDoor = level.get_node("Door")
	door.interact(player)
	level.last_door_attempt_time -= 3.0
	door.interact(player)
	level.last_door_attempt_time -= 3.0
	door.interact(player)
	check(GameRuntime.behaviour.count(&"door_rechecked") == 2 and GameRuntime.habits.confidence_for(&"DOOR_RECHECK") > 0.4, "separated door checks establish usable habit")
	(level.get_node("Terminal") as FacilityTerminal).interact(player)
	for item in GameRuntime.other_player.scheduled:
		if item.action == &"unlock": item.due = GameRuntime.other_player.now() - 0.01
	await get_tree().process_frame
	await get_tree().process_frame
	check(GameRuntime.story_stage == 2 and not door.locked, "reliable remote unlock still occurs")
	player.global_position = Vector3(0, 1.0, -3.5)
	await get_tree().process_frame
	check(GameRuntime.director.last_decision.get("selected", "") == "EARLY_LIGHT_ASSIST", "observed habit selects anticipatory light")
	var scheduled_light := false
	for item in GameRuntime.other_player.scheduled:
		if item.action == &"light_on":
			scheduled_light = true
			item.due = GameRuntime.other_player.now() - 0.01
	check(scheduled_light, "manipulation is scheduled, not instantaneous")
	await get_tree().process_frame
	check((level.get_node("RoomLight") as Light3D).visible and not (level.get_node("PowerSwitch") as PowerSwitch).powered, "room light anticipates player before circuit activation")
	check(GameRuntime.other_player.memory.anticipated_light and GameRuntime.trust_strategy.reliable_help_count == 2, "adaptive help updates agent and trust memory")
	var saved := JSON.parse_string(JSON.stringify(SaveSystem.build_data(player))) as Dictionary
	check(SaveSystem.apply_data(player, saved), "manipulation state survives save round trip")
	level._restore_visual_state()
	check((level.get_node("RoomLight") as Light3D).visible and GameRuntime.director.manipulation_count == 1, "restored visuals and pacing retain the cooperative intervention")
	player.global_position = Vector3(0, 1.0, -7.5)
	await get_tree().process_frame
	(level.get_node("PowerSwitch") as PowerSwitch).interact(player)
	check(GameRuntime.story_stage == 4 and GameRuntime.director.last_decision.get("selected", "") != "DELAY_ACK", "unusual interventions do not stack in the same moment")
	print("ADAPTIVE SCENE: %d checks, %d failed" % [checks, failures])
	get_tree().quit(failures)

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + label)
