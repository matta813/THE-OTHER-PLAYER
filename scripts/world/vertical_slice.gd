extends Node3D

@onready var player: FirstPersonController = $Player
@onready var prompt: Label = $UI/Prompt
@onready var message: Label = $UI/TerminalPanel/TerminalText
@onready var terminal_panel: Panel = $UI/TerminalPanel
@onready var debug: Label = $UI/DebugPanel/Scroll/Debug
var terminal_visits := 0; var room_b_entered := false; var delayed_logged := false; var corridor_entered := false; var typing_tween: Tween

func _ready() -> void:
	player.focus_changed.connect(func(text: String) -> void: prompt.text = text)
	$Terminal.terminal_used.connect(_terminal); $PowerSwitch.power_changed.connect(_power); GameRuntime.behaviour.event_recorded.connect(_event); GameRuntime.other_player.action_due.connect(_other_action)
	terminal_panel.visible = false; $UI/DebugPanel.visible = false; $RoomLight.visible = false
	$Terminal.history.clear(); $Terminal.append_line("FACILITY LINK // NODE 02"); $Terminal.append_line("STATUS: SEARCHING FOR PEER...")

func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0; GameRuntime.predictions.expire(now)
	if not corridor_entered and player.global_position.z < -2.8:
		corridor_entered = true; GameRuntime.behaviour.record(&"room_entered", player.global_position, &"service_corridor")
	if not room_b_entered and player.global_position.z < -7.0:
		room_b_entered = true; GameRuntime.behaviour.record(&"room_entered", player.global_position, &"room_b"); _begin_power_request()
	if GameRuntime.story_stage == 3 and not delayed_logged and $PowerSwitch.get_meta("requested_at", now) + 18.0 < now:
		delayed_logged = true; GameRuntime.behaviour.record(&"instruction_delayed", player.global_position, &"east_power", &"power_request", 18.0)
	if Input.is_action_just_pressed("toggle_debug"): $UI/DebugPanel.visible = not $UI/DebugPanel.visible
	if Input.is_action_just_pressed("quick_save"): _status("STATE RECORDED" if SaveSystem.save_game(player) else "SAVE FAILED")
	if Input.is_action_just_pressed("quick_load"): _status("STATE RESTORED" if SaveSystem.load_game(player) else "NO VALID SAVE"); _restore_visual_state()
	if $UI/DebugPanel.visible: _update_debug(now)

func _terminal() -> void:
	terminal_visits += 1
	if terminal_visits > 1: GameRuntime.behaviour.record(&"returned_to_terminal", player.global_position, &"terminal_a")
	_show_terminal($Terminal.text)
	if GameRuntime.story_stage == 0:
		GameRuntime.story_stage = 1; $Terminal.append_line("PEER FOUND // HANDSHAKE ACCEPTED"); $Terminal.append_line("02: you there?"); _show_terminal($Terminal.text)
		GameRuntime.other_player.schedule(&"unlock", &"door_a", 0.55, {"task": "Tracing door control", "message": "give me a sec"})
		GameRuntime.predictions.issue(&"interact", &"door_a", 0.42, 35.0, Time.get_ticks_msec() / 1000.0)

func _other_action(action: StringName, target: StringName, payload: Dictionary) -> void:
	if action == &"light_on" and target == &"room_b_light":
		$RoomLight.visible = true; $RoomLight.light_energy = 2.8; GameRuntime.other_player.memory.anticipated_light = true; return
	var receiver := GameRuntime.get_facility(target)
	if receiver and receiver.has_method("remote_action") and receiver.remote_action(action, payload):
		if action == &"unlock":
			GameRuntime.story_stage = 2; GameRuntime.trust.reliable_help(); GameRuntime.other_player.memory.help_count = int(GameRuntime.other_player.memory.help_count) + 1; $Terminal.append_line("02: try it now"); _show_terminal($Terminal.text); $DoorIndicator.light_color = Color(0.2, 1.0, 0.45)

