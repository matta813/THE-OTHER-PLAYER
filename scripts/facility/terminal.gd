class_name FacilityTerminal
extends Interactable
signal terminal_used
@export_multiline var text := "LINK STATUS: STANDBY"
var history: Array[String] = []
func _ready() -> void:
	super._ready()
	_refresh_screen()
func _perform_interaction(_actor: Node) -> void: terminal_used.emit()
func append_line(line: String) -> void:
	history.append(line)
	if history.size() > 8: history.pop_front()
	text = "\n".join(history); _refresh_screen(); state_changed.emit()
func remote_action(action: StringName, payload: Dictionary = {}) -> bool:
	if action == &"display_text": append_line(payload.get("text", "")); return true
	return false
func state_dict() -> Dictionary: return {"history": history.duplicate(), "text": text}
func load_state(data: Dictionary) -> void: history.assign(data.get("history", [])); text = data.get("text", text); _refresh_screen(); state_changed.emit()
func _refresh_screen() -> void:
	var screen := get_node_or_null("ScreenText") as Label3D
	if screen:
		screen.text = "LINK 02\n%s" % history[-1].to_upper().substr(0, 12) if not history.is_empty() else "LINK 02\nSTANDBY"
