extends Node2D

@onready var spawner: MultiplayerSpawner = $PlayersContainer/MultiplayerSpawner
@onready var spawn_points: Array = []
var spawn_index := 0
	

func _ready() -> void:
	spawn_points = get_tree().get_nodes_in_group("spawn_point")
	spawner.spawn_function = _spawn_player_custom

func _spawn_player_custom(data: Dictionary) -> Node:
	print(
		"PROCESS: ",
		OS.get_process_id(),
		" | PEER ID: ",
		multiplayer.get_unique_id(),
		" | SERVER: ",
		multiplayer.is_server()
	)

	var player_scene = load("res://scenes/player/player.tscn")
	var player_instance = player_scene.instantiate()
	player_instance.name = str(data["id"])
	player_instance.set_multiplayer_authority(data["id"], true)
	player_instance.position = data["spawn_pos"]

	return player_instance

func spawn_player(id: int) -> void:
	var pos = Vector2.ZERO
	if spawn_points.is_empty():
		push_warning("На мапі нема точок спавну")
	else:
		pos = spawn_points[spawn_index % spawn_points.size()].global_position
	spawn_index += 1
	spawner.spawn({"id": id, "spawn_pos": pos})

func get_next_spawn_position() -> Vector2:
	if spawn_points.is_empty():
		return Vector2.ZERO
	
	var index = get_tree().get_nodes_in_group("Player").size() % spawn_points.size()
	return spawn_points[index].global_position
