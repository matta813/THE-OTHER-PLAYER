class_name FacilityActionPoint
extends Interactable

signal activated(action_id: StringName)
@export var action_id: StringName = &""
var activated_once := false

func _perform_interaction(_actor: Node) -> void:
	activated.emit(action_id)
	activated_once = true
	state_changed.emit()

func state_dict() -> Dictionary: return {"activated_once": activated_once, "available": available}
func load_state(data: Dictionary) -> void:
	activated_once = bool(data.get("activated_once", false))
	available = bool(data.get("available", available))
	state_changed.emit()
