extends CharacterBody3D

@onready var camera: Camera3D = $head/playercam
@onready var head: Node3D = $head

@onready var animation_player: AnimationPlayer = $head/playercam/CanvasLayer/SubViewportContainer/SubViewport/viewmodel_cam/fp_rig/AnimationPlayer
@onready var hands: Node3D = $head/playercam/CanvasLayer/SubViewportContainer/SubViewport/viewmodel_cam/fp_rig
@onready var swinging_hands: PackedScene = preload("res://scenes/swinging_hands.tscn")
@onready var vaulting_hands: PackedScene = preload("res://scenes/vaulting_hands.tscn")
@onready var grappling_start_point_node: Node3D = $head/playercam/grappling_start_point
var instantiation_swinging_hands
var instantiation_vaulting_hands

@onready var wallcheck_l: RayCast3D = $WallcheckL
@onready var wallcheck_r: RayCast3D = $WallcheckR
@onready var vault_ray: RayCast3D = $VaultRay
@onready var grappling_ray: RayCast3D = $head/playercam/GrapplingRay

@onready var fps_label: Label = $"../UI/CanvasLayer/Transform_repl/VBoxContainer/FPS"
@onready var velocity_label: Label = $"../UI/CanvasLayer/Transform_repl/VBoxContainer/Velocity"
@onready var sprint_toggle_label: Label = $"../UI/CanvasLayer/Transform_repl/VBoxContainer/Sprint_toggle"

@onready var radial_blur: ColorRect = $"../visuals/CanvasLayer/RadialBlur"
@onready var radial_blur_shader_material: ShaderMaterial = radial_blur.material

@onready var spawnpoint: Node3D = $"../../Spawnpoint"

#WORLD
@onready var world = get_tree().current_scene

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
var jumpstrength := 20.0
var air_control_mult := 0.2
var airbonus_per_frame := 1.0 #for bunny_hop
var bunny_hop_control_multiplier := 1.0
var air_speed_incr := 4
var sprungbuffertimer := 0.150
var koyotebuffertimer := 0.150
var jump_boost := 5 #for bunny_hop
@onready var sprungbuffertimer_max = sprungbuffertimer
@onready var koyotebuffertimer_max = koyotebuffertimer

#CAM
var mouse_input: Vector2
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
var sway_lerp_str_else := 11.0
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
var ground_pound_speed := 25.0
var slide_cooldown := 0.200
var sway_amount_deg_slide := 6.0
@onready var sliding_cam_pos = original_cam_pos - Vector3(0, sliding_cam_offset, 0)
@onready var slide_cooldown_max = slide_cooldown

#WALLRUN
var last_wall
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
var wallrun_jump_off_boost := 16
var wallrun_jump_off_str := 20
var just_wallran_L := false
var just_wallran_R := false
var fov_wallruning := 120.0

#SWINGING
var swinging := false
var swing_jump_off_boost := 12
var swing_jump_off_str := 15
var desired_dist_swing := 5
var dist_swing: float
var dir_stange_to_player: Vector3
var swing_lerp_str := 12.0
var stange
var stange_local_pos: Vector3
var stange_pos: Vector3
var stangen_pos_change_counter_links := 0
var stangen_pos_change_counter_rechts := 0
var max_rutsch_int := 10
var rutsch_amount := 0.3
var fov_swinging := 110.0
var swing_gravity:= -8
var behind_bar := false
var infront_bar := false
var swinging_jump_off_boost := 16
var swinging_jump_off_str := 20
var max_swinging_jump_off_speed := 35.0
var swinging_cooldown := 0.100
@onready var swinging_cooldown_max = swinging_cooldown

#vaulting
var vaulting := false
var vault_collider
var vault_global_pos: Vector3
var vault_lerp_str_y := 11.0
var vault_lerp_str_xz:= 11.0
var vault_min_y_dif := 0.5
var vault_min_dif := 0.5
var Menschenhoehe := 1.5
var vault_timer := 0.160
@onready var vault_timer_max = vault_timer

