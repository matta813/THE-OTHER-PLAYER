extends Node3D
@onready var player:Node3D=$Player;@onready var message:Label=$UI/Message;@onready var debug:Label=$UI/Debug
var request_started:=0.0;var terminal_visits:=0
func _ready()->void:
 $Terminal.terminal_used.connect(_terminal);$PowerSwitch.power_changed.connect(_power);GameRuntime.behaviour.event_recorded.connect(_event);message.text="";debug.visible=false
func _process(_d:float)->void:
 if GameRuntime.story_stage==2 and player.global_position.z < -5.0:
  request_started=Time.get_ticks_msec()/1000.0;$PowerSwitch.set_meta("requested_at",request_started);GameRuntime.story_stage=3;GameRuntime.behaviour.record(&"room_entered",player.global_position,&"room_b");_show("OTHER: POWER THE EAST CIRCUIT. I NEED LIGHT.")
 if Input.is_action_just_pressed("toggle_debug"):debug.visible=!debug.visible
 if Input.is_action_just_pressed("quick_save"):SaveSystem.save_game(player);_show("STATE RECORDED")
 if Input.is_action_just_pressed("quick_load"):SaveSystem.load_game(player);_show("STATE RESTORED")
 if debug.visible:
  var lines:=["DEVELOPER TELEMETRY","trust %.2f / confidence %.2f"%[GameRuntime.trust.player_trust_in_other_player,GameRuntime.trust.other_player_confidence_in_player],"stage %d | events %d"%[GameRuntime.story_stage,GameRuntime.behaviour.events.size()]]
  for k in GameRuntime.behaviour.model.metrics:lines.append("%s  %.2f"%[k,GameRuntime.behaviour.model.metrics[k]])
  debug.text="\n".join(lines)
func _terminal()->void:
 terminal_visits+=1
 if terminal_visits>1:GameRuntime.behaviour.record(&"returned_to_terminal",player.global_position,&"terminal_a")
 _show($Terminal.text)
 if GameRuntime.story_stage==0:GameRuntime.story_stage=1;_show("REMOTE HANDSHAKE...\nOTHER PLAYER CONNECTED");await get_tree().create_timer(2.1).timeout;$Door.remote_action(&"unlock");GameRuntime.trust.reliable_help();GameRuntime.story_stage=2;_show("OTHER: I FOUND YOUR DOOR. TRY IT.")
func _power(on:bool)->void:
 if on:$RoomLight.visible=true;$RoomLight.light_energy=4.0;GameRuntime.story_stage=4;_show("OTHER: Good. That was fast.");GameRuntime.trust.reliable_help()
func _event(_e:BehaviourEvent)->void:pass
func _show(t:String)->void:message.text=t;$UI/MessageTimer.start()
func _on_message_timer_timeout()->void:message.text=""
