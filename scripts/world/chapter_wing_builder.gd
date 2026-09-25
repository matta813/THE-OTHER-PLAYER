class_name ChapterWingBuilder
extends Node3D

var concrete := preload("res://assets/materials/painted_concrete.tres")
var bare := preload("res://assets/materials/bare_concrete.tres")
var floor_material := preload("res://assets/materials/facility_floor.tres")
var metal := preload("res://assets/materials/industrial_metal.tres")
var rubber := preload("res://assets/materials/dark_rubber.tres")
var hazard := preload("res://assets/materials/hazard_yellow.tres")
var glow := preload("res://assets/materials/monitor_glow.tres")
var luminaire := preload("res://assets/materials/luminaire_diffuser.tres")
var enamel := preload("res://assets/materials/machine_enamel.tres")
var objects: Dictionary = {}
var lights: Dictionary = {}
var task_lights: Dictionary = {}
var audio_zones: Dictionary = {}
var power_readout: Label3D
var airlock_audio: AudioStreamPlayer3D

func _ready() -> void:
	_build_shell()
	_build_service_details()
	_build_task_stations()
	_build_room_props()
	_build_lighting()
	_install_production_kit()
	airlock_audio = AudioStreamPlayer3D.new(); airlock_audio.name = "AirlockMechanics"; airlock_audio.position = Vector3(0, 1.6, -55); airlock_audio.max_distance = 16.0; airlock_audio.volume_db = -11.0; airlock_audio.bus = "SFX"; add_child(airlock_audio)

func object(id: StringName) -> Node: return objects.get(id)

func set_zone_power(id: String, enabled: bool) -> void:
	if id == "security" and task_lights.has(id): (task_lights[id] as Light3D).visible = enabled
	var player := audio_zones.get(id) as AudioStreamPlayer3D
	if player == null or DisplayServer.get_name() == "headless": return
	if enabled:
		if not player.playing: player.play()
		player.volume_db = -32.0 if id in ["observation", "airlock"] else -27.0
	else: player.stop()

func play_airlock_phase(phase: int) -> void:
	if airlock_audio == null or DisplayServer.get_name() == "headless": return
	match phase:
		AirlockSystem.Phase.SEALING: airlock_audio.stream = FacilitySoundLibrary.relay()
		AirlockSystem.Phase.PRESSURIZING: airlock_audio.stream = FacilitySoundLibrary.pressure()
		AirlockSystem.Phase.OPENING: airlock_audio.stream = FacilitySoundLibrary.motor()
		_: return
	airlock_audio.play()

func _install_production_kit() -> void:
	# Exterior wall modules leave the proven collision shell and stable task layout intact.
	for side in [-1.0, 1.0]:
		for index in range(20):
			var z := -15.2 - index * 2.4
			ProductionKit.add_visual(self, "wall_section", Vector3(side * 5.80, 1.7, z), Vector3(0, side * PI * 0.5, 0))
		for z in [-18.0, -30.0, -42.0, -54.0]:
			ProductionKit.add_visual(self, "cable_tray", Vector3(side * 5.45, 2.88, z))
			ProductionKit.add_visual(self, "pipe_straight", Vector3(side * 5.48, 2.46, z))
	for z in [-17.8, -23.2, -29.5, -36.0, -41.0, -44.5, -48.5, -54.5]:
		ProductionKit.add_visual(self, "industrial_light", Vector3(0, 3.19, z))
	for side in [-1.0, 1.0]:
		for z in [-53.3, -55.6]:
			ProductionKit.add_visual(self, "reinforced_wall", Vector3(side * 1.29, 1.7, z), Vector3(0, side * PI * 0.5, 0))
		ProductionKit.add_visual(self, "pipe_straight", Vector3(side * 1.15, 2.55, -54.5))
	for z in [-52.0, -58.0]:
		ProductionKit.add_visual(self, "door_frame", Vector3(0, 1.48, z))
		ProductionKit.add_visual(self, "emergency_light", Vector3(0, 2.88, z + 0.3))
	ProductionKit.add_visual(self, "equipment_rack", Vector3(5.06, 1.04, -26.2))
	ProductionKit.add_visual(self, "electrical_cabinet", Vector3(3.6, 1.1, -9.0))
	ProductionKit.add_visual(self, "generator_control_unit", Vector3(-3.2, 1.02, -34.7))
	for child in get_children():
		if child.name in ["GeneratorBed", "GeneratorRotor", "RotorBand", "GeneratorSupport", "CoolingFin"]:
			(child as Node3D).visible = false
	ProductionKit.add_visual(self, "generator_unit", Vector3(-4.55, 1.17, -37.1))
	ProductionKit.add_visual(self, "warning_sign_frame", Vector3(0, 2.23, -51.74))