#grappling hook
var grappling := false
var grappling_grav := -45.0
var max_speed_grappling := 90.0
var grappling_control_mult := 0.10
var grappling_point: Vector3
var dir_grappling_point_to_player: Vector3
var dir_player_to_grappling_point: Vector3
var distance_grappling_point_to_player: float
var spring_power := 1.0
var spring_power_current: float
var original_distance_grappling_point_to_player: float
var grappling_jump_off_boost := 5.0
var grappling_jump_off_str := 20.0
var distance_player_to_grappling_point: float
var final_target_distance: float
var target_difference := 4.0
var max_grapple_jump_off_speed := 35.0
var grappling_lerp_str := 11.0
var grappling_cooldown := 0.200
@onready var grappling_cooldown_max = grappling_cooldown
##VISUALS
var rope_points: Array
var rope_gravity := 3
var rope_thickness := 0.05
var mesh: ImmediateMesh
var point_count: float
var grappling_start_point: Vector3 

#HAND-SWAY
var sway: Vector2
var sway_amount := 0.008
var hand_sway_lerp_str := 4.0
var desired_rope_point_distance

#POST PROCESSING
var Radial_Blur
var blur_str: float

#DEBUGGING
var fliegend := false

func _ready() -> void:
	mesh = ImmediateMesh.new()
	EventBus.swing_triggered.connect(_on_swing_entered)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#$head/playercam/CanvasLayer/SubViewportContainer/SubViewport.size = DisplayServer.window_get_size()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		x_rot = -event.relative.y * mouse_sensi
		camera.rotation.x += x_rot
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		y_rot = -event.relative.x * mouse_sensi
		rotation.y += y_rot
		
		mouse_input = event.relative

func _physics_process(delta: float) -> void:
	grappling_start_point = grappling_start_point_node.global_position
	$head/playercam/CanvasLayer/SubViewportContainer/SubViewport/viewmodel_cam.global_transform = camera.global_transform
	if is_on_wall():
		var n = get_wall_normal()
		if cur_speed.dot(n) < 0:
			cur_speed = cur_speed.slide(n)
	
	WASD_Movement(delta)
	jump(delta)
	sprint_state_set(delta)
	max_speed_set(delta)
	grav(delta)
	hand_sway(delta)
	cam_sway(delta)
	cam_fov_set(delta)
	cur_speed_set(delta)
	vel_x_z_set(delta)
	slide_ground_pound(delta)
	wallrun(delta)
	swing(delta)
	vault(delta)
	grappling_hook(delta)
	grappling_visuals(delta)
	Debugging(delta)
	Label_text(delta)
	get_state()
	animation_handler(delta)
	post_processing(delta)
	move_and_slide()
	#print(dir)

func WASD_Movement(delta):
	dir = Vector3.ZERO
	#BASIC X/Z-MOVEMENT
	if Input.is_action_pressed("W"):
		dir += -global_transform.basis.z
	if Input.is_action_pressed("S"):
		dir += global_transform.basis.z
	if Input.is_action_pressed("A") and not swinging:
		dir += -global_transform.basis.x
	if Input.is_action_pressed("D") and not swinging:
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
	if not wallrunningL and not wallrunningR and not vaulting:
		if sliding:
			cur_speed *= slide_dampening
			cur_speed = lerp(cur_speed, max_speed * dir, accel * delta * slide_control_mult)
		elif grappling:
			cur_speed = lerp(cur_speed, (max_speed_grappling) * dir, accel * delta * grappling_control_mult)
		elif not is_on_floor():
			if cur_speed.length() < (max_speed + air_speed_incr) or swinging:
				cur_speed = lerp(cur_speed, (max_speed + air_speed_incr) * dir, accel * delta * air_control_mult)
			else:
				#print("airbonus")
				cur_speed = lerp(cur_speed, (cur_speed.length() + airbonus_per_frame) * dir, accel * delta * air_control_mult * bunny_hop_control_multiplier)
		else:
			cur_speed = lerp(cur_speed, max_speed * dir, accel * delta)

