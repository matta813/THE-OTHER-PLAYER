extends Node
var behaviour:BehaviourRecorder;var trust:=TrustModel.new();var facility:={};var story_stage:=0
func _ready()->void:behaviour=BehaviourRecorder.new();add_child(behaviour)
func register(id:StringName,node:Node)->void:facility[id]=node
func unregister(id:StringName,node:Node)->void:
 if facility.get(id)==node:facility.erase(id)
func get_facility(id:StringName)->Node:return facility.get(id)
