extends SceneTree
var failures:=0
func _init()->void:
 var model:=BehaviourModel.new();var before:float=model.metrics[&"cooperation"];model.apply(BehaviourEvent.new(&"instruction_completed",Vector3.ZERO,&"switch",&"",4.0));check(model.metrics[&"cooperation"]>before,"cooperation derived from completion")
 var event:=BehaviourEvent.new(&"room_entered",Vector3(1,2,3),&"room_b");check(BehaviourEvent.from_dict(event.to_dict()).world_position==Vector3(1,2,3),"event round trip")
 var trust:=TrustModel.new();var initial:=trust.player_trust_in_other_player;trust.reliable_help();check(trust.player_trust_in_other_player>initial,"reliable help raises trust")
 print("TESTS: ",3-failures," passed, ",failures," failed");quit(failures)
func check(value:bool,label:String)->void:
 if not value:failures+=1;push_error("FAIL: "+label)
