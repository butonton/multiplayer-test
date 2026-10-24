extends StaticBody2D

var position_offset = 0.0
var ready_position

func _ready() -> void:
	ready_position = position

func _physics_process(delta: float) -> void:
	if position != ready_position:
		position = lerp(position, ready_position, 10 * delta)

func takeDamage(val):
	
	position -= Vector2.RIGHT.rotated(rotation) * 2
	
