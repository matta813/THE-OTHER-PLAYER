extends Node3D

var camera: Camera3D
var clock := 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	camera = Camera3D.new(); camera.position = Vector3(0.8, 1.7, 5.7); camera.rotation.y = -0.14; add_child(camera); camera.current = true
	var environment := WorldEnvironment.new(); add_child(environment)
	var tone := Environment.new(); tone.background_mode = Environment.BG_COLOR; tone.background_color = Color(0.005, 0.011, 0.014); tone.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; tone.ambient_light_color = Color(0.07, 0.12, 0.13); tone.ambient_light_energy = 0.24; tone.fog_enabled = true; tone.fog_density = 0.022; environment.environment = tone
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
	GameSettings.apply_environment(tone)
	var hum := AudioStreamPlayer.new(); hum.name = "DistantVentilation"; hum.bus = "Ambience"; hum.volume_db = -32.0; hum.stream = FacilitySoundLibrary.hum(47.0); add_child(hum)
	if DisplayServer.get_name() != "headless": hum.play()

func _box(pos: Vector3, size: Vector3, color: Color, emissive := false) -> void:
	var mesh := MeshInstance3D.new(); var box := BoxMesh.new(); box.size = size; mesh.mesh = box; mesh.position = pos
	var material := StandardMaterial3D.new(); material.albedo_color = color; material.roughness = 0.84
	if emissive: material.emission_enabled = true; material.emission = color; material.emission_energy_multiplier = 1.1
	mesh.material_override = material; add_child(mesh)

func _process(delta: float) -> void:
	clock += delta
	if camera: camera.rotation.y = -0.14 + sin(clock * 0.13) * 0.012
