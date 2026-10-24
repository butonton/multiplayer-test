extends CharacterBody2D

# ///////// DEBUG /////////
@export var DEBUG: bool = false
var ray_length: float = 30.0

# ///////// UI /////////
@onready var canvasLayer: CanvasLayer = $UI
@onready var hpBar = $UI/hpBar

# ///////// VISUAL NODES /////////
@onready var legs: AnimatedSprite2D = $legs
@onready var body: AnimatedSprite2D = $body
@onready var head: AnimatedSprite2D = $head
@onready var collision = $collision
@onready var camera = $head/Camera2D

# ///////// WEAPON /////////
@onready var m4a4 = $body/m4a4
@onready var muzzle: Node2D = $"body/m4a4/Muzzle"
@onready var shoulder: Node2D = $body/shoulder

@export var muzzle_offset: float = 5.0
@export var dist_to_disabled_gun: float = 100.0

var ready_weapon: bool = true
var can_shoot: bool = true

var recoil_max_power:float = 25.0  

@export var max_ammo: int = 30
var current_ammo: int = 30
var is_reloading: bool = false
@export var reload_time: float = 2.0

# ///////// MOVEMENT /////////
@export var max_speed: float = 80.0
var acceleration: float = 10.0

enum State { IDLE, WALK, RUN, SIT, SIT_WALK }
var current_state = State.IDLE

# ///////// HEAD PEEK /////////
@export var head_peek_offset: float = 15.0
@export var peek_speed: float = 8.0

var head_base_position: Vector2
var current_peek_offset: Vector2 = Vector2.ZERO

# ///////// HEALTH /////////
@export var hp: float = 100.0
var isAlive: bool = true
var consciousness = 100.0

# ///////// ANIMATIONS /////////

var intercepted_body_anim: bool = false
var played_animation_reloadFinished = false

func _ready() -> void:
	head_base_position = head.position
	
	if not is_multiplayer_authority():
		set_process(false)
		set_physics_process(false)
		camera.enabled = false
		canvasLayer.visible = false
	else:
		camera.enabled = true
		canvasLayer.visible = true
		$"UI/ammo visual".text = str(current_ammo) + " / " + str(max_ammo)



func get_input(delta):
	if ChatManager.typing:
		return
	
	var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = velocity.move_toward(input_direction * max_speed, acceleration)
	
	if velocity != Vector2.ZERO:
		var target_angle = velocity.angle()
		legs.rotation = lerp_angle(legs.rotation, target_angle, 10 * delta)
	else:
		legs.rotation = lerp_angle(legs.rotation, body.rotation, 10 * delta)
	
	var limit = deg_to_rad(40)
	var diff = angle_difference(body.rotation, legs.rotation)
	diff = clamp(diff, -limit, limit)
	legs.rotation = body.rotation + diff
	
	if current_state == 0 || current_state == 3:
		max_speed = 0
		recoil_max_power = 3
	elif current_state == 1:
		max_speed = 34 * (consciousness / 100)
		recoil_max_power = 7
	elif current_state == 2:
		max_speed = 74 *  (consciousness / 100)
		recoil_max_power = 13
	elif current_state == 4:
		max_speed = 30
	
	setVisual(delta)
	
	
	changeState(input_direction)
	setStepSound()
	if Input.is_action_pressed("press_LBM"):
		var shoot_direction = Vector2.RIGHT.rotated(muzzle.global_rotation)
		if ready_weapon:
			request_shoot.rpc_id(1, muzzle.global_position, shoot_direction)
	
	if Input.is_action_pressed("reload") and Input.is_action_pressed("ui_accept"):
		request_reload.rpc_id(1)
	
	
	
	
	var target_peek = Vector2.ZERO
	if Input.is_action_pressed("press_RBM"):
		recoil_max_power = 15.0
		max_speed = max_speed / 2
		var peek_dir = Vector2.RIGHT.rotated(body.rotation + deg_to_rad(130))
		target_peek = peek_dir * head_peek_offset
	else: recoil_max_power = 25.0
	current_peek_offset = current_peek_offset.lerp(target_peek, peek_speed * delta)
	head.position = head_base_position + current_peek_offset
	#var current_speed = velocity.length()
	
	


