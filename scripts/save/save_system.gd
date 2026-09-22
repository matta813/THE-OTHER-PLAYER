class_name SaveSystem
extends RefCounted
const VERSION := 2; const PATH := "user://save.json"
static func build_data(player: Node3D) -> Dictionary:
	var states := {}
	for id in GameRuntime.facility:
		var node: Node = GameRuntime.facility[id]
		if node.has_method("state_dict"): states[String(id)] = node.state_dict()
	return {"version": VERSION, "player": [player.global_position.x, player.global_position.y, player.global_position.z], "player_rotation": player.rotation.y, "story_stage": GameRuntime.story_stage, "trust": GameRuntime.trust.to_dict(), "behaviour": GameRuntime.behaviour.to_dict(), "predictions": GameRuntime.predictions.to_dict(), "other_player": GameRuntime.other_player.to_dict(), "facility": states}
static func save_game(player: Node3D) -> bool:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(build_data(player), "  ")); return true
static func load_game(player: Node3D) -> bool:
	if not FileAccess.file_exists(PATH): return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not data is Dictionary or int(data.get("version", 0)) > VERSION: return false
	var p: Array = data.get("player", [0, 1, 5]); player.global_position = Vector3(p[0], p[1], p[2]); player.rotation.y = data.get("player_rotation", 0.0); GameRuntime.story_stage = data.get("story_stage", 0); GameRuntime.trust.load_dict(data.get("trust", {})); GameRuntime.behaviour.load_dict(data.get("behaviour", {})); GameRuntime.predictions.load_dict(data.get("predictions", {})); GameRuntime.other_player.load_dict(data.get("other_player", {}))
	for id in data.get("facility", {}):
		var node := GameRuntime.get_facility(StringName(id))
		if node and node.has_method("load_state"): node.load_state(data.facility[id])
	return true
