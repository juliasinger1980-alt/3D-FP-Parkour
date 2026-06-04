extends CharacterBody3D

@onready var camera: Camera3D = $head/playercam
@onready var head: Node3D = $head

@onready var animation_player: AnimationPlayer = $head/playercam/SubViewportContainer/SubViewport/viewmodel_cam/fp_rig/AnimationPlayer

@onready var wallcheck_l: RayCast3D = $WallcheckL
@onready var wallcheck_r: RayCast3D = $WallcheckR

@onready var fps_label: Label = $"../UI/Transform_repl/VBoxContainer/FPS"
@onready var velocity_label: Label = $"../UI/Transform_repl/VBoxContainer/Velocity"
@onready var sprint_toggle_label: Label = $"../UI/Transform_repl/VBoxContainer/Sprint_toggle"

#GRAVITY
var gravity_player := 50

#WASD_MOVEMENT
var move_input: Vector2
var cur_speed := Vector3.ZERO
var target_speed_gehen := 9.0
var target_speed_sprint := 15.0
var max_speed := 0.0
var sprinting := false
var dir := Vector3.ZERO
var accel := 12.0

#JUMP
var sprungstaerke := 20.0
var air_control_mult := 0.2
var air_speed_incr := 4
var sprungbuffertimer := 0.150
var koyotebuffertimer := 0.150
var jump_boost := 5 #for bunny_hop
@onready var sprungbuffertimer_max = sprungbuffertimer
@onready var koyotebuffertimer_max = koyotebuffertimer

#CAM
var cam_sway_rot_dir: Vector3
var sway_lerp_str := 5
var sway_amount_deg_sprint := 2
var sway_amount_deg_walk := 1
var x_rot := 0.0
var y_rot := 0.0
var mouse_sensi := 0.0015
var fov_normal := 100.0
var fov_sprinting := 110.0
var cam_fov_lerp_str := 8.0
var walking_fov_cooldown := 0.050
@onready var walking_fov_cooldown_max = walking_fov_cooldown
@onready var orig_cam_rot = camera.rotation
@onready var original_cam_pos = camera.position

#SLIDE/GP
var sliding := false
var fov_sliding := 120.0
var sliding_speed := 30.5
var min_slide_speed:= 16.0
var slide_dampening := 0.999
var slide_control_mult := 0.2
var sliding_cam_offset := 0.6
var sliding_cam_lerp_str := 8.0
var ground_pound_speed := 20.0
var slide_cooldown := 0.200
@onready var sliding_cam_pos = original_cam_pos - Vector3(0, sliding_cam_offset, 0)
@onready var slide_cooldown_max = slide_cooldown

#WALLRUN
var wallrunningL := false
var wallrunningR := false
var wallrun_boost := 4.0
var target_speed_wallrun := 25.0
var wall_dir: Vector3
var wall_L_normal: Vector3
var wall_R_normal: Vector3
var sway_amount_deg_wallrunning := 4.0
var wallrun_lerp_str := 3.0
var gravity_wallrun := 28
var min_wallrun_speed := 4
var wallrun_jump_off_boost := 8
var wallrun_jump_off_str := 20
var just_wallran_L := false
var just_wallran_R := false

#DEBUGGING
var fliegend := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$head/playercam/SubViewportContainer/SubViewport.size = DisplayServer.window_get_size()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		x_rot = -event.relative.y * mouse_sensi
		camera.rotation.x += x_rot
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		
		y_rot = -event.relative.x * mouse_sensi
		rotation.y += y_rot

func _physics_process(delta: float) -> void:
	$head/playercam/SubViewportContainer/SubViewport/viewmodel_cam.global_transform = camera.global_transform
	if is_on_wall():
		var n = get_wall_normal()
		if cur_speed.dot(n) < 0:
			cur_speed = cur_speed.slide(n)
	
	WASD_Movement(delta)
	springen(delta)
	sprint_state_set(delta)
	max_speed_set(delta)
	grav(delta)
	cam_sway(delta)
	cam_fov_set(delta)
	cur_speed_set(delta)
	vel_x_z_set(delta)
	slide_ground_pound(delta)
	wallrun(delta)
	Debugging(delta)
	Label_text(delta)
	get_state()
	animation_handler(delta)
	move_and_slide()
	#print(velocity.y)

func WASD_Movement(delta):
	dir = Vector3.ZERO
	#BASIC X/Z-MOVEMENT
	if Input.is_action_pressed("W"):
		dir += -global_transform.basis.z
	if Input.is_action_pressed("S"):
		dir += global_transform.basis.z
	if Input.is_action_pressed("A"):
		dir += -global_transform.basis.x
	if Input.is_action_pressed("D"):
		dir += global_transform.basis.x
	
	move_input = Input.get_vector("A","D","W","S")
	dir = dir.normalized()