func _exit_tree() -> void:
	for zone in audio_zones.values():
		(zone as AudioStreamPlayer3D).stop()
		(zone as AudioStreamPlayer3D).stream = null
	audio_zones.clear()

func _build_shell() -> void:
	_box("ChapterFloor", Vector3(0, -0.1, -38.2), Vector3(12, 0.4, 48.4), floor_material, true)
	_box("ChapterCeiling", Vector3(0, 3.45, -38.2), Vector3(12, 0.2, 48.4), bare, true)
	for side in [-1.0, 1.0]:
		_box("OuterWall", Vector3(side * 6.0, 1.7, -38.2), Vector3(0.3, 3.4, 48.4), concrete, true)
	for section in [[-14.0, -16.0], [-20.0, -32.0], [-39.0, -52.0]]:
		_partition(-2.2, float(section[0]), float(section[1]))
	for section in [[-14.0, -21.0], [-26.0, -42.0], [-47.0, -52.0]]:
		_partition(2.2, float(section[0]), float(section[1]))
	for z in [-52.0, -58.0]:
		_box("AirlockBulkheadL", Vector3(-3.65, 1.7, z), Vector3(4.7, 3.4, 0.32), bare, true)
		_box("AirlockBulkheadR", Vector3(3.65, 1.7, z), Vector3(4.7, 3.4, 0.32), bare, true)
		_box("AirlockHeader", Vector3(0, 3.04, z), Vector3(2.8, 0.5, 0.38), metal, true)
	_box("ChapterEndWall", Vector3(0, 1.7, -62.45), Vector3(12, 3.4, 0.3), concrete, true)
	_box("MaintenanceGrating", Vector3(0, 0.16, -30.0), Vector3(3.7, 0.035, 7.0), metal, false)
	_box("AirlockFloor", Vector3(0, 0.16, -55.0), Vector3(2.7, 0.04, 5.4), metal, false)
	for side in [-1.0, 1.0]:
		_box("AirlockSideWall", Vector3(side * 1.55, 1.7, -55.0), Vector3(0.22, 3.4, 5.7), bare, true)
		_box("AirlockServiceChannel", Vector3(side * 1.28, 2.83, -55.0), Vector3(0.18, 0.16, 5.4), metal, false)
	_box("AirlockCeilingCassette", Vector3(0, 3.17, -55.0), Vector3(2.8, 0.23, 5.55), metal, false)

func _partition(x: float, from_z: float, to_z: float) -> void:
	var center := (from_z + to_z) * 0.5
	_box("Partition", Vector3(x, 1.7, center), Vector3(0.2, 3.4, absf(to_z - from_z)), concrete, true)

