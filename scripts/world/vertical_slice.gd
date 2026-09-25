extends Node3D

@onready var player: FirstPersonController = $Player
@onready var prompt: Label = $UI/Prompt
@onready var message: Label = $UI/TerminalPanel/TerminalText
@onready var terminal_panel: Panel = $UI/TerminalPanel
@onready var typewriter: TerminalTypewriter = $UI/TerminalTypewriter
@onready var debug: Label = $UI/DebugPanel/Scroll/Debug

var terminal_visits := 0
var terminal_left_since_last_use := false
var last_door_attempt_time := -100000.0
var room_b_entered := false
var corridor_entered := false
var corridor_decision_made := false
var delayed_logged := false
var awaiting_ack := false
var interim_message_sent := false
var optional_exploration_logged := false
var threshold_since := -1.0
var threshold_logged := false
var request_last_position := Vector3.ZERO
var stationary_seconds := 0.0
var wait_logged := false
var subtitles: SubtitlePresenter

func _ready() -> void:
	player.focus_changed.connect(func(value: String) -> void: prompt.text = value)
	GameSettings.changed.connect(_apply_settings)
	_apply_settings()
	subtitles = SubtitlePresenter.new(); add_child(subtitles)
	$Terminal.terminal_used.connect(_terminal)
	$PowerSwitch.power_changed.connect(_power)
	GameRuntime.behaviour.event_recorded.connect(_event)
	GameRuntime.other_player.action_due.connect(_other_action)
	typewriter.configure(terminal_panel, message)
	terminal_panel.visible = false
	$UI/DebugPanel.visible = false
	$RoomLight.visible = false
	$Terminal.history.clear()
	$Terminal.append_line("FACILITY LINK // NODE 02")
	$Terminal.append_line("STATUS: SEARCHING FOR PEER...")
	if not GameFlow.pending_save.is_empty():
		if SaveSystem.load_from(GameFlow.pending_save, player): _restore_visual_state()
		else: _status("SAVE COULD NOT BE LOADED")
		GameFlow.pending_save = ""

func _apply_settings() -> void:
	GameSettings.apply_environment($Environment.environment)
	player.camera.fov = float(GameSettings.get_value("fov"))
	prompt.add_theme_color_override("font_color", Color(1, 1, 0.86) if GameSettings.get_value("high_contrast_prompt") else Color(0.76, 0.82, 0.78, 0.9))
	for light in find_children("*", "Light3D", true, false):
		if not light.has_meta("authored_shadow"): light.set_meta("authored_shadow", light.shadow_enabled)
		light.shadow_enabled = bool(light.get_meta("authored_shadow")) and bool(GameSettings.get_value("shadows"))
	$VentilationHum.bus = "Ambience"
	$DistantMachinery.bus = "Ambience"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		var pause_layer := CanvasLayer.new(); pause_layer.name = "PauseLayer"; pause_layer.layer = 20; pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS; add_child(pause_layer)
		var pause_ui := MenuUI.new(); pause_ui.game_root = self; pause_layer.add_child(pause_ui)
		pause_ui.tree_exited.connect(func() -> void: pause_layer.queue_free())
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().paused = true

