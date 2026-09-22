class_name ExpectationModel
extends RefCounted
var entries: Dictionary = {}

func observe(kind: StringName, fulfilled: bool, when: float) -> Dictionary:
	var key := String(kind)
	var entry: Dictionary = entries.get(key, {"type": key, "observations": 0, "fulfilled": 0, "violated": 0, "confidence": 0.0, "last_observed_time": 0.0})
	entry.observations = int(entry.observations) + 1
	entry["fulfilled" if fulfilled else "violated"] = int(entry["fulfilled" if fulfilled else "violated"]) + 1
	entry.last_observed_time = when
	entry.confidence = (1.0 - exp(-float(entry.observations) / 2.0)) * float(entry.fulfilled) / float(entry.observations)
	entries[key] = entry
	return entry

func confidence_for(kind: StringName) -> float: return float(entries.get(String(kind), {}).get("confidence", 0.0))
func to_dict() -> Dictionary: return {"entries": entries.duplicate(true)}
func load_dict(data: Dictionary) -> void: entries = data.get("entries", {}).duplicate(true)
