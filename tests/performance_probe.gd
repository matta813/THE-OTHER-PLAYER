extends Node

func _ready() -> void:
	call_deferred("_probe")

func _probe() -> void:
	var game: Node3D = load("res://scenes/chapter_01.tscn").instantiate()
	add_child(game)
	var player: FirstPersonController = game.get_node("Player")
	player.set_physics_process(false)
	player.global_position = Vector3(0, 1, -30)
	player.camera.make_current()
	var meshes := game.find_children("*", "MeshInstance3D", true, false).size()
	var lights := game.find_children("*", "Light3D", true, false)
	var shadowed := 0
	for light in lights:
		if light.shadow_enabled: shadowed += 1
	var begin := Time.get_ticks_msec()
	for i in 180: await get_tree().process_frame
	var elapsed := Time.get_ticks_msec() - begin
	var viewport := get_viewport()
	print("PERFORMANCE: renderer=", RenderingServer.get_rendering_device() != null, " viewport=", viewport.size, " frames=180 elapsed_ms=", elapsed, " engine_fps=", Engine.get_frames_per_second())
	print("PERFORMANCE: meshes=", meshes, " lights=", lights.size(), " shadowed_lights=", shadowed)
	print("PERFORMANCE: visible_objects=", viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_OBJECTS_IN_FRAME), " draw_calls=", viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME), " primitives=", viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME))
	get_tree().quit()