func _process(delta: float) -> void:
	GameRuntime.playtime += delta
	var clock := GameRuntime.playtime
	var world_time := Time.get_unix_time_from_system()
	GameRuntime.predictions.expire(world_time)
	if terminal_visits > 0 and player.global_position.distance_to($Terminal.global_position) > 3.0:
		terminal_left_since_last_use = true
	if not corridor_entered and player.global_position.z < -2.8:
		corridor_entered = true
		GameRuntime.behaviour.record(&"room_entered", player.global_position, &"service_corridor")
		_choose_corridor_action(world_time)
	if not room_b_entered and player.global_position.z < -7.0:
		room_b_entered = true
		GameRuntime.behaviour.record(&"room_entered", player.global_position, &"room_b")
		_begin_power_request()
	if GameRuntime.story_stage == 3 and not delayed_logged and float($PowerSwitch.get_meta("requested_at", clock)) + 18.0 < clock:
		delayed_logged = true
		GameRuntime.behaviour.record(&"instruction_delayed", player.global_position, &"east_power", &"power_request", 18.0)
	if GameRuntime.story_stage == 3 and not wait_logged:
		stationary_seconds = stationary_seconds + delta if player.global_position.distance_to(request_last_position) < 0.025 else 0.0
		request_last_position = player.global_position
		if stationary_seconds > 10.0:
			wait_logged = true
			GameRuntime.behaviour.record(&"waited_for_partner", player.global_position, &"east_power", &"power_request", stationary_seconds)
	if GameRuntime.story_stage == 2 and not room_b_entered and player.global_position.z < -6.0 and player.global_position.z > -7.0:
		if threshold_since < 0.0: threshold_since = clock
		if not threshold_logged and clock - threshold_since > 4.0:
			threshold_logged = true
			GameRuntime.behaviour.record(&"hesitated_at_threshold", player.global_position, &"room_b")
	else: threshold_since = -1.0
	if OS.is_debug_build() and Input.is_action_just_pressed("toggle_debug"): $UI/DebugPanel.visible = not $UI/DebugPanel.visible
	if Input.is_action_just_pressed("quick_save"): _status("STATE RECORDED" if SaveSystem.save_game(player) else "SAVE FAILED")
	if Input.is_action_just_pressed("quick_load"):
		var restored := SaveSystem.load_game(player)
		_status("STATE RESTORED" if restored else "NO VALID SAVE")
		if restored: _restore_visual_state()
	if $UI/DebugPanel.visible: _update_debug(world_time)

func _terminal() -> void:
	if terminal_visits > 0 and terminal_left_since_last_use:
		GameRuntime.behaviour.record(&"returned_to_terminal", player.global_position, &"terminal_a")
	terminal_left_since_last_use = false
	terminal_visits += 1
	_show_terminal($Terminal.text)
	if GameRuntime.story_stage == 0:
		GameRuntime.story_stage = 1
		$Terminal.append_line("PEER FOUND // HANDSHAKE ACCEPTED")
		$Terminal.append_line("02: you there?")
		GameRuntime.expectations.observe(&"partner_reply", true, Time.get_unix_time_from_system())
		_show_terminal($Terminal.text, "02: you there?")
		GameRuntime.other_player.schedule(&"unlock", &"door_a", 0.55, {"task": "Tracing door control"})
	elif awaiting_ack and GameRuntime.trust_strategy.should_reassure(GameRuntime.suspicion, Time.get_unix_time_from_system()):
		var reassurance := GameRuntime.director.choose(&"reassurance", SliceEventOptions.reassurance(), GameRuntime.adaptive_state(), Time.get_unix_time_from_system())
		if reassurance.get("id", "") == "REASSURE_NOW":
			GameRuntime.other_player.cancel_action(&"terminal_ack", &"terminal_a")
			GameRuntime.other_player.schedule(&"terminal_ack", &"terminal_a", 0.1, {"task": "Checking circuit status", "message": "sorry. panel lagged. got it", "reassurance": true})

