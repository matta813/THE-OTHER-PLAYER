class_name TransferHatch
extends Interactable

signal item_deposited(item_id: StringName)
signal hatch_sealed(item_id: StringName)
signal remote_received(item_id: StringName)
signal item_collected(item_id: StringName)
@export var accepted_item_id: StringName = &"fuse_35a"

enum HatchState {EMPTY, LOADED, TRANSIT, RETURN_READY}
var hatch_state := HatchState.EMPTY
var item_id: StringName = &""

func _perform_interaction(actor: Node) -> void:
	match hatch_state:
		HatchState.EMPTY:
			if not actor.has_method("take_carried_item"): return
			if accepted_item_id != &"" and actor.carried_item_id != accepted_item_id:
				GameRuntime.behaviour.record(&"wrong_item_attempted", global_position, stable_id, &"transfer")
				return
			var carried: StringName = actor.take_carried_item()
			if carried == &"": return
			item_id = carried; hatch_state = HatchState.LOADED
			item_deposited.emit(item_id)
			GameRuntime.behaviour.record(&"item_deposited", global_position, stable_id, &"transfer", -1.0, {"item_id": String(item_id)})
		HatchState.LOADED:
			hatch_state = HatchState.TRANSIT
			hatch_sealed.emit(item_id)
			GameRuntime.behaviour.record(&"hatch_sealed", global_position, stable_id, &"transfer", -1.0, {"item_id": String(item_id)})
		HatchState.RETURN_READY:
			if actor.has_method("give_item") and actor.give_item(item_id):
				var collected_id := item_id
				item_id = &""; hatch_state = HatchState.EMPTY
				item_collected.emit(collected_id)
				GameRuntime.behaviour.record(&"item_collected", global_position, stable_id, &"transfer", -1.0, {"item_id": String(collected_id)})
	state_changed.emit()

func remote_action(action: StringName, payload: Dictionary = {}) -> bool:
	if action == &"receive" and hatch_state == HatchState.TRANSIT:
		remote_received.emit(item_id)
		GameRuntime.behaviour.record(&"item_transferred", global_position, stable_id, &"remote", -1.0, {"item_id": String(item_id)})
		item_id = &""; state_changed.emit(); return true
	if action == &"return_item" and hatch_state == HatchState.TRANSIT:
		item_id = StringName(payload.get("item_id", "")); hatch_state = HatchState.RETURN_READY; state_changed.emit(); return item_id != &""
	return false

func prompt_text(actor: Node) -> String:
	match hatch_state:
		HatchState.EMPTY:
			if actor.has_method("has_carried_item") and actor.has_carried_item(): return "[E] Place 35A fuse" if actor.carried_item_id == accepted_item_id else "HATCH REQUIRES 35A FUSE"
			return "TRANSFER HATCH // EMPTY"
		HatchState.LOADED: return "[E] Seal transfer hatch"
		HatchState.TRANSIT: return "TRANSFER IN PROGRESS"
		HatchState.RETURN_READY: return "[E] Collect returned item"
	return ""

func state_dict() -> Dictionary: return {"hatch_state": hatch_state, "item_id": String(item_id)}
func load_state(data: Dictionary) -> void:
	hatch_state = clampi(int(data.get("hatch_state", 0)), 0, HatchState.RETURN_READY)
	item_id = StringName(data.get("item_id", "")); state_changed.emit()
