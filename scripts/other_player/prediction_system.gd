class_name PredictionSystem
extends RefCounted

var current: Dictionary = {}
var history: Array[Dictionary] = []
var correct := 0
var evaluated := 0

func issue(type: StringName, target: StringName, certainty: float, lifetime: float, now: float, source := "baseline", reason := "Limited observations") -> Dictionary:
	if current.get("result", "") == "pending":
		current.result = "superseded"; _sync()
	current = {"type": String(type), "target": String(target), "confidence": clampf(certainty, 0.1, 0.85), "source": source, "reason": reason, "issued": now, "expiry": now + lifetime, "expected_time_window": lifetime, "result": "pending", "actual_action": "", "actual_target": "", "resolution_time": -1.0}
	history.append(current.duplicate(true))
	return current

func issue_for_context(context: StringName, memory: BehaviourMemory, now: float) -> Dictionary:
	if context == &"door_unlocked":
		var door_habit := memory.confidence_for(&"DOOR_RECHECK", &"", now)
		var terminal_habit := memory.confidence_for(&"TERMINAL_RETURN", &"", now)
		if terminal_habit > door_habit and terminal_habit >= 0.38:
			return issue(&"returned_to_terminal", &"terminal_a", 0.2 + terminal_habit * 0.55, 40.0, now, "TERMINAL_RETURN", "Repeated terminal returns")
		return issue(&"interact", &"door_a", 0.35 + door_habit * 0.5, 40.0, now, "DOOR_RECHECK" if door_habit >= 0.38 else "baseline", "Checks locked doors again" if door_habit >= 0.38 else "Door has just unlocked")
	if context == &"power_request":
		var fast := memory.confidence_for(&"FAST_COOPERATOR", &"", now)
		var explore := memory.confidence_for(&"OPTIONAL_EXPLORER", &"", now)
		var wait := memory.confidence_for(&"WAIT_FOR_PARTNER", &"", now)
		if explore >= 0.38 and explore > fast: return issue(&"unrelated_interaction", &"diagnostic_panel", 0.22 + explore * 0.5, 35.0, now, "OPTIONAL_EXPLORER", "Inspects optional equipment before helping")
		if wait >= 0.38 and wait > fast: return issue(&"waited_for_partner", &"east_power", 0.2 + wait * 0.5, 25.0, now, "WAIT_FOR_PARTNER", "Usually waits for remote help")
		return issue(&"interact", &"east_power", 0.34 + fast * 0.48, 75.0, now, "FAST_COOPERATOR" if fast >= 0.38 else "baseline", "Prompt response to instruction" if fast >= 0.38 else "Requested circuit is nearby")
	return {}

func observe(type: StringName, target: StringName, now: float) -> bool:
	if current.is_empty() or current.get("result") != "pending" or now > float(current.get("expiry", 0.0)): return false
	var matched: bool = current.get("type") == String(type) and current.get("target") == String(target)
	if not matched and type not in [&"interact", &"unrelated_interaction", &"returned_to_terminal", &"waited_for_partner"]: return false
	current.result = "correct" if matched else "incorrect"; current.actual_action = String(type); current.actual_target = String(target); current.resolution_time = now; evaluated += 1
	if matched: correct += 1
	_sync(); return matched

func expire(now: float) -> void:
	if not current.is_empty() and current.get("result") == "pending" and now > float(current.get("expiry", 0.0)):
		current.result = "expired"; current.resolution_time = now; evaluated += 1; _sync()

func _sync() -> void:
	if not history.is_empty(): history[history.size() - 1] = current.duplicate(true)
func accuracy() -> float: return float(correct) / float(evaluated) if evaluated > 0 else 0.0
func to_dict() -> Dictionary: return {"current": current.duplicate(true), "history": history.duplicate(true), "correct": correct, "evaluated": evaluated}
func load_dict(data: Dictionary) -> void: current = data.get("current", {}).duplicate(true); history.assign(data.get("history", [])); correct = int(data.get("correct", 0)); evaluated = int(data.get("evaluated", 0))
