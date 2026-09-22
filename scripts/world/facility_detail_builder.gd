extends Node3D

var concrete := preload("res://assets/materials/painted_concrete.tres")
var metal := preload("res://assets/materials/industrial_metal.tres")
var floor_material := preload("res://assets/materials/facility_floor.tres")
var rubber := preload("res://assets/materials/dark_rubber.tres")
var bare_concrete := preload("res://assets/materials/bare_concrete.tres")
var hazard := preload("res://assets/materials/hazard_yellow.tres")
var luminaire := preload("res://assets/materials/luminaire_diffuser.tres")
var east_diffuser: MeshInstance3D

func _ready() -> void:
	# Room dividers leave a narrow service corridor and provide readable thresholds.
	box("RoomARear", Vector3(0, 1.7, 7.4), Vector3(8, 3.4, 0.25), concrete, true)
	box("DividerL", Vector3(-2.675, 1.7, -2.0), Vector3(2.65, 3.4, 0.28), concrete, true)
	box("DividerR", Vector3(2.675, 1.7, -2.0), Vector3(2.65, 3.4, 0.28), concrete, true)
	box("RoomBRear", Vector3(0, 1.7, -13.8), Vector3(8, 3.4, 0.25), concrete, true)
	for side in [-1.0, 1.0]:
		box("RoomBThresholdWall", Vector3(side * 2.7, 1.68, -7.0), Vector3(2.6, 3.36, 0.23), concrete, true)
	box("RoomBThresholdHeader", Vector3(0, 3.12, -7.0), Vector3(2.8, 0.3, 0.26), metal, true)
	# Door frame, ceiling beams, cable trays, pipes, equipment plinths.
	for x in [-1.35, 1.35]: box("DoorFrame", Vector3(x, 1.55, -1.88), Vector3(0.22, 3.1, 0.38), metal, true)
	box("DoorLintel", Vector3(0, 3.05, -1.88), Vector3(2.92, 0.22, 0.38), metal, true)
	for z in [-5.0, -8.0, -11.0]: box("CeilingBeam", Vector3(0, 3.2, z), Vector3(7.5, 0.16, 0.22), metal, false)
	box("CableTray", Vector3(-3.35, 2.8, -7.5), Vector3(0.32, 0.16, 10.5), metal, false)
	for x in [-3.55, -3.2]: pipe(Vector3(x, 2.35, -7.5), 0.07, 10.5)
	box("RoomAInset", Vector3(0, 0.13, 3.0), Vector3(7.2, 0.06, 7.5), floor_material, false)
	box("RoomBInset", Vector3(0, 0.13, -9.8), Vector3(7.2, 0.06, 7.2), floor_material, false)
	box("EquipmentCabinet", Vector3(3.15, 1.02, -11.7), Vector3(1.18, 2.04, 0.72), metal, true)
	box("CabinetDoor", Vector3(3.15, 1.08, -11.32), Vector3(1.02, 1.82, 0.045), concrete, false)
	box("CabinetSeam", Vector3(3.15, 1.08, -11.29), Vector3(0.018, 1.78, 0.02), rubber, false)
	for y in [0.55, 0.62, 0.69, 0.76]: box("CabinetVent", Vector3(3.15, y, -11.285), Vector3(0.68, 0.018, 0.016), rubber, false)
	box("CabinetHandle", Vector3(3.54, 1.3, -11.25), Vector3(0.045, 0.3, 0.06), metal, false)
	box("VentFrame", Vector3(0, 3.25, -9.5), Vector3(1.55, 0.16, 0.82), metal, false)
	for offset in [-0.4, -0.2, 0.0, 0.2, 0.4]: box("VentLouver", Vector3(offset, 3.16, -9.5), Vector3(0.06, 0.025, 0.68), rubber, false)
	# Architectural rhythm: protective skirting, wall ribs and inset service panels.
	for z in [5.8, 3.5, 1.2, -3.7, -6.2, -8.7, -11.2, -13.0]:
		box("WallRibL", Vector3(-3.78, 1.65, z), Vector3(0.16, 3.25, 0.12), metal, false)
		box("WallRibR", Vector3(3.78, 1.65, z), Vector3(0.16, 3.25, 0.12), metal, false)
	for z in [4.7, 2.4, -4.8, -9.9, -12.0]:
		box("WallServicePanelL", Vector3(-3.75, 1.25, z), Vector3(0.08, 1.6, 1.34), bare_concrete, false)
		box("WallServicePanelR", Vector3(3.75, 1.25, z), Vector3(0.08, 1.6, 1.34), bare_concrete, false)
		for y in [0.53, 1.97]:
			box("PanelFastenerL", Vector3(-3.68, y, z - 0.58), Vector3(0.018, 0.045, 0.045), metal, false)
			box("PanelFastenerR", Vector3(3.68, y, z + 0.58), Vector3(0.018, 0.045, 0.045), metal, false)
	box("SkirtingL", Vector3(-3.79, 0.28, -3.2), Vector3(0.12, 0.42, 21.0), rubber, false)
	box("SkirtingR", Vector3(3.79, 0.28, -3.2), Vector3(0.12, 0.42, 21.0), rubber, false)
	for z in [3.0, -4.8, -9.5]:
		box("LightHousing", Vector3(0, 3.28, z), Vector3(2.3, 0.16, 0.55), metal, false)
		var light_assembly := box("LightDiffuser", Vector3(0, 3.18, z), Vector3(1.85, 0.035, 0.34), rubber if z == -9.5 else luminaire, false)
		if z == -9.5: east_diffuser = light_assembly.get_node("Mesh") as MeshInstance3D
		for x in [-1.05, 1.05]: box("LuminaireBracket", Vector3(x, 3.26, z), Vector3(0.08, 0.28, 0.68), metal, false)
	for z in [5.1, 2.6, -1.1, -4.0, -6.0, -8.5, -11.0, -13.0]:
		box("FloorExpansionJoint", Vector3(0, 0.164, z), Vector3(7.2, 0.008, 0.024), rubber, false)
	box("DrainChannel", Vector3(3.15, 0.165, -9.9), Vector3(0.36, 0.015, 6.2), metal, false)
	for z in [-12.55, -11.8, -11.05, -10.3, -9.55, -8.8, -8.05]:
		box("DrainSlot", Vector3(3.15, 0.176, z), Vector3(0.26, 0.006, 0.055), rubber, false)
	for z in [-1.64, -2.32, -6.68, -7.32]:
		box("ThresholdMark", Vector3(0, 0.17, z), Vector3(2.75, 0.015, 0.07), hazard, false)
	box("UpperDuct", Vector3(3.3, 3.06, -8.0), Vector3(0.62, 0.48, 10.6), metal, false)
	for z in [-4.0, -6.0, -8.0, -10.0, -12.0]: box("DuctBand", Vector3(3.3, 3.06, z), Vector3(0.69, 0.52, 0.07), rubber, false)
	box("TerminalStand", Vector3(-2.8, 0.43, -0.72), Vector3(0.96, 0.86, 0.62), metal, true)
	box("TerminalKeybed", Vector3(-2.8, 0.78, 0.02), Vector3(0.84, 0.08, 0.48), rubber, false)
	for key in range(7): box("TerminalKey", Vector3(-3.13 + key * 0.11, 0.827, 0.1), Vector3(0.07, 0.015, 0.08), metal, false)
	box("TerminalCable", Vector3(-3.38, 1.6, -0.65), Vector3(0.06, 2.8, 0.06), rubber, false)
	box("BreakerBackplate", Vector3(2.8, 1.0, -9.2), Vector3(0.72, 1.12, 0.13), rubber, false)
	box("BreakerLabel", Vector3(2.8, 1.57, -8.98), Vector3(0.57, 0.16, 0.03), hazard, false)
	for x in [-1.28, 1.28]: box("DoorGasketSide", Vector3(x, 1.36, -1.85), Vector3(0.07, 2.84, 0.035), rubber, false)
	box("DoorGasketTop", Vector3(0, 2.78, -1.85), Vector3(2.62, 0.07, 0.035), rubber, false)
	box("DoorControlPlate", Vector3(1.56, 1.5, -1.81), Vector3(0.24, 0.4, 0.08), metal, false)
	box("DoorControlLamp", Vector3(1.56, 1.63, -1.75), Vector3(0.06, 0.06, 0.02), hazard, false)
	label("ROOM A  //  LINK BAY", Vector3(-3.72, 2.25, 3.8), Vector3(0, PI / 2.0, 0))
	label("SERVICE 02", Vector3(3.72, 2.25, -5.2), Vector3(0, -PI / 2.0, 0))
	label("EAST POWER", Vector3(3.72, 2.1, -9.0), Vector3(0, -PI / 2.0, 0))
	label("02 / EAST CIRCUIT", Vector3(0, 2.65, -6.82), Vector3.ZERO)