func _build_service_details() -> void:
	for z in [-16.0, -19.5, -23.0, -27.0, -31.0, -35.5, -40.0, -44.5, -48.5, -54.5, -60.0]:
		_box("CeilingTruss", Vector3(0, 3.22, z), Vector3(11.4, 0.16, 0.18), metal, false)
		_box("FloorJoint", Vector3(0, 0.155, z), Vector3(11.4, 0.008, 0.025), rubber, false)
	for x in [-5.62, 5.62]:
		_box("CableTray", Vector3(x, 2.86, -38.2), Vector3(0.3, 0.16, 46.0), metal, false)
		_box("Pipe", Vector3(x, 2.44, -38.2), Vector3(0.09, 0.09, 46.0), metal, false)
		for z in [-18.0, -24.0, -30.0, -36.0, -42.0, -48.0, -54.0]:
			_box("TraySupport", Vector3(x, 2.95, z), Vector3(0.5, 0.04, 0.12), rubber, false)
	for z in [-17.8, -23.2, -29.5, -36.0, -41.0, -44.5, -49.0, -55.0]:
		_box("LightHousing", Vector3(0, 3.29, z), Vector3(1.6, 0.14, 0.5), metal, false)
		_box("LightDiffuser", Vector3(0, 3.18, z), Vector3(1.28, 0.03, 0.32), luminaire, false)
	for z in [-29.0, -30.0, -31.0, -40.0, -41.0, -42.0]:
		_box("GrateCrossbar", Vector3(0, 0.185, z), Vector3(3.5, 0.018, 0.08), rubber, false)
	for z in [-52.4, -57.6]:
		_box("AirlockHazardStripe", Vector3(0, 0.185, z), Vector3(2.6, 0.008, 0.08), hazard, false)
	_label("STORAGE / 03", Vector3(-2.08, 2.25, -17.0), Vector3(0, PI / 2.0, 0))
	_label("SECURITY OFFICE / 04", Vector3(2.08, 2.25, -22.0), Vector3(0, -PI / 2.0, 0))
	_label("MAINTENANCE ACCESS", Vector3(0, 2.7, -28.0), Vector3.ZERO)
	_label("GENERATOR / 05", Vector3(-2.08, 2.25, -34.0), Vector3(0, PI / 2.0, 0))
	_label("OBSERVATION // CAMERA LIMIT", Vector3(0, 2.7, -40.0), Vector3.ZERO)
	_label("TRANSFER / 06", Vector3(2.08, 2.25, -43.0), Vector3(0, -PI / 2.0, 0))
	_label("COMMS // LINK 02", Vector3(0, 2.7, -48.0), Vector3.ZERO)
	_label("EXIT AIRLOCK // MANUAL CYCLE", Vector3(0, 2.7, -51.6), Vector3.ZERO)
	_build_schematic()
	for z in [-18.5, -36.5, -44.0]:
		_box("EquipmentHousing", Vector3(-5.25 if z != -44.0 else 5.25, 0.75, z), Vector3(0.9, 1.5, 0.72), metal, true)
		for offset in [-0.2, 0.0, 0.2]: _box("HousingVent", Vector3(-5.25 if z != -44.0 else 5.25, 0.8 + offset, z + 0.37), Vector3(0.55, 0.025, 0.015), rubber, false)

