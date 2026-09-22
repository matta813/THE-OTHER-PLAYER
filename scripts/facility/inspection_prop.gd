class_name InspectionProp
extends Interactable
signal inspected_text(value: String)
@export var observation_text := "Nothing unusual."
var inspected := false
func _perform_interaction(_actor: Node) -> void:
	GameRuntime.behaviour.record(&"unrelated_interaction", global_position, stable_id, &"inspection", -1.0, {"repeat": inspected}); inspected = true; inspected_text.emit(observation_text); state_changed.emit()
func prompt_text(actor: Node) -> String: return super.prompt_text(actor) if not inspected else "[E] Inspect again"
func state_dict() -> Dictionary: return {"inspected": inspected}
func load_state(data: Dictionary) -> void: inspected = data.get("inspected", false)
