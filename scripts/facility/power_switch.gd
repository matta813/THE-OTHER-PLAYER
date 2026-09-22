class_name PowerSwitch
extends Interactable
signal power_changed(powered:bool)
var powered:=false
func _perform_interaction(_actor:Node)->void:
 powered=!powered;rotation.z=deg_to_rad(25 if powered else -25);power_changed.emit(powered)
 var response:float=Time.get_ticks_msec()/1000.0-float(get_meta("requested_at",Time.get_ticks_msec()/1000.0))
 GameRuntime.behaviour.record(&"instruction_completed",global_position,stable_id,&"power_request",response);GameRuntime.trust.player_response(response,true)
func state_dict()->Dictionary:return {"powered":powered}
func load_state(d:Dictionary)->void:powered=d.get("powered",false)
