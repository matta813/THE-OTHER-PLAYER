extends Node

var failures := 0
var total := 0

func _ready() -> void:
	test_behaviour_smoothing(); test_event_round_trip(); test_trust_bounds(); test_prediction_evaluation(); test_prediction_expiry(); test_scheduler_timing(); test_save_schema(); test_save_load_round_trip()
	test_habit_evidence(); test_habit_detector(); test_expectations(); test_suspicion(); test_context_prediction(); test_action_scoring(); test_adaptive_save_and_profile(); test_due_action_order()
	print("TESTS: %d passed, %d failed" % [total - failures, failures]); get_tree().quit(failures)

func test_behaviour_smoothing() -> void:
	var model := BehaviourModel.new(); var initial: float = model.metrics[&"cooperation"]
	model.apply(BehaviourEvent.new(&"instruction_completed", Vector3.ZERO, &"switch", &"", 4.0))
	check(model.metrics[&"cooperation"] > initial and model.metrics[&"cooperation"] < 0.65, "single action updates without labelling aggressively")
	check(model.samples[&"cooperation"] == 1 and model.confidence[&"cooperation"] > 0.0, "model tracks samples and confidence")
	var first_delta: float = model.metrics[&"cooperation"] - initial; var before: float = model.metrics[&"cooperation"]
	model.apply(BehaviourEvent.new(&"instruction_completed", Vector3.ZERO, &"switch", &"", 4.0))
	check(model.metrics[&"cooperation"] - before < first_delta, "repeated evidence is smoothed")
	var confidence_before: float = model.confidence[&"cooperation"]
	model.observe(&"cooperation", 0.15, 0.2, "contradictory test evidence")
	check(model.confidence[&"cooperation"] < confidence_before and model.metrics[&"cooperation"] > 0.4, "contradiction lowers confidence without instantly relabelling player")

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
	prediction.issue(&"interact", &"east_power", 0.4, 20.0, 20.0)
	check(not prediction.observe(&"unrelated_interaction", &"diagnostic_panel", 21.0) and prediction.current.result == "incorrect" and prediction.current.actual_target == "diagnostic_panel", "contradictory player action resolves prediction")

func test_scheduler_timing() -> void:
	var agent := OtherPlayerAgent.new(); add_child(agent); var first := agent.schedule(&"unlock", &"door", 0.2, {}); agent.scheduled.clear(); var second := agent.schedule(&"unlock", &"door", 0.8, {})
	check(first > 0.7 and second > first, "complex tasks receive longer contextual delay"); agent.queue_free()

func test_due_action_order() -> void:
	var agent := OtherPlayerAgent.new(); add_child(agent)
	var seen: Array[String] = []
	agent.action_due.connect(func(action: StringName, _target: StringName, _payload: Dictionary) -> void: seen.append(String(action)))
	agent.schedule(&"expectation_timeout", &"terminal_a", 0.1)
	agent.schedule(&"terminal_ack", &"terminal_a", 0.2)
	agent.scheduled[0].due = agent.now() - 2.0
	agent.scheduled[1].due = agent.now() - 1.0
	agent._process(0.0)
	check(seen == ["expectation_timeout", "terminal_ack"] and agent.scheduled.is_empty(), "same-frame remote actions preserve due-time order")
	agent.queue_free()

func test_save_schema() -> void:
	var player := Node3D.new(); add_child(player); player.position = Vector3(2, 3, 4); var data := SaveSystem.build_data(player); var decoded = JSON.parse_string(JSON.stringify(data))
	check(data.version == SaveSystem.VERSION and decoded.predictions is Dictionary and decoded.other_player is Dictionary and decoded.adaptive is Dictionary, "save v3 contains adaptive state"); player.queue_free()

func test_save_load_round_trip() -> void:
	var player := Node3D.new(); add_child(player); player.position = Vector3(4, 1, -8); GameRuntime.story_stage = 3; GameRuntime.trust.player_trust_in_other_player = 0.61
	check(SaveSystem.save_game(player), "save writes versioned JSON"); player.position = Vector3.ZERO; GameRuntime.story_stage = 0; GameRuntime.trust.player_trust_in_other_player = 0.0
	check(SaveSystem.load_game(player) and player.position == Vector3(4, 1, -8) and GameRuntime.story_stage == 3 and is_equal_approx(GameRuntime.trust.player_trust_in_other_player, 0.61), "save/load restores progression, transform, and trust")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.PATH)); player.queue_free()

func test_habit_evidence() -> void:
	var memory := BehaviourMemory.new()
	var first := memory.observe(&"DOOR_RECHECK", &"", true, 100.0)
	var initial_confidence := float(first.confidence)
	check(initial_confidence < 0.4, "one observation does not establish a habit")
	memory.observe(&"DOOR_RECHECK", &"", true, 101.0)
	var repeated := memory.confidence_for(&"DOOR_RECHECK", &"", 101.0)
	check(repeated > initial_confidence, "repeated evidence strengthens habit confidence")
	memory.observe(&"DOOR_RECHECK", &"", false, 102.0)
	check(memory.confidence_for(&"DOOR_RECHECK", &"", 102.0) < repeated and int(memory.get_entry(&"DOOR_RECHECK").contradiction_count) == 1, "contradictory evidence reduces confidence without erasing history")
	check(memory.confidence_for(&"DOOR_RECHECK", &"", 102.0 + BehaviourMemory.HALF_LIFE_SECONDS) < memory.confidence_for(&"DOOR_RECHECK", &"", 102.0), "old evidence decays")

