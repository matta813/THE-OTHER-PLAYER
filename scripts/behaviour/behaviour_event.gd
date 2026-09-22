class_name BehaviourEvent
extends RefCounted
var timestamp:float;var event_type:StringName;var world_position:Vector3;var target_id:StringName;var context:StringName;var response_time:float;var previous_related_event:StringName;var metadata:Dictionary
func _init(type:StringName=&"unknown",position:=Vector3.ZERO,target:=&"",event_context:=&"",response:=-1.0,previous:=&"",extra:={})->void:
 timestamp=Time.get_unix_time_from_system();event_type=type;world_position=position;target_id=target;context=event_context;response_time=response;previous_related_event=previous;metadata=extra.duplicate(true)
func to_dict()->Dictionary:return {"timestamp":timestamp,"event_type":String(event_type),"position":[world_position.x,world_position.y,world_position.z],"target_id":String(target_id),"context":String(context),"response_time":response_time,"previous":String(previous_related_event),"metadata":metadata}
static func from_dict(d:Dictionary)->BehaviourEvent:
 var p:Array=d.get("position",[0,0,0]);var e:=BehaviourEvent.new(StringName(d.get("event_type","unknown")),Vector3(p[0],p[1],p[2]),StringName(d.get("target_id","")),StringName(d.get("context","")),d.get("response_time",-1.0),StringName(d.get("previous","")),d.get("metadata",{}));e.timestamp=d.get("timestamp",0.0);return e
