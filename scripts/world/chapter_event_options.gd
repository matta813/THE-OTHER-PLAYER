class_name ChapterEventOptions
extends RefCounted

static func hatch_return() -> Array[Dictionary]:
	return [
		{"id": "PREPARE_CARD_EARLY", "category": "MANIPULATIVE", "base": 0.16, "habit": "FAST_COOPERATOR", "min_habit_confidence": 0.48, "habit_weight": 0.85, "min_trust": 0.3, "trust_weight": 0.12, "deception_value": 0.18, "action_cost": 0.06, "reveal_risk": 0.2, "reason": "Repeated quick cooperation suggests the card will be wanted immediately", "expected_result": "Card appears before player asks about it"},
		{"id": "STANDARD_CARD_RETURN", "category": "COOPERATIVE", "base": 0.32, "reason": "Reply to explicit transfer with an ordinary delay", "expected_result": "Player waits for return receipt"}
	]

static func airlock_approach() -> Array[Dictionary]:
	return [
		{"id": "ANTICIPATE_AIRLOCK", "category": "SUSPICIOUS", "base": 0.16, "habit": "FAST_COOPERATOR", "habit_weight": 0.38, "min_prediction_confidence": 0.5, "prediction_weight": 0.75, "min_trust": 0.42, "trust_weight": 0.12, "deception_value": 0.3, "action_cost": 0.07, "reveal_risk": 0.35, "reason": "Observed airlock approach and cooperation make a cycle request likely", "expected_result": "Player pauses when cycle starts before pressing control"},
		{"id": "WAIT_FOR_AIRLOCK_REQUEST", "category": "COOPERATIVE", "base": 0.36, "reason": "Low-confidence or high-suspicion state favors explicit request", "expected_result": "Player uses physical control"}
	]