func vel_x_z_set(delta):
	if not wallrunningL and not wallrunningR:
		velocity.x = cur_speed.x
		velocity.z = cur_speed.z

func grav(delta):
	if not fliegend and not vaulting and not grappling and not swinging:
		if wallrunningL or wallrunningR:
			velocity.y -= gravity_wallrun * delta
		elif not is_on_floor():
			#print("schwnaz")
			velocity.y -= gravity_player * delta

func jump(delta):
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
		velocity.y = jumpstrength
		cur_speed += jump_boost * dir
		koyotebuffertimer = 0

func slide_ground_pound(delta):
	if wallrunningL or wallrunningR:
		return
	if grappling:
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
			camera.rotation.z = lerp(camera.rotation.z, orig_cam_rot.z + deg_to_rad(sway_amount_deg_slide), sway_lerp_str*delta)
	else:
		camera.position = lerp(camera.position, original_cam_pos, sliding_cam_lerp_str*delta)
	
	slide_cooldown -= delta
	slide_cooldown = clamp(slide_cooldown, 0, slide_cooldown_max)

func wallrun(delta):
	if swinging:
		return
	
	if is_on_floor():
		wallrunningL = false
		wallrunningR = false
		last_wall = null
		return
	
	if (not wallcheck_l.get_collider() == last_wall and ((not wallrunningL and not wallrunningR) and (not is_on_floor() and wallcheck_l.is_colliding()))):
		wall_L_normal = wallcheck_l.get_collision_normal()
		wall_dir = Vector3.UP.cross(wallcheck_l.get_collision_normal().normalized())
		if velocity.dot(wall_dir) < 0:
			wall_dir = -wall_dir
		if cur_speed.length() > min_wallrun_speed:
			cur_speed = cur_speed + wallrun_boost * wall_dir
			if velocity.y < 2:
				velocity.y = 6
			wallrunningL = true
			
	if  (not wallcheck_r.get_collider() == last_wall and ((not wallrunningL and not wallrunningR) and (not is_on_floor() and wallcheck_r.is_colliding()))):
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
		if not wallcheck_l.is_colliding() or is_on_floor() or cur_speed.length() < min_wallrun_speed:
			wallrunningL = false
			return
		if Input.is_action_just_pressed("Space"):
			wallrunningL = false
			cur_speed += wallrun_jump_off_boost * dir
			velocity.y = wallrun_jump_off_str
			return
		if velocity.length() < target_speed_wallrun:
			velocity.x = lerp(velocity.x , target_speed_wallrun * wall_dir.x, wallrun_lerp_str * delta)
			velocity.z = lerp(velocity.z , target_speed_wallrun * wall_dir.z, wallrun_lerp_str * delta)
		cur_speed.x = velocity.x
		cur_speed.z = velocity.z
		camera.rotation.z = lerp(camera.rotation.z, orig_cam_rot.z - deg_to_rad(sway_amount_deg_wallrunning), sway_lerp_str*delta)
		last_wall = wallcheck_l.get_collider()
		
	if wallrunningR:
		if not wallcheck_r.is_colliding() or is_on_floor() or cur_speed.length() < min_wallrun_speed:
			wallrunningR = false
			return
		if Input.is_action_just_pressed("Space"):
			wallrunningR = false
			cur_speed += wallrun_jump_off_boost * dir
			velocity.y = wallrun_jump_off_str
			return
		if velocity.length() < target_speed_wallrun:
			velocity.x = lerp(velocity.x , target_speed_wallrun * wall_dir.x, wallrun_lerp_str * delta)
			velocity.z = lerp(velocity.z , target_speed_wallrun * wall_dir.z, wallrun_lerp_str * delta)
		cur_speed.x = velocity.x
		cur_speed.z = velocity.z
		camera.rotation.z = lerp(camera.rotation.z, orig_cam_rot.z + deg_to_rad(sway_amount_deg_wallrunning), sway_lerp_str*delta)
		last_wall = wallcheck_r.get_collider()

