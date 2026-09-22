extends Node3D

var failures := 0
var checks := 0

func _ready() -> void:
	var level := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(level)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var player: FirstPersonController = level.get_node("Player")
	var chapter: ChapterOneController = level.get_node("ChapterOne")
	GameRuntime.story_stage = 4
	GameRuntime.trust.player_trust_in_other_player = 0.75
	for index in 3: GameRuntime.habits.observe(&"FAST_COOPERATOR", &"", true, Time.get_unix_time_from_system() + index)
	chapter.load_state({"stage": ChapterOneController.Stage.AIRLOCK, "grid": chapter.grid.to_dict(), "airlock": chapter.airlock.state_dict()})
	player.global_position = Vector3(0, 1, -54)
	await get_tree().process_frame
	await get_tree().process_frame
	check(chapter.airlock.phase == AirlockSystem.Phase.REQUESTED and chapter.airlock.predicted_start, "trusted, observed approach can start an anticipatory airlock cycle")
	check(GameRuntime.predictions.current.get("result", "") == "preempted" and GameRuntime.predictions.evaluated == 0, "preempted airlock prediction is retained without mis-scoring")
	check(GameRuntime.behaviour.count(&"airlock_anticipated") == 1 and GameRuntime.director.last_decision.get("selected", "") == "ANTICIPATE_AIRLOCK", "psychological event records director rationale and player-facing action")
	print("CHAPTER ADAPTIVE: %d checks, %d failed" % [checks, failures])
	level.queue_free()
	await get_tree().process_frame
	get_tree().quit(failures)

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + label)
