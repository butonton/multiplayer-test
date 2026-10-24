extends CanvasLayer

@onready var ammo_visual = $"ammo visual"
@onready var camera = $"../head/Camera2D"  # онови шлях під реальну структуру
@onready var player_body = $".."
@onready var menu_player = $"menu player"
func _process(delta: float) -> void:
	if Input.is_action_pressed("reload"):
		ammo_visual.visible = true
	else:
		ammo_visual.visible = false
	ammo_visual.rotation = player_body.rotation
	


func _on_button_pressed() -> void:
	owner.queue_free()
	NetworkManager.disconnect_from_server()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed('ui_cancel'):
		menu_player.visible = !menu_player.visible
	
