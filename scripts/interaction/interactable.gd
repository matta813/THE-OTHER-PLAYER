class_name Interactable
extends StaticBody3D
signal interacted(actor: Node)
signal state_changed
@export var stable_id: StringName = &""; @export var interaction_name := "Interact"; @export_multiline var interaction_description := ""; @export var available := true; @export var interaction_duration := 0.0; @export var interaction_type: StringName = &"use"; @export var unavailable_reason := "Unavailable"
func _ready() -> void: collision_layer = 2; GameRuntime.register(stable_id, self)
func _exit_tree() -> void: GameRuntime.unregister(stable_id, self)
func can_interact(_actor: Node) -> bool: return available
func prompt_text(actor: Node) -> String: return "[E] %s" % interaction_name if can_interact(actor) else unavailable_reason
func required_hold_duration() -> float: return maxf(interaction_duration, 0.0)
func interact(actor: Node) -> bool:
	if not can_interact(actor): _unavailable(actor); return false
	var audio := get_node_or_null("Audio") as FacilityAudioEmitter
	if audio: audio.play_interaction()
	interacted.emit(actor); _perform_interaction(actor); return true
func _perform_interaction(_actor: Node) -> void: pass
func _unavailable(_actor: Node) -> void:
	var audio := get_node_or_null("Audio") as FacilityAudioEmitter
	if audio: audio.play_unavailable()
	GameRuntime.behaviour.record(&"unavailable_interaction", global_position, stable_id, interaction_type)
func remote_action(_action: StringName, _payload: Dictionary = {}) -> bool: return false
func state_dict() -> Dictionary: return {"available": available}
func load_state(data: Dictionary) -> void: available = data.get("available", available); state_changed.emit()
