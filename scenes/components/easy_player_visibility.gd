extends Node

@onready var owner_body = owner
var fade_speed = 10.0
var is_visible_to_me = false




func _process(delta):
	check_player_visibility(delta)

func get_local_player() -> Node:
	for p in get_tree().get_nodes_in_group("Player"):
		if p.is_multiplayer_authority():
			return p
	return null


func check_player_visibility(delta):
	var player = get_local_player()

	if player == null:
		return

	var space_state = owner_body.get_world_2d().direct_space_state

	var query = PhysicsRayQueryParameters2D.create(
		player.global_position,
		owner_body.global_position
	)
	query.exclude = [player]
	
	var result = space_state.intersect_ray(query)
	
	if result:
		# Перший об'єкт на шляху
		if result.collider == owner_body:
			is_visible_to_me = true
		else:
			is_visible_to_me = false
	else:
		is_visible_to_me = true
	
	var target_alpha = 1.0 if is_visible_to_me else 0.0
	owner_body.modulate.a = lerp(owner_body.modulate.a, target_alpha, fade_speed * delta)
