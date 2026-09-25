class_name ChapterOneController
extends Node

signal chapter_stage_changed(stage: int)
signal chapter_completed

enum Stage {WAITING, CAMERA, TRANSFER, POWER_ROUTE, GENERATOR, COMMS, AIRLOCK, COMPLETE}

@onready var wing: ChapterWingBuilder = $"../ChapterWing"
@onready var player: FirstPersonController = $"../Player"
@onready var arrival_terminal: FacilityTerminal = $"../Terminal"
var dialogue := ChapterDialogueBank.new()
var grid := ChapterPowerGrid.new()
var reciprocity := ReciprocityModel.new()
var airlock: AirlockSystem
var stage := Stage.WAITING
var stage_started_at := 0.0
var checkpoint_index := 0
var spoken: Dictionary = {}
var visited: Dictionary = {}
var viewed_storage := false
var viewed_generator := false
var card_returned := false
var generator_online := false
var generator_pending := false
var hatch_pending := false
var generator_pending_since := 0.0
var hatch_pending_since := 0.0
var chapter_end_visible := false
var restoring := false
var end_layer: CanvasLayer
var end_fade: ColorRect
var end_title: Label
var end_menu: Button

func _ready() -> void:
	GameRuntime.register(&"chapter_one", self)
	var camera := wing.object(&"camera_console") as SecurityCameraConsole
	camera.feed_selected.connect(_on_feed_selected)
	var hatch := wing.object(&"transfer_hatch") as TransferHatch
	hatch.hatch_sealed.connect(_on_hatch_sealed)
	hatch.remote_received.connect(_on_remote_received)
	hatch.item_collected.connect(_on_item_collected)
	for id in [&"ventilation_breaker", &"starter_breaker", &"security_breaker", &"door_breaker"]:
		(wing.object(id) as CircuitBreaker).grid = grid
		(wing.object(id) as CircuitBreaker).load_state({})
	grid.circuit_changed.connect(_on_circuit_changed)
	_apply_power_dependencies()
	_update_power_readout()
	for id in [&"camera_report", &"generator_report", &"generator_starter", &"comms_panel"]:
		(wing.object(id) as FacilityActionPoint).activated.connect(_on_action_point)
	for id in [&"storage_notice", &"security_notice", &"generator_notice"]:
		(wing.object(id) as InspectionProp).inspected_text.connect(_on_notice_read)
	for node in wing.objects.values():
		if node is FacilityTerminal:
			var chapter_terminal := node as FacilityTerminal
			chapter_terminal.terminal_used.connect(func() -> void: _on_chapter_terminal_used(chapter_terminal))
	airlock = AirlockSystem.new(); airlock.name = "AirlockState"; add_child(airlock)
	airlock.configure(wing.object(&"airlock_inner") as ElectronicDoor, wing.object(&"airlock_outer") as ElectronicDoor)
	airlock.phase_changed.connect(_on_airlock_phase)
	airlock.cycle_opened.connect(_on_airlock_opened)
	(wing.object(&"airlock_control") as AirlockControl).airlock = airlock
	(wing.object(&"airlock_control") as AirlockControl).cycle_requested.connect(_on_airlock_requested)
	(wing.object(&"airlock_control") as AirlockControl).available = false
	GameRuntime.other_player.action_due.connect(_on_remote_action)
	stage_started_at = GameRuntime.playtime
	_build_end_overlay()

func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or not get_node("../UI/DebugPanel").visible: return
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_F6: _debug_teleport_to_task()
		KEY_F7:
			GameRuntime.trust.player_trust_in_other_player = 0.75
			GameRuntime.suspicion.value = 0.05
		KEY_F8:
			for item in GameRuntime.other_player.scheduled: item.due = GameRuntime.other_player.now() - 0.01

func _debug_teleport_to_task() -> void:
	var destinations := {Stage.WAITING: Vector3(0, 1, -12.4), Stage.CAMERA: Vector3(3.1, 1, -22.0), Stage.TRANSFER: Vector3(3.2, 1, -43.5), Stage.POWER_ROUTE: Vector3(3.0, 1, -23.3), Stage.GENERATOR: Vector3(-3.0, 1, -34.1), Stage.COMMS: Vector3(0, 1, -47.6), Stage.AIRLOCK: Vector3(0, 1, -51.0)}
	if destinations.has(stage): player.global_position = destinations[stage]