func box(node_name: String, position: Vector3, size: Vector3, material: Material, collision: bool) -> Node3D:
	var root: Node3D = StaticBody3D.new() if collision else Node3D.new(); root.name = node_name; root.position = position; add_child(root)
	var mesh := MeshInstance3D.new(); mesh.name = "Mesh"; var shape := BoxMesh.new(); shape.size = size; mesh.mesh = shape; mesh.material_override = material; root.add_child(mesh)
	if collision:
		var collider := CollisionShape3D.new(); var box_shape := BoxShape3D.new(); box_shape.size = size; collider.shape = box_shape; root.add_child(collider)
	return root

func set_east_power(powered: bool) -> void:
	if east_diffuser: east_diffuser.material_override = luminaire if powered else rubber

func pipe(position: Vector3, radius: float, length: float) -> void:
	var mesh := MeshInstance3D.new(); var cylinder := CylinderMesh.new(); cylinder.top_radius = radius; cylinder.bottom_radius = radius; cylinder.height = length; mesh.mesh = cylinder; mesh.material_override = metal; mesh.position = position; mesh.rotation.x = PI / 2.0; add_child(mesh)

func label(text: String, position: Vector3, rotation: Vector3) -> void:
	var node := Label3D.new(); node.text = text; node.position = position; node.rotation = rotation; node.font_size = 38; node.pixel_size = 0.0018; node.modulate = Color(0.64, 0.7, 0.65, 0.78); node.outline_size = 3; add_child(node)
