class_name FirstPersonController
extends CharacterBody3D
signal focus_changed(prompt: String)
signal interaction_progress(progress: float)
@export_group("Movement")
@export var walk_speed := 3.1; @export var sprint_speed := 4.8; @export var crouch_speed := 1.8; @export var ground_acceleration := 9.0; @export var ground_deceleration := 12.0; @export var gravity := 18.0; @export var max_slope_angle := 46.0
@export_group("View")
@export var mouse_sensitivity := 0.0019; @export var standing_eye_offset := 0.6; @export var crouching_eye_offset := 0.1; @export var crouch_transition_speed := 5.0; @export var step_bob_amount := 0.012; @export var step_bob_frequency := 7.5
@export_group("Interaction")
@export var interaction_distance := 2.4
@onready var head: Node3D = $Head; @onready var camera: Camera3D = $Head/Camera3D; @onready var ray: RayCast3D = $Head/Camera3D/InteractionRay; @onready var collider: CollisionShape3D = $Collision
var pitch := 0.0; var bob_time := 0.0; var focused: Interactable; var last_yaw := 0.0
var carried_item_id: StringName = &""
var carry_mesh: MeshInstance3D
var footstep_player: AudioStreamPlayer3D
var footstep_distance := 0.0
var previous_step_position := Vector3.ZERO
var step_streams: Dictionary = {}
var footstep_index := 0
var sprint_active := false
var crouch_active := false
var hold_target: Interactable
var hold_elapsed := 0.0
func _ready() -> void:
	floor_max_angle = deg_to_rad(max_slope_angle); ray.target_position = Vector3(0, 0, -interaction_distance); if OS.get_environment("TOP_CAPTURE_DIR").is_empty(): Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	carry_mesh = MeshInstance3D.new(); carry_mesh.name = "CarriedItem"; camera.add_child(carry_mesh)
	carry_mesh.position = Vector3(0.3, -0.28, -0.55)
	var shape := BoxMesh.new(); shape.size = Vector3(0.18, 0.06, 0.3); carry_mesh.mesh = shape
	var material := StandardMaterial3D.new(); material.albedo_color = Color(0.36, 0.39, 0.35); material.metallic = 0.55; material.roughness = 0.48; carry_mesh.material_override = material
	carry_mesh.visible = false
	footstep_player = AudioStreamPlayer3D.new(); footstep_player.name = "Footsteps"; footstep_player.position = Vector3(0, -0.75, 0); footstep_player.max_distance = 8.0; footstep_player.volume_db = -16.0; footstep_player.bus = "SFX"; add_child(footstep_player)
	for surface in [&"concrete", &"metal", &"grating"]:
		step_streams[surface] = [FacilitySoundLibrary.step(surface, 0), FacilitySoundLibrary.step(surface, 1), FacilitySoundLibrary.step(surface, 2)]
	previous_step_position = global_position
	GameSettings.changed.connect(_refresh_prompt)
func has_carried_item() -> bool: return carried_item_id != &""
func give_item(item_id: StringName) -> bool:
	if item_id == &"" or has_carried_item(): return false
	set_carried_item(item_id); return true
func take_carried_item() -> StringName:
	var result := carried_item_id
	set_carried_item(&"")
	return result
func set_carried_item(item_id: StringName) -> void:
	carried_item_id = item_id
	if carry_mesh: carry_mesh.visible = has_carried_item()
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("sprint") and GameSettings.get_value("sprint_toggle"): sprint_active = not sprint_active
	if event.is_action_pressed("crouch") and GameSettings.get_value("crouch_toggle"): crouch_active = not crouch_active
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sensitivity := float(GameSettings.get_value("mouse_sensitivity"))
		rotate_y(-event.relative.x * sensitivity); pitch = clampf(pitch + event.relative.y * sensitivity * (1.0 if GameSettings.get_value("invert_y") else -1.0), -1.42, 1.42); head.rotation.x = pitch
	if event.is_action_pressed("interact") and focused:
		var duration := focused.required_hold_duration()
		if duration <= 0.0 or not focused.can_interact(self): focused.interact(self)
		elif GameSettings.get_value("interaction_toggle") and hold_target == focused: _clear_hold()
		else:
			hold_target = focused
			hold_elapsed = 0.0
			interaction_progress.emit(0.0)