func _build_end_overlay() -> void:
	end_layer = CanvasLayer.new(); end_layer.name = "ChapterEnd"; end_layer.layer = 10; add_child(end_layer)
	end_fade = ColorRect.new(); end_fade.name = "Fade"; end_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); end_fade.color = Color(0.005, 0.009, 0.01, 0.0); end_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE; end_layer.add_child(end_fade)
	end_title = Label.new(); end_title.name = "Title"; end_title.set_anchors_and_offsets_preset(Control.PRESET_CENTER); end_title.text = "CONNECTION ESTABLISHED"; end_title.add_theme_color_override("font_color", Color(0.61, 0.72, 0.67)); end_title.add_theme_font_size_override("font_size", 22); end_title.visible = false; end_layer.add_child(end_title)
	end_menu = Button.new(); end_menu.text = "RETURN TO MAIN MENU"; end_menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM); end_menu.position = Vector2(-115, -120); end_menu.custom_minimum_size = Vector2(230, 42); end_menu.visible = false; end_menu.pressed.connect(GameFlow.main_menu); end_layer.add_child(end_menu)

func _exit_tree() -> void: GameRuntime.unregister(&"chapter_one", self)

func _process(_delta: float) -> void:
	if GameRuntime.story_stage >= 1 and checkpoint_index < 1: _checkpoint(1)
	if GameRuntime.story_stage >= 4 and checkpoint_index < 2: _checkpoint(2)
	if stage == Stage.WAITING and GameRuntime.story_stage >= 4 and player.global_position.z < -14.2:
		_set_stage(Stage.CAMERA)
		_send(&"security_request")
	if stage == Stage.WAITING: return
	_track_rooms()
	if stage == Stage.TRANSFER and hatch_pending and GameRuntime.playtime - hatch_pending_since > 28.0:
		var hatch := wing.object(&"transfer_hatch") as TransferHatch
		if hatch.hatch_state == TransferHatch.HatchState.TRANSIT and not card_returned:
			GameRuntime.other_player.cancel_action(&"chapter_fuse_return", &"transfer_hatch")
			_on_fuse_return()
	if stage == Stage.GENERATOR and generator_pending and GameRuntime.playtime - generator_pending_since > 30.0: _generator_online()
	if stage == Stage.AIRLOCK:
		if player.global_position.z < -53.0 and not visited.has("airlock_entry"):
			visited["airlock_entry"] = true
			_try_anticipatory_airlock()
		if airlock.phase == AirlockSystem.Phase.OPEN and player.global_position.z < -59.5:
			_finish_chapter()

func _track_rooms() -> void:
	var p := player.global_position
	if p.z < -16.0 and p.z > -20.5 and p.x < -2.2: _mark_room(&"storage")
	if p.z < -21.0 and p.z > -26.0 and p.x > 2.2:
		_mark_room(&"security_office")
		if checkpoint_index < 3: _checkpoint(3)
	if p.z < -32.0 and p.z > -39.0 and p.x < -2.2: _mark_room(&"generator_room")
	if p.z < -42.0 and p.z > -47.0 and p.x > 2.2: _mark_room(&"transfer_room")
	if p.z < -40.0 and p.z > -42.0: _mark_room(&"observation_corridor")
	if p.z < -49.0 and p.z > -52.0: _mark_room(&"communications")

func _mark_room(id: StringName) -> void:
	if visited.has(String(id)): return
	visited[String(id)] = true
	GameRuntime.behaviour.record(&"room_entered", player.global_position, id, &"chapter_01")
	if id == &"observation_corridor": _send(&"observation_note")

func _on_feed_selected(feed_id: StringName) -> void:
	GameRuntime.behaviour.record(&"camera_feed_viewed", player.global_position, &"camera_console", feed_id)
	if feed_id == &"STORAGE": viewed_storage = true
	if feed_id == &"GENERATOR": viewed_generator = true

func _on_notice_read(value: String) -> void: get_parent().call("_status", value)

func _on_chapter_terminal_used(terminal: FacilityTerminal) -> void:
	get_parent().call("_show_terminal", terminal.text)
	GameRuntime.behaviour.record(&"terminal_accessed", player.global_position, terminal.stable_id, &"chapter_01")

