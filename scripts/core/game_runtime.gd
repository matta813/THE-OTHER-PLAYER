extends Node
var behaviour: BehaviourRecorder; var trust := TrustModel.new(); var predictions := PredictionSystem.new(); var other_player: OtherPlayerAgent; var facility: Dictionary = {}; var story_stage := 0
func _ready() -> void:
	behaviour = BehaviourRecorder.new(); behaviour.name = "BehaviourRecorder"; add_child(behaviour)
	other_player = OtherPlayerAgent.new(); other_player.name = "OtherPlayerAgent"; add_child(other_player)
func register(id: StringName, node: Node) -> void:
	if id != &"": facility[id] = node
func unregister(id: StringName, node: Node) -> void:
	if facility.get(id) == node: facility.erase(id)
func get_facility(id: StringName) -> Node: return facility.get(id)
