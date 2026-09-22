class_name FirstPersonController
extends CharacterBody3D
signal focus_changed(prompt: String)
@export_group("Movement")
@export var walk_speed := 3.1; @export var sprint_speed := 4.8; @export var crouch_speed := 1.8; @export var ground_acceleration := 9.0; @export var ground_deceleration := 12.0; @export var gravity := 18.0; @export var max_slope_angle := 46.0
@export_group("View")
@export var mouse_sensitivity := 0.0019; @export var standing_eye_height := 1.58; @export var crouching_eye_height := 1.05; @export var crouch_transition_speed := 5.0; @export var step_bob_amount := 0.012; @export var step_bob_frequency := 7.5
@export_group("Interaction")
@export var interaction_distance := 2.4
@onready var head: Node3D = $Head; @onready var camera: Camera3D = $Head/Camera3D; @onready var ray: RayCast3D = $Head/Camera3D/InteractionRay; @onready var collider: CollisionShape3D = $Collision
var pitch := 0.0; var bob_time := 0.0; var focused: Interactable; var last_yaw := 0.0
func _ready() -> void:
	floor_max_angle = deg_to_rad(max_slope_angle); ray.target_position = Vector3(0, 0, -interaction_distance); Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity); pitch = clampf(pitch - event.relative.y * mouse_sensitivity, -1.42, 1.42); head.rotation.x = pitch
	if event.is_action_pressed("ui_cancel"): Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("interact") and focused: focused.interact(self)
func _physics_process(delta: float) -> void:
	if not is_on_floor(): velocity.y -= gravity * delta
	else: velocity.y = -0.5
	var crouching := Input.is_action_pressed("crouch"); var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back"); var direction := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	var target_speed := crouch_speed if crouching else (sprint_speed if Input.is_action_pressed("sprint") and input.y < 0.0 else walk_speed); var rate := ground_acceleration if direction else ground_deceleration
	velocity.x = move_toward(velocity.x, direction.x * target_speed, rate * delta); velocity.z = move_toward(velocity.z, direction.z * target_speed, rate * delta)
	var target_height := crouching_eye_height if crouching else standing_eye_height; head.position.y = move_toward(head.position.y, target_height, crouch_transition_speed * delta)
	var capsule := collider.shape as CapsuleShape3D
	if capsule: capsule.height = move_toward(capsule.height, 1.25 if crouching else 1.75, crouch_transition_speed * delta)
	if is_on_floor() and Vector2(velocity.x, velocity.z).length() > 0.4:
		bob_time += delta * step_bob_frequency * (target_speed / walk_speed); camera.position.y = sin(bob_time) * step_bob_amount
	else: camera.position.y = move_toward(camera.position.y, 0.0, delta * 0.08)
	move_and_slide(); _update_focus()
func _update_focus() -> void:
	var candidate := ray.get_collider() as Interactable if ray.is_colliding() else null
	if candidate != focused:
		focused = candidate; focus_changed.emit(focused.prompt_text(self) if focused else "")