func swing(delta):
	if swinging:
		if Input.is_action_just_pressed("Space"):
			swinging = false
			cur_speed += swinging_jump_off_boost * dir
			velocity.y = swinging_jump_off_str
			cur_speed.x = clamp(cur_speed.x,-max_swinging_jump_off_speed, max_swinging_jump_off_speed)
			cur_speed.z = clamp(cur_speed.z,-max_swinging_jump_off_speed, max_swinging_jump_off_speed)
			velocity.x = clamp(velocity.x,-max_swinging_jump_off_speed, max_swinging_jump_off_speed)
			velocity.z = clamp(velocity.z,-max_swinging_jump_off_speed, max_swinging_jump_off_speed)
			swinging_cooldown = swinging_cooldown_max
			return
		#print(stange.global_transform.basis.z.z)
		if Input.is_action_pressed("A"):
			if not stangen_pos_change_counter_links == max_rutsch_int:
				if infront_bar:
					stange_pos += rutsch_amount * stange.global_transform.basis.y
				if behind_bar:
					stange_pos -= rutsch_amount * stange.global_transform.basis.y
				stangen_pos_change_counter_links += 1
				stangen_pos_change_counter_rechts -= 1
		if Input.is_action_pressed("D"):
			if not stangen_pos_change_counter_rechts == max_rutsch_int:
				if infront_bar:
					stange_pos -= rutsch_amount * stange.global_transform.basis.y
				if behind_bar:
					stange_pos += rutsch_amount * stange.global_transform.basis.y
				stangen_pos_change_counter_links -= 1
				stangen_pos_change_counter_rechts += 1
		dir_stange_to_player = (global_position - stange_pos).normalized()
		dist_swing = (global_position - stange_pos).length()
		#if dist_swing > desired_dist_swing:
		global_position = lerp(global_position, stange_pos + (dir_stange_to_player * desired_dist_swing), swing_lerp_str*delta)
		velocity.y = velocity.slide(dir_stange_to_player).y
		velocity.y = swing_gravity
	
	swinging_cooldown -= delta
	swinging_cooldown = clamp(swinging_cooldown, 0, swinging_cooldown_max)

func _on_swing_entered(trigger):
	if swinging or swinging_cooldown != 0:
		return
	stangen_pos_change_counter_rechts = 0
	stangen_pos_change_counter_links = 0
	infront_bar = false
	behind_bar = false
	#var from = trigger.global_position
	#var to = global_position
	#var space = get_world_3d().direct_space_state
	#var parameters = PhysicsRayQueryParameters3D.create(from,to)
	#var result = space.intersect_ray(parameters)
	if trigger.to_local(global_position).x > 0:
		infront_bar = true
	if trigger.to_local(global_position).x < 0:
		behind_bar = true
	print(trigger.to_local(global_position))
	stange = trigger
	stange_pos = trigger.get_global_position()
	stange_local_pos = trigger.get_position()
	swinging = true

func vault(delta):
	if grappling:
		return
	if vault_ray.is_colliding():
		if not vaulting and vault_ray.get_collider().is_in_group("block"):
			vault_collider = vault_ray.get_collider()
			vault_global_pos = vault_ray.get_collision_point()
			#print("START VAULT... ")
			vault_timer = vault_timer_max
			vaulting = true
	
	if vaulting:
		velocity.y = 0
		if vault_timer == 0:
			#print("ZEIT AUS!!!")
			vaulting = false
			return
		if (vault_global_pos + Vector3(0,Menschenhoehe,0) - global_position).length() < vault_min_dif:
			#print("passt schon")
			vaulting = false
			return
		#print("vault_point: ", vault_global_pos + Vector3(0,Menschenhoehe,0), "  player: ", global_position, "  diff: ", (vault_global_pos + Vector3(0,Menschenhoehe,0) - global_position).length())
		global_position.y = lerp(global_position.y, vault_global_pos.y + Menschenhoehe, vault_lerp_str_y * delta)
		#if vault_global_pos.y - global_position.y < vault_min_y_dif:
			#print("hoch genug")
		global_position.x = lerp(global_position.x, vault_global_pos.x, vault_lerp_str_xz * delta)
		global_position.z = lerp(global_position.z, vault_global_pos.z, vault_lerp_str_xz * delta)
	
	vault_timer -= delta
	vault_timer = clamp(vault_timer, 0, vault_timer_max)

