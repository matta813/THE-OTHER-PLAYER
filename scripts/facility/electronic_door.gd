class_name ElectronicDoor
extends Interactable

@export var locked := true
@export var open_angle := -92.0
@export var motion_duration := 1.15
@export var latch_delay := 0.16
var opened := false
var target_angle := 0.0
var powered := true
var motion_from := 0.0
var motion_elapsed := 0.0
var delay_remaining := 0.0
var motor_started := false

func _process(delta: float) -> void:
	if delay_remaining > 0.0:
		delay_remaining -= delta
		if delay_remaining > 0.0: return
	if not motor_started:
		motor_started = true
		var audio := get_node_or_null("Audio") as FacilityAudioEmitter
		if audio: audio.play_remote()
	motion_elapsed += delta
	var progress := clampf(motion_elapsed / maxf(motion_duration, 0.2), 0.0, 1.0)
	var eased := progress * progress * (3.0 - 2.0 * progress)
	rotation.y = lerp_angle(motion_from, deg_to_rad(target_angle), eased)
	if progress >= 1.0:
		rotation.y = deg_to_rad(target_angle)
		set_process(false)

func _begin_motion(angle: float) -> void:
	motion_from = rotation.y
	target_angle = angle
	motion_elapsed = 0.0
	delay_remaining = latch_delay
	motor_started = false
	set_process(true)

func prompt_text(actor: Node) -> String:
	return "NO POWER" if not powered else ("LOCKED // REMOTE CONTROL" if locked else super.prompt_text(actor))

func _perform_interaction(_actor: Node) -> void:
	if not powered:
		GameRuntime.behaviour.record(&"unavailable_interaction", global_position, stable_id, &"no_power")
		return
	if locked:
		GameRuntime.behaviour.record(&"interaction_retried", global_position, stable_id, &"locked_door")
		return
	GameRuntime.predictions.observe(&"interact", stable_id, Time.get_unix_time_from_system())
	opened = not opened
	_begin_motion(open_angle if opened else 0.0)
	GameRuntime.behaviour.record(&"door_opened", global_position, stable_id)
	state_changed.emit()

func remote_action(action: StringName, _payload: Dictionary = {}) -> bool:
	if action == &"power_on": powered = true; state_changed.emit(); return true
	if action == &"power_off": powered = false; state_changed.emit(); return true
	if not powered: return false
	if action == &"unlock":
		locked = false; available = true; state_changed.emit()
		var audio := get_node_or_null("Audio") as FacilityAudioEmitter
		if audio: audio.play_interaction()
		return true
	if action == &"lock": locked = true; state_changed.emit(); return true
	if action == &"open" and not locked: opened = true; _begin_motion(open_angle); return true
	if action == &"close": opened = false; _begin_motion(0.0); return true
	return false

func state_dict() -> Dictionary: return {"locked": locked, "opened": opened, "angle": target_angle, "powered": powered}
func load_state(data: Dictionary) -> void:
	locked = data.get("locked", true); opened = data.get("opened", false); powered = data.get("powered", true)
	target_angle = data.get("angle", open_angle if opened else 0.0)
	rotation.y = deg_to_rad(target_angle)
	motion_elapsed = 0.0; delay_remaining = 0.0; set_process(false)
	state_changed.emit()
