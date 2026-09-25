class_name ProductionKit
extends RefCounted

const ENVIRONMENT := "res://assets/models/environment/"
const PROPS := "res://assets/models/props/"
static var scenes: Dictionary = {}

static func add_visual(parent: Node3D, name: String, position: Vector3 = Vector3.ZERO, rotation: Vector3 = Vector3.ZERO, scale: Vector3 = Vector3.ONE) -> Node3D:
	var category := PROPS if name in ["electrical_cabinet", "breaker_panel", "equipment_rack", "terminal_housing", "security_camera_housing", "security_console", "transfer_hatch", "airlock_door", "generator_control_unit"] else ENVIRONMENT
	var path := category + name + ".glb"
	if not scenes.has(path): scenes[path] = load(path)
	var packed := scenes[path] as PackedScene
	if packed == null: return null
	var visual := packed.instantiate() as Node3D
	visual.name = "Kit_" + name
	parent.add_child(visual)
	visual.position = position
	visual.rotation = rotation
	visual.scale = scale
	return visual
