class_name BehaviourRecorder
extends Node
signal event_recorded(event: BehaviourEvent)
@export var maximum_events := 512
var events: Array[BehaviourEvent] = []; var model := BehaviourModel.new()
func record(type: StringName, position := Vector3.ZERO, target := &"", context := &"", response := -1.0, metadata := {}) -> BehaviourEvent:
	var previous := &""
	for index in range(events.size() - 1, -1, -1):
		if events[index].target_id == target and target != &"": previous = events[index].event_type; break
	var event := BehaviourEvent.new(type, position, target, context, response, previous, metadata); events.append(event)
	if events.size() > maximum_events: events.pop_front()
	model.apply(event); event_recorded.emit(event); return event
func count(type: StringName, target := &"") -> int:
	var result := 0
	for event in events:
		if event.event_type == type and (target == &"" or event.target_id == target): result += 1
	return result
func recent(limit := 10) -> Array[BehaviourEvent]: return events.slice(maxi(events.size() - limit, 0), events.size())
func to_dict() -> Dictionary:
	var serialized: Array[Dictionary] = []
	for event in events: serialized.append(event.to_dict())
	return {"events": serialized, "model": model.to_dict()}
func load_dict(data: Dictionary) -> void:
	events.clear()
	for value in data.get("events", []): events.append(BehaviourEvent.from_dict(value))
	model.load_dict(data.get("model", {}))
