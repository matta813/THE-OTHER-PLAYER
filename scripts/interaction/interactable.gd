class_name Interactable
extends StaticBody3D
@export var stable_id:StringName=&"";@export var interaction_name:="Interact";@export_multiline var interaction_description:="";@export var available:=true;@export var interaction_duration:=0.0;@export var interaction_type:StringName=&"use"
signal interacted(actor:Node)
func _ready()->void:collision_layer=2;GameRuntime.register(stable_id,self)
func _exit_tree()->void:GameRuntime.unregister(stable_id,self)
func can_interact(_actor:Node)->bool:return available
func interact(actor:Node)->void:
 if can_interact(actor):interacted.emit(actor);_perform_interaction(actor)
func _perform_interaction(_actor:Node)->void:pass
func remote_action(_action:StringName,_payload:Dictionary={})->bool:return false
func state_dict()->Dictionary:return {"available":available}
func load_state(d:Dictionary)->void:available=d.get("available",available)
