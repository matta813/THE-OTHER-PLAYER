class_name SaveSystem
extends RefCounted

const VERSION := 4
const PATH := "user://save.json"
const CHECKPOINT_PATH := "user://checkpoint.json"
const SLOT_COUNT := 4

static func slot_path(index: int) -> String:
	return "user://slot_%d.json" % index if index >= 1 and index <= SLOT_COUNT else ""

static func slot_info(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path): return {"state": "empty", "path": path}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK: return {"state": "invalid", "path": path}
	var parsed: Variant = parser.data
	if not parsed is Dictionary or not _valid_data(parsed): return {"state": "invalid", "path": path}
	var chapter: Dictionary = parsed.get("facility", {}).get("chapter_one", {})
	var metadata: Dictionary = parsed.get("metadata", {})
	return {"state": "valid", "path": path, "version": int(parsed.version), "game_version": String(metadata.get("game_version", "legacy")), "chapter": String(metadata.get("chapter", "Chapter 1 — Connection")), "playtime": float(metadata.get("playtime", 0.0)), "timestamp": int(metadata.get("timestamp", 0)), "location": String(metadata.get("location", _location_from_stage(int(chapter.get("stage", 0)))))}

static func recent_path() -> String:
	var best := ""
	var latest := -1
	for path in [PATH, CHECKPOINT_PATH, slot_path(1), slot_path(2), slot_path(3), slot_path(4)]:
		var info := slot_info(path)
		if info.state != "valid": continue
		var stamp := int(info.timestamp)
		if stamp <= 0: stamp = int(FileAccess.get_modified_time(path))
		if stamp > latest: latest = stamp; best = path
	return best

static func _location_from_stage(stage: int) -> String:
	return ["Arrival", "Security Office", "Transfer Room", "Power Distribution", "Generator Room", "Communications", "Exit Airlock", "Chapter Complete"][clampi(stage, 0, 7)]

static func _valid_data(data: Dictionary) -> bool:
	if not data.get("version", 0) is int and not data.get("version", 0) is float: return false
	var version := int(data.get("version", 0))
	if version < 1 or version > VERSION: return false
	if not data.get("player") is Array or data.player.size() != 3: return false
	for coordinate in data.player:
		if not coordinate is float and not coordinate is int: return false
		if not is_finite(float(coordinate)): return false
	for key in ["trust", "behaviour", "predictions", "other_player", "facility", "adaptive", "metadata"]:
		if not data.get(key, {}) is Dictionary: return false
	if not data.get("player_rotation", 0.0) is float and not data.get("player_rotation", 0.0) is int: return false
	if not data.get("story_stage", 0) is float and not data.get("story_stage", 0) is int: return false
	var metadata: Dictionary = data.get("metadata", {})
	for key in ["playtime", "timestamp"]:
		if not metadata.get(key, 0) is float and not metadata.get(key, 0) is int: return false
	var facility: Dictionary = data.get("facility", {})
	for state in facility.values():
		if not state is Dictionary: return false
	var behaviour: Dictionary = data.get("behaviour", {})
	if not behaviour.get("events", []) is Array or not behaviour.get("model", {}) is Dictionary: return false
	for event in behaviour.get("events", []):
		if not event is Dictionary: return false
	var model: Dictionary = behaviour.get("model", {})
	for key in ["metrics", "samples", "confidence", "consistency", "last_evidence", "last_reason"]:
		if not model.get(key, {}) is Dictionary: return false
	var predictions: Dictionary = data.get("predictions", {})
	if not predictions.get("current", {}) is Dictionary or not predictions.get("history", []) is Array: return false
	var other: Dictionary = data.get("other_player", {})
	if not other.get("memory", {}) is Dictionary or not other.get("scheduled", []) is Array: return false
	for action in other.get("scheduled", []):
		if not action is Dictionary: return false
	var adaptive: Dictionary = data.get("adaptive", {})
	for key in ["habits", "expectations", "suspicion", "director", "trust_strategy"]:
		if not adaptive.get(key, {}) is Dictionary: return false
	return true

static func build_data(player: Node3D) -> Dictionary:
	var states := {}
	for id in GameRuntime.facility:
		var node: Node = GameRuntime.facility[id]
		if node.has_method("state_dict"): states[String(id)] = node.state_dict()
	var chapter: Dictionary = states.get("chapter_one", {})
	return {"version": VERSION, "metadata": {"game_version": ReleaseInfo.VERSION, "chapter": "Chapter 1 — Connection", "playtime": GameRuntime.playtime, "timestamp": int(Time.get_unix_time_from_system()), "location": _location_from_stage(int(chapter.get("stage", 0)))}, "player": [player.global_position.x, player.global_position.y, player.global_position.z], "player_rotation": player.rotation.y, "carried_item": String(player.carried_item_id) if player is FirstPersonController else "", "story_stage": GameRuntime.story_stage, "trust": GameRuntime.trust.to_dict(), "behaviour": GameRuntime.behaviour.to_dict(), "predictions": GameRuntime.predictions.to_dict(), "other_player": GameRuntime.other_player.to_dict(), "facility": states, "adaptive": {"habits": GameRuntime.habits.to_dict(), "expectations": GameRuntime.expectations.to_dict(), "suspicion": GameRuntime.suspicion.to_dict(), "director": GameRuntime.director.to_dict(), "trust_strategy": GameRuntime.trust_strategy.to_dict()}}

static func save_game(player: Node3D) -> bool:
	return save_to(PATH, player)

static func save_checkpoint(player: Node3D) -> bool: return save_to(CHECKPOINT_PATH, player)
static func save_slot(index: int, player: Node3D) -> bool:
	var path := slot_path(index)
	return not path.is_empty() and save_to(path, player)

static func save_to(path: String, player: Node3D) -> bool:
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(build_data(player), "  "))
	file.flush()
	file.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path)) == OK

static func load_game(player: Node3D) -> bool:
	return load_from(PATH, player)

static func load_checkpoint(player: Node3D) -> bool: return load_from(CHECKPOINT_PATH, player)
static func load_slot(index: int, player: Node3D) -> bool: return load_from(slot_path(index), player)

static func load_from(path: String, player: Node3D) -> bool:
	if not FileAccess.file_exists(path): return false
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK: return false
	var data: Variant = parser.data
	if not data is Dictionary or not _valid_data(data): return false
	return apply_data(player, data)

static func apply_data(player: Node3D, raw_data: Dictionary) -> bool:
	if not _valid_data(raw_data): return false
	var data := migrate(raw_data)
	var position: Array = data.get("player", [0, 1, 5])
	if position.size() != 3: return false
	player.global_position = Vector3(float(position[0]), float(position[1]), float(position[2]))
	player.rotation.y = float(data.get("player_rotation", 0.0))
	if player is FirstPersonController: player.set_carried_item(StringName(data.get("carried_item", "")))
	GameRuntime.story_stage = int(data.get("story_stage", 0))
	GameRuntime.playtime = float(data.get("metadata", {}).get("playtime", 0.0))
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
