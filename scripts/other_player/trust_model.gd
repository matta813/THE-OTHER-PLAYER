class_name TrustModel
extends RefCounted
var player_trust_in_other_player:=.15;var other_player_confidence_in_player:=.25
func reliable_help()->void:player_trust_in_other_player=clampf(player_trust_in_other_player+.09,0,1)
func player_response(seconds:float,completed:bool)->void:other_player_confidence_in_player=clampf(other_player_confidence_in_player+((.08-minf(seconds,60)*.001) if completed else -.12),0,1)
func to_dict()->Dictionary:return {"player_trust":player_trust_in_other_player,"other_confidence":other_player_confidence_in_player}
func load_dict(d:Dictionary)->void:player_trust_in_other_player=d.get("player_trust",.15);other_player_confidence_in_player=d.get("other_confidence",.25)
