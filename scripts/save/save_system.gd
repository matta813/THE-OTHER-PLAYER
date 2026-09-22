class_name SaveSystem
extends RefCounted

const VERSION := 3
const PATH := "user://save.json"

static func build_data(player: Node3D) -> Dictionary:
	var states := {}
	for id in GameRuntime.facility:
		var node: Node = GameRuntime.facility[id]
		if node.has_method("state_dict"): states[String(id)] = node.state_dict()
	return {"version": VERSION, "player": [player.global_position.x, player.global_position.y, player.global_position.z], "player_rotation": player.rotation.y, "story_stage": GameRuntime.story_stage, "trust": GameRuntime.trust.to_dict(), "behaviour": GameRuntime.behaviour.to_dict(), "predictions": GameRuntime.predictions.to_dict(), "other_player": GameRuntime.other_player.to_dict(), "facility": states, "adaptive": {"habits": GameRuntime.habits.to_dict(), "expectations": GameRuntime.expectations.to_dict(), "suspicion": GameRuntime.suspicion.to_dict(), "director": GameRuntime.director.to_dict(), "trust_strategy": GameRuntime.trust_strategy.to_dict()}}

static func save_game(player: Node3D) -> bool:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(build_data(player), "  "))
	return true

static func load_game(player: Node3D) -> bool:
	if not FileAccess.file_exists(PATH): return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not data is Dictionary: return false
	return apply_data(player, data)

static func apply_data(player: Node3D, raw_data: Dictionary) -> bool:
	var version := int(raw_data.get("version", 0))
	if version < 1 or version > VERSION: return false
	var data := migrate(raw_data)
	var position: Array = data.get("player", [0, 1, 5])
	if position.size() != 3: return false
	player.global_position = Vector3(float(position[0]), float(position[1]), float(position[2]))
	player.rotation.y = float(data.get("player_rotation", 0.0))
	GameRuntime.story_stage = int(data.get("story_stage", 0))
	GameRuntime.trust.load_dict(data.get("trust", {}))
	GameRuntime.behaviour.load_dict(data.get("behaviour", {}))
	GameRuntime.predictions.load_dict(data.get("predictions", {}))
	GameRuntime.other_player.load_dict(data.get("other_player", {}))
	var adaptive: Dictionary = data.get("adaptive", {})
	GameRuntime.habits.load_dict(adaptive.get("habits", {}))
	GameRuntime.expectations.load_dict(adaptive.get("expectations", {}))
	GameRuntime.suspicion.load_dict(adaptive.get("suspicion", {}))
	GameRuntime.director.load_dict(adaptive.get("director", {}))
	GameRuntime.trust_strategy.load_dict(adaptive.get("trust_strategy", {}))
	for id in data.get("facility", {}):
		var node := GameRuntime.get_facility(StringName(id))
		if node and node.has_method("load_state"): node.load_state(data.facility[id])
	return true

static func migrate(raw_data: Dictionary) -> Dictionary:
	var data := raw_data.duplicate(true)
	if int(data.get("version", 0)) < 3:
		data["adaptive"] = {"habits": {}, "expectations": {}, "suspicion": {}, "director": {}, "trust_strategy": {}}
		var prediction: Dictionary = data.get("predictions", {})
		var current: Dictionary = prediction.get("current", {})
		if current.get("result", "") == "pending": current["result"] = "superseded"; prediction["current"] = current; data["predictions"] = prediction
	data["version"] = VERSION
	return data