func grappling_hook(delta):
	if not grappling and grappling_cooldown == 0 and grappling_ray.is_colliding():
		if grappling_ray.get_collider().is_in_group("grappable") and Input.is_action_just_pressed("RC"):
			grappling_point = grappling_ray.get_collision_point()
			original_distance_grappling_point_to_player = (global_position - grappling_point).length()
			final_target_distance = original_distance_grappling_point_to_player - target_difference
			rope_points.clear()
			point_count = original_distance_grappling_point_to_player
			generate_points(delta)
			desired_rope_point_distance = original_distance_grappling_point_to_player/3 / point_count
			var l = []
			for i in rope_points:
				l.append(i.pos) 
			print("grappling_point: ", grappling_point, "  player: ", global_position, "  rope points: ", l)
			
			grappling = true
		
	if grappling:
		if is_on_floor():
			grappling = false
			cur_speed.x = clamp(cur_speed.x,-max_grapple_jump_off_speed, max_grapple_jump_off_speed)
			cur_speed.z = clamp(cur_speed.z,-max_grapple_jump_off_speed, max_grapple_jump_off_speed)
			velocity.x = clamp(velocity.x,-max_grapple_jump_off_speed, max_grapple_jump_off_speed)
			velocity.z = clamp(velocity.z,-max_grapple_jump_off_speed, max_grapple_jump_off_speed)
			return
		if Input.is_action_just_released("RC"):
			grappling = false
			velocity.y = 0
			cur_speed.x = clamp(cur_speed.x,-max_grapple_jump_off_speed, max_grapple_jump_off_speed)
			cur_speed.z = clamp(cur_speed.z,-max_grapple_jump_off_speed, max_grapple_jump_off_speed)
			velocity.x = clamp(velocity.x,-max_grapple_jump_off_speed, max_grapple_jump_off_speed)
			velocity.z = clamp(velocity.z,-max_grapple_jump_off_speed, max_grapple_jump_off_speed)
			grappling_cooldown = grappling_cooldown_max
			return
		if Input.is_action_just_pressed("Space"):
			grappling = false
			cur_speed += grappling_jump_off_boost * -global_transform.basis.z
			velocity.y = grappling_jump_off_str
			cur_speed.x = clamp(cur_speed.x,-max_grapple_jump_off_speed, max_grapple_jump_off_speed)
			cur_speed.z = clamp(cur_speed.z,-max_grapple_jump_off_speed, max_grapple_jump_off_speed)
			velocity.x = clamp(velocity.x,-max_grapple_jump_off_speed, max_grapple_jump_off_speed)
			velocity.z = clamp(velocity.z,-max_grapple_jump_off_speed, max_grapple_jump_off_speed)
			grappling_cooldown = grappling_cooldown_max
			return
		
		dir_grappling_point_to_player = (global_position - grappling_point).normalized()
		dir_player_to_grappling_point = (grappling_point - global_position).normalized()
		distance_grappling_point_to_player = (global_position - grappling_point).length() #einfach das gleiche lol
		distance_player_to_grappling_point = (grappling_point - global_position).length() #voll lol
		
		#spring_power_current = (distance_grappling_point_to_player - final_target_distance) * spring_power
		if distance_grappling_point_to_player > final_target_distance:
			global_position = lerp(global_position, grappling_point + dir_grappling_point_to_player * final_target_distance, grappling_lerp_str * delta)
		
		velocity.y = velocity.slide(dir_grappling_point_to_player).y
		velocity.y = grappling_grav
	
	grappling_cooldown -= delta
	grappling_cooldown = clamp(grappling_cooldown, 0, grappling_cooldown_max)

func generate_points(delta):
	point_count = int(point_count)
	for i in range(point_count):
		var t = float(i) / max(point_count -1, 1)
		var temp_pos = lerp(grappling_start_point, grappling_point, t)
		rope_points.append(ropepoint.new(temp_pos))

