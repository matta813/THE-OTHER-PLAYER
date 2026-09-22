class_name ElectronicDoor
extends Interactable
@export var locked := true; @export var open_angle := -92.0; @export var motion_speed := 3.2
var opened := false; var target_angle := 0.0
func _process(delta: float) -> void:
	rotation.y = lerp_angle(rotation.y, deg_to_rad(target_angle), clampf(delta * motion_speed, 0.0, 1.0)); set_process(absf(rotation.y - deg_to_rad(target_angle)) > 0.002)
func prompt_text(actor: Node) -> String: return "LOCKED // REMOTE CONTROL" if locked else super.prompt_text(actor)
func _perform_interaction(_actor: Node) -> void:
	if locked:
		GameRuntime.behaviour.record(&"interaction_retried", global_position, stable_id, &"locked_door"); return
	GameRuntime.predictions.observe(&"interact", stable_id, Time.get_unix_time_from_system())
	opened = not opened; target_angle = open_angle if opened else 0.0; set_process(true); GameRuntime.behaviour.record(&"door_opened", global_position, stable_id); state_changed.emit()
func remote_action(action: StringName, _payload: Dictionary = {}) -> bool:
	if action == &"unlock":
		locked = false; available = true; state_changed.emit(); var audio := get_node_or_null("Audio") as FacilityAudioEmitter
		if audio: audio.play_remote()
		return true
	if action == &"lock": locked = true; state_changed.emit(); return true
	if action == &"open" and not locked: opened = true; target_angle = open_angle; set_process(true); return true
	return false
func state_dict() -> Dictionary: return {"locked": locked, "opened": opened, "angle": target_angle}
func load_state(data: Dictionary) -> void: locked = data.get("locked", true); opened = data.get("opened", false); target_angle = data.get("angle", open_angle if opened else 0.0); rotation.y = deg_to_rad(target_angle); set_process(false)