func _on_action_point(action_id: StringName) -> void:
	match action_id:
		&"report_storage":
			if stage != Stage.CAMERA: return
			if not viewed_storage or not viewed_generator: _send(&"security_hint", false); return
			GameRuntime.behaviour.record(&"camera_guidance_given", player.global_position, &"camera_report", &"storage")
			var response := _stage_elapsed()
			GameRuntime.behaviour.record(&"instruction_completed", player.global_position, &"camera_report", &"security_request", response)
			reciprocity.player_helped(response, GameRuntime.trust)
			_send(&"security_fast" if GameRuntime.habits.confidence_for(&"FAST_COOPERATOR") > 0.4 else &"security_normal")
			_set_stage(Stage.TRANSFER)
			reciprocity.request_help()
			_send(&"fuse_request")
		&"report_generator":
			if stage != Stage.CAMERA: return
			GameRuntime.behaviour.record(&"camera_report_incorrect", player.global_position, &"generator_report", &"security_request")
			_send(&"security_wrong", false)
		&"start_generator":
			if stage != Stage.GENERATOR or generator_pending: return
			if player.carried_item_id != &"access_card": _send(&"generator_card", false); return
			if not grid.is_powered(&"generator_starter"): _send(&"power_hint", false); return
			generator_pending = true
			generator_pending_since = GameRuntime.playtime
			GameRuntime.behaviour.record(&"generator_started", player.global_position, &"generator_starter", &"local")
			GameRuntime.other_player.schedule(&"chapter_generator_sync", &"generator_starter", 1.0, {"task": "Holding remote contactor", "delay_bias": 2.0})
			_send(&"generator_wait")
		&"test_link":
			if stage != Stage.COMMS: return
			GameRuntime.behaviour.record(&"link_tested", player.global_position, &"comms_panel", &"chapter_01")
			reciprocity.player_helped(_stage_elapsed(), GameRuntime.trust)
			_set_stage(Stage.AIRLOCK)
			_apply_power_dependencies()
			_send(&"airlock_normal" if grid.is_powered(&"door_controls") else &"airlock_power")

func _on_hatch_sealed(item_id: StringName) -> void:
	if stage != Stage.TRANSFER or item_id != &"fuse_35a": return
	hatch_pending = true
	hatch_pending_since = GameRuntime.playtime
	GameRuntime.other_player.schedule(&"chapter_fuse_receive", &"transfer_hatch", 0.9, {"task": "Receiving fuse", "delay_bias": 1.2})

func _on_remote_received(item_id: StringName) -> void:
	if item_id != &"fuse_35a": return
	reciprocity.player_helped(_stage_elapsed(), GameRuntime.trust)
	_send(&"fuse_received")
	var choice := GameRuntime.director.choose(&"hatch_return", ChapterEventOptions.hatch_return(), GameRuntime.adaptive_state(), Time.get_unix_time_from_system())
	var eager: bool = choice.get("id", "") == "PREPARE_CARD_EARLY"
	GameRuntime.other_player.schedule(&"chapter_fuse_return", &"transfer_hatch", 0.6, {"task": "Sending spare card", "delay_bias": -0.3 if eager else 1.4})
	if eager: GameRuntime.behaviour.record(&"anticipated_transfer", player.global_position, &"transfer_hatch", &"fast_cooperator")

func _on_fuse_return() -> void:
	var hatch := wing.object(&"transfer_hatch") as TransferHatch
	if hatch.hatch_state != TransferHatch.HatchState.TRANSIT: return
	if not hatch.remote_action(&"return_item", {"item_id": "access_card"}): return
	card_returned = true
	hatch_pending = false
	hatch_pending_since = 0.0
	reciprocity.partner_helped(GameRuntime.trust)
	_set_stage(Stage.POWER_ROUTE)
	_send(&"fuse_returned")
	_send(&"power_request")
	reciprocity.request_help()

func _on_item_collected(item_id: StringName) -> void:
	if item_id == &"access_card": GameRuntime.behaviour.record(&"keycard_recovered", player.global_position, &"transfer_hatch")

func _on_circuit_changed(_circuit: StringName, _enabled: bool) -> void:
	_update_power_readout()
	_apply_power_dependencies()
	if restoring: return
	for id in [&"ventilation_breaker", &"starter_breaker", &"security_breaker", &"door_breaker"]:
		var breaker := wing.object(id) as CircuitBreaker
		if breaker: breaker.load_state({})
	if stage == Stage.POWER_ROUTE and grid.is_powered(&"generator_starter"):
		var response := _stage_elapsed()
		_set_stage(Stage.GENERATOR)
		reciprocity.player_helped(response, GameRuntime.trust)
		_send(&"power_ready")
		_send(&"generator_request")

func _update_power_readout() -> void:
	if wing.power_readout: wing.power_readout.text = "LOAD %d / %d" % [grid.demand(), ChapterPowerGrid.CAPACITY]