func grappling_visuals(delta):
	if grappling:
		$grappling_visuals.visible = true
		#$grappling_visuals.global_transform = Transform3D.IDENTITY
		#GRAVITY
		for i in rope_points:
			var temp = i.prev_pos
			i.prev_pos = i.pos
			i.pos += (i.pos - temp) + Vector3.DOWN * rope_gravity * delta * delta
			
		#CONSTRAINTS
		rope_points[0].pos = grappling_start_point
		rope_points[0].prev_pos = grappling_start_point
		rope_points[rope_points.size()-1].pos = grappling_point
		for j in range(8):
			for i in range(1, len(rope_points)):
				var error = (rope_points[i].pos - rope_points[i-1].pos).length() - desired_rope_point_distance
				if error > 0:
					var a = error/2
					var dir_i_to_i_1 = (rope_points[i-1].pos - rope_points[i].pos).normalized()
					var dir_i_1_to_i = (rope_points[i].pos - rope_points[i-1].pos).normalized()
					rope_points[i].pos += dir_i_to_i_1 * a
					rope_points[i-1].pos += dir_i_1_to_i * a 
				rope_points[0].pos = grappling_start_point
				rope_points[rope_points.size()-1].pos = grappling_point
		
		#IMMEDIATE MESH
		mesh.clear_surfaces()
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(1, len(rope_points)):
			var p0 = $grappling_visuals.to_local(rope_points[i-1].pos)
			var p1 = $grappling_visuals.to_local(rope_points[i].pos)
			var mid = (p0 + p1) * 0.5
			var mid_world = $grappling_visuals.to_global(mid)
			var to_cam = (camera.global_position - mid_world).normalized()
			var cam_forward = -camera.global_transform.basis.z
			var direction = (p1 - p0).normalized()
			var side1 = direction.cross(cam_forward).normalized()
			var side2 = direction.cross(side1).normalized()
			
			side1 *= rope_thickness
			var v0 = p0 + side1
			var v1 = p0 - side1
			var v2 = p1 + side1
			var v3 = p1 - side1

			mesh.surface_add_vertex(v0)
			mesh.surface_add_vertex(v1)
			mesh.surface_add_vertex(v2)

			mesh.surface_add_vertex(v2)
			mesh.surface_add_vertex(v1)
			mesh.surface_add_vertex(v3)
			
			
			side2 *= rope_thickness
			var v0_2 = p0 + side2
			var v1_2 = p0 - side2 
			var v2_2 = p1 + side2
			var v3_2 = p1 - side2

			mesh.surface_add_vertex(v0_2)
			mesh.surface_add_vertex(v1_2)
			mesh.surface_add_vertex(v2_2)

			mesh.surface_add_vertex(v2_2)
			mesh.surface_add_vertex(v1_2)
			mesh.surface_add_vertex(v3_2)
			
		mesh.surface_end()
		$grappling_visuals.mesh = mesh
	
	else:
		$grappling_visuals.visible = false

func cam_sway(delta):
	if not wallrunningL and not wallrunningR and not sliding:
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
			camera.rotation.z = lerp(camera.rotation.z, orig_cam_rot.z, sway_lerp_str_else*delta)

func hand_sway(delta):
	if not grappling and not get_state() == "IDLE" and not wallrunningL and not wallrunningR:
		sway.x = lerp(sway.x, -mouse_input.x * sway_amount, sway_lerp_str * delta)
		sway.y = lerp(sway.x, -mouse_input.y * sway_amount, sway_lerp_str * delta)
		
		hands.rotation.y = -sway.x
	else:
		hands.rotation = Vector3.ZERO

