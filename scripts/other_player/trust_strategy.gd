class_name TrustStrategy
extends RefCounted
var reliable_help_count := 0
var trust_building_actions := 0
var last_reassurance_time := -100000.0

func record_help(trust: TrustModel, suspicion: SuspicionModel, expectation: ExpectationModel, when: float, replied := true) -> void:
	reliable_help_count += 1; trust_building_actions += 1; trust.reliable_help(); suspicion.reassure(when); expectation.observe(&"remote_help", true, when)
	if replied: expectation.observe(&"partner_reply", true, when)

func should_reassure(suspicion: SuspicionModel, now: float) -> bool:
	return suspicion.value >= 0.32 and now - last_reassurance_time > 30.0

func record_reassurance(now: float, suspicion: SuspicionModel) -> void:
	last_reassurance_time = now; suspicion.reassure(now)

func to_dict() -> Dictionary: return {"reliable_help_count": reliable_help_count, "trust_building_actions": trust_building_actions, "last_reassurance_time": last_reassurance_time}
func load_dict(data: Dictionary) -> void: reliable_help_count = int(data.get("reliable_help_count", 0)); trust_building_actions = int(data.get("trust_building_actions", 0)); last_reassurance_time = float(data.get("last_reassurance_time", -100000.0))