func sprint_state_set(delta):
	if sprinting:
		if Input.is_action_just_pressed("Shift"):
			sprinting = false
	elif Input.is_action_just_pressed("Shift"):
		sprinting = true

func max_speed_set(delta):
	if sprinting:
		max_speed = target_speed_sprint
	else:
		max_speed = target_speed_gehen

func cur_speed_set(delta):
	if not wallrunningL and not wallrunningR:
		if sliding:
			cur_speed *= slide_dampening
			cur_speed = lerp(cur_speed, max_speed * dir, accel * delta * slide_control_mult)
		elif not is_on_floor():
			cur_speed = lerp(cur_speed, (max_speed + air_speed_incr) * dir, accel * delta * air_control_mult)
		else:
			cur_speed = lerp(cur_speed, max_speed * dir, accel * delta)

func vel_x_z_set(delta):
	if not wallrunningL and not wallrunningR:
		velocity.x = cur_speed.x
		velocity.z = cur_speed.z

func grav(delta):
	if not fliegend:
		if wallrunningL or wallrunningR:
			velocity.y -= gravity_wallrun * delta
		elif not is_on_floor():
			velocity.y -= gravity_player * delta

func springen(delta):
	if wallrunningL or wallrunningR:
		return
	if Input.is_action_just_pressed("Space"):
		sprungbuffertimer = 0.150
	
	if is_on_floor():
		koyotebuffertimer = 0.150
	
	if not is_on_floor():
		koyotebuffertimer -= delta
	
	koyotebuffertimer = clamp(koyotebuffertimer, 0, koyotebuffertimer_max)
	
	sprungbuffertimer -= delta
	sprungbuffertimer = clamp(sprungbuffertimer, 0, koyotebuffertimer_max)
	
	if (is_on_floor() and sprungbuffertimer > 0) or (not is_on_floor() and koyotebuffertimer > 0 and Input.is_action_just_pressed("Space")):
		velocity.y = sprungstaerke
		cur_speed += jump_boost * dir
		koyotebuffertimer = 0

func slide_ground_pound(delta):
	if wallrunningL or wallrunningR:
		return
	
	if Input.is_action_just_pressed("Ctrl") and (
		not is_on_floor()
		or (slide_cooldown == 0 and move_input != Vector2.ZERO)):
		
		if not is_on_floor():
			velocity.y -= ground_pound_speed
		cur_speed = sliding_speed * dir
		sliding = true
	
	if sliding:
		if Input.is_action_just_released("Ctrl") or cur_speed.length() <= min_slide_speed:
			slide_cooldown = slide_cooldown_max
			sliding = false
		if is_on_floor():
			camera.position = lerp(camera.position, sliding_cam_pos, sliding_cam_lerp_str*delta)
	else:
		camera.position = lerp(camera.position, original_cam_pos, sliding_cam_lerp_str*delta)
	
	slide_cooldown -= delta
	slide_cooldown = clamp(slide_cooldown, 0, slide_cooldown_max)

func wallrun(delta):
	if (not just_wallran_L) and ((not wallrunningL and not wallrunningR) and (not is_on_floor() and wallcheck_l.is_colliding())):
		wall_L_normal = wallcheck_l.get_collision_normal()
		wall_dir = Vector3.UP.cross(wallcheck_l.get_collision_normal().normalized())
		if velocity.dot(wall_dir) < 0:
			wall_dir = -wall_dir
		if cur_speed.length() > min_wallrun_speed:
			cur_speed = cur_speed + wallrun_boost * wall_dir
			if velocity.y < 2:
				velocity.y = 6
			wallrunningL = true
			
	if (not just_wallran_R) and ((not wallrunningL and not wallrunningR) and (not is_on_floor() and wallcheck_r.is_colliding())):
		wall_R_normal = wallcheck_r.get_collision_normal()
		wall_dir = Vector3.UP.cross(wallcheck_r.get_collision_normal().normalized())
		if velocity.dot(wall_dir) < 0:
			wall_dir = -wall_dir
		if cur_speed.length() > min_wallrun_speed:
			cur_speed = cur_speed + wallrun_boost * wall_dir
			if velocity.y < 2:
				velocity.y = 6
			wallrunningR = true
		
	#print("VEL: ", " X: ", int(velocity.x), " Z: ",  int(velocity.z))
	#print("CUR_S", cur_speed)
	#print(wallcheck_r.is_colliding())
	
	if wallrunningL:
		if Input.is_action_just_pressed("Space"):
			wallrunningL = false
			velocity.x += (wallrun_jump_off_boost * dir).x
			velocity.z += (wallrun_jump_off_boost * dir).z
			velocity.y = wallrun_jump_off_str
			just_wallran_L = true
			just_wallran_R = false
		if not wallcheck_l.is_colliding() or is_on_floor() or cur_speed.length() < min_wallrun_speed:
			just_wallran_L = true
			just_wallran_R = false
			wallrunningL = false
		if velocity.length() < target_speed_wallrun:
			velocity.x = lerp(velocity.x , target_speed_wallrun * wall_dir.x, wallrun_lerp_str * delta)
			velocity.z = lerp(velocity.z , target_speed_wallrun * wall_dir.z, wallrun_lerp_str * delta)
		cur_speed.x = velocity.x
		cur_speed.z = velocity.z
		camera.rotation.z = lerp(camera.rotation.z, orig_cam_rot.z - deg_to_rad(sway_amount_deg_wallrunning), sway_lerp_str*delta)
		
	if wallrunningR:
		if Input.is_action_just_pressed("Space"):
			wallrunningR = false
			velocity.x += (wallrun_jump_off_boost * dir).x
			velocity.z += (wallrun_jump_off_boost * dir).z
			velocity.y = wallrun_jump_off_str
			just_wallran_R = true
			just_wallran_L = false
		if not wallcheck_r.is_colliding() or is_on_floor() or cur_speed.length() < min_wallrun_speed:
			just_wallran_R = true
			just_wallran_L = false
			wallrunningR = false
		if velocity.length() < target_speed_wallrun:
			velocity.x = lerp(velocity.x , target_speed_wallrun * wall_dir.x, wallrun_lerp_str * delta)
			velocity.z = lerp(velocity.z , target_speed_wallrun * wall_dir.z, wallrun_lerp_str * delta)
		cur_speed.x = velocity.x
		cur_speed.z = velocity.z
		camera.rotation.z = lerp(camera.rotation.z, orig_cam_rot.z + deg_to_rad(sway_amount_deg_wallrunning), sway_lerp_str*delta)
	
	if is_on_floor():
		just_wallran_L = false
		just_wallran_R = false