func cam_fov_set(delta):
	if swinging:
		camera.fov = lerp(camera.fov, fov_swinging, cam_fov_lerp_str*delta)
	if wallrunningL or wallrunningR:
		camera.fov = lerp(camera.fov, fov_wallruning, cam_fov_lerp_str*delta)
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
	if grappling:
		return "GRAPPLING"
	elif vaulting:
		return "VAULTING"
	elif swinging:
		return "SWINGING"
	elif wallrunningL:
		return "WALLRUNNING_LEFT"
	elif wallrunningR:
		return "WALLRUNNING_RIGHT"
	elif not is_on_floor() and velocity.y > 0:
		return "JUMPING"
	elif not is_on_floor() and velocity.y < 0:
		return "FALLING"
	elif sliding:
		return "SLIDING"
	elif move_input == Vector2.ZERO:
		return "IDLE"
	elif sprinting:
		return "SPRINTING"
	else:
		return "WALKING"

func animation_handler(delta):
	if get_state() == "GRAPPLING":
		hands.visible = false
		if animation_player.current_animation != "grappling_hold":
			animation_player.play("grappling")
			await animation_player.animation_finished
			animation_player.play("grappling_hold")
	if get_state() == "VAULTING":
		animation_player.stop()
		#print("check")
		hands.visible = false
		if not instantiation_vaulting_hands:
			vaulting_hands.instantiate()
			instantiation_vaulting_hands = vaulting_hands.instantiate()
			world.add_child(instantiation_vaulting_hands)
		instantiation_vaulting_hands.global_position = vault_global_pos
		instantiation_vaulting_hands.global_rotation = global_rotation
	else:
		if instantiation_vaulting_hands:
			instantiation_vaulting_hands.queue_free()
	
	if get_state() == "SWINGING":
		animation_player.stop()
		hands.visible = false
		if not instantiation_swinging_hands:
			swinging_hands.instantiate()
			instantiation_swinging_hands = swinging_hands.instantiate()
			world.add_child(instantiation_swinging_hands)
		instantiation_swinging_hands.global_position = stange_pos
		if behind_bar:
			instantiation_swinging_hands.global_rotation = stange.global_rotation + Vector3(0,deg_to_rad(180),0)
			#print("behind")
		else:
			instantiation_swinging_hands.global_rotation = stange.global_rotation + Vector3(0,0,0)
			#print("infront")
	else:
		if instantiation_swinging_hands:
			instantiation_swinging_hands.queue_free()

	if get_state() != "SWINGING" and get_state() != "VAULTING" and get_state() != "GRAPPLING":
		hands.visible = true

	if get_state() == "WALLRUNNING_LEFT":
		if not animation_player.current_animation == "wallrunning_left":
			animation_player.play("wallrunning_left")
	if get_state() == "WALLRUNNING_RIGHT":
		if not animation_player.current_animation == "wallrunning_right":
			animation_player.play("wallrunning_right")
	if get_state() == "JUMPING":
		if animation_player.current_animation != "jumping_hold":
			animation_player.play("jumping")
			await animation_player.animation_finished
			animation_player.play("jumping_hold")
	if get_state() == "FALLING":
		if animation_player.current_animation != "falling":
			animation_player.play("falling")
	if get_state() == "SLIDING":
		if animation_player.current_animation != "sliding":
			animation_player.play("sliding")
	if get_state() == "SPRINTING":
		if not animation_player.current_animation == "running":
			animation_player.play("running")
	if get_state() == "WALKING":
		if not animation_player.current_animation == "walking":
			animation_player.play("walking")
	if get_state() == "IDLE":
		if animation_player.current_animation != "idle_hold":
			animation_player.play("idle")
			await animation_player.animation_finished
			animation_player.play("idle_hold")

func post_processing(delta):
	#radial blur
	if grappling:
		blur_str = 40 * 0.0002 #to prevent crazy radial blur
	else:
		blur_str = velocity.length() * 0.0002
	#print(radial_blur_shader_material.get_shader_parameter("blur_power"))
	radial_blur_shader_material.set_shader_parameter("blur_power", blur_str)

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
			
	#Spawn Teleport
	if Input.is_action_just_pressed("R"):
		global_position = spawnpoint.global_position

class ropepoint:
	var pos: Vector3
	var prev_pos: Vector3
	
	func _init(position = Vector3.ZERO) -> void:
		pos = position
		prev_pos = position
