class_name BehaviourMemory
extends RefCounted

const HALF_LIFE_SECONDS := 86400.0
var entries: Dictionary = {}

func observe(kind: StringName, target: StringName, supported: bool, when: float) -> Dictionary:
	var key := "%s|%s" % [kind, target]
	var entry: Dictionary = entries.get(key, {"type": String(kind), "target": String(target), "confidence": 0.0, "observation_count": 0, "support_count": 0, "contradiction_count": 0, "last_observed_time": 0.0, "strength": 0.5, "recency": 1.0, "decay_half_life": HALF_LIFE_SECONDS})
	entry["observation_count"] = int(entry.observation_count) + 1
	entry["support_count" if supported else "contradiction_count"] = int(entry["support_count" if supported else "contradiction_count"]) + 1
	entry["strength"] = lerpf(float(entry.strength), 1.0 if supported else 0.0, 0.25)
	entry["last_observed_time"] = when; entry["recency"] = 1.0
	var sample_factor := 1.0 - exp(-float(entry.observation_count) / 2.0)
	var consistency := float(entry.support_count) / float(entry.observation_count)
	entry["confidence"] = clampf(sample_factor * consistency * (0.6 + float(entry.strength) * 0.4), 0.0, 0.95)
	entries[key] = entry
	return entry

func get_entry(kind: StringName, target: StringName = &"") -> Dictionary:
	return entries.get("%s|%s" % [kind, target], {})

func confidence_for(kind: StringName, target: StringName = &"", when: float = -1.0) -> float:
	var entry := get_entry(kind, target)
	if entry.is_empty(): return 0.0
	var now := when if when >= 0.0 else Time.get_unix_time_from_system()
	var age := maxf(now - float(entry.last_observed_time), 0.0)
	return float(entry.confidence) * pow(0.5, age / maxf(float(entry.decay_half_life), 1.0))

func refresh_recency(when: float) -> void:
	for key in entries:
		var entry: Dictionary = entries[key]
		entry["recency"] = pow(0.5, maxf(when - float(entry.last_observed_time), 0.0) / maxf(float(entry.decay_half_life), 1.0))
		entries[key] = entry

func to_dict() -> Dictionary: return {"entries": entries.duplicate(true)}
func load_dict(data: Dictionary) -> void: entries = data.get("entries", {}).duplicate(true)
