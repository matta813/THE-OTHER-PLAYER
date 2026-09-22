extends Node
var behaviour: BehaviourRecorder; var trust := TrustModel.new(); var predictions := PredictionSystem.new(); var other_player: OtherPlayerAgent; var habits := BehaviourMemory.new(); var detector := HabitDetector.new(habits); var expectations := ExpectationModel.new(); var suspicion := SuspicionModel.new(); var director := AdaptiveEventDirector.new(); var trust_strategy := TrustStrategy.new(); var facility: Dictionary = {}; var story_stage := 0
func _ready() -> void:
	behaviour = BehaviourRecorder.new(); behaviour.name = "BehaviourRecorder"; add_child(behaviour)
	other_player = OtherPlayerAgent.new(); other_player.name = "OtherPlayerAgent"; add_child(other_player)
	behaviour.event_recorded.connect(_on_behaviour_event)
func _on_behaviour_event(event: BehaviourEvent) -> void: detector.observe(event); suspicion.observe(event)
func adaptive_state() -> Dictionary:
	return {"stage": story_stage, "trust": trust.player_trust_in_other_player, "suspicion": suspicion.value, "habits": habits, "expectations": expectations, "prediction_confidence": float(predictions.current.get("confidence", 0.0)), "cooperation": float(behaviour.model.metrics.get(&"cooperation", 0.5)), "world_time": Time.get_unix_time_from_system()}
func register(id: StringName, node: Node) -> void:
	if id != &"": facility[id] = node
func unregister(id: StringName, node: Node) -> void:
	if facility.get(id) == node: facility.erase(id)
func get_facility(id: StringName) -> Node: return facility.get(id)
