class_name ElectronicDoor
extends Interactable
@export var locked:=true
var opened:=false
func _perform_interaction(actor:Node)->void:
 if locked:GameRuntime.behaviour.record(&"interaction_retried",global_position,stable_id,&"locked_door");return
 opened=!opened;rotation.y=deg_to_rad(-95 if opened else 0);GameRuntime.behaviour.record(&"door_opened",global_position,stable_id)
func remote_action(action:StringName,_payload:Dictionary={})->bool:
 if action==&"unlock":locked=false;available=true;return true
 if action==&"lock":locked=true;return true
 return false
func state_dict()->Dictionary:return {"locked":locked,"opened":opened}
func load_state(d:Dictionary)->void:locked=d.get("locked",true);opened=d.get("opened",false);rotation.y=deg_to_rad(-95 if opened else 0)
