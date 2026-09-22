class_name ChapterPowerGrid
extends RefCounted

signal circuit_changed(circuit: StringName, enabled: bool)
const CAPACITY := 10
const COSTS := {"security": 3, "door_controls": 2, "ventilation": 3, "generator_starter": 5}
var circuits := {"security": true, "door_controls": true, "ventilation": true, "generator_starter": false}

func demand() -> int:
	var total := 0
	for key in COSTS:
		if bool(circuits.get(key, false)): total += int(COSTS[key])
	return total

func can_enable(circuit: StringName) -> bool:
	var key := String(circuit)
	return COSTS.has(key) and (bool(circuits.get(key, false)) or demand() + int(COSTS[key]) <= CAPACITY)

func set_circuit(circuit: StringName, enabled: bool) -> bool:
	var key := String(circuit)
	if not COSTS.has(key): return false
	if enabled and not can_enable(circuit): return false
	if bool(circuits[key]) == enabled: return true
	circuits[key] = enabled
	circuit_changed.emit(circuit, enabled)
	return true

func is_powered(circuit: StringName) -> bool: return bool(circuits.get(String(circuit), false))
func to_dict() -> Dictionary: return {"circuits": circuits.duplicate(true)}
func load_dict(data: Dictionary) -> void:
	var requested: Dictionary = data.get("circuits", {})
	for key in COSTS: circuits[key] = bool(requested.get(key, circuits[key]))
	if demand() > CAPACITY: circuits["generator_starter"] = false
	for key in COSTS: circuit_changed.emit(StringName(key), bool(circuits[key]))
