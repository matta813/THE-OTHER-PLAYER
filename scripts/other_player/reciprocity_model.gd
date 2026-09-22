class_name ReciprocityModel
extends RefCounted

var help_given := 0
var help_requested := 0
var help_delayed := 0
var help_refused := 0
var reliable_exchanges := 0

func request_help() -> void: help_requested += 1
func player_helped(delay_seconds: float, trust: TrustModel) -> void:
	help_given += 1
	if delay_seconds > 20.0: help_delayed += 1
	else: reliable_exchanges += 1
	trust.player_response(delay_seconds, true)
func player_refused(trust: TrustModel) -> void:
	help_refused += 1
	trust.player_response(60.0, false)
func partner_helped(trust: TrustModel) -> void:
	reliable_exchanges += 1
	trust.reliable_help()
func to_dict() -> Dictionary:
	return {"help_given": help_given, "help_requested": help_requested, "help_delayed": help_delayed, "help_refused": help_refused, "reliable_exchanges": reliable_exchanges}
func load_dict(data: Dictionary) -> void:
	help_given = int(data.get("help_given", 0)); help_requested = int(data.get("help_requested", 0)); help_delayed = int(data.get("help_delayed", 0)); help_refused = int(data.get("help_refused", 0)); reliable_exchanges = int(data.get("reliable_exchanges", 0))