func _build_task_stations() -> void:
	var fuse := CarryableItem.new(); fuse.name = "TransferFuse"; fuse.stable_id = &"transfer_fuse"; fuse.item_id = &"fuse_35a"; fuse.interaction_name = "Take 35A fuse"; fuse.position = Vector3(-4.15, 1.0, -18.0); _add_interactable(fuse, Vector3(0.22, 0.1, 0.1), hazard)
	var camera := SecurityCameraConsole.new(); camera.name = "CameraConsole"; camera.stable_id = &"camera_console"; camera.interaction_name = "Security camera selector"; camera.position = Vector3(4.2, 1.05, -23.0); _add_interactable(camera, Vector3(1.18, 0.86, 0.42), metal)
	camera.configure([{"id": "STORAGE", "status": "RELAY ACTIVE", "position": Vector3(-3.8, 2.85, -19.6), "target": Vector3(-4.2, 1.0, -18.0)}, {"id": "GENERATOR", "status": "CONTACTOR OPEN", "position": Vector3(-3.8, 2.9, -38.0), "target": Vector3(-4.6, 1.2, -36.0)}])
	var report := FacilityActionPoint.new(); report.name = "CameraReport"; report.stable_id = &"camera_report"; report.action_id = &"report_storage"; report.interaction_name = "Report storage relay status"; report.position = Vector3(3.0, 1.0, -23.0); _add_interactable(report, Vector3(0.35, 0.55, 0.22), metal)
	var wrong_report := FacilityActionPoint.new(); wrong_report.name = "GeneratorReport"; wrong_report.stable_id = &"generator_report"; wrong_report.action_id = &"report_generator"; wrong_report.interaction_name = "Report generator contactor status"; wrong_report.position = Vector3(3.45, 1.0, -23.0); _add_interactable(wrong_report, Vector3(0.35, 0.55, 0.22), metal)
	var ventilation := CircuitBreaker.new(); ventilation.name = "VentilationBreaker"; ventilation.stable_id = &"ventilation_breaker"; ventilation.circuit_id = &"ventilation"; ventilation.interaction_name = "Ventilation breaker"; ventilation.position = Vector3(3.2, 1.0, -24.1); _add_interactable(ventilation, Vector3(0.28, 0.72, 0.2), metal)
	var starter := CircuitBreaker.new(); starter.name = "StarterBreaker"; starter.stable_id = &"starter_breaker"; starter.circuit_id = &"generator_starter"; starter.interaction_name = "Generator starter breaker"; starter.position = Vector3(3.65, 1.0, -24.1); _add_interactable(starter, Vector3(0.28, 0.72, 0.2), metal)
	var security_breaker := CircuitBreaker.new(); security_breaker.name = "SecurityBreaker"; security_breaker.stable_id = &"security_breaker"; security_breaker.circuit_id = &"security"; security_breaker.interaction_name = "CCTV circuit breaker"; security_breaker.position = Vector3(4.1, 1.0, -24.1); _add_interactable(security_breaker, Vector3(0.28, 0.72, 0.2), metal)
	var door_breaker := CircuitBreaker.new(); door_breaker.name = "DoorBreaker"; door_breaker.stable_id = &"door_breaker"; door_breaker.circuit_id = &"door_controls"; door_breaker.interaction_name = "Door control breaker"; door_breaker.position = Vector3(4.55, 1.0, -24.1); _add_interactable(door_breaker, Vector3(0.28, 0.72, 0.2), metal)
	var hatch := TransferHatch.new(); hatch.name = "TransferHatch"; hatch.stable_id = &"transfer_hatch"; hatch.interaction_name = "Transfer hatch"; hatch.position = Vector3(4.3, 0.95, -44.0); _add_interactable(hatch, Vector3(1.18, 0.8, 0.52), metal)
	var generator := FacilityActionPoint.new(); generator.name = "GeneratorStarter"; generator.stable_id = &"generator_starter"; generator.action_id = &"start_generator"; generator.interaction_duration = 0.65; generator.interaction_name = "Generator starter"; generator.position = Vector3(-3.15, 1.0, -34.8); _add_interactable(generator, Vector3(0.8, 1.25, 0.42), metal)
	var comms := FacilityActionPoint.new(); comms.name = "CommsPanel"; comms.stable_id = &"comms_panel"; comms.action_id = &"test_link"; comms.interaction_name = "Test remote link"; comms.position = Vector3(0.0, 1.0, -48.5); _add_interactable(comms, Vector3(0.85, 1.0, 0.38), metal)
	var control := AirlockControl.new(); control.name = "AirlockControl"; control.stable_id = &"airlock_control"; control.interaction_name = "Airlock cycle control"; control.interaction_duration = 0.8; control.position = Vector3(1.08, 1.1, -54.0); _add_interactable(control, Vector3(0.48, 0.68, 0.28), metal)
	var inner := _door("AirlockInnerDoor", &"airlock_inner", -52.0)
	var outer := _door("AirlockOuterDoor", &"airlock_outer", -58.0)
	objects[&"airlock_inner"] = inner; objects[&"airlock_outer"] = outer
	for position in [Vector3(3.05, 1.0, -25.0), Vector3(-4.7, 1.0, -35.0), Vector3(0, 1.0, -49.5)]:
		var terminal := FacilityTerminal.new(); terminal.name = "LinkTerminal"; terminal.stable_id = StringName("link_terminal_%d" % objects.size()); terminal.interaction_name = "Link terminal"; terminal.position = position
		var screen := MeshInstance3D.new(); var screen_mesh := BoxMesh.new(); screen_mesh.size = Vector3(0.48, 0.38, 0.035); screen.mesh = screen_mesh; screen.material_override = glow; screen.position = Vector3(0, 0.2, 0.18); terminal.add_child(screen)
		var text := Label3D.new(); text.name = "ScreenText"; text.position = Vector3(-0.21, 0.28, 0.205); text.font_size = 26; text.pixel_size = 0.0018; text.modulate = Color(0.52, 0.94, 0.69); terminal.add_child(text)
		_add_interactable(terminal, Vector3(0.62, 1.25, 0.3), metal)

