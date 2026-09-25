class_name CircuitBreaker
extends Interactable

@export var circuit_id: StringName = &""
var grid: ChapterPowerGrid
var handle: Node3D
var handle_tween: Tween

func _ready() -> void:
	super._ready()
	handle = Node3D.new(); handle.name = "Handle"; handle.position = Vector3(0, 0, 0.14); add_child(handle)
	var lever := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size = Vector3(0.075, 0.30, 0.095); lever.mesh = mesh
	lever.material_override = preload("res://assets/materials/industrial_metal.tres")
	handle.add_child(lever)

func _perform_interaction(_actor: Node) -> void:
	if grid == null: return
	var next := not grid.is_powered(circuit_id)
	if not grid.set_circuit(circuit_id, next):
		GameRuntime.behaviour.record(&"circuit_overload_attempt", global_position, stable_id, &"power_budget")
		return
	GameRuntime.behaviour.record(&"circuit_toggled", global_position, stable_id, &"power_budget", -1.0, {"circuit": String(circuit_id), "enabled": next, "demand": grid.demand()})
	_set_handle(next, true)
	state_changed.emit()

func _set_handle(enabled: bool, animate: bool) -> void:
	if handle == null: return
	if handle_tween and handle_tween.is_running(): handle_tween.kill()
	var angle := deg_to_rad(-24.0 if enabled else 24.0)
	if animate:
		handle_tween = create_tween()
		handle_tween.tween_property(handle, "rotation:x", angle, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else: handle.rotation.x = angle

func prompt_text(_actor: Node) -> String:
	if grid == null: return "BREAKER OFFLINE"
	return "[E] %s // %s (%d/%d)" % [String(circuit_id).to_upper(), "ON" if grid.is_powered(circuit_id) else "OFF", grid.demand(), ChapterPowerGrid.CAPACITY]

func state_dict() -> Dictionary: return {"circuit_id": String(circuit_id)}
func load_state(_data: Dictionary) -> void:
	if grid: _set_handle(grid.is_powered(circuit_id), false)
	state_changed.emit()