func setVisual(delta) -> void:
	var mouse_pos = get_global_mouse_position()
	
	#gun section
	if ready_weapon:
		pass
	
	#gun section
	
	# head section
	head.rotation = lerp_angle(head.rotation, (mouse_pos - head.global_position).angle(), 10 * delta)
	# head section
	
	# body section
	
	var base_angle = (mouse_pos - global_position).angle()
	var y = global_position.distance_to(mouse_pos)
	var correction = 0.0
	if y > 0.01:
		correction = atan(muzzle_offset / y)
	
	body.rotation = lerp_angle(body.rotation, base_angle - correction, 10 * delta)
	# body section

func changeState(input_direction) :
	#var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if isAlive:
		if input_direction != Vector2.ZERO && Input.is_action_pressed("L_Shift"):
			current_state = State.RUN
		#elif input_direction != Vector2.ZERO && Input.is_action_pressed("Take_sit"):
			#current_state = State.SIT_WALK
		#elif Input.is_action_pressed("Take_sit"):	
			#current_state = State.SIT
		elif input_direction != Vector2.ZERO :
			current_state = State.WALK
		else :
			current_state = State.IDLE

func setAnimationLegs():
	pass
	#if current_state == 4 :
		#legs.play("SIT_WALK")
		#
	#elif current_state == 3 :
		#legs.play("SIT")
		#
	if velocity.length() == 0:
		legs.play("idle")
		
	elif velocity.length() > 0 && velocity.length() <= 40:
		legs.play("walk")
		
	elif velocity.length() > 40:
		legs.play("run")

var can_take_sound = true
func setStepSound() :
	
	if velocity.length() > 10 and velocity.length() < 70:
		if can_take_sound:
			can_take_sound = false
			$legs/AudioStreamPlayer2D.volume_db = 0
			$legs/AudioStreamPlayer2D.max_distance = 50
			$legs/AudioStreamPlayer2D.pitch_scale = 1 + randf_range(-0.1, 0.1)
			$legs/AudioStreamPlayer2D.play()
			$step_timer.start(0.48)
			await $step_timer.timeout
			can_take_sound = true
			
	if velocity.length() >= 70:
		if can_take_sound:
			$legs/AudioStreamPlayer2D.volume_db = 5
			$legs/AudioStreamPlayer2D.max_distance = 200
			$legs/AudioStreamPlayer2D.pitch_scale = 1 + randf_range(-0.1, 0.1)
			can_take_sound = false
			$legs/AudioStreamPlayer2D.play()
			$step_timer.start(0.4)
			await $step_timer.timeout
			can_take_sound = true
			

func setAnimationBody(delta) :
	if intercepted_body_anim:
		return
	
	if checkWallDistance($body/shoulder, dist_to_disabled_gun):
		if can_shoot:
			body.play("not ready")
			
			set_rotate_gun(Vector2(13,0), -80, delta)
		ready_weapon = false
	else :
		body.play("ready")

		
		set_rotate_gun(Vector2(15,10), 0, delta)
		ready_weapon = true
	
	pass
	#if somethingInHand == true:
		#body.play("HAVE_LIGHT_GUN")
	#elif current_state == 4 :
		#body.play("SIT_WALK")
	#elif current_state == 3 :
		#body.play("SIT")
	#elif velocity.length() == 0:
		#body.play('IDLE')
	#elif velocity.length() > 0 && velocity.length() <= 40:
		#body.play("WALK")
	#elif velocity.length() > 40:
		#body.play("RUN")

func setAllAnimations(delta):
	if isAlive:
		setAnimationBody(delta)
		setAnimationLegs()
	else :
		body.stop()
		legs.stop()
		head.stop()

