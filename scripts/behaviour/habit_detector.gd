class_name HabitDetector
extends RefCounted

# Rule data stays separate from the event loop. New habits only need another rule.
const RULES: Array[Dictionary] = [
	{"name": "DOOR_RECHECK", "positive": ["door_rechecked"], "negative": [], "target": ""},
	{"name": "TERMINAL_RETURN", "positive": ["returned_to_terminal"], "negative": [], "target": ""},
	{"name": "FAST_COOPERATOR", "positive": ["instruction_completed"], "negative": ["instruction_completed"], "test": "fast", "target": ""},
	{"name": "SLOW_COOPERATOR", "positive": ["instruction_completed"], "negative": ["instruction_completed"], "test": "slow", "target": ""},
	{"name": "OPTIONAL_EXPLORER", "positive": ["optional_area_explored"], "negative": ["instruction_completed"], "target": ""},
	{"name": "REPEATED_INTERACTOR", "positive": ["interaction_retried", "door_rechecked"], "negative": [], "target": ""},
	{"name": "WAIT_FOR_PARTNER", "positive": ["waited_for_partner"], "negative": ["unrelated_interaction"], "target": ""},
	{"name": "LIGHT_BEFORE_ENTRY", "positive": ["light_activated_before_entry"], "negative": ["dark_room_entered"], "target": ""},
	{"name": "DARKNESS_AVOIDANT", "positive": ["hesitated_at_threshold"], "negative": ["dark_room_entered"], "target": ""},
	{"name": "ROUTE_PREFERENCE", "positive": ["route_chosen"], "negative": [], "target": "event_target"}
]

var memory: BehaviourMemory
func _init(store: BehaviourMemory = null) -> void: memory = store if store != null else BehaviourMemory.new()

func observe(event: BehaviourEvent) -> void:
	for rule in RULES:
		var event_name := String(event.event_type)
		if event_name not in rule.positive and event_name not in rule.negative: continue
		var target := event.target_id if rule.get("target", "") == "event_target" else &""
		var supported: bool = event_name in rule.positive
		match rule.get("test", ""):
			"fast": supported = event.response_time >= 0.0 and event.response_time <= 12.0
			"slow": supported = event.response_time >= 25.0
		memory.observe(StringName(rule.name), target, supported, event.timestamp)
