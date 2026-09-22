class_name PredictionSystem
extends RefCounted
var current: Dictionary = {}; var history: Array[Dictionary] = []; var correct := 0; var evaluated := 0
func issue(type: StringName, target: StringName, certainty: float, lifetime: float, now: float) -> Dictionary:
	current = {"type": String(type), "target": String(target), "confidence": clampf(certainty, 0.1, 0.85), "issued": now, "expiry": now + lifetime, "result": "pending"}; history.append(current.duplicate(true)); return current
func observe(type: StringName, target: StringName, now: float) -> bool:
	if current.is_empty() or current.get("result") != "pending" or now > float(current.get("expiry", 0.0)): return false
	var matched: bool = current.get("type") == String(type) and current.get("target") == String(target)
	if matched: current["result"] = "correct"; evaluated += 1; correct += 1; _sync()
	return matched
func expire(now: float) -> void:
	if not current.is_empty() and current.get("result") == "pending" and now > float(current.get("expiry", 0.0)): current["result"] = "expired"; evaluated += 1; _sync()
func _sync() -> void:
	if not history.is_empty(): history[history.size() - 1] = current.duplicate(true)
func accuracy() -> float: return float(correct) / float(evaluated) if evaluated > 0 else 0.0
func to_dict() -> Dictionary: return {"current": current.duplicate(true), "history": history.duplicate(true), "correct": correct, "evaluated": evaluated}
func load_dict(data: Dictionary) -> void: current = data.get("current", {}).duplicate(true); history.assign(data.get("history", [])); correct = data.get("correct", 0); evaluated = data.get("evaluated", 0)