func _physics_process(delta):
	if not isAlive:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	
	get_input(delta)
	move_and_slide()
	setAllAnimations(delta)
	set_enviroument()
	collision.rotation = body.rotation + deg_to_rad(45)

func get_distance_multiplier(target: Node2D) -> float:
	var distance = global_position.distance_to(target.global_position)
	var multipler = distance / 90
	return snappedf(multipler, 0.1)




func takeDamage(amount: float) -> void:
	if not multiplayer.is_server():
		return
	
	hp -= amount
	
	if hp <= 0 and isAlive:
		isAlive = false
		update_hp.rpc(hp, false)
		GameManager.on_player_died.rpc(name)
	else:
		update_hp.rpc(hp, true)
		

func draw_debug_ray(from: Vector2, to: Vector2) -> void:
	var line = Line2D.new()
	line.add_point(from)
	line.add_point(to)
	line.width = 2.0
	line.default_color = Color.RED
	get_tree().current_scene.add_child(line)
	
	await get_tree().create_timer(0.3).timeout
	line.queue_free()

func checkWallDistance(start_pos_ray = body, ray_dist: float = 1200.0, ray_detect: float = ray_dist) -> bool:
	var start_pos = start_pos_ray.global_position
	var direction = Vector2.RIGHT.rotated(body.rotation)
	var end_pos = start_pos + direction * ray_dist
	var space_state = get_world_2d().direct_space_state
	
	var query = PhysicsRayQueryParameters2D.create(start_pos, end_pos)
	query.collision_mask = 1
	var result = space_state.intersect_ray(query)
	
	if result:
		if DEBUG:
			draw_debug_ray(start_pos, result.position)
			var indicator = $"CanvasLayer/dev vizual detector"
			indicator.visible = body.position.distance_to(result.position) > ray_detect
		
		return true;
	else:
		if DEBUG :
			$"CanvasLayer/dev vizual detector".visible = false
		return false;

func _on_shoot_cooldown_timeout() -> void:
	can_shoot = true

func _on_recovery_consciousness_timeout() -> void:
	if consciousness < 100.0:
		consciousness += 0.4

func take_consciousness(value: float = 1.0):
	if consciousness - value > 0:
		consciousness -= value
	else :
		consciousness = 0

func set_enviroument():
	$UI/Control/Panel.modulate.a = (1.0 - (consciousness / 100))

func screenShake(intensity: float, duration: float) -> void:
	if not is_multiplayer_authority():
		return  # трясти камеру тільки для себе
	
	var tween = create_tween()
	var shakes = int(duration / 0.02)
	
	for i in range(shakes):
		var random_offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(camera, "offset", random_offset, 0.02)
	
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.02)

func set_rotate_gun(pos: Vector2, rot:float, delta):
	m4a4.rotation = lerp(m4a4.rotation, deg_to_rad(rot), 20 * delta) 
	m4a4.position = lerp(m4a4.position, pos, 20 * delta) 

func set_rotate_gun_instant(pos: Vector2, rot: float) -> void:
	m4a4.rotation = deg_to_rad(rot)
	m4a4.position = pos

func moveGunToPosition(pos: Vector2, rot: float, duration: float = 0.15) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(m4a4, "position", pos, duration)
	tween.tween_property(m4a4, "rotation", deg_to_rad(rot), duration)


# ////////////////// RPC ///////////////////

@rpc("any_peer", "call_local")
func update_hp(new_hp: float, alive: bool) -> void:
	if new_hp < hp:  # тільки якщо реально отримали шкоду, не при лікуванні
		
		screenShake(5.0, 0.2)
	
	hp = new_hp
	hpBar.value = hp
	isAlive = alive

@rpc("any_peer", "call_local")
func teleport_to(new_pos: Vector2) -> void:
	position = new_pos
	velocity = Vector2.ZERO

