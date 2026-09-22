class_name FirstPersonController
extends CharacterBody3D
@export var walk_speed:=3.2;@export var sprint_speed:=5.2;@export var sensitivity:=.0022
@onready var head:Node3D=$Head;@onready var ray:RayCast3D=$Head/Camera3D/InteractionRay
var pitch:=0.0;var head_base:=1.65
func _ready()->void:Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
func _unhandled_input(e:InputEvent)->void:
 if e is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:rotate_y(-e.relative.x*sensitivity);pitch=clampf(pitch-e.relative.y*sensitivity,-1.45,1.45);head.rotation.x=pitch
 if e.is_action_pressed("ui_cancel"):Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if Input.mouse_mode==Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
 if e.is_action_pressed("interact") and ray.is_colliding():
  var target:=ray.get_collider()
  if target is Interactable:target.interact(self)
func _physics_process(delta:float)->void:
 if not is_on_floor():velocity.y-=18.0*delta
 var input:=Input.get_vector("move_left","move_right","move_forward","move_back");var direction:=(transform.basis*Vector3(input.x,0,input.y)).normalized();var speed:=sprint_speed if Input.is_action_pressed("sprint") else walk_speed
 velocity.x=move_toward(velocity.x,direction.x*speed,14*delta);velocity.z=move_toward(velocity.z,direction.z*speed,14*delta)
 head.position.y=move_toward(head.position.y,1.05 if Input.is_action_pressed("crouch") else head_base,delta*3);move_and_slide()