func _other_action(action: StringName, target: StringName, payload: Dictionary) -> void:
	if action == &"light_on" and target == &"room_b_light":
		if $PowerSwitch.powered: return
		$RoomLight.visible = true
		$RoomLight.light_energy = 4.0
		$FacilityDetails.set_east_power(true)
		GameRuntime.other_player.memory.anticipated_light = true
		GameRuntime.trust_strategy.record_help(GameRuntime.trust, GameRuntime.suspicion, GameRuntime.expectations, Time.get_unix_time_from_system(), false)
		return
	if action == &"terminal_ack" and target == &"terminal_a":
		awaiting_ack = false
		var line := "02: " + String(payload.get("message", "got it. thanks"))
		$Terminal.append_line(line)
		_show_terminal($Terminal.text, line)
		_status("LINK 02 // " + String(payload.get("message", "got it. thanks")))
		GameRuntime.expectations.observe(&"partner_reply", true, Time.get_unix_time_from_system())
		if bool(payload.get("reassurance", false)):
			GameRuntime.trust_strategy.record_reassurance(Time.get_unix_time_from_system(), GameRuntime.suspicion)
		return
	if action == &"expectation_timeout" and target == &"terminal_a":
		if awaiting_ack:
			GameRuntime.expectations.observe(&"partner_reply", false, Time.get_unix_time_from_system())
			GameRuntime.behaviour.record(&"expectation_violated", player.global_position, &"terminal_a", &"power_ack")
		return
	if action == &"display_text" and target == &"terminal_a":
		var short_line := String(payload.get("text", ""))
		$Terminal.append_line(short_line)
		_show_terminal($Terminal.text, short_line)
		return
	var receiver := GameRuntime.get_facility(target)
	if receiver and receiver.has_method("remote_action") and receiver.remote_action(action, payload):
		if action == &"unlock":
			GameRuntime.story_stage = 2
			GameRuntime.trust_strategy.record_help(GameRuntime.trust, GameRuntime.suspicion, GameRuntime.expectations, Time.get_unix_time_from_system())
			GameRuntime.other_player.memory.help_count = int(GameRuntime.other_player.memory.help_count) + 1
			$Terminal.append_line("02: try it now")
			_show_terminal($Terminal.text, "02: try it now")
			$DoorIndicator.light_color = Color(0.2, 1.0, 0.45)
			GameRuntime.predictions.issue_for_context(&"door_unlocked", GameRuntime.habits, Time.get_unix_time_from_system())

func _choose_corridor_action(world_time: float) -> void:
	if corridor_decision_made or GameRuntime.story_stage < 2: return
	corridor_decision_made = true
	var choice := GameRuntime.director.choose(&"corridor", SliceEventOptions.corridor(), GameRuntime.adaptive_state(), world_time)
	if choice.get("id", "") == "EARLY_LIGHT_ASSIST":
		GameRuntime.other_player.schedule(&"light_on", &"room_b_light", 0.2, {"task": "Checking the next circuit", "delay_bias": -0.25})

func _begin_power_request() -> void:
	if GameRuntime.story_stage != 2: return
	GameRuntime.story_stage = 3
	$PowerSwitch.set_meta("requested_at", GameRuntime.playtime)
	request_last_position = player.global_position
	stationary_seconds = 0.0
	$Terminal.append_line("02: need power over here")
	_status("LINK 02 // need power over here")
	GameRuntime.predictions.issue_for_context(&"power_request", GameRuntime.habits, Time.get_unix_time_from_system())

func _power(on: bool) -> void:
	if not on: return
	GameRuntime.other_player.cancel_action(&"light_on", &"room_b_light")
	$RoomLight.visible = true
	$RoomLight.light_energy = 5.0
	$FacilityDetails.set_east_power(true)
	$MachineryIndicator.visible = true
	GameRuntime.story_stage = 4
	GameRuntime.other_player.memory.last_player_response = GameRuntime.playtime - float($PowerSwitch.get_meta("requested_at"))
	var world_time := Time.get_unix_time_from_system()
	var choice := GameRuntime.director.choose(&"power_restored", SliceEventOptions.power_restored(), GameRuntime.adaptive_state(), world_time)
	awaiting_ack = true
	if choice.get("id", "") == "DELAY_ACK":
		GameRuntime.other_player.schedule(&"expectation_timeout", &"terminal_a", 0.1, {"task": "Checking remote panel", "delay_bias": 2.2})
		GameRuntime.other_player.schedule(&"terminal_ack", &"terminal_a", 0.25, {"task": "Checking remote panel", "delay_bias": 5.0, "message": "sorry, panel lagged. got it"})
	elif choice.get("id", "") == "REASSURE_ACK":
		GameRuntime.other_player.schedule(&"terminal_ack", &"terminal_a", 0.1, {"task": "Confirming power", "message": "power's back. thanks", "reassurance": true})
	else:
		GameRuntime.other_player.schedule(&"terminal_ack", &"terminal_a", 0.2, {"task": "Confirming power", "message": "got it. thanks"})

