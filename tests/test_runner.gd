extends Node

var failures := 0
var total := 0

func _ready() -> void:
	test_behaviour_smoothing(); test_event_round_trip(); test_trust_bounds(); test_prediction_evaluation(); test_prediction_expiry(); test_scheduler_timing(); test_save_schema(); test_save_load_round_trip()
	print("TESTS: %d passed, %d failed" % [total - failures, failures]); get_tree().quit(failures)

func test_behaviour_smoothing() -> void:
	var model := BehaviourModel.new(); var initial: float = model.metrics[&"cooperation"]
	model.apply(BehaviourEvent.new(&"instruction_completed", Vector3.ZERO, &"switch", &"", 4.0))
	check(model.metrics[&"cooperation"] > initial and model.metrics[&"cooperation"] < 0.65, "single action updates without labelling aggressively")
	check(model.samples[&"cooperation"] == 1 and model.confidence[&"cooperation"] > 0.0, "model tracks samples and confidence")
	var first_delta: float = model.metrics[&"cooperation"] - initial; var before: float = model.metrics[&"cooperation"]
	model.apply(BehaviourEvent.new(&"instruction_completed", Vector3.ZERO, &"switch", &"", 4.0))
	check(model.metrics[&"cooperation"] - before < first_delta, "repeated evidence is smoothed")

func test_event_round_trip() -> void:
	var event := BehaviourEvent.new(&"room_entered", Vector3(1, 2, 3), &"room_b", &"threshold", 2.4, &"room_left", {"route": "east"}); var restored := BehaviourEvent.from_dict(event.to_dict())
	check(restored.world_position == Vector3(1, 2, 3) and restored.metadata.route == "east", "behaviour event round trip")

func test_trust_bounds() -> void:
	var trust := TrustModel.new()
	for i in 30: trust.reliable_help()
	check(trust.player_trust_in_other_player == 1.0, "trust remains bounded")
	var confidence := trust.other_player_confidence_in_player; trust.player_response(6.0, true)
	check(trust.other_player_confidence_in_player > confidence, "completed response raises independent confidence")

func test_prediction_evaluation() -> void:
	var prediction := PredictionSystem.new(); prediction.issue(&"interact", &"east_power", 0.7, 20.0, 10.0)
	check(prediction.observe(&"interact", &"east_power", 12.0), "prediction resolves matching action")
	check(prediction.correct == 1 and prediction.evaluated == 1 and prediction.accuracy() == 1.0, "prediction accuracy recorded")

func test_prediction_expiry() -> void:
	var prediction := PredictionSystem.new(); prediction.issue(&"interact", &"door", 0.4, 2.0, 10.0); prediction.expire(13.0)
	check(prediction.current.result == "expired" and prediction.evaluated == 1, "prediction expiry records failure")

func test_scheduler_timing() -> void:
	var agent := OtherPlayerAgent.new(); add_child(agent); var first := agent.schedule(&"unlock", &"door", 0.2, {}); agent.scheduled.clear(); var second := agent.schedule(&"unlock", &"door", 0.8, {})
	check(first > 0.7 and second > first, "complex tasks receive longer contextual delay"); agent.queue_free()

func test_save_schema() -> void:
	var player := Node3D.new(); add_child(player); player.position = Vector3(2, 3, 4); var data := SaveSystem.build_data(player); var decoded = JSON.parse_string(JSON.stringify(data))
	check(data.version == SaveSystem.VERSION and decoded.predictions is Dictionary and decoded.other_player is Dictionary, "save v2 contains agent and prediction state"); player.queue_free()

func test_save_load_round_trip() -> void:
	var player := Node3D.new(); add_child(player); player.position = Vector3(4, 1, -8); GameRuntime.story_stage = 3; GameRuntime.trust.player_trust_in_other_player = 0.61
	check(SaveSystem.save_game(player), "save writes versioned JSON"); player.position = Vector3.ZERO; GameRuntime.story_stage = 0; GameRuntime.trust.player_trust_in_other_player = 0.0
	check(SaveSystem.load_game(player) and player.position == Vector3(4, 1, -8) and GameRuntime.story_stage == 3 and is_equal_approx(GameRuntime.trust.player_trust_in_other_player, 0.61), "save/load restores progression, transform, and trust")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.PATH)); player.queue_free()

func check(value: bool, label: String) -> void:
	total += 1
	if not value: failures += 1; push_error("FAIL: " + label)
