class_name BehaviourProfile
extends RefCounted
const SCHEMA_VERSION := 1

static func export_data(model: BehaviourModel, memory: BehaviourMemory, prediction: PredictionSystem, trust: TrustModel) -> Dictionary:
	return {"schema_version": SCHEMA_VERSION, "metrics": model.to_dict(), "habits": memory.to_dict(), "prediction_performance": {"correct": prediction.correct, "evaluated": prediction.evaluated}, "trust_summary": trust.to_dict(), "common_routes": _route_summary(memory), "interaction_tendencies": {"door_recheck": memory.confidence_for(&"DOOR_RECHECK"), "terminal_return": memory.confidence_for(&"TERMINAL_RETURN"), "repeated_interaction": memory.confidence_for(&"REPEATED_INTERACTOR")}}

static func import_data(data: Dictionary) -> Dictionary:
	if int(data.get("schema_version", 0)) != SCHEMA_VERSION: return {}
	var model := BehaviourModel.new(); model.load_dict(data.get("metrics", {}))
	var memory := BehaviourMemory.new(); memory.load_dict(data.get("habits", {}))
	return {"model": model, "memory": memory, "prediction_performance": data.get("prediction_performance", {}), "trust_summary": data.get("trust_summary", {}), "common_routes": data.get("common_routes", {}), "interaction_tendencies": data.get("interaction_tendencies", {})}

static func _route_summary(memory: BehaviourMemory) -> Dictionary:
	var routes := {}
	for key in memory.entries:
		var entry: Dictionary = memory.entries[key]
		if entry.type == "ROUTE_PREFERENCE": routes[entry.target] = {"confidence": entry.confidence, "observations": entry.observation_count}
	return routes
