class_name SecurityCameraConsole
extends Interactable

signal feed_selected(feed_id: StringName)
var feeds: Array[Dictionary] = []
var selected_feed := -1
var active_seconds := 0.0
var feed_viewport: SubViewport
var feed_camera: Camera3D
var screen: MeshInstance3D
var status_label: Label3D
var powered := true

func _ready() -> void:
	super._ready()
	feed_viewport = SubViewport.new()
	feed_viewport.name = "CameraFeed"
	feed_viewport.size = Vector2i(384, 216)
	feed_viewport.transparent_bg = false
	feed_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(feed_viewport)
	feed_viewport.world_3d = get_viewport().world_3d
	feed_camera = Camera3D.new()
	feed_viewport.add_child(feed_camera)
	feed_camera.current = true
	status_label = Label3D.new()
	status_label.name = "FeedStatus"
	status_label.position = Vector3(-0.46, 0.42, 0.24)
	status_label.font_size = 28
	status_label.pixel_size = 0.0017
	status_label.text = "CCTV // STANDBY"
	add_child(status_label)
	screen = MeshInstance3D.new()
	screen.name = "Monitor"
	screen.position = Vector3(0, 0.06, 0.22)
	var mesh := BoxMesh.new(); mesh.size = Vector3(1.0, 0.58, 0.035); screen.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_texture = feed_viewport.get_texture()
	material.emission_enabled = true
	material.emission_texture = feed_viewport.get_texture()
	material.emission_energy_multiplier = 0.65
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	screen.material_override = material
	add_child(screen)
	set_process(false)

func configure(camera_feeds: Array[Dictionary]) -> void: feeds = camera_feeds.duplicate(true)

func _perform_interaction(_actor: Node) -> void:
	if feeds.is_empty() or not powered: return
	selected_feed = (selected_feed + 1) % feeds.size()
	var feed: Dictionary = feeds[selected_feed]
	feed_camera.global_position = feed.position
	feed_camera.look_at(feed.target, Vector3.UP)
	status_label.text = "CCTV // %s // %s" % [String(feed.id), String(feed.get("status", "SIGNAL OK"))]
	active_seconds = 8.0
	feed_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	set_process(true)
	feed_selected.emit(StringName(feed.id))
	state_changed.emit()

func _process(delta: float) -> void:
	active_seconds -= delta
	if active_seconds <= 0.0:
		active_seconds = 0.0
		feed_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		set_process(false)

func set_powered(enabled: bool) -> void:
	powered = enabled
	if not powered:
		active_seconds = 0.0
		feed_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		set_process(false)
		status_label.text = "CCTV // NO POWER"
	else: status_label.text = "CCTV // STANDBY"
	state_changed.emit()

func prompt_text(_actor: Node) -> String: return "[E] Select CCTV feed" if powered and not feeds.is_empty() else "CCTV OFFLINE"
func state_dict() -> Dictionary: return {"selected_feed": selected_feed, "powered": powered}
func load_state(data: Dictionary) -> void:
	selected_feed = int(data.get("selected_feed", -1))
	active_seconds = 0.0
	if feed_viewport: feed_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	set_process(false)
	if status_label: status_label.text = "CCTV // NO POWER" if not powered else ("CCTV // STANDBY" if selected_feed < 0 else "CCTV // %s" % String(feeds[clampi(selected_feed, 0, feeds.size() - 1)].id))