func _begin_power_request() -> void:
	if GameRuntime.story_stage != 2: return
	GameRuntime.story_stage = 3; var now := Time.get_ticks_msec() / 1000.0; $PowerSwitch.set_meta("requested_at", now); $Terminal.append_line("02: need power over here"); _status("LINK 02 // need power over here")
	var cooperation: float = GameRuntime.behaviour.model.metrics[&"cooperation"]; GameRuntime.predictions.issue(&"interact", &"east_power", 0.32 + cooperation * 0.28, 75.0, now)
	# A quiet cooperative anticipation: after repeated door checks, light Room B just before the switch.
	if GameRuntime.behaviour.count(&"interaction_retried", &"door_a") >= 2: GameRuntime.other_player.schedule(&"light_on", &"room_b_light", 0.15, {"task": "Anticipating route"})

func _power(on: bool) -> void:
	if not on: return
	$RoomLight.visible = true; $RoomLight.light_energy = 3.8; GameRuntime.story_stage = 4; GameRuntime.trust.reliable_help(); GameRuntime.other_player.memory.last_player_response = Time.get_ticks_msec() / 1000.0 - float($PowerSwitch.get_meta("requested_at")); $Terminal.append_line("02: got it. thanks"); _status("LINK 02 // got it. thanks"); $MachineryIndicator.visible = true

func _event(event: BehaviourEvent) -> void:
	if event.event_type == &"interaction_retried" and event.target_id == &"door_a" and GameRuntime.behaviour.count(&"interaction_retried", &"door_a") > 1: GameRuntime.behaviour.record(&"door_rechecked", event.world_position, event.target_id)
	GameRuntime.predictions.observe(event.event_type, event.target_id, Time.get_ticks_msec() / 1000.0)

func _show_terminal(text: String) -> void:
	terminal_panel.visible = true; message.text = text; message.visible_ratio = 0.0
	if typing_tween: typing_tween.kill()
	typing_tween = create_tween(); typing_tween.tween_property(message, "visible_ratio", 1.0, clampf(text.length() * 0.012, 0.3, 2.5)); typing_tween.tween_interval(3.0); typing_tween.tween_callback(func() -> void: terminal_panel.visible = false)
func _status(text: String) -> void: $UI/Status.text = text; $UI/StatusTimer.start()
func _on_status_timer_timeout() -> void: $UI/Status.text = ""
func _restore_visual_state() -> void:
	$RoomLight.visible = $PowerSwitch.powered or bool(GameRuntime.other_player.memory.get("anticipated_light", false)); $MachineryIndicator.visible = $PowerSwitch.powered; room_b_entered = GameRuntime.story_stage >= 3; corridor_entered = GameRuntime.story_stage >= 2

func _update_debug(now: float) -> void:
	var prediction: Dictionary = GameRuntime.predictions.current; var lines := ["OTHER PLAYER", " task: %s" % GameRuntime.other_player.current_task, " scheduled: %d" % GameRuntime.other_player.scheduled.size(), " confidence: %.2f" % GameRuntime.trust.other_player_confidence_in_player, " player trust: %.2f" % GameRuntime.trust.player_trust_in_other_player, "", "PLAYER MODEL"]
	for name in [&"curiosity", &"hesitation", &"cooperation", &"predictability", &"routine_strength"]: lines.append(" %s %.2f  c%.2f  n%d\n  %s" % [name, GameRuntime.behaviour.model.metrics[name], GameRuntime.behaviour.model.confidence[name], GameRuntime.behaviour.model.samples[name], GameRuntime.behaviour.model.last_reason[name]])
	lines.append_array(["", "PREDICTION", " %s -> %s  %.2f  expires %.1fs" % [prediction.get("type", "none"), prediction.get("target", "-"), prediction.get("confidence", 0.0), maxf(float(prediction.get("expiry", now)) - now, 0.0)], " accuracy %.2f (%d)" % [GameRuntime.predictions.accuracy(), GameRuntime.predictions.evaluated], "", "EVENTS"])
	for event in GameRuntime.behaviour.recent(10): lines.append(" %s :: %s" % [event.event_type, event.target_id])
	lines.append_array(["", "DIRECTOR", " phase: %d  active: vertical_slice" % GameRuntime.story_stage]); debug.text = "\n".join(lines)