func _build_lighting() -> void:
	for fixture in [
		{"z": -17.8, "color": Color(0.62, 0.72, 0.72), "energy": 0.85},
		{"z": -23.2, "color": Color(0.55, 0.7, 0.63), "energy": 0.9},
		{"z": -29.5, "color": Color(0.52, 0.58, 0.56), "energy": 1.2},
		{"z": -36.0, "color": Color(0.92, 0.75, 0.53), "energy": 0.9},
		{"z": -41.0, "color": Color(0.6, 0.69, 0.69), "energy": 0.75},
		{"z": -44.5, "color": Color(0.78, 0.82, 0.73), "energy": 0.85},
		{"z": -48.5, "color": Color(0.58, 0.73, 0.66), "energy": 0.8},
		{"z": -54.5, "color": Color(0.69, 0.78, 0.82), "energy": 1.4}
	]:
		var practical := OmniLight3D.new()
		practical.name = "PracticalCeilingLight"
		practical.position = Vector3(0, 2.85, fixture.z)
		practical.light_color = fixture.color
		practical.light_energy = fixture.energy
		practical.omni_range = 7.2
		practical.shadow_enabled = fixture.z in [-23.2, -36.0, -54.5]
		add_child(practical)
	# Bench luminaires illuminate the two primary work surfaces without casting more shadows.
	for station in [
		{"id": "security", "position": Vector3(4.35, 2.95, -23.8), "color": Color(0.55, 0.73, 0.65)},
		{"id": "generator", "position": Vector3(-4.50, 2.98, -37.1), "color": Color(0.95, 0.79, 0.58)}
	]:
		ProductionKit.add_visual(self, "industrial_light", station.position + Vector3(0, 0.20, 0))
		var task_light := SpotLight3D.new()
		task_light.name = "%sTaskLight" % station.id
		task_light.position = station.position
		task_light.rotation.x = -PI * 0.5
		task_light.light_color = station.color
		task_light.light_energy = 1.15
		task_light.spot_range = 4.5
		task_light.spot_angle = 45.0
		task_light.shadow_enabled = false
		add_child(task_light)
		task_lights[station.id] = task_light
	for zone in [
		{"id": "storage", "position": Vector3(-4.4, 2.8, -18), "color": Color(0.42, 0.52, 0.55), "energy": 0.9},
		{"id": "security", "position": Vector3(4.3, 2.8, -23), "color": Color(0.4, 0.65, 0.55), "energy": 0.85},
		{"id": "maintenance", "position": Vector3(0, 2.8, -30), "color": Color(0.45, 0.51, 0.48), "energy": 1.2},
		{"id": "generator", "position": Vector3(-4.3, 2.8, -36), "color": Color(0.9, 0.69, 0.44), "energy": 1.2},
		{"id": "observation", "position": Vector3(0, 2.8, -41), "color": Color(0.5, 0.63, 0.67), "energy": 0.8},
		{"id": "transfer", "position": Vector3(4.3, 2.8, -44), "color": Color(0.72, 0.74, 0.66), "energy": 0.85},
		{"id": "communications", "position": Vector3(0, 2.8, -49), "color": Color(0.42, 0.64, 0.57), "energy": 0.9},
		{"id": "airlock", "position": Vector3(0, 2.8, -55), "color": Color(0.64, 0.74, 0.8), "energy": 0.75}
	]:
		var light := OmniLight3D.new(); light.name = "%sLight" % zone.id; light.position = zone.position; light.light_color = zone.color; light.light_energy = zone.energy; light.omni_range = 6.5; light.shadow_enabled = zone.id in ["generator", "airlock"]; add_child(light); lights[zone.id] = light
		var ambience := AudioStreamPlayer3D.new(); ambience.name = "%sHum" % zone.id; ambience.position = zone.position - Vector3(0, 1.5, 0); ambience.max_distance = 12.0; ambience.volume_db = -32.0 if zone.id in ["observation", "airlock"] else -27.0; ambience.stream = FacilitySoundLibrary.ambience(zone.id); ambience.bus = "Ambience"; add_child(ambience); audio_zones[zone.id] = ambience
		if zone.id != "generator" and DisplayServer.get_name() != "headless": ambience.play()

