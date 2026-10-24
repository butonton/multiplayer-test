extends StaticBody2D

@onready var anim = $AnimatedSprite2D
@onready var sound = $AudioStreamPlayer2D



var is_crashed = false
var normal_pitch

func _process(delta: float) -> void:
	#visible = is_on_screen
	pass

func _ready() -> void:
	
	
	if sound:
		normal_pitch = sound.pitch_scale
	else :
		print("!!! sound dont found: " + name  + ' !!!')
	anim.play("default")
	rotation = deg_to_rad(randf_range(0, 360))

func _on_crash_zone_area_entered(area: Area2D) -> void:
	anim.play("crash")
	if sound:
		if is_crashed:
			if sound.max_distance > 30:
				sound.max_distance -= 25
		
		sound.pitch_scale = normal_pitch + randf_range(-0.2, 0.2)
		sound.play()
	is_crashed = true
	rotation += deg_to_rad(randf_range(-10, 10))