func test_habit_detector() -> void:
	var memory := BehaviourMemory.new(); var detector := HabitDetector.new(memory)
	detector.observe(BehaviourEvent.new(&"door_rechecked", Vector3.ZERO, &"door_a"))
	check(memory.get_entry(&"DOOR_RECHECK").observation_count == 1, "telemetry reaches reusable habit rule")
	detector.observe(BehaviourEvent.new(&"instruction_completed", Vector3.ZERO, &"east_power", &"power_request", 4.0))
	detector.observe(BehaviourEvent.new(&"instruction_completed", Vector3.ZERO, &"east_power", &"power_request", 35.0))
	check(memory.get_entry(&"FAST_COOPERATOR").contradiction_count == 1 and memory.get_entry(&"SLOW_COOPERATOR").support_count == 1, "response timing supports and contradicts habits")

func test_expectations() -> void:
	var expectation := ExpectationModel.new()
	expectation.observe(&"partner_reply", true, 10.0)
	var first := expectation.confidence_for(&"partner_reply")
	expectation.observe(&"partner_reply", true, 11.0)
	check(expectation.confidence_for(&"partner_reply") > first, "reliable replies form an expectation")
	expectation.observe(&"partner_reply", false, 12.0)
	check(expectation.confidence_for(&"partner_reply") < 0.6322 and expectation.entries.partner_reply.violated == 1, "unmet reply weakens expectation")

func test_suspicion() -> void:
	var suspicion := SuspicionModel.new(); var initial := suspicion.value
	suspicion.change(0.09, "unexpected silence", 10.0)
	check(suspicion.value > initial and suspicion.causes.size() == 1, "suspicion records reasoned increase")
	suspicion.reassure(11.0)
	check(is_equal_approx(suspicion.value, initial), "reliable help reduces estimated suspicion")

func test_context_prediction() -> void:
	var memory := BehaviourMemory.new(); var prediction := PredictionSystem.new()
	for i in 3: memory.observe(&"DOOR_RECHECK", &"", true, 100.0 + i)
	var item := prediction.issue_for_context(&"door_unlocked", memory, 103.0)
	check(item.source == "DOOR_RECHECK" and item.confidence < 0.85 and item.expected_time_window == 40.0, "habit drives bounded contextual prediction")

func test_action_scoring() -> void:
	var director := AdaptiveEventDirector.new(); var memory := BehaviourMemory.new(); var expectation := ExpectationModel.new()
	for i in 3: memory.observe(&"DOOR_RECHECK", &"", true, 100.0 + i)
	var state := {"stage": 2, "trust": 0.3, "suspicion": 0.05, "habits": memory, "expectations": expectation, "prediction_confidence": 0.55, "cooperation": 0.5, "world_time": 103.0}
	var choice := director.choose(&"corridor", SliceEventOptions.corridor(), state, 103.0)
	check(choice.get("id") == "EARLY_LIGHT_ASSIST" and director.last_decision.alternatives.size() > 0, "confirmed habit wins scored manipulation and logs alternative")
	var second := director.choose(&"corridor", SliceEventOptions.corridor(), state, 105.0)
	check(second.get("id", "") != "EARLY_LIGHT_ASSIST", "category cooldown prevents immediate manipulation repeat")
	state.suspicion = 0.5
	var restrained := AdaptiveEventDirector.new().choose(&"corridor", SliceEventOptions.corridor(), state, 200.0)
	check(restrained.get("id") == "HOLD_LIGHT", "high suspicion suppresses manipulation")

func test_adaptive_save_and_profile() -> void:
	GameRuntime.habits.observe(&"TERMINAL_RETURN", &"", true, Time.get_unix_time_from_system())
	GameRuntime.expectations.observe(&"remote_help", true, 100.0)
	GameRuntime.suspicion.change(0.1, "test", 101.0)
	var player := Node3D.new(); add_child(player)
	var encoded := JSON.parse_string(JSON.stringify(SaveSystem.build_data(player))) as Dictionary
	GameRuntime.habits.entries.clear(); GameRuntime.expectations.entries.clear(); GameRuntime.suspicion.value = 0.0
	check(SaveSystem.apply_data(player, encoded) and GameRuntime.habits.get_entry(&"TERMINAL_RETURN").observation_count == 1 and GameRuntime.expectations.confidence_for(&"remote_help") > 0.0 and GameRuntime.suspicion.value > 0.0, "save restores adaptive memory, expectation, and suspicion")
	var profile := BehaviourProfile.export_data(GameRuntime.behaviour.model, GameRuntime.habits, GameRuntime.predictions, GameRuntime.trust)
	var imported := BehaviourProfile.import_data(JSON.parse_string(JSON.stringify(profile)))
	check(imported.has("memory") and (imported.memory as BehaviourMemory).get_entry(&"TERMINAL_RETURN").observation_count == 1, "versioned behaviour profile exports and imports")
	var old := encoded.duplicate(true); old.version = 2; old.erase("adaptive")
	check(SaveSystem.migrate(old).version == SaveSystem.VERSION and SaveSystem.apply_data(player, old), "version 2 saves migrate without adaptive data")
	player.queue_free()

func check(value: bool, label: String) -> void:
	total += 1
	if not value: failures += 1; push_error("FAIL: " + label)
