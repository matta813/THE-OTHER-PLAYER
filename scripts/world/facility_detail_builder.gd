extends Node3D

var concrete := preload("res://assets/materials/painted_concrete.tres")
var metal := preload("res://assets/materials/industrial_metal.tres")
var floor_material := preload("res://assets/materials/facility_floor.tres")
var rubber := preload("res://assets/materials/dark_rubber.tres")

func _ready() -> void:
	# Room dividers leave a narrow service corridor and provide readable thresholds.
	box("RoomARear", Vector3(0, 1.7, 7.4), Vector3(8, 3.4, 0.25), concrete, true)
	box("DividerL", Vector3(-2.675, 1.7, -2.0), Vector3(2.65, 3.4, 0.28), concrete, true)
	box("DividerR", Vector3(2.675, 1.7, -2.0), Vector3(2.65, 3.4, 0.28), concrete, true)
	box("RoomBRear", Vector3(0, 1.7, -13.8), Vector3(8, 3.4, 0.25), concrete, true)
	# Door frame, ceiling beams, cable trays, pipes, equipment plinths.
	for x in [-1.35, 1.35]: box("DoorFrame", Vector3(x, 1.55, -1.88), Vector3(0.22, 3.1, 0.38), metal, true)
	box("DoorLintel", Vector3(0, 3.05, -1.88), Vector3(2.92, 0.22, 0.38), metal, true)
	for z in [-5.0, -8.0, -11.0]: box("CeilingBeam", Vector3(0, 3.2, z), Vector3(7.5, 0.16, 0.22), metal, false)
	box("CableTray", Vector3(-3.35, 2.8, -7.5), Vector3(0.32, 0.16, 10.5), metal, false)
	for x in [-3.55, -3.2]: pipe(Vector3(x, 2.35, -7.5), 0.07, 10.5)
	box("RoomAInset", Vector3(0, 0.13, 3.0), Vector3(7.2, 0.06, 7.5), floor_material, false)
	box("RoomBInset", Vector3(0, 0.13, -9.8), Vector3(7.2, 0.06, 7.2), floor_material, false)
	box("EquipmentCabinet", Vector3(3.25, 1.0, -11.7), Vector3(1.1, 2.0, 0.7), metal, false)
	box("Vent", Vector3(0, 3.28, -9.5), Vector3(1.4, 0.12, 0.75), rubber, false)
	# Architectural rhythm: protective skirting, wall ribs and inset service panels.
	for z in [5.8, 3.5, 1.2, -3.7, -6.2, -8.7, -11.2, -13.0]:
		box("WallRibL", Vector3(-3.78, 1.65, z), Vector3(0.16, 3.25, 0.12), metal, false)
		box("WallRibR", Vector3(3.78, 1.65, z), Vector3(0.16, 3.25, 0.12), metal, false)
	box("SkirtingL", Vector3(-3.79, 0.28, -3.2), Vector3(0.12, 0.42, 21.0), rubber, false)
	box("SkirtingR", Vector3(3.79, 0.28, -3.2), Vector3(0.12, 0.42, 21.0), rubber, false)
	for z in [4.0, -4.8, -9.5]:
		box("LightHousing", Vector3(0, 3.28, z), Vector3(2.3, 0.16, 0.55), metal, false)
		box("LightDiffuser", Vector3(0, 3.18, z), Vector3(1.85, 0.035, 0.34), preload("res://assets/materials/monitor_glow.tres"), false)
	box("SafetyStripe", Vector3(0, 0.16, -2.15), Vector3(2.8, 0.025, 0.22), preload("res://assets/materials/hazard_yellow.tres"), false)
	label("ROOM A  //  LINK BAY", Vector3(-3.72, 2.25, 3.8), Vector3(0, PI / 2.0, 0))
	label("SERVICE 02", Vector3(3.72, 2.25, -5.2), Vector3(0, -PI / 2.0, 0))
	label("EAST POWER", Vector3(3.72, 2.1, -9.0), Vector3(0, -PI / 2.0, 0))

func box(node_name: String, position: Vector3, size: Vector3, material: Material, collision: bool) -> void:
	var root: Node3D = StaticBody3D.new() if collision else Node3D.new(); root.name = node_name; root.position = position; add_child(root)
	var mesh := MeshInstance3D.new(); var shape := BoxMesh.new(); shape.size = size; mesh.mesh = shape; mesh.material_override = material; root.add_child(mesh)
	if collision:
		var collider := CollisionShape3D.new(); var box_shape := BoxShape3D.new(); box_shape.size = size; collider.shape = box_shape; root.add_child(collider)

func pipe(position: Vector3, radius: float, length: float) -> void:
	var mesh := MeshInstance3D.new(); var cylinder := CylinderMesh.new(); cylinder.top_radius = radius; cylinder.bottom_radius = radius; cylinder.height = length; mesh.mesh = cylinder; mesh.material_override = metal; mesh.position = position; mesh.rotation.x = PI / 2.0; add_child(mesh)

func label(text: String, position: Vector3, rotation: Vector3) -> void:
	var node := Label3D.new(); node.text = text; node.position = position; node.rotation = rotation; node.font_size = 48; node.pixel_size = 0.004; node.modulate = Color(0.62, 0.68, 0.62, 0.72); node.outline_size = 4; add_child(node)
