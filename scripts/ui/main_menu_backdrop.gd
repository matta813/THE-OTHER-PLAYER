extends Node3D

var camera: Camera3D
var clock := 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	camera = Camera3D.new(); camera.position = Vector3(-2.3, 1.68, -1.0); camera.rotation.y = -0.08; add_child(camera); camera.current = true
	var environment := WorldEnvironment.new(); add_child(environment)
	var tone := Environment.new(); tone.background_mode = Environment.BG_COLOR; tone.background_color = Color(0.005, 0.011, 0.014); tone.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; tone.ambient_light_color = Color(0.07, 0.12, 0.13); tone.ambient_light_energy = 0.24; tone.fog_enabled = true; tone.fog_density = 0.012; environment.environment = tone
	_box(Vector3(0, -0.1, -2), Vector3(8, 0.2, 17), Color(0.11, 0.15, 0.16))
	_box(Vector3(0, 3.4, -2), Vector3(8, 0.2, 17), Color(0.08, 0.11, 0.12))
	for side in [-1, 1]:
		_box(Vector3(side * 4, 1.65, -2), Vector3(0.2, 3.5, 17), Color(0.10, 0.14, 0.15))
		for i in range(5):
			_box(Vector3(side * 3.82, 1.5, 3 - i * 2.6), Vector3(0.05, 2.7, 0.08), Color(0.2, 0.25, 0.25))
	_box(Vector3(0, 1.5, -9.6), Vector3(2.6, 3, 0.3), Color(0.16, 0.2, 0.21))
	_box(Vector3(0, 2.45, -9.4), Vector3(0.6, 0.07, 0.04), Color(0.22, 0.8, 0.55), true)
	for z in [-5.5, -1.0, 3.5]:
		_box(Vector3(0, 3.23, z), Vector3(1.8, 0.05, 0.32), Color(0.45, 0.6, 0.55), true)
		var light := OmniLight3D.new(); light.position = Vector3(0, 3.05, z); light.light_color = Color(0.47, 0.68, 0.62); light.light_energy = 0.55; light.omni_range = 5; add_child(light)
	for side in [-1.0, 1.0]:
		for i in range(6):
			ProductionKit.add_visual(self, "wall_section", Vector3(side * 3.85, 1.6, 3.4 - i * 2.4), Vector3(0, side * PI * 0.5, 0))
	ProductionKit.add_visual(self, "industrial_door", Vector3(0, 1.38, -9.32))
	ProductionKit.add_visual(self, "door_frame", Vector3(0, 1.52, -9.3))
	ProductionKit.add_visual(self, "terminal_housing", Vector3(2.55, 1.02, -6.4))
	ProductionKit.add_visual(self, "industrial_light", Vector3(0, 3.2, -5.5))
	var far_light := OmniLight3D.new(); far_light.position = Vector3(0, 2.8, -8.35); far_light.light_color = Color(0.54, 0.68, 0.61); far_light.light_energy = 0.95; far_light.omni_range = 4.2; far_light.shadow_enabled = true; add_child(far_light)
	GameSettings.apply_environment(tone)
	var hum := AudioStreamPlayer.new(); hum.name = "DistantVentilation"; hum.bus = "Ambience"; hum.volume_db = -32.0; hum.stream = FacilitySoundLibrary.ambience("maintenance"); add_child(hum)
	if DisplayServer.get_name() != "headless": hum.play()

func _box(pos: Vector3, size: Vector3, color: Color, emissive := false) -> void:
	var mesh := MeshInstance3D.new(); var box := BoxMesh.new(); box.size = size; mesh.mesh = box; mesh.position = pos
	var material := StandardMaterial3D.new(); material.albedo_color = color; material.roughness = 0.84
	if emissive: material.emission_enabled = true; material.emission = color; material.emission_energy_multiplier = 1.1
	mesh.material_override = material; add_child(mesh)

func _process(delta: float) -> void:
	clock += delta
	if camera: camera.rotation.y = -0.08 + sin(clock * 0.13) * 0.012
