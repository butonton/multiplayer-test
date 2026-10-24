extends Node
class_name PlayerVisibility

@export var wall_collision_mask: int = 1
@export var fade_speed: float = 10.0
@export var visibility_point_group: String = "visibility_points"

@onready var owner_body: Node2D = get_parent()

func _process(delta: float) -> void:
	if not owner_body.is_multiplayer_authority():
		return
	update_visibility_of_others(delta)

func update_visibility_of_others(delta: float) -> void:
	var container = owner_body.get_parent()
	
	for other_player in container.get_children():
		if other_player == owner_body:
			continue
		if not other_player.is_in_group("Player"):
			continue
		
		var is_visible_to_me = check_any_point_visible(other_player)
		var target_alpha = 1.0 if is_visible_to_me else 0.0
		other_player.modulate.a = lerp(other_player.modulate.a, target_alpha, fade_speed * delta)

func check_any_point_visible(other_player: Node2D) -> bool:
	var space_state = owner_body.get_world_2d().direct_space_state
	var my_head_pos = owner_body.get_node("head").global_position
	
	var check_points = get_visibility_points(other_player)
	
	for point in check_points:
		var query = PhysicsRayQueryParameters2D.create(my_head_pos, point)
		query.exclude = [owner_body, other_player]
		query.collision_mask = wall_collision_mask
		var result = space_state.intersect_ray(query)
		if result.is_empty():
			return true
	
	return false

func get_visibility_points(player: Node2D) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for child in player.get_tree().get_nodes_in_group(visibility_point_group):
		if child.is_inside_tree() and child.get_parent().get_parent() == player:  # належить саме цьому гравцю
			points.append(child.global_position)
	return points
