class_name PowerSwitch
extends Interactable
signal power_changed(powered: bool)
var powered := false
func _perform_interaction(_actor: Node) -> void:
	if powered: GameRuntime.behaviour.record(&"unnecessary_toggle", global_position, stable_id); return
	powered = true; _move_lever(true); state_changed.emit()
	var response := GameRuntime.playtime - float(get_meta("requested_at", GameRuntime.playtime)); GameRuntime.behaviour.record(&"instruction_completed", global_position, stable_id, &"power_request", response); GameRuntime.trust.player_response(response, true); GameRuntime.predictions.observe(&"interact", stable_id, Time.get_unix_time_from_system())
	power_changed.emit(true)
func prompt_text(actor: Node) -> String: return "CIRCUIT ENABLED" if powered else super.prompt_text(actor)
func state_dict() -> Dictionary:
	var elapsed := GameRuntime.playtime - float(get_meta("requested_at", GameRuntime.playtime))
	return {"powered": powered, "request_elapsed": maxf(elapsed, 0.0)}
func load_state(data: Dictionary) -> void:
	powered = data.get("powered", false); set_meta("requested_at", GameRuntime.playtime - float(data.get("request_elapsed", 0.0))); _move_lever(false); state_changed.emit()

func _move_lever(animate: bool) -> void:
	var lever := get_node_or_null("Lever") as Node3D
	if lever == null: return
	var angle := deg_to_rad(-28.0 if powered else 18.0)
	if animate:
		var tween := create_tween()
		tween.tween_property(lever, "rotation:x", angle, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else: lever.rotation.x = angle