func _physics_process(delta: float) -> void:
	if not is_on_floor(): velocity.y -= gravity * delta
	else: velocity.y = -0.5
	var crouching := crouch_active if GameSettings.get_value("crouch_toggle") else Input.is_action_pressed("crouch"); var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back"); var direction := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	var sprinting := sprint_active if GameSettings.get_value("sprint_toggle") else Input.is_action_pressed("sprint")
	var target_speed := crouch_speed if crouching else (sprint_speed if sprinting and input.y < 0.0 else walk_speed); var rate := ground_acceleration if direction else ground_deceleration
	velocity.x = move_toward(velocity.x, direction.x * target_speed, rate * delta); velocity.z = move_toward(velocity.z, direction.z * target_speed, rate * delta)
	var target_height := crouching_eye_offset if crouching else standing_eye_offset; head.position.y = move_toward(head.position.y, target_height, crouch_transition_speed * delta)
	var capsule := collider.shape as CapsuleShape3D
	if capsule: capsule.height = move_toward(capsule.height, 1.25 if crouching else 1.75, crouch_transition_speed * delta)
	collider.position.y = move_toward(collider.position.y, -0.25 if crouching else 0.0, crouch_transition_speed * delta)
	if is_on_floor() and Vector2(velocity.x, velocity.z).length() > 0.4:
		bob_time += delta * step_bob_frequency * (target_speed / walk_speed); camera.position.y = sin(bob_time) * step_bob_amount * (0.0 if GameSettings.get_value("reduce_motion") else float(GameSettings.get_value("camera_bob")))
	else: camera.position.y = move_toward(camera.position.y, 0.0, delta * 0.08)
	move_and_slide(); _update_footsteps(crouching); _update_focus(); _update_hold(delta)
func _update_footsteps(crouching: bool) -> void:
	var horizontal := Vector2(global_position.x - previous_step_position.x, global_position.z - previous_step_position.z).length()
	previous_step_position = global_position
	if not is_on_floor() or horizontal > 0.5:
		footstep_distance = 0.0
		return
	footstep_distance += horizontal
	var stride := 0.95 if crouching else (1.55 if (sprint_active if GameSettings.get_value("sprint_toggle") else Input.is_action_pressed("sprint")) else 1.32)
	if footstep_distance < stride: return
	footstep_distance = fmod(footstep_distance, stride)
	var surface: StringName = &"concrete"
	if global_position.z < -52.0 and global_position.z > -59.0: surface = &"metal"
	elif global_position.z < -27.0 and global_position.z > -33.0: surface = &"grating"
	footstep_index += 1
	footstep_player.stream = step_streams[surface][footstep_index % 3]
	if DisplayServer.get_name() != "headless": footstep_player.play()
func _clear_hold() -> void:
	hold_target = null
	hold_elapsed = 0.0
	interaction_progress.emit(0.0)

func _update_hold(delta: float) -> void:
	if not is_instance_valid(hold_target): return
	if hold_target != focused or not hold_target.can_interact(self) or (not GameSettings.get_value("interaction_toggle") and not Input.is_action_pressed("interact")):
		_clear_hold()
		return
	var duration := hold_target.required_hold_duration()
	if duration <= 0.0:
		_clear_hold()
		return
	hold_elapsed += delta
	interaction_progress.emit(clampf(hold_elapsed / duration, 0.0, 1.0))
	if hold_elapsed >= duration:
		var completed := hold_target
		_clear_hold()
		completed.interact(self)

func _update_focus() -> void:
	var candidate := ray.get_collider() as Interactable if ray.is_colliding() else null
	if candidate != focused:
		_clear_hold()
		if is_instance_valid(focused) and focused.state_changed.is_connected(_refresh_prompt): focused.state_changed.disconnect(_refresh_prompt)
		focused = candidate; focus_changed.emit(_focused_prompt())
		if is_instance_valid(focused): focused.state_changed.connect(_refresh_prompt)
func _focused_prompt() -> String:
	if not is_instance_valid(focused): return ""
	var value := focused.prompt_text(self)
	if focused.required_hold_duration() > 0.0 and value.begins_with("[E]"):
		return value.replace("[E]", "[E TO START]" if GameSettings.get_value("interaction_toggle") else "[HOLD E]")
	return value

func _refresh_prompt() -> void:
	focus_changed.emit(_focused_prompt())
