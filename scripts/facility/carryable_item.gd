class_name CarryableItem
extends Interactable

@export var item_id: StringName = &""
var collected := false

func _perform_interaction(actor: Node) -> void:
	if collected or not actor.has_method("give_item"): return
	if actor.give_item(item_id):
		collected = true
		visible = false
		collision_layer = 0
		GameRuntime.behaviour.record(&"item_collected", global_position, stable_id, &"chapter", -1.0, {"item_id": String(item_id)})
		state_changed.emit()

func prompt_text(actor: Node) -> String:
	if collected: return ""
	return "HANDS FULL" if actor.has_method("has_carried_item") and actor.has_carried_item() else super.prompt_text(actor)

func state_dict() -> Dictionary: return {"collected": collected}
func load_state(data: Dictionary) -> void:
	collected = bool(data.get("collected", false)); visible = not collected; collision_layer = 0 if collected else 2; state_changed.emit()