func _build_room_props() -> void:
	# Storage: anchored shelving, labeled trays, and a conspicuously incomplete fuse rack.
	for z in [-17.0, -18.6, -20.0]:
		for y in [0.45, 1.15, 1.85]: _box("StorageShelf", Vector3(-5.1, y, z), Vector3(1.45, 0.06, 0.58), metal, false)
		for x in [-5.75, -4.45]: _box("ShelfUpright", Vector3(x, 1.13, z), Vector3(0.06, 2.22, 0.06), metal, false)
	for z in [-17.0, -20.0]:
		_box("PartsBin", Vector3(-5.1, 1.36, z), Vector3(0.42, 0.28, 0.3), rubber, false)
	_label("35A  /  SPARE", Vector3(-5.8, 2.45, -17.5), Vector3(0, PI / 2.0, 0))
	# Security: a continuous workstation, paired inactive monitors and a physical schematic.
	_box("SecurityDesk", Vector3(4.4, 0.74, -24.0), Vector3(2.65, 0.09, 0.7), enamel, true)
	for x in [3.2, 5.55]: _box("DeskPedestal", Vector3(x, 0.37, -24.0), Vector3(0.22, 0.68, 0.62), metal, false)
	for x in [3.35, 5.3]:
		_box("InactiveMonitorFrame", Vector3(x, 1.42, -24.25), Vector3(0.82, 0.54, 0.12), rubber, false)
		_box("InactiveMonitorScreen", Vector3(x, 1.42, -24.17), Vector3(0.66, 0.4, 0.018), glow, false)
		_box("MonitorStand", Vector3(x, 1.06, -24.25), Vector3(0.06, 0.24, 0.09), metal, false)
	_box("SecurityKeybed", Vector3(4.4, 0.84, -23.75), Vector3(0.9, 0.035, 0.2), rubber, false)
	for x in [4.08, 4.22, 4.36, 4.5, 4.64, 4.78]: _box("SecurityKey", Vector3(x, 0.865, -23.7), Vector3(0.09, 0.015, 0.06), metal, false)
	for y in [1.15, 1.45, 1.75]: _box("StatusRail", Vector3(5.72, y, -23.0), Vector3(0.035, 0.025, 2.0), metal, false)
	_label("CCTV 01 // STORAGE", Vector3(3.05, 1.83, -24.1), Vector3.ZERO)
	_label("CCTV 02 // GENERATOR", Vector3(4.92, 1.83, -24.1), Vector3.ZERO)
	# Generator: a restrained turbine housing with radial rings and service pipework.
	_box("GeneratorBed", Vector3(-4.55, 0.35, -37.1), Vector3(2.55, 0.58, 2.8), enamel, true)
	_cylinder("GeneratorRotor", Vector3(-4.55, 1.25, -37.1), 0.58, 2.2, enamel, true)
	for z in [-38.0, -37.5, -37.0, -36.5, -36.1]: _cylinder("RotorBand", Vector3(-4.55, 1.25, z), 0.64, 0.09, rubber, false)
	for x in [-5.65, -3.45]:
		_box("GeneratorSupport", Vector3(x, 1.0, -37.1), Vector3(0.12, 1.15, 2.4), metal, false)
		_box("GeneratorFeedPipe", Vector3(x, 2.12, -36.8), Vector3(0.15, 0.15, 3.2), metal, false)
	for z in [-38.0, -37.2, -36.4]: _box("CoolingFin", Vector3(-4.55, 1.84, z), Vector3(1.6, 0.1, 0.08), metal, false)
	_label("CONTACTOR / REMOTE HOLD", Vector3(-5.8, 2.4, -35.3), Vector3(0, PI / 2.0, 0))
	# Transfer interface: reinforced hatch frame, rollers, and a mechanical latch.
	for x in [3.56, 5.04]: _box("HatchFrameSide", Vector3(x, 1.0, -44.0), Vector3(0.12, 1.14, 0.64), rubber, false)
	for y in [0.43, 1.57]: _box("HatchFrameTop", Vector3(4.3, y, -44.0), Vector3(1.6, 0.12, 0.64), rubber, false)
	for z in [-44.22, -44.08, -43.94, -43.8]: _cylinder("TransferRoller", Vector3(4.3, 0.59, z), 0.035, 1.22, metal, false, false)
	_box("HatchLatch", Vector3(4.9, 1.28, -43.66), Vector3(0.12, 0.32, 0.08), hazard, false)
	_label("SEALED TRANSFER / LINK 02", Vector3(5.8, 2.3, -44.2), Vector3(0, -PI / 2.0, 0))
	# Airlock: redundant rails, gaskets, warning markers, and visible interlocks.
	for x in [-1.43, 1.43]:
		for z in [-52.0, -58.0]:
			_box("AirlockGasket", Vector3(x, 1.4, z + 0.14), Vector3(0.09, 2.8, 0.08), rubber, false)
			_box("AirlockGuard", Vector3(x * 1.25, 0.85, z + 0.6), Vector3(0.07, 1.45, 0.08), hazard, false)
	for side in [-1.0, 1.0]:
		_box("AirlockWallBaseRail", Vector3(side * 1.18, 0.36, -55.0), Vector3(0.07, 0.18, 5.55), metal, false)
		_box("AirlockWallTopRail", Vector3(side * 1.18, 2.68, -55.0), Vector3(0.07, 0.08, 5.55), metal, false)
		for z in [-53.45, -55.0, -56.55]:
			_box("AirlockWallRib", Vector3(side * 1.17, 1.48, z), Vector3(0.09, 2.3, 0.08), metal, false)
	for z in [-53.0, -54.0, -55.0, -56.0, -57.0]:
		_box("AirlockFloorGrip", Vector3(0, 0.195, z), Vector3(2.5, 0.01, 0.05), rubber, false)
		_box("AirlockCeilingRail", Vector3(0, 3.23, z), Vector3(2.6, 0.1, 0.1), metal, false)
	_label("INTERLOCK / KEEP CLEAR", Vector3(0, 2.45, -57.65), Vector3.ZERO)
	# Optional maintenance traces, deliberately short and mundane.
	_notice(&"storage_notice", Vector3(-5.76, 1.2, -19.0), "35A fuse stock: one unit. Recount pending.")
	_notice(&"security_notice", Vector3(5.74, 1.15, -22.1), "Camera 03 offline after conduit work.")
	_notice(&"generator_notice", Vector3(-5.76, 1.18, -34.4), "Remote contactor requires second operator.")

