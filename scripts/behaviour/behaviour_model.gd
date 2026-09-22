class_name BehaviourModel
extends RefCounted
const NAMES:=[&"risk_tolerance",&"curiosity",&"trust",&"predictability",&"patience",&"hesitation",&"exploration_bias",&"resource_attachment",&"routine_strength",&"cooperation",&"dependence_on_other_player"]
var metrics:={};var counts:={}
func _init()->void:
 for n in NAMES:metrics[n]=.5
func apply(e:BehaviourEvent)->void:
 counts[e.event_type]=counts.get(e.event_type,0)+1
 match e.event_type:
  &"unrelated_interaction":adjust(&"curiosity",.03);adjust(&"cooperation",-.01)
  &"optional_area_explored":adjust(&"exploration_bias",.04)
  &"instruction_completed":adjust(&"cooperation",.07);adjust(&"hesitation",-.03 if e.response_time<12 else .03)
  &"instruction_ignored":adjust(&"cooperation",-.1)
  &"returned_to_terminal":adjust(&"dependence_on_other_player",.06)
  &"interaction_retried":adjust(&"patience",-.02)
func adjust(n:StringName,a:float)->void:metrics[n]=clampf(metrics.get(n,.5)+a,0,1)
func to_dict()->Dictionary:return {"metrics":metrics,"counts":counts}
func load_dict(d:Dictionary)->void:
 for n in NAMES:metrics[n]=clampf(d.get("metrics",{}).get(String(n),.5),0,1)
 counts=d.get("counts",{}).duplicate()
