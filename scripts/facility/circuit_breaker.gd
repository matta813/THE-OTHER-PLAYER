class_name CircuitBreaker
extends Interactable

@export var circuit_id: StringName = &""
var grid: ChapterPowerGrid

func _perform_interaction(_actor: Node) -> void:
	if grid == null: return
	var next := not grid.is_powered(circuit_id)
	if not grid.set_circuit(circuit_id, next):
		GameRuntime.behaviour.record(&"circuit_overload_attempt", global_position, stable_id, &"power_budget")
		return
	GameRuntime.behaviour.record(&"circuit_toggled", global_position, stable_id, &"power_budget", -1.0, {"circuit": String(circuit_id), "enabled": next, "demand": grid.demand()})
	rotation.z = deg_to_rad(16.0 if next else -16.0)
	state_changed.emit()

func prompt_text(_actor: Node) -> String:
	if grid == null: return "BREAKER OFFLINE"
	return "[E] %s // %s (%d/%d)" % [String(circuit_id).to_upper(), "ON" if grid.is_powered(circuit_id) else "OFF", grid.demand(), ChapterPowerGrid.CAPACITY]

func state_dict() -> Dictionary: return {"circuit_id": String(circuit_id)}
func load_state(_data: Dictionary) -> void:
	if grid: rotation.z = deg_to_rad(16.0 if grid.is_powered(circuit_id) else -16.0)
	state_changed.emit()