func _notice(id: StringName, position: Vector3, value: String) -> void:
	var note := InspectionProp.new(); note.name = String(id); note.stable_id = id; note.interaction_name = "Read maintenance notice"; note.observation_text = value; note.position = position
	_add_interactable(note, Vector3(0.05, 0.42, 0.5), bare)

func _build_schematic() -> void:
	_box("SchematicBackplate", Vector3(5.76, 1.85, -24.2), Vector3(0.08, 1.55, 2.85), rubber, false)
	_box("SchematicRoute", Vector3(5.7, 1.68, -24.2), Vector3(0.02, 0.018, 2.34), enamel, false)
	for mark in [
		{"z": -23.15, "name": "ARRIVAL"}, {"z": -23.65, "name": "SECURITY"},
		{"z": -24.15, "name": "TRANSFER"}, {"z": -24.65, "name": "GENERATOR"},
		{"z": -25.15, "name": "AIRLOCK"}
	]:
		_box("SchematicNode", Vector3(5.67, 1.68, mark.z), Vector3(0.03, 0.09, 0.09), hazard, false)
		_label(mark.name, Vector3(5.64, 1.92, mark.z), Vector3(0, -PI / 2.0, 0))
	_label("FACILITY / SERVICE SPINE", Vector3(5.62, 2.46, -24.9), Vector3(0, -PI / 2.0, 0))
	_label("10 kW  CCTV 3  DOORS 2  VENT 3  START 5", Vector3(5.62, 1.31, -25.1), Vector3(0, -PI / 2.0, 0))
	power_readout = Label3D.new(); power_readout.name = "PowerReadout"; power_readout.text = "LOAD 8 / 10"; power_readout.position = Vector3(5.6, 2.24, -23.1); power_readout.rotation.y = -PI / 2.0; power_readout.font_size = 54; power_readout.pixel_size = 0.0018; power_readout.modulate = Color(0.9, 0.72, 0.42); add_child(power_readout)