func _apply_power_dependencies() -> void:
	(wing.object(&"camera_console") as SecurityCameraConsole).set_powered(grid.is_powered(&"security"))
	wing.set_zone_power("security", grid.is_powered(&"security"))
	wing.set_zone_power("maintenance", grid.is_powered(&"ventilation"))
	wing.set_zone_power("observation", grid.is_powered(&"ventilation"))
	for id in [&"airlock_inner", &"airlock_outer"]:
		(wing.object(id) as ElectronicDoor).remote_action(&"power_on" if grid.is_powered(&"door_controls") else &"power_off")
	var control := wing.object(&"airlock_control") as AirlockControl
	if control:
		control.available = stage >= Stage.AIRLOCK and grid.is_powered(&"door_controls")
		control.unavailable_reason = "AIRLOCK // NO DOOR POWER" if stage >= Stage.AIRLOCK else "AIRLOCK // GENERATOR OFFLINE"
		control.state_changed.emit()
	if stage >= Stage.AIRLOCK and grid.is_powered(&"door_controls"):
		(wing.object(&"airlock_inner") as ElectronicDoor).remote_action(&"unlock")

func _on_remote_action(action: StringName, target: StringName, _payload: Dictionary) -> void:
	if target == &"transfer_hatch" and action == &"chapter_fuse_receive":
		(wing.object(&"transfer_hatch") as TransferHatch).remote_action(&"receive")
	elif target == &"transfer_hatch" and action == &"chapter_fuse_return": _on_fuse_return()
	elif target == &"generator_starter" and action == &"chapter_generator_sync": _generator_online()
	elif target == &"airlock_control" and action == &"chapter_airlock_explain": _send(&"airlock_explain")

func _generator_online() -> void:
	if stage != Stage.GENERATOR or not generator_pending: return
	generator_pending = false; generator_pending_since = 0.0; generator_online = true
	var generator_hum: AudioStreamPlayer3D = wing.audio_zones.get("generator")
	if generator_hum and not generator_hum.playing and DisplayServer.get_name() != "headless": generator_hum.play()
	_set_stage(Stage.COMMS)
	reciprocity.partner_helped(GameRuntime.trust)
	_send(&"generator_online")
	_send(&"comms_request")
	_checkpoint(4)

func _try_anticipatory_airlock() -> void:
	if airlock.phase != AirlockSystem.Phase.IDLE or not grid.is_powered(&"door_controls"): return
	var cooperation_value := float(GameRuntime.behaviour.model.metrics.get(&"cooperation", 0.5))
	var cooperation_confidence := float(GameRuntime.behaviour.model.confidence.get(&"cooperation", 0.0))
	var habit := GameRuntime.habits.confidence_for(&"FAST_COOPERATOR")
	var contextual_confidence := clampf(0.34 + cooperation_value * 0.2 + cooperation_confidence * 0.22 + habit * 0.18, 0.25, 0.75)
	GameRuntime.predictions.issue(&"interact", &"airlock_control", contextual_confidence, 18.0, Time.get_unix_time_from_system(), "airlock_approach", "Player inside enabled airlock with prior reciprocal cooperation")
	var choice := GameRuntime.director.choose(&"airlock_approach", ChapterEventOptions.airlock_approach(), GameRuntime.adaptive_state(), Time.get_unix_time_from_system())
	if choice.get("id", "") != "ANTICIPATE_AIRLOCK": return
	_send(&"airlock_wait")
	if airlock.request(true):
		GameRuntime.predictions.preempt(Time.get_unix_time_from_system())
		GameRuntime.behaviour.record(&"airlock_anticipated", player.global_position, &"airlock_control", &"chapter_01")
		GameRuntime.other_player.schedule(&"chapter_airlock_explain", &"airlock_control", 0.25, {"task": "Monitoring airlock cycle", "delay_bias": 1.0})
		_checkpoint(5)

func _on_airlock_requested() -> void:
	if stage != Stage.AIRLOCK: return
	GameRuntime.behaviour.record(&"airlock_requested", player.global_position, &"airlock_control")
	_send(&"airlock_normal")
	_checkpoint(5)

func _on_airlock_phase(next: int) -> void:
	wing.play_airlock_phase(next)
	var light: OmniLight3D = wing.lights.get("airlock")
	if light: light.light_color = Color(0.9, 0.46, 0.22) if next in [AirlockSystem.Phase.SEALING, AirlockSystem.Phase.PRESSURIZING] and not GameSettings.get_value("reduce_flashing") else Color(0.64, 0.74, 0.8)

func _on_airlock_opened() -> void:
	GameRuntime.behaviour.record(&"airlock_opened", player.global_position, &"airlock_outer", &"chapter_01")

