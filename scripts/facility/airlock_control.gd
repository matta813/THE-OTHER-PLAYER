class_name AirlockControl
extends Interactable

signal cycle_requested
var airlock: AirlockSystem

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