func _cylinder(node_name: String, position: Vector3, radius: float, length: float, material: Material, collides: bool, along_z := true) -> Node3D:
	var root: Node3D = StaticBody3D.new() if collides else Node3D.new(); root.name = node_name; root.position = position
	var mesh := MeshInstance3D.new(); var shape := CylinderMesh.new(); shape.top_radius = radius; shape.bottom_radius = radius; shape.height = length; mesh.mesh = shape; mesh.material_override = material
	if along_z: mesh.rotation.x = PI / 2.0
	root.add_child(mesh)
	if collides:
		var collider := CollisionShape3D.new(); var capsule := CapsuleShape3D.new(); capsule.radius = radius; capsule.height = length; collider.shape = capsule; collider.rotation = mesh.rotation; root.add_child(collider)
	add_child(root); return root

func _add_interactable(node: Interactable, size: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new(); mesh.name = "BodyMesh"; var box_mesh := BoxMesh.new(); box_mesh.size = size; mesh.mesh = box_mesh; mesh.material_override = material; node.add_child(mesh)
	var visual_names := {"camera_console": "security_console", "transfer_hatch": "transfer_hatch", "generator_starter": "generator_control_unit", "airlock_control": "airlock_cycle_panel"}
	var visual_name: String = visual_names.get(String(node.stable_id), "")
	if not visual_name.is_empty():
		mesh.visible = false
		ProductionKit.add_visual(node, visual_name, Vector3.ZERO, Vector3(0, PI * 0.5, 0) if node.stable_id == &"airlock_control" else Vector3.ZERO)
	var collider := CollisionShape3D.new(); collider.name = "Collision"; var shape := BoxShape3D.new(); shape.size = size; collider.shape = shape; node.add_child(collider)
	var audio := FacilityAudioEmitter.new(); audio.name = "Audio"; audio.max_distance = 7.0; audio.interaction_volume_db = -14.0; node.add_child(audio)
	add_child(node)
	objects[node.stable_id] = node

func _door(node_name: String, id: StringName, z: float) -> ElectronicDoor:
	var door := ElectronicDoor.new(); door.name = node_name; door.stable_id = id; door.interaction_name = "Airlock bulkhead"; door.position = Vector3(-1.3, 1.35, z); door.open_angle = -96.0
	var mesh := MeshInstance3D.new(); mesh.name = "DoorLeaf"; mesh.position = Vector3(1.3, 0, 0); var shape := BoxMesh.new(); shape.size = Vector3(2.6, 2.7, 0.18); mesh.mesh = shape; mesh.material_override = metal; mesh.visible = false; door.add_child(mesh)
	ProductionKit.add_visual(door, "airlock_door", mesh.position)
	var collider := CollisionShape3D.new(); collider.name = "Collision"; collider.position = mesh.position; var collision_shape := BoxShape3D.new(); collision_shape.size = shape.size; collider.shape = collision_shape; door.add_child(collider)
	var audio := FacilityAudioEmitter.new(); audio.name = "Audio"; audio.max_distance = 15.0; audio.interaction_volume_db = -12.0; door.add_child(audio)
	add_child(door)
	return door

func _box(node_name: String, position: Vector3, size: Vector3, material: Material, collides: bool) -> Node3D:
	var root: Node3D = StaticBody3D.new() if collides else Node3D.new(); root.name = node_name; root.position = position
	var mesh := MeshInstance3D.new(); var shape := BoxMesh.new(); shape.size = size; mesh.mesh = shape; mesh.material_override = material; root.add_child(mesh)
	if collides:
		var collider := CollisionShape3D.new(); var box_shape := BoxShape3D.new(); box_shape.size = size; collider.shape = box_shape; root.add_child(collider)
	add_child(root); return root

func _label(value: String, position: Vector3, rotation: Vector3) -> void:
	var label := Label3D.new(); label.text = value; label.position = position; label.rotation = rotation; label.font_size = 32; label.pixel_size = 0.0016; label.modulate = Color(0.65, 0.74, 0.69, 0.82); add_child(label)
