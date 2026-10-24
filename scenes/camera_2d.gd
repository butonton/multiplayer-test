extends Camera2D

@export var multipler_offset: float = 10.0
@export var smooth_speed: float = 8.0
var max_offset: float = 100.0

func _process(delta: float) -> void:
	var mouse_local = get_local_mouse_position()
	var dist_to_cursor = mouse_local.length() / 100
	
	var target_position = Vector2.ZERO
	
	
	if Input.is_action_pressed("press_RBM"):
		var direction = mouse_local.normalized()
		
		target_position = direction * min(multipler_offset * dist_to_cursor, max_offset)
	
	position = position.lerp(target_position, smooth_speed * delta)
	
	if Input.is_action_just_pressed("scroll_up"):
		if zoom < Vector2(6,6):
			zoom += Vector2(1,1)
	
	if Input.is_action_just_pressed("scroll_down"):
		if zoom > Vector2(3,3):
			zoom -= Vector2(1,1)