func _finish_chapter() -> void:
	if stage == Stage.COMPLETE: return
	_set_stage(Stage.COMPLETE)
	_send(&"chapter_end")
	chapter_end_visible = true
	_show_end_transition(false)
	chapter_completed.emit()
	_checkpoint(6)

func _show_end_transition(immediate: bool) -> void:
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if immediate:
		end_fade.color.a = 0.96
		end_title.visible = true
		end_menu.visible = true
		return
	var fade := create_tween()
	fade.tween_property(end_fade, "color:a", 0.96, 2.2)
	fade.tween_callback(func() -> void: end_title.visible = true; end_menu.visible = true)

func _send(key: StringName, once := true) -> void:
	if once and spoken.has(String(key)): return
	spoken[String(key)] = true
	var line := dialogue.get_line(key)
	arrival_terminal.append_line(line)
	for node in wing.objects.values():
		if node is FacilityTerminal: (node as FacilityTerminal).append_line(line)
	get_parent().call("_status", "LINK 02 // " + line.trim_prefix("02: "))

func _set_stage(next: int) -> void:
	if stage == next: return
	stage = next
	stage_started_at = GameRuntime.playtime
	chapter_stage_changed.emit(stage)

func _stage_elapsed() -> float: return GameRuntime.playtime - stage_started_at

func _checkpoint(index: int) -> void:
	if index <= checkpoint_index: return
	var previous := checkpoint_index
	checkpoint_index = index
	if not SaveSystem.save_checkpoint(player): checkpoint_index = previous

func state_dict() -> Dictionary:
	var now := GameRuntime.playtime
	return {"stage": stage, "stage_elapsed": _stage_elapsed(), "checkpoint_index": checkpoint_index, "spoken": spoken.duplicate(true), "visited": visited.duplicate(true), "viewed_storage": viewed_storage, "viewed_generator": viewed_generator, "card_returned": card_returned, "generator_online": generator_online, "generator_pending": generator_pending, "generator_pending_elapsed": maxf(now - generator_pending_since, 0.0) if generator_pending else 0.0, "hatch_pending": hatch_pending, "hatch_pending_elapsed": maxf(now - hatch_pending_since, 0.0) if hatch_pending else 0.0, "chapter_end_visible": chapter_end_visible, "grid": grid.to_dict(), "reciprocity": reciprocity.to_dict(), "airlock": airlock.state_dict()}

func load_state(data: Dictionary) -> void:
	restoring = true
	stage = clampi(int(data.get("stage", Stage.WAITING)), Stage.WAITING, Stage.COMPLETE)
	stage_started_at = GameRuntime.playtime - float(data.get("stage_elapsed", 0.0))
	checkpoint_index = int(data.get("checkpoint_index", 0))
	spoken = data.get("spoken", {}).duplicate(true)
	visited = data.get("visited", {}).duplicate(true)
	viewed_storage = bool(data.get("viewed_storage", false))
	viewed_generator = bool(data.get("viewed_generator", false))
	card_returned = bool(data.get("card_returned", false))
	generator_online = bool(data.get("generator_online", false))
	var generator_hum: AudioStreamPlayer3D = wing.audio_zones.get("generator")
	if generator_hum:
		if generator_online and not generator_hum.playing and DisplayServer.get_name() != "headless": generator_hum.play()
		elif not generator_online: generator_hum.stop()
	generator_pending = bool(data.get("generator_pending", false))
	hatch_pending = bool(data.get("hatch_pending", false))
	var now := GameRuntime.playtime
	generator_pending_since = now - float(data.get("generator_pending_elapsed", 0.0)) if generator_pending else 0.0
	hatch_pending_since = now - float(data.get("hatch_pending_elapsed", 0.0)) if hatch_pending else 0.0
	chapter_end_visible = bool(data.get("chapter_end_visible", false))
	if chapter_end_visible: _show_end_transition(true)
	else:
		end_fade.color.a = 0.0; end_title.visible = false; end_menu.visible = false
		player.set_physics_process(true); player.set_process_unhandled_input(true)
	grid.load_dict(data.get("grid", {}))
	for id in [&"ventilation_breaker", &"starter_breaker", &"security_breaker", &"door_breaker"]: (wing.object(id) as CircuitBreaker).load_state({})
	reciprocity.load_dict(data.get("reciprocity", {}))
	airlock.load_state(data.get("airlock", {}))
	_apply_power_dependencies()
	restoring = false
	chapter_stage_changed.emit(stage)
