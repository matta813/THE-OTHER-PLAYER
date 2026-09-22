class_name SliceEventOptions
extends RefCounted

static func corridor() -> Array[Dictionary]:
	return [
		{"id": "EARLY_LIGHT_ASSIST", "category": "MANIPULATIVE", "base": 0.13, "habit": "DOOR_RECHECK", "min_habit_confidence": 0.4, "habit_weight": 1.1, "min_trust": 0.2, "trust_weight": 0.15, "prediction_weight": 0.1, "deception_value": 0.24, "action_cost": 0.08, "reveal_risk": 0.18, "reason": "Repeated door rechecks suggest a player who responds to prepared routes", "expected_result": "Player continues through the lit Room B threshold"},
		{"id": "HOLD_LIGHT", "category": "AMBIENT", "base": 0.3, "reason": "No reliable habit justifies an early intervention", "expected_result": "Player reaches the circuit with backup lighting"}
	]

static func power_restored() -> Array[Dictionary]:
	return [
		{"id": "DELAY_ACK", "category": "SUSPICIOUS", "base": 0.2, "expectation": "partner_reply", "min_expectation_confidence": 0.43, "expectation_weight": 0.48, "min_trust": 0.2, "trust_weight": 0.16, "cooperation_weight": 0.08, "deception_value": 0.22, "action_cost": 0.05, "reveal_risk": 0.18, "reason": "Reliable prior replies make a brief silence noticeable; observe the player's response", "expected_result": "Player waits, retries, or returns to terminal"},
		{"id": "PROMPT_ACK", "category": "COOPERATIVE", "base": 0.34, "trust_weight": 0.1, "reason": "Preserve reliable cooperation", "expected_result": "Player accepts the circuit response"},
		{"id": "REASSURE_ACK", "category": "COOPERATIVE", "base": 0.1, "min_suspicion": 0.32, "suspicion_weight": 1.0, "reason": "Estimated suspicion calls for an ordinary, helpful reply", "expected_result": "Suspicion eases after a reliable response"}
	]

static func reassurance() -> Array[Dictionary]:
	return [
		{"id": "REASSURE_NOW", "category": "COOPERATIVE", "base": 0.3, "min_suspicion": 0.13, "suspicion_weight": 0.8, "reason": "Player revisited terminal during unexpected silence", "expected_result": "Player receives a plausible explanation"}
	]
