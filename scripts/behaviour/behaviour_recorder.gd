class_name BehaviourRecorder
extends Node
signal event_recorded(event:BehaviourEvent)
var events:Array[BehaviourEvent]=[];var model:=BehaviourModel.new()
func record(type:StringName,position:=Vector3.ZERO,target:=&"",context:=&"",response:=-1.0,metadata:={})->BehaviourEvent:
 var previous:=&""
 for i in range(events.size()-1,-1,-1):
  if events[i].target_id==target and target!=&"":previous=events[i].event_type;break
 var e:=BehaviourEvent.new(type,position,target,context,response,previous,metadata);events.append(e);model.apply(e);event_recorded.emit(e);return e
func to_dict()->Dictionary:
 var a:=[];for e in events:a.append(e.to_dict())
 return {"events":a,"model":model.to_dict()}
func load_dict(d:Dictionary)->void:
 events.clear();for v in d.get("events",[]):events.append(BehaviourEvent.from_dict(v))
 model.load_dict(d.get("model",{}))
