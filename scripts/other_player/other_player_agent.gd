class_name OtherPlayerAgent
extends Node
signal task_changed(task: String)
signal action_due(action: StringName, target: StringName, payload: Dictionary)
var current_task := "Idle"; var scheduled: Array[Dictionary] = []; var memory: Dictionary = {"help_count": 0, "last_player_response": -1.0, "anticipated_light": false}; var simulated_activity := 0.15
func _ready() -> void: set_process(not scheduled.is_empty())
func schedule(action: StringName, target: StringName, complexity: float, payload := {}) -> float:
	var trust: float = GameRuntime.trust.other_player_confidence_in_player; var hesitation: float = GameRuntime.behaviour.model.metrics.get(&"hesitation", 0.5); var variation := float(abs(hash("%s:%s:%d" % [action, target, GameRuntime.behaviour.events.size()])) % 1000) / 1000.0
	var delay := maxf(0.45, 0.65 + complexity * 3.4 + hesitation * 0.8 + simulated_activity * 1.2 + variation * 0.9 - trust * 0.35 + float(payload.get("delay_bias", 0.0)))
	scheduled.append({"action": action, "target": target, "payload": payload, "due": now() + delay}); current_task = payload.get("task", "Working remotely"); task_changed.emit(current_task); set_process(true); return delay
func _process(_delta: float) -> void:
	while not scheduled.is_empty():
		var earliest := 0
		for index in range(1, scheduled.size()):
			if float(scheduled[index].due) < float(scheduled[earliest].due): earliest = index
		var item: Dictionary = scheduled[earliest]
		if now() < float(item.due): break
		scheduled.remove_at(earliest)
		action_due.emit(item.action, item.target, item.payload)
	if scheduled.is_empty(): _set_idle()
func now() -> float: return Time.get_ticks_msec() / 1000.0
func cancel_action(action: StringName, target: StringName = &"") -> void:
	for index in range(scheduled.size() - 1, -1, -1):
		if scheduled[index].action == action and (target == &"" or scheduled[index].target == target): scheduled.remove_at(index)
	if scheduled.is_empty(): _set_idle()
func delay_action(action: StringName, target: StringName, extra_seconds: float) -> bool:
	for index in scheduled.size():
		if scheduled[index].action == action and scheduled[index].target == target:
			scheduled[index].due = float(scheduled[index].due) + maxf(extra_seconds, 0.0)
			return true
	return false
func to_dict() -> Dictionary:
	var pending: Array[Dictionary] = []
	for item in scheduled:
		var saved := item.duplicate(true); saved["remaining"] = maxf(float(item.due) - now(), 0.0); saved.erase("due"); pending.append(saved)
	return {"current_task": current_task, "scheduled": pending, "memory": memory.duplicate(true), "simulated_activity": simulated_activity}
func load_dict(data: Dictionary) -> void:
	current_task = data.get("current_task", "Listening"); scheduled.clear()
	for value in data.get("scheduled", []):
		var item: Dictionary = value.duplicate(true); item["due"] = now() + float(item.get("remaining", 0.0)); item.erase("remaining"); scheduled.append(item)
	memory = data.get("memory", memory).duplicate(true); simulated_activity = data.get("simulated_activity", 0.15)
	set_process(not scheduled.is_empty())
	if scheduled.is_empty(): _set_idle()
func _set_idle() -> void:
	set_process(false)
	if current_task != "Listening": current_task = "Listening"; task_changed.emit(current_task)
