extends StaticBody2D

@onready var anim = $AnimatedSprite2D
@onready var area2d = $Area2D
@onready var delete_timer = $Timer_self_delete
@onready var particles = $CPUParticles2D
@onready var sound = $AudioStreamPlayer2D
# Called when the node enters the scene tree for the first time.

func _ready() -> void:
	
	if not is_visible_to_shooter():
		visible = false
	if visible:
		anim.play("default")
	
	if delete_timer:
		delete_timer.start()
	if particles:
		particles.emitting = true
	
	if sound:
		sound.pitch_scale = randf_range(0.8, 1.2)
	
	await  delete_timer.timeout
	queue_free()
	
	


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("take_consciousness"):
		var dist_to_body = position.distance_to(body.position)
		var falloff = max(0.0, 100 - dist_to_body)
		body.take_consciousness(0.2 * falloff)

func is_visible_to_shooter() -> bool:
	var player = get_local_player()
	if not player:
		return true
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(player.global_position, global_position)
	query.exclude = [player]
	query.collision_mask = 1  # шар стін
	
	var result = space_state.intersect_ray(query)
	
	if result:
		return global_position.distance_to(result.position) < 5.0  # промінь долетів майже до самої точки ефекту
	return true

func get_local_player() -> Node:
	for p in get_tree().get_nodes_in_group("Player"):
		if p.is_multiplayer_authority():
			return p
	return null
