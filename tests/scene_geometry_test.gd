extends Node3D

var failures := 0

func _ready() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	var level := scene.instantiate()
	add_child(level)
	await get_tree().physics_frame
	await get_tree().physics_frame
	for point in [Vector3(0, 2, 5), Vector3(0, 2, -5), Vector3(0, 2, -9)]:
		check(not ray(point, point + Vector3(0, -4, 0), 1).is_empty(), "floor collision below %s" % point)
	for x in [0.0, 1.1, 1.5]:
		check(not ray(Vector3(x, 1.2, -1.0), Vector3(x, 1.2, -3.0), 3).is_empty(), "closed door seam at x=%.1f" % x)
	check(ray(Vector3(0, 1.2, -6.4), Vector3(0, 1.2, -7.6), 1).is_empty(), "Room B threshold center clear")
	check(not ray(Vector3(2, 1.2, -6.4), Vector3(2, 1.2, -7.6), 1).is_empty(), "Room B threshold wall solid")
	var player: Node3D = level.get_node("Player")
	var camera: Camera3D = level.get_node("Player/Head/Camera3D")
	check(camera.global_position.y > 1.4 and camera.global_position.y < 1.8, "standing eye height is human scale")
	var terminal: FacilityTerminal = level.get_node("Terminal")
	terminal.interact(player)
	check(GameRuntime.story_stage == 1 and not GameRuntime.other_player.scheduled.is_empty(), "terminal starts delayed remote task")
	var pending: Dictionary = GameRuntime.other_player.scheduled[0]
	pending["due"] = GameRuntime.other_player.now() - 0.01
	GameRuntime.other_player.scheduled[0] = pending
	await get_tree().process_frame
	await get_tree().process_frame
	check(not (level.get_node("Door") as ElectronicDoor).locked and GameRuntime.story_stage == 2, "remote action unlocks door")
	player.global_position = Vector3(0, 1.0, -7.5)
	await get_tree().process_frame
	check(GameRuntime.story_stage == 3 and not (level.get_node("RoomLight") as Light3D).visible, "Room B requests power while main light is off")
	(level.get_node("PowerSwitch") as PowerSwitch).interact(player)
	check(GameRuntime.story_stage == 4 and (level.get_node("RoomLight") as Light3D).visible, "switch powers Room B")
	check(GameRuntime.behaviour.model.samples[&"cooperation"] > 0, "slice updates behaviour model")
	Input.action_press("crouch")
	for frame in range(20): await get_tree().physics_frame
	var player_collider := level.get_node("Player/Collision") as CollisionShape3D
	var capsule := player_collider.shape as CapsuleShape3D
	check(camera.global_position.y < 1.35, "crouch lowers camera")
	check(absf(player_collider.global_position.y - capsule.height * 0.5 - 0.1) < 0.1, "crouch keeps feet on floor")
	Input.action_release("crouch")
	print("SCENE AND FLOW: %d checks, %d failed" % [16, failures])
	get_tree().quit(failures)

func ray(start: Vector3, end: Vector3, mask: int) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(start, end, mask)
	return get_world_3d().direct_space_state.intersect_ray(query)

func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + label)
