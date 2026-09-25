class_name AirlockControl
extends Interactable

signal cycle_requested
var airlock: AirlockSystem
var selector: Node3D
var selector_home := 0.0
var selector_tween: Tween

func _ready() -> void:
	super._ready()
	selector = find_child("VIS_airlock_cycle_panel_selector", true, false) as Node3D
	if selector: selector_home = selector.rotation.z
	state_changed.connect(_update_visual_state)

func can_interact(_actor: Node) -> bool:
	return available and airlock != null and airlock.phase == AirlockSystem.Phase.IDLE

func _update_visual_state() -> void:
	if selector == null: return
	if selector_tween and selector_tween.is_running(): selector_tween.kill()
	var active := airlock != null and airlock.phase != AirlockSystem.Phase.IDLE
	selector_tween = create_tween()
	selector_tween.tween_property(selector, "rotation:z", selector_home + (0.55 if active else 0.0), 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func _perform_interaction(_actor: Node) -> void:
	if airlock and airlock.request():
		GameRuntime.predictions.observe(&"interact", stable_id, Time.get_unix_time_from_system())
		cycle_requested.emit()
	state_changed.emit()

func prompt_text(_actor: Node) -> String:
	if not available: return unavailable_reason
	if airlock == null: return "AIRLOCK CONTROL OFFLINE"
	if airlock.phase == AirlockSystem.Phase.IDLE: return "[E] Request airlock cycle"
	return "AIRLOCK // %s" % AirlockSystem.Phase.keys()[airlock.phase]