func _event(event: BehaviourEvent) -> void:
	if event.event_type == &"interaction_retried" and event.target_id == &"door_a":
		if GameRuntime.behaviour.count(&"interaction_retried", &"door_a") > 1 and event.timestamp - last_door_attempt_time >= 2.5:
			GameRuntime.behaviour.record(&"door_rechecked", event.world_position, event.target_id)
			if GameRuntime.story_stage == 1 and not interim_message_sent and GameRuntime.other_player.delay_action(&"unlock", &"door_a", 1.5):
				interim_message_sent = true
				GameRuntime.other_player.schedule(&"display_text", &"terminal_a", 0.05, {"task": "Checking door controller", "text": "02: sec"})
		last_door_attempt_time = event.timestamp
	if event.event_type == &"unrelated_interaction" and GameRuntime.story_stage == 3 and not optional_exploration_logged:
		optional_exploration_logged = true
		GameRuntime.behaviour.record(&"optional_area_explored", event.world_position, event.target_id, &"power_request")
	GameRuntime.predictions.observe(event.event_type, event.target_id, Time.get_unix_time_from_system())

func _show_terminal(text: String, newest_line := "") -> void: typewriter.display(text, newest_line)
func _status(text: String) -> void:
	$UI/Status.text = text; $UI/StatusTimer.start()
	if text.begins_with("LINK 02 // ") and subtitles:
		subtitles.show_caption("Link 02", text.trim_prefix("LINK 02 // "), 4.0, 1, true)
func _on_status_timer_timeout() -> void: $UI/Status.text = ""

func _restore_visual_state() -> void:
	$RoomLight.visible = $PowerSwitch.powered or bool(GameRuntime.other_player.memory.get("anticipated_light", false))
	$RoomLight.light_energy = 5.0 if $PowerSwitch.powered else 4.0
	$FacilityDetails.set_east_power($RoomLight.visible)
	$MachineryIndicator.visible = $PowerSwitch.powered
	$DoorIndicator.light_color = Color(0.2, 1.0, 0.45) if not $Door.locked else Color(1.0, 0.16, 0.1)
	room_b_entered = GameRuntime.story_stage >= 3 or player.global_position.z < -7.0
	corridor_entered = GameRuntime.story_stage >= 3 or player.global_position.z < -2.8
	corridor_decision_made = GameRuntime.story_stage >= 3 or GameRuntime.director.last_decision.get("context", "") == "corridor"
	delayed_logged = GameRuntime.behaviour.count(&"instruction_delayed") > 0
	interim_message_sent = GameRuntime.behaviour.count(&"door_rechecked") > 0
	optional_exploration_logged = GameRuntime.behaviour.count(&"optional_area_explored") > 0
	threshold_logged = GameRuntime.behaviour.count(&"hesitated_at_threshold") > 0
	wait_logged = GameRuntime.behaviour.count(&"waited_for_partner") > 0
	request_last_position = player.global_position
	stationary_seconds = 0.0
	terminal_visits = GameRuntime.behaviour.count(&"returned_to_terminal") + (1 if GameRuntime.story_stage > 0 else 0)
	terminal_left_since_last_use = terminal_visits > 0 and player.global_position.distance_to($Terminal.global_position) > 3.0
	last_door_attempt_time = -100000.0
	for event in GameRuntime.behaviour.events:
		if event.event_type == &"interaction_retried" and event.target_id == &"door_a": last_door_attempt_time = event.timestamp
	terminal_panel.visible = false
	typewriter.set_process(false)
	awaiting_ack = false
	for item in GameRuntime.other_player.scheduled:
		if item.get("action", &"") == &"terminal_ack": awaiting_ack = true

