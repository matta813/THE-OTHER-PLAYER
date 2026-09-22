class_name AdaptiveEventDirector
extends RefCounted

const CATEGORY_COOLDOWN := {"AMBIENT": 8.0, "COOPERATIVE": 3.0, "SUSPICIOUS": 35.0, "MANIPULATIVE": 70.0}
var last_category_time: Dictionary = {}
var last_decision: Dictionary = {}
var manipulation_count := 0
var last_unusual_time := -100000.0

func choose(context: StringName, candidates: Array[Dictionary], state: Dictionary, now: float) -> Dictionary:
	var eligible: Array[Dictionary] = []
	for candidate in candidates:
		var category: String = candidate.get("category", "COOPERATIVE")
		var since: float = now - float(last_category_time.get(category, -100000.0))
		if since < float(candidate.get("cooldown", CATEGORY_COOLDOWN.get(category, 0.0))): continue
		if category in ["SUSPICIOUS", "MANIPULATIVE"] and now - last_unusual_time < 20.0: continue
		if int(state.get("stage", 0)) < int(candidate.get("min_stage", 0)): continue
		if float(state.get("trust", 0.0)) < float(candidate.get("min_trust", 0.0)): continue
		if float(state.get("suspicion", 0.0)) < float(candidate.get("min_suspicion", 0.0)): continue
		if category in ["SUSPICIOUS", "MANIPULATIVE"] and float(state.get("suspicion", 0.0)) > 0.38: continue
		var habit_confidence: float = (state.get("habits") as BehaviourMemory).confidence_for(StringName(candidate.get("habit", "")), &"", float(state.get("world_time", Time.get_unix_time_from_system()))) if candidate.has("habit") else 0.0
		if habit_confidence < float(candidate.get("min_habit_confidence", 0.0)): continue
		var expectation_confidence: float = (state.get("expectations") as ExpectationModel).confidence_for(StringName(candidate.get("expectation", ""))) if candidate.has("expectation") else 0.0
		if expectation_confidence < float(candidate.get("min_expectation_confidence", 0.0)): continue
		var score: float = float(candidate.get("base", 0.0)) + habit_confidence * float(candidate.get("habit_weight", 0.0)) + expectation_confidence * float(candidate.get("expectation_weight", 0.0)) + float(state.get("trust", 0.0)) * float(candidate.get("trust_weight", 0.0)) + float(state.get("prediction_confidence", 0.0)) * float(candidate.get("prediction_weight", 0.0)) + float(state.get("cooperation", 0.5)) * float(candidate.get("cooperation_weight", 0.0)) + float(state.get("suspicion", 0.0)) * float(candidate.get("suspicion_weight", 0.0)) + float(candidate.get("deception_value", 0.0)) * 0.25 - float(candidate.get("action_cost", 0.0)) - float(candidate.get("reveal_risk", 0.0)) * float(state.get("suspicion", 0.0))
		var option := candidate.duplicate(true); option["score"] = score; option["habit_confidence"] = habit_confidence; option["expectation_confidence"] = expectation_confidence; eligible.append(option)
	eligible.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.score) > float(b.score))
	if eligible.is_empty(): return {}
	var selected := eligible[0]
	last_category_time[selected.category] = now
	if selected.category in ["SUSPICIOUS", "MANIPULATIVE"]: last_unusual_time = now
	if selected.category == "MANIPULATIVE": manipulation_count += 1
	last_decision = {"context": String(context), "selected": selected.get("id", ""), "score": selected.score, "reason": selected.get("reason", "habit %.2f, expectation %.2f" % [selected.habit_confidence, selected.expectation_confidence]), "expected_result": selected.get("expected_result", ""), "alternatives": eligible.slice(1, mini(eligible.size(), 4)), "time": now}
	return selected

func to_dict() -> Dictionary: return {"last_category_time": last_category_time.duplicate(true), "last_decision": last_decision.duplicate(true), "manipulation_count": manipulation_count, "last_unusual_time": last_unusual_time}
func load_dict(data: Dictionary) -> void: last_category_time = data.get("last_category_time", {}).duplicate(true); last_decision = data.get("last_decision", {}).duplicate(true); manipulation_count = int(data.get("manipulation_count", 0)); last_unusual_time = float(data.get("last_unusual_time", -100000.0))
