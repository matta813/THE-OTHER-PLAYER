class_name PowerSwitch
extends Interactable
signal power_changed(powered: bool)
var powered := false
func _perform_interaction(_actor: Node) -> void:
	if powered: GameRuntime.behaviour.record(&"unnecessary_toggle", global_position, stable_id); return
	powered = true; rotation.z = deg_to_rad(22); state_changed.emit()
	var response := Time.get_ticks_msec() / 1000.0 - float(get_meta("requested_at", Time.get_ticks_msec() / 1000.0)); GameRuntime.behaviour.record(&"instruction_completed", global_position, stable_id, &"power_request", response); GameRuntime.trust.player_response(response, true); GameRuntime.predictions.observe(&"interact", stable_id, Time.get_unix_time_from_system())
	power_changed.emit(true)
func prompt_text(actor: Node) -> String: return "CIRCUIT ENABLED" if powered else super.prompt_text(actor)
func state_dict() -> Dictionary:
	var elapsed := Time.get_ticks_msec() / 1000.0 - float(get_meta("requested_at", Time.get_ticks_msec() / 1000.0))
	return {"powered": powered, "request_elapsed": maxf(elapsed, 0.0)}
func load_state(data: Dictionary) -> void:
	powered = data.get("powered", false); set_meta("requested_at", Time.get_ticks_msec() / 1000.0 - float(data.get("request_elapsed", 0.0))); rotation.z = deg_to_rad(22 if powered else 0); state_changed.emit()