func _update_debug(world_time: float) -> void:
	var agent := GameRuntime.other_player
	var prediction: Dictionary = GameRuntime.predictions.current
	var decision: Dictionary = GameRuntime.director.last_decision
	var lines := ["OTHER PLAYER", " task: %s" % agent.current_task, " scheduled: %s" % str(agent.scheduled.map(func(item: Dictionary) -> String: return "%s -> %s" % [item.action, item.target])), " confidence: %.2f" % GameRuntime.trust.other_player_confidence_in_player, " player trust: %.2f" % GameRuntime.trust.player_trust_in_other_player, " help / reassurance: %d / %.0f" % [GameRuntime.trust_strategy.reliable_help_count, GameRuntime.trust_strategy.last_reassurance_time], "", "PLAYER MODEL"]
	for name in [&"curiosity", &"hesitation", &"cooperation", &"predictability", &"routine_strength"]:
		lines.append(" %s %.2f  c%.2f  n%d\n  %s" % [name, GameRuntime.behaviour.model.metrics[name], GameRuntime.behaviour.model.confidence[name], GameRuntime.behaviour.model.samples[name], GameRuntime.behaviour.model.last_reason[name]])
	lines.append_array(["", "HABITS"])
	for entry in GameRuntime.habits.entries.values():
		lines.append(" %s c%.2f n%d s%.2f  %s" % [entry.type, GameRuntime.habits.confidence_for(StringName(entry.type), StringName(entry.target), world_time), entry.observation_count, entry.strength, entry.target])
	lines.append_array(["", "EXPECTATIONS"])
	for entry in GameRuntime.expectations.entries.values(): lines.append(" %s c%.2f n%d" % [entry.type, GameRuntime.expectations.confidence_for(StringName(entry.type)), entry.observation_count])
	lines.append_array(["", "SUSPICION", " %.2f" % GameRuntime.suspicion.value])
	for cause in GameRuntime.suspicion.causes.slice(-3): lines.append(" %s" % str(cause))
	lines.append_array(["", "ACTION SELECTION", " %s %.2f" % [decision.get("selected", "none"), decision.get("score", 0.0)], " %s" % decision.get("reason", "-"), " expected: %s" % decision.get("expected_result", "-")])
	for option in decision.get("alternatives", []): lines.append(" alternative: %s %.2f" % [option.get("id", "-"), option.get("score", 0.0)])
	lines.append_array(["", "MEMORY", " %s" % str(agent.memory), "", "PREDICTION", " %s -> %s  %.2f" % [prediction.get("type", "none"), prediction.get("target", "-"), prediction.get("confidence", 0.0)], " source: %s  %s" % [prediction.get("source", "-"), prediction.get("reason", "-")], " expires %.1fs | accuracy %.2f (%d)" % [maxf(float(prediction.get("expiry", world_time)) - world_time, 0.0), GameRuntime.predictions.accuracy(), GameRuntime.predictions.evaluated], "", "EVENTS"])
	for event in GameRuntime.behaviour.recent(10): lines.append(" %s :: %s" % [event.event_type, event.target_id])
	lines.append_array(["", "DIRECTOR", " phase: %d | unusual count: %d" % [GameRuntime.story_stage, GameRuntime.director.manipulation_count]])
	var chapter: ChapterOneController = $ChapterOne
	var wing: ChapterWingBuilder = $ChapterWing
	lines.append_array(["", "CHAPTER 1", " stage: %s | checkpoint: %d" % [ChapterOneController.Stage.keys()[chapter.stage], chapter.checkpoint_index], " power: %d/%d %s" % [chapter.grid.demand(), ChapterPowerGrid.CAPACITY, str(chapter.grid.circuits)], " reciprocity: given %d / asked %d / delayed %d / reliable %d" % [chapter.reciprocity.help_given, chapter.reciprocity.help_requested, chapter.reciprocity.help_delayed, chapter.reciprocity.reliable_exchanges], " hatch: %s" % TransferHatch.HatchState.keys()[(wing.object(&"transfer_hatch") as TransferHatch).hatch_state], " airlock: %s" % AirlockSystem.Phase.keys()[chapter.airlock.phase], " camera: %d" % (wing.object(&"camera_console") as SecurityCameraConsole).selected_feed, " F6 task teleport / F7 trust reset / F8 advance remote timers"])
	debug.text = "\n".join(lines)
