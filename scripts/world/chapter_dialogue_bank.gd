class_name ChapterDialogueBank
extends RefCounted

var lines: Dictionary = {}

func _init(path := "res://resources/dialogue/chapter_01.json") -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary: lines = parsed

func get_line(key: StringName) -> String:
	return String(lines.get(String(key), "02: check the local panel"))
