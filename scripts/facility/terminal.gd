class_name FacilityTerminal
extends Interactable
signal terminal_used
@export_multiline var text := "LINK STATUS: STANDBY"
var history: Array[String] = []
func _perform_interaction(_actor: Node) -> void: terminal_used.emit()
func append_line(line: String) -> void:
	history.append(line)
	if history.size() > 8: history.pop_front()
	text = "\n".join(history); state_changed.emit()
func remote_action(action: StringName, payload: Dictionary = {}) -> bool:
	if action == &"display_text": append_line(payload.get("text", "")); return true
	return false
func state_dict() -> Dictionary: return {"history": history.duplicate(), "text": text}
func load_state(data: Dictionary) -> void: history.assign(data.get("history", [])); text = data.get("text", text); state_changed.emit()
