class_name SaveSystem
extends RefCounted
const VERSION:=1;const PATH:="user://save.json"
static func save_game(player:Node3D)->bool:
 var states:={}
 for id in GameRuntime.facility:var n:Node=GameRuntime.facility[id];if n.has_method("state_dict"):states[String(id)]=n.state_dict()
 var d={"version":VERSION,"player":[player.global_position.x,player.global_position.y,player.global_position.z],"story_stage":GameRuntime.story_stage,"trust":GameRuntime.trust.to_dict(),"behaviour":GameRuntime.behaviour.to_dict(),"facility":states}
 var f:=FileAccess.open(PATH,FileAccess.WRITE);if f==null:return false
 f.store_string(JSON.stringify(d));return true
static func load_game(player:Node3D)->bool:
 if not FileAccess.file_exists(PATH):return false
 var d=JSON.parse_string(FileAccess.get_file_as_string(PATH));if not d is Dictionary:return false
 var p:Array=d.get("player",[0,1,5]);player.global_position=Vector3(p[0],p[1],p[2]);GameRuntime.story_stage=d.get("story_stage",0);GameRuntime.trust.load_dict(d.get("trust",{}));GameRuntime.behaviour.load_dict(d.get("behaviour",{}))
 for id in d.get("facility",{}):
  var n:=GameRuntime.get_facility(StringName(id));if n and n.has_method("load_state"):n.load_state(d.facility[id])
 return true
