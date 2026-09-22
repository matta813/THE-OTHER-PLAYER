class_name SuspicionModel
extends RefCounted
var value := 0.08
var causes: Array[Dictionary] = []
const WEIGHTS := {"returned_to_terminal": 0.045, "door_rechecked": 0.025, "instruction_delayed": 0.025, "waited_for_partner": 0.018, "hesitated_at_threshold": 0.018, "expectation_violated": 0.09, "tested_partner": 0.12}

func observe(event: BehaviourEvent) -> void:
	var weight: float = WEIGHTS.get(String(event.event_type), 0.0)
	if weight > 0.0: change(weight, String(event.event_type), event.timestamp)

func change(amount: float, cause: String, when: float) -> void:
	value = clampf(value + amount, 0.0, 1.0)
	causes.append({"cause": cause, "amount": amount, "time": when})
	if causes.size() > 12: causes.pop_front()

func reassure(when: float) -> void: change(-0.09, "reliable help", when)
func to_dict() -> Dictionary: return {"value": value, "causes": causes.duplicate(true)}
func load_dict(data: Dictionary) -> void: value = clampf(float(data.get("value", 0.08)), 0.0, 1.0); causes.assign(data.get("causes", []))