func cam_sway(delta):
	if not wallrunningL and not wallrunningR:
		if move_input.x > 0:
			if sprinting:
				camera.rotation.z = lerp(camera.rotation.z, orig_cam_rot.z - deg_to_rad(sway_amount_deg_sprint), sway_lerp_str*delta)
			else:
				camera.rotation.z = lerp(camera.rotation.z, orig_cam_rot.z - deg_to_rad(sway_amount_deg_walk), sway_lerp_str*delta)
				
		elif move_input.x < 0:
			if sprinting:
				camera.rotation.z = lerp(camera.rotation.z, orig_cam_rot.z + deg_to_rad(sway_amount_deg_sprint), sway_lerp_str*delta)
			else:
				camera.rotation.z = lerp(camera.rotation.z, orig_cam_rot.z + deg_to_rad(sway_amount_deg_walk), sway_lerp_str*delta)
		
		else:
			camera.rotation.z = lerp(camera.rotation.z, orig_cam_rot.z, sway_lerp_str*delta)

func cam_fov_set(delta):
	if wallrunningL or wallrunningR:
		camera.fov = lerp(camera.fov, fov_sliding, cam_fov_lerp_str*delta)
		return
	if sliding:
		if move_input != Vector2.ZERO:
			camera.fov = lerp(camera.fov, fov_sliding, cam_fov_lerp_str*delta)
		return
	if not sprinting:
		camera.fov = lerp(camera.fov, fov_normal, cam_fov_lerp_str*delta)
		return
	if move_input != Vector2.ZERO:
		walking_fov_cooldown = walking_fov_cooldown_max
		camera.fov = lerp(camera.fov, fov_sprinting, cam_fov_lerp_str*delta)
	else:
		if walking_fov_cooldown == 0:
			camera.fov = lerp(camera.fov, fov_normal, cam_fov_lerp_str*delta)
	walking_fov_cooldown -= delta
	walking_fov_cooldown = clamp(walking_fov_cooldown, 0, walking_fov_cooldown_max)

func Label_text(delta):
	fps_label.text = "FPS: " + str(Engine.get_frames_per_second())
	velocity_label.text = "VELOCITY: " + str(int(velocity.length()))
	sprint_toggle_label.text = get_state()

func get_state() -> String:
	if wallrunningL or wallrunningR:
		return "WALLRUNNING"
	elif sliding:
		return "SLIDING"
	elif move_input == Vector2.ZERO:
		return "IDLE"
	elif sprinting:
		return "SPRINTING"
	else:
		return "WALKING"

func animation_handler(delta):
	if get_state() == "SPRINTING":
		if not animation_player.is_playing():
			animation_player.play("running")
	if get_state() == "IDLE":
		animation_player.stop()
	
func Debugging(delta):
	#NO-GRAV modus (T)
	if Input.is_action_just_pressed("T"):
		if fliegend:
			fliegend = false
		elif not fliegend:
			fliegend = true
	if fliegend:
		if Input.is_action_just_pressed("G"):
			velocity.y += 50
