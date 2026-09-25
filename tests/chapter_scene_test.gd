extends Node3D

var checks := 0
var failures := 0

func _ready() -> void:
	var level := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(level)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var player: FirstPersonController = level.get_node("Player")
	var wing: ChapterWingBuilder = level.get_node("ChapterWing")
	var chapter: ChapterOneController = level.get_node("ChapterOne")
	for point in [Vector3(0, 2, -17), Vector3(4.2, 2, -23), Vector3(-4.3, 2, -36), Vector3(4.2, 2, -44), Vector3(0, 2, -55)]:
		check(not ray(point, point + Vector3(0, -3, 0), 1).is_empty(), "solid floor below %s" % point)
	check(ray(Vector3(0, 1.2, -14.3), Vector3(0, 1.2, -51.5), 1).is_empty(), "main chapter corridor has a continuous unobstructed route")
	for section in [[-18.0, -4.0], [-23.0, 3.0], [-35.0, -3.0], [-44.0, 3.0]]:
		check(ray(Vector3(0, 1.2, section[0]), Vector3(section[1], 1.2, section[0]), 1).is_empty(), "side room entrance open at z %.1f" % section[0])
	GameRuntime.story_stage = 4
	player.global_position = Vector3(0, 1, -15)
	await get_tree().process_frame
	await get_tree().process_frame
	check(chapter.stage == ChapterOneController.Stage.CAMERA, "Chapter 1 starts after the existing electrical slice (stage %d, position %s)" % [chapter.stage, str(player.global_position)])
	var link_terminal := wing.object(&"link_terminal_12") as FacilityTerminal
	if link_terminal == null:
		for node in wing.objects.values():
			if node is FacilityTerminal: link_terminal = node; break
	link_terminal.interact(player)
	check((level.get_node("UI/TerminalPanel") as Panel).visible and (level.get_node("UI/TerminalPanel/TerminalText") as Label).text.contains("feeds"), "chapter link terminal presents the current in-world message")
	var camera := wing.object(&"camera_console") as SecurityCameraConsole
	var cctv_breaker := wing.object(&"security_breaker") as CircuitBreaker
	cctv_breaker.interact(player)
	camera.interact(player)
	check(not camera.powered and camera.selected_feed == -1, "CCTV feed cannot be used without its circuit")
	cctv_breaker.interact(player)
	camera.interact(player)
	check(camera.selected_feed == 0 and chapter.viewed_storage, "security camera shows storage feed only when used")
	(wing.object(&"generator_report") as FacilityActionPoint).interact(player)
	check(chapter.stage == ChapterOneController.Stage.CAMERA and GameRuntime.behaviour.count(&"camera_report_incorrect") == 1, "incorrect camera report provides a recoverable correction")
	camera.interact(player)
	check(camera.selected_feed == 1 and chapter.viewed_generator, "generator feed is independently observed")
	(wing.object(&"camera_report") as FacilityActionPoint).interact(player)
	check(chapter.stage == ChapterOneController.Stage.TRANSFER, "camera guidance advances reciprocal task")
	(wing.object(&"transfer_fuse") as CarryableItem).interact(player)
	check(player.carried_item_id == &"fuse_35a", "physical fuse can be carried")
	var hatch := wing.object(&"transfer_hatch") as TransferHatch
	hatch.interact(player)
	check(hatch.hatch_state == TransferHatch.HatchState.LOADED and player.carried_item_id == &"", "fuse deposits with stable item identity")
	hatch.interact(player)
	check(hatch.hatch_state == TransferHatch.HatchState.TRANSIT, "hatch must be sealed before transfer")
	chapter.stage_started_at -= 120.0
	chapter._process(0.0)
	check(hatch.hatch_state == TransferHatch.HatchState.TRANSIT, "old stage time does not trigger a premature transfer fallback")
	_force_action(&"chapter_fuse_receive")
	await get_tree().process_frame
	check(GameRuntime.behaviour.count(&"item_transferred") == 1, "remote player receives the fuse")
	_force_action(&"chapter_fuse_return")
	await get_tree().process_frame
	check(hatch.hatch_state == TransferHatch.HatchState.RETURN_READY and chapter.stage == ChapterOneController.Stage.POWER_ROUTE, "remote player returns a usable card")
	hatch.interact(player)
	check(player.carried_item_id == &"access_card", "returned item is physically recovered")
	var starter := wing.object(&"starter_breaker") as CircuitBreaker
	starter.interact(player)
	check(not chapter.grid.is_powered(&"generator_starter") and chapter.stage == ChapterOneController.Stage.POWER_ROUTE, "power budget rejects overload without softlocking")
	(wing.object(&"ventilation_breaker") as CircuitBreaker).interact(player)
	starter.interact(player)
	check(chapter.grid.demand() == 10 and chapter.stage == ChapterOneController.Stage.GENERATOR, "rerouting ventilation frees starter capacity")
	var saved := JSON.parse_string(JSON.stringify(SaveSystem.build_data(player))) as Dictionary
	check(SaveSystem.apply_data(player, saved) and chapter.stage == ChapterOneController.Stage.GENERATOR and chapter.grid.is_powered(&"generator_starter") and player.carried_item_id == &"access_card", "chapter state, grid, and carried item survive save round trip")
	(wing.object(&"generator_starter") as FacilityActionPoint).interact(player)
	check(chapter.generator_pending, "generator waits for remote contactor")
	chapter.stage_started_at -= 120.0
	chapter._process(0.0)
	check(chapter.generator_pending, "old stage time does not trigger a premature generator fallback")
	_force_action(&"chapter_generator_sync")
	await get_tree().process_frame
	check(chapter.stage == ChapterOneController.Stage.COMMS and chapter.generator_online, "remote sync enables communications")
	check(FileAccess.file_exists(SaveSystem.CHECKPOINT_PATH) and SaveSystem.load_checkpoint(player) and chapter.stage == ChapterOneController.Stage.COMMS, "generator checkpoint restores chapter progression")
	(wing.object(&"comms_panel") as FacilityActionPoint).interact(player)
	check(chapter.stage == ChapterOneController.Stage.AIRLOCK and not (wing.object(&"airlock_inner") as ElectronicDoor).locked, "link test enables airlock access")
	var control := wing.object(&"airlock_control") as AirlockControl
	var door_breaker := wing.object(&"door_breaker") as CircuitBreaker
	door_breaker.interact(player)
	check(not control.available and not (wing.object(&"airlock_inner") as ElectronicDoor).powered, "door control circuit removes airlock power")
	door_breaker.interact(player)
	check(control.available and (wing.object(&"airlock_inner") as ElectronicDoor).powered, "restoring door circuit recovers airlock progression")
	GameSettings.set_value("interaction_toggle", false)
	player.focused = control
	check(player._focused_prompt().begins_with("[HOLD E]"), "timed airlock action displays a hold prompt")
	player.focused = null
	var selector_start := control.selector.rotation.z if control.selector else 0.0
	control.interact(player)
	check(chapter.airlock.phase == AirlockSystem.Phase.REQUESTED, "airlock cycle is requested through physical control")
	await get_tree().create_timer(0.38).timeout
	check(control.selector != null and absf(control.selector.rotation.z - selector_start) > 0.3, "airlock selector turns when the cycle starts")
	check(not ray(Vector3(0, 1.2, -57.0), Vector3(0, 1.2, -59.0), 2).is_empty(), "outer door physically blocks passage before cycle")
	for duration in [1.1, 1.9, 4.6, 2.1]: chapter.airlock._process(duration)
	check(chapter.airlock.phase == AirlockSystem.Phase.OPEN and not (wing.object(&"airlock_outer") as ElectronicDoor).locked, "airlock seals, pressurizes, and opens in order")
	for frame in 120: await get_tree().process_frame
	check(ray(Vector3(0, 1.2, -57.0), Vector3(0, 1.2, -59.0), 2).is_empty(), "opened outer door clears physical route")
	player.global_position = Vector3(0, 1, -60)
	await get_tree().process_frame
	check(chapter.stage == ChapterOneController.Stage.COMPLETE and chapter.chapter_end_visible, "crossing airlock completes chapter without a blocking screen")
	print("CHAPTER FLOW: %d checks, %d failed" % [checks, failures])
	level.queue_free()
	await get_tree().process_frame
	get_tree().quit(failures)

func _force_action(action: StringName) -> void:
	for item in GameRuntime.other_player.scheduled:
		if item.action == action: item.due = GameRuntime.other_player.now() - 0.01

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + label)

func ray(start: Vector3, end: Vector3, mask: int) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(start, end, mask)
	return get_world_3d().direct_space_state.intersect_ray(query)