@rpc("any_peer", "call_local")
func spawn_impact_effect(pos: Vector2, normal: Vector2, impact_type: String = "wall") -> void:
	var impact_scene: PackedScene
	
	match impact_type:
		"wall":
			impact_scene = load("res://scenes/elements/wall_bullet_impact.tscn")
		"blood":
			impact_scene = load("res://scenes/elements/blood_bullet_impact.tscn")
		"iron":
			impact_scene = load("res://scenes/elements/iron_bullet_impact.tscn")
		_:
			impact_scene = load("res://scenes/elements/wall_bullet_impact.tscn")
	
	var impact = impact_scene.instantiate()
	impact.global_position = pos
	impact.rotation = normal.angle()
	get_tree().current_scene.add_child(impact)

@rpc("any_peer", "call_local")
func request_reload() -> void:
	if not multiplayer.is_server():
		return
	
	if is_reloading or current_ammo >= max_ammo:
		return
	
	
	do_reload_sequence.rpc()

@rpc("any_peer", "call_local")
func do_reload_sequence() -> void:
	is_reloading = true
	intercepted_body_anim = true
	
	moveGunToPosition(Vector2(23, 8), -5)
	
	body.play("reload_start")
	await body.animation_finished
	
	set_rotate_gun_instant(Vector2(13, 1), -30)
	
	body.play("reload_finish")
	await body.animation_finished
	
	intercepted_body_anim = false
	
	if multiplayer.is_server():
		current_ammo = max_ammo
		update_ammo.rpc(current_ammo)
		is_reloading = false
		$"UI/ammo visual".text = str(current_ammo) + " / " + str(max_ammo)

@rpc("any_peer", "call_local")
func start_reload_visual() -> void:
	intercepted_body_anim = true
	body.play("reload_start")

@rpc("any_peer", "call_local")
func finish_reload(new_ammo: int) -> void:
	current_ammo = new_ammo
	
	
	body.play("reload_finish")
	
	await body.animation_finished
	intercepted_body_anim = false
	

@rpc("any_peer", "call_local")
func request_shoot(shoot_origin: Vector2, shoot_direction: Vector2) -> void:
	if not multiplayer.is_server():
		return
	
	print("SERVER: request_shoot called, is_reloading=", is_reloading, " can_shoot=", can_shoot, " current_ammo=", current_ammo)
	if !can_shoot:
		return
	
	if !can_shoot or is_reloading or current_ammo <= 0:
		return
	
	current_ammo -= 1
	update_ammo.rpc(current_ammo)
	$"UI/ammo visual".text = str(current_ammo) + " / " + str(max_ammo)
	
		
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		shoot_origin,
		shoot_origin + shoot_direction.normalized() * 1200.0 #<-- line distance
	)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	
	
	
	var hit_point = shoot_origin + shoot_direction.normalized() * 1200.0
	var impact_type: String = "wall"
	if result:
		hit_point = result.position
		if result.collider.has_method("takeDamage"):
			result.collider.takeDamage(25.0)
		
		if DEBUG:
			print("has_meta check: ", result.collider.has_meta("impact"))
			print("get_meta check: ", result.collider.get_meta("impact", "NONE"))
		
		if result.collider.has_meta("impact"):
			impact_type = result.collider.get_meta("impact")
		else:
			impact_type = "wall"
		
		spawn_impact_effect.rpc(hit_point, result.normal, impact_type)
		
	
	
	$body/m4a4/shoot_cooldown.start()
	can_shoot = false
	show_shoot_effect.rpc()

@rpc("any_peer", "call_local")
func show_shoot_effect() -> void:
	m4a4.play("shoot")
	$body/m4a4/AudioStream.play()
	body.rotation += deg_to_rad(randf_range(10, recoil_max_power))
	screenShake(0.5, 0.1)

@rpc("any_peer", "call_local")
func update_ammo(new_ammo) -> void:
	current_ammo = new_ammo

# server
