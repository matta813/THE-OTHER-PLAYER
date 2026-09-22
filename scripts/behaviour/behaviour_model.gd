class_name BehaviourModel
extends RefCounted

const NAMES: Array[StringName] = [&"risk_tolerance", &"curiosity", &"trust", &"predictability", &"patience", &"hesitation", &"exploration_bias", &"resource_attachment", &"routine_strength", &"cooperation", &"dependence_on_other_player"]
var metrics: Dictionary = {}
var samples: Dictionary = {}
var confidence: Dictionary = {}
var last_reason: Dictionary = {}

func _init() -> void:
	for name in NAMES:
		metrics[name] = 0.5; samples[name] = 0; confidence[name] = 0.0; last_reason[name] = "No observations"

func apply(event: BehaviourEvent) -> void:
	match event.event_type:
		&"unrelated_interaction": observe(&"curiosity", 0.72, 0.18, "inspected an unrelated object"); observe(&"cooperation", 0.42, 0.08, "explored during a request")
		&"optional_area_explored": observe(&"exploration_bias", 0.78, 0.20, "explored before progressing"); observe(&"curiosity", 0.70, 0.12, "entered an optional space")
		&"instruction_completed":
			var quickness: float = clampf(1.0 - maxf(event.response_time, 0.0) / 60.0, 0.0, 1.0)
			observe(&"cooperation", 0.55 + quickness * 0.35, 0.22, "completed requested action"); observe(&"hesitation", 1.0 - quickness, 0.16, "response time %.1fs" % event.response_time)
		&"instruction_delayed": observe(&"hesitation", 0.75, 0.12, "request remained unresolved")
		&"returned_to_terminal": observe(&"dependence_on_other_player", 0.72, 0.14, "returned to the link terminal")
		&"interaction_retried": observe(&"patience", 0.38, 0.10, "retried an unavailable interaction")
		&"door_rechecked": observe(&"routine_strength", 0.70, 0.12, "rechecked the locked door")
		&"hesitated_at_threshold": observe(&"hesitation", 0.68, 0.10, "paused at a new-room threshold")

func observe(name: StringName, evidence: float, weight: float, reason: String) -> void:
	var n: int = int(samples.get(name, 0)); var adaptive_weight := weight / (1.0 + float(n) * 0.12)
	metrics[name] = clampf(lerpf(float(metrics.get(name, 0.5)), evidence, adaptive_weight), 0.0, 1.0)
	samples[name] = n + 1; confidence[name] = clampf(1.0 - exp(-float(n + 1) / 6.0), 0.0, 0.95); last_reason[name] = reason

func to_dict() -> Dictionary: return {"metrics": metrics.duplicate(true), "samples": samples.duplicate(true), "confidence": confidence.duplicate(true), "last_reason": last_reason.duplicate(true)}
func load_dict(data: Dictionary) -> void:
	for name in NAMES:
		metrics[name] = clampf(float(data.get("metrics", {}).get(String(name), 0.5)), 0.0, 1.0); samples[name] = int(data.get("samples", {}).get(String(name), 0)); confidence[name] = clampf(float(data.get("confidence", {}).get(String(name), 0.0)), 0.0, 1.0); last_reason[name] = str(data.get("last_reason", {}).get(String(name), "Restored"))
